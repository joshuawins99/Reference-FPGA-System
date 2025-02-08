#include "io.h"

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
        WriteIO(Timer_6502_BaseAddress, value[i]);
    }
    WriteIO(Timer_6502_BaseAddress+1, 1);

    // Wait until the timer status is non-zero
    do {
        timer_status = ReadIO(Timer_6502_BaseAddress+2);
    } while (timer_status == 0);
}

void DACWrite(char *txchar) {
    unsigned char busy_status = 0;
    unsigned txdata = atoi(txchar);

    WriteIO(DAC_SPI_BaseAddress, 0b00010000);
    WriteIO(DAC_SPI_BaseAddress, (txdata >> 8));
    WriteIO(DAC_SPI_BaseAddress, (txdata & 0x00FF));
    WriteIO(DAC_SPI_BaseAddress+2, 1); //Start Transaction in SPI Module
    do {
        busy_status = ReadIO(DAC_SPI_BaseAddress+3);
    } while (busy_status == 1);
}

void ADCMeasure(char *NumReadingsChar) {
    unsigned NumReadings = atoi(NumReadingsChar);
    unsigned char busy_status = 0;

    WriteIO(ADC_SPI_BaseAddress+4, (NumReadings >> 8));
    WriteIO(ADC_SPI_BaseAddress+4, (NumReadings & 0x00FF));
    WriteIO(ADC_SPI_BaseAddress+2, 1); //Start Transaction in SPI Module
    do {
        busy_status = ReadIO(ADC_SPI_BaseAddress+3);
    } while (busy_status == 1);
}

char* ReadADCData(char *NumReadingsChar) {
    unsigned NumReadings = atoi(NumReadingsChar);
    unsigned char upperbits;
    unsigned char lowerbits;
    char returnval[6];
    unsigned value;
    unsigned i;

    for (i = 0; i < NumReadings; ++i) {
        upperbits = ReadIO(ADC_SPI_BaseAddress+1);
        __asm__ ("nop");
        lowerbits = ReadIO(ADC_SPI_BaseAddress+1);
        value = ((upperbits & 0b00011111) << 8) | lowerbits;
        sprintf(returnval, "%d", value);
        if (NumReadings > 1) {
            Print(1, returnval);
        } 
    }
    if (NumReadings > 1) {
        return "";
    } else {
        return returnval;
    }
}

void Print(unsigned char line, char *data) {
    unsigned char busy_status = 0;
    unsigned char iterator = 0;
    unsigned char strlength = strlen(data);

    while (iterator < strlength || (line && iterator == strlength)) {
        busy_status = ReadIO(UART_6502_BaseAddress+2);
        if (busy_status == 0) {
            if (iterator < strlength) {
                WriteIO(UART_6502_BaseAddress, data[iterator]);
                ++iterator;
            } else if (line) {
                WriteIO(UART_6502_BaseAddress, '\n');
                line = 0;  // To exit the loop after writing the newline character
            }
            WriteIO(UART_6502_BaseAddress+1, 1);
        }
    }
}

char* ReadVersion() {
    char readversion[VersionStringSize];
    char current_char;
    unsigned char count = 0;
    unsigned char i;

    for (i = 0; i < VersionStringSize; ++i) {
        current_char = (char) ReadIO(Version_String_BaseAddress+i);
        if (current_char == '\0') {
            ++count;
        } else {
            readversion[i-count] = current_char;
        }
    }
    return readversion;
}

char* readFPGA(char *addr) {
    char rd_data[3];

    sprintf(rd_data, "%d", ReadIO(atoi(addr)));
    return rd_data;
}

void writeFPGA(char *addr, char *data) {
    WriteIO(atoi(addr), atoi(data));
}

const char READF[]    = "rFPGA,";
const char WRITEF[]   = "wFPGA,";
const char RVERSION[] = "readFPGAVersion";
const char WDAC[]     = "wDAC,";
const char ADCMeas[]  = "ADCMeas,";
const char RADC[]     = "rADC,";

char* executeCommandsSerial(char *data) {
    unsigned char j = 0;
    unsigned char k = 0;
    unsigned char address_done = 0;
    char addr_sub[6];
    char data_sub[4];

    if (strncmp(data, READF, 5) == 0) {
        strncpy(addr_sub, data+6, (strlen(data))-6);
        return readFPGA(&addr_sub[0]);
    } else if (strncmp(data, WRITEF, 5) == 0) {
        for (j = 6; j <= (strlen(data)); ++j) {
            if (data[j] != ',' && address_done == 0) {
                addr_sub[j-6] = data[j];
            } else if (data[j] != '\n' && data[j] != '\r' && data[j] != ',') {
                data_sub[k] = data[j];
                ++k;
            } else {
                address_done = 1;
            }
        }
        writeFPGA(&addr_sub[0], &data_sub[0]);
        return "";
    } else if (strncmp(data, RVERSION, 14) == 0) {
        return ReadVersion();
    } else if (strncmp(data, WDAC, 4) == 0) {
        DACWrite(&data[5]);
        return "";
    } else if (strncmp(data, ADCMeas, 7) == 0) {
        ADCMeasure(&data[8]);
        return "";
    } else if (strncmp(data, RADC, 4) == 0) {
        return ReadADCData(&data[5]);
    } else {
        return "";
    }
}

void ReadUART() {
    unsigned char char_iter;
    char *commandOutput;
    char readuart[20];

    if (ReadIO(UART_6502_BaseAddress+4) == 0) {
        readuart[char_iter] = (char) ReadIO(UART_6502_BaseAddress+3);
        if (readuart[char_iter] != '\n') {
            ++char_iter;
        } else {
            readuart[char_iter] = (char) 0;
            char_iter = 0;
            commandOutput = executeCommandsSerial(&readuart[0]);
            if (commandOutput != "") {
                Print(1, commandOutput);
            }
        }
    }
}
