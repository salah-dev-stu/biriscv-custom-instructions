# MADD Instruction Test Program
# Tests the custom MADD (Multiply-Add) instruction
# Operation: rd = (rs1 × rs2) + rs3 (lower 32 bits of result)
# Encoding (R4-type): rs3[31:27], funct2[26:25]=01, rs2[24:20], rs1[19:15], funct3[14:12]=000, rd[11:7], opcode[6:0]=0x7B

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
    # madd x10, x1, x2, x3
    # Expected: x10 = 205 (0x000000CD)
    .word 0x1A20857B   # rs3=x3(5), funct2=01, rs2=x2(20), rs1=x1(10), funct3=000, rd=x10, opcode=0x7B

    # Test 2: MADD with zero accumulator - (10 × 20) + 0 = 200
    # madd x11, x1, x2, x5
    # Expected: x11 = 200 (0x000000C8)
    .word 0x2A2085FB   # rs3=x5(0), funct2=01, rs2=x2(20), rs1=x1(10), funct3=000, rd=x11, opcode=0x7B

    # Test 3: MADD with larger accumulator - (10 × 20) + 100 = 300
    # madd x12, x1, x2, x4
    # Expected: x12 = 300 (0x0000012C)
    .word 0x2220867B   # rs3=x4(100), funct2=01, rs2=x2(20), rs1=x1(10), funct3=000, rd=x12, opcode=0x7B

    # Test 4: MADD with zero multiplicand - (0 × 20) + 5 = 5
    # madd x13, x5, x2, x3
    # Expected: x13 = 5 (0x00000005)
    .word 0x1A2286FB   # rs3=x3(5), funct2=01, rs2=x2(20), rs1=x5(0), funct3=000, rd=x13, opcode=0x7B

    # Test 5: MADD with zero multiplier - (10 × 0) + 5 = 5
    # madd x14, x1, x5, x3
    # Expected: x14 = 5 (0x00000005)
    .word 0x1A50877B   # rs3=x3(5), funct2=01, rs2=x5(0), rs1=x1(10), funct3=000, rd=x14, opcode=0x7B

    # Test 6: MADD all zeros - (0 × 0) + 0 = 0
    # madd x15, x5, x5, x5
    # Expected: x15 = 0 (0x00000000)
    .word 0x2A5287FB   # rs3=x5(0), funct2=01, rs2=x5(0), rs1=x5(0), funct3=000, rd=x15, opcode=0x7B

    # Test 7: MADD with negative accumulator - (10 × 20) + (-1) = 199
    # madd x16, x1, x2, x6
    # Expected: x16 = 199 (0x000000C7)
    .word 0x3220887B   # rs3=x6(-1), funct2=01, rs2=x2(20), rs1=x1(10), funct3=000, rd=x16, opcode=0x7B

    # Test 8: MADD with same source registers - (10 × 10) + 10 = 110
    # madd x17, x1, x1, x1
    # Expected: x17 = 110 (0x0000006E)
    .word 0x0A1088FB   # rs3=x1(10), funct2=01, rs2=x1(10), rs1=x1(10), funct3=000, rd=x17, opcode=0x7B

    # Test 9: MADD with overflow (test lower 32 bits)
    # Large multiplication: 0x7FFFFFFF × 2 + 5 = 0xFFFFFFFE + 5 = 0x100000003
    # Expected: x18 = 0x00000003 (only lower 32 bits)
    li x9, 2
    .word 0x1A94097B   # rs3=x3(5), funct2=01, rs2=x9(2), rs1=x8(0x7FFFFFFF), funct3=000, rd=x18, opcode=0x7B

    # Test 10: MADD with negative numbers
    # (-1) × 10 + 5 = -10 + 5 = -5 (0xFFFFFFFB in two's complement)
    # Expected: x19 = 0xFFFFFFFB
    .word 0x1A1309FB   # rs3=x3(5), funct2=01, rs2=x1(10), rs1=x6(-1), funct3=000, rd=x19, opcode=0x7B

    # Test 11: MADD producing negative result
    # 10 × 20 + (-300) = 200 - 300 = -100
    # Expected: x20 = 0xFFFFFF9C (-100 in two's complement)
    li x21, -300
    .word 0xAA208A7B   # rs3=x21(-300), funct2=01, rs2=x2(20), rs1=x1(10), funct3=000, rd=x20, opcode=0x7B

    # Test 12: Chain MADD operations
    # First: (5 × 5) + 0 = 25
    # madd x22, x3, x3, x5
    .word 0x2A318B7B   # rs3=x5(0), funct2=01, rs2=x3(5), rs1=x3(5), funct3=000, rd=x22, opcode=0x7B

    # Second: Use result of first as accumulator: (5 × 5) + 25 = 50
    # madd x23, x3, x3, x22
    .word 0xB2318BFB   # rs3=x22(25), funct2=01, rs2=x3(5), rs1=x3(5), funct3=000, rd=x23, opcode=0x7B

    # Verification: Store results to memory for inspection
    li x31, 0x80000000  # Base address for result storage
    sw x10, 0(x31)      # Store test 1 result (expected: 205)
    sw x11, 4(x31)      # Store test 2 result (expected: 200)
    sw x12, 8(x31)      # Store test 3 result (expected: 300)
    sw x13, 12(x31)     # Store test 4 result (expected: 5)
    sw x14, 16(x31)     # Store test 5 result (expected: 5)
    sw x15, 20(x31)     # Store test 6 result (expected: 0)
    sw x16, 24(x31)     # Store test 7 result (expected: 199)
    sw x17, 28(x31)     # Store test 8 result (expected: 110)
    sw x18, 32(x31)     # Store test 9 result (expected: 3)
    sw x19, 36(x31)     # Store test 10 result (expected: 0xFFFFFFFB)
    sw x20, 40(x31)     # Store test 11 result (expected: 0xFFFFFF9C)
    sw x22, 44(x31)     # Store test 12a result (expected: 25)
    sw x23, 48(x31)     # Store test 12b result (expected: 50)

    # Exit simulation (write to CSR_SIM_CTRL)
    li x30, 0x00000000  # Exit code 0
    csrw 0x8b2, x30     # Write to CSR_SIM_CTRL to exit

    # Loop forever (in case CSR write doesn't exit)
end_loop:
    j end_loop

.section .data
# Expected results for verification:
# Test 1:  205 (0x000000CD)
# Test 2:  200 (0x000000C8)
# Test 3:  300 (0x0000012C)
# Test 4:  5   (0x00000005)
# Test 5:  5   (0x00000005)
# Test 6:  0   (0x00000000)
# Test 7:  199 (0x000000C7)
# Test 8:  110 (0x0000006E)
# Test 9:  3   (0x00000003)
# Test 10: -5  (0xFFFFFFFB)
# Test 11: -100 (0xFFFFFF9C)
# Test 12a: 25  (0x00000019)
# Test 12b: 50  (0x00000032)
