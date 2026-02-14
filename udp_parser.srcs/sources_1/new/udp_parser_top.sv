`timescale 1ns / 1ps

module udp_parser_top(
    input logic PL_CLK_50M,
    input logic ETH_RXCK,
    input logic ETH_RXDV,
    input logic [3:0] ETH_RXD,
    input logic PL_KEY1,
    output logic ETH_nRST,
    output logic PL_LED1,
    output logic PL_LED2

);

    parameter MAC_ADDR = 48'h04_A4_DD_09_35_C7;
    logic rst_n;
    logic [3:0] rx_data;
    logic [7:0] fifo_byte;
    logic frame_err, frame_valid;
    logic wr_en;
    logic por_done; // Power on Reset done
    
    // delay of approx 330ms - requirement is 10ms
    logic [24:0] r_cnt = 25'd0;
    always_ff @(posedge PL_CLK_50M) begin
        if (!r_cnt[24]) r_cnt <= r_cnt + 1'b1;
    end
    assign por_done = r_cnt[24];
    
    // rst whenever key is pressed OR por hasnt finished
    assign rst_n = por_done && PL_KEY1; 
    assign ETH_nRST = rst_n;
    
    // instantiate mac
    eth_mac_rx #(
        .MAC_ADDR(MAC_ADDR)
    ) mac_rx (
        .eth_rx_clk(ETH_RXCK),
        .rst_n(rst_n),
        .eth_rx_data(ETH_RXD),
        .eth_rx_valid(ETH_RXDV),
        .byte_out(fifo_byte),
        .frame_err(frame_err),
        .frame_valid(frame_valid),
        .wr_en(wr_en)
    );
    
    
//    // stretch frame_valid for LED1
    pulse_stretcher #(
        .COUNT_WIDTH(23)
    ) ps_valid (
        .clk(ETH_RXCK),
        .rst_n(rst_n),
        .trigger(frame_valid),
        .dout(PL_LED1)
    );

    // stretch frame_err for LED2
    pulse_stretcher #(
        .COUNT_WIDTH(23)
    ) ps_err (
        .clk(ETH_RXCK),
        .rst_n(rst_n),
        .trigger(frame_err),
        .dout(PL_LED2)
    );

    
    // feed output data into fifo (todo)
    
endmodule
