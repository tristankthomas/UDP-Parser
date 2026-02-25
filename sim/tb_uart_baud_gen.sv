`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.12.2025 22:03:20
// Design Name: 
// Module Name: tb_uart_baud_gen
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

module tb_uart_baud_gen;

    parameter CLK_FREQ = 50_000_000;
    parameter real CLK_PERIOD = 1.0e9/CLK_FREQ;
    parameter BAUD_RATE = 9_600;
    parameter CLK_DIV = CLK_FREQ / (BAUD_RATE * 16);

    logic clk, rst, tick;

    uart_baud_gen uut (
        .clk(clk),
        .rst(rst),
        .baud_tick(tick)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    property p_tick_interval;
        @(posedge clk) disable iff (rst)
        tick |-> ##CLK_DIV tick;
    endproperty
    
    assert property (p_tick_interval) 
        else $error("Next tick did not occur at expected interval of %0d cycles", CLK_DIV);
        
    property p_pulse_width;
        @(posedge clk) disable iff (rst)
        tick |=> !tick;
    endproperty
    
    assert property (p_pulse_width) else $error("Baud tick wider than one clock cycle.");
    
    cover property (@(posedge clk) tick);
    

    realtime last_tick_time = 0;
    realtime current_period = 0;
    
    always_ff @(posedge tick) begin
        if (last_tick_time > 0) begin
            current_period = $realtime - last_tick_time;
            $display("[TIME: %0t] Tick detected. Period since last: %0f ns", $realtime, current_period);
        end
        last_tick_time = $realtime;
    end
    
    

    initial begin
        $display("Simulation Started.");

        rst = 1;
        repeat(10) @(posedge clk);
        rst = 0;

        #(CLK_PERIOD * CLK_DIV * 30);

        $display("Simulation Finished.");
        $finish;
    end

endmodule