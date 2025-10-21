# TERNLOG Instruction Test Program
# Tests the custom TERNLOG (Bitwise Ternary Logic) instruction
# Operation: For each bit i: index = {rs1[i], rs2[i], rs3[i]}, rd[i] = imm8[index]
# Encoding (R4-type with split imm): imm8[7:3][31:27], funct2[26:25]=10, rs2[24:20], rs1[19:15], imm8[2:0][14:12], rd[11:7], opcode[6:0]=0x7B

.section .text
.globl _start

_start:
    # Initialize test values in registers
    li x1, 0xAAAAAAAA  # x1 = 10101010... (alternating bits)
    li x2, 0xCCCCCCCC  # x2 = 11001100... (2-bit pattern)
    li x3, 0xF0F0F0F0  # x3 = 11110000... (4-bit pattern)
    li x4, 0xFFFFFFFF  # x4 = all ones
    li x5, 0x00000000  # x5 = all zeros
    li x6, 0x12345678  # x6 = test pattern
    li x7, 0xFEDCBA98  # x7 = inverse test pattern

    # Test 1: TERNLOG with imm8=0xF0 - Copy rs1 (a ? 1 : 0)
    # Truth table: abc | out
    #              000 | 0
    #              001 | 0
    #              010 | 0
    #              011 | 0
    #              100 | 1
    #              101 | 1
    #              110 | 1
    #              111 | 1
    # imm8 = 0b11110000 = 0xF0
    # ternlog x10, x1, x2, x3, 0xF0
    # Expected: x10 = 0xAAAAAAAA (copy of x1)
    .word 0x7820807B   # imm8[7:3]=11110=0x1E@[31:27], funct2=10@[26:25], rs2=x2@[24:20], rs1=x1@[19:15], imm8[2:0]=000=0@[14:12], rd=x10@[11:7], opcode=0x7B

    # Test 2: TERNLOG with imm8=0xCC - Copy rs2 (b ? 1 : 0)
    # Truth table: 0b11001100 = 0xCC
    # ternlog x11, x1, x2, x3, 0xCC
    # Expected: x11 = 0xCCCCCCCC (copy of x2)
    .word 0x662085FB   # imm8[7:3]=11001=0x19@[31:27], funct2=10@[26:25], rs2=x2@[24:20], rs1=x1@[19:15], imm8[2:0]=100=4@[14:12], rd=x11@[11:7], opcode=0x7B

    # Test 3: TERNLOG with imm8=0xAA - Copy rs3 (c ? 1 : 0)
    # Truth table: 0b10101010 = 0xAA
    # ternlog x12, x1, x2, x3, 0xAA
    # Expected: x12 = 0xF0F0F0F0 (copy of x3)
    .word 0x5620867B   # imm8[7:3]=10101=0x15@[31:27], funct2=10@[26:25], rs2=x2@[24:20], rs1=x1@[19:15], imm8[2:0]=010=2@[14:12], rd=x12@[11:7], opcode=0x7B

    # Test 4: TERNLOG with imm8=0xE8 - 3-input AND (a & b & c)
    # Truth table: 0b11101000 = 0xE8
    # ternlog x13, x1, x2, x3, 0xE8
    # x1 = 0xAAAAAAAA = 10101010...
    # x2 = 0xCCCCCCCC = 11001100...
    # x3 = 0xF0F0F0F0 = 11110000...
    # AND result = 10001000... = 0x88888888
    .word 0x742086FB   # imm8[7:3]=11101=0x1D@[31:27], funct2=10@[26:25], rs2=x2@[24:20], rs1=x1@[19:15], imm8[2:0]=000=0@[14:12], rd=x13@[11:7], opcode=0x7B

    # Test 5: TERNLOG with imm8=0xFE - 3-input OR (a | b | c)
    # Truth table: 0b11111110 = 0xFE
    # ternlog x14, x1, x2, x3, 0xFE
    # OR result = 11111110... = 0xFEFEFEFE
    .word 0x7E20877B   # imm8[7:3]=11111=0x1F@[31:27], funct2=10@[26:25], rs2=x2@[24:20], rs1=x1@[19:15], imm8[2:0]=110=6@[14:12], rd=x14@[11:7], opcode=0x7B

    # Test 6: TERNLOG with imm8=0x96 - 3-input XOR (a ^ b ^ c)
    # Truth table: 0b10010110 = 0x96
    # ternlog x15, x1, x2, x3, 0x96
    # XOR result = 10010110... = 0x96969696
    .word 0x4A2087FB   # imm8[7:3]=10010=0x12@[31:27], funct2=10@[26:25], rs2=x2@[24:20], rs1=x1@[19:15], imm8[2:0]=110=6@[14:12], rd=x15@[11:7], opcode=0x7B

    # Test 7: TERNLOG with imm8=0xCA - MUX (c ? a : b)
    # Truth table: 0b11001010 = 0xCA
    # If c=1, select a; if c=0, select b
    # ternlog x16, x1, x2, x3, 0xCA
    # Result should select x1 where x3=1, x2 where x3=0
    # x3 = 0xF0F0F0F0, so upper nibbles from x1, lower nibbles from x2
    # Result = 0xACACACAC
    .word 0x6620887B   # imm8[7:3]=11001=0x19@[31:27], funct2=10@[26:25], rs2=x2@[24:20], rs1=x1@[19:15], imm8[2:0]=010=2@[14:12], rd=x16@[11:7], opcode=0x7B

    # Test 8: TERNLOG with imm8=0x00 - Always zero
    # ternlog x17, x1, x2, x3, 0x00
    # Expected: x17 = 0x00000000
    .word 0x002088FB   # imm8[7:3]=00000=0x00@[31:27], funct2=10@[26:25], rs2=x2@[24:20], rs1=x1@[19:15], imm8[2:0]=000=0@[14:12], rd=x17@[11:7], opcode=0x7B

    # Test 9: TERNLOG with imm8=0xFF - Always ones
    # ternlog x18, x1, x2, x3, 0xFF
    # Expected: x18 = 0xFFFFFFFF
    .word 0x7E20897B   # imm8[7:3]=11111=0x1F@[31:27], funct2=10@[26:25], rs2=x2@[24:20], rs1=x1@[19:15], imm8[2:0]=111=7@[14:12], rd=x18@[11:7], opcode=0x7B

    # Test 10: TERNLOG with all zeros input
    # ternlog x19, x5, x5, x5, 0xAA
    # index = 000 for all bits, so output = imm8[0] = bit 0 of 0xAA = 0
    # Expected: x19 = 0x00000000
    .word 0x542289FB   # imm8[7:3]=10101=0x15@[31:27], funct2=10@[26:25], rs2=x5@[24:20], rs1=x5@[19:15], imm8[2:0]=010=2@[14:12], rd=x19@[11:7], opcode=0x7B

    # Test 11: TERNLOG with all ones input
    # ternlog x20, x4, x4, x4, 0xAA
    # index = 111 for all bits, so output = imm8[7] = bit 7 of 0xAA = 1
    # Expected: x20 = 0xFFFFFFFF
    .word 0x56248A7B   # imm8[7:3]=10101=0x15@[31:27], funct2=10@[26:25], rs2=x4@[24:20], rs1=x4@[19:15], imm8[2:0]=010=2@[14:12], rd=x20@[11:7], opcode=0x7B

    # Test 12: TERNLOG with test pattern - SHA-256 Ch function
    # Ch(e,f,g) = (e & f) ^ (~e & g)
    # Truth table: 0b11011000 = 0xD8
    # ternlog x21, x6, x7, x1, 0xD8
    .word 0x6E338AFB   # imm8[7:3]=11011=0x1B@[31:27], funct2=10@[26:25], rs2=x7@[24:20], rs1=x6@[19:15], imm8[2:0]=000=0@[14:12], rd=x21@[11:7], opcode=0x7B

    # Test 13: Test with different register combinations
    # ternlog x22, x6, x5, x4, 0xF0  (should copy x6 since imm8=0xF0 copies a)
    # Expected: x22 = 0x12345678
    .word 0x78258B7B   # imm8[7:3]=11110=0x1E@[31:27], funct2=10@[26:25], rs2=x5@[24:20], rs1=x6@[19:15], imm8[2:0]=000=0@[14:12], rd=x22@[11:7], opcode=0x7B

    # Test 14: Majority function - (a&b) | (b&c) | (a&c)
    # Truth table: 0b11101000 = 0xE8 (same as 3-input AND for our test values)
    # ternlog x23, x1, x2, x3, 0xE8
    .word 0x742087FB   # imm8[7:3]=11101=0x1D@[31:27], funct2=10@[26:25], rs2=x2@[24:20], rs1=x1@[19:15], imm8[2:0]=000=0@[14:12], rd=x23@[11:7], opcode=0x7B

    # Test 15: NAND operation - ~(a & b & c)
    # Truth table: 0b00010111 = 0x17
    # ternlog x24, x1, x2, x3, 0x17
    .word 0x0E208C7B   # imm8[7:3]=00010=0x02@[31:27], funct2=10@[26:25], rs2=x2@[24:20], rs1=x1@[19:15], imm8[2:0]=111=7@[14:12], rd=x24@[11:7], opcode=0x7B

    # Verification: Store results to memory for inspection
    li x31, 0x80000000  # Base address for result storage
    sw x10, 0(x31)      # Test 1: Copy A (expected: 0xAAAAAAAA)
    sw x11, 4(x31)      # Test 2: Copy B (expected: 0xCCCCCCCC)
    sw x12, 8(x31)      # Test 3: Copy C (expected: 0xF0F0F0F0)
    sw x13, 12(x31)     # Test 4: AND (expected: 0x88888888)
    sw x14, 16(x31)     # Test 5: OR (expected: 0xFEFEFEFE)
    sw x15, 20(x31)     # Test 6: XOR (expected: 0x96969696)
    sw x16, 24(x31)     # Test 7: MUX (expected: 0xACACACAC)
    sw x17, 28(x31)     # Test 8: All zeros (expected: 0x00000000)
    sw x18, 32(x31)     # Test 9: All ones (expected: 0xFFFFFFFF)
    sw x19, 36(x31)     # Test 10: Zero inputs (expected: 0x00000000)
    sw x20, 40(x31)     # Test 11: One inputs (expected: 0xFFFFFFFF)
    sw x21, 44(x31)     # Test 12: SHA-256 Ch
    sw x22, 48(x31)     # Test 13: Copy with different regs (expected: 0x12345678)
    sw x23, 52(x31)     # Test 14: Majority (expected: 0x88888888)
    sw x24, 56(x31)     # Test 15: NAND (expected: 0x77777777)

    # Exit simulation (write to CSR_SIM_CTRL)
    li x30, 0x00000000  # Exit code 0
    csrw 0x8b2, x30     # Write to CSR_SIM_CTRL to exit

    # Loop forever (in case CSR write doesn't exit)
end_loop:
    j end_loop

.section .data
# Expected results for verification:
# Test 1:  0xAAAAAAAA (Copy A)
# Test 2:  0xCCCCCCCC (Copy B)
# Test 3:  0xF0F0F0F0 (Copy C)
# Test 4:  0x88888888 (3-input AND)
# Test 5:  0xFEFEFEFE (3-input OR)
# Test 6:  0x96969696 (3-input XOR)
# Test 7:  0xACACACAC (MUX c?a:b)
# Test 8:  0x00000000 (Always zero)
# Test 9:  0xFFFFFFFF (Always ones)
# Test 10: 0x00000000 (Zero inputs)
# Test 11: 0xFFFFFFFF (One inputs)
# Test 12: (SHA-256 Ch result)
# Test 13: 0x12345678 (Copy different reg)
# Test 14: 0x88888888 (Majority)
# Test 15: 0x77777777 (NAND)
