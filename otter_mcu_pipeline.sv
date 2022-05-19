`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2022 11:44:17 AM
// Design Name: 
// Module Name: otter_mcu_pipeline
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


//Log:
//Need to put in the forwarding unit and other hazards zontrol
module otter_mcu_pipeline(
    input CLOCK,
    input INTR,
    input RESET,
    input [31:0] IOBUS_IN,
    output [31:0] IOBUS_OUT,
    output [31:0] IOBUS_ADDR,
    output IOBUS_WR);

//Initializations for Fetch-------------------------------------------------------------------------------
    // Inputs for PC and MUX
    logic  PC_WRITE;
    logic [1:0]PC_SOURCE;
    logic [31:0] MUX_JALR, MUX_BRANCH, MUX_JAL;
    logic IF_ID_Write;
        
    // Logic for MUX to PC
    logic [31:0] MUX_to_PC;
    
    // Output of PC, and incremented PC
    logic [31:0] PC_OUT, PC_PLUS_4;
    
    // Output of Memory
    logic [31:0] MEM_IR;
    
    // Input for MEM
    logic MEM_READ_1;
    
    // Set MEM_READ_1 as high
    assign MEM_READ_1 = 1'b1;
    
    // Outputs of Fetch register
    logic [31:0] FETCH_REG_OUT, FETCH_REG_PC, FETCH_REG_PC_4;
//Initiliazation for Decode-----------------------------------------------------------------------------
    // Inputs for register file
    logic ID_EX_Controls_Sel;
    
    // 32-bit outputs from Fetch Register
    logic [31:0] FR_MEM, FR_PC, FR_PC_4;
        
    // Wires for outputs of Decoder that go to Decode Register
    logic REGWRITE_TO_DR, MEMWRITE_TO_DR, MEMREAD2_TO_DR;
    logic [3:0] ALU_FUN_TO_DR;
    logic [1:0] RF_WR_SEL_TO_DR;
    
    // Wires for outputs of Decoder that are used internally in the module
    logic ALU_A;
    logic [1:0] ALU_B;
    
    // Wires for outputs of Register File
    logic [31:0] REG_FILE_RS1, REG_FILE_RS2;
    
    // Wires for outptuts of Immediate Generator
    logic [31:0] U_TYPE, I_TYPE, S_TYPE, J_TYPE, B_TYPE;
    
    // Wires for output of MUXes to enter Decoder Register
    logic [31:0] ALU_A_TO_DR, ALU_B_TO_DR;
    
    logic [2:0] ID_EX_Controls; // ID_EX_Controls[0] -> regWrite 
                                // ID_EX_Controls[1] -> memWrite 
                                // ID_EX_Controls[2] -> memRead2
    
    // Outputs of Decode register 
    logic [31:0] DEC_PC_OUT, DEC_ALU_A, DEC_ALU_B, DEC_J_TYPE, DEC_B_TYPE, DEC_I_TYPE, DEC_MEM_IR, DEC_RS1, DEC_RS2;
    logic [3:0] DEC_ALU_FUN;
    logic DEC_REGWRITE, DEC_MEMWRITE, DEC_MEMREAD_2;
    logic [1:0] DEC_RF_WR_SEL;
    logic [4:0] ID_EX_RS1, ID_EX_RS2, ID_EX_RD;
    
//Initialization for Execute--------------------------------------------------------------------------------
// Inputs for Branch Address Generator
    logic [31:0] DR_J_TYPE, DR_B_TYPE, DR_I_TYPE;
// Inputs for Target Gen and Branch Condition Generator + ALU
    logic [31:0] DR_PC_MEM;    //(Current PC)
    logic [31:0] DR_RS1;
// Input for Branch Condition Generator + ALU
    logic [31:0] DR_RS2;
// Input for ALU
    logic [31:0] DR_ALU_FUN, DR_ALU_A, DR_ALU_B;

// Inputs to pass directly into Execute register
    logic DR_REG_WRITE, DR_MEM_WRITE, DR_MEM_READ2;
    logic [1:0] DR_RF_WR_SEL;
    logic [31:0] DR_PC_4;
    
//    logic [4:0] ID_EX_RD;
    
   // Input for overriding ALU Input
    logic [1:0] OVERRIDE_A;
    logic [1:0] OVERRIDE_B;
    
    logic [31:0] Forward1, Forward2;
    
// Logics for outputs of ALU and rs2
    logic [31:0] ALU_OUT_TO_REG;
    
    logic [31:0] FINAL_ALU_A, FINAL_ALU_B;

// Outputs for Target Gen + Branch Condititon Generator
    logic [31:0] JALR_TO_PC, BRANCH_TO_PC, JAL_TO_PC;
    logic [1:0] PCSOURCE_TO_PC;
    
// Outputs of Execute register
    logic [31:0] EXEC_PC_4, EXEC_PC_MEM, EXEC_ALU_RESULT, EXEC_RS2;
    logic [1:0] EXEC_RF_WR_SEL;
    logic EXEC_REGWRITE, EXEC_MEMWRITE, EXEC_MEMREAD2;
    
    logic [4:0] EX_MS_RD;
//Initiliazation for Memory----------------------------------------------------------------------------------
// Inputs from Execute register
    logic ER_memWrite, ER_memRead2, ER_REG_WRITE;
    logic [31:0] ER_PC_MEM, ER_PC_4, ER_ALU_OUT, ER_RS2;
    logic [1:0] ER_RF_WR_SEL;
    
//    logic [4:0] EX_MS_RD;

// Output for IOBUS_ADDR, IOBUS_OUT, IOBUS_WR
    logic [31:0] IOBUS_ADDR, IOBUS_OUT, IOBUS_WR;

// Wire for Memory dout2
    logic [31:0] DOUT2_TO_MEM_REG;
    
// Outputs of Memory register
    logic [31:0] MEM_REG_DOUT2, MEM_REG_ALU_RESULT, MEM_REG_IR, MEM_REG_PC_4;
    logic [1:0] MEM_RF_WR_SEL;
    logic MEM_REG_WRITE;
    logic [4:0] MS_WB_RD;

//Initializaion for Writeback---------------------------------------------------------------------------------  
// Inputs from Memory register
    logic [31:0] MR_dout2, MR_alu_result, MR_ir, MR_PC_4;
    logic [1:0] MR_rf_wr_sel;
    logic MR_regWrite;
    
    // For now, assign CSR register to 0
    logic CSR_temp;
    assign CSR_temp = 1'b0;
    
    // Wire for MUX Output
    logic [31:0] MUX_OUT_TO_REG_FILE;  


//Fetch
// --------------------------------- Program Counter Setup----------------------------------------
    // Incrementer for Program Count (PC + 4)
    PC_4 PC_Increment (.Program_count(PC_OUT), .PC_4(PC_PLUS_4));
    
    // Program Count setup 
    Program_Counter MyCounter (.pc_write(PC_WRITE), .pc_rst(RESET),
    .pc_clk(CLOCK), .PC_DIN(MUX_to_PC), .PC_CNT(PC_OUT));

    // 4 Option MUX
    PC_MUX Prog_Count_MUX (.MUX_SEL(PC_SOURCE), .PC_4(PC_PLUS_4), .JALR(MUX_JALR),
    .BRANCH(MUX_BRANCH), .JAL(MUX_JAL), .MUX_OUT(MUX_to_PC));

    //----------------------------------- Memory Setup -----------------------------------------------
    
    // Memory Module setup (only look at bits [15:2] of the output for PC
    Memory Mem_Module (.MEM_CLK(CLOCK), .MEM_ADDR1(PC_OUT[15:2]), .MEM_RDEN1(MEM_READ_1), .MEM_DOUT1(MEM_IR));
    
    // Fetch Register for Pipeline Setup (write output of Memory to Fetch Register on negative clock cycle)
    
    // Initialize FETCH_REG to hold three values: PC, incremented PC and output of Memory
    logic [0:2][31:0]FETCH_REG;
    
    // Save the value of the output of the Memory module and PC+4 to the Fetch Register on negative clock cycle
    always_ff @ (negedge CLOCK) begin
        FETCH_REG[0] <= MEM_IR;
        FETCH_REG[1] <= PC_OUT;
        FETCH_REG[2] <= PC_PLUS_4;
    end 
    
    // Reading from the Fetch register should happen on the positive edge of the clock 
    always_ff @ (posedge CLOCK) begin
        if (RESET == 1'b1) begin
            FETCH_REG <= 3'b000;
        end
        else if (IF_ID_Write != 0)begin
            FETCH_REG_OUT <= FETCH_REG[0];
            FETCH_REG_PC <= FETCH_REG[1];
            FETCH_REG_PC_4 <= FETCH_REG[2];
        end
    end

//Decode
 // ----------------------------------- Decoder Setup -----------------------------------------------
    
    cu_decoder Decoder (.IR_FETCH_REG(FR_MEM), .ALU_FUN(ALU_FUN_TO_DR), .ALU_SOURCE_A(ALU_A), .ALU_SOURCE_B(ALU_B), 
    .RF_WR_SEL(RF_WR_SEL_TO_DR), .REG_WRITE(REGWRITE_TO_DR), .MEM_WRITE(MEMWRITE_TO_DR), .MEM_READ_2(MEMREAD2_TO_DR));
    
    // ----------------------------------- Register File Setup -----------------------------------------------
    
   Register_File_HW_3 Reg_File (.CLOCK(CLOCK), .input_reg(FR_MEM), .RF_RS1(REG_FILE_RS1), .RF_RS2(REG_FILE_RS2));
   
       // ----------------------------------- Immediate Generator Setup -----------------------------------------------
       
   Imm_Gen IG (.IR_INPUT(FR_MEM), .U_TYPE_OUT(U_TYPE), .I_TYPE_OUT(I_TYPE), .S_TYPE_OUT(S_TYPE), .J_TYPE_OUT(J_TYPE),
   .B_TYPE_OUT(B_TYPE));

       // ----------------------------------- ALU_A Setup -----------------------------------------------
   
   ALU_MUX_srcA MUX_A (.REG_rs1(REG_FILE_RS1), .IMM_GEN_U_Type(U_TYPE), .alu_srcA(ALU_A), .srcA(ALU_A_TO_DR));
   
   // ----------------------------------- ALU_B Setup -----------------------------------------------
   
   ALU_MUX_srcB MUX_B (.REG_rs2(REG_FILE_RS2), .IMM_GEN_I_Type(I_TYPE), .IMM_GEN_S_Type(S_TYPE), .PC_OUT(FR_PC),
   .alu_srcB(ALU_B), .srcB(ALU_B_TO_DR));

   // ----------------------------------- Hazard Detection MUX Setup -----------------------------------------------
    Mult2to1 MUX_HDU( .In1(0), .In2({REGWRITE_TO_DR, MEMWRITE_TO_DR, MEMREAD2_TO_DR}), .Sel(ID_EX_Controls_Sel),
    .Out(ID_EX_Controls));
   
   // ----------------------------------- Decode Register Setup -----------------------------------------------
   
    // Initialize DECODE_REG to hold ten values: 32-bit: Incremented PC from Fetch register, Output of ALU_A,
    // Output of Fetch register, Output of ALU_B, J-type output of Immediate Generator, B-Type output of Immediate Generator
    // I-Type output of Immediate Generator
    // Single bit values: Outputs from decoder : regWrite, memWrite, memRead2
    // 4-bit value: Output from decoder: alu_fun
    // 2-bit value: Output from decoder: rf_wr_sel
    
    logic [0:8][31:0]DECODE_REG_1; // 32-bit values
    logic [0:2]DECODE_REG_2;  // Single-bit values
    logic [3:0]DECODE_REG_3;       // 4-bit value
    logic [1:0]DECODE_REG_4;       // 2-bit value
    logic [2:0][4:0]DECODE_REG_5;
    
    // Save the various outputs on the negative edge of the clock cycle
    always_ff @ (negedge CLOCK) begin
    if (RESET == 1'b1) begin
        DECODE_REG_1 <= 0;
        DECODE_REG_2 <= 0;
        DECODE_REG_3 <= 0;
        DECODE_REG_4 <= 0;
        DECODE_REG_5 <= 0;
    end
    else begin     
        // 32-bit values
        DECODE_REG_1[0] <= FR_PC_4 ;
        DECODE_REG_1[1] <= ALU_A_TO_DR;
        DECODE_REG_1[2] <= FR_MEM;
        DECODE_REG_1[3] <= ALU_B_TO_DR;
        DECODE_REG_1[4] <= J_TYPE;
        DECODE_REG_1[5] <= B_TYPE;
        DECODE_REG_1[6] <= I_TYPE;
        DECODE_REG_1[7] <= REG_FILE_RS1;
        DECODE_REG_1[8] <= REG_FILE_RS2;
        
        // Single-bit values
        DECODE_REG_2[0] <= REGWRITE_TO_DR;
        DECODE_REG_2[1] <= MEMWRITE_TO_DR;
        DECODE_REG_2[2] <= MEMREAD2_TO_DR;
        
        // 4-bit value
        DECODE_REG_3 <= ALU_FUN_TO_DR;
        
        // 2-bit value
        DECODE_REG_4 <= RF_WR_SEL_TO_DR;
        
        DECODE_REG_5[0] <= FR_MEM[19:15];
        DECODE_REG_5[1] <= FR_MEM[24:20];
        DECODE_REG_5[2] <= FR_MEM[11:7];
               
        end
    end
    
    // Reading from the Fetch register should happen on the positive edge of the clock 
    always_ff @ (posedge CLOCK) begin
    
    // 32-bit reads
    DEC_PC_OUT <= DECODE_REG_1[0];
    DEC_ALU_A  <= DECODE_REG_1[1];
    DEC_MEM_IR <= DECODE_REG_1[2];
    DEC_ALU_B  <= DECODE_REG_1[3];
    DEC_J_TYPE <= DECODE_REG_1[4];
    DEC_B_TYPE <= DECODE_REG_1[5];
    DEC_I_TYPE <= DECODE_REG_1[6];
    DEC_RS1 <= DECODE_REG_1[7];
    DEC_RS2 <= DECODE_REG_1[8];

    
    // Single-bit reads
    DEC_REGWRITE  <= ID_EX_Controls[3];
    DEC_MEMWRITE  <= ID_EX_Controls[2];
    DEC_MEMREAD_2 <= ID_EX_Controls[1];
    
    // 4-bit read
    DEC_ALU_FUN <= DECODE_REG_3;
    
    // 2-bit read
    DEC_RF_WR_SEL <= DECODE_REG_4;
    
    ID_EX_RS1 <= DECODE_REG_5[0];
    ID_EX_RS2 <= DECODE_REG_5[1];
    ID_EX_RD <= DECODE_REG_5[2];

    end

//Execute
    // ----------------------------------- Target Gen Setup -----------------------------------------------
    Branch_Addr_Gen_HW_5 Target_Gen (.PC_COUNT(DR_PC_MEM), .J_INPUT(DR_J_TYPE), .B_INPUT(DR_B_TYPE), .I_INPUT(DR_I_TYPE),
                                    .RS1_INPUT(DR_RS1), .JALR_OUT(JALR_TO_PC), .BRANCH_OUT(BRANCH_TO_PC), .JAL_OUT(JAL_TO_PC));
   
    // ----------------------------------- Branch Cond. Gen Setup -----------------------------------------------
    Brand_Cond_Gen BC_Generator (.REG_INPUTA(DR_RS1), .REG_INPUTB(DR_RS2), .DR_MEM_OUT(DR_PC_MEM), .PC_SOURCE_OUT(PCSOURCE_TO_PC));
    
    // ----------------------------------- ALU_A Override Setup -----------------------------------------------

    Mult4to1 MUX_OVERRIDE_A (.In1(DR_ALU_A), .In2(Forward1), .In3(Forward2),
    .In4(), .Sel(OVERRIDE_A ), .Out(FINAL_ALU_A));

     // ----------------------------------- ALU_B Override Setup -----------------------------------------------
  
    Mult4to1 MUX_OVERRIDE_B (.In1(DR_ALU_B), .In2(Forward1), .In3(Forward2),
    .In4(), .Sel(OVERRIDE_B), .Out(FINAL_ALU_B));

    // ----------------------------------- ALU Setup -----------------------------------------------
    ALU_HW_4 Execute_ALU (.ALU_A(FINAL_ALU_A), .ALU_B(FINAL_ALU_B), .ALU_FUN(DR_ALU_FUN), .RESULT(ALU_OUT_TO_REG));

    // ----------------------------------- Execute Register Setup -----------------------------------------------
    // Initalize Execute Register to hold the following values:
    // 32-bit: PC+4 from Decode register, DOUT1 from Decode register, ALU output, rs2 from Decode register
    // 2-bit: rf_wr_sel from Decode register
    // 1-bit from Decode register: regWrite, memWrite, memRead2
    
    logic [0:3][31:0]EXECUTE_REG_1;  // 32-bit values
    logic [1:0] EXECUTE_REG_2;  // 2-bit value
    logic [0:2]EXECUTE_REG_3;  // 1-bit values
    logic [4:0] EXECUTE_REG_4;
    
      // Save the various outputs on the negative edge of the clock cycle
    always_ff @ (negedge CLOCK) begin
    if (RESET == 1'b1) begin
        EXECUTE_REG_1 <= 0;
        EXECUTE_REG_2 <= 0;
        EXECUTE_REG_3 <= 0;
        EXECUTE_REG_4 <= 0;
    end
    else begin
        // 32-bit values
        EXECUTE_REG_1[0] <= DR_PC_4 ;       // PC + 4 from Decode register
        EXECUTE_REG_1[1] <= DR_PC_MEM;      // DOUT 1 from Decode register
        EXECUTE_REG_1[2] <= ALU_OUT_TO_REG; // ALU Output   
        EXECUTE_REG_1[3] <= DR_RS2;         // rs2 from Decode register
        
        // 2- bit value
        EXECUTE_REG_2 <= DR_RF_WR_SEL;       // RF_WR_SEL from Decode register
        
        // 1-bit values
        EXECUTE_REG_3[0] <= DR_REG_WRITE;    // regWrite from Decode register
        EXECUTE_REG_3[1] <= DR_MEM_WRITE;    // memWrite from Decode register
        EXECUTE_REG_3[2] <= DR_MEM_READ2;    // memRead2 from Decode register
        
        EXECUTE_REG_4 <= ID_EX_RD; 
        end
    end
    
     // Reading from the Fetch register should happen on the positive edge of the clock 
    always_ff @ (posedge CLOCK) begin
        
        // 32-bit reads
        EXEC_PC_4 <= EXECUTE_REG_1[0];
        EXEC_PC_MEM <= EXECUTE_REG_1[1];
        EXEC_ALU_RESULT <= EXECUTE_REG_1[2];
        EXEC_RS2 <= EXECUTE_REG_1[3];
        
        // 2-bit reads
        EXEC_RF_WR_SEL <= EXECUTE_REG_2;
        
        // 1-bit reads
        EXEC_REGWRITE <= EXECUTE_REG_3[0];
        EXEC_MEMWRITE <= EXECUTE_REG_3[1];
        EXEC_MEMREAD2 <= EXECUTE_REG_3[2];
        
        EX_MS_RD <= EXECUTE_REG_4;
    end

//Memory-----------------------------------------------------------------------------------------------------------------
 //----------------------------------- Memory Setup -----------------------------------------------
    
    // Memory Module setup 
//    Memory Mem_Module (.MEM_ADDR2(ER_ALU_OUT), .MEM_DIN2(ER_RS2), .MEM_WE2(ER_memWrite), .MEM_RDEN2(ER_memRead2), 
//                       .MEM_SIZE(ER_PC_MEM[14:12]), .IO_WR(IOBUS_WR), .MEM_DOUT2(DOUT2_TO_MEM_REG)); (already declared)
    // Still need to assign IOBUS_IN
    
     // Taking care of IOBUS.....
     assign IOBUS_ADDR = ER_ALU_OUT;
     assign IOBUS_OUT = ER_RS2;

    // ----------------------------------- Memory Register Setup -----------------------------------------------
    // Initalize Memory Register to hold the following values:
    // 32-bit: ALU result from Execute register, DOUT2 from Memory module, Current PC from Execute Register, PC + 4 from 
    // Execute register
    // 2-bit: rf_wr_sel from Execute register
    // 1-bit: regWrite from Execute register
    
    logic [0:3][31:0]MEMORY_REG_1;  // 32-bit values
    logic [1:0] MEMORY_REG_2;        // 2-bit value
    logic MEMORY_REG_3;              // 1-bit value
    logic [4:0] MEMORY_REG_4;
    
    // Save the various outputs on the negative edge of the clock cycle
    always_ff @ (negedge CLOCK) begin
        if(RESET == 1'b1) begin
        MEMORY_REG_1 <= 0;
        MEMORY_REG_2 <= 0;
        MEMORY_REG_3 <= 0;
        MEMORY_REG_4 <= 0;
    end
    else begin
        // 32-bit values
        MEMORY_REG_1[0] <= ER_PC_4 ;              // PC + 4 from Execute register
        MEMORY_REG_1[1] <= DOUT2_TO_MEM_REG;      // DOUT2 from Memory module
        MEMORY_REG_1[2] <= ER_ALU_OUT;            // ALU Output from Execute register   
        MEMORY_REG_1[3] <= ER_PC_MEM;                // Current PC from Execute register
        
        // 2-bit value
        MEMORY_REG_2 <= ER_RF_WR_SEL;
        
        // 1-bit value
        MEMORY_REG_3 <= ER_REG_WRITE;
        
        MEMORY_REG_4 <= EX_MS_RD;
        end
    end
    
     // Reading from the Fetch register should happen on the positive edge of the clock 
    always_ff @ (posedge CLOCK) begin
        // 32-bit reads
        MEM_REG_PC_4 <= MEMORY_REG_1[0];
        MEM_REG_DOUT2 <=  MEMORY_REG_1[1];
        MEM_REG_ALU_RESULT <= MEMORY_REG_1[2];
        MEM_REG_IR <= MEMORY_REG_1[3];
        
        // 2-bit read
        MEM_RF_WR_SEL <= MEMORY_REG_2;
        
        //1-bit read
        MEM_REG_WRITE <= MEMORY_REG_3;
        
        MS_WB_RD <= MEMORY_REG_4;
    end

//WriteBack
    // ----------------------------------- Register File MUX -----------------------------------------------
    Reg_file_MUX Reg_MUX (.ALU_OUT(MR_alu_result), .MEM_DOUT_2(MR_dout2), .CSR_RD(CSR_temp), .PC_OUT(MR_PC_4),
    .RF_WR_SEL(MR_rf_wr_sel));
    
     // ----------------------------------- Register File Setup -----------------------------------------------
    
//   Register_File_HW_3 Reg_File (.WD(MUX_OUT_TO_REG_FILE), .ENABLE(MR_regWrite)); (already declared
   
endmodule 