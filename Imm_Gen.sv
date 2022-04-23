`timescale 1ns / 1ps


module Imm_Gen(IR_INPUT, U_TYPE_OUT, I_TYPE_OUT, S_TYPE_OUT,
                J_TYPE_OUT, B_TYPE_OUT);
                
    input [31:0] IR_INPUT; //Input of IR that will undergo concatenation
    output [31:0] U_TYPE_OUT, I_TYPE_OUT, S_TYPE_OUT, 
    J_TYPE_OUT, B_TYPE_OUT; //32-bit outputs of each type
    
    //Now, concatenate and replicate values for output
    
    
    assign U_TYPE_OUT = {{IR_INPUT [31:12]}, {12'b0}};
    //Concatenated output of U_TYPE_OUT
    assign I_TYPE_OUT = { {21{IR_INPUT[31]}}, IR_INPUT[30:20]};
    //Concatenated output of I_TYPE_OUT
    assign S_TYPE_OUT = {{21{IR_INPUT[31]}}, IR_INPUT[30:25],
    IR_INPUT[11:7]};
    //Concatenated output of S_TYPE_OUT
    assign B_TYPE_OUT = {{20{IR_INPUT[31]}}, IR_INPUT[7], IR_INPUT[30:25],
    IR_INPUT[11:8], 1'b0};
    //Concatenated output of B_TYPE_OUT
    assign J_TYPE_OUT = {{12{IR_INPUT[31]}}, IR_INPUT[19:12],
    IR_INPUT[20], IR_INPUT[30:21], 1'b0};
    //Concatenated output of J_TYPE_OUT
    
    //Concatenations above were done based on the Hardware 4
    // lab manual

endmodule
