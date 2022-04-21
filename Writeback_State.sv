`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2022 12:15:10 AM
// Design Name: 
// Module Name: Writeback_State
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


module Writeback_State(MR_dout2, MR_alu_result, MR_ir, MR_PC_4, MR_rf_wr_sel, MR_regWrite);

    // Inputs from Memory register
    input logic [31:0] MR_dout2, MR_alu_result, MR_ir, MR_PC_4;
    input logic [1:0] MR_rf_wr_sel;
    input logic MR_regWrite;
    
    // For now, assign CSR register to 0
    logic CSR_temp;
    assign CSR_temp = 1'b0;
    
    // Wire for MUX Output
    logic [31:0] MUX_OUT_TO_REG_FILE;
    
    // ----------------------------------- Register File MUX -----------------------------------------------
    Reg_file_MUX Reg_MUX (.ALU_OUT(MR_alu_result), .MEM_DOUT_2(MR_dout2), .CSR_RD(CSR_temp), .PC_OUT(MR_PC_4),
    .RF_WR_SEL(MR_rf_wr_sel));
    
    
     // ----------------------------------- Register File Setup -----------------------------------------------
    
   Register_File_HW_3 Reg_File (.WD(MUX_OUT_TO_REG_FILE), .wa(MR_ir[11:7]), .ENABLE(MR_regWrite));
   
endmodule
