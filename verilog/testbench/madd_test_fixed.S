# MADD Instruction Test Program (Fixed for address 0x00)
# Tests the custom MADD (Multiply-Add) instruction
# Operation: rd = (rs1 × rs2) + rs3 (lower 32 bits of result)

.section .text
.globl _start

_start:
    # Initialize test values in registers
    li x1, 10          # x1 = 10
    li x2, 20          # x2 = 20
    li x3, 5           # x3 = 5
    li x4, 100         # x4 = 100
    li x5, 0           # x5 = 0 (zero accumulator)
    li x6, -1          # x6 = -1 (0xFFFFFFFF)
    li x7, 0x80000000  # x7 = largest negative 32-bit number
    li x8, 0x7FFFFFFF  # x8 = largest positive 32-bit number

    # Test 1: Basic MADD - (10 × 20) + 5 = 205
    .word 0x1A20857B

    # Test 2: MADD with zero accumulator - (10 × 20) + 0 = 200
    .word 0x2A2085FB

    # Test 3: MADD with larger accumulator - (10 × 20) + 100 = 300
    .word 0x2220867B

    # Test 4: MADD with zero multiplicand - (0 × 20) + 5 = 5
    .word 0x1A2286FB

    # Test 5: MADD with zero multiplier - (10 × 0) + 5 = 5
    .word 0x1A50877B

    # Test 6: MADD all zeros - (0 × 0) + 0 = 0
    .word 0x2A5287FB

    # Test 7: MADD with negative accumulator - (10 × 20) + (-1) = 199
    .word 0x3220887B

    # Test 8: MADD with same source registers - (10 × 10) + 10 = 110
    .word 0x0A1088FB

    # Test 9: MADD with overflow
    li x9, 2
    .word 0x1A90897B

    # Test 10: MADD with negative numbers - (-1) × 10 + 5 = -5
    .word 0x1A1309FB

    # Test 11: MADD producing negative result - 10 × 20 + (-300) = -100
    li x21, -300
    .word 0xAA20AA7B

    # Test 12: Chain MADD operations
    .word 0x2A31AB7B   # (5 × 5) + 0 = 25
    .word 0xB231ABFB   # (5 × 5) + 25 = 50

    # Verification: Store results to memory
    li x31, 0x80000000
    sw x10, 0(x31)
    sw x11, 4(x31)
    sw x12, 8(x31)
    sw x13, 12(x31)
    sw x14, 16(x31)
    sw x15, 20(x31)
    sw x16, 24(x31)
    sw x17, 28(x31)
    sw x18, 32(x31)
    sw x19, 36(x31)
    sw x20, 40(x31)
    sw x22, 44(x31)
    sw x23, 48(x31)

    # Exit simulation
    li x30, 0x00000000
    csrw 0x8b2, x30

end_loop:
    j end_loop
