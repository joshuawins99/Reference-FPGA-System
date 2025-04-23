#!/bin/bash
cp ../C_Code/* .

riscv32-unknown-elf-gcc -DRV32 -std=c99 -mabi=ilp32 -march=rv32i -nostartfiles -Os -static -specs=nano.specs -Wl,-Tsections.lds -Wl,-Map=output.map -o a.elf start.s  main.c 

riscv32-unknown-elf-objcopy -O binary a.elf a.out

python3 convert_bin_init.py -RV32
