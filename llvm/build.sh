#!/bin/bash
rm -f none.lib
rm -f *.l *.m *.o *.elf *.s *.h *.py
rm -f mem_init.mem
cp ../C_Code/* .

mos-common-clang -DLLVM -o a.out -Os main.c -lexit-loop -linit-stack -flto -fnonreentrant -mcpu=mos65c02
python3 convert_bin_init.py
