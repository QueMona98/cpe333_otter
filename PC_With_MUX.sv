`timescale 1ns / 1ps

module PC_With_MUX(MUX_IN_JALR, MUX_IN_BRANCH,
 MUX_IN_JAL, MUX_IN_MTVEC, MUX_IN_MEPC, PC_WRITE, PC_RST, CLK, PC_SOURCE,
 PC_ADDRESS, PC_4_to_MUX);
 
input [31:0] MUX_IN_JALR, MUX_IN_BRANCH, MUX_IN_JAL, MUX_IN_MTVEC, MUX_IN_MEPC; //Serves as the 6 32-bit signals for the input to the MUX
input PC_WRITE, PC_RST, CLK; //Serve as the inputs for the PC
input [2:0]PC_SOURCE; //Serves as the input for the selector of the MUX
output logic [31:0]PC_ADDRESS; //Serves as the output for the PC
logic [31:0]Mux_to_PC; //Logic to connect MUX to PC
output logic [31:0] PC_4_to_MUX; //Logic to connect PC to PC_4

PC_MUX MyMUX (.MUX_SEL(PC_SOURCE), .PC_4(PC_4_to_MUX), .JALR(MUX_IN_JALR),
.BRANCH(MUX_IN_BRANCH), .JAL(MUX_IN_JAL), .MTVEC(MUX_IN_MTVEC), .MEPC(MUX_IN_MEPC),       //Creation of MUX with inputs/outputs
.MUX_OUT(Mux_to_PC));

Program_Counter MyCounter (.pc_write(PC_WRITE), .pc_rst(PC_RST),        //Creation of PC with inputs/outputs
.pc_clk(CLK), .PC_DIN(Mux_to_PC), .PC_CNT(PC_ADDRESS));

PC_4 PC_Increment (.Program_count(PC_ADDRESS), .PC_4(PC_4_to_MUX));
endmodule

