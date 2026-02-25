`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.02.2026 23:22:28
// Design Name: 
// Module Name: phy_test_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// this module was created to debug the PHY
// Microphase xdc incorrectly defines ETH_nRST as pin H20 instead of pin J20
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module phy_test_top (
    input  logic sys_clk,
    output logic ETH_nRST,
    input  logic ETH_TXCK,
    input  logic ETH_RXCK,
    output logic PL_LED1,
    output logic PL_LED2
);

    // create a ~335ms delay at 50MHz
    logic [24:0] r_cnt = 25'd0;
    
    always_ff @(posedge sys_clk) begin
        if (!r_cnt[24]) begin
            r_cnt <= r_cnt + 1'b1;
        end
    end

    // reset transitions from low to high after delay and stays there.
    assign ETH_nRST = r_cnt[24]; 


    logic [23:0] rx_cnt = 24'd0;
    logic [23:0] tx_cnt = 24'd0;

    // LED1 blinks if ETH_RXCK is active
    always_ff @(posedge ETH_RXCK) begin
        rx_cnt <= rx_cnt + 1'b1;
    end
    assign PL_LED1 = rx_cnt[23]; 

    // LED2 blinks if ETH_TXCK is active
    always_ff @(posedge ETH_TXCK) begin
        tx_cnt <= tx_cnt + 1'b1;
    end
    assign PL_LED2 = tx_cnt[23];

endmodule
