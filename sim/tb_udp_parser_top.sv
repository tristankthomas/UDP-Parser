`timescale 1ns / 1ps
import eth_pkg::*;
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.02.2026 17:46:32
// Design Name: 
// Module Name: tb_udp_parser_top
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


module tb_udp_parser_top;
    
    parameter SYS_CLK_FREQ = 50_000_000;
    parameter SYS_CLK_PERIOD = 1.0e9/SYS_CLK_FREQ;
    parameter RX_CLK_FREQ = 25_000_000;
    parameter RX_CLK_PERIOD = 1.0e9/RX_CLK_FREQ;
    
    parameter DEST_MAC = 48'h04_A4_DD_09_35_C7;
        
    logic PL_CLK_50M;
    logic ETH_RXCK;
    logic ETH_RXDV;
    logic [3:0] ETH_RXD;
    logic PL_KEY1;
    logic ETH_nRST;
    logic PL_LED1; // frame valid
    logic PL_LED2; // frame error
    
    logic expected_valid;

    // instantiate system
    udp_parser_top #(
        .POR_BIT(4)
    ) uut (
        .PL_CLK_50M(PL_CLK_50M),
        .ETH_RXCK(ETH_RXCK),
        .ETH_RXDV(ETH_RXDV),
        .ETH_RXD(ETH_RXD),
        .PL_KEY1(PL_KEY1),
        .ETH_nRST(ETH_nRST),
        .PL_LED1(PL_LED1),
        .PL_LED2(PL_LED2)
    );
    
    // create clocks and reset
    initial PL_CLK_50M = 0;
    always #(SYS_CLK_PERIOD) PL_CLK_50M <= ~PL_CLK_50M;
  
    initial ETH_RXCK = 0;
    always #(RX_CLK_PERIOD) ETH_RXCK <= ~ETH_RXCK;
    
    initial PL_KEY1 = 1;
    
    // ethernet frame class
    class eth_frame;
        byte_t [5:0] dest_mac, source_mac;
        byte_t [1:0] ether_type;
        byte_t payload[];
        byte_t [3:0] fcs;
        
        function new(
            input byte_t [5:0] dest_mac,
            input byte_t [5:0] source_mac,
            input byte_t [1:0] ether_type,
            input byte_t payload[],
            input logic valid_frame
        );
            
            this.dest_mac = dest_mac;
            this.source_mac = source_mac;
            this.ether_type = ether_type;
            this.payload = payload;
            this.fcs = calculate_fcs();
            expected_valid = valid_frame;
        endfunction
        
        function byte_t [3:0] calculate_fcs();
            logic [31:0] crc_reg;
            crc_reg = 32'hFFFFFFFF;
        
            // destination MAC
            for (int i = 5; i >= 0; i--) crc_reg = get_next_crc(crc_reg, dest_mac[i]);
            // source MAC
            for (int i = 5; i >= 0; i--) crc_reg = get_next_crc(crc_reg, source_mac[i]);
            // EtherType
            for (int i = 1; i >= 0; i--) crc_reg = get_next_crc(crc_reg, ether_type[i]);
            // payload
            foreach (payload[i]) crc_reg = get_next_crc(crc_reg, payload[i]);
        
            return crc_reg ^ 32'hFFFFFFFF;
        endfunction
        
        // ouputs the CRC after 8 bit shifts (generated through crc_engine_gen.py)
        function logic [31:0] get_next_crc(input logic [31:0] c, input byte_t d);
            logic [31:0] next_crc;
            next_crc[0] = c[2] ^ c[8] ^ d[2];
            next_crc[1] = c[0] ^ c[3] ^ c[9] ^ d[0] ^ d[3];
            next_crc[2] = c[0] ^ c[1] ^ c[4] ^ c[10] ^ d[0] ^ d[1] ^ d[4];
            next_crc[3] = c[1] ^ c[2] ^ c[5] ^ c[11] ^ d[1] ^ d[2] ^ d[5];
            next_crc[4] = c[0] ^ c[2] ^ c[3] ^ c[6] ^ c[12] ^ d[0] ^ d[2] ^ d[3] ^ d[6];
            next_crc[5] = c[1] ^ c[3] ^ c[4] ^ c[7] ^ c[13] ^ d[1] ^ d[3] ^ d[4] ^ d[7];
            next_crc[6] = c[4] ^ c[5] ^ c[14] ^ d[4] ^ d[5];
            next_crc[7] = c[0] ^ c[5] ^ c[6] ^ c[15] ^ d[0] ^ d[5] ^ d[6];
            next_crc[8] = c[1] ^ c[6] ^ c[7] ^ c[16] ^ d[1] ^ d[6] ^ d[7];
            next_crc[9] = c[7] ^ c[17] ^ d[7];
            next_crc[10] = c[2] ^ c[18] ^ d[2];
            next_crc[11] = c[3] ^ c[19] ^ d[3];
            next_crc[12] = c[0] ^ c[4] ^ c[20] ^ d[0] ^ d[4];
            next_crc[13] = c[0] ^ c[1] ^ c[5] ^ c[21] ^ d[0] ^ d[1] ^ d[5];
            next_crc[14] = c[1] ^ c[2] ^ c[6] ^ c[22] ^ d[1] ^ d[2] ^ d[6];
            next_crc[15] = c[2] ^ c[3] ^ c[7] ^ c[23] ^ d[2] ^ d[3] ^ d[7];
            next_crc[16] = c[0] ^ c[2] ^ c[3] ^ c[4] ^ c[24] ^ d[0] ^ d[2] ^ d[3] ^ d[4];
            next_crc[17] = c[0] ^ c[1] ^ c[3] ^ c[4] ^ c[5] ^ c[25] ^ d[0] ^ d[1] ^ d[3] ^ d[4] ^ d[5];
            next_crc[18] = c[0] ^ c[1] ^ c[2] ^ c[4] ^ c[5] ^ c[6] ^ c[26] ^ d[0] ^ d[1] ^ d[2] ^ d[4] ^ d[5] ^ d[6];
            next_crc[19] = c[1] ^ c[2] ^ c[3] ^ c[5] ^ c[6] ^ c[7] ^ c[27] ^ d[1] ^ d[2] ^ d[3] ^ d[5] ^ d[6] ^ d[7];
            next_crc[20] = c[3] ^ c[4] ^ c[6] ^ c[7] ^ c[28] ^ d[3] ^ d[4] ^ d[6] ^ d[7];
            next_crc[21] = c[2] ^ c[4] ^ c[5] ^ c[7] ^ c[29] ^ d[2] ^ d[4] ^ d[5] ^ d[7];
            next_crc[22] = c[2] ^ c[3] ^ c[5] ^ c[6] ^ c[30] ^ d[2] ^ d[3] ^ d[5] ^ d[6];
            next_crc[23] = c[3] ^ c[4] ^ c[6] ^ c[7] ^ c[31] ^ d[3] ^ d[4] ^ d[6] ^ d[7];
            next_crc[24] = c[0] ^ c[2] ^ c[4] ^ c[5] ^ c[7] ^ d[0] ^ d[2] ^ d[4] ^ d[5] ^ d[7];
            next_crc[25] = c[0] ^ c[1] ^ c[2] ^ c[3] ^ c[5] ^ c[6] ^ d[0] ^ d[1] ^ d[2] ^ d[3] ^ d[5] ^ d[6];
            next_crc[26] = c[0] ^ c[1] ^ c[2] ^ c[3] ^ c[4] ^ c[6] ^ c[7] ^ d[0] ^ d[1] ^ d[2] ^ d[3] ^ d[4] ^ d[6] ^ d[7];
            next_crc[27] = c[1] ^ c[3] ^ c[4] ^ c[5] ^ c[7] ^ d[1] ^ d[3] ^ d[4] ^ d[5] ^ d[7];
            next_crc[28] = c[0] ^ c[4] ^ c[5] ^ c[6] ^ d[0] ^ d[4] ^ d[5] ^ d[6];
            next_crc[29] = c[0] ^ c[1] ^ c[5] ^ c[6] ^ c[7] ^ d[0] ^ d[1] ^ d[5] ^ d[6] ^ d[7];
            next_crc[30] = c[0] ^ c[1] ^ c[6] ^ c[7] ^ d[0] ^ d[1] ^ d[6] ^ d[7];
            next_crc[31] = c[1] ^ c[7] ^ d[1] ^ d[7];
            
            return next_crc;
        endfunction
        
    endclass
    
    // driver
    task automatic send_nibble (input logic [3:0] nibble);
        ETH_RXD <= nibble;
    endtask
    
    task automatic send_byte (input logic [7:0] data);
//        $display("DEBUG: Sending byte %h", data);
        send_nibble(data[3:0]);
        @(posedge ETH_RXCK);
        send_nibble(data[7:4]);
        @(posedge ETH_RXCK);
    endtask
    
    
    task automatic send_frame (eth_frame frame);

        // let mac know data is available
        ETH_RXDV <= 1'b1;
        
        // preamble
        repeat(PREAMBLE_LEN) send_byte(PREAMBLE_BYTE);
        send_byte(SFD_BYTE);
        
        // send destination mac
        for (int i = MAC_LEN-1; i >= 0; i--) send_byte(frame.dest_mac[i]);
        // send source mac
        for (int i = MAC_LEN-1; i >= 0; i--) send_byte(frame.source_mac[i]);
        // send ethertype
        send_byte(frame.ether_type[1]);
        send_byte(frame.ether_type[0]);
        // send payload
        foreach(frame.payload[i]) send_byte(frame.payload[i]);
        // send FSC
        for (int i = 0; i < 4; i++) send_byte(frame.fcs[i]);
        
        // end of frame
        ETH_RXDV <= 1'b0;
        ETH_RXD <= 4'h0;
        
        // interframe gap
        repeat(IFG_CYCLES) @(posedge ETH_RXCK);
        
    endtask
    
    
    function automatic byte_array_t random_payload(input int length);
        byte_array_t payload;
        payload = new[length];
    
        for (int i = 0; i < length; i++) payload[i] = $urandom_range(0, 255);
    
        return payload;
    endfunction
    
    
    // check for a valid frame
    always @(posedge PL_LED1) begin
        if (expected_valid) $display("SUCCESS: Valid rame transmitted successfully");
        else $display("FAIL: Invalid frame transmitted successfully");
        
    end
    
    // check for frame failure
    always @(posedge PL_LED2) begin
        if (~expected_valid) $display("SUCCESS: Invalid frame not transmitted successfully");
        else $display("FAIL: Valid frame transmitted unsuccessfully");
    end
    
    
    initial begin
        
        eth_frame f0, f1, f2, f3;
        
        // power on reset
        wait(uut.por_done == 1'b1);
        
        $display("Sending valid frame");
        // valid frame
        f0 = new(
            DEST_MAC,
            48'h71ABD97E0110,
            16'h0800,
            random_payload(32),
            1
        );
        send_frame(f0);
        
        $display("Sending valid frame");
        // valid frame
        f1 = new(
            DEST_MAC,
            48'h71ABD97E0110,
            16'h0800,
            random_payload(25),
            1
        );
        send_frame(f1);
        
        $display("Sending invalid frame - wrong mac");
        // invalid frame - wrong mac
        f2 = new(
            48'h123456789ABC,
            48'h71ABD97E0110,
            16'h0800,
            random_payload(16),
            0
        );
        send_frame(f2);
        
        $display("Sending invalid frame - ethertype");
        // invalid frame - wrong mac
        f3 = new(
            DEST_MAC,
            48'h71ABD97E0110,
            16'h58B0,
            random_payload(16),
            0
        );
        send_frame(f3);
        
        @(posedge ETH_RXCK);
        $display("Simulation Finished at %t", $time);
        $finish;        
        
    
    end
    
endmodule