`timescale 1ns / 1ps

module Reg_file_MUX(ALU_OUT, MEM_DOUT_2, CSR_RD, PC_OUT, RF_WR_SEL, MUX_OUT);

    input [31:0] ALU_OUT, MEM_DOUT_2, CSR_RD, PC_OUT;
    input [1:0] RF_WR_SEL;
    output logic [31:0] MUX_OUT;
    
    always_comb begin
        case (RF_WR_SEL)
            2'b00: begin MUX_OUT = PC_OUT; end// Select PC_OUT
            2'b01: begin MUX_OUT = CSR_RD ; end// Select CSR_RD
            2'b10: begin MUX_OUT = MEM_DOUT_2 ; end// Select MEM_DOUT_2
            2'b11: begin MUX_OUT = ALU_OUT ; end// Select ALU_OUT
        endcase
    end
endmodule
