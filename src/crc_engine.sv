`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.02.2026 22:48:45
// Design Name: 
// Module Name: crc_engine
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


module crc_engine (
    input logic clk,
    input logic rst_n,
    input logic init,
    input logic [7:0] byte_in,
    input logic en,
    output logic [31:0] crc
);
    
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            crc <= 32'hFFFFFFFF;
        else if (init)
            crc <= 32'hFFFFFFFF;
        else if (en)
            crc <= next_crc(crc, byte_in);
    end
    
    
    // generated in scripts/crc_engine_gen.py
    // simulates 8 shifts of the LFSR
    function [31:0] next_crc;
        input [31:0] c;
        input [7:0] d;
        begin
            // this implicitly reverses d's bit order
            next_crc[0] = c[2] ^ c[8] ^ d[2];
            next_crc[1] = c[0] ^ c[3] ^ c[9] ^ d[0] ^ d[3];
            next_crc[2] = c[0] ^ c[1] ^ c[4] ^ c[10] ^ d[0] ^ d[1] ^ d[4];
            next_crc[3] = c[1] ^ c[2] ^ c[5] ^ c[11] ^ d[1] ^ d[2] ^ d[5];
            next_crc[4] = c[0] ^ c[2] ^ c[3] ^ c[6] ^ c[12] ^ d[0] ^ d[2] ^ d[3] ^ d[6];
            next_crc[5] = c[1] ^ c[3] ^ c[4] ^ c[7] ^ c[13] ^ d[1] ^ d[3] ^ d[4] ^ d[7];
            next_crc[6] = c[4] ^ c[5] ^ c[14] ^ d[4] ^ d[5];
            next_crc[7] = c[0] ^ c[5] ^ c[6] ^ c[15] ^ d[0] ^ d[5] ^ d[6];
            next_crc[8] = c[1] ^ c[6] ^ c[7] ^ c[16] ^ d[1] ^ d[6] ^ d[7];
            next_crc[9] = c[7] ^ c[17] ^ d[7];
            next_crc[10] = c[2] ^ c[18] ^ d[2];
            next_crc[11] = c[3] ^ c[19] ^ d[3];
            next_crc[12] = c[0] ^ c[4] ^ c[20] ^ d[0] ^ d[4];
            next_crc[13] = c[0] ^ c[1] ^ c[5] ^ c[21] ^ d[0] ^ d[1] ^ d[5];
            next_crc[14] = c[1] ^ c[2] ^ c[6] ^ c[22] ^ d[1] ^ d[2] ^ d[6];
            next_crc[15] = c[2] ^ c[3] ^ c[7] ^ c[23] ^ d[2] ^ d[3] ^ d[7];
            next_crc[16] = c[0] ^ c[2] ^ c[3] ^ c[4] ^ c[24] ^ d[0] ^ d[2] ^ d[3] ^ d[4];
            next_crc[17] = c[0] ^ c[1] ^ c[3] ^ c[4] ^ c[5] ^ c[25] ^ d[0] ^ d[1] ^ d[3] ^ d[4] ^ d[5];
            next_crc[18] = c[0] ^ c[1] ^ c[2] ^ c[4] ^ c[5] ^ c[6] ^ c[26] ^ d[0] ^ d[1] ^ d[2] ^ d[4] ^ d[5] ^ d[6];
            next_crc[19] = c[1] ^ c[2] ^ c[3] ^ c[5] ^ c[6] ^ c[7] ^ c[27] ^ d[1] ^ d[2] ^ d[3] ^ d[5] ^ d[6] ^ d[7];
            next_crc[20] = c[3] ^ c[4] ^ c[6] ^ c[7] ^ c[28] ^ d[3] ^ d[4] ^ d[6] ^ d[7];
            next_crc[21] = c[2] ^ c[4] ^ c[5] ^ c[7] ^ c[29] ^ d[2] ^ d[4] ^ d[5] ^ d[7];
            next_crc[22] = c[2] ^ c[3] ^ c[5] ^ c[6] ^ c[30] ^ d[2] ^ d[3] ^ d[5] ^ d[6];
            next_crc[23] = c[3] ^ c[4] ^ c[6] ^ c[7] ^ c[31] ^ d[3] ^ d[4] ^ d[6] ^ d[7];
            next_crc[24] = c[0] ^ c[2] ^ c[4] ^ c[5] ^ c[7] ^ d[0] ^ d[2] ^ d[4] ^ d[5] ^ d[7];
            next_crc[25] = c[0] ^ c[1] ^ c[2] ^ c[3] ^ c[5] ^ c[6] ^ d[0] ^ d[1] ^ d[2] ^ d[3] ^ d[5] ^ d[6];
            next_crc[26] = c[0] ^ c[1] ^ c[2] ^ c[3] ^ c[4] ^ c[6] ^ c[7] ^ d[0] ^ d[1] ^ d[2] ^ d[3] ^ d[4] ^ d[6] ^ d[7];
            next_crc[27] = c[1] ^ c[3] ^ c[4] ^ c[5] ^ c[7] ^ d[1] ^ d[3] ^ d[4] ^ d[5] ^ d[7];
            next_crc[28] = c[0] ^ c[4] ^ c[5] ^ c[6] ^ d[0] ^ d[4] ^ d[5] ^ d[6];
            next_crc[29] = c[0] ^ c[1] ^ c[5] ^ c[6] ^ c[7] ^ d[0] ^ d[1] ^ d[5] ^ d[6] ^ d[7];
            next_crc[30] = c[0] ^ c[1] ^ c[6] ^ c[7] ^ d[0] ^ d[1] ^ d[6] ^ d[7];
            next_crc[31] = c[1] ^ c[7] ^ d[1] ^ d[7];
        end
    endfunction
    
    
    

endmodule
