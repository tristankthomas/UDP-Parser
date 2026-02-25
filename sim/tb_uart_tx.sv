`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.01.2026 22:59:28
// Design Name: 
// Module Name: tb_uart_tx
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

module tb_uart_tx;
    parameter CLK_FREQ = 50_000_000;
    parameter real CLK_PERIOD = 1.0e9/CLK_FREQ;
    parameter BAUD_RATE = 9_600;
    parameter real BAUD_PERIOD = 1.0e9/BAUD_RATE;
    
    logic clk, rst_n, serial;
    logic [7:0] data_out, data_in;
    logic rx_busy, rx_valid, rx_error;
    logic tx_start, tx_busy, tx_done;
    logic [7:0] data_q[$];
    
    uart_tx uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .tx_start(tx_start),
        .tx(serial),
        .busy(tx_busy),
        .tx_done(tx_done)
    );
    
    uart_rx rx (
        .rx(serial),
        .clk(clk),
        .rst_n(rst_n),
        .data_out(data_out),
        .busy(rx_busy),
        .data_valid(rx_valid),
        .frame_err(rx_error)
    );
    
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
    
    task reset();
        rst_n = 0;
        tx_start = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
    endtask
    
    // driver
    task send_byte(input logic [7:0] data);
        @(negedge clk);
        data_q.push_back(data);
        data_in = data;
        tx_start = 1;
        @(negedge clk)
        tx_start = 0;
        
        fork : timeout_block
        begin
            wait(tx_done == 1);
            $display("[STATUS] Byte received");
        end 
        begin
            #(BAUD_PERIOD * 13)
            $display("[TIMEOUT] Byte not received");
        end
        join_any
        disable timeout_block;

    endtask
    
    // scoreboard
    always @(posedge tx_done) begin
        logic [7:0] data_ref;
        if (data_q.size() > 0) begin
            data_ref = data_q.pop_front();
            a_data_match: assert(data_out === data_in)
                $display("[PASS] Data %h successfully received by rx", data_out);
            else
                $display("[FAIL] Output data from rx %h does not match tx input data %h", data_out, data_in);
        end

    end
    
    initial begin
    
        $display("Simulation Started.");
        reset();
        
        repeat(10) begin
            send_byte($urandom);
        end
       

        $display("Simulation Finished.");
        $finish;
        
    end
        

endmodule
