`timescale 1ns / 1ps

module Fetch_State(CLOCK, RESET, PC_WRITE, PC_SOURCE, MUX_JALR, MUX_JAL, MUX_BRANCH, PC_OUT, PC_PLUS_4, MEM_READ_1, MEM_IR,
FETCH_REG_OUT, FETCH_REG_PC, FETCH_REG_PC_4);

    // Inputs for PC and MEM
    input CLOCK, RESET;
    
    // Inputs for PC and MUX
    input logic  PC_WRITE;
    input logic [1:0]PC_SOURCE;
    input logic [31:0] MUX_JALR, MUX_BRANCH, MUX_JAL;
    // Logic for MUX to PC
    logic [31:0] MUX_to_PC;
    
    // Output of PC, and incremented PC
    output logic [31:0] PC_OUT, PC_PLUS_4;
    
    // Output of Memory
    output logic [31:0] MEM_IR;
    
    // Input for MEM
    input logic MEM_READ_1;
    // Set MEM_READ_1 as high
    assign MEM_READ_1 = 1'b1;
    
    // Outputs of Fetch register
    output logic [31:0] FETCH_REG_OUT, FETCH_REG_PC, FETCH_REG_PC_4;
    
    // --------------------------------- Program Counter Setup----------------------------------------
    // Incrementer for Program Count (PC + 4)
    PC_4 PC_Increment (.Program_count(PC_OUT), .PC_4(PC_PLUS_4));
    
    // Program Count setup 
    Program_Counter MyCounter (.pc_write(PC_WRITE), .pc_rst(RESET),
.pc_clk(CLOCK), .PC_DIN(MUX_to_PC), .PC_CNT(PC_OUT));

    // 4 Option MUX
    PC_MUX Prog_Count_MUX (.MUX_SEL(PC_SOURCE), .PC_4(PC_PLUS_4), .JALR(MUX_JALR),
    .BRANCH(MUX_BRANCH), .JAL(MUX_JAL), .MUX_OUT(MUX_to_PC));

    //----------------------------------- Memory Setup -----------------------------------------------
    
    // Memory Module setup (only look at bits [15:2] of the output for PC
    Memory Mem_Module (.MEM_CLK(CLOCK), .MEM_ADDR1(PC_OUT[15:2]), .MEM_RDEN1(MEM_READ_1), .MEM_DOUT1(MEM_IR));
    
    // Fetch Register for Pipeline Setup (write output of Memory to Fetch Register on negative clock cycle)
    
    // Initialize FETCH_REG to hold three values: PC, incremented PC and output of Memory
    logic [31:0]FETCH_REG[0:3];
    
    // Save the value of the output of the Memory module and PC+4 to the Fetch Register on negative clock cycle
    always_ff @ (negedge CLOCK) begin
    FETCH_REG[0] <= MEM_IR;
    FETCH_REG[1] <= PC_OUT;
    FETCH_REG[2] <= PC_PLUS_4;
    end
    
    // Reading from the Fetch register should happen on the positive edge of the clock 
    always_ff @ (posedge CLOCK) begin
    FETCH_REG_OUT <= FETCH_REG[0];
    FETCH_REG_PC <= FETCH_REG[1];
    FETCH_REG_PC_4 <= FETCH_REG[2];
    end
    
endmodule
