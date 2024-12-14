#define IO_6502_BaseAddress        0x9000
#define UART_6502_BaseAddress      0x9100
#define Version_String_BaseAddress 0x8000

#define WriteIO(addr,val)     (*(unsigned char*) (addr) = (val))
#define ReadIO(addr)          (*(unsigned char*) (addr))


void digitalWrite(unsigned char pin, bool state) {
    unsigned char read_outputs;
    read_outputs = ReadIO(IO_6502_BaseAddress+1);
    switch (pin) {
    case 1: 
        WriteIO(IO_6502_BaseAddress+1, (read_outputs & 254) | state);
        break;
    case 2:
        WriteIO(IO_6502_BaseAddress+1, (read_outputs & 253) | (state << 1));
        break;
    case 3:
        WriteIO(IO_6502_BaseAddress+1, (read_outputs & 251) | (state << 2));
        break;
    case 4:
        WriteIO(IO_6502_BaseAddress+1, (read_outputs & 247) | (state << 3));
        break;
    case 5:
        WriteIO(IO_6502_BaseAddress+1, (read_outputs & 239) | (state << 4));
        break;
    case 6:
        WriteIO(IO_6502_BaseAddress+1, (read_outputs & 223) | (state << 5));
        break;
    case 7:
        WriteIO(IO_6502_BaseAddress+1, (read_outputs & 191) | (state << 6));
        break;
    case 8:
        WriteIO(IO_6502_BaseAddress+1, (read_outputs & 127) | (state << 7));
        break;
    }
}

unsigned char digitalRead (unsigned char pin) {
    switch (pin) {
    case 1: 
        return (ReadIO(IO_6502_BaseAddress) & 1);
    case 2:
        return (ReadIO(IO_6502_BaseAddress) & 2);
    case 3:
        return (ReadIO(IO_6502_BaseAddress) & 4);
    case 4:
        return (ReadIO(IO_6502_BaseAddress) & 8);
    case 5:
        return (ReadIO(IO_6502_BaseAddress) & 16);
    case 6:
        return (ReadIO(IO_6502_BaseAddress) & 32);
    case 7:
        return (ReadIO(IO_6502_BaseAddress) & 64);
    case 8:
        return (ReadIO(IO_6502_BaseAddress) & 128);
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

void ReadVersion() {
    unsigned long i = Version_String_BaseAddress+0x2A;
    memset(&readversion[0], 0, sizeof(readversion));
    for (i = Version_String_BaseAddress+0x2A; i >= Version_String_BaseAddress; i --) {
        readversion[(Version_String_BaseAddress+0x2A)-i] = (char) ReadIO(i);
    }
    Print(1,readversion);
}

void readFPGA(char addr[6]) {
    char rd_data[3];
    sprintf(rd_data, "%d", ReadIO(atoi(addr)));
    Print(1, rd_data);
}
void writeFPGA(char addr[6], char data[4]) {
    WriteIO(atoi(addr), atoi(data));
}

void executeCommandsSerial(char *data) {
    unsigned char j = 0;
    unsigned char k = 0;
    unsigned char address_done = 0;
    if (strncmp(data, READF, 5) == 0) {
        strncpy(addr_sub, data + 6, (strlen(data)) - 6);
        readFPGA(addr_sub);
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
    } else if (strncmp(data, RVERSION, 14) == 0) {
        ReadVersion();
    }
}

void ReadUART() {
    unsigned char i = 0;
    readuartstatus = ReadIO(UART_6502_BaseAddress+4);
    if (readuartstatus == 0) {
        readuart[char_iter] = (char) ReadIO(UART_6502_BaseAddress+3);
        if (readuart[char_iter] != '\n') {
            char_iter = char_iter + 1;
        } else {
            readuart[char_iter] = (char) 0;
            char_iter = 0;
            executeCommandsSerial(&readuart[0]);
            memset(&readuart[0], 0, sizeof(readuart));
        }
    }
}
