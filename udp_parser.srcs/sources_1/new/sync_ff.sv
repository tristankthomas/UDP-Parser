`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.01.2026 21:22:49
// Design Name: 
// Module Name: sync_ff
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


module sync_ff #(
    parameter logic INIT = 1'b1
)(
    input logic clk,
    input logic rst_n,
    input logic data,
    output logic data_sync
);
    
    logic data_tmp;
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_tmp <= INIT;
            data_sync <= INIT;
        end else begin
            data_tmp <= data;
            data_sync <= data_tmp;
        end
    end
        
endmodule
