`timescale 1ns / 1ps

module mii_to_byte(
    input logic rx_clk,
    input logic rst_n,
    input logic [3:0] rx_data,
    input logic rx_valid,
    output logic [7:0] byte_out,
    output logic byte_valid
);
    
    logic [3:0] low_nibble;
    logic nibble_phase;
    

    always_ff @(posedge rx_clk or negedge rst_n) begin
        if (~rst_n) begin
            low_nibble <= 4'h0;
            nibble_phase <= 1'b0;
            
        end else if (rx_valid) begin
            if (nibble_phase == 1'b0) begin
                low_nibble <= rx_data;
                nibble_phase <= 1'b1;
            end else begin
                nibble_phase <= 1'b0;
            end
        end else begin
            nibble_phase <= 1'b0;
        end
    end
    
    // allows the byte to output a cycle quicker
    assign byte_out = {rx_data, low_nibble};
    assign byte_valid = rx_valid && (nibble_phase == 1'b1);
    
    
endmodule
