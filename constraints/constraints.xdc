# ethernet RX
set_property PACKAGE_PIN M17 [get_ports {ETH_RXD[3]}]
set_property PACKAGE_PIN M18 [get_ports {ETH_RXD[2]}]
set_property PACKAGE_PIN K14 [get_ports {ETH_RXD[1]}]
set_property PACKAGE_PIN J14 [get_ports {ETH_RXD[0]}]
set_property PACKAGE_PIN K17 [get_ports ETH_RXCK]
set_property PACKAGE_PIN K18 [get_ports ETH_RXDV]

# ethernet TX
set_property PACKAGE_PIN L14 [get_ports ETH_TXCK]

# ethernet reset (updated to J20 from H20)
set_property PACKAGE_PIN J20 [get_ports ETH_nRST]

# keys
set_property PACKAGE_PIN P16 [get_ports PL_KEY1]

# leds
set_property PACKAGE_PIN P15 [get_ports PL_LED1]
set_property PACKAGE_PIN U12 [get_ports PL_LED2]

# clk
set_property PACKAGE_PIN N18 [get_ports PL_CLK_50M]

# IO standards
set_property IOSTANDARD LVCMOS33 [get_ports ETH_*]
set_property IOSTANDARD LVCMOS33 [get_ports PL_KEY1]
set_property IOSTANDARD LVCMOS33 [get_ports PL_LED1]
set_property IOSTANDARD LVCMOS33 [get_ports PL_LED2]
set_property IOSTANDARD LVCMOS33 [get_ports PL_CLK_50M]

# RX clock constraint (25MHz)
create_clock -period 40.000 -name eth_rx_clk [get_ports ETH_RXCK]
