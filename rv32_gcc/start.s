    .section .text.startup
    .global _start

_start:
    # Initialize the stack pointer
    la sp, __stack_top       # Load the top of the stack into sp

    # Zero out the .bss section
    la t0, _bss_start        # Start address of .bss
    la t1, _bss_end          # End address of .bss
zero_bss:
    bge t0, t1, jump_main    # Exit loop when t0 >= t1
    sw zero, 0(t0)           # Store 0 to the current memory location
    addi t0, t0, 4           # Move to the next word
    j zero_bss               # Repeat the loop

    # Jump to main function
jump_main:
    la a0, main              # Load address of main
    #jalr zero, a0            # Jump to main (no return)
    jalr ra, a0              # Jump to main, save return address in ra
    j halt                   # Redirect to halt after main returns

    # Halt the processor (in case main returns)
halt:
    j halt                   # Infinite loop
