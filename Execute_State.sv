`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2022 07:21:22 PM
// Design Name: 
// Module Name: Execute_State
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


module Execute_State(EXECUTE_CLOCK, EXECUTE_RESET, DR_J_TYPE, DR_B_TYPE, DR_I_TYPE, DR_PC_MEM, DR_RS1, DR_RS2, DR_ALU_FUN, JALR_TO_PC, BRANCH_TO_PC,
                     JAL_TO_PC, PCSOURCE_TO_PC, DR_REG_WRITE, DR_MEM_WRITE, DR_MEM_READ2, DR_RF_WR_SEL, DR_PC_4);

// Inputs for clock and reset signals
    input EXECUTE_CLOCK, EXECUTE_RESET;
// Inputs for Branch Address Generator
    input logic [31:0] DR_J_TYPE, DR_B_TYPE, DR_I_TYPE;
// Inputs for Target Gen and Branch Condition Generator + ALU
    input logic [31:0] DR_PC_MEM;    //(Current PC)
    input logic [31:0] DR_RS1;
// Input for Branch Condition Generator + ALU
    input logic [31:0] DR_RS2;
// Input for ALU
    input logic [31:0] DR_ALU_FUN;

// Inputs to pass directly into Execute register
    input logic DR_REG_WRITE, DR_MEM_WRITE, DR_MEM_READ2;
    input logic [1:0] DR_RF_WR_SEL;
    input logic [31:0] DR_PC_4;
    
// Logics for outputs of ALU and rs2
    logic [31:0] ALU_OUT_TO_REG;

// Outputs for Target Gen + Branch Condititon Generator
    output logic [31:0] JALR_TO_PC, BRANCH_TO_PC, JAL_TO_PC;
    output logic [1:0] PCSOURCE_TO_PC;
    
// Outputs of Execute register
    output logic [31:0] EXEC_PC_4, EXEC_PC_MEM, EXEC_ALU_RESULT, EXEC_RS2;
    output logic [1:0] EXEC_RF_WR_SEL;
    output logic EXEC_REGWRITE, EXEC_MEMWRITE, EXEC_MEMREAD2;
    
    // ----------------------------------- Target Gen Setup -----------------------------------------------
    Branch_Addr_Gen_HW_5 Target_Gen (.PC_COUNT(DR_PC_MEM), .J_INPUT(DR_J_TYPE), .B_INPUT(DR_B_TYPE), .I_INPUT(DR_I_TYPE),
                                    .RS1_INPUT(DR_RS1), .JALR_OUT(JALR_TO_PC), .BRANCH_OUT(BRANCH_TO_PC), .JAL_OUT(JAL_TO_PC));
   
    // ----------------------------------- Branch Cond. Gen Setup -----------------------------------------------
    Brand_Cond_Gen BC_Generator (.REG_INPUTA(DR_RS1), .REG_INPUTB(DR_RS2), .DR_MEM_OUT(DR_PC_MEM), .PC_SOURCE_OUT(PCSOURCE_TO_PC));
    
    // ----------------------------------- ALU Setup -----------------------------------------------
    ALU_HW_4 Execute_ALU (.ALU_A(DR_RS1), .ALU_B(DR_RS2), .ALU_FUN(DR_ALU_FUN), .RESULT(ALU_OUT_TO_REG));

    // ----------------------------------- Execute Register Setup -----------------------------------------------
    // Initalize Execute Register to hold the following values:
    // 32-bit: PC+4 from Decode register, DOUT1 from Decode register, ALU output, rs2 from Decode register
    // 2-bit: rf_wr_sel from Decode register
    // 1-bit from Decode register: regWrite, memWrite, memRead2
    
    logic [31:0] EXECUTE_REG1[0:3];  // 32-bit values
    logic [1:0] EXECUTE_REG2;  // 2-bit value
    logic EXECUTE_REG3[0:2];  // 1-bit values
    
      // Save the various outputs on the negative edge of the clock cycle
    always_ff @ (negedge EXECUTE_CLOCK) begin
    
    // 32-bit values
    EXECUTE_REG_1[0] <= DR_PC_4 ;       // PC + 4 from Decode register
    EXECUTE_REG_1[1] <= DR_PC_MEM;      // DOUT 1 from Decode register
    EXECUTE_REG_1[2] <= ALU_OUT_TO_REG; // ALU Output   
    EXECUTE_REG_1[3] <= DR_RS2;         // rs2 from Decode register
    
    // 2- bit value
    EXECUTE_REG2 <= DR_RF_WR_SEL;       // RF_WR_SEL from Decode register
    
    // 1-bit values
    EXECUTE_REG3[0] <= DR_REG_WRITE;    // regWrite from Decode register
    EXECUTE_REG3[1] <= DR_MEM_WRITE;    // memWrite from Decode register
    EXECUTE_REG3[2] <= DR_MEM_READ2;    // memRead2 from Decode register
    
    end
    
     // Reading from the Fetch register should happen on the positive edge of the clock 
    always_ff @ (posedge EXECUTE_CLOCK) begin
    
    // 32-bit reads
    EXEC_PC_4 = EXECUTE_REG_1[0];
    EXEC_PC_MEM = EXECUTE_REG_1[1];
    EXEC_ALU_RESULT = EXECUTE_REG_1[2];
    EXEC_RS2 = EXECUTE_REG_1[3];
    
    // 2-bit reads
    EXEC_RF_WR_SEL = EXECUTE_REG_2;
    
    // 1-bit reads
    EXEC_REGWRITE = EXECUTE_REG_3[0];
    EXEC_MEMWRITE = EXECUTE_REG_3[1];
    EXEC_MEMREAD2 = EXECUTE_REG_3[2];
    
    end
    endmodule
