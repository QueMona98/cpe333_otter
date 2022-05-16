`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2022 10:13:50 PM
// Design Name: 
// Module Name: Decode_State
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


module Decode_State(REG_CLOCK, REG_RESET, FR_MEM, FR_PC, FR_PC_4, DEC_PC_OUT, DEC_ALU_A, DEC_ALU_B, DEC_J_TYPE, DEC_B_TYPE,
                    DEC_MEM_IR, DEC_ALU_FUN, DEC_REGWRITE, DEC_MEMWRITE, DEC_MEMREAD_2, DEC_RF_WR_SEL, DEC_I_TYPE, DEC_RS1, DEC_RS2,
                    ID_EX_RS1, ID_EX_RS2, ID_EX_RD, OVERRIDE_A, OVERRIDE_B, Forward1, Forward2);
                    
    // Inputs for register file
    input logic REG_CLOCK, REG_RESET;
    
    // 32-bit outputs from Fetch Register
    input logic [31:0] FR_MEM, FR_PC, FR_PC_4;
    
    // Input for overriding MUXES
    input logic [1:0] OVERRIDE_A;
    input logic [2:0] OVERRIDE_B;
    
    input logic [31:0] Forward1, Forward2;
    
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
    logic [31:0] ALU_A_TO_DR, ALU_B_TO_DR, FINAL_ALU_A_TO_DR, FINAL_ALU_B_TO_DR;
    
    // Outputs of Decode register 
    output logic [31:0] DEC_PC_OUT, DEC_ALU_A, DEC_ALU_B, DEC_J_TYPE, DEC_B_TYPE, DEC_I_TYPE, DEC_MEM_IR, DEC_RS1, DEC_RS2;
    output logic [3:0] DEC_ALU_FUN;
    output logic DEC_REGWRITE, DEC_MEMWRITE, DEC_MEMREAD_2;
    output logic [1:0] DEC_RF_WR_SEL;
    output logic [4:0] ID_EX_RS1, ID_EX_RS2, ID_EX_RD;
    
    // ----------------------------------- Decoder Setup -----------------------------------------------
    
    cu_decoder Decoder (.IR_FETCH_REG(FR_MEM), .ALU_FUN(ALU_FUN_TO_DR), .ALU_SOURCE_A(ALU_A), .ALU_SOURCE_B(ALU_B), 
    .RF_WR_SEL(RF_WR_SEL_TO_DR), .REG_WRITE(REGWRITE_TO_DR), .MEM_WRITE(MEMWRITE_TO_DR), .MEM_READ_2(MEMREAD2_TO_DR));
    
    // ----------------------------------- Register File Setup -----------------------------------------------
    
   Register_File_HW_3 Reg_File (.CLOCK(REG_CLOCK), .input_reg(FR_MEM), .RF_RS1(REG_FILE_RS1), .RF_RS2(REG_FILE_RS2));
   
       // ----------------------------------- Immediate Generator Setup -----------------------------------------------
       
   Imm_Gen IG (.IR_INPUT(FR_MEM), .U_TYPE_OUT(U_TYPE), .I_TYPE_OUT(I_TYPE), .S_TYPE_OUT(S_TYPE), .J_TYPE_OUT(J_TYPE),
   .B_TYPE_OUT(B_TYPE));

       // ----------------------------------- ALU_A Setup -----------------------------------------------
   
   ALU_MUX_srcA MUX_A (.REG_rs1(REG_FILE_RS1), .IMM_GEN_U_Type(U_TYPE), .alu_srcA(ALU_A), .srcA(ALU_A_TO_DR));
   
   // ----------------------------------- ALU_B Setup -----------------------------------------------
   
   ALU_MUX_srcB MUX_B (.REG_rs2(REG_FILE_RS2), .IMM_GEN_I_Type(I_TYPE), .IMM_GEN_S_Type(S_TYPE), .PC_OUT(FR_PC),
   .alu_srcB(ALU_B), .srcB(ALU_B_TO_DR));

   // ----------------------------------- ALU_A Override Setup -----------------------------------------------

    Mult4to1 MUX_OVERRIDE_A (.In1(ALU_A_TO_DR), .In2(Forward1), .In3(Forward2),
    .In4(), .Sel(OVERRIDE_A ), .Out(FINAL_ALU_A_TO_DR ));


   // ----------------------------------- ALU_B Override Setup -----------------------------------------------
  
    Mult4to1 MUX_OVERRIDE_B (.In1(ALU_B_TO_DR), .In2(Forward1), .In3(Forward2),
    .In4(), .Sel(OVERRIDE_B), .Out(FINAL_ALU_B_TO_DR));


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
    always_ff @ (negedge REG_CLOCK) begin
    if (REG_RESET == 1'b1) begin
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
    always_ff @ (posedge REG_CLOCK) begin
    
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
    DEC_REGWRITE  <= DECODE_REG_2[0];
    DEC_MEMWRITE  <= DECODE_REG_2[1];
    DEC_MEMREAD_2 <= DECODE_REG_2[2];
    
    // 4-bit read
    DEC_ALU_FUN <= DECODE_REG_3;
    
    // 2-bit read
    DEC_RF_WR_SEL <= DECODE_REG_4;
    
    ID_EX_RS1 <= DECODE_REG_5[0];
    ID_EX_RS2 <= DECODE_REG_5[1];
    ID_EX_RD <= DECODE_REG_5[2];

    end
    
    
   
endmodule

