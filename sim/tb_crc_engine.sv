`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.02.2026 19:45:12
// Design Name: 
// Module Name: tb_crc_engine
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


module tb_crc_engine;

    logic clk;
    logic rst_n;
    
    logic [7:0] tx_data;
    logic tx_en;
    logic [31:0] tx_result;
    

    logic [7:0] rx_data;
    logic rx_en;
    logic [31:0] rx_result;

    always #5 clk = ~clk;

    // calculates CRC on the payload
    crc_engine tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .byte_in(tx_data),
        .en(tx_en),
        .crc(tx_result)
    );

    // calculates CRC on payload + appended checksum
    crc_engine rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .byte_in(rx_data),
        .en(rx_en),
        .crc(rx_result)
    );


    initial begin

        clk = 0;
        rst_n = 0;
        tx_en = 0;
        rx_en = 0;
        tx_data = 0;
        rx_data = 0;
        
        @(posedge clk);
        rst_n = 1;
        
        // transmit simple payload
        drive_byte(8'h12);
        drive_byte(8'hCD);

        // ensure result is stable
        tx_en = 0;
        rx_en = 0;
        @(posedge clk);
        
        $display("Payload Sent: 0x12, 0xCD");
        $display("TX Generated CRC: %h", tx_result);
        tx_result = tx_result ^ 32'hFFFFFFFF;

        // transmit computed CRC from LSb to MSb in reflected mode (crc_engine flips bit order of bytes)
        rx_data = tx_result[7:0];
        rx_en = 1;
        @(posedge clk);
        rx_data = tx_result[15:8];
        @(posedge clk);
        rx_data = tx_result[23:16];
        @(posedge clk);
        rx_data = tx_result[31:24];
        @(posedge clk);
        rx_en = 0;
        @(posedge clk);

        $display("Final RX CRC (Residue): %h", rx_result);

        if (rx_result == 32'hDEBB20E3) begin
            $display("SUCCESS: Residue is 0xDEBB20E3");
        end else begin
            $display("FAILURE: Residue is %h (Expected 0xDEBB20E3).", rx_result);
        end
        
        $finish;
    end

    // drives RX and TX simulataneously to simulate data passing through on both sides
    task drive_byte(input [7:0] data);
        begin
            tx_en = 1;
            rx_en = 1;
            tx_data = data;
            rx_data = data;

            @(posedge clk);
        end
    endtask

endmodule