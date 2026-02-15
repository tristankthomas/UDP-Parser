from scapy.all import Ether, Raw, sendp
import os
import time

dst_mac = "04:A4:DD:09:35:C7"  # FPGA MAC
src_mac = "00:E0:4C:B3:02:F6"  # NIC MAC

# interface to send on
iface = "Ethernet"

# send continuously
while True:
    # generate random payload of 32 bytes
    payload = os.urandom(32)

    # build ethernet frame
    frame = Ether(dst=dst_mac, src=src_mac, type=0x1234) / Raw(load=payload)

    # send the frame
    sendp(frame, iface=iface, verbose=True)

    time.sleep(0.5)  # 10 ms
