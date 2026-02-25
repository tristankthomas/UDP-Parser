`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.02.2026 21:32:50
// Design Name: 
// Module Name: eth_parser
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


module eth_parser #(
    parameter ETHERTYPE
)(
    input logic clk,
    input logic rst_n,
    input logic fifo_valid,
    input byte_t data_in,
    input logic fifo_eof,
    input logic fifo_frame_err,
    output logic fifo_ready,
    output byte_t eth_data_out,
    output logic eth_byte_valid,
    output logic eth_eof,
    output logic eth_err
);

    typedef enum logic [1:0] { HEADER, PAYLOAD, ERROR } state_t;
    state_t state;
    
    logic [$clog2(ETH_HEADER_LEN)-1:0] byte_cnt;
    byte_t ethertype_msb;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            eth_data_out <= 7'b0;
            eth_byte_valid <= 1'b0;
            eth_eof <= 1'b0;
            fifo_ready <= 1'b0;
            byte_cnt <= '0;
            eth_err <= 1'b0;
            state <= HEADER;
            
        end else begin
            // these apply unless overridden below
            eth_byte_valid <= 1'b0;
            eth_eof <= 1'b0;
            eth_err <= 1'b0;
            fifo_ready <= 1'b1;// deal with this properly
            
            if (fifo_ready && fifo_valid) begin
                case (state)
                    
                    HEADER : begin
                        byte_cnt <= byte_cnt + 1'b1;
                        if (fifo_frame_err && fifo_eof) begin
                            // frame error from mac - rst count
                            eth_err <= 1'b1;
                            eth_eof <= 1'b1;
                            byte_cnt <= '0;
                        end else if (byte_cnt == ETHERTYPE_POS) begin
                            ethertype_msb <= data_in;
                        end else if (byte_cnt == ETHERTYPE_POS+1) begin
                            // check if frame is using IPv4
                            byte_cnt <= '0;
                            if ({ethertype_msb, data_in} == ETHERTYPE) begin
                                state <= PAYLOAD;
                            end else begin
                                eth_err <= 1'b1;
                                state <= ERROR;
                            end
                        end
                        

                    end
                    
                    PAYLOAD : begin
                        eth_byte_valid <= 1'b1;
                        if (fifo_frame_err && fifo_eof) begin
                            // frame error from crc - drop frame
                            eth_err <= 1'b1;
                            eth_eof <= 1'b1;
                            state <= HEADER;
                        end else begin
                            eth_data_out <= data_in;
                            
                            if (fifo_eof) begin
                                // end of valid frame
                                eth_eof <= 1'b1;
                                state <= HEADER;
                            end
                        
                        end

                    end
                    
                    
                    ERROR : begin
                        // flush the frame after finding new error (ethertype)
                        if (fifo_eof) begin
                            state <= HEADER;
                            byte_cnt <= '0;
                        end
                    end

                endcase
            
            end
        end

    end
    


endmodule
