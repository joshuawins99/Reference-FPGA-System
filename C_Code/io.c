#include "io.h"
#include "ethernet.h"

void Sleep(unsigned long delay_time) { // In 10^-4 seconds
    unsigned char value[4];
    unsigned char i;
    unsigned char timer_status;

    value[0] = (delay_time >> 24) & 0xFF;
    value[1] = (delay_time >> 16) & 0xFF;
    value[2] = (delay_time >> 8)  & 0xFF;
    value[3] = delay_time & 0xFF;

    // Write the value array to the timer base address
    for (i = 0; i < 4; ++i) {
        WriteIO(Timer_CPU_BaseAddress, value[i]);
    }
    WriteIO(Timer_CPU_BaseAddress+(1*ADDR_WORD), 1);

    // Wait until the timer status is non-zero
    do {
        timer_status = ReadIO(Timer_CPU_BaseAddress+(2*ADDR_WORD));
    } while (timer_status == 0);
}

void DACWrite(char *txchar) {
    unsigned char busy_status = 0;
    unsigned txdata = atoi(txchar);

    WriteIO(DAC_SPI_BaseAddress, 0b00010000);
    WriteIO(DAC_SPI_BaseAddress, (txdata >> 8));
    WriteIO(DAC_SPI_BaseAddress, (txdata & 0x00FF));
    WriteIO(DAC_SPI_BaseAddress+(2*ADDR_WORD), 1); //Start Transaction in SPI Module
    do {
        busy_status = ReadIO(DAC_SPI_BaseAddress+(3*ADDR_WORD));
    } while (busy_status == 1);
}

void ADCMeasure(char *NumReadingsChar) {
    unsigned NumReadings = atoi(NumReadingsChar);
    unsigned char busy_status = 0;

    WriteIO(ADC_SPI_BaseAddress+(4*ADDR_WORD), (NumReadings >> 8));
    WriteIO(ADC_SPI_BaseAddress+(4*ADDR_WORD), (NumReadings & 0x00FF));
    WriteIO(ADC_SPI_BaseAddress+(2*ADDR_WORD), 1); //Start Transaction in SPI Module
    do {
        busy_status = ReadIO(ADC_SPI_BaseAddress+(3*ADDR_WORD));
    } while (busy_status == 1);
}

char* ReadADCData(char *NumReadingsChar) {
    unsigned NumReadings = atoi(NumReadingsChar);
    unsigned char upperbits;
    unsigned char lowerbits;
    static char returnval[6];
    unsigned value;
    unsigned i;

    for (i = 0; i < NumReadings; ++i) {
        #if !defined(LLVM) && !defined(RV32)
            upperbits = ReadIO(ADC_SPI_BaseAddress+1);
            __asm__ ("nop");
            lowerbits = ReadIO(ADC_SPI_BaseAddress+1);
        #else
            upperbits = ReadIO(ADC_SPI_BaseAddress+(1*ADDR_WORD));
            lowerbits = ReadIO(ADC_SPI_BaseAddress+(1*ADDR_WORD));
        #endif
        value = ((upperbits & 0b00011111) << 8) | lowerbits;
        sprintf(returnval, "%d", value);
        if (NumReadings > 1) {
            //For Burst Readings Either Serial or Ethernet
            //Print(1, returnval);
            EthSendUDP(0, returnval);
        } 
    }
    if (NumReadings > 1) {
        return NULL;
    } else {
        return returnval;
    }
}

void Print(unsigned char line, char *data) {
    unsigned char busy_status = 0;
    unsigned char iterator = 0;
    unsigned char strlength = strlen(data);

    while (iterator < strlength || (line && iterator == strlength)) {
        busy_status = ReadIO(UART_CPU_BaseAddress+(2*ADDR_WORD));
        if (busy_status == 0) {
            if (iterator < strlength) {
                WriteIO(UART_CPU_BaseAddress, data[iterator]);
                ++iterator;
            } else if (line) {
                WriteIO(UART_CPU_BaseAddress, '\n');
                line = 0;  // To exit the loop after writing the newline character
            }
            WriteIO(UART_CPU_BaseAddress+(1*ADDR_WORD), 1);
        }
    }
}

char* ReadVersion() {
    static char readversion[VersionStringSize];
    char current_char;
    unsigned char count = 0;
    unsigned char i;

    for (i = 0; i < VersionStringSize; ++i) {
        current_char = (char) ReadIO(Version_String_BaseAddress+(i*ADDR_WORD));
        if (current_char == '\0') {
            ++count;
        } else {
            readversion[i-count] = current_char;
        }
    }
    return readversion;
}

char* readFPGA(char *addr) {
    static char rd_data[3];

    sprintf(rd_data, "%d", ReadIO(atoi(addr)));
    return rd_data;
}

void writeFPGA(char *addr, char *data) {
    WriteIO(atoi(addr), atoi(data));
}

typedef char* (*command_func)(char*);

typedef struct {
    const char *command;
    command_func func;
    unsigned char length;
} command_entry;

const char READF[]    = "rFPGA,";
const char WRITEF[]   = "wFPGA,";
const char RVERSION[] = "readFPGAVersion";
const char WDAC[]     = "wDAC,";
const char ADCMeas[]  = "ADCMeas,";
const char RADC[]     = "rADC,";

char* readFPGAWrapper(char *data) {
    static char addr_sub[6];
    strncpy(addr_sub, data + 6, strlen(data) - 6);
    return readFPGA(&addr_sub[0]);
}

char* writeFPGAWrapper(char *data) {
    static char addr_sub[6];
    static char data_sub[4];
    unsigned char j = 0;
    unsigned char k = 0;
    unsigned char address_done = 0;

    for (j = 6; j <= (strlen(data)); ++j) {
        if (data[j] != ',' && address_done == 0) {
            addr_sub[j - 6] = data[j];
        } else if (data[j] != '\n' && data[j] != '\r' && data[j] != ',') {
            data_sub[k] = data[j];
            ++k;
        } else {
            address_done = 1;
        }
    }
    writeFPGA(&addr_sub[0], &data_sub[0]);
    return NULL;
}

char* DACWriteWrapper(char *data) {
    DACWrite(&data[5]);
    return NULL;
}

char* ADCMeasureWrapper(char *data) {
    ADCMeasure(&data[8]);
    return NULL;
}

char* ReadADCDataWrapper(char *data) {
    return ReadADCData(&data[5]);
}

const command_entry commands[] = {
    {READF,    readFPGAWrapper,    sizeof(READF)-1   },
    {WRITEF,   writeFPGAWrapper,   sizeof(WRITEF)-1  },
    {RVERSION, ReadVersion,        sizeof(RVERSION)-1},
    {WDAC,     DACWriteWrapper,    sizeof(WDAC)-1    },
    {ADCMeas,  ADCMeasureWrapper,  sizeof(ADCMeas)-1 },
    {RADC,     ReadADCDataWrapper, sizeof(RADC)-1    }
};

const unsigned char num_commands = sizeof(commands) / sizeof(commands[0]); //Divide total size in bytes by the size in bytes of a single element

char* executeCommandsSerial(char *data) {
    unsigned char i;

    for (i = 0; i < num_commands; ++i) {
        if (strncmp(data, commands[i].command, commands[i].length) == 0) {
            return commands[i].func(data);
        }
    }
    return NULL;
}

void ReadUART() {
    static unsigned char char_iter;
    char *commandOutput;
    static char readuart[20];

    if (ReadIO(UART_CPU_BaseAddress+(4*ADDR_WORD)) == 0) {
        readuart[char_iter] = (char) ReadIO(UART_CPU_BaseAddress+(3*ADDR_WORD));
        if (readuart[char_iter] != '\n') {
            ++char_iter;
        } else {
            readuart[char_iter] = (char) 0;
            char_iter = 0;
            commandOutput = executeCommandsSerial(&readuart[0]);
            if (commandOutput != NULL) {
                Print(1, commandOutput);
            }
        }
    }
}
