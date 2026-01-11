`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.01.2026 19:38:21
// Design Name: 
// Module Name: uart_rx
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


module uart_rx (
    input logic rx,
    input logic clk,
    input logic rst_n,
    output logic [7:0] data_out,
    output logic data_valid,
    output logic busy,
    output logic frame_err
);
    
    logic baud_tick;
    logic rx_sync;
    
    uart_baud_gen baud_gen (
        .clk(clk),
        .rst(~rst_n),
        .baud_tick(baud_tick)
    );
    
    sync_ff sync_rx (
        .clk(clk),
        .rst_n(rst_n),
        .data(rx),
        .data_sync(rx_sync)
    ); 

    
    typedef enum logic [2:0] { IDLE, START, DATA, STOP, DONE } state_t;
    logic [3:0] tick_cnt;
    logic [2:0] bit_cnt;
    logic [7:0] rx_shift_reg;
    state_t state, next_state;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
            tick_cnt <= 0;
            bit_cnt  <= 0;
            rx_shift_reg <= 0;
            data_out <= 0;
        end else if (baud_tick) begin
            case (state)
                IDLE: tick_cnt <= 0;
                
                START: begin
                    if (tick_cnt == 7) begin
                        tick_cnt <= 0;
                    end else begin
                        tick_cnt <= tick_cnt + 1;
                    end
                end
    
                DATA: begin
                    if (tick_cnt == 15) begin
                        tick_cnt <= 0;
                        bit_cnt <= bit_cnt + 1;
                        rx_shift_reg <= {rx_sync, rx_shift_reg[7:1]};        
                    end else begin
                        tick_cnt <= tick_cnt + 1;
                    end
                    
                end
                
                STOP: begin
                    if (tick_cnt == 15) begin
                        tick_cnt <= 0;
                        data_out <= rx_shift_reg;
                    end else begin
                        tick_cnt <= tick_cnt + 1;
                    end
                end
                
                DONE: begin
                    tick_cnt <= 0;
                    bit_cnt <= 0;
                end
                     
            endcase
            state <= next_state;
        end
        
    end
    
    always_comb begin
        // used for the case where if statements are false
        next_state = state;
        case (state)
            IDLE: begin
            if (rx_sync == 0) next_state = START;
            frame_err = 0;
            end
            START: if (tick_cnt == 7) next_state = DATA; 
            DATA: if (tick_cnt == 15 && bit_cnt == 7) next_state = STOP;
            STOP: begin
                if (tick_cnt == 15) begin
                    next_state = DONE;
                    frame_err = (rx_sync == 0);
                end
            end
            DONE: next_state = IDLE;
            default: next_state = state;
        endcase
   end 
    assign busy = (state != IDLE);
    assign data_valid = (state == DONE);
    
    
endmodule
