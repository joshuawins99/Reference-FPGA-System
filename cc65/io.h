#define IO_6502_BaseAddress        0x9000
#define UART_6502_BaseAddress      0x9100
#define Version_String_BaseAddress 0x8000
#define Ethernet_SPI_BaseAddress   0x9200
#define Timer_6502_BaseAddress     0x9300

#define WriteIO(addr,val)     (*(unsigned char*) (addr) = (val))
#define ReadIO(addr)          (*(unsigned char*) (addr))

// void digitalWrite(unsigned char pin, bool state) {
//     unsigned char read_outputs;
//     read_outputs = ReadIO(IO_6502_BaseAddress+1);
//     switch (pin) {
//     case 1: 
//         WriteIO(IO_6502_BaseAddress+1, (read_outputs & 254) | state);
//         break;
//     case 2:
//         WriteIO(IO_6502_BaseAddress+1, (read_outputs & 253) | (state << 1));
//         break;
//     case 3:
//         WriteIO(IO_6502_BaseAddress+1, (read_outputs & 251) | (state << 2));
//         break;
//     case 4:
//         WriteIO(IO_6502_BaseAddress+1, (read_outputs & 247) | (state << 3));
//         break;
//     case 5:
//         WriteIO(IO_6502_BaseAddress+1, (read_outputs & 239) | (state << 4));
//         break;
//     case 6:
//         WriteIO(IO_6502_BaseAddress+1, (read_outputs & 223) | (state << 5));
//         break;
//     case 7:
//         WriteIO(IO_6502_BaseAddress+1, (read_outputs & 191) | (state << 6));
//         break;
//     case 8:
//         WriteIO(IO_6502_BaseAddress+1, (read_outputs & 127) | (state << 7));
//         break;
//     }
// }

// unsigned char digitalRead (unsigned char pin) {
//     switch (pin) {
//     case 1: 
//         return (ReadIO(IO_6502_BaseAddress) & 1);
//     case 2:
//         return (ReadIO(IO_6502_BaseAddress) & 2);
//     case 3:
//         return (ReadIO(IO_6502_BaseAddress) & 4);
//     case 4:
//         return (ReadIO(IO_6502_BaseAddress) & 8);
//     case 5:
//         return (ReadIO(IO_6502_BaseAddress) & 16);
//     case 6:
//         return (ReadIO(IO_6502_BaseAddress) & 32);
//     case 7:
//         return (ReadIO(IO_6502_BaseAddress) & 64);
//     case 8:
//         return (ReadIO(IO_6502_BaseAddress) & 128);
//     }
// }

void Sleep (unsigned long);
void AddLine ();
void Print (bool, char[]);
char* ReadVersion ();
char* readFPGA (char[]);
void writeFPGA (char[], char[]);
char* executeCommandsSerial(char *);
void ReadUART();
void StartEthernetInit();

