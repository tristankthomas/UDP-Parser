from scapy.all import Ether, IP, Raw, sendp
import os
import time

dst_mac = "04:A4:DD:09:35:C7"  # FPGA MAC
src_mac = "00:E0:4C:B3:02:F6"  # NIC MAC

# ip addresses
dst_ip = "192.168.1.1" # matches 32'hC0A80101
src_ip = "192.168.1.2"

# interface to send on
iface = "Ethernet"

# send continuously
while True:
    # generate random payload of 32 bytes
    payload = os.urandom(32)

    # build ethernet frame with ip
    frame = Ether(dst=dst_mac, src=src_mac) / IP(dst=dst_ip, src=src_ip, proto=17) / Raw(load=payload)

    # send the frame
    sendp(frame, iface=iface, verbose=True)

    time.sleep(0.5)  # 500 ms