`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.01.2026 21:46:01
// Design Name: 
// Module Name: tb_uart_rx
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

module tb_uart_rx;

    parameter CLK_FREQ = 50_000_000;
    parameter real CLK_PERIOD = 1.0e9/CLK_FREQ;
    parameter BAUD_RATE = 9_600;
    parameter real BAUD_PERIOD = 1.0e9/BAUD_RATE;
    
    logic clk, rst_n, rx;
    logic [7:0] data_out;
    logic busy, data_valid, error;
    logic [7:0] data_q[$];
    bit error_q[$];
    
    
    uart_rx uut (
        .rx(rx),
        .clk(clk),
        .rst_n(rst_n),
        .data_out(data_out),
        .busy(busy),
        .data_valid(data_valid),
        .frame_err(error)
    );
    
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
    
    clocking cb @(posedge clk);
        default input #1ns output #0ns;
        input data_valid, data_out, error, busy;
        output rx;
    endclocking
    
    
    
    // covergroup
    covergroup uart_rx_cg;
        cp_data: coverpoint data_out {
            bins corner_cases[] = {8'h00, 8'hFF, 8'h55, 8'hAA};
            bins all_others     = {[8'h01:8'hFE]};
        }
        cp_error: coverpoint error;
        cross_data_err: cross cp_data, cp_error;
    endgroup
    
    
    uart_rx_cg cg_inst;
    
    
    // driver
    task automatic send_byte(input [7:0] data, input bit corrupt=0);
        data_q.push_back(data);
        error_q.push_back(corrupt);
        $display("[TX] Starting transmission of 0x%h", data);
        
        // start bit
        cb.rx <= 1'b0;
        #(BAUD_PERIOD);
        
        // data bits (LSB first)
        for (int i = 0; i < 8; i++) begin
            cb.rx <= data[i];
            #(BAUD_PERIOD);
        end
        
        // stop bit
        cb.rx <= corrupt ? 1'b0 : 1'b1;
        #(BAUD_PERIOD);
        
    endtask
    
    task reset();
        rx <= 1;
        rst_n = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
    endtask
   
    
    // scoreboard
    always @(cb) begin
        if (cb.data_valid) begin
            logic [7:0] data_ref;
            bit error_ref;
            
            if (data_q.size() > 0) begin
                data_ref = data_q.pop_front();
                error_ref = error_q.pop_front();
                
                a_error_bit: assert (cb.error === error_ref)
                    $display("[PASS] Error bit matches: %b", cb.error);
                else
                    $error("[FAIL] Error bit mismatch! Exp: %b, Got: %b", error_ref, cb.error);
                    
                if (!cb.error) begin
                    a_data_mismatch: assert(cb.data_out === data_ref)
                        $display("[PASS] Received: 0x%h", cb.data_out);
                    else
                        $error("[FAIL] Data mismatch! Exp: 0x%h, Got: 0x%h", data_ref, cb.data_out);
                end
            end
            cg_inst.sample();
        end
    end
   
    
    // test sequence
    initial begin
        logic [7:0] r_data;
        cg_inst = new();
        $display("Simulation Started.");
        reset();
        
        // sending random data
        repeat (10) begin
            r_data = $urandom;
            send_byte(r_data);
            #(BAUD_PERIOD * $urandom_range(0, 5)); 
        end
        
        // corner cases
        send_byte(8'h00);
        send_byte(8'hFF);
        send_byte(8'h55);
        send_byte(8'hAA);
        
        // corrupted byte
        send_byte($urandom, 1);
        
        
        // wait until all data is processed
        fork : timeout_block
            begin
                wait(data_q.size() == 0);
                $display("[STATUS] All bytes processed.");
            end
            begin
                #(BAUD_PERIOD * 11 * 5); 
                $error("[TIMEOUT] Simulation timed out. Queue size remaining: %0d", data_q.size());
            end
        join_any
        disable timeout_block;
        
        $display("Simulation Finished.");
        $finish;
    end      
    
endmodule