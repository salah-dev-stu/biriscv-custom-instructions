##############################################################################
# BASELINE BREV Test Program (SOFTWARE BIT REVERSAL) - FIXED VERSION
#
# This program reverses bits using loop-based bit-by-bit reversal
# Simple and guaranteed correct
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
# Software Bit Reverse Function - Simple bit-by-bit method
# Input: a0 = 32-bit value to reverse
# Output: a0 = bit-reversed result
##############################################################################
reverse_bits_software:
    # Save registers
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw t3, 12(sp)

    mv t0, a0                # t0 = input value
    li t1, 0                 # t1 = result (accumulator)
    li t2, 32                # t2 = bit counter

reverse_loop:
    # Shift result left by 1
    slli t1, t1, 1

    # Get LSB of input
    andi t3, t0, 1

    # OR LSB into result
    or t1, t1, t3

    # Shift input right by 1
    srli t0, t0, 1

    # Decrement counter
    addi t2, t2, -1

    # Continue if counter > 0
    bnez t2, reverse_loop

    mv a0, t1                # Return result

    # Restore registers
    lw t3, 12(sp)
    lw t2, 8(sp)
    lw t1, 4(sp)
    lw t0, 0(sp)
    addi sp, sp, 16
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
