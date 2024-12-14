#!/bin/bash
rm -f main.bin
rm -f rtl/uart_vhd_6502.v
python3 update_vhdl_params.py main_ecp5.sv
cd cc65
./build.sh
cd ../rtl
echo -n '`define version_string ' > version_string.svh
if [ "$1" = -build ]; then
    if [ "$2" = REL ]; then
        echo -n '"' >> version_string.svh
        echo -n "REL " >> version_string.svh
        git rev-parse --verify HEAD | cut -c1-7 | xargs echo -n >> version_string.svh
    else
        echo -n '"' >> version_string.svh
        echo -n "DEV " >> version_string.svh
        echo -n "1234567" >> version_string.svh
    fi
else 
    echo -n '"' >> version_string.svh
    echo -n "DEV " >> version_string.svh
    echo -n "1234567" >> version_string.svh
fi

#git rev-parse --verify HEAD | cut -c1-7 | xargs echo -n | sed -e 's/^/"/' >> version_string.svh
echo -n ' ' >> version_string.svh
date --date 'now' '+%a %b %d %r %Z %Y' | sed -e 's/$/"/' -e 's/,/","/g' >> version_string.svh
ghdl --synth --out=verilog modules/uart_vhdl/*.vhd -e UART_VHD_6502 > uart_vhd_6502.v
yosys -q -p 'abc_new; read_verilog -sv -DUSB_UART -nooverwrite main_ecp5.sv main_6502.sv modules/*.* modules/6502/* modules/async_fifo/* modules/usb_serial/* uart_vhd_6502.v pll_ecp5.v; hierarchy -top main_ecp5; synth_ecp5 -top main_ecp5 -json main.json'
nextpnr-ecp5 --25k --package CABGA256 --speed 6 --json main.json --textcfg main.config --lpf ../pin_config_ecp5.lpf --lpf-allow-unconstrained --randomize-seed --sdc ../main_sdc.sdc
ecppack --compress --bit main.bit main.config
rm -f main.config main.json
mv main.bit ../main.bin

#echo ""
#echo "************************************"
#echo "         Starting Testbench"
#echo "************************************"

#iverilog -g2012 -i -o main_tb ../sim/main_tb.sv main.sv slave_spi_controller.sv spi_slave.sv led_control.sv version_string.sv CAN_Silent.sv 6502/cpu.v 6502/ALU.v dual_port_ram.sv system_6502_top.sv io_6502.sv k_line.sv uart_vhd_kline.v async_fifo/* 2>&1 | grep -v "sorry: Case unique/unique0 qualities are ignored\."
#vvp main_tb
#rm main_tb
#../../gtkwave/build/src/gtkwave main_tb.vcd wave.gtkw
cd ..
python3 convert_bin.py
