quit -sim
vlib work
vlog -work work -incr -sv ../rtl/main.sv
vlog -work work -incr -sv ../rtl/slave_spi_controller.sv
vlog -work work -incr -sv ../rtl/spi_slave.sv
vlog -work work -incr -sv ../rtl/led_control.sv
vlog -work work -incr -sv ../rtl/version_string.sv
vlog -work work -incr -sv ../rtl/version_string.svh
vlog -work work -incr -sv ../rtl/CAN_Silent.sv
vlog -work work -incr -sv ../rtl/6502/cpu.v
vlog -work work -incr -sv ../rtl/6502/ALU.v
vlog -work work -incr -sv ../rtl/dual_port_ram.sv
vlog -work work -incr -sv ../rtl/system_6502_top.sv
vlog -work work -incr -sv ../rtl/io_6502.sv

vlog -work work -incr -sv main_tb.sv

vsim -t 100ps -voptargs=+acc work.main_tb
#do wave.do
run -all
