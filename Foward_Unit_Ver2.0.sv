`timescale 1ns / 1ps

module Foward_Unit(
    input logic [31:0] Execute_Register_SourceRegister_1, Execute_Register_SourceRegister_2,
    input logic [31:0] Memory_Register_value, WriteBack_Register_IOBUSaddr_value,
    input logic CLK,
    
    output logic [1:0] mux_srcA_priority_foward, 
    output logic [2:0] mux_srcB_priority_foward
    );
    
   //*******************************************************************************//  
   //********************************** Design Log ******************************************//  
   //  NOTE: positive edge will result in reading data and detecting for fowarding compability
   //   IF fowarding is detected then will we will be able to set path way via SRCA or SRCB MUX selector overide
   //
   //  NOTE: POSSIBLY create stalls to get corret results for certain instructions such as branch commands which need CLK
   //       and cannot be fowarding, MUST investigate which instructions require stalls
   //
   //   NOTE: Limiting Fowarding unit control arm to just last 2 input selection of ALU input muxes will help keep 
   //       output possibilites for control arms easier to debug pipeline processor side
   //
   //   ERROR: when both EP and WP outputs both match RS1 value we cannot produce and override signal for mux selctor
   //       Resolved: However need to add asyncronous read and sycrounous wire clearing to prevent signals going into next 
   //                   clock cycle
   //           Answer: On negative edge of clock signal Unit will output absolute zero signal 
   //                   will allow ALU mux to be able to differentiate from 3 different outputs
   //            ERROR: Throws invalid driver combination error, solve with use of register 
   //                    since we already have a time critical component, or make it combinational
   //
   //            NOTE: would still result with original error propegating with 
   //                 mux input not have a change in full clock cycle. However the fowarding goes into 
   //                 into non time critical components to have the proper value 
   //                 **** Maybe can have wire from INPUT REGISTER to send over register address location instead of matching by value output ****
   //                   General process of Unit shouldn't change as it its just a method matching and sending control arm signal to mux
   //                   Most likely would have values connected from pipelines outputs to mux and wires carrying corresponding array addresss foward to unit
  //            Note: added asyncrounous read to allow
   //*******************************************************************************//
   //*******************************************************************************//
   
    reg [1:0] A_override;
    reg [2:0] B_override;
   
   always_comb begin    // asyncronous read
   
    if(Execute_Register_SourceRegister_1 == Memory_Register_value) begin              // if rs1 is matching memory Pipeline output from WP pipeline
    
        if(Execute_Register_SourceRegister_2 == Memory_Register_value)begin
            A_override = 2'b10;      // OVERIDE to EP pipeline 
            B_override = 3'b100;     // OVERIDE to EP pipeline
            end
    
        if(Execute_Register_SourceRegister_2 == WriteBack_Register_IOBUSaddr_value)begin
            A_override = 2'b10;      // OVERIDE to EP pipeline
            B_override = 3'b101;     // OVERIDE to WP pipeline 
            end
    
        else begin
            A_override = 2'b10;      // OVERIDE MUX_SRCA to EP
            B_override = 1'b0;
            end
    
        end
      
    
    if(Execute_Register_SourceRegister_1 == WriteBack_Register_IOBUSaddr_value) begin    // if rs2 is matching writeback Pipeline output from ALU
    
        if(Execute_Register_SourceRegister_2 == Memory_Register_value)begin
            A_override = 2'b11;      // OVERIDE to WP pipeline 
            B_override = 3'b100;     // OVERIDE to EP pipeline
            end
    
        if(Execute_Register_SourceRegister_2 == WriteBack_Register_IOBUSaddr_value)begin
            A_override = 2'b11;      // OVERIDE to WP pipeline
            B_override = 3'b101;     // OVERIDE to WP pipeline 
            end
    
        else begin
            A_override = 2'b11;      // OVERIDE MUX_SRCA to WP
            B_override = 1'b0;
            end
            
        end
    
    if(Execute_Register_SourceRegister_2 == Memory_Register_value) begin    // if rs1 is matching memory Pipeline output from ALU
        
        if(Execute_Register_SourceRegister_1 == Memory_Register_value)begin
            A_override = 2'b10;      // OVERIDE to EP pipeline 
            B_override = 3'b100;     // OVERIDE to EP pipeline
            end
    
        if(Execute_Register_SourceRegister_1 == WriteBack_Register_IOBUSaddr_value)begin
            A_override = 2'b11;      // OVERIDE to WP pipeline
            B_override = 3'b100;     // OVERIDE to EP pipeline 
            end
    
        else begin
             B_override = 3'b100;      // OVERIDE MUX_SRCB to EP
             A_override = 1'b0;
             end
        
        end
    
    if(Execute_Register_SourceRegister_2 == WriteBack_Register_IOBUSaddr_value) begin    // if rs2 is matching writeback Pipeline output from ALU
        /// ********* ERROR with else case here in these sections ************* ///
        if(Execute_Register_SourceRegister_1 == Memory_Register_value)begin
            A_override = 2'b10;      // OVERIDE to EP pipeline 
            B_override = 3'b101;     // OVERIDE to WP pipeline
            end
    
        if(Execute_Register_SourceRegister_1 == WriteBack_Register_IOBUSaddr_value)begin
            A_override = 2'b11;      // OVERIDE to WP pipeline
            B_override = 3'b101;     // OVERIDE to WP pipeline 
            end
    
        else begin
             B_override = 3'b101;      // OVERIDE MUX_SRCB to WP
             A_override = 1'b0;
             end
    
        end
   
   end
   
//-----------------------------------------------------------------------------------------------------------------------------------------//   
//-----------------------------------------------------------------------------------------------------------------------------------------//
//-----------------------------------------------------------------------------------------------------------------------------------------//
//-----------------------------------------------------------------------------------------------------------------------------------------//
//-----------------------------------------------------------------------------------------------------------------------------------------//
//-----------------------------------------------------------------------------------------------------------------------------------------//
   
    always_ff @ (posedge CLK) begin
    
    mux_srcB_priority_foward <= B_override;      // OVERIDE MUX_SRCB to EP
    mux_srcA_priority_foward <= A_override;
    
//    if(Execute_Register_SourceRegister_1 == Memory_Register_value) begin              // if rs1 is matching memory Pipeline output from WP pipeline
    
//        if(Execute_Register_SourceRegister_2 == Memory_Register_value)begin
//            mux_srcA_priority_foward <= A_override;      // OVERIDE to EP pipeline 
//            mux_srcB_priority_foward <= B_override;     // OVERIDE to EP pipeline
//            end
    
//        if(Execute_Register_SourceRegister_2 == WriteBack_Register_IOBUSaddr_value)begin
//            mux_srcA_priority_foward <= A_override;      // OVERIDE to EP pipeline
//            mux_srcB_priority_foward <= B_override;     // OVERIDE to WP pipeline 
//            end
    
//        else
//            mux_srcA_priority_foward <= A_override;      // OVERIDE MUX_SRCA to EP
//            mux_srcB_priority_foward <= B_override;
    
//        end
      
    
//    if(Execute_Register_SourceRegister_1 == WriteBack_Register_IOBUSaddr_value) begin    // if rs2 is matching writeback Pipeline output from ALU
    
//        if(Execute_Register_SourceRegister_2 == Memory_Register_value)begin
//            mux_srcA_priority_foward <= A_override;      // OVERIDE to WP pipeline 
//            mux_srcB_priority_foward <= B_override;     // OVERIDE to EP pipeline
//            end
    
//        if(Execute_Register_SourceRegister_2 == WriteBack_Register_IOBUSaddr_value)begin
//            mux_srcA_priority_foward <= A_override;      // OVERIDE to WP pipeline
//            mux_srcB_priority_foward <= B_override;     // OVERIDE to WP pipeline 
//            end
    
//        else
//            mux_srcA_priority_foward <= A_override;      // OVERIDE MUX_SRCA to WP
//            mux_srcB_priority_foward <= B_override;
            
//        end
    
//    if(Execute_Register_SourceRegister_2 == Memory_Register_value) begin    // if rs1 is matching memory Pipeline output from ALU
        
//        if(Execute_Register_SourceRegister_1 == Memory_Register_value)begin
//            mux_srcA_priority_foward <= A_override;      // OVERIDE to EP pipeline 
//            mux_srcB_priority_foward <= B_override;     // OVERIDE to EP pipeline
//            end
    
//        if(Execute_Register_SourceRegister_1 == WriteBack_Register_IOBUSaddr_value)begin
//            mux_srcA_priority_foward <= A_override;      // OVERIDE to WP pipeline
//            mux_srcB_priority_foward <= B_override;     // OVERIDE to EP pipeline 
//            end
    
//        else
//             mux_srcB_priority_foward <= B_override;      // OVERIDE MUX_SRCB to EP
//             mux_srcA_priority_foward <= A_override;
        
//        end
    
//    if(Execute_Register_SourceRegister_2 == WriteBack_Register_IOBUSaddr_value) begin    // if rs2 is matching writeback Pipeline output from ALU
        
//        if(Execute_Register_SourceRegister_1 == Memory_Register_value)begin
//            mux_srcA_priority_foward <= A_override;      // OVERIDE to EP pipeline 
//            mux_srcB_priority_foward <= B_override;     // OVERIDE to WP pipeline
//            end
    
//        if(Execute_Register_SourceRegister_1 == WriteBack_Register_IOBUSaddr_value)begin
//            mux_srcA_priority_foward <= A_override;      // OVERIDE to WP pipeline
//            mux_srcB_priority_foward <= B_override;     // OVERIDE to WP pipeline 
//            end
    
//        else
//             mux_srcB_priority_foward <= B_override;      // OVERIDE MUX_SRCB to WP
//             mux_srcA_priority_foward <= A_override;
    
//        end
      
      end
 
      
           
endmodule
