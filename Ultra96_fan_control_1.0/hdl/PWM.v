`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2018 05:46:04 AM
// Design Name: 
// Module Name: PWM
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


module PWM(
    input clk_in,
    input rst_n_in,
    input [11:0] val_in,
    output reg PWM_out
    );
    
    reg [11:0] counter = 0;

    
    always@ (posedge clk_in)
    begin
        if (rst_n_in == 1'b0)
        begin
            PWM_out = 1'b1;
            counter = 0;
        end
        else
        begin   
            if(val_in == 12'hFFF)
                PWM_out <= 1; 
            else if ( counter < val_in )
                PWM_out <= 1;
            else
                PWM_out <= 0;
            
             counter <= counter+1;
        end
    end
endmodule
