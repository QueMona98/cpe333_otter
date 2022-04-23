`timescale 1ns / 1ps

module Brand_Cond_Gen (REG_INPUTA, REG_INPUTB, DR_MEM_OUT, PC_SOURCE_OUT);
    
    // Inputs of Branch Condition Generator: RS1, RS2, Memory Dout1
    input logic [31:0] REG_INPUTA, REG_INPUTB, DR_MEM_OUT;
    // Output of Branch Condition Generator: PC_SOURCE_OUT
    output logic [1:0] PC_SOURCE_OUT;
    
    // Asynchronous, use always_comb
      
always_comb begin
     
     // Look at current option code for program being executed
     case (DR_MEM_OUT[6:0])
     
     
     7'b1100011: // First case: Branch instruction (Same OP Code, different funct3) or Jalr
        begin
        
            case(DR_MEM_OUT[14:12])  // Check funct3
            
                3'b000: begin // Beq (Branch if equal)
                    // Check to see if current rs1 is equal to rs2. If so, set pcSource to 2. Otherwise, set to 0
                    if (REG_INPUTA == REG_INPUTB) begin
                        PC_SOURCE_OUT = 2'b10; end
                    else begin PC_SOURCE_OUT = 1'b0; end
                end
                
                3'b101: begin // Bge (Branch if greater than or equal to)
                    // Check to see if inverse of blt is true. If so, set pcSource to 2. Otherwise, set to 0
                    if (!($signed(REG_INPUTA) < $signed(REG_INPUTB))) begin
                        PC_SOURCE_OUT = 2'b10; end
                    else begin PC_SOURCE_OUT = 1'b0; end
                end
                
                3'b111: begin // Bgeu (Branch if greater than or equal to unsigned)
                    // Check to see if inverse of bltu is true. If so, set pcSource to 2. Otherwise, set to 0
                    if (!(REG_INPUTA < REG_INPUTB)) begin
                        PC_SOURCE_OUT = 2'b10; end
                    else begin PC_SOURCE_OUT = 1'b0; end
                end
                    
                3'b100: begin // Blt (Branch if less than)
                    // Check to see if less than is true. If so, set pcSource to 2. Otherwise, set to 0
                    if ($signed(REG_INPUTA) < $signed(REG_INPUTB)) begin
                           PC_SOURCE_OUT = 2'b10; end
                    else begin PC_SOURCE_OUT = 1'b0; end
                end
                    
                3'b110: begin // Bltu (Branch if less than unsigned)
                    // Check to see if less than unsigned is true. If so, set pcSource to 2. Otherwise, set to 0
                    if (REG_INPUTA < REG_INPUTB) begin
                     PC_SOURCE_OUT = 2'b10; end
                    else begin PC_SOURCE_OUT = 1'b0; end
                end
                
                3'b001: begin // Bne (Branch if not equal)
                // Check to see if inverse of equals is true. If so, set pcSource to 2. Otherwise, set to 0
                    if(!(REG_INPUTA == REG_INPUTB)) begin
                        PC_SOURCE_OUT = 2'b10; end
                    else begin PC_SOURCE_OUT = 1'b0; end
                end
                
                3'b000: begin // jalr (Jump and link at register)
                    // Set pcSource to 1
                    PC_SOURCE_OUT = 1'b1;
                end
                
                default: begin // For all other cases: Default to 0
                    PC_SOURCE_OUT =1'b0;
                end
                
            endcase
            
        end
        
     7'b1101111: begin // Second case: jal (Jump and link) 
        // Set pcSource to 3 
            PC_SOURCE_OUT = 2'b11;
     end
     
     default: begin// Default case: pcSource is set to 0 (PC + 4)
        PC_SOURCE_OUT = 1'b0;
        end
        
     endcase
     
end
        
                
endmodule
