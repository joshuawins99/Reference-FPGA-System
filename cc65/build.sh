#!/bin/bash
rm -f none.lib
rm -f *.l *.m *.o *.c *.s *.h *.py *.out *.mem
rm -f mem_init.mem
cp /share/cc65/lib/none.lib .
cp ../C_Code/* .
ca65 --cpu 65c02 crt0.s
ca65 --cpu 65c02 irq.s
ar65 r none.lib crt0.o irq.o
cc65 -t none -Oir -Cl --cpu 65c02 main.c 
ca65 --cpu 65c02 -g main.s -o main.o -l main.l
ld65 -C none.cfg -vm -m main.m -o a.out main.o none.lib
python3 convert_bin_init.py