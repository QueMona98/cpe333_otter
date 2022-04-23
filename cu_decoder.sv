`timescale 1ns / 1ps

module cu_decoder(IR_FETCH_REG, ALU_FUN, ALU_SOURCE_A, ALU_SOURCE_B,
RF_WR_SEL, REG_WRITE, MEM_WRITE, MEM_READ_2);
    
    // Input from Fetch Register
    input logic [31:0] IR_FETCH_REG;
    // Various outputs of Decoder
    output logic [3:0] ALU_FUN;
    output logic ALU_SOURCE_A;
    output logic [1:0] ALU_SOURCE_B, RF_WR_SEL;
    // New outputs: regWrite, memWrite, memRead2
    output logic REG_WRITE, MEM_WRITE, MEM_READ_2;
    
    
    // Since both R-type and I-type instructions have the same output signals for the following:
    // PC_SOURCE, RF_WR_SEL, ALU_SOURCE_A, ALU_SOURCE_B, ALU_FUN
    // We can check to see what FUNCT3 is instead
    
    // Combinational logic, asynchronous 
always_comb

begin
// Initialize all outputs to 0
ALU_FUN = 1'b0;
ALU_SOURCE_A = 1'b0;
ALU_SOURCE_B = 1'b0;
RF_WR_SEL = 1'b0;
REG_WRITE = 1'b0;
MEM_WRITE = 1'b0;
MEM_READ_2 = 1'b0;
         
         // Look at last 7 bits of IR
        case (IR_FETCH_REG[6:0])
        
            7'b0110011: //R-type opcode
            begin
                //Set ALU_SOURCE_A to 0
                ALU_SOURCE_A = 1'b0;
                //Set ALU_SOURCE_B to 0
                ALU_SOURCE_B = 1'b0;
                // Set RF_WR_SEL to 3
                RF_WR_SEL = 2'b11;
                // Set REG_WRITE to 1
                REG_WRITE = 1'b1;
                // Set MEM_WRITE to 1
                MEM_WRITE = 1'b0;
                // MEM_READ_2 = 1'b0
                MEM_READ_2 = 1'b0;
                
                //------------------------  STOPPED HERE ---------------------- 
                
                // Check OP_CODE for ALU_FUN
                case (IR_FETCH_REG[14:12])
                
                    3'b010: //Set less than 
                    begin ALU_FUN = 4'b0010; end
                    
                    3'b100: //XOR
                    begin ALU_FUN = 4'b0100; end
                    
                    3'b111: //AND
                    begin ALU_FUN = 4'b0111; end
                    
                    3'b110: //OR
                    begin ALU_FUN = 4'b0110; end
                    
                    3'b001: //Sll
                    begin ALU_FUN = 4'b0001; end
                    
                    3'b011: //Sltu
                    begin ALU_FUN = 4'b0011; end
                    
                    // Cases that consider the 30th bit: Add/Sub and Sra/Srl
                    
                    3'b000: //Add or Sub
                        case (IR_FETCH_REG[30]) 
                            1'b0: //Add
                                begin ALU_FUN = 4'b0000; end
                            1'b1: //Sub
                                begin ALU_FUN = 4'b1000; end
                            default:
                                begin ALU_FUN = 4'b0000; end
                        endcase
                    3'b101: //Sra or Srl
                        case (IR_FETCH_REG[30])
                            1'b0: //Srl
                                begin ALU_FUN = 4'b0101; end
                            1'b1: //Sra
                                begin ALU_FUN =4'b1101; end
                            default:
                                begin ALU_FUN =4'b0101; end
                        endcase
                        
                    default: //Funct3 default case
                    ALU_FUN = 1'b0;
                    
                endcase //Funct3 endcase
            end //Funct3 end
           
           7'b0010011: //I-Type opcode (no load operations / jalr)
           begin
                //Set ALU_SOURCE_A to 0
                ALU_SOURCE_A = 1'b0;
                //Set ALU_SOURCE_B to 1
                ALU_SOURCE_B = 1'b1;
                // Set RF_WR_SEL to 3
                RF_WR_SEL = 2'b11;
                // Set REG_WRITE to 1
                REG_WRITE = 1'b1;
                // Check OP_CODE for ALU_FUN
                case (IR_FETCH_REG[14:12])
                
                    3'b000: //Addi 
                    begin ALU_FUN = 4'b0000; end
                    
                    3'b111: //Andi
                    begin ALU_FUN = 4'b0111; end
                    
                    3'b001: //Slli
                    begin ALU_FUN = 4'b0001; end
                    
                    3'b110: //Ori
                    begin ALU_FUN = 4'b0110; end
                    
                    3'b010: //slti
                    begin ALU_FUN = 4'b0010; end
                    
                    3'b011: //sltiu
                    begin ALU_FUN = 4'b0011; end 
                    
                    3'b100: //Xori
                    begin ALU_FUN = 4'b0100; end
                    
                    // Case that considers the 30th bit: Srai or Srli
                    
                    3'b101: //Srai or Srli
                        begin
                            case(IR_FETCH_REG[30])
                                1'b0: //Srli
                                    begin ALU_FUN = 4'b0101; end
                                1'b1: //Srai 
                                    begin ALU_FUN = 4'b1101; end
                            endcase                            
                        end  
                                          
                    default:
                    ALU_FUN = 1'b0;
                    
                endcase
           end
           
           7'b0000011: // I-type load operations, not concerned with opcode (opcode determines size, sign)
           begin // Now need to add high signal for memRead2
                //Set ALU_SOURCE_A to 0
                ALU_SOURCE_A = 1'b0;
                //Set ALU_SOURCE_B to 1
                ALU_SOURCE_B = 1'b1;
                //Set ALU_FUN to 0
                ALU_FUN = 4'b0000;
                //Set rf_wr_sel to 2
                RF_WR_SEL = 2'b10;
                // Set MEM_READ_2 to 1
                MEM_READ_2 = 1'b1;
                // Set regWrite to high
                REG_WRITE = 1'b1;
           end
           
           7'b0100011: //S-type operations
           begin    // Now need to add high signal for memWrite
                //Set ALU_FUN to 0
                ALU_FUN = 4'b0000;
                //Set ALU_SOURCE_A to 0
                ALU_SOURCE_A = 1'b0;
                //Set ALU_SOURCE_B to 2
                ALU_SOURCE_B = 2'b10;
                //Set rf_we_sel to 2
                RF_WR_SEL = 2'b10;
                // Set memWrite to 1
                MEM_WRITE = 1'b1;
           end
           
           7'b0110111: //Lui, U-type
           begin
                //Set ALU_SOURCE_A to 1
                ALU_SOURCE_A = 1'b1;
                // Ignore value of ALU_SOURCE_B 
                // Set RF_WR_SEL to 3
                RF_WR_SEL = 2'b11;
                // Set ALU_FUN to 1001
                ALU_FUN = 4'b1001;
            end
           
           7'b0010111: //Auipc, U-type
           begin
                //Set ALU_SOURCE_A to 1
                ALU_SOURCE_A = 1'b1;
                // Set ALU_SOURCE_B to 3
                ALU_SOURCE_B = 2'b11;
                // Set RF_WR_SEL to 3
                RF_WR_SEL = 2'b11;
                // Set ALU_FUN to 0000
                ALU_FUN = 4'b0000;
            end
            
// ---------------------------------- B-type code now taken care of by Branch Condition Generator -------------------
           
//           7'b1100011: // B-type opcode
//           begin
//                case (IR_FETCH_REG[14:12])
//                    3'b000: //Branch if equal opcode
//                        begin
//                    // First, check to see if br_eq is 1. If so, set PC_SOURCE to 2, otherwise set PC_SOURCE to 0
//                            case (BR_EQ)
//                                1'b1:
//                                begin PC_SOURCE = 3'b010; end
//                                default:
//                                PC_SOURCE = 1'b0;
//                            endcase
//                        end
                        
//                    3'b101: //Branch if greater than or equal
//                        begin
//                            case(BR_LT) //Check to see if BR_LT is 0. If so, set PC_Source to 2. Otherwise, PC_Source = 0
//                                1'b0:
//                                begin PC_SOURCE =3'b010; end
//                                default: 
//                                PC_SOURCE = 1'b0;
//                            endcase
//                        end
                        
//                     3'b111: //Branch if greater than or equal unsigned
//                        begin
//                            case(BR_LTU) //Check to see if BR_LTU is 0. If so, set PC_Source to 2. Otherwise, PC_Source = 0
//                                1'b0:
//                                begin PC_SOURCE =3'b010; end
//                                default: 
//                                PC_SOURCE = 1'b0;
//                            endcase
//                        end    
                    
//                      3'b100: //Branch if less than
//                        begin
//                            case(BR_LT) //Check to see if BR_LT is 1. If so, set PC_Source to 2. Otherwise, PC_Source = 0
//                                1'b1:
//                                begin PC_SOURCE =3'b010; end
//                                default: 
//                                PC_SOURCE = 1'b0;
//                            endcase
//                        end  
                          
//                      3'b110: //Branch if less than unsigned
//                        begin
//                         case(BR_LTU) //Check to see if BR_LTU is 1. If so, set PC_Source to 2. Otherwise, PC_Source = 0
//                                1'b1:
//                                begin PC_SOURCE =3'b010; end
//                                default: 
//                                PC_SOURCE = 1'b0;
//                            endcase
//                        end  
                              
//                       3'b001: //Branch if not equal opcode
//                        begin
//                            case (BR_EQ) // First, check to see if br_eq is 0. If so, set PC_SOURCE to 2, otherwise set PC_SOURCE to 0
//                                1'b0:
//                                begin PC_SOURCE = 3'b010; end
//                                default:
//                                PC_SOURCE = 1'b0;
//                            endcase
//                        end        
                        
//                    default:
//                    ALU_FUN = 1'b0;
//                endcase
//            end
            
            7'b1101111: //J-type jal instruction
            begin
                //Set rf_wr_sel to 0
                RF_WR_SEL = 1'b0;
            end
            
            7'b1100111: //I-type jalr instruction
            begin
                //Set rf_wr_sel to 0
                RF_WR_SEL = 1'b0;
            end
            
// ---------------------------------- csrrw and mret commented out for now -------------------

//            7'b1110011: //csrrw or mret instruction
//                case(FUNCT3)
//                3'b001: //csrrw instruction
//                    begin PC_SOURCE = 1'b0;
//                    RF_WR_SEL = 3'b010; end
                    
//                3'b000:
//                    begin PC_SOURCE = 3'b101; end
//                endcase
                
//            default: //Default for OP_CODE
//            ALU_FUN = 1'b0;
        endcase
end
endmodule
