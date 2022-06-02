`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2022 01:50:50 PM
// Design Name: 
// Module Name: Multicycle_Wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Multicycle_Wrapper(RESET, CLOCK, IOBUS_IN, IOBUS_WR, IOBUS_OUT, IOBUS_ADDR);

// Main inputs/outputs of OTTER MCU
 input logic RESET, CLOCK;
 input logic [31:0] IOBUS_IN;
 output IOBUS_WR;
 output [31:0] IOBUS_OUT, IOBUS_ADDR;
 
 // --------------------------------- Fetch State -----------------------------------------------
 // Modules in Fetch State: Program Counter (PC), PC + 4, Memory Module, 4x1 MUX Connected to PC
 // Connected to Fetch State Register: PC + 4 output, output of Memory Module (IR) 

 // --------------------------------- Program Counter Setup -----------------------------------------------

// Wires: Target Generator outputs to 4x1 MUX
// TG_Jalr_to_MUX, TG_Branch_to_MUX, TG_Jal_to_MUX
logic [31:0] TG_Jalr_to_MUX, TG_Branch_to_MUX, TG_Jal_to_MUX;

//Wire: Output of Branch Condition Generator to 4x1 MUX outside PC
logic [1:0] BCG_PC_Source;

// Wire: Output of Program Count Address to Fetch Register (also serves as input of Memory)
logic [31:0] PC_Addr1;
// Wire: Output of Incremented Program Count (PC + 4), will be carried out to Fetch State Register
logic [31:0] PC_Plus_4;
// For now, MTVEC and MEPC will not be used
// Temporary wire to always have PC_WRITE as high
logic pc_write;
assign pc_write = 1'b1;

 // Program Counter, 4x1 MUX, PC + 4 Increment 
 // OLD METHOD:
PC_With_MUX Program_Counter (.MUX_IN_JALR(TG_Jalr_to_MUX), .MUX_IN_BRANCH(TG_Branch_to_MUX), .MUX_IN_JAL(TG_Jal_to_MUX),.PC_WRITE(pc_write), 
.PC_RST(RESET), .CLK(CLOCK), .PC_SOURCE(BCG_PC_Source), .PC_ADDRESS(PC_Addr1), .PC_4_to_MUX(PC_Plus_4));

// NEW METHOD: Instantiate individual modules of Program Counter

 // --------------------------------- Memory Module Setup -----------------------------------------------

// Temporary wire to always have MEM_READ1 as high
logic mem_read_1;
assign mem_read_1 = 1'b1;


// Wire: Output of Memory to Fetch Register (Labeled as IR on top level view on diagram)
logic [31:0] Mem_dout1;

// Dualport Memory (Obtained from Canvas), should only be instantiated ONCE. Has multiple inputs coming from Memory State (See Memory State for more details)
//OLD METHOD:
//OTTER_mem_dualport Memory (.MEM_CLK(CLOCK), .MEM_ADDR1(PC_Addr1), .MEM_READ1(mem_read_1), .MEM_DOUT1(Mem_dout1));

// NEW METHOD:
OTTER_mem_byte Memory (.MEM_CLK(CLOCK), .MEM_ADDR1(PC_Addr1), .MEM_ADDR2(Execute_Reg_ALU_out), .MEM_DIN2(Execute_Reg_rs2), .MEM_WRITE2(Execute_Reg_memWrite),
.MEM_READ1(mem_read_1), .MEM_READ2(Execute_Reg_memRead2), .MEM_DOUT1(Mem_dout1), .MEM_DOUT2(mem_dout2), .IO_IN(IOBUS_IN), .IO_WR(IOBUS_WR),
 .MEM_SIZE(Execute_Reg_mem_dout1[13:12]), .MEM_SIGN(Execute_Reg_mem_dout1[14]));

 // --------------------------------- Fetch State Register Setup -----------------------------------------------

// Fetch Register for Pipeline Setup (write output of Memory to Fetch Register on negative clock cycle)
// Initialize FETCH_REG to hold two values: Incremented PC and output of Memory
logic [0:2][31:0]FETCH_REG;
 
 // Wires: Output of saved, incremented PC and output of Memory (Mem_dout1)
 logic [31:0] Fetch_Reg_Mem_dout1, Fetch_Reg_PC_4, Fetch_Reg_PC;   
// Save the value of the output of the Memory module and PC+4 to the Fetch Register on negative clock
 always_ff @ (negedge CLOCK) begin
 
  if (RESET == 1'b1) begin
            FETCH_REG <= 3'b000;
        end
        else begin 
        FETCH_REG[0] <= Mem_dout1;
        FETCH_REG[1] <= PC_Plus_4;
        FETCH_REG[2] <= PC_Addr1;
    end 
    end
    
    // Reading from the Fetch register should happen on the positive edge of the clock 
    always_ff @ (posedge CLOCK) begin
        begin
            Fetch_Reg_Mem_dout1 <= FETCH_REG[0];
            Fetch_Reg_PC_4  <= FETCH_REG[1];
            Fetch_Reg_PC <= FETCH_REG[2];
        end
    end


 // --------------------------------- Decode State -----------------------------------------------
 // Modules in Decode State: Decoder, Register File, Immediate Generator, MUX A, MUX B
 // Connected to Decode State Register: Several outputs of Decoder, Output of Mux A/B, Several Outputs of Immediate Generator, and 
 // output of Memory dout 1 (output from Fetch Register: Fetch_Reg_Mem_dout1)

// --------------------------------- Decoder Setup -----------------------------------------------
// Wires: Outputs from Decoder to pass onto Decode State Register: regWrite, memWrite, memRead2, alu_fun, rf_wr_sel
 // 1-bit Wires 
 logic D_regWrite, D_memWrite, D_memRead2; 
 // 2-bit Wire
 logic [1:0] D_rf_wr_sel;
 // 4-bit Wire
 logic [3:0] D_alu_fun;
 
 // Wires to connect output of decoder to Mux A to serce as source select
 logic D_alu_srcA;
 logic [1:0] D_alu_srcB;
 
 // Use output from Fetch Register as input for Decoder
cu_decoder Decoder (.IR_FETCH_REG(Fetch_Reg_Mem_dout1), .ALU_FUN(D_alu_fun), .ALU_SOURCE_A(D_alu_srcA), .ALU_SOURCE_B(D_alu_srcB),
 .RF_WR_SEL(D_rf_wr_sel), .REG_WRITE(D_regWrite), .MEM_WRITE(D_memWrite), .MEM_READ_2(D_memRead2));

// --------------------------------- Register File Setup -----------------------------------------------
// Wires: Outputs of Regsiter File (labeled as rs1 and rs2 in diagram)
logic [31:0] RF_rs1, RF_rs2;

 // Use output from Fetch Register as input for Register File
 // OLD METHOD: 
//Register_File_HW_3 Register_File (.CLOCK(CLOCK), .input_reg(Fetch_Reg_Mem_dout1), .RF_RS1(RF_rs1), .RF_RS2(RF_rs2));

// NEW METHOD: Use wires from outputs in Writeback State
Register_File_HW_3 Register_File (.CLOCK(CLOCK), .WD(Mux_to_wd_Reg_File), .ENABLE(Memory_Reg_regWrite), .input_reg(Fetch_Reg_Mem_dout1),
 .RF_RS1(RF_rs1), .RF_RS2(RF_rs2), .WA(Memory_Reg_dout1[11:7]));


// --------------------------------- Immediate Generator Setup -----------------------------------------------
// Wire: Outputs of Immediate Generator to MUX A/B and Decode Register
logic [31:0] IG_U_type, IG_I_type, IG_S_type, IG_J_type, IG_B_type;

 // Use output from Fetch Register as input for Immediate Generator
Imm_Gen Immediate_Generator (.IR_INPUT(Fetch_Reg_Mem_dout1), .U_TYPE_OUT(IG_U_type), .I_TYPE_OUT(IG_I_type), .S_TYPE_OUT(IG_S_type), 
.J_TYPE_OUT(IG_J_type), .B_TYPE_OUT(IG_B_type));

// --------------------------------- MUX A Setup (2-input MUX) -----------------------------------------------
//Wire: Output of MUX A to Decode State Register
logic [31:0] MUX_A_Output;

// Uses rs1 output of Register File and U type output of Immediate Generator
ALU_MUX_srcA MUX_A (.REG_rs1(RF_rs1), .IMM_GEN_U_Type(IG_U_type), .alu_srcA(D_alu_srcA),.srcA(MUX_A_Output));

// --------------------------------- MUX B Setup (4-input MUX) -----------------------------------------------
//Wire: Output of MUX B to Decode State Register
logic [31:0] MUX_B_Output;

//Uses outputs of Immediate Generator, rs2 output of Register File, and PC output
ALU_MUX_srcB MUX_B (.REG_rs2(RF_rs2), .IMM_GEN_I_Type(IG_I_type), .IMM_GEN_S_Type(IG_S_type), .PC_OUT(Fetch_Reg_PC),
.alu_srcB(D_alu_srcB), .srcB(MUX_B_Output));


// OLD METHOD: Decode State Register used in Pipelined Processor
// New Method: Wire outputs from Decode State directly into Execute State (Execute State modulules are all asynchronous)
// Note: Only keep time-sensitive values in Decode State Register (PC, PC + 4)

//// --------------------------------- Decode State Register Setup  -----------------------------------------------
//// Registers: Will hold 3 single-bit outputs from the Decoder, 1 two-bit output from the Decoder, 1 four-bit output from the decoder,
//// and 7 32-bit outputs

//// 3 Single-bit registers (From Decoder output): regWrite output, memWrite output, memRead2 output
//logic [0:2] DECODE_REG_1;
//// Two 2-bit register (From Decoder output): rf_wr_sel
//logic [1:0] DECODE_REG_2;
//// One 4-bit register (From Decoder output): alu_fun out
//logic [3:0] DECODE_REG_4;
//// Seven 32-bit registers (From various outputs): PC, PC + 4, MUX A output, Fetch State Register Mem dout 1, MUX B output, I/J/B type outputs from Imediate Generator,
//// rs1/rs2 outputs
// NEW VALUES TO KEEP: PC, PC + 4
  logic [0:1] [31:0] DECODE_REG_32;

//// Save the value of the outputs to Decode Register on negative clock
 always_ff @ (negedge CLOCK) begin
 
    if (RESET == 1'b1) begin
//            DECODE_REG_1 <= 1'b0;
//            DECODE_REG_2  <= 1'b0;
//            DECODE_REG_4 <= 1'b0;
            DECODE_REG_32 <= 1'b0;
                 end
        else begin
// // Single-bit:
//        DECODE_REG_1[0] <= D_regWrite;
//        DECODE_REG_1[1] <= D_memWrite;
//        DECODE_REG_1[2] <= D_memRead2;
// // Double-bit:
//        DECODE_REG_2 <= D_rf_wr_sel;
// // 4-bit:
//        DECODE_REG_4 <= D_alu_fun;
// // 32-bit:
        DECODE_REG_32[0] <= Fetch_Reg_PC_4;
//        DECODE_REG_32[1] <= MUX_A_Output;
//        DECODE_REG_32[2] <= Fetch_Reg_Mem_dout1;
//        DECODE_REG_32[3] <= MUX_B_Output;
//        DECODE_REG_32[4] <= IG_I_type;
//        DECODE_REG_32[5] <= IG_J_type;
//        DECODE_REG_32[6] <= IG_B_type;
        DECODE_REG_32[1] <= Fetch_Reg_PC;
//        DECODE_REG_32[8] <= RF_rs1;
//        DECODE_REG_32[9] <= RF_rs2;
    end 
end
//// Wires: Outputs from Decode Register
// // Single-bit:
//    logic Decode_Reg_regWrite, Decode_Reg_memWrite, Decode_Reg_memRead2;
// // Double-bit:
//    logic [1:0] Decode_Reg_rf_wr_sel;
// // 4-bit:
//    logic [3:0] Decode_Reg_alu_fun;
// // 32-bit:
// NEW 32-BIT OUTPUTS: PC, PC + 4
//    logic [31:0] Decode_Reg_PC_4, Decode_Reg_PC, Decode_Reg_Mux_A_out, Decode_Reg_Mux_B_out, Decode_Reg_mem_dout1, Decode_Reg_I_type,
//     Decode_Reg_J_type, Decode_Reg_B_type, Decode_Reg_rs1, Decode_Reg_rs2;
logic [31:0] Decode_Reg_PC_4, Decode_Reg_PC;
    
//// Reading from the Decode register should happen on the positive edge of the clock 
    always_ff @ (posedge CLOCK) begin
//            Decode_Reg_regWrite <= DECODE_REG_1[0];
//            Decode_Reg_memWrite <= DECODE_REG_1[1];
//            Decode_Reg_memRead2 <= DECODE_REG_1[2];
//            Decode_Reg_rf_wr_sel <= DECODE_REG_2;
//            Decode_Reg_alu_fun <= DECODE_REG_4;
            Decode_Reg_PC_4 <= DECODE_REG_32[0];
//            Decode_Reg_Mux_A_out <= DECODE_REG_32[1];
//            Decode_Reg_mem_dout1 <= DECODE_REG_32[2];
//            Decode_Reg_Mux_B_out <= DECODE_REG_32[3];
//            Decode_Reg_I_type <= DECODE_REG_32[4];
//            Decode_Reg_J_type <= DECODE_REG_32[5];
//            Decode_Reg_B_type <= DECODE_REG_32[6];
            Decode_Reg_PC <= DECODE_REG_32[1];
//            Decode_Reg_rs1 <= DECODE_REG_32[8];
//            Decode_Reg_rs2 <= DECODE_REG_32[9];
    end

// --------------------------------- Execute State -----------------------------------------------
 // Modules in Execute State: Target Generator (Branch Address Generator), Branch Condition Generator, ALU
 // Connected to Execute State Register: memWrite, memRead, rf_wr_sel, regWrite, PC + 4, mem dout1, ALU output, rs2 
 
 
 // --------------------------------- Target Generator Setup -----------------------------------------------
// Takes in J/B/I type outputs from Decode State Register, as well as rs1 output and PC
// Uses wires in Fetch State to serve as inputs for 4x1 MUX outside PC 

// OLD TARGET GENERATOR:
//Branch_Addr_Gen_HW_5 Target_Gen (.PC_COUNT(Decode_Reg_PC), .J_INPUT(Decode_Reg_J_type), .B_INPUT(Decode_Reg_B_type), 
//.I_INPUT(Decode_Reg_I_type), .RS1_INPUT(Decode_Reg_rs1), .JALR_OUT(TG_Jalr_to_MUX), .JAL_OUT(TG_Jal_to_MUX), 
//.BRANCH_OUT(TG_Branch_to_MUX));

// NEW TARGET GENERATOR: 
Branch_Addr_Gen_HW_5 Target_Gen (.PC_COUNT(Decode_Reg_PC), .J_INPUT(IG_J_type), .B_INPUT(IG_B_type), 
.I_INPUT(IG_I_type), .RS1_INPUT(RF_rs1), .JALR_OUT(TG_Jalr_to_MUX), .JAL_OUT(TG_Jal_to_MUX), 
.BRANCH_OUT(TG_Branch_to_MUX));

 // --------------------------------- Branch Condition Generator Setup -----------------------------------------------
// Uses wire in Fetch State to serve as pcSource for 4x1 MUX outside PC

// OLD BRANCH CONDITION GENERATOR:
//Brand_Cond_Gen Branch_Condition_Generator (.REG_INPUTA(Decode_Reg_rs1), .REG_INPUTB(Decode_Reg_rs2),
//.DR_MEM_OUT(Decode_Reg_mem_dout1), .PC_SOURCE_OUT(BCG_PC_Source));

// NEW BRANCH CONDITION GENERATOR:
Brand_Cond_Gen Branch_Condition_Generator (.REG_INPUTA(RF_rs1), .REG_INPUTB(RF_rs2),
.DR_MEM_OUT(Fetch_Reg_Mem_dout1), .PC_SOURCE_OUT(BCG_PC_Source));
 // --------------------------------- ALU Setup -----------------------------------------------
 //Wires: Output of ALU
 logic [31:0] ALU_out;
 
 // Uses outputs of Mux A and MUX B from Decode State, as well as alu_fun
 // OLD ALU:
 //ALU_HW_4 ALU (.ALU_A(Decode_Reg_Mux_A_out), .ALU_B(Decode_Reg_Mux_B_out), .ALU_FUN(Decode_Reg_alu_fun), .RESULT(ALU_out));
 
 // NEW ALU:
  ALU_HW_4 ALU (.ALU_A(MUX_A_Output), .ALU_B(MUX_B_Output), .ALU_FUN(D_alu_fun), .RESULT(ALU_out));
 
  // --------------------------------- Execute State Register Setup -----------------------------------------------

// Three 1-bit inputs (Decode Register): memWrite, memRead2, regWrite
logic [0:2] EXECUTE_REG_1;

// Single 2-bit input (Decode Register): rf_wr_sel
logic [1:0] EXECUTE_REG_2;

// Four 32-bit inputs from various sources
logic [0:3] [31:0] EXECUTE_REG_32;

// Save the value of the outputs to Execute Register on negative clock
 always_ff @ (negedge CLOCK) begin
 
 if (RESET == 1'b1) begin
            EXECUTE_REG_1 <= 1'b0;
            EXECUTE_REG_2 <= 1'b0;
            EXECUTE_REG_32 <= 1'b0;
  end
  
  // OLD EXECUTE REGISTER SETUP:
//  else begin         
// // Single-bit:
//        EXECUTE_REG_1[0] <= Decode_Reg_memWrite;
//        EXECUTE_REG_1[1] <= Decode_Reg_memRead2;
//        EXECUTE_REG_1[2] <= Decode_Reg_regWrite;
// // Double-bit:
//        EXECUTE_REG_2 <= Decode_Reg_rf_wr_sel;
// // 32-bit:
//        EXECUTE_REG_32[0] <= Decode_Reg_PC_4;
//        EXECUTE_REG_32[1] <= Decode_Reg_mem_dout1;
//        EXECUTE_REG_32[2] <= Decode_Reg_rs2;
//        EXECUTE_REG_32[3] <= ALU_out;
//    end 

// NEW EXECUTE REGISTER SETUP: KEEP DECODE REGISTER PC + 4
 else begin         
 // Single-bit:
        EXECUTE_REG_1[0] <= D_memWrite;
        EXECUTE_REG_1[1] <= D_memRead2;
        EXECUTE_REG_1[2] <= D_regWrite;
 // Double-bit:
        EXECUTE_REG_2 <= D_rf_wr_sel;
 // 32-bit:
        EXECUTE_REG_32[0] <= Decode_Reg_PC_4;
        EXECUTE_REG_32[1] <= Fetch_Reg_Mem_dout1;
        EXECUTE_REG_32[2] <= RF_rs2;
        EXECUTE_REG_32[3] <= ALU_out;
    end 
    end

// Wires: Outputs from Execute Register
 // Single-bit:
    logic Execute_Reg_memWrite, Execute_Reg_memRead2, Execute_Reg_regWrite;
 // Double-bit:
    logic [1:0] Execute_Reg_rf_wr_sel;
 // 32-bit:
    logic [31:0] Execute_Reg_PC_4, Execute_Reg_mem_dout1, Execute_Reg_rs2, Execute_Reg_ALU_out;
    
// Reading from the Decode register should happen on the positive edge of the clock 
    always_ff @ (posedge CLOCK) begin
           Execute_Reg_memWrite <= EXECUTE_REG_1[0];
           Execute_Reg_memRead2 <= EXECUTE_REG_1[1];
           Execute_Reg_regWrite <= EXECUTE_REG_1[2];
           Execute_Reg_rf_wr_sel <= EXECUTE_REG_2;
           Execute_Reg_PC_4 <= EXECUTE_REG_32[0];
           Execute_Reg_mem_dout1 <= EXECUTE_REG_32[1];
           Execute_Reg_rs2 <= EXECUTE_REG_32[2];
           Execute_Reg_ALU_out <= EXECUTE_REG_32[3]; 
    end
    
    
// --------------------------------- Memory State -----------------------------------------------
// Modules in Memory State: Memory (Instantiated Previously in Fetch State)

// Wires to be connected to the previously instantiated Memory module:

// Wire: Output of Memory dout2. This signal will be carried into the Memory State Register
logic [31:0] mem_dout2;
// Will also pass the following wires to the Memory module in the Fetch State
//Execute_Reg_ALU_out, Execute_Reg_memRead2, Execute_Reg_memWrite, Execute_Reg_rs2, IOBUS_IN, IOBUS_WR, 

// OLD METHOD: Instantiate new Memory
//OTTER_mem_dualport Memory_2 (.MEM_ADDR2(Execute_Reg_ALU_out), .MEM_READ2(Execute_Reg_memRead2), .MEM_WRITE2(Execute_Reg_memWrite),
//.MEM_DIN2(Execute_Reg_rs2), .MEM_CLK(CLOCK), .IO_IN(IOBUS_IN), .IO_WR(IOBUS_WR), .MEM_DOUT2(mem_dout2));


// NEW METHOD: Feed outputs from Execute Register to Memory module instantiated in Fetch State. The main output of concern is dout2, which should be a valid output 
// when it is being chosen by the 4x1 Mux in the Writeback State

// Assign values of IOBUS_ADDR, IOBUS_OUT
assign IOBUS_OUT = Execute_Reg_rs2;
assign IOBUS_ADDR = Execute_Reg_ALU_out;

// --------------------------------- Memory State Register Setup  -----------------------------------------------
// Register: One Single-bit register (Output from Decode State)
logic MEMORY_REG_1;

// Register: One 2-bit register (Output from Decode State)
logic [1:0] MEMORY_REG_2;

// Register: Four 32-bit registers (Various Outputs) 
logic [0:3] [31:0] MEMORY_REG_32;

// Save the value of the outputs to Memory Register on negative clock
 always_ff @ (negedge CLOCK) begin
 
  if (RESET == 1'b1) begin
            MEMORY_REG_1 <= 0;
            MEMORY_REG_2 <= 1'b0;
            MEMORY_REG_32 <= 1'b0;

        end
        
        else begin
 // Single-bit:
        MEMORY_REG_1 <= Execute_Reg_regWrite;
 // Two-bit:
        MEMORY_REG_2 <= Execute_Reg_rf_wr_sel;
 // 32-bit:
        MEMORY_REG_32[0] <= Execute_Reg_ALU_out;
        MEMORY_REG_32[1] <= mem_dout2;
        MEMORY_REG_32[2] <= Execute_Reg_mem_dout1;
        MEMORY_REG_32[3] <= Execute_Reg_PC_4;
    end 
    end

// Reading from the Memory register should happen on the positive edge of the clock 
// Wires: Outputs from Memory Register
// Single-bit:
    logic Memory_Reg_regWrite;
// Two-bit:
    logic [1:0]Memory_Reg_rf_wr_sel;
// 32-bit:
    logic [31:0] Memory_Reg_ALU_out, Memory_Reg_mem_dout2, Memory_Reg_PC_4, Memory_Reg_dout1;
    
    always_ff @ (posedge CLOCK) begin
          Memory_Reg_regWrite <= MEMORY_REG_1;
          Memory_Reg_rf_wr_sel <= MEMORY_REG_2;
          Memory_Reg_ALU_out <= MEMORY_REG_32[0];
          Memory_Reg_mem_dout2 <= MEMORY_REG_32[1];
          Memory_Reg_dout1 <= MEMORY_REG_32[2];
          Memory_Reg_PC_4 <= MEMORY_REG_32[3];
        end
    
// --------------------------------- Writeback State -----------------------------------------------
// Modules in Writeback State: Register File (instantiated previously), 4x1 MUX Outside Register File

// --------------------------------- 4x1 MUX Setup  -----------------------------------------------
// Wire: 32-bit output of 4x1 MUX
logic [31:0] Mux_to_wd_Reg_File;
// Temporary Wire: Assign 0 to CSR_RD
logic [31:0] Mux_CSR_RD;
assign Mux_CSR_RD = 1'b0;
Reg_file_MUX Reg_File_4x1_MUX (.ALU_OUT(Memory_Reg_ALU_out), .MEM_DOUT_2(Memory_Reg_mem_dout2), .CSR_RD(Mux_CSR_RD)
, .PC_OUT(Memory_Reg_PC_4), .RF_WR_SEL(Memory_Reg_rf_wr_sel), .MUX_OUT(Mux_to_wd_Reg_File));

// OLD METHOD: 
//Register_File_HW_3 Register_File_2 (.CLOCK(CLOCK), .WD(Mux_to_wd_Reg_File), .ENABLE(Memory_Reg_regWrite));

// NEW METHOD: Feed wires from Memory Register into previously instantiated Register File in Decode State
// Wires to be fed into previously instantiated Register File:
// Mux_to_wd_Reg_File -> Fed into .WD of Register File
// Memory_Reg_dout1 -> Fed into .wa of Register File
// Memory_Reg_regWrite -> Fed into regWrite of Register File

endmodule
