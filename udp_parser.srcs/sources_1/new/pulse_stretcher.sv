`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.02.2026 20:40:18
// Design Name: 
// Module Name: pulse_stretcher
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


module pulse_stretcher #(
    parameter int COUNT_WIDTH = 23 // 2^23 @ 25MHz ~= 330ms
)(
    input logic clk,
    input logic rst_n,
    input logic trigger,
    output logic dout
);
    logic [COUNT_WIDTH-1:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
            dout <= 1'b0;
        end else begin
            if (trigger) begin
                counter <= '1;
                dout <= 1'b1;
            end else if (counter != '0) begin
                counter <= counter - 1'b1;
                dout <= 1'b1;
            end else begin
                dout <= 1'b0;
            end
        end
    end
endmodule
