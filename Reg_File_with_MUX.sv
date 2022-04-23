`timescale 1ns / 1ps

module Reg_File_with_MUX(ALU_OUT, MEM_DOUT_2, CSR_RD, PC_4_OUT, RF_WR_SEL,
                         CLOCK, regWrite, input_reg, RF_RS1, RF_RS2);
                         
    //Inputs/outputs of MUX outside REG_FILE                     
    input [31:0] ALU_OUT, MEM_DOUT_2, CSR_RD, PC_4_OUT;
    input [1:0] RF_WR_SEL;
    
    //Inputs/outputs of Reg_File
    input CLOCK; // Input clock for reg_file
    input regWrite; //Input en, can be 0 or 1 to write wd to wa
    input [31:0] input_reg; //Input register
    output logic [31:0] RF_RS1; 
    output logic [31:0] RF_RS2; //32-bit outputs RS1 and RS2
    
    // Logic for output of MUX outside Reg_file
    logic [31:0] Mux_to_RegFile;
    
    Reg_file_MUX Mux (.ALU_OUT(ALU_OUT), .MEM_DOUT_2(MEM_DOUT_2), .CSR_RD(CSR_RD),
    .PC_OUT(PC_4_OUT), .RF_WR_SEL(RF_WR_SEL), .MUX_OUT(Mux_to_RegFile));
    
    Register_File_HW_3 RegFile (.CLOCK(CLOCK), .WD(Mux_to_RegFile), .ENABLE(regWrite),
    .input_reg(input_reg), .RF_RS1(RF_RS1), .RF_RS2(RF_RS2));
    

endmodule
