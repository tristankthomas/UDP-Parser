`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.12.2025 20:56:02
// Design Name: 
// Module Name: uart_baud_gen
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


module uart_baud_gen #(
    parameter int BAUD_RATE = 9600,
    parameter int SAMPLING_RATE = 16,
    parameter int CLK_FREQ = 50_000_000
        
)(
    input clk,
    input rst,
    output baud_tick
);

    localparam CLK_DIV = CLK_FREQ / (BAUD_RATE * SAMPLING_RATE); // clk_freq / sample_freq
    
    logic [$clog2(CLK_DIV)-1:0] count;
    
    always_ff @(posedge clk or posedge rst)
        if (rst)
            count <= 0;
        else if (count == CLK_DIV - 1)
            count <= 0;
        else
            count <= count + 1;
     
     assign baud_tick = count == CLK_DIV-1;
            

    
    
endmodule
