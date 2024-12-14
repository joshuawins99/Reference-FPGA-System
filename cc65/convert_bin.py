import os

RAM_SIZE = 4096+6
RAM_START_ADDR = "0x2002"
CPU_RAM_START_ADDR = "0x0200" #Also program start location

outputFile = open('test.txt', 'w')

def bytes(integer):
    return divmod(integer, 0x100)

high_start, low_start = bytes(int(CPU_RAM_START_ADDR,16))

outputFile.write("writeFPGA(" + str(int(RAM_START_ADDR, 16) + RAM_SIZE - 4) + ", " + str(low_start) + ");\n")
outputFile.write("writeFPGA(" + str(int(RAM_START_ADDR, 16) + RAM_SIZE - 3) + ", " + str(high_start) + ");\n")

iterator = 0

with open('a.out', 'rb') as f:
    bytes_read = f.read()
for b in bytes_read:
    outputFile.write("writeFPGA(" + str(int(RAM_START_ADDR, 16)+int(CPU_RAM_START_ADDR, 16)+iterator) + ", " + str(b)+');\n')
    iterator = iterator + 1

outputFile.close()
