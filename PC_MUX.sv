`timescale 1ns / 1ps

module PC_MUX(MUX_SEL, MUX_OUT, PC_4, JALR, BRANCH, JAL);
    
    // Options of 0-3, use two bits to select
    input [1:0]MUX_SEL;
    
    // Inputs of MUX 
    input [31:0] PC_4, JALR, BRANCH, JAL;
    
   // Output of MUX going to PC
   output logic [31:0]MUX_OUT;
    
    always_comb begin
        case (MUX_SEL) //Choices for MUX, dependent on 3 bit input
        2'b00: MUX_OUT = PC_4;
        2'b01: MUX_OUT = JALR;
        2'b10: MUX_OUT = BRANCH;
        2'b11: MUX_OUT = JAL;
        default: MUX_OUT = 16'hDEAD; //Default case is a large value,
        //Helps when it comes to debugging code
        
        endcase   
        end
        
endmodule
