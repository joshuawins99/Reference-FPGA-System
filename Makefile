BASE_DIR := $(shell pwd)
SCRIPTS_DIR := scripts
QUARTUS_ROOT_DIR := /root/altera_lite/24.1std/quartus
CC65_DIR := cc65
ECP5_DIR := ecp5
ECP5_FILELIST := rtl_filelist.txt
ICE40_DIR := ice40
ICE40_FILELIST := rtl_filelist.txt
CYCLONEIV_DIR := cycloneiv_quartus
CYCLONEIV_FILELIST := rtl_filelist.txt
VERSION_FILE = rtl/version_string.svh

# Default target: Show available options
all:
	@echo "Available make targets:"
	@echo " build_ecp5      - Build for Lattice ECP5"
	@echo " build_ice40     - Build for Lattice ICE40"
	@echo " build_cycloneiv - Build for Altera Cyclone IV"
	@echo " clean           - Remove Build Files"

build_ecp5:
	@echo "Building for ECP5...\n"
	@make .build_ecp5_int 2>&1 | python3 $(SCRIPTS_DIR)/error_check.py "make" $(ECP5_DIR)/warnings_ecp5.txt $(ECP5_DIR)/output_ecp5.txt $(ECP5_DIR)/result_ecp5.txt ""

.build_ecp5_int:
	@make .version
	@make .build_cc65
	@(cd $(ECP5_DIR) && \
	yosys -q -p "abc_new; read_verilog -sv -DUSB_UART -DECP5 -nooverwrite $(shell cd $(ECP5_DIR) && $(BASE_DIR)/$(SCRIPTS_DIR)/convert_filelist.sh $(ECP5_FILELIST)); \
	hierarchy -top main_ecp5; synth_ecp5 -top main_ecp5 -json main.json" && \
	nextpnr-ecp5 --25k --package CABGA256 --speed 6 --json main.json --textcfg main.config --lpf pin_config_ecp5.lpf --lpf-allow-unconstrained --randomize-seed && \
	ecppack --compress --bit main.bit main.config && \
	rm -f main.config main.json && \
	mv main.bit $(BASE_DIR)/main.bin)
	@python3 $(BASE_DIR)/$(SCRIPTS_DIR)/convert_bin.py

build_ice40:
	@echo "Building for ICE40...\n"
	@make .build_ice40_int 2>&1 | python3 $(SCRIPTS_DIR)/error_check.py "make" $(ICE40_DIR)/warnings_ice40.txt $(ICE40_DIR)/output_ice40.txt $(ICE40_DIR)/result_ice40.txt ""

.build_ice40_int:
	@make .version
	@make .build_cc65
	@(cd $(ICE40_DIR) && \
	yosys -q -p "abc_new; read_verilog -sv -nooverwrite $(shell cd $(ICE40_DIR) && $(BASE_DIR)/$(SCRIPTS_DIR)/convert_filelist.sh $(ICE40_FILELIST)); \
	hierarchy -top main_ice40; synth_ice40 -top main_ice40 -json main.json" && \
	nextpnr-ice40 --up5k --package sg48 --json main.json --pcf pin_config_ice40.pcf --asc main.asc --pcf-allow-unconstrained --randomize-seed --timing-allow-fail && \
	icepack main.asc main.bin && \
	rm -f main.asc main.json && \
	mv main.bin $(BASE_DIR)/main.bin)
	@python3 $(BASE_DIR)/$(SCRIPTS_DIR)/convert_bin.py

build_cycloneiv:
	@echo "Building for Cyclone IV...\n"
	@make .build_cycloneiv_int 2>&1 | python3 $(SCRIPTS_DIR)/error_check.py "make" $(CYCLONEIV_DIR)/warnings_cycloneiv.txt $(CYCLONEIV_DIR)/output_cycloneiv.txt \
	$(CYCLONEIV_DIR)/result_cycloneiv.txt ""

.build_cycloneiv_int:
	@make .version
	@make .build_cc65
	@(cd $(CYCLONEIV_DIR) && \
	$(BASE_DIR)/$(SCRIPTS_DIR)/convert_filelist.sh rtl_filelist.txt --quartus && \
	$(QUARTUS_ROOT_DIR)/bin/quartus_sh --flow compile main.qpf && \
	mv output_files/main.sof $(BASE_DIR)/main.sof)

.version:
	@echo -n '`define version_string ' > $(VERSION_FILE)
	@if [ "$(VERSION_TYPE)" = "REL" ]; then \
		echo -n '"' >> $(VERSION_FILE); \
		echo -n "REL " >> $(VERSION_FILE); \
		git rev-parse --verify HEAD | cut -c1-7 | xargs echo -n >> $(VERSION_FILE); \
	else \
			echo -n '"' >> $(VERSION_FILE); \
			echo -n "DEV " >> $(VERSION_FILE); \
			echo -n "1234567" >> $(VERSION_FILE); \
	fi
	@echo -n ' ' >> $(VERSION_FILE)
	@date --date 'now' '+%a %b %d %r %Z %Y' | sed -e "s/$$/\"/" -e "s/,/\",\"/g" >> $(VERSION_FILE)

.build_cc65:
	@(cd $(CC65_DIR) && ./build.sh)

# Clean target
clean:
	@echo "Cleaning up...\n"
	@rm -rf main.bin main.sof fpga_image.h resized_flash.bin $(VERSION_FILE)
	@(cd $(ECP5_DIR) && rm -rf output_ecp5.txt result_ecp5.txt)
	@(cd $(ICE40_DIR) && rm -rf output_ice40.txt result_ice40.txt)
	@(cd $(CYCLONEIV_DIR) && rm -rf db incremental_db output_files file_list.qsf output_cycloneiv.txt result_cycloneiv.txt)
	@(cd $(CC65_DIR) && rm -rf *.c *.h *.py *.o *.s *.l *.m *.lib *.mem *.out)

.PHONY: all build_ecp5 build_ice40 build_cycloneiv clean
