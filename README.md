# Zynq UDP Parser
This project implements a low-latency UDP datagram parser targeting the Zynq-7000 (XC7Z020) on the Microphase Z7-Lite development board. The design interfaces with an RTL8201F PHY via MII to receive, validate, and strip headers from Ethernet frames using a cut-through architecture. Will be extended to transmit frames and perform processing on the PS.

## Installation
Clone the repository:
```
git clone https://github.com/tristankthomas/udp_parser.git
cd udp_parser
```
### Option A: Command Line (Tcl Batch Mode)
```
vivado -mode batch -source scripts/recreate_project.tcl
```

### Option B: Vivado GUI
1. Launch Vivado GUI.
2. In the Tcl Console, navigate to the project root:
```
cd <path_to_repo>/udp_parser
```
3. Run the Tcl script:
```
source scripts/recreate_project.tcl
```

## Hardware Specs
- Development Board: [Microphase Z7-Lite](https://fpga-docs.microphase.cn/en/latest/DEV_BOARD/Z7-LITE/Z7-Lite_Reference_Manual.html) featuring Xilinx Zynq-7000 (XC7Z020-CLG400).
- Ethernet PHY: Realtek [RTL8201F-VB-CG](https://file.elecfans.com/web1/M00/99/0F/o4YBAF0VytaAI7ezABH66fmIRIg854.pdf?filename=RTL8201F-VB-CG.pdf) supporting 10/100 Mbps via MII.
- Use of other hardware requires updating the `constraints/constraints.xdc` file to match the target FPGA pinout and I/O standards.

## Architecture
1. **Physical Layer**: PC Host transmits UDP frames. The RTL8201F PHY receives and decodes serialized data, and transmits 4-bit nibbles over the MII bus.
2. **MII MAC RX**: Captures MII nibbles and converts them into 8-bit bytes. Validates the preamble and Start Frame Delimiter (SFD), and filters frames by MAC address. Verifies payload using CRC-32 checksum.
3. **AXI4-Stream Data FIFO**: Acts as an elastic buffer to bridge the MII RX clock domain to the System Clock domain.
4. **Ethernet Frame Parser**: Evaluates the Ethernet Header. Filters non-IP packets through EtherType.
5. **IP Packet Parser**: Validates IPv4 header length, checksum, and protocol type (UDP).
6. **UDP Datagram Parser**: Identifies Destination Port and extracts payload length. TODO
7. **PS Interface**: Payload data is transferred to the ARM core. TODO
8. **Feedback Loop**: UART interface transmits payload and calculated latency statistics back to the host PC. TODO


## Folder Structure
```
udp_parser/
├── constraints/      # Physical pinout and timing constraints
├── ip/               # Xilinx IP core metadata (.xci)
├── scripts/          # Tcl build scripts and Python verification tools
├── sim/              # Unit-level and system-level testbenches
├── src/              # Synthesisable RTL source code
├── .gitignore
└── README.md
```

## Files
| RTL Module | Description |
| :--- | :--- |
| **`udp_parser_top.sv`** | Top-level design containing PHY/clock input and LED indicator ouput |
| **`mii_mac_rx.sv`** | Interfaces directly with PHY pins. Detects Preamble/SFD, performs MAC address filtering, and manages the CRC-32 verification engine. |
| **`mii_to_byte.sv`** | Internal sub-module for `mii_mac_rx`. Manages the 4-bit to 8-bit data width conversion logic. |
| **`crc_engine.sv`** | Parallel CRC-32 calculation engine. Performs real-time frame validation for Ethernet FCS. |
| **`eth_parser.sv`** | Layer 2 parser. Extracts Destination/Source MAC addresses and validates the EtherType field. |
| **`ip_parser.sv`** | Layer 3 parser. Validates IPv4 header length, checksum, and extracts Source/Destination IP 
| **`udp_parser.sv`** | Layer 4 parser. Extracts Source/Destination ports and validates the UDP length field. Initiates data transfer to the PS interface.
| **`eth_pkg.sv`** | SystemVerilog package containing protocol constants, header widths, and type definitions. |
| **`sync_ff.sv`** | Double-flip-flop synchroniser for safe CDC of asynchronous control signals. |
| **`pulse_stretcher.sv`** | Extends single-cycle pulses for visibility on hardware LEDs or status pins. |
| **`phy_test_top.sv`** | Debug top-level used for initial PHY connectivity and MII interface timing verification. |

| Script | Description |
| :--- | :--- |
| **`crc_engine_gen.py`** | Generates Verilog XOR tree, to allow multiple shifts of LFSR per cycle in CRC engine  |
| **`create_frames.py`** | Creates raw Ethernet frames using Scapy |
| **`send_frames.py`** | Sends raw Ethernet frames to FPGA PHY for validation |
| **`recreate_project.tcl`** | Used to create the project structure in Vivado (see Installation) |




<!-- 

## Resource Utilisation
## Usage


## Block Design

include block diagram --> 


