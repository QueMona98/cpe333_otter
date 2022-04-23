module ALU_MUX_srcA(alu_srcA, REG_rs1, IMM_GEN_U_Type, srcA);

    input [31:0] REG_rs1, IMM_GEN_U_Type;
    input alu_srcA;
    output logic [31:0] srcA;
    
    always_comb begin
        case (alu_srcA)
            1'b0: begin srcA = REG_rs1; end
            1'b1: begin srcA = IMM_GEN_U_Type; end
        endcase
    end         
endmodule