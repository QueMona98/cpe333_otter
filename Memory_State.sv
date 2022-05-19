`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2022 11:25:19 PM
// Design Name: 
// Module Name: Memory_State
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


module Memory_State(MEM_CLOCK, MEM_RESET, ER_memWrite, ER_memRead2, ER_REG_WRITE, ER_PC_MEM, ER_PC_4, ER_ALU_OUT,
                    ER_RS2, ER_RF_WR_SEL, M_IOBUS_ADDR, M_IOBUS_OUT, M_IOBUS_WR, MEM_REG_DOUT2, MEM_REG_ALU_RESULT, MEM_REG_IR,
                    MEM_REG_PC_4, MEM_RF_WR_SEL, MEM_REG_WRITE, EX_MS_RD, MS_WB_RD);

// Inputs for Memory register
    input MEM_CLOCK, MEM_RESET;
// Inputs from Execute register
    input logic ER_memWrite, ER_memRead2, ER_REG_WRITE;
    input logic [31:0] ER_PC_MEM, ER_PC_4, ER_ALU_OUT, ER_RS2;
    input logic [1:0] ER_RF_WR_SEL;
    
    input logic [4:0] EX_MS_RD;

// Output for IOBUS_ADDR, IOBUS_OUT, IOBUS_WR
    output logic [31:0] M_IOBUS_ADDR, M_IOBUS_OUT, M_IOBUS_WR;

// Wire for Memory dout2
    logic [31:0] DOUT2_TO_MEM_REG;
    
// Outputs of Memory register
    output logic [31:0] MEM_REG_DOUT2, MEM_REG_ALU_RESULT, MEM_REG_IR, MEM_REG_PC_4;
    output logic [1:0] MEM_RF_WR_SEL;
    output logic MEM_REG_WRITE;
    
    output logic [4:0] MS_WB_RD;
    
    //----------------------------------- Memory Setup -----------------------------------------------
    
    // Memory Module setup 
    Memory Mem_Module (.MEM_ADDR2(ER_ALU_OUT), .MEM_DIN2(ER_RS2), .MEM_WE2(ER_memWrite), .MEM_RDEN2(ER_memRead2), 
                       .MEM_SIZE(ER_PC_MEM[14:12]), .IO_WR(M_IOBUS_WR), .MEM_DOUT2(DOUT2_TO_MEM_REG));
    // Still need to assign IOBUS_IN
    
     // Taking care of IOBUS.....
     assign M_IOBUS_ADDR = ER_ALU_OUT;
     assign M_IOBUS_OUT = ER_RS2;

    // ----------------------------------- Memory Register Setup -----------------------------------------------
    // Initalize Memory Register to hold the following values:
    // 32-bit: ALU result from Execute register, DOUT2 from Memory module, Current PC from Execute Register, PC + 4 from 
    // Execute register
    // 2-bit: rf_wr_sel from Execute register
    // 1-bit: regWrite from Execute register
    
    logic [0:3][31:0]MEMORY_REG_1;  // 32-bit values
    logic [1:0] MEMORY_REG_2;        // 2-bit value
    logic MEMORY_REG_3;              // 1-bit value
    logic [4:0] MEMORY_REG_4;
    
    // Save the various outputs on the negative edge of the clock cycle
    always_ff @ (negedge MEM_CLOCK) begin
        if(MEM_RESET == 1'b1) begin
        MEMORY_REG_1 <= 0;
        MEMORY_REG_2 <= 0;
        MEMORY_REG_3 <= 0;
        MEMORY_REG_4 <= 0;
    end
    else begin
        // 32-bit values
        MEMORY_REG_1[0] <= ER_PC_4 ;              // PC + 4 from Execute register
        MEMORY_REG_1[1] <= DOUT2_TO_MEM_REG;      // DOUT2 from Memory module
        MEMORY_REG_1[2] <= ER_ALU_OUT;            // ALU Output from Execute register   
        MEMORY_REG_1[3] <= ER_PC_MEM;                // Current PC from Execute register
        
        // 2-bit value
        MEMORY_REG_2 <= ER_RF_WR_SEL;
        
        // 1-bit value
        MEMORY_REG_3 <= ER_REG_WRITE;
        
        MEMORY_REG_4 <= EX_MS_RD;
        end
    end
    
     // Reading from the Fetch register should happen on the positive edge of the clock 
    always_ff @ (posedge MEM_CLOCK) begin
        // 32-bit reads
        MEM_REG_PC_4 <= MEMORY_REG_1[0];
        MEM_REG_DOUT2 <=  MEMORY_REG_1[1];
        MEM_REG_ALU_RESULT <= MEMORY_REG_1[2];
        MEM_REG_IR <= MEMORY_REG_1[3];
        
        // 2-bit read
        MEM_RF_WR_SEL <= MEMORY_REG_2;
        
        //1-bit read
        MEM_REG_WRITE <= MEMORY_REG_3;
        
        MS_WB_RD <= MEMORY_REG_4;
    end
endmodule
