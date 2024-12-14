# Reference-FPGA-System
## What is it?
This is an FPGA Register System that can communicate with a host computer or mcu. It also has the ability to run standalone through the built in 6502 CPU core. The program for this CPU core is written in C using the CC65 compiler. With this, accessory modules can be written to share the same address and data bus that the cpu is on allowing for communication with these custom modules. The interfaces provided for communication with a host include: UART, USB, and as a Slave SPI device (uses different module).

## Compatibility
This project was aimed to provide compatibility across a wide range of FPGAs from various vendors. Example build scripts given here in which this system was tested on include: Lattice ECP5 using yosys/nextpnr, Lattice ICE40 using yosys/nextpnr, and Intel Cyclone IV E using Quartus Prime Lite 23.1

## How do I use it?
By creating a new custom module that follows the port structure of those found in the main_6502.sv file, one can create an accessory module that has custom functionality and can be accessed by the 6502. In order to add a new module, an additional enum must be added to the list under the Data Registers and Mux section of main_6502.sv and a start and end address must be given to the mdoule. This is done through the add address function and is added to the module_addresses localparam. The clk, address, write enable, data in, and data out ports must be connected to the rest of the system in order to have access. Data reads from custom modules are expected to have their data available one clock cycle after the accompanying address is given. If a combinatorial output is desired, use of the address_reg logic ensures that data is valid when the CPU expects it.

The host side is up to the specfic use case. Anything that supports a UART type device can be used for communication. Three commands are available for communication: rFPGA (read a register from the FPGA), wFPGA (write a value to a register in the FPGA), and readFPGAVersion (reports the build time and version of the FPGA build running). Additional commands can be added by examining the C program side located in the cc65 folder. 
