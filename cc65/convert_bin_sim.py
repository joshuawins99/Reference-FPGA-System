import os

RAM_SIZE = 2054
RAM_START_ADDR = "0x2002"
CPU_RAM_START_ADDR = "0x0200" #Also program start location

outputFile = open('test.txt', 'w')

def bytes(integer):
    return divmod(integer, 0x100)

high_start, low_start = bytes(int(CPU_RAM_START_ADDR,16))

outputFile.write("Send_SPI(1, " + "'d" + str(int(RAM_START_ADDR, 16) + RAM_SIZE - 4) + ", 'd" + str(low_start) + ");\n")
outputFile.write("Send_SPI(1, " + "'d" + str(int(RAM_START_ADDR, 16) + RAM_SIZE - 3) + ", 'd" + str(high_start) + ");\n")

iterator = 0

with open('a.out', 'rb') as f:
    bytes_read = f.read()
for b in bytes_read:
    outputFile.write("Send_SPI(1, 'd" + str(int(RAM_START_ADDR, 16)+int(CPU_RAM_START_ADDR, 16)+iterator) + ", 'd" + str(b)+');\n')
    iterator = iterator + 1

outputFile.close()
