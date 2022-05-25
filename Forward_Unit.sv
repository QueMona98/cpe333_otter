`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2022 02:12:11 AM
// Design Name: 
// Module Name: Forward_Unit
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


module Forward_Unit(
    // inputs will register addressses most likely and will be changed to 5 bits internally at checks or via wire usage
    input logic [4:0] ID_EX_RS1, ID_EX_RS2, EX_MS_RD, MS_WB_RD,
    input logic EX_MS_regWrite, MS_WB_regWrite,
    
    output logic [1:0] A_override, B_override
    );
    
    always_comb begin
    
        // EX hazards
        if (EX_MS_regWrite && (EX_MS_RD != 0) && (EX_MS_RD == ID_EX_RS1)) begin
            A_override = 2'b10;
            if (EX_MS_regWrite && (EX_MS_RD != 0) && (EX_MS_RD == ID_EX_RS2)) begin
                B_override = 2'b10;
            end
            else
                B_override = 0;
        end
        
        else if (EX_MS_regWrite && (EX_MS_RD != 0) && (EX_MS_RD == ID_EX_RS2)) begin
            B_override = 2'b10;
            if (EX_MS_regWrite && (EX_MS_RD != 0)&& (EX_MS_RD == ID_EX_RS1)) begin
                A_override = 2'b10;
            end
            else
                A_override = 0;
        end
        
        // MEM hazards
        else if (MS_WB_regWrite && (MS_WB_RD != 0) && (MS_WB_RD == ID_EX_RS1)) begin
            A_override = 2'b01;
            if (MS_WB_regWrite && (MS_WB_RD != 0) && (MS_WB_RD == ID_EX_RS2)) begin
                B_override = 2'b01;
            end
            else
                B_override = 0;
        end
        
        else if (MS_WB_regWrite && (MS_WB_RD != 0) && (MS_WB_RD == ID_EX_RS2)) begin
            B_override = 2'b01;
            if (MS_WB_regWrite && (MS_WB_RD != 0) && (MS_WB_RD == ID_EX_RS1)) begin
                A_override = 2'b01;
            end
            else
                A_override = 0;
        end
        else
            A_override = 0;
            B_override = 0;
    end
        
endmodule
