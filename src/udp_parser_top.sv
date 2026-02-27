`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.02.2026 22:12:32
// Design Name: 
// Module Name: udp_parser_top
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

module udp_parser_top #(
    parameter POR_BIT = 24,
    parameter PULSE_CNT_WIDTH = 22
)(
    input logic PL_CLK_50M,
    input logic ETH_RXCK,
    input logic ETH_RXDV,
    input logic [3:0] ETH_RXD,
    input logic PL_KEY1,
    output logic ETH_nRST,
    output logic PL_LED1,
    output logic PL_LED2

);

    localparam MAC_ADDR = 48'h04A4DD0935C7;
    
    logic rst_n;
    logic [7:0] fifo_byte;
    logic mac_frame_err;
    logic mac_frame_valid;
    logic wr_en;
    logic por_done; // Power on Reset done
    
    // delay of approx 330ms - requirement is 10ms
    logic [POR_BIT:0] r_cnt = '0;
    always_ff @(posedge PL_CLK_50M) begin
        if (!r_cnt[POR_BIT]) r_cnt <= r_cnt + 1'b1;
    end
    assign por_done = r_cnt[POR_BIT];
    
    // rst whenever key is pressed OR por hasnt finished
    assign rst_n = por_done && PL_KEY1; 
    assign ETH_nRST = rst_n;
    
    // instantiate mac
    mii_mac_rx #(
        .MAC_ADDR(MAC_ADDR)
    ) u_mac_rx (
        .rx_clk(ETH_RXCK),
        .rst_n(rst_n),
        .rx_data(ETH_RXD),
        .rx_valid(ETH_RXDV),
        .data_out(fifo_byte),
        .frame_err(mac_frame_err),
        .frame_valid(mac_frame_valid),
        .wr_en(wr_en)
    );
    
//    pulse_stretcher #(
//        .COUNT_WIDTH(21)
//    ) ps_valid (
//        .clk(ETH_RXCK),
//        .rst_n(rst_n),
//        .trigger(frame_valid),
//        .dout(PL_LED1)
//    );
    
//    // stretch frame_err for LED2
//    pulse_stretcher #(
//        .COUNT_WIDTH(21)
//    ) ps_err (
//        .clk(ETH_RXCK),
//        .rst_n(rst_n),
//        .trigger(frame_err),
//        .dout(PL_LED2)
//    );
    
    

    logic [7:0] m_axis_tdata;
    logic m_axis_tvalid;
    logic m_axis_tlast;
    logic m_axis_tready;
    logic m_axis_tuser;
    logic s_axis_tready;
    logic s_axis_tlast;
    logic fifo_overflow;
    
    // feed output data into fifo
    axis_data_fifo_0 u_rx_fifo (
      .s_axis_aresetn(rst_n),
      .s_axis_aclk(ETH_RXCK),
      .s_axis_tvalid(wr_en),
      .s_axis_tready(s_axis_tready),
      .s_axis_tdata(fifo_byte),
      .s_axis_tlast(s_axis_tlast),
      .s_axis_tuser(mac_frame_err),
      .m_axis_aclk(PL_CLK_50M),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tready(m_axis_tready),
      .m_axis_tdata(m_axis_tdata),
      .m_axis_tlast(m_axis_tlast),
      .m_axis_tuser(m_axis_tuser)
    );
    
    assign s_axis_tlast = mac_frame_valid || mac_frame_err;
    assign fifo_overflow = wr_en && !s_axis_tready;
 
//    // stretch fifo overflow for LED2
//    pulse_stretcher #(
//        .COUNT_WIDTH(21)
//    ) ps_fifo_err (
//        .clk(ETH_RXCK),
//        .rst_n(rst_n),
//        .trigger(fifo_overflow),
//        .dout(PL_LED2)
//    );
    
    logic [7:0] eth_data_out;
    logic eth_data_valid;
    logic eth_eof;
    logic eth_err;
    
    // send data through ethernet header passer
    eth_parser #(
        .ETHERTYPE(16'h0800)
    ) u_eth_parser (
        .clk(PL_CLK_50M),
        .rst_n(rst_n),
        .fifo_valid(m_axis_tvalid),
        .data_in(m_axis_tdata),
        .fifo_eof(m_axis_tlast),
        .fifo_frame_err(m_axis_tuser),
        .fifo_ready(m_axis_tready),
        .eth_data_out(eth_data_out),
        .eth_byte_valid(eth_data_valid),
        .eth_eof(eth_eof),
        .eth_err(eth_err)
    );
    
    logic [7:0] ip_data_out;
    logic ip_data_valid;
    logic ip_eof;
    logic ip_err;
    
    // send data through IP header passer
    ip_parser #(
        .TRANSPORT_PROTOCOL(8'd17),
        .IP_ADDRESS(32'hC0A80101)
    ) u_ip_parser (
        .clk(PL_CLK_50M),
        .rst_n(rst_n),
        .eth_data_in(eth_data_out),
        .eth_eof(eth_eof),
        .eth_err(eth_err),
        .eth_byte_valid(eth_data_valid),
        .ip_data_out(ip_data_out),
        .ip_byte_valid(ip_data_valid),
        .ip_eof(ip_eof),
        .ip_err(ip_err)
    );
    
    logic frame_valid;
    assign frame_valid = ip_eof && ~ip_err;
    
    logic frame_err;
    assign frame_err = eth_err || ip_err;
//    assign PL_LED1 = eth_eof && ~eth_err;
//    assign PL_LED2 = eth_err;
    // stretch frame_valid for LED1
    pulse_stretcher #(
        .COUNT_WIDTH(PULSE_CNT_WIDTH)
    ) ps_valid (
        .clk(PL_CLK_50M),
        .rst_n(rst_n),
        .trigger(frame_valid),
        .dout(PL_LED1)
    );
    
    // stretch frame_err for LED2
    pulse_stretcher #(
        .COUNT_WIDTH(PULSE_CNT_WIDTH)
    ) ps_err (
        .clk(PL_CLK_50M),
        .rst_n(rst_n),
        .trigger(frame_err),
        .dout(PL_LED2)
    );
    
    
endmodule
