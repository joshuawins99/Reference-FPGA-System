import os

#inputFile = open('main.bin', 'rb')
outputFile = open('fpga_image.h', 'w')
flashFile = open('resized_flash.bin', 'wb')
outputFile.write('const uint8_t FPGAConfig[] = {')
bufSize = 128
count = 0
# data = bytearray(inputFile.read()) + bytearray([0] * (bufSize * 2))

# def sendBlock(data):
#     for d in data:
#         outputFile.write(str(d) +',')

# while len(data) > bufSize:
#     block = data[:bufSize]
#     data = data[bufSize:]
#     sendBlock(block)

with open('main.bin', 'rb') as f:
    bytes_read = f.read()
for b in bytes_read:
    count = count + 1
    flashFile.write(bytes([b]))
    outputFile.write(str(b)+',')

for x in range(count, 2097152):
    flashFile.write(bytes([0]))

flashFile.close

#for b in range(128):
#    outputFile.write(str(0)+',')


outputFile.seek(outputFile.tell()-1, os.SEEK_SET)
outputFile.write('')
outputFile.write('};')
outputFile.close()
