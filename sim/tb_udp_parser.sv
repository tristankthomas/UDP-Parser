`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.02.2026 22:32:26
// Design Name: 
// Module Name: tb_udp_parser
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
import eth_pkg::*;

module tb_udp_parser;

    parameter CLK_FREQ = 50_000_000;
    parameter CLK_PERIOD = 1.0e9/CLK_FREQ;
    parameter DEST_PORT = 16'h1234;
    
    logic clk;
    logic rst_n;
    
    // input signals (simulating ip parser output)
    byte_t ip_data_in;
    logic ip_eof;
    logic ip_err;
    logic ip_byte_valid;
    
    // output signals from udp parser
    byte_t udp_data_out;
    logic udp_byte_valid;
    logic udp_eof;
    logic udp_err;
    
    byte_t rx_data_q[$]; 
    byte_t tx_data_q[$]; 
    logic error_expected = 1'b0;
    logic error_found = 1'b0;
    
    // instantiate uut
    udp_parser #(
        .DEST_PORT(DEST_PORT)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .ip_data_in(ip_data_in),
        .ip_eof(ip_eof),
        .ip_err(ip_err),
        .ip_byte_valid(ip_byte_valid),
        .udp_data_out(udp_data_out),
        .udp_byte_valid(udp_byte_valid),
        .udp_eof(udp_eof),
        .udp_err(udp_err)
    );
    
    // clk generation
    initial clk = 0;
    always #(CLK_PERIOD) clk <= ~clk;
    
    task reset;
        rst_n <= 1'b0;
        ip_err <= 1'b0;
        ip_eof <= 1'b0;
        ip_byte_valid <= 1'b0;
        @(posedge clk);
        rst_n <= 1'b1;
        @(posedge clk);
    endtask
    
    task send_ip_payload (
        input byte_t data,
        input logic eof = 0,
        input logic err = 0
    );
        ip_byte_valid <= 1'b1;
        ip_data_in <= data;
        ip_eof <= eof;
        ip_err <= err;
        @(posedge clk);
        ip_eof <= 1'b0;
        ip_err <= 1'b0;
        ip_byte_valid <= 1'b0;
        repeat(3) @(posedge clk);
    endtask
    
    // driver
    task send_udp_frame (
        input logic [15:0] src_port,
        input logic [15:0] dst_port,
        input byte_t payload[],
        input logic upstream_err,
        input logic total_len_err
    );
        logic [15:0] udp_len;

        $write("UDP Payload (%0d bytes): ", payload.size());
        foreach (payload[i]) $write("%02X ", payload[i]);
        $display("");

        error_expected = dst_port !== DEST_PORT || upstream_err || total_len_err;
        
        // send source port
        send_ip_payload(src_port[15:8]);
        send_ip_payload(src_port[7:0]);
        
        // send destination port
        send_ip_payload(dst_port[15:8]);
        send_ip_payload(dst_port[7:0]);
        
        // send length (header + payload)
        if (total_len_err) udp_len = 16'd9 + payload.size();
        else udp_len = 16'd8 + payload.size();
            
        send_ip_payload(udp_len[15:8]);
        send_ip_payload(udp_len[7:0]);
        
        // send checksum (dummy)
        send_ip_payload(8'h00);
        send_ip_payload(8'h00);
        
        // send payload
        foreach (payload[i]) begin
            if (!error_expected) tx_data_q.push_back(payload[i]);
            
            if (i == payload.size()-1) begin
                send_ip_payload(payload[i], 1, upstream_err);
            end else begin
                send_ip_payload(payload[i]);
            end
        end

        cleanup();
    endtask
    
    task cleanup;
        ip_byte_valid <= 1'b0;
        ip_eof <= 1'b0;
        ip_err <= 1'b0;
        repeat(4) @(posedge clk);
    endtask
    
    function automatic byte_array_t random_payload(input int length);
        byte_array_t payload = new[length];
        for (int i = 0; i < length; i++) payload[i] = $urandom();
        return payload;
    endfunction
    
    // scoreboard
    always @(posedge clk) begin
        if (udp_byte_valid) rx_data_q.push_back(udp_data_out);
        if (udp_err) error_found = 1'b1;
        if (udp_eof || udp_err) check_frame();
    end
    
    task check_frame;
        if (error_expected) begin
            if (error_found) $display("SUCCESS: Correctly caught expected error");
            else $display("FAIL: Expected error not caught");
        end else if (rx_data_q.size() != tx_data_q.size()) begin
            $display("ERROR: Frame size mismatch. Expected %d; Result %d", tx_data_q.size(), rx_data_q.size());
        end else begin
            automatic bit match = 1;
            foreach (tx_data_q[i]) begin
                if (tx_data_q[i] != rx_data_q[i]) begin
                    $display("ERROR: Byte mismatch at index %0d. Expected: %h, Result: %h", i, tx_data_q[i], rx_data_q[i]);
                    match = 0;
                end
            end
            if (match) $display("SUCCESS: Frame received correctly.");
        end

        tx_data_q.delete();
        rx_data_q.delete();
        error_found = 1'b0;
        error_expected = 1'b0;
    endtask
    
    initial begin
        reset();
        
        $display("--- Test 1: Valid UDP Frame ---");
        send_udp_frame(16'hAAAA, DEST_PORT, random_payload(20), 0, 1);
        
        $display("\n--- Test 2: Invalid Port ---");
        send_udp_frame(16'hAAAA, 16'h5555, random_payload(20), 0, 0);
        
        $display("\n--- Test 3: Upstream IP Error ---");
        send_udp_frame(16'hAAAA, DEST_PORT, random_payload(20), 1, 0);
        
        $display("\nSimulation Finished at %t", $time);
        $finish;
    end

endmodule
