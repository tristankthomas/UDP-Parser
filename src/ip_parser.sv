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

    typedef enum logic [1:0] { HEADER, PAYLOAD, ERROR } state_t;
    state_t state;
    logic [$clog2(MAX_IP_HEADER_LEN)-1:0] header_cnt;
    
    logic [3:0] ihl;
    logic [15:0] ip_total_len;
    logic [31:0] ip_dest_addr;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            ip_byte_valid <= 1'b0;
            ip_eof <= 1'b0;
            ip_err <= 1'b0;
            header_cnt <= '0;
            state <= HEADER;
        end else begin
        
            ip_byte_valid <= 1'b0;
            ip_eof <= 1'b0;
            ip_err <= 1'b0;
            // TODO: align ensure alignment with data
            if (eth_byte_valid) begin
                case (state)
                    HEADER: begin
                        case (header_cnt)
                            8'd0: begin
                                // byte 1 IP version & ihl
                                if (eth_data_in[7:4] !== 4'd4) begin
                                    // ensure frame is IPv4
                                    ip_err <= 1'b1;
                                    state <= ERROR;
                                end
                                ihl <= eth_data_in[3:0];
                                header_cnt <= header_cnt + 1'b1;
                            end
                            
                            // bytes 3 and 4 packet size
                            8'd2: begin
                                ip_total_len[15:8] <= eth_data_in;
                                header_cnt <= header_cnt + 1'b1;
                            end
                
                            8'd3: begin
                                ip_total_len[7:0] <= eth_data_in;
                                header_cnt <= header_cnt + 1'b1;
                            end
                
                            // skip ident, flags, ttl
                
                            8'd9: begin
                                // check frame uses correct transport protocol
                                if (eth_data_in !== TRANSPORT_PROTOCOL) begin
                                    ip_err <= 1'b1;
                                    state <= ERROR;
                                end
                                header_cnt <= header_cnt + 1'b1;
                            end
                
                            // destination IP addr
                            8'd16, 8'd17, 8'd18: begin
                                header_cnt <= header_cnt + 1'b1;
                                ip_dest_addr <= {ip_dest_addr[23:0], eth_data_in};
                            end
                            
                            8'd19: begin
                                header_cnt <= header_cnt + 1'b1;
                                // check if ip address is correct
                                if ({ip_dest_addr[23:0], eth_data_in} !== IP_ADDRESS) begin
                                    ip_err <= 1'b1;
                                    state <= ERROR;
                                end
                                else if (ihl == 5) state <= PAYLOAD;
                            end
                            
                            // add new options based on ihl
                            8'd59: state <= PAYLOAD;
                
                            default: header_cnt <= header_cnt + 1'b1;
                        endcase
                    end
                    
                    PAYLOAD: begin
                        ip_byte_valid <= 1'b1;
                        if (eth_eof && eth_err) begin
                            ip_err <= 1'b1;
                            ip_eof <= 1'b1;
                            state <= HEADER;
                        end else begin
                            ip_data_out <= eth_data_in;
                            
                            if (eth_eof) begin
                                // end of valid frame
                                ip_eof <= 1'b1;
                                state <= HEADER;
                            end
                        end
                        
                    end    
                        
                    ERROR: begin
                        // flush the frame after finding new error (ethertype)
                        if (eth_eof) begin
                            state <= HEADER;
                            header_cnt <= '0;
                        end
                    end
                    
                endcase
            end
            
        end
    
    end
    
    
    
endmodule
