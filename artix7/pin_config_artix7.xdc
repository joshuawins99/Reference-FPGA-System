create_clock -period 10.000 [get_ports clk_i]

set_property PACKAGE_PIN N14 [get_ports clk_i]
set_property IOSTANDARD LVCMOS33 [get_ports clk_i]

set_property PACKAGE_PIN T9 [get_ports uart_rx_i]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx_i]

set_property PACKAGE_PIN T10 [get_ports uart_tx_o]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx_o]

set_property PACKAGE_PIN K13 [get_ports ex_data_o[0]]
set_property IOSTANDARD LVCMOS33 [get_ports ex_data_o[0]]

set_property PACKAGE_PIN K12 [get_ports ex_data_o[1]]
set_property IOSTANDARD LVCMOS33 [get_ports ex_data_o[1]]

set_property PACKAGE_PIN L14 [get_ports ex_data_o[2]]
set_property IOSTANDARD LVCMOS33 [get_ports ex_data_o[2]]

set_property PACKAGE_PIN L13 [get_ports ex_data_o[3]]
set_property IOSTANDARD LVCMOS33 [get_ports ex_data_o[3]]

set_property PACKAGE_PIN M16 [get_ports ex_data_o[4]]
set_property IOSTANDARD LVCMOS33 [get_ports ex_data_o[4]]

set_property PACKAGE_PIN M14 [get_ports ex_data_o[5]]
set_property IOSTANDARD LVCMOS33 [get_ports ex_data_o[5]]

set_property PACKAGE_PIN M12 [get_ports ex_data_o[6]]
set_property IOSTANDARD LVCMOS33 [get_ports ex_data_o[6]]

set_property PACKAGE_PIN N16 [get_ports ex_data_o[7]]
set_property IOSTANDARD LVCMOS33 [get_ports ex_data_o[7]]