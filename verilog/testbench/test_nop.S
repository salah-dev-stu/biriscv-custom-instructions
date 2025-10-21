# Test NOPs - No MADD
.section .text
.globl _start

_start:
    li x10, 0x12345678
    li x31, 0x80000000
    sw x10, 0(x31)

    # Exit simulation
    li x30, 0x00000000
    csrw 0x8b2, x30

end_loop:
    j end_loop
