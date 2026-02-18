`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.02.2026 22:15:15
// Design Name: 
// Module Name: eth_mac_rx_tb
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

module eth_mac_rx_tb;

    parameter RX_CLK_FREQ = 25_000_000; // 25MHz clk
    parameter RX_CLK_PERIOD = 1.0e9/RX_CLK_FREQ;
    parameter DEST_MAC = 48'h04_A4_DD_09_35_C7;
    
    logic rx_clk;
    logic rx_rst_n;
    logic rx_valid;
    logic [3:0] rx_data;
    logic [7:0] byte_out;
    logic frame_err, frame_valid, wr_en;
    logic [7:0] rx_frame_q[$]; // queue used to store uut result
    logic [7:0] tx_frame_q[$]; // queue used to store send data
    
    // instantiate MAC
    eth_mac_rx #(
        .MAC_ADDR(DEST_MAC)
    ) uut (
        .rx_clk(rx_clk),
        .rst_n(rx_rst_n),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .data_out(byte_out),
        .frame_err(frame_err),
        .frame_valid(frame_valid),
        .wr_en(wr_en)
    );
    
    
    // setup clk
    initial rx_clk = 0;
    always #(RX_CLK_PERIOD) rx_clk <= ~rx_clk;
    
    
    // ethernet frame class
    class eth_frame;
        byte_t [5:0] dest_mac, source_mac;
        byte_t [1:0] ether_type;
        byte_t payload[];
        byte_t [3:0] fcs;
        
        function new(
            byte_t [5:0] dest_mac,
            byte_t [5:0] source_mac,
            byte_t [1:0] ether_type,
            byte_t payload[]
        );
            
            this.dest_mac = dest_mac;
            this.source_mac = source_mac;
            this.ether_type = ether_type;
            this.payload = payload;
            this.fcs = calculate_fcs();
            
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
        rx_data <= nibble;
    endtask
    
    task automatic send_byte (input logic [7:0] data);
//        $display("DEBUG: Sending byte %h", data);
        send_nibble(data[3:0]);
        @(posedge rx_clk);
        send_nibble(data[7:4]);
        @(posedge rx_clk);
    endtask
    
    
    task automatic send_frame (eth_frame frame);
        
        // populate the expected results
        for (int i = MAC_LEN-1; i >= 0; i--) tx_frame_q.push_back(frame.dest_mac[i]);
        for (int i = MAC_LEN-1; i >= 0; i--) tx_frame_q.push_back(frame.source_mac[i]);
        tx_frame_q.push_back(frame.ether_type[1]);
        tx_frame_q.push_back(frame.ether_type[0]);
        foreach(frame.payload[i]) tx_frame_q.push_back(frame.payload[i]);
        
        // let mac know data is available
        rx_valid <= 1'b1;
        
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
        rx_valid <= 1'b0;
        rx_data <= 4'h0;
        
        // interframe gap
        repeat(IFG_CYCLES) @(posedge rx_clk);
        
    endtask
    
    
    task reset;
        rx_rst_n <= 1'b0;
        rx_valid <= 1'b0;
        rx_data <= 4'h0;
        repeat(4) @(posedge rx_clk);
        rx_rst_n <= 1'b1;
    endtask
    
    function automatic byte_array_t random_payload(input int length);
        byte_array_t payload;
        payload = new[length];
    
        for (int i = 0; i < length; i++) begin
            payload[i] = $urandom_range(0, 255);
        end
    
        return payload;
    endfunction
    
    
    
    always @(posedge rx_clk) begin
        // storing result
        if (wr_en) rx_frame_q.push_back(byte_out);
        
        // scoreboard
        if (frame_valid) check_frame();
    end
   
    
    task check_frame;
        if (rx_frame_q.size() != tx_frame_q.size()) begin   
            $display("ERROR: Frame size mismatch. Expected: %d, Result: %d", tx_frame_q.size(), rx_frame_q.size());
            $write("DEBUG: tx_frame_q contents: ");
            foreach (tx_frame_q[i]) $write("%02h ", tx_frame_q[i]);
            $display("");
        
            $write("DEBUG: rx_frame_q contents: ");
            foreach (rx_frame_q[i]) $write("%02h ", rx_frame_q[i]);
            $display("");
            
        end else begin
            automatic bit match = 1;
            foreach (tx_frame_q[i]) begin
                if (tx_frame_q[i] != rx_frame_q[i]) begin
                    $display("ERROR: Byte mismatch. Expected: %h, Result: %h", tx_frame_q[i], rx_frame_q[i]);
                    match = 0;
                end
            
            end
            if (match) begin
                $display("SUCCESS: Frame recevied correctly.");
            end
            
            // clear queues for new frame
            tx_frame_q.delete();
            rx_frame_q.delete();
        
        end   
    
    
    endtask
    
    always @(posedge frame_err) begin
        $display("WARNING: Frame not received correctly.");
        tx_frame_q.delete();
        rx_frame_q.delete();
   
    end
    
   
    initial begin
        eth_frame f0, f1, f2;
        
        reset();
        
        $display("Sending valid frame");
        // valid frame
        f0 = new(
            DEST_MAC,
            48'h71ABD97E0110,
            16'h0800,
            random_payload(4)
        );
        send_frame(f0);
        
        $display("Sending valid frame");
        // valid frame
        f1 = new(
            DEST_MAC,
            48'h71_AB_D9_7E_01_10,
            16'h0800,
            random_payload(12)
        );
        send_frame(f1);
        
        $display("Sending invaild frame - wrong mac");
        // invalid frame - wrong mac
        f2 = new(
            48'h123456789ABC,
            48'h71ABD97E0110,
            16'h0800,
            random_payload(20)
        );
        send_frame(f2);
        
        @(posedge rx_clk);
        $display("Simulation Finished at %t", $time);
        $finish;        
        
    
    end
    
endmodule
