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


module otter_mcu_pipeline(
    input CLOCK,
    input INTR,
    input RESET,
    input [31:0] IOBUS_IN,
    output [31:0] IOBUS_OUT,
    output [31:0] IOBUS_ADDR,
    output IOBUS_WR);

// ---------------------------------------------- FETCH Stage ---------------------------------------------- 
    logic  PC_WRITE;
    logic [1:0]PC_SOURCE;
    logic [31:0] MUX_JALR, MUX_BRANCH, MUX_JAL;
    logic IF_ID_Write;
    logic [31:0] MUX_to_PC;  
    logic [31:0] PC_OUT, PC_PLUS_4;
    logic [31:0] MEM_IR;
    logic MEM_READ_1;
    
    // Set to 1
    assign MEM_READ_1 = 1'b1;
//    assign PC_WRITE = 1;
//    assign IF_ID_Write = 1;

    // Fetch stage registers
    logic [31:0] FETCH_REG_OUT, FETCH_REG_PC, FETCH_REG_PC_4;
    
    // Incrementer for Program Count (PC + 4)
    PC_4 PC_Increment (.Program_count(PC_OUT), .PC_4(PC_PLUS_4));
    
    // Program Count setup 
    Program_Counter MyCounter (.pc_write(PC_WRITE), .pc_rst(RESET),
    .pc_clk(CLOCK), .PC_DIN(MUX_to_PC), .PC_CNT(PC_OUT));

    // 4 Option MUX
    PC_MUX Prog_Count_MUX (.MUX_SEL(PCSOURCE_TO_PC), .PC_4(PC_PLUS_4), .JALR(MUX_JALR),
    .BRANCH(MUX_BRANCH), .JAL(MUX_JAL), .MUX_OUT(MUX_to_PC));

    always_ff @ (posedge CLOCK) begin
        if (RESET == 1'b1) begin
            FETCH_REG_OUT <= 0;
            FETCH_REG_PC <= 0;
            FETCH_REG_PC_4 <= 0;
        end
        else if (IF_ID_Write != 0)begin
            FETCH_REG_OUT <= MEM_IR;
            FETCH_REG_PC <= PC_OUT;
            FETCH_REG_PC_4 <= PC_PLUS_4;
        end
    end
   
// ---------------------------------------------- DECODE Stage ---------------------------------------------- 
    logic ID_EX_Controls_Sel;
    logic REGWRITE_TO_DR, MEMWRITE_TO_DR, MEMREAD2_TO_DR;
    logic [1:0] RF_WR_SEL_TO_DR;
    logic ALU_A;
    logic [1:0] ALU_B;
    logic [31:0] REG_FILE_RS1, REG_FILE_RS2;
    logic [31:0] U_TYPE, I_TYPE, S_TYPE, J_TYPE, B_TYPE;
    logic [31:0] ALU_A_TO_DR, ALU_B_TO_DR;
    logic [2:0] ID_EX_Controls; // ID_EX_Controls[0] -> regWrite 
                                // ID_EX_Controls[1] -> memWrite 
                                // ID_EX_Controls[2] -> memRead2
    
    // Decode stage registers
    logic [31:0] DEC_PC_OUT, DEC_PC_4, DEC_ALU_A, DEC_ALU_B, DEC_J_TYPE, DEC_B_TYPE, DEC_I_TYPE, DEC_MEM_IR, DEC_RS1, DEC_RS2;
    logic [3:0] DEC_ALU_FUN;
    logic DEC_REGWRITE, DEC_MEMWRITE, DEC_MEMREAD2;
    logic [1:0] DEC_RF_WR_SEL;
    logic [4:0] ID_EX_RS1, ID_EX_RS2, ID_EX_RD;
 
    cu_decoder Decoder (.IR_FETCH_REG(FETCH_REG_OUT), .ALU_FUN(DR_ALU_FUN), .ALU_SOURCE_A(ALU_A), .ALU_SOURCE_B(ALU_B), 
    .RF_WR_SEL(RF_WR_SEL_TO_DR), .REG_WRITE(REGWRITE_TO_DR), .MEM_WRITE(MEMWRITE_TO_DR), .MEM_READ_2(MEMREAD2_TO_DR));
    
   Imm_Gen IG (.IR_INPUT(FETCH_REG_OUT), .U_TYPE_OUT(U_TYPE), .I_TYPE_OUT(I_TYPE), .S_TYPE_OUT(S_TYPE), .J_TYPE_OUT(J_TYPE),
   .B_TYPE_OUT(B_TYPE));
   
   ALU_MUX_srcA MUX_A (.REG_rs1(REG_FILE_RS1), .IMM_GEN_U_Type(U_TYPE), .alu_srcA(ALU_A), .srcA(ALU_A_TO_DR));
      
   ALU_MUX_srcB MUX_B (.REG_rs2(REG_FILE_RS2), .IMM_GEN_I_Type(I_TYPE), .IMM_GEN_S_Type(S_TYPE), .PC_OUT(FETCH_REG_PC),
                       .alu_srcB(ALU_B), .srcB(ALU_B_TO_DR));
    
    // Hazard Detection MUX Setup
   Mult2to1 MUX_HDU( .In1(0), .In2({REGWRITE_TO_DR, MEMWRITE_TO_DR, MEMREAD2_TO_DR}),
                     .Sel(ID_EX_Controls_Sel), .Out(ID_EX_Controls));
                     
   Hazard_Detector HDU (.ID_EX_MemRead(Decoder_memRead2),
                        .IF_ID_RS1(FETCH_REG_OUT[19:15]), .IF_ID_RS2(FETCH_REG_OUT [24:20]), .ID_EX_RS2(ID_EX_RS2),
                        .select(ID_EX_Controls_Sel), .PCWrite(PC_WRITE), .IF_ID_Write(IF_ID_Write));
                           
    always_ff @ (posedge CLOCK) begin
        if (RESET == 1'b1) begin
            DEC_PC_OUT <= 0;
            DEC_ALU_A  <= 0;
            DEC_MEM_IR <= 0;
            DEC_ALU_B  <= 0;
            DEC_J_TYPE <= 0;
            DEC_B_TYPE <= 0;
            DEC_I_TYPE <= 0;
            DEC_RS1 <= 0;
            DEC_RS2 <= 0;
            
            DEC_REGWRITE  <= 0;
            DEC_MEMWRITE  <= 0;
            DEC_MEMREAD2 <= 0;
            
            DEC_ALU_FUN <= 0;
            
            DEC_RF_WR_SEL <= 0;
            
            ID_EX_RS1 <= 0;
            ID_EX_RS2 <= 0;
            ID_EX_RD <= 0;            
        end
        else begin
            DEC_PC_OUT <= FETCH_REG_PC;
            DEC_PC_4 <= FETCH_REG_PC_4;
            DEC_ALU_A  <= ALU_A_TO_DR;
            DEC_MEM_IR <= FETCH_REG_OUT;
            DEC_ALU_B  <= ALU_B_TO_DR;
            DEC_J_TYPE <= J_TYPE;
            DEC_B_TYPE <= B_TYPE;
            DEC_I_TYPE <= I_TYPE;
            DEC_RS1 <= REG_FILE_RS1;
            DEC_RS2 <= REG_FILE_RS2;
            
            DEC_REGWRITE  <= ID_EX_Controls[2];
            DEC_MEMWRITE  <= ID_EX_Controls[1];
            DEC_MEMREAD2 <= ID_EX_Controls[0];
            
            DEC_ALU_FUN <= DR_ALU_FUN;
            
            DEC_RF_WR_SEL <= RF_WR_SEL_TO_DR;
            
            ID_EX_RS1 <= FETCH_REG_OUT[19:15];
            ID_EX_RS2 <= FETCH_REG_OUT[24:20];
            ID_EX_RD <= FETCH_REG_OUT[11:7];
        end
    end
    
    
  // ---------------------------------------------- EXECUTE Stage ---------------------------------------------- 
    logic [1:0] OVERRIDE_A;
    logic [1:0] OVERRIDE_B;
    logic [31:0] Forward1, Forward2;

    logic [31:0] ALU_OUT_TO_REG;
    
    logic [31:0] FINAL_ALU_A, FINAL_ALU_B;

    logic [31:0] JALR_TO_PC, BRANCH_TO_PC, JAL_TO_PC;
    logic [1:0] PCSOURCE_TO_PC;
    
    // Execute stage reigsters
    logic [31:0] EXEC_PC_4, EXEC_PC_MEM, EXEC_ALU_RESULT, EXEC_RS2;
    logic [1:0] EXEC_RF_WR_SEL;
    logic EXEC_REGWRITE, EXEC_MEMWRITE, EXEC_MEMREAD2;
    logic [4:0] EX_MS_RD;
        
    Branch_Addr_Gen_HW_5 Target_Gen (.PC_COUNT(DEC_PC_OUT), .J_INPUT(DEC_J_TYPE), .B_INPUT(DEC_B_TYPE), .I_INPUT(DEC_I_TYPE),
                                    .RS1_INPUT(DEC_RS1), .JALR_OUT(JALR_TO_PC), .BRANCH_OUT(BRANCH_TO_PC), .JAL_OUT(JAL_TO_PC));
   
    Brand_Cond_Gen BC_Generator (.REG_INPUTA(DEC_RS1), .REG_INPUTB(DEC_RS2), .DR_MEM_OUT(DEC_MEM_IR), .PC_SOURCE_OUT(PCSOURCE_TO_PC));
    
    Forward_Unit FU ( .ID_EX_RS1(ID_EX_RS1), .ID_EX_RS2(ID_EX_RS2),
                    .EX_MS_RD(EX_MS_RD), .MS_WB_RD(MS_WB_RD),
                    .A_override(OVERRIDE_A), .B_override(OVERRIDE_B),
                    .EX_MS_regWrite(EXEC_REGWRITE), .MS_WB_regWrite(MEM_REG_WRITE));
                        
    Mult4to1 MUX_OVERRIDE_A (.In1(DEC_ALU_A), .In2(MEM_REG_ALU_RESULT), .In3(EXEC_ALU_RESULT),
                             .In4(), .Sel(OVERRIDE_A), .Out(FINAL_ALU_A));
  
    Mult4to1 MUX_OVERRIDE_B (.In1(DEC_ALU_B), .In2(MEM_REG_ALU_RESULT), .In3(EXEC_ALU_RESULT),
                             .In4(), .Sel(OVERRIDE_B), .Out(FINAL_ALU_B));

    ALU_HW_4 Execute_ALU (.ALU_A(FINAL_ALU_A), .ALU_B(FINAL_ALU_B), .ALU_FUN(DEC_ALU_FUN), .RESULT(ALU_OUT_TO_REG));
    
    always_ff @ (posedge CLOCK) begin
        if (RESET == 1'b1) begin
            EXEC_PC_4 <= 0;
            EXEC_PC_MEM <= 0;
            EXEC_ALU_RESULT <= 0;
            EXEC_RS2 <= 0;
            
            EXEC_RF_WR_SEL <= 0;
            
            EXEC_REGWRITE <= 0;
            EXEC_MEMWRITE <= 0;
            EXEC_MEMREAD2 <= 0;
            
            EX_MS_RD <= 0;
        end
        else begin
            EXEC_PC_4 <= DEC_PC_4;
            EXEC_PC_MEM <= DEC_MEM_IR;
            EXEC_ALU_RESULT <= ALU_OUT_TO_REG;
            EXEC_RS2 <= DEC_RS2;
            
            EXEC_RF_WR_SEL <= DEC_RF_WR_SEL;
            
            EXEC_REGWRITE <= DEC_REGWRITE;
            EXEC_MEMWRITE <= DEC_MEMWRITE;
            EXEC_MEMREAD2 <= DEC_MEMREAD2;
            
            EX_MS_RD <= ID_EX_RD;
        end      
    end
    
//----------------------------------- MEMORY Stage ----------------------------------------------- 
    // Memory stage registers
    logic [31:0] MEM_REG_DOUT2, MEM_REG_ALU_RESULT, MEM_REG_IR, MEM_REG_PC_4;
    logic [1:0] MEM_RF_WR_SEL;
    logic MEM_REG_WRITE;
    logic [4:0] MS_WB_RD;
    logic [31:0] DOUT2_TO_MEM_REG;
    
    // For now, assign CSR register to 0
    logic CSR_temp;
    assign CSR_temp = 1'b0;
    
     assign IOBUS_ADDR = EXEC_ALU_RESULT;
     assign IOBUS_OUT = EXEC_RS2;
    
    always_ff @ (posedge CLOCK) begin
        if (RESET == 1'b1) begin
            MEM_REG_PC_4 <= 0;
            MEM_REG_DOUT2 <= 0;
            MEM_REG_ALU_RESULT <= 0;
            MEM_REG_IR <= 0;
            
            MEM_RF_WR_SEL <= 0;
            
            MEM_REG_WRITE <= 0;
            
            MS_WB_RD <= 0;
        end
        else begin
            MEM_REG_PC_4 <= EXEC_PC_4;
            MEM_REG_DOUT2 <=  DOUT2_TO_MEM_REG;
            MEM_REG_ALU_RESULT <= EXEC_ALU_RESULT;
            MEM_REG_IR <= EXEC_PC_MEM;
            
            MEM_RF_WR_SEL <= EXEC_RF_WR_SEL;
            MEM_REG_WRITE <= EXEC_REGWRITE;
            
            MS_WB_RD <= EX_MS_RD;
        end
    end
    
    
//----------------------------------- WRITEBACK Stage ----------------------------------------------- 
    logic [31:0] MUX_OUT_TO_REG_FILE;  
    
    Reg_file_MUX Reg_MUX (.ALU_OUT(MEM_REG_ALU_RESULT), .MEM_DOUT_2(MEM_REG_DOUT2), .CSR_RD(CSR_temp),
                          .PC_OUT(MEM_REG_PC_4), .RF_WR_SEL(MEM_RF_WR_SEL), .MUX_OUT(MUX_OUT_TO_REG_FILE));
    
 
//----------------------------------- MEMORY ----------------------------------------------- 
    Memory Mem_Module (.MEM_CLK(CLOCK), .MEM_ADDR1(PC_OUT[15:2]), .MEM_RDEN1(MEM_READ_1), .MEM_DOUT1(MEM_IR),
                       .MEM_ADDR2(EXEC_ALU_RESULT), .MEM_DIN2(EXEC_RS2), .MEM_WE2(EXEC_MEMWRITE), .MEM_RDEN2(EXEC_MEMREAD2), 
                       .MEM_SIZE(EXEC_PC_MEM[14:12]), .IO_WR(IOBUS_WR), .MEM_DOUT2(DOUT2_TO_MEM_REG));

    
// ----------------------------------- REGISTER FILE -----------------------------------------------
   Register_File_HW_3 Reg_File (.CLOCK(CLOCK), .input_reg(MEM_REG_IR), .RF_RS1(REG_FILE_RS1),
                                .RF_RS2(REG_FILE_RS2), .WD(MUX_OUT_TO_REG_FILE), .ENABLE(MEM_REG_WRITE));
    
endmodule 