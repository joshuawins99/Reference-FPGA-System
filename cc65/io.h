#define IO_6502_BaseAddress        0x9000
#define UART_6502_BaseAddress      0x9100
#define Version_String_BaseAddress 0x8000
#define Ethernet_SPI_BaseAddress   0x9200
#define DAC_SPI_BaseAddress        0x9210
#define ADC_SPI_BaseAddress        0x9220
#define Timer_6502_BaseAddress     0x9300

#define VersionStringSize 64

#define WriteIO(addr,val)     (*(unsigned char*) (addr) = (val))
#define ReadIO(addr)          (*(unsigned char*) (addr))

void Sleep (unsigned long);
void DACWrite(char *);
void ADCMeasure(char *);
char* ReadADCData(char *);
void Print (unsigned char, char *);
char* ReadVersion ();
char* readFPGA (char *);
void writeFPGA (char *, char *);
char* executeCommandsSerial(char *);
void ReadUART();
void StartEthernetInit();

