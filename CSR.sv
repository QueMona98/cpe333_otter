`timescale 1ns / 1ps

module CSR_HW_8(RST, INT_TAKEN, ADDR, WR_EN, PC_ADDR, WD, CLK, CSR_MIE, CSR_MEPC, CSR_MTVEC, RD);

    input RST;
    input INT_TAKEN;
    input [11:0] ADDR;
    input WR_EN;
    input [31:0] PC_ADDR, WD;
    input CLK;
    output logic CSR_MIE;
    output logic [31:0] CSR_MEPC, CSR_MTVEC, RD;
    
    
    // Initialize CSR registers, 3 32-bit addresses
    logic [31:0]CSR[0:2];
    
    always_ff @ (posedge CLK) begin //Writing is synchronous, first check if reset is high
        
        if (RST) //On high Reset, set current CSRs to 0
        
            begin 
                CSR[0] <= 1'b0;
                CSR[1] <= 1'b0;
                CSR[2] <= 1'b0;
            end
             
       else
       
        if (WR_EN) begin//Now, check if csr_we is high. If so, check input addr to see where to write data
            case(ADDR)
                12'h305: begin //Write input WD to mtvec register (CSR[1])
                CSR[1] <= WD; 
                end
                
                12'h341: begin //Write current PC to mepc register (CSR[0])
                CSR[0] <= PC_ADDR;
                end
                
                12'h304: begin //Set mie to high (only consider bit 0) (CSR[2])
                CSR[2][0] <= WD[0];
                end
                
                default:
                CSR[2] <= 1'b0;
            endcase
        end
        
        if (INT_TAKEN) begin //If an interrupt is taken, set mie back to 0
            CSR[0] <= PC_ADDR;
            CSR[2][0] <= 1'b0;
        end
        
     end
   
   always_comb begin //Reading is asynchronous
   
        CSR_MIE = CSR[2][0];
        CSR_MEPC = CSR[0];
        CSR_MTVEC = CSR[1];
        RD = 0; // :Initialized output
        
        case (ADDR) //Case for RD based on ADDR
        
            12'h00000305: begin //RD mtvec register
            RD = CSR[1]; end
            
            12'h00000341: begin //RD mepc register
            RD = CSR[0]; end
            
            12'h00000304: begin //RD bit 0 of mie
            RD = CSR[2][0]; end
            
            default: begin //Default to remove any latches
            RD = 1'b0; end
            
        endcase
    end
endmodule
