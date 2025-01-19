#include "io.h"

void Sleep (unsigned long delay_time) { //In 10^-4 seconds
    unsigned char value[4];
    unsigned char i;
    unsigned char timer_status;
    value[0] = (delay_time >> 24) & 0xFF;
    value[1] = (delay_time >> 16) & 0xFF;
    value[2] = (delay_time >> 8)  & 0xFF;
    value[3] = delay_time & 0xFF;

    for (i = 0; i < sizeof(value); ++i) {
        WriteIO(Timer_6502_BaseAddress,value[i]);
    }
    WriteIO(Timer_6502_BaseAddress+1, 1);
    timer_status = ReadIO(Timer_6502_BaseAddress+2);
    while (timer_status == 0) {
        timer_status = ReadIO(Timer_6502_BaseAddress+2);
    }
}

void AddLine () {
    char new_line[1] = "\n";
    unsigned char busy_status = ReadIO(UART_6502_BaseAddress+2);
    unsigned char iterator = 0;
    while (iterator < 1) {
        busy_status = ReadIO(0x9102);
        if (busy_status == 0) {
            WriteIO(UART_6502_BaseAddress, new_line[iterator]);
            WriteIO(UART_6502_BaseAddress+1, 1);
            iterator = iterator + 1;
        } else {
            busy_status = ReadIO(UART_6502_BaseAddress+2);
        }
    }
}

void Print (bool line, char data[]) {
    unsigned char busy_status = 0;
    unsigned char iterator = 0;
    while (iterator < strlen(data)) {
        busy_status = ReadIO(UART_6502_BaseAddress+2);
        if (busy_status == 0) {
            WriteIO(UART_6502_BaseAddress, data[iterator]);
            WriteIO(UART_6502_BaseAddress+1, 1);
            iterator = iterator + 1;
        } else {
            busy_status = ReadIO(UART_6502_BaseAddress+2);
        }
    }
    if (line == 1) {
        AddLine();
    }
}

const char READF[] = "rFPGA,";
const char WRITEF[] = "wFPGA,";
const char RVERSION[] = "readFPGAVersion";
char readuart[20];
char readversion[45];
unsigned char readuartstatus;
unsigned char char_iter = 0;
char addr_sub[6];
char data_sub[4];

char* ReadVersion() {
    unsigned long i = Version_String_BaseAddress+0x2A;
    memset(&readversion[0], 0, sizeof(readversion));
    for (i = Version_String_BaseAddress+0x2A; i >= Version_String_BaseAddress; i --) {
        readversion[(Version_String_BaseAddress+0x2A)-i] = (char) ReadIO(i);
    }
    return readversion;
}

char* readFPGA(char addr[6]) {
    char rd_data[3];
    sprintf(rd_data, "%d", ReadIO(atoi(addr)));
    return rd_data;
}
void writeFPGA(char addr[6], char data[4]) {
    WriteIO(atoi(addr), atoi(data));
}

char* executeCommandsSerial(char *data) {
    unsigned char j = 0;
    unsigned char k = 0;
    unsigned char address_done = 0;
    if (strncmp(data, READF, 5) == 0) {
        strncpy(addr_sub, data + 6, (strlen(data)) - 6);
        return readFPGA(addr_sub);
        memset(&addr_sub[0], 0, sizeof(addr_sub));
    } else if (strncmp(data, WRITEF, 5) == 0) {
        for (j = 6; j <= (strlen(data)); ++j) {
            if (data[j] != ',' && address_done == 0) {
                addr_sub[j-6] = data[j];
            } else if (data[j] != '\n' && data[j] != '\r' && data[j] != ',') {
                data_sub[k] = data[j];
                k = k + 1;
            } else {
                address_done = 1;
            }
        }
        writeFPGA(addr_sub, data_sub);
        memset(&addr_sub[0], 0, sizeof(addr_sub));
        memset(&data_sub[0], 0, sizeof(data_sub));
        return "";
    } else if (strncmp(data, RVERSION, 14) == 0) {
        return ReadVersion();
    }
}

void ReadUART() {
    unsigned char i = 0;
    char* commandOutput;
    readuartstatus = ReadIO(UART_6502_BaseAddress+4);
    if (readuartstatus == 0) {
        readuart[char_iter] = (char) ReadIO(UART_6502_BaseAddress+3);
        if (readuart[char_iter] != '\n') {
            char_iter = char_iter + 1;
        } else {
            readuart[char_iter] = (char) 0;
            char_iter = 0;
            commandOutput = executeCommandsSerial(&readuart[0]);
            if (commandOutput != "") {
                Print(1, commandOutput);
                memset(&commandOutput[0], 0, sizeof(commandOutput));
            }
            memset(&readuart[0], 0, sizeof(readuart));
        }
    }
}
