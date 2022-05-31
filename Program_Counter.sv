`timescale 1ns / 1ps

module Program_Counter(
input pc_write, pc_rst, pc_clk,
input [31:0]PC_DIN, output logic [31:0]PC_CNT);

always_ff @ (posedge pc_clk)
    begin
        if (pc_rst == 1'b1) //First check, when reset = 1, output should be 0
            PC_CNT <= 32'h00;
        else if (pc_write == 1'b1) begin 
                //Only write when pc_write is high
                PC_CNT <= PC_DIN; //Output value to PC_CNT
                if (PC_CNT >= 32'hFFFFFFFF) //Since PC_CNT is only able to accept values up to 32-bits
                    //We need to reset PC_CNT back to 0 once it reaches a number greater than this 
                    PC_CNT <= 32'h00;
        end          
    end
    
endmodule
