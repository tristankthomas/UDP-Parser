`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.01.2026 21:18:24
// Design Name: 
// Module Name: uart_tx
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

module uart_tx (
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in,
    input logic tx_start,
    output logic tx,
    output logic busy,
    output logic tx_done
);
    logic baud_tick;
    typedef enum logic [2:0] { IDLE, START, DATA, STOP, DONE } state_t;
    
    state_t state, next_state;
    logic [3:0] tick_cnt;
    logic [2:0] bit_cnt;
    logic [7:0] data_reg;
    logic tx_start_sync;
    
    uart_baud_gen baud_gen (
        .clk(clk),
        .rst(~rst_n),
        .baud_tick(baud_tick)
    );
    
    sync_ff #( .INIT(1'b0) ) sync_tx_start (
        .clk(clk),
        .rst_n(rst_n),
        .data(tx_start),
        .data_sync(tx_start_sync)
    ); 
   
    
    // control logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            state <= IDLE;
        else if (state == IDLE & tx_start_sync) begin
            state <= START;
        end else if (state == DONE)
            state <= IDLE;
        else if (baud_tick)
            state <= next_state;
    end
    
    // data logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            tick_cnt <= 0;
            bit_cnt <= 0;
            tx <= 1'b1;
            data_reg <= 8'h00;
        end else begin
            if (state == IDLE && tx_start_sync) begin
                data_reg <= data_in;
                tick_cnt <= 0;
                bit_cnt  <= 0;
            end else if (baud_tick)
                case (state)
                    IDLE : begin
                        tick_cnt <= 0;
                        bit_cnt <= 0;
                    end
                    START: begin
                        tx <= 1'b0;
                        tick_cnt <= tick_cnt + 1;
                    end
                    DATA: begin
                        tx <= data_reg[bit_cnt];
                        if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            bit_cnt <= bit_cnt + 1;
                        end else 
                            tick_cnt <= tick_cnt + 1;
                    end
                    STOP: begin
                        tx <= 1'b1;
                        tick_cnt <= tick_cnt + 1;
                    end
                                   
                endcase
        end        
    end
    
    // next state logic
    always_comb begin
        next_state = state;
        case (state)
            START: if (tick_cnt == 15) next_state = DATA;
            DATA:  if (tick_cnt == 15 && bit_cnt == 7) next_state = STOP;
            STOP:  if (tick_cnt == 15) next_state = DONE;
        endcase
    end
    
    // outputs
    assign busy = (state != IDLE);
    assign tx_done = (state == DONE);
    
    
    
endmodule
