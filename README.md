# Reference-FPGA-System
## What is it?
This is an FPGA Register System that can communicate with a host computer or mcu. It also has the ability to run standalone through the built in 6502 CPU core. The program for this CPU core is written in C using the CC65 compiler. With this, accessory modules can be written to share the same address and data bus that the cpu is on allowing for communication with these custom modules. The interfaces provided for communication with a host include: UART, USB, Ethernet (Through Wiznet W5500), and as a Slave SPI device (uses different module).

## Compatibility
This project was aimed to provide compatibility across a wide range of FPGAs from various vendors. Example build scripts given here in which this system was tested on include: Lattice ECP5 using yosys/nextpnr, Lattice ICE40 using yosys/nextpnr, and Intel Cyclone IV E using Quartus Prime Lite 23.1

## Building
To build run make to get preconfigured targets:
```
$ make
Available make targets:
 build_ecp5      - Build for Lattice ECP5
 build_ice40     - Build for Lattice ICE40
 build_cycloneiv - Build for Altera Cyclone IV
 clean           - Remove Build Files
```
## How do I use it?
By creating a new custom module that follows the port structure of those found in the main_6502.sv or main_rv32.sv file, one can create an accessory module that has custom functionality and can be accessed by the 6502. In order to add a new module, an additional enum must be added to the list under the Data Registers and Mux section of main_6502.sv or main_rv32.sv and a start and end address must be given to the mdoule. This is done through the add address function and is added to the module_addresses localparam. The clk, address, write enable, data in, and data out ports must be connected to the rest of the system in order to have access. Data reads from custom modules are expected to have their data available one clock cycle after the accompanying address is given. If a combinatorial output is desired, use of the address_reg logic ensures that data is valid when the CPU expects it.

The host side is up to the specfic use case. Anything that supports a UART type device can be used for communication. Three commands are available for communication: rFPGA (read a register from the FPGA), wFPGA (write a value to a register in the FPGA), and readFPGAVersion (reports the build time and version of the FPGA build running). Additional commands can be added by examining the C program side located in the cc65 folder. The ethernet function works in a similar way, except UDP packets with the string of the command are sent to the appropriate IP Address and port.

An example of using this in Python is as follows:
```Python
SerialObj = serial.Serial("/dev/ttyUSB1")
SerialObj.close()
SerialObj.baudrate = 230400
SerialObj.bytesize = 8
SerialObj.parity  ='N'
SerialObj.stopbits = 1
SerialObj.rtscts = False
SerialObj.dsrdtr = False
SerialObj.xonxoff = False
print(SerialObj.get_settings())
SerialObj.open()
numBufferBytes = SerialObj.in_waiting
SerialObj.read(size=numBufferBytes)

def readFPGAVersion():
    SerialObj.write('readFPGAVersion\n'.encode('utf-8'))
    readVersion = SerialObj.readline()
    readVersion = readVersion[:-1]
    print(readVersion.decode('utf-8'))
    
def writeFPGA(addr, data):
    strtosend = 'wFPGA,' + str(int(addr)) + ',' + str(int(data)) + '\n'
    SerialObj.write(strtosend.encode('utf-8'))

def readFPGA(addr):
    strtosend = 'rFPGA,'+ str(addr) + '\n'
    SerialObj.write(strtosend.encode('utf-8'))
    readData = SerialObj.readline()
    readData = readData[:-1]
    return int(readData.decode('utf-8'))
```
