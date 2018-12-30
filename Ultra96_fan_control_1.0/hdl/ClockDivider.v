`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2018 09:43:47 AM
// Design Name: 
// Module Name: ClockDivider
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


module ClockDivider(
    input clk_in,
    input rst_n_in,
    input [31:0] divider_in,
    output reg clk_out
    );
    
    reg [31:0] count=31'b0;
    reg [31:0] cur_divider=31'b0;
     
    always @ (posedge(clk_in))
    begin
        if (rst_n_in == 1'b0)
            count <= 31'b0;
        else if (count >= divider_in)
            count <= 31'b0;
        else
            count <= count + 1;
    end
    
    always @ (posedge(clk_in))
    begin
        if (rst_n_in == 1'b0)
            clk_out <= 1'b0;
        else  if (count >= divider_in)
            clk_out <= ~clk_out;
        else
            clk_out <= clk_out;
    end

endmodule