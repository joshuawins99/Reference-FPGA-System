#!/bin/bash
rm -f none.lib
rm -f *.l *.m *.o
rm -f main.s
rm -f mem_init.mem
cp /cc65/lib/none.lib .
ca65 --cpu 6502 crt0.s
ca65 --cpu 6502 irq.s
ar65 a none.lib crt0.o irq.o
cc65 -t none -Osir -Cl --cpu 6502 main.c
ca65 --cpu 6502 -g main.s -o main.o -l main.l
ld65 -C none.cfg -vm -m main.m -o a.out main.o none.lib
python3 convert_bin_init.py