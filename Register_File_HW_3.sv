`timescale 1ns / 1ps

module Register_File_HW_3(CLOCK, WD, ENABLE, input_reg, RF_RS1, RF_RS2);

    input CLOCK; // Input clock for reg_file
    input [31:0] WD; //Input wd
    input ENABLE; //Input en, can be 0 or 1 to write wd to wa
    input [31:0] input_reg; //Input register
    output logic [31:0] RF_RS1; 
    output logic [31:0] RF_RS2; //32-bit outputs RS1 and RS2
    
    logic [31:0]RAM[0:31]; //Input RAM
    logic [4:0] adr1, adr2, wa; // Logics for adr1, adr2, and wa
    
  //Intitalize RAM   
  initial begin
  int i;
  for (i=0; i<32; i=i+1) begin
    RAM[i] = 0;
  end
end

   always_comb begin
    adr1 = input_reg[19:15]; //assign address 1 value to the specified bits from input_reg 
    adr2 = input_reg[24:20]; //assign address 2 value to the specified bits from input_reg 
    wa = input_reg[11:7]; ////assign wa to the specified bits from input_reg 
     //Note: Specified bits from input_reg determined by OTTR_architecture
  
    //Asynchronous from CLOCK, output values at specified RAM address
    RF_RS1 = RAM[adr1]; 
    RF_RS2 = RAM[adr2];
  end
  
//Whenever clock is HIGH
always_ff @ (posedge CLOCK)
    begin
       if(ENABLE) //When enable is HIGH, set data specified RAM address determined by wa equal to wd (saving data)
       begin
            RAM[wa] <= WD;
       end      //Set value at register 0 equal to 0 (hardwired to 0)
       RAM[0] <= 32'h00;
    end
endmodule
