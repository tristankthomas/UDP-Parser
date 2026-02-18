import eth_pkg::*;

module eth_mac_rx #(
    parameter byte_t [5:0] MAC_ADDR
)(
    input logic rx_clk,
    input logic rst_n,
    input logic [3:0] rx_data,
    input logic rx_valid,
    output byte_t data_out,
    output logic frame_err,
    output logic frame_valid,
    output logic wr_en
);
    
    logic rx_byte_valid;
    byte_t rx_byte;
    logic compute_crc;
    logic [31:0] curr_crc;
    logic init_crc;
    logic [$clog2(MAX_PAYLOAD_LEN)-1:0] byte_cnt;
    
    typedef enum logic [2:0] { IDLE, PREAMBLE, HEADER, PAYLOAD, FINISH } state_t;
    state_t state;
    
    mii_to_byte u_mii_to_byte (
        .rx_clk(rx_clk),
        .rst_n(rst_n),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .byte_out(rx_byte),
        .byte_valid(rx_byte_valid)
    );
    
    crc_engine u_crc_engine (
        .clk(rx_clk),
        .rst_n(rst_n),
        .init(init_crc),
        .byte_in(rx_byte),
        .en(compute_crc),
        .crc(curr_crc) 
    );
    
    // create a 5 cycle delay so that the last payload byte aligns with the crc result (valid | err)
    byte_t [4:0] data_pipe;
    logic [4:0] wr_pipe;
    
    always_ff @(posedge rx_clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
            byte_cnt <= '0;
            frame_valid <= 1'b0;
            frame_err <= 1'b0;
            init_crc <= 1'b1;
            wr_pipe <= 5'b0;
            
        end else begin
            init_crc <= 1'b0;
            case (state)
                IDLE : begin
                    frame_valid <= 1'b0;
                    frame_err <= 1'b0;
//                    wr_en <= 1'b0;
                    if (rx_byte_valid && rx_byte === PREAMBLE_BYTE) state <= PREAMBLE;
                end
                
                PREAMBLE: begin
                
                    if (rx_byte_valid) begin
                        if (rx_byte === SFD_BYTE) begin
                            byte_cnt <= '0;
                            state <= HEADER;
                            init_crc <= 1'b1;
                        end else if (rx_byte !== PREAMBLE_BYTE) begin
                            state <= IDLE;
                        end
                    
                    end
                end
                
                HEADER: begin
                    
                    if (rx_byte_valid) begin
                        // read in the header with 5 cycle delay for FCS
                        wr_pipe <= {wr_pipe[3:0], 1'b1};
                        data_pipe <= {data_pipe[3:0], rx_byte};
                        
                        if (byte_cnt < MAC_LEN) begin
                            // if fpga mac is invalid then flush frame
                            if (rx_byte !== MAC_ADDR[MAC_LEN-1-byte_cnt]) begin
                                frame_err <= 1'b1;
                                state <= IDLE;
                            end
                            byte_cnt <= byte_cnt + 1'b1;
                        end else if (byte_cnt < HEADER_LEN) begin
                            // source mac and ethertype
                            byte_cnt <= byte_cnt + 1'b1;
                        end else begin
                            // header complete
                            state <= PAYLOAD;
                            byte_cnt <= '0;
                        end
                    end
                end
                
                PAYLOAD: begin
                    // pulse based on valid bytes
                    if (rx_byte_valid) begin
                        // read in payload
                        wr_pipe <= {wr_pipe[3:0], rx_byte_valid};
                        data_pipe <= {data_pipe[3:0], rx_byte};
                        
                    end else if (~rx_valid) begin
                        // perform FCS check - reversed order
                        if (curr_crc == 32'hDEBB20E3) begin
                            frame_valid <= 1'b1;
                            frame_err <= 1'b0;
                        end else begin
                            frame_valid <= 1'b0;
                            frame_err <= 1'b1;
                        end
                        
                        state <= FINISH;
                        byte_cnt <= '0;
                    end
                end
                
                FINISH: begin
                    frame_valid <= 1'b0;
                    frame_err <= 1'b0;
                    wr_pipe <= 5'b0;
                    if (byte_cnt == IFG_CYCLES) state <= IDLE;
                    else byte_cnt <= byte_cnt + 1'b1;
                end
            endcase
            
        end
        
    end
    
    
    assign compute_crc = rx_byte_valid & (state == HEADER | state == PAYLOAD);
    assign wr_en = wr_pipe[4] & (rx_byte_valid | frame_valid | frame_err); // want wr_en to pulse with available byte
    assign data_out = data_pipe[4];
    
endmodule



