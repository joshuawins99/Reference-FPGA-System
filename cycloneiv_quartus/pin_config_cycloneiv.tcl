set_location_assignment PIN_23 -to clk_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk_i

set_location_assignment PIN_38 -to reset_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to reset_i

set_location_assignment PIN_70 -to usb_dp_pull
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_dp_pull

set_location_assignment PIN_68 -to usb_dp
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_dp

set_location_assignment PIN_66 -to usb_dn
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb_dn

set_location_assignment PIN_144 -to ex_data_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ex_data_o

set_location_assignment PIN_111 -to uart_rx_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to uart_rx_i

set_location_assignment PIN_110 -to uart_tx_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to uart_tx_o