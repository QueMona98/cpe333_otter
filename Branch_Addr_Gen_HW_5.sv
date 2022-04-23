`timescale 1ns / 1ps

module Branch_Addr_Gen_HW_5(PC_COUNT, J_INPUT, B_INPUT,
 I_INPUT, RS1_INPUT, JALR_OUT, BRANCH_OUT, JAL_OUT);
 
 input [31:0] PC_COUNT, J_INPUT, B_INPUT, I_INPUT, RS1_INPUT;
 output logic [31:0] JALR_OUT, BRANCH_OUT, JAL_OUT;
 
 always_comb begin
 
 BRANCH_OUT = PC_COUNT + B_INPUT;
 
 JAL_OUT = PC_COUNT + J_INPUT;
 
 JALR_OUT = RS1_INPUT + I_INPUT;
 
 end
endmodule
