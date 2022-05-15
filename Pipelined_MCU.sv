`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2022 09:30:06 AM
// Design Name: 
// Module Name: Pipelined_MCU
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


module Pipelined_MCU(RST, CLK, IOBUS_IN, IOBUS_WR, IOBUS_OUT, IOBUS_ADDR);
 
 // Main inputs/outputs of OTTER MCU
 input logic RST, CLK;
 input logic [31:0] IOBUS_IN;
 output IOBUS_WR;
 output [31:0] IOBUS_OUT, IOBUS_ADDR;
 
 // Logics to connect outputs of Fetch State module to Decode State module
 logic [31:0] Fetch_reg_PC_4, Fetch_reg_dout1, Fetch_reg_pc;
 
 // Logics to connect PC MUX inputs from Execute state
 logic [31:0] Execute_jalr_to_MUX, Execute_branch_to_MUX, Execute_jal_to_MUX;
 
 // Temporary logic for PC_WRITE
 logic pc_write;
 assign pc_write = 1'b1;
    // --------------------------------- Fetch State Setup-----------------------------------------------
    
    Fetch_State FS (.CLOCK(CLK), .RESET(RST), .FETCH_REG_OUT(Fetch_reg_dout1), .FETCH_REG_PC(Fetch_reg_pc),
    .FETCH_REG_PC_4(Fetch_reg_PC_4), .MUX_JALR(Execute_jalr_to_MUX), .MUX_BRANCH(Execute_branch_to_MUX), 
    .MUX_JAL(Execute_jal_to_MUX), .PC_WRITE(pc_write), .PC_SOURCE(pcsource_to_pc));
    
    // --------------------------------- Decode State Setup-----------------------------------------------

    // Logics to connect outputs of Decode state to Execute State
    logic [31:0] Decoder_PC_4, Decoder_rs1, Decoder_rs2, Decoder_J_type, Decoder_B_type, Decoder_I_type, Decoder_dout1, Decoder_ALU_A, Decoder_ALU_B;
    logic [3:0] Decoder_alu_fun;
    logic Decoder_regWrite, Decoder_memWrite, Decoder_memRead2;
    logic [1:0] Decoder_rf_wr_sel;
    logic [4:0] ID_EX_RS1, ID_EX_RS2, ID_EX_RD;
    
    Decode_State DS (.REG_CLOCK(CLK), .REG_RESET(RST), .FR_MEM(Fetch_reg_dout1), .FR_PC(Fetch_reg_pc), .FR_PC_4(Fetch_reg_PC_4), // Inputs 
                    .DEC_PC_OUT(Decoder_PC_4), .DEC_ALU_A(Decoder_ALU_A), .DEC_ALU_B(Decoder_ALU_B), .DEC_J_TYPE(Decoder_J_type), // Outputs
                    .DEC_B_TYPE(Decoder_B_type), .DEC_I_TYPE(Decoder_I_type), .DEC_MEM_IR(Decoder_dout1), .DEC_ALU_FUN(Decoder_alu_fun), 
                    .DEC_REGWRITE(Decoder_regWrite), .DEC_MEMWRITE(Decoder_memWrite), .DEC_MEMREAD_2(Decoder_memRead2),
                    .DEC_RF_WR_SEL(Decoder_rf_wr_sel), .DEC_RS1(Decoder_rs1), .DEC_RS2(Decoder_rs2),
                    .ID_EX_RS1(ID_EX_RS1), .ID_EX_RS2(ID_EX_RS2), .ID_EX_RD(ID_EX_RD), .OVERRIDE_A(OVERRIDE_A), .OVERRIDE_B(OVERRIDE_B));
                    
    // --------------------------------- Execute State Setup-----------------------------------------------
    
    // Logics to connect outputs of Execute state to Memory State
    logic [31:0] Execute_PC_4, Execute_dout1, Execute_alu_out, Execute_rs2;
    logic [1:0] Execute_rf_wr_sel;
    logic Execute_regWrite, Execute_memWrite, Execute_memRead2;
    logic [1:0] pcsource_to_pc;
    logic [4:0] EX_MS_RD;
    
    Execute_State ES (.EXECUTE_CLOCK(CLK), .EXECUTE_RESET(RST), .DR_J_TYPE(Decoder_J_type), .DR_B_TYPE(Decoder_B_type), // Inputs
                      .DR_I_TYPE(Decoder_I_type), .DR_PC_MEM(Decoder_dout1), .DR_RS1(Decoder_rs1), .DR_RS2(Decoder_rs2), 
                      .DR_ALU_A(Decoder_ALU_A), .DR_ALU_B(Decoder_ALU_B), .DR_ALU_FUN(Decoder_alu_fun), .DR_REG_WRITE(Decoder_regWrite), .DR_MEM_WRITE(Decoder_memWrite),
                      .DR_MEM_READ2(Decoder_memRead2), .DR_RF_WR_SEL(Decoder_rf_wr_sel), .DR_PC_4(Decoder_PC_4), 
                      .EXEC_PC_4(Execute_PC_4), .EXEC_PC_MEM(Execute_dout1), .EXEC_ALU_RESULT(Execute_alu_out),         // Outputs
                      .EXEC_RS2(Execute_rs2), .EXEC_RF_WR_SEL(Execute_rf_wr_sel), .EXEC_REGWRITE(Execute_regWrite),
                      .EXEC_MEMWRITE(Execute_memWrite), .EXEC_MEMREAD2(Execute_memRead2), 
                      .JALR_TO_PC(Execute_jalr_to_MUX ), .JAL_TO_PC(Execute_jal_to_MUX), 
                      .BRANCH_TO_PC(Execute_branch_to_MUX), .PCSOURCE_TO_PC(pcsource_to_pc),  // Outputs to PC in Fetch State
                      .ID_EX_RD(ID_EX_RD), .EX_MS_RD(EX_MS_RD));
                      
    // --------------------------------- Memory State Setup-----------------------------------------------
    
    // Logics to connect outputs of Memory state to Writeback State
    logic [31:0] Memory_dout2, Memory_alu_out, Memory_dout1, Memory_PC_4;
    logic [1:0] Memory_rf_wr_sel;
    logic Memory_regWrite;
    logic [4:0] MS_WB_RD;

    Memory_State MS (.MEM_CLOCK(CLK), .MEM_RESET(RST), .ER_memWrite(Execute_memWrite), .ER_memRead2(Execute_memRead2), // Inputs
                     .ER_REG_WRITE(Execute_regWrite), .ER_PC_MEM(Execute_dout1), .ER_PC_4(Execute_PC_4), .ER_ALU_OUT(Execute_alu_out),
                     .ER_RS2(Execute_rs2), .ER_RF_WR_SEL(Execute_rf_wr_sel),
                     .M_IOBUS_ADDR(IOBUS_ADDR), .M_IOBUS_OUT(IOBUS_OUT), .M_IOBUS_WR(IOBUS_WR), .MEM_REG_DOUT2(Memory_dout2),  // Outputs    
                     .MEM_REG_ALU_RESULT(Memory_alu_out), .MEM_REG_IR(Memory_dout1), .MEM_REG_PC_4(Memory_PC_4),
                     .MEM_RF_WR_SEL(Memory_rf_wr_sel), .MEM_REG_WRITE(Memory_regWrite),
                     .EX_MS_RD(EX_MS_RD), .MS_WB_RD(MS_WB_RD));
                     
   // --------------------------------- Writeback State Setup-----------------------------------------------
   
   Writeback_State WS (.MR_dout2(Memory_dout2), .MR_alu_result(Memory_alu_out), .MR_ir(Memory_dout1), .MR_PC_4(Memory_PC_4), // Inputs
                       .MR_rf_wr_sel(Memory_rf_wr_sel), .MR_regWrite(Memory_regWrite));     
                       
                       
        
   // --------------------------------- Forwarding Unit -----------------------------------------------

   logic [1:0] OVERRIDE_A;
   logic [2:0] OVERRIDE_B;
   
   Foward_Unit foward_unit( .Execute_Register_SourceRegister_1(ID_EX_RS1), .Execute_Register_SourceRegister_2(ID_EX_RS2),
                            .Memory_Register_value(EX_MS_RD), .WriteBack_Register_IOBUSaddr_value(MS_WB_RD), .CLK(CLK),
                            .mux_srcA_priority_foward(OVERRIDE_A), .mux_srcB_priority_foward(OVERRIDE_B),
                            .EX_MS_regWrite(Execute_regWrite), .MS_WV_regWrite(Memory_regWrite));
    
endmodule
