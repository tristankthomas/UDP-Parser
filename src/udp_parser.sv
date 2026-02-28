`timescale 1ns / 1ps

import eth_pkg::*;

module udp_parser #(
    parameter [15:0] DEST_PORT = 16'h1234
)(
    input logic clk,
    input logic rst_n,
    input byte_t ip_data_in,
    input logic ip_eof,
    input logic ip_err,
    input logic ip_byte_valid,
    output byte_t udp_data_out,
    output logic udp_byte_valid,
    output logic udp_eof,
    output logic udp_err
);
    
    typedef enum logic [1:0] { HEADER, PAYLOAD, FLUSH } state_t;
    state_t state;
    
    // header_cnt width covers the 8-byte UDP header
    logic [$clog2(UDP_HEADER_LEN)-1:0] header_cnt;
    
    // internal registers for header fields
    logic [15:0] src_port;
    logic [15:0] dest_port;
    logic [15:0] udp_len;
    logic [15:0] udp_checksum;
    logic [15:0] payload_rem_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            udp_byte_valid <= 1'b0;
            udp_eof <= 1'b0;
            udp_err <= 1'b0;
            header_cnt <= '0;
            state <= HEADER;
        end else begin
            
            // default output assignments
            udp_byte_valid <= 1'b0;
            udp_eof <= 1'b0;
            udp_err <= 1'b0;

            if (ip_byte_valid) begin
                case (state)
                    HEADER: begin
                        case (header_cnt)
                            // bytes 1 and 2: source port
                            8'd0: begin
                                src_port[15:8] <= ip_data_in;
                                header_cnt <= header_cnt + 1'b1;
                            end
                            8'd1: begin
                                src_port[7:0] <= ip_data_in;
                                header_cnt <= header_cnt + 1'b1;
                            end

                            // bytes 3 and 4: destination port
                            8'd2: begin
                                dest_port[15:8] <= ip_data_in;
                                header_cnt <= header_cnt + 1'b1;
                            end
                            8'd3: begin
                                if (DEST_PORT != {dest_port[15:8], ip_data_in}) begin
                                    udp_err <= 1'b1;
                                    state <= FLUSH;
                                end
                                header_cnt <= header_cnt + 1'b1;
                            end

                            // bytes 5 and 6: length
                            8'd4: begin
                                udp_len[15:8] <= ip_data_in;
                                header_cnt <= header_cnt + 1'b1;
                            end
                            8'd5: begin
                                udp_len[7:0] <= ip_data_in;
                                header_cnt <= header_cnt + 1'b1;
                            end

                            // bytes 7 and 8: checksum
                            8'd6: begin
                                udp_checksum[15:8] <= ip_data_in;
                                header_cnt <= header_cnt + 1'b1;
                            end
                            
                            8'd7: begin
                                udp_checksum[7:0] <= ip_data_in;
                                header_cnt <= '0;
                                payload_rem_cnt <= udp_len - 16'd8;
                                state <= PAYLOAD;
                            end

                            default: header_cnt <= header_cnt + 1'b1;
                        endcase
                    end
                    
                    PAYLOAD: begin
                        // ignores any paddig missed by IP layer
                        if (payload_rem_cnt > 16'h0) begin
                            udp_byte_valid <= 1'b1;
                            udp_data_out <= ip_data_in;
                            payload_rem_cnt <= payload_rem_cnt - 1'b1;
                        end

                        if (ip_eof) begin
                        
                            if (payload_rem_cnt > 16'h1) begin
                                // IP frame ended before UDP payload was finished
                                udp_err <= 1'b1;
                            end else if (ip_err) begin
                                // upstream error
                                udp_err <= 1'b1;
                            end
                            
                            udp_eof <= 1'b1;
                            state <= HEADER;
                            header_cnt <= '0;
                        end
                    end
                    
                    FLUSH: begin
                        // flush frame until end of ip packet
                        if (ip_eof) begin
                            state <= HEADER;
                            header_cnt <= '0;
                        end
                    end
                    
                    default: state <= FLUSH;
                endcase
            end
        end
    end

endmodule