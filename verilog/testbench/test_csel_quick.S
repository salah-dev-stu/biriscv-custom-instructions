# Quick CSEL test to verify testbench
.section .text
.globl _start

_start:
    # Initialize values
    li x1, 0x1111
    li x2, 0x2222
    li x3, 0

    # CSEL: rd = (rs3 == 0) ? rs1 : rs2
    # csel x10, x1, x2, x3
    # funct2=00, funct3=000
    # Expected: x10 = 0x1111
    .word 0x1820857B

    # Store result
    li x20, 0x80000000
    sw x10, 0(x20)

    # Success marker
    li x21, 0xC0DE000D
    sw x21, 4(x20)

    # Exit
    li x17, 0
    csrw 0x8b2, x17

end_loop:
    j end_loop
