# TERNLOG Minimal Test - Simplest possible test

.section .text
.globl _start

_start:
    # Load immediate values directly (no pseudo-instructions)
    lui x1, 0xAAAAB      # Load upper 20 bits
    addi x1, x1, -1366   # x1 = 0xAAAAAAAA

    lui x2, 0xCCCCD      # Load upper 20 bits
    addi x2, x2, -820    # x2 = 0xCCCCCCCC

    # Test: imm8=0xF0 - Should copy x1 to x10
    # With third input=0: index = {x1[i], x2[i], 0}
    # imm8[0]=0, imm8[2]=0, imm8[4]=1, imm8[6]=1
    # This implements: out = x1
    .word 0xF420857B  # ternlog x10, x1, x2, 0xF0

    # Store result to memory for inspection
    lui x31, 0x80001
    sw x10, 0(x31)

    # Exit
    li x30, 0
    csrw 0x8b2, x30

end_loop:
    j end_loop
