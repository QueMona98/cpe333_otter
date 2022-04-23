`timescale 1ns / 1ps

module ALU_HW_4(ALU_A, ALU_B, ALU_FUN, RESULT);
    input signed [31:0] ALU_A;
    input signed [31:0] ALU_B; //Two inputs from MUX outputs, output A and B
    input logic [3:0] ALU_FUN; //4-bit input for option for ALU
    output logic [31:0] RESULT; //32-bit output of ALU
   
   always_comb //Combinational logic (asynchronous clock)
   begin
   
    case (ALU_FUN) //Case statement for different cases of ALU_fun
        1'b0 :   RESULT = ALU_A + ALU_B; //ALU_FUN operation: add A and B
        4'b1000: RESULT = ALU_A - ALU_B; //ALU_FUN operation: subtract A from B
        4'b0110: RESULT = ALU_A | ALU_B; //ALU_FUN operation: OR A and B
        4'b0111: RESULT = ALU_A & ALU_B; //ALU_FUN operation: AND A and B
        4'b0100: RESULT = ALU_A ^ ALU_B; //ALU_FUN operation: XOR A and B
        4'b0101: RESULT = ALU_A >> ALU_B[4:0]; //ALU_FUN operation: Right-shift ALU_A the amount indicated by ALU_B, store in RESULT
        4'b0001: RESULT = ALU_A << ALU_B[4:0]; //ALU_FUN operation: Left-shift ALU_A the amount indicated by ALU_B, store in RESULT
        4'b1101: RESULT = ALU_A >>> ALU_B[4:0]; //ALU_FUN operation: Arithmetic right-shift ALU_A the amount indicated by ALU_B, store in RESULT
        4'b0010: if (ALU_A < ALU_B) RESULT  = 1'b1; else RESULT = 1'b0;
        //Statement above used when ALU_FUN is set to 1101 (set less than)
        // When ALU_A < ALU_B, set RESULT equal to 1, else set it to 0
        4'b0011: 
        begin //When ALU_FUN is set to 0011 (set less than unsigned), we need to recast the 
        // as unsigned values before we begin to compare them
        //Once this is done, it's just a matter of following the same format as slt
        if ($unsigned(ALU_A) < $unsigned(ALU_B)) RESULT = 1'b1; else RESULT = 1'b0;
        end
        4'b1001: RESULT = ALU_A; 
        // For option 1001 (lui-copy), the ALU will grab the value provided
        //by the 1st MUX (ALU_A). 
        default: RESULT = 0;
        //Since we don't want default to do anything, we just let the default case do nothing (set to 0)
     endcase
    end
   
endmodule