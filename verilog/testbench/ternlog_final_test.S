# TERNLOG Comprehensive Test
# 2-source + 8-bit immediate design (third input = 0)

.section .text
.globl _start

_start:
    # Initialize test values
    lui x1, 0xAAAAB
    addi x1, x1, -1366  # x1 = 0xAAAAAAAA
    lui x2, 0xCCCCD
    addi x2, x2, -820   # x2 = 0xCCCCCCCC

    # Test 1: Copy A (rs1)
    # Function: a
    # imm8=0x50, Expected: 0xAAAAAAAA
    .word 0x5420857B  # ternlog x10, x1, x2, 0x50

    # Test 2: Copy B (rs2)
    # Function: b
    # imm8=0x44, Expected: 0xCCCCCCCC
    .word 0x4420C5FB  # ternlog x11, x1, x2, 0x44

    # Test 3: AND
    # Function: a & b
    # imm8=0x40, Expected: 0x88888888
    .word 0x4420867B  # ternlog x12, x1, x2, 0x40

    # Test 4: OR
    # Function: a | b
    # imm8=0x54, Expected: 0xEEEEEEEE
    .word 0x5420C6FB  # ternlog x13, x1, x2, 0x54

    # Test 5: XOR
    # Function: a ^ b
    # imm8=0x14, Expected: 0x66666666
    .word 0x1420C77B  # ternlog x14, x1, x2, 0x14

    # Test 6: NAND
    # Function: ~(a & b)
    # imm8=0x15, Expected: 0x77777777
    .word 0x1420D7FB  # ternlog x15, x1, x2, 0x15

    # Test 7: NOR
    # Function: ~(a | b)
    # imm8=0x01, Expected: 0x11111111
    .word 0x0420987B  # ternlog x16, x1, x2, 0x01

    # Test 8: XNOR
    # Function: ~(a ^ b)
    # imm8=0x41, Expected: 0x99999999
    .word 0x442098FB  # ternlog x17, x1, x2, 0x41

    # Test 9: NOT A
    # Function: ~a
    # imm8=0x05, Expected: 0x55555555
    .word 0x0420D97B  # ternlog x18, x1, x2, 0x05

    # Test 10: NOT B
    # Function: ~b
    # imm8=0x11, Expected: 0x33333333
    .word 0x142099FB  # ternlog x19, x1, x2, 0x11

    # Test 11: A AND NOT B
    # Function: a & ~b
    # imm8=0x10, Expected: 0x22222222
    .word 0x14208A7B  # ternlog x20, x1, x2, 0x10

    # Test 12: B AND NOT A
    # Function: b & ~a
    # imm8=0x04, Expected: 0x44444444
    .word 0x0420CAFB  # ternlog x21, x1, x2, 0x04

    # Test 13: Constant 0
    # Function: 0
    # imm8=0x00, Expected: 0x00000000
    .word 0x04208B7B  # ternlog x22, x1, x2, 0x00

    # Test 14: Constant 1
    # Function: 1
    # imm8=0x55, Expected: 0xFFFFFFFF
    .word 0x5420DBFB  # ternlog x23, x1, x2, 0x55

    # Test 15: Implies (A->B)
    # Function: ~a | b
    # imm8=0x45, Expected: 0xDDDDDDDD
    .word 0x4420DC7B  # ternlog x24, x1, x2, 0x45

    # Store results to memory (starting at 0x80001000)
    lui x31, 0x80001
    sw x10, 0(x31)  # Test 1
    sw x11, 4(x31)  # Test 2
    sw x12, 8(x31)  # Test 3
    sw x13, 12(x31)  # Test 4
    sw x14, 16(x31)  # Test 5
    sw x15, 20(x31)  # Test 6
    sw x16, 24(x31)  # Test 7
    sw x17, 28(x31)  # Test 8
    sw x18, 32(x31)  # Test 9
    sw x19, 36(x31)  # Test 10
    sw x20, 40(x31)  # Test 11
    sw x21, 44(x31)  # Test 12
    sw x22, 48(x31)  # Test 13
    sw x23, 52(x31)  # Test 14
    sw x24, 56(x31)  # Test 15

    # Exit
    li x30, 0
    csrw 0x8b2, x30

end_loop:
    j end_loop


# Expected results:
# Test 1: Copy A (rs1)         = 0xAAAAAAAA
# Test 2: Copy B (rs2)         = 0xCCCCCCCC
# Test 3: AND                  = 0x88888888
# Test 4: OR                   = 0xEEEEEEEE
# Test 5: XOR                  = 0x66666666
# Test 6: NAND                 = 0x77777777
# Test 7: NOR                  = 0x11111111
# Test 8: XNOR                 = 0x99999999
# Test 9: NOT A                = 0x55555555
# Test 10: NOT B                = 0x33333333
# Test 11: A AND NOT B          = 0x22222222
# Test 12: B AND NOT A          = 0x44444444
# Test 13: Constant 0           = 0x00000000
# Test 14: Constant 1           = 0xFFFFFFFF
# Test 15: Implies (A->B)       = 0xDDDDDDDD
