`timescale 1ns / 1ps

module PC_4(Program_count, PC_4);
    input [31:0] Program_count;
    output logic [31:0] PC_4;
    
always_comb begin
    PC_4 = Program_count + 3'b100;
end
endmodule
