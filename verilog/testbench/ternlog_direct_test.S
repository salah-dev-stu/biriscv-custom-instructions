# TERNLOG Direct Register Test
# Test TERNLOG outputs directly in registers (no memory stores)

.section .text
.globl _start

_start:
    # Initialize test values
    li x1, 0xAAAAAAAA  # x1 = 10101010...
    li x2, 0xCCCCCCCC  # x2 = 11001100...

    # Test 1: imm8=0xF0 - Copy A (should copy x1 to x10)
    .word 0xF420857B  # ternlog x10, x1, x2, 0xF0

    # Test 2: imm8=0xCC - Copy B (should copy x2 to x11)
    .word 0xCC20C5FB  # ternlog x11, x1, x2, 0xCC

    # Test 3: imm8=0x88 - AND (should compute x1 AND x2 to x12)
    .word 0x8C2086FB  # ternlog x12, x1, x2, 0x88

    # Now registers x10, x11, x12 should contain the results
    # We can check them directly in the testbench

    # Exit
    li x30, 0
    csrw 0x8b2, x30

end_loop:
    j end_loop
