import os
import sys

outputFile = open('mem_init.mem', 'w')

iterator = 0

if (len(sys.argv) > 1 and sys.argv[1] == "-RV32"):
    with open('a.out', 'rb') as f:
        while True:
            word = f.read(4)  # Read 4 bytes
            if not word:
                break
            
            # Convert to a 32-bit hexadecimal value, assuming little-endian
            hex_value = format(int.from_bytes(word, byteorder='little'), '08x')
            
            # Write to the output file
            outputFile.write(hex_value + '\n')
else :
    with open('a.out', 'rb') as f:
        bytes_read = f.read()
    for b in bytes_read:
        outputFile.write(format(b, 'x'))
        outputFile.write('\n')
        iterator = iterator + 1

outputFile.close()
