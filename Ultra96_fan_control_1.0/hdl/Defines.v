`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/15/2018 07:17:27 PM
// Design Name: 
// Module Name: Defines
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


`define FixedTotalBits 32
`define FixedFractionalBits 8
`define FixedShift (1 << `FixedFractionalBits)
`define FixedHalf {`FixedFractionalBits-1{1'b1}}
`define FixedUnsignedBits (TotalBits - FractionalBits)
`define UFixed [`FixedTotalBits-1:0] 

`define UnsignedTotalBits 16
`define Unsigned [`UnsignedTotalBits-1:0] 
