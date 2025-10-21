# Super simple test - just ADD and exit
.section .text
.globl _start

_start:
    # Simple ADD
    li x1, 10
    li x2, 20
    add x10, x1, x2  # x10 = 30

    # Store result (use address after program code)
    li x20, 0x80001000
    sw x10, 0(x20)

    # Success marker
    li x21, 0xC0DE000D
    sw x21, 4(x20)

    # Exit (use same CSR as TERNLOG test)
    li x30, 0
    csrw 0x7C1, x30

end_loop:
    j end_loop
