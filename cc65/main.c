#include "fpga_6502.h"
#include "io.c"
#include "ethernet.c"

unsigned char irq_clear = 0;
unsigned char dest_ip[4] = {192,168,1,137};
//unsigned char dest_ip_broadcast[4] = {255,255,255,255};

void loop() {
    while (1) {
        ReadUART();
        EthRecvUDP(0);
        //WriteIO(IO_6502_BaseAddress+1, 1);
        //Sleep(5000); 
        //WriteIO(IO_6502_BaseAddress+1,0);
        //Sleep(5000);
    }
}

unsigned char IRQ () {
    char irq_clear_char[3];
    char int_str[] = "Interrupt Occured on line: ";
    //WriteIO(IO_6502_BaseAddress+2,0);
    irq_clear = ReadIO(IO_6502_BaseAddress+3);
    sprintf(irq_clear_char, "%d", irq_clear);
    strcat(int_str, irq_clear_char);
    Print(1,int_str);
    return IRQ_NOT_HANDLED;
}

void main () {
    SEI();
    set_irq(IRQ, TempStack, STACK_SIZE);
    CLI();
    WriteIO(IO_6502_BaseAddress+2, 1); //Set Interrupt Mask to Bit 0
    EthInitialize(0);
    OpenEthUDPSocket(0, 1200, 1200, dest_ip);
    loop();
}


