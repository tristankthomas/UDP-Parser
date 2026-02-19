`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.02.2026 18:57:01
// Design Name: 
// Module Name: eth_parser_tb
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


module eth_parser_tb;

    parameter CLK_FREQ = 50_000_000;
    parameter CLK_PERIOD = 1.0e9/CLK_FREQ;
    parameter ETHERTYPE = 16'h0800;
    
    logic clk;
    logic rst_n;
    logic fifo_valid;
    byte_t data_in;
    logic fifo_eof;
    logic fifo_frame_err;
    logic fifo_ready;
    byte_t eth_data_out;
    logic eth_byte_valid;
    logic eth_eof;
    logic eth_err;
    
    byte_t rx_data_q[$]; // data outputted to IP parser 
    byte_t tx_data_q[$]; // data inputted from FIFO
    logic error_expected = 1'b0;
    logic error_found = 1'b0;
    
    // instantiate uut
    eth_parser #(
        .ETHERTYPE(ETHERTYPE)
    ) uut (.*);
    
    // clk generation
    initial clk = 0;
    always #(CLK_PERIOD) clk <= ~clk;
    
    
    task reset;
        rst_n <= 1'b0;
        fifo_frame_err <= 1'b0;
        fifo_eof <= 1'b0;
        fifo_valid <= 1'b0;
        @(posedge clk);
        rst_n <= 1'b1;
        @(posedge clk);
    endtask
    
    task send_data (input byte_t data);
        fifo_valid <= 1'b1;
        data_in <= data;
        @(posedge clk);
        fifo_valid <= 1'b0;
        repeat(3) @(posedge clk);
        
    endtask
    
    // driver
    task send_frame (
        input byte_t [1:0] ether_type,
        input byte_t payload[],
        input logic crc_err,
        input logic mac_err
    );
        error_expected = mac_err || crc_err || (ether_type != ETHERTYPE);
        
        // send mac addresses
        for (int i = 0; i < 12; i++) begin
            if (mac_err) begin
                fifo_frame_err <= 1'b1;
                fifo_eof <= 1'b1;
                send_data($urandom());
                cleanup();
                return;
            end
            send_data($urandom());
        end
        
        // send ethertype
        for (int i = 1; i >= 0; i--) begin
            send_data(ether_type[i]);
        end
        
        // send payload
        foreach (payload[i]) begin
            tx_data_q.push_back(payload[i]);
            if (i == payload.size()-1) begin
                if (crc_err) fifo_frame_err <= 1'b1;
                fifo_eof <= 1'b1;
                send_data(payload[i]);
                break;
            end
            send_data(payload[i]);
            
        end

        cleanup();
       
    endtask
    
    task cleanup;
        fifo_valid <= 1'b0;
        fifo_eof <= 1'b0;
        fifo_frame_err <= 1'b0;
        repeat(2) @(posedge clk);
    endtask
    
    function automatic byte_array_t random_payload(input int length);
        byte_array_t payload;
        payload = new[length];
    
        for (int i = 0; i < length; i++) begin
            payload[i] = $urandom_range(0, 255);
        end
    
        return payload;
    endfunction
    
    
    // scoreboard
    always @(posedge clk) begin
        // add received byte to queue
        if (eth_byte_valid) rx_data_q.push_back(eth_data_out);
        
        // if error occurs log it
        if (eth_err) error_found = 1'b1;;
        
        // check results once frame complete
        if (eth_eof | eth_err) check_frame();
    end
    
    
    task check_frame;
        if (error_expected) begin
            // check error handling
            if (error_found) begin
                $display("SUCCESS: Correctly caught expected error");
            end else begin
                $display("FAIL: Expected error not caught");
            end
            
        end else if (rx_data_q.size() != tx_data_q.size())
            $display("ERROR: Frame size mismatch. Expected %d; Result %d", tx_data_q.size(), rx_data_q.size());
        else begin
            // check data was received correctly
            automatic bit match = 1;
            foreach (tx_data_q[i]) begin
                if (tx_data_q[i] != rx_data_q[i]) begin
                    $display("ERROR: Byte mismatch. Expected: %h, Result: %h", tx_data_q[i], rx_data_q[i]);
                    match = 0;
                end
            
            end
            if (match) begin
                $display("SUCCESS: Frame recevied correctly.");
            end
            
        end
        // clear queues for new frame
        tx_data_q.delete();
        rx_data_q.delete();
        error_found = 1'b0;
        error_expected = 1'b0;
    endtask
    
    
    initial begin
    
        reset();
        
        $display("Sending valid frame");
        // valid frame
        send_frame(
            16'h0800,
            random_payload(55),
            0,
            0
        );
        
        $display("\nSending error frame - wrong ethertype");
        // wrong ethertype
        send_frame(
            16'hFFFF,
            random_payload(18),
            0,
            0
        );
        
        $display("\nSending error frame - CRC");
        // crc error
        send_frame(
            16'h0800,
            random_payload(64),
            1,
            0
        );

        $display("\nSending error frame - wrong mac address");
        // mac error
        send_frame(
            16'h0800,
            random_payload(32),
            0,
            1
        );
        
        $display("\nSending error frame - wrong ethertype & CRC");
        // crc and ethertype error
        send_frame(
            16'hABCD,
            random_payload(20),
            1,
            0
        );
        $display("\nSimulation Finished at %t", $time);
        $finish;
    end
    
endmodule
