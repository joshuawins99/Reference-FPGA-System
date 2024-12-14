#include "fpga_6502.h"

unsigned char irq_clear = 0;

void loop() {
    while (1) {
        ReadUART();
    }
}

unsigned char IRQ () {
    irq_clear = ReadIO(0x9003);
    //if ((ReadIO(0x9001) & 2) == 0) {
        digitalWrite(2, 0);
    //}
    //else {
        digitalWrite(2, 1);
        //PrintLn("This is the 6502!");
    //}
    return (IRQ_NOT_HANDLED);
}

int main () {
    //SEI();
    //set_irq(IRQ, TempStack, STACK_SIZE);
    //CLI();
    //WriteIO(0x9002, 1);
    //WriteIO(0x9001, 0);
    //digitalWrite(2, 1);
    loop();
    return(0);
}

