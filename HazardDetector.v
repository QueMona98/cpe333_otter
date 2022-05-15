`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2022 09:22:04 AM
// Design Name: // Module Name: HazardDetector
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module HazardDetector(
    input CLK,
    input logic [31:0] ID_EX_MemRead,
    input logic [31:0] instruction,
    input logic [4:0] ID_EX_RS2,
    output logic select,
    output logic PCWrite,
    output logic IF_ID_Write
    );
    
    logic [4:0] IF_ID_RS1, IF_ID_RS2;
    
    assign IF_ID_RS1 = instruction[19:15];  // fix
    assign IF_ID_RS2 = instruction [19:15];
    
    always_ff @(posedge CLK) begin
        
        // data hazard
        // Note: only detecting load-use hazard because forwarding is implemented
        if(ID_EX_MemRead && ((ID_EX_RS2 == IF_ID_RS1) || (ID_EX_RS2 == IF_ID_RS2)))begin
            select <= 0;
            PCWrite <= 0;
            IF_ID_Write <= 0;
        end
        else begin
            select <= 1;
            PCWrite <= 1;
            IF_ID_Write <= 1;
        end     
        
        // control hazard
    end
endmodule
