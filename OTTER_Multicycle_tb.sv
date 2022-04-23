`timescale 1ns / 1ps


module OTTER_Multicycle_tb();

    logic cpu_clk, reset, iobus_wr;
    logic [31:0] iobus_in, iobus_out, iobus_addr;
    
     always #5 cpu_clk = ~cpu_clk;
    
    Pipelined_MCU UUT (.CLK(cpu_clk), .RST(reset), .IOBUS_IN(iobus_in), // Inputs
                       .IOBUS_WR(iobus_wr), .IOBUS_OUT(iobus_out), .IOBUS_ADDR(iobus_addr)); // Outputs
    
    initial begin
        iobus_in = 32'h00000002;
        cpu_clk = 0;
        reset = 1;
        #10 reset = 0;
    end 
    
endmodule
