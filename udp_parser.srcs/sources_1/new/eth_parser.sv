import eth_pkg::*;
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


module eth_parser (
    input logic clk,
    input logic rst_n,
    input logic fifo_valid,
    input byte_t data_in,
    input logic fifo_eof,
    input logic fifo_frame_err,
    output logic fifo_ready,
    output byte_t ip_data_out,
    output logic ip_valid,
    output logic ip_eof,
    output logic ip_eth_err
);

    typedef enum logic [1:0] { HEADER, PAYLOAD, ERROR } state_t;
    state_t state;
    
    logic [$clog2(HEADER_LEN)-1:0] byte_cnt;
    byte_t ethertype_msb;
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            ip_data_out <= 7'b0;
            ip_valid <= 1'b0;
            ip_eof <= 1'b0;
            fifo_ready <= 1'b0;
            byte_cnt <= '0;
            ip_eth_err <= 1'b0;
            state <= HEADER;
            
        end else begin
            // these apply unless overridden below
            ip_valid <= 1'b0;
            ip_eof <= 1'b0;
            ip_eth_err <= 1'b0;
            fifo_ready <= 1'b1;// deal with this properly
            
            if (fifo_ready && fifo_valid) begin
                case (state)
                    
                    HEADER : begin
                        byte_cnt <= byte_cnt + 1'b1;
                        if (fifo_frame_err && fifo_eof) begin
                            // frame error from mac - rst count
                            ip_eth_err <= 1'b1;
                            ip_eof <= 1'b1;
                            byte_cnt <= '0;
                        end else if (byte_cnt == 2*MAC_LEN) begin
                            ethertype_msb <= data_in;
                        end else if (byte_cnt == 2*MAC_LEN+1) begin
                            // check if frame is using IPv4
                            if ({ethertype_msb, data_in} == IPV4_ETHERTYPE) begin
                                state <= PAYLOAD;
                                byte_cnt <= '0;
                            end else begin
                                ip_eth_err <= 1'b1;
                                state <= ERROR;
                            end
                        end
                        

                    end
                    
                    PAYLOAD : begin
                        if (fifo_frame_err && fifo_eof) begin
                            // frame error from crc
                            ip_eth_err <= 1'b1;
                            ip_eof <= 1'b1;
                            state <= HEADER;
                        end else begin
                            ip_data_out <= data_in;
                            ip_valid <= 1'b1;
                            
                            if (fifo_eof) begin
                                // end of valid frame
                                ip_eof <= 1'b1;
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
