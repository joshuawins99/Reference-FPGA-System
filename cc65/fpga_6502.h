#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdbool.h>
#include <6502.h>
#include <peekpoke.h>
#include "io.h"

#define STACK_SIZE 256  // vary this depending how busy your IRQ method is

unsigned char TempStack[STACK_SIZE];