`timescale 1ns / 1ps

module ALU_with_MUX(REG_rs1, IMM_GEN_U_Type, alu_srcA, REG_rs2, IMM_GEN_I_Type, 
                    IMM_GEN_S_Type, PC_OUT, alu_srcB, alu_fun, ALU_RESULT);
    
    // Inputs for MUX source A
    input [31:0] REG_rs1, IMM_GEN_U_Type;
    input alu_srcA;
    // Logic for output of MUX_A to ALU
    logic [31:0] srcA_to_ALU;
    
    //Inputs for MUX source B
    input [31:0] REG_rs2, IMM_GEN_I_Type, IMM_GEN_S_Type, PC_OUT;
    input [1:0] alu_srcB;
    // Logic for output of MUX_B to ALU
    logic [31:0] srcB_to_ALU;
    
    // Input for ALU_fun
    input [3:0] alu_fun;
    // Output for ALU
    output logic [31:0] ALU_RESULT;
    
    ALU_MUX_srcA MUX_A (.REG_rs1(REG_rs1), .IMM_GEN_U_Type(IMM_GEN_U_Type), 
                        .alu_srcA(alu_srcA), .srcA(srcA_to_ALU));
                        
    ALU_MUX_srcB MUX_B (.REG_rs2(REG_rs2), .IMM_GEN_I_Type(IMM_GEN_I_Type), 
                        .IMM_GEN_S_Type(IMM_GEN_S_Type), .PC_OUT(PC_OUT),
                        .alu_srcB(alu_srcB), .srcB(srcB_to_ALU));
                        
    ALU_HW_4 ALU_with_MUXes (.ALU_A(srcA_to_ALU), .ALU_B(srcB_to_ALU), .ALU_FUN(alu_fun),
                        .RESULT(ALU_RESULT));
    
endmodule
