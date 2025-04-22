#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdbool.h>

#ifndef RV32
    #include <6502.h>
    #include <peekpoke.h>
    #define ADDR_WORD 1

    #ifndef LLVM
        #define STACK_SIZE 512  // vary this depending how busy your IRQ method is
        unsigned char TempStack[STACK_SIZE];
    #else
        #define INTERRUPT_VECTOR_TABLE_BASE 0xFFFE

        void __putchar(char c) {

        }

        //void __attribute__((interrupt)) IRQ(void);

        //void setup_interrupt_vector() {
        //    // Set the address of the IRQ function in the interrupt vector table
        //    *((void (**)(void))INTERRUPT_VECTOR_TABLE_BASE) = IRQ;
        //}
    #endif

#else
    #define ADDR_WORD 4
#endif