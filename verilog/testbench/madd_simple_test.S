# Simple MADD Test - Just one instruction
.section .text
.globl _start

_start:
    # Test 1: Basic MADD - (10 × 20) + 5 = 205
    li x1, 10
    li x2, 20
    li x3, 5

    # madd x10, x1, x2, x3
    .word 0x1A20857B

    # Store result to memory
    li x31, 0x80000000
    sw x10, 0(x31)

    # Exit simulation
    li x30, 0x00000000
    csrw 0x8b2, x30

    # Loop forever
end_loop:
    j end_loop
