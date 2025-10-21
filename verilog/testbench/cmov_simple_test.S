# Simple CMOV test - minimal test case
.section .text
.globl _start

_start:
    # Initialize values
    li x1, 0x1111      # x1 = 0x1111
    li x2, 0x2222      # x2 = 0x2222
    li x3, 0           # x3 = 0 (condition)

    # Single CMOV test
    # cmov x10, x1, x2, x3
    # Expected: x10 = 0x2222 (because x3 == 0, selects rs2)
    .word 0x1E20957B

    # Store result (use address after program code - 0x80001000)
    li x20, 0x80001000
    sw x10, 0(x20)

    # Success marker
    li x21, 0xC0DE000D
    sw x21, 4(x20)

    # Exit (use CSR 0x7C1 which doesn't cause immediate $finish)
    li x17, 0x00000000
    csrw 0x7C1, x17

end_loop:
    j end_loop
