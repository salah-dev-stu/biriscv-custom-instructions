# BREV (Bit Reverse) Functional Test Program
# Tests the BREV custom instruction with various input patterns

.section .text
.globl _start

_start:
    # Test 1: All zeros
    # Input: 0x00000000
    # Expected: 0x00000000 (reversed zeros are still zeros)
    li x5, 0x00000000
    .word 0x2002C57B        # brev x10, x5

    # Test 2: All ones
    # Input: 0xFFFFFFFF
    # Expected: 0xFFFFFFFF (reversed ones are still ones)
    li x6, 0xFFFFFFFF
    .word 0x200345FB        # brev x11, x6

    # Test 3: Alternating pattern (0x55555555 = 01010101...)
    # Input: 0x55555555
    # Expected: 0xAAAAAAAA (reversed = 10101010...)
    li x7, 0x55555555
    .word 0x2003C67B        # brev x12, x7

    # Test 4: Opposite alternating pattern (0xAAAAAAAA = 10101010...)
    # Input: 0xAAAAAAAA
    # Expected: 0x55555555 (reversed = 01010101...)
    li x8, 0xAAAAAAAA
    .word 0x200446FB        # brev x13, x8

    # Test 5: Low nibble set (0x0000000F)
    # Input: 0x0000000F = 00000000_00000000_00000000_00001111
    # Expected: 0xF0000000 = 11110000_00000000_00000000_00000000
    li x9, 0x0000000F
    .word 0x2004C77B        # brev x14, x9

    # Test 6: High nibble set (0xF0000000)
    # Input: 0xF0000000 = 11110000_00000000_00000000_00000000
    # Expected: 0x0000000F = 00000000_00000000_00000000_00001111
    li x15, 0xF0000000
    .word 0x2007C87B        # brev x16, x15

    # Test 7: Single bit set (LSB: 0x00000001)
    # Input: 0x00000001 = 00000000_00000000_00000000_00000001
    # Expected: 0x80000000 = 10000000_00000000_00000000_00000000
    li x17, 0x00000001
    .word 0x2008C97B        # brev x18, x17

    # Test 8: Single bit set (MSB: 0x80000000)
    # Input: 0x80000000 = 10000000_00000000_00000000_00000000
    # Expected: 0x00000001 = 00000000_00000000_00000000_00000001
    li x19, 0x80000000
    .word 0x2009CA7B        # brev x20, x19

    # Test 9: Pattern 0x12345678
    # Input: 0x12345678 = 00010010_00110100_01010110_01111000
    # Expected: 0x1E6A2C48 = 00011110_01101010_00101100_01001000
    lui x21, 0x12345
    addi x21, x21, 0x678
    .word 0x200ACB7B        # brev x22, x21

    # Test 10: Pattern 0xDEADBEEF
    # Input: 0xDEADBEEF = 11011110_10101101_10111110_11101111
    # Expected: 0xF77DB57B = 11110111_01111101_10110101_01111011
    li x23, 0xDEADBEEF
    .word 0x200BCC7B        # brev x24, x23

    # Store all results to memory for verification
    lui x25, 0x80000      # Base address 0x80000000
    sw x10, 0(x25)        # Test 1 result
    sw x11, 4(x25)        # Test 2 result
    sw x12, 8(x25)        # Test 3 result
    sw x13, 12(x25)       # Test 4 result
    sw x14, 16(x25)       # Test 5 result
    sw x16, 20(x25)       # Test 6 result
    sw x18, 24(x25)       # Test 7 result
    sw x20, 28(x25)       # Test 8 result
    sw x22, 32(x25)       # Test 9 result
    sw x24, 36(x25)       # Test 10 result

    # Exit simulation
    li x17, 0x00000000
    csrw 0x8b2, x17

    # Infinite loop (should not reach here)
loop:
    j loop
