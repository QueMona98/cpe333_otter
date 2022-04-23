`timescale 1ns / 1ps

module ALU_MUX_srcB(REG_rs2, IMM_GEN_I_Type, IMM_GEN_S_Type, PC_OUT, alu_srcB, srcB);

    input [31:0] REG_rs2, IMM_GEN_I_Type, IMM_GEN_S_Type, PC_OUT;
    input [1:0] alu_srcB;
    output logic [31:0] srcB;
    
    always_comb begin
        case (alu_srcB)
            1'b0: begin srcB = REG_rs2; end
            1'b1: begin srcB = IMM_GEN_I_Type; end
            2'b10: begin srcB = IMM_GEN_S_Type; end
            2'b11: begin srcB = PC_OUT; end
        endcase
   end
endmodule
