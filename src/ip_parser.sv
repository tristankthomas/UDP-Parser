`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.02.2026 20:14:21
// Design Name: 
// Module Name: ip_parser
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


module ip_parser #(
    parameter TRANSPORT_PROTOCOL,
    parameter IP_ADDRESS
)(
    input logic clk,
    input logic rst_n,
    input byte_t eth_data_in,
    input logic eth_eof,
    input logic eth_err,
    input logic eth_byte_valid,
    output byte_t ip_data_out,
    output logic ip_byte_valid,
    output logic ip_eof,
    output logic ip_err
);

    typedef enum logic [1:0] { HEADER, PAYLOAD, FLUSH } state_t;
    state_t state;
    logic [$clog2(MAX_IP_HEADER_LEN)-1:0] header_cnt;
    logic [15:0] curr_checksum;
    logic init_checksum;
    logic compute_checksum;
    
    ip_checksum_engine u_ip_checksum_engine (
         .clk(clk),
         .rst_n(rst_n),
         .byte_valid(eth_byte_valid),
         .byte_in(eth_data_in),
         .init(init_checksum),
         .en(compute_checksum),
         .checksum(curr_checksum)
    );
    
    logic [3:0] ihl;
    logic [15:0] ip_total_len;
    logic [31:0] ip_dest_addr;
    logic [15:0] payload_rem_cnt;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            ip_byte_valid <= 1'b0;
            ip_eof <= 1'b0;
            ip_err <= 1'b0;
            header_cnt <= '0;
            state <= HEADER;
            init_checksum <= 1'b1;
        end else begin
        
            ip_byte_valid <= 1'b0;
            ip_eof <= 1'b0;
            ip_err <= 1'b0;
            init_checksum <= 1'b0;
            
            if (eth_byte_valid) begin
                case (state)
                    HEADER: begin
                        case (header_cnt)
                            8'd0: begin
                                // IP version & ihl
                                if (eth_data_in[7:4] !== 4'd4) begin
                                    ip_err <= 1'b1;
                                    state <= FLUSH;
                                end
                                ihl <= eth_data_in[3:0];
                                header_cnt <= header_cnt + 1'b1;
                            end
                            
                            // skip tos
                            
                            // total packet length
                            8'd2: begin
                                ip_total_len[15:8] <= eth_data_in;
                                header_cnt <= header_cnt + 1'b1;
                            end
                            8'd3: begin
                                ip_total_len[7:0] <= eth_data_in;
                                header_cnt <= header_cnt + 1'b1;
                            end
                            
                            // skip ID, flags, frag and ttl
                            
                            // transport protocol
                            8'd9: begin
                                if (eth_data_in !== TRANSPORT_PROTOCOL) begin
                                    ip_err <= 1'b1;
                                    state <= FLUSH;
                                end
                                header_cnt <= header_cnt + 1'b1;
                            end
                            
                            // skip checksum and srs IP addr
                
                            8'd16, 8'd17, 8'd18: begin
                                header_cnt <= header_cnt + 1'b1;
                                ip_dest_addr <= {ip_dest_addr[23:0], eth_data_in};
                            end
                            
                            8'd19: begin
                                header_cnt <= header_cnt + 1'b1;
                                if ({ip_dest_addr[23:0], eth_data_in} !== IP_ADDRESS) begin
                                    ip_err <= 1'b1;
                                    state <= FLUSH;
                                end
                            end
                            
                            // add more options if required
                
                            default: header_cnt <= header_cnt + 1'b1;
                        endcase

                        // checksum check
                        if (header_cnt == (ihl << 2) - 1) begin
                            // checksum of header including checksum field should be 0
                            if (curr_checksum != 16'h0000) begin
                                ip_err <= 1'b1;
                                state <= FLUSH;
                            end else begin
                                state <= PAYLOAD;
                                payload_rem_cnt = ip_total_len - (ihl << 2);
                            end
                        end

                    end
                    PAYLOAD: begin
                        // ignores padding when ip_total_len < actual length - no error
                        if (payload_rem_cnt > 16'd0) begin
                            ip_byte_valid <= 1'b1;
                            ip_data_out <= eth_data_in;
                            payload_rem_cnt <= payload_rem_cnt - 1'b1;
                        end

                        if (eth_eof) begin
                            if (payload_rem_cnt > 16'd1) begin
                                // check if packet was truncated; ip_total_len > actual length - error
                                ip_err <= 1'b1;
                            end else if (eth_err) begin
                                // upstream error
                                ip_err <= 1'b1;
                            end
                            // end of frame valid
                            ip_eof <= 1'b1;
                            init_checksum <= 1'b1;
                            header_cnt <= '0;
                            state <= HEADER;
                        end
                    end
                        
                    FLUSH: begin
                        // flush the frame after finding new error in header (ip version/transport protocol/ip address/checksum)
                        if (eth_eof) begin
                            state <= HEADER;
                            header_cnt <= '0;
                            init_checksum <= 1'b1;
                        end
                    end
                    
                endcase
            end
            
        end
    
    end
    
    
    assign compute_checksum = (state == HEADER);
    
    
    
endmodule
