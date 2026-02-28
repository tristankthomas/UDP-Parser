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
    
    parameter DEST_MAC = 48'h04A4DD0935C7;
    parameter DEST_IP = 32'hC0A80101;
    parameter DEST_PORT = 16'h1234;
        
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
        .POR_BIT(4),
        .PULSE_CNT_WIDTH(1)
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
    
    class eth_frame;
        // ethernet header
        byte_t [5:0] dest_mac;
        byte_t [5:0] source_mac;
        byte_t [1:0] ether_type;
    
        // ipv4 header fields
        logic [3:0] ip_version;
        logic [3:0] ip_ihl;
        byte_t ip_tos;
        byte_t [1:0] ip_total_length;
        byte_t [1:0] ip_id;
        byte_t [1:0] ip_flags_offset;
        byte_t ip_ttl;
        byte_t ip_protocol;
        byte_t [1:0] ip_checksum;
        byte_t [3:0] src_ip_addr;
        byte_t [3:0] dest_ip_addr;

        // udp header fields
        byte_t [1:0] udp_src_port;
        byte_t [1:0] udp_dest_port;
        byte_t [1:0] udp_length;
        byte_t [1:0] udp_checksum;
    
        // data and control
        byte_t payload[];
        byte_t [3:0] fcs;
    
        function new(
            input byte_t [5:0] dest_mac,
            input byte_t [5:0] source_mac,
            input byte_t [1:0] ether_type,
            input logic [3:0]  ip_version,
            input byte_t trans_protocol,
            input byte_t [3:0] src_ip_addr,
            input byte_t [3:0] dest_ip_addr,
            input byte_t [1:0] udp_src_port,
            input byte_t [1:0] udp_dest_port,
            input byte_t payload[],
            input logic valid_frame
        );
            // ethernet mapping
            this.dest_mac = dest_mac;
            this.source_mac = source_mac;
            this.ether_type = ether_type;
    
            // ip mapping
            this.ip_version = ip_version;
            this.ip_ihl = 4'h5;
            this.ip_tos = 8'h00;
            this.ip_id = 16'h0000;
            this.ip_flags_offset = 16'h4000;
            this.ip_ttl = 8'h40;
            this.ip_protocol = trans_protocol;
            this.src_ip_addr = src_ip_addr;
            this.dest_ip_addr = dest_ip_addr;

            // udp mapping
            this.udp_src_port = udp_src_port;
            this.udp_dest_port = udp_dest_port;
            this.udp_length = 16'd8 + payload.size();
            this.udp_checksum = 16'h0000;
    
            // calculate ip total length (20B IP header + 8B UDP header + payload)
            this.ip_total_length = 16'd28 + payload.size();
    
            this.payload = payload;
            expected_valid = valid_frame;
    
            // checksums
            this.ip_checksum = calculate_ip_checksum();
            this.fcs = calculate_fcs();
        endfunction
        
        function void pack(output byte_t stream[]);
            // serialise fields into byte stream
            stream = {>>{
                this.dest_mac,
                this.source_mac,
                this.ether_type,
                {this.ip_version, this.ip_ihl}, 
                this.ip_tos,
                this.ip_total_length,
                this.ip_id,
                this.ip_flags_offset,
                this.ip_ttl,
                this.ip_protocol,
                this.ip_checksum,
                this.src_ip_addr,
                this.dest_ip_addr,
                this.udp_src_port,
                this.udp_dest_port,
                this.udp_length,
                this.udp_checksum,
                this.payload
            }};
        endfunction
        
        // ip checksum calculation
        function automatic logic [15:0] calculate_ip_checksum();
            logic [31:0] sum = 0;
            byte_t header_bytes[];
            
            // pack only ip header fields with checksum field zeroed
            header_bytes = {>>{
                {this.ip_version, this.ip_ihl},
                this.ip_tos,
                this.ip_total_length,
                this.ip_id,
                this.ip_flags_offset,
                this.ip_ttl,
                this.ip_protocol,
                16'h0000, 
                this.src_ip_addr,
                this.dest_ip_addr
            }};

            // 1's complement summation
            for (int i = 0; i < header_bytes.size(); i += 2) begin
                if (i + 1 < header_bytes.size()) begin
                    sum = sum + {header_bytes[i], header_bytes[i+1]};
                end else begin
                    // handle odd byte length
                    sum = sum + {header_bytes[i], 8'h00};
                end
            end

            // fold carry bits
            while (sum >> 16) begin
                sum = (sum & 32'hFFFF) + (sum >> 16);
            end

            return ~sum[15:0];
        endfunction
        
        // calculate crc-32 fcs bytes
        function byte_t [3:0] calculate_fcs();
            logic [31:0] crc_reg = 32'hFFFFFFFF;
            byte_t raw_data[];
            this.pack(raw_data);
            foreach (raw_data[i]) begin
                crc_reg = get_next_crc(crc_reg, raw_data[i]);
            end
            return ~(crc_reg);
        endfunction
        
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
        send_nibble(data[3:0]);
        @(posedge ETH_RXCK);
        send_nibble(data[7:4]);
        @(posedge ETH_RXCK);
    endtask
    
    task automatic send_frame (input eth_frame frame, input logic crc_err=1'b0);
        byte_t raw_stream[];
        frame.pack(raw_stream);
        $write("Sending Frame: %0d bytes. ", raw_stream.size());
        $display("Payload size: %0d bytes.", frame.payload.size());
        ETH_RXDV <= 1'b1;
        repeat(PREAMBLE_LEN) send_byte(PREAMBLE_BYTE);
        send_byte(SFD_BYTE);
        foreach (raw_stream[i]) begin
            send_byte(raw_stream[i]);
        end
        if (crc_err) begin
            for (int i = 0; i < 4; i++) send_byte(~frame.fcs[i]);
        end else begin
            for (int i = 0; i < 4; i++) send_byte(frame.fcs[i]);
        end
        ETH_RXDV <= 1'b0;
        ETH_RXD  <= 4'h0;
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
        if (expected_valid) $display("SUCCESS: Valid frame transmitted successfully");
        else $display("FAIL: Invalid frame transmitted successfully");
    end
    
    // check for frame failure
    always @(posedge PL_LED2) begin
        if (~expected_valid) $display("SUCCESS: Invalid frame not transmitted successfully");
        else $display("FAIL: Valid frame transmitted unsuccessfully");
    end
    
    initial begin
        eth_frame f0, f1, f2, f3, f4, f5;
        
        // power on reset
        wait(uut.por_done == 1'b1);
        
        $display("Sending valid UDP frame");
        f0 = new(
            .dest_mac(DEST_MAC),
            .source_mac(48'h71ABD97E0110),
            .ether_type(16'h0800),
            .ip_version(4'd4),
            .trans_protocol(8'h11),
            .src_ip_addr(32'hC0A8_0101),
            .dest_ip_addr(DEST_IP),
            .udp_src_port(16'hAAAA),
            .udp_dest_port(DEST_PORT),
            .payload(random_payload(4)),
            .valid_frame(1'b1)
        );
        send_frame(f0);

        $display("Sending invalid frame - wrong UDP port");
        f1 = new(
            .dest_mac(DEST_MAC),
            .source_mac(48'h71ABD97E0110),
            .ether_type(16'h0800),
            .ip_version(4'd4),
            .trans_protocol(8'h11),
            .src_ip_addr(32'hC0A8_0101),
            .dest_ip_addr(DEST_IP),
            .udp_src_port(16'hAAAA),
            .udp_dest_port(16'h5555), // Non-matching port
            .payload(random_payload(4)),
            .valid_frame(1'b0)
        );
        send_frame(f1);

        $display("Sending invalid frame - wrong transport protocol");
        f2 = new(
            .dest_mac(DEST_MAC),
            .source_mac(48'h71ABD97E0110),
            .ether_type(16'h0800),
            .ip_version(4'd4),
            .trans_protocol(8'h12),
            .src_ip_addr(32'h0A00_0001),
            .dest_ip_addr(DEST_IP),
            .udp_src_port(16'hAAAA),
            .udp_dest_port(DEST_PORT),
            .payload(random_payload(25)),
            .valid_frame(1'b0)
        );
        send_frame(f2);

        $display("Sending invalid frame - wrong ip addr");
        f3 = new(
            .dest_mac(48'h123456789ABC),
            .source_mac(48'h71ABD97E0110),
            .ether_type(16'h0800),
            .ip_version(4'd4),
            .trans_protocol(8'h11),
            .src_ip_addr(32'hC0A8_0101),
            .dest_ip_addr(32'hC0A8_0112),
            .udp_src_port(16'hAAAA),
            .udp_dest_port(DEST_PORT),
            .payload(random_payload(16)),
            .valid_frame(1'b0)
        );
        send_frame(f3);

        $display("Sending invalid frame - ethertype");
        f4 = new(
            .dest_mac(DEST_MAC),
            .source_mac(48'h71ABD97E0110),
            .ether_type(16'h58B0),
            .ip_version(4'd4),
            .trans_protocol(8'h11),
            .src_ip_addr(32'hC0A8_0101),
            .dest_ip_addr(DEST_IP),
            .udp_src_port(16'hAAAA),
            .udp_dest_port(DEST_PORT),
            .payload(random_payload(4)),
            .valid_frame(1'b0)
        );
        send_frame(f4);

        $display("Sending invalid frame - crc");
        f5 = new(
            .dest_mac(DEST_MAC),
            .source_mac(48'h71ABD97E0110),
            .ether_type(16'h0800),
            .ip_version(4'd4),
            .trans_protocol(8'h11),
            .src_ip_addr(32'hC0A8_0101),
            .dest_ip_addr(DEST_IP),
            .udp_src_port(16'hAAAA),
            .udp_dest_port(DEST_PORT),
            .payload(random_payload(16)),
            .valid_frame(1'b0)
        );
        send_frame(f5, 1'b1);
        
        @(posedge ETH_RXCK);
        $display("Simulation Finished at %t", $time);
        $finish;        
    end
endmodule