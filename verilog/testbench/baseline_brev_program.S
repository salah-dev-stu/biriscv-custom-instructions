##############################################################################
# BASELINE BREV Test Program (SOFTWARE BIT REVERSAL)
#
# This program reverses bits using the standard software algorithm:
# - Swap 16-bit halves
# - Swap 8-bit bytes within halves
# - Swap 4-bit nibbles within bytes
# - Swap 2-bit pairs within nibbles
# - Swap individual bits within pairs
#
# Requires ~45-50 instructions per reversal
# For performance comparison with BREV custom instruction
##############################################################################

.section .text
.globl _start

_start:
    # Initialize stack pointer
    lui sp, 0x80010          # SP = 0x80010000

    # Test bit reversal on multiple values
    jal ra, test_bit_reverse_software

    # Finish - write to CSR to signal completion
    li a0, 0x12345678        # Success marker
    csrw 0x7C1, a0

_done:
    j _done                   # Infinite loop


##############################################################################
# Software Bit Reverse Function
# Input: a0 = 32-bit value to reverse
# Output: a0 = bit-reversed result
# Uses standard divide-and-conquer algorithm (5 stages)
##############################################################################
reverse_bits_software:
    # Save registers
    addi sp, sp, -20
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw t3, 12(sp)
    sw t4, 16(sp)

    mv t0, a0                # Working value

    # Stage 1: Swap 16-bit halves
    # result = ((value >> 16) & 0xFFFF) | ((value & 0xFFFF) << 16)
    srli t1, t0, 16          # t1 = value >> 16
    lui t2, 0xFFFF           # t2 = 0xFFFF0000
    addi t2, t2, -1          # t2 = 0x0000FFFF
    and t1, t1, t2           # t1 = (value >> 16) & 0xFFFF
    and t3, t0, t2           # t3 = value & 0xFFFF
    slli t3, t3, 16          # t3 = (value & 0xFFFF) << 16
    or t0, t1, t3            # t0 = result of stage 1

    # Stage 2: Swap 8-bit bytes within each 16-bit half
    # result = ((value >> 8) & 0x00FF00FF) | ((value & 0x00FF00FF) << 8)
    srli t1, t0, 8           # t1 = value >> 8
    lui t2, 0x00FF0          # t2 = 0x00FF0000
    addi t2, t2, 0xFF        # t2 = 0x00FF00FF
    and t1, t1, t2           # t1 = (value >> 8) & 0x00FF00FF
    and t3, t0, t2           # t3 = value & 0x00FF00FF
    slli t3, t3, 8           # t3 = (value & 0x00FF00FF) << 8
    or t0, t1, t3            # t0 = result of stage 2

    # Stage 3: Swap 4-bit nibbles within each byte
    # result = ((value >> 4) & 0x0F0F0F0F) | ((value & 0x0F0F0F0F) << 4)
    srli t1, t0, 4           # t1 = value >> 4
    lui t2, 0x0F0F0          # t2 = 0x0F0F0000
    addi t3, x0, 0x0F0       # t3 = 0x0F0
    slli t3, t3, 4           # t3 = 0x0F00
    addi t3, t3, 0x0F        # t3 = 0x0F0F
    or t2, t2, t3            # t2 = 0x0F0F0F0F
    and t1, t1, t2           # t1 = (value >> 4) & 0x0F0F0F0F
    and t3, t0, t2           # t3 = value & 0x0F0F0F0F
    slli t3, t3, 4           # t3 = (value & 0x0F0F0F0F) << 4
    or t0, t1, t3            # t0 = result of stage 3

    # Stage 4: Swap 2-bit pairs within each nibble
    # result = ((value >> 2) & 0x33333333) | ((value & 0x33333333) << 2)
    srli t1, t0, 2           # t1 = value >> 2
    lui t2, 0x33333          # t2 = 0x33333000
    addi t3, x0, 0x333       # t3 = 0x333
    or t2, t2, t3            # t2 = 0x33333333
    and t1, t1, t2           # t1 = (value >> 2) & 0x33333333
    and t3, t0, t2           # t3 = value & 0x33333333
    slli t3, t3, 2           # t3 = (value & 0x33333333) << 2
    or t0, t1, t3            # t0 = result of stage 4

    # Stage 5: Swap individual bits within each pair
    # result = ((value >> 1) & 0x55555555) | ((value & 0x55555555) << 1)
    srli t1, t0, 1           # t1 = value >> 1
    lui t2, 0x55555          # t2 = 0x55555000
    addi t3, x0, 0x555       # t3 = 0x555
    or t2, t2, t3            # t2 = 0x55555555
    and t1, t1, t2           # t1 = (value >> 1) & 0x55555555
    and t3, t0, t2           # t3 = value & 0x55555555
    slli t3, t3, 1           # t3 = (value & 0x55555555) << 1
    or t0, t1, t3            # t0 = result of stage 5

    mv a0, t0                # Return result

    # Restore registers
    lw t4, 16(sp)
    lw t3, 12(sp)
    lw t2, 8(sp)
    lw t1, 4(sp)
    lw t0, 0(sp)
    addi sp, sp, 20
    ret


##############################################################################
# Test: Reverse multiple values using software algorithm
##############################################################################
test_bit_reverse_software:
    addi sp, sp, -12
    sw ra, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    # Result storage base address
    lui s2, 0x80009

    # Test 1: 0x00000000
    li a0, 0x00000000
    jal ra, reverse_bits_software
    sw a0, 0(s2)

    # Test 2: 0xFFFFFFFF
    li a0, -1                # 0xFFFFFFFF
    jal ra, reverse_bits_software
    sw a0, 4(s2)

    # Test 3: 0x55555555 (alternating 01...)
    lui a0, 0x55555
    addi a0, a0, 0x555
    jal ra, reverse_bits_software
    sw a0, 8(s2)

    # Test 4: 0xAAAAAAAA (alternating 10...)
    lui a0, 0xAAAAB
    addi a0, a0, -0x556      # 0xAAAAB000 - 0x556 = 0xAAAAAAAA
    jal ra, reverse_bits_software
    sw a0, 12(s2)

    # Test 5: 0x0000000F
    li a0, 0x0F
    jal ra, reverse_bits_software
    sw a0, 16(s2)

    # Test 6: 0xF0000000
    lui a0, 0xF0000
    jal ra, reverse_bits_software
    sw a0, 20(s2)

    # Test 7: 0x00000001 (LSB set)
    li a0, 0x01
    jal ra, reverse_bits_software
    sw a0, 24(s2)

    # Test 8: 0x80000000 (MSB set)
    lui a0, 0x80000
    jal ra, reverse_bits_software
    sw a0, 28(s2)

    # Test 9: 0x12345678
    lui a0, 0x12345
    addi a0, a0, 0x678
    jal ra, reverse_bits_software
    sw a0, 32(s2)

    # Test 10: 0xDEADBEEF
    lui a0, 0xDEADC
    addi a0, a0, -0x111       # 0xDEADC000 - 0x111 = 0xDEADBEEF
    jal ra, reverse_bits_software
    sw a0, 36(s2)

    # Add completion marker
    li a0, 0xC0FFEE00        # Marker for baseline completion
    sw a0, 40(s2)

    lw s2, 0(sp)
    lw s1, 4(sp)
    lw ra, 8(sp)
    addi sp, sp, 12
    ret
