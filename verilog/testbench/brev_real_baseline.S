##############################################################################
# Real-World BREV Baseline Program (SOFTWARE BIT REVERSAL)
#
# Application: Network Packet Processing with CRC and Endianness Conversion
#
# This program simulates real-world bit reversal operations:
# 1. CRC-32 calculation with bit reflection
# 2. Endian conversion for network protocols
# 3. Binary data manipulation for encoding
# 4. Checksum validation with bit-reversed keys
#
# Uses software bit-by-bit reversal (slow but correct)
##############################################################################

.section .text
.globl _start

_start:
    # Initialize stack pointer
    lui sp, 0x80010          # SP = 0x80010000

    # Run real-world bit reversal tasks
    jal ra, process_network_packets

    # Signal completion
    li a0, 0x12345678
    csrw 0x7C1, a0

_done:
    j _done


##############################################################################
# Software Bit Reverse Function (Loop-based)
# Input: a0 = 32-bit value to reverse
# Output: a0 = bit-reversed result
##############################################################################
reverse_bits_software:
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw t3, 12(sp)

    mv t0, a0                # t0 = input value
    li t1, 0                 # t1 = result (accumulator)
    li t2, 32                # t2 = bit counter

reverse_loop:
    slli t1, t1, 1           # Shift result left
    andi t3, t0, 1           # Get LSB of input
    or t1, t1, t3            # OR LSB into result
    srli t0, t0, 1           # Shift input right
    addi t2, t2, -1          # Decrement counter
    bnez t2, reverse_loop    # Continue if counter > 0

    mv a0, t1                # Return result

    lw t3, 12(sp)
    lw t2, 8(sp)
    lw t1, 4(sp)
    lw t0, 0(sp)
    addi sp, sp, 16
    ret


##############################################################################
# CRC-32 Reflect Function
# Used in CRC calculations - reflects bits for proper polynomial evaluation
# Input: a0 = data word
# Output: a0 = reflected data
##############################################################################
crc32_reflect:
    addi sp, sp, -4
    sw ra, 0(sp)

    jal ra, reverse_bits_software

    lw ra, 0(sp)
    addi sp, sp, 4
    ret


##############################################################################
# Endian Swap with Bit Reversal
# Converts between big-endian and little-endian with bit-level granularity
# Input: a0 = 32-bit value
# Output: a0 = converted value
##############################################################################
endian_swap_bitwise:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Reverse all bits
    jal ra, reverse_bits_software

    lw ra, 0(sp)
    addi sp, sp, 4
    ret


##############################################################################
# Hash Function with Bit Reversal
# Simple hash that uses bit reversal as part of mixing
# Input: a0 = input data
# Output: a0 = hash value
##############################################################################
hash_with_reversal:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw s0, 0(sp)

    mv s0, a0                # Save original

    # Step 1: Reverse bits
    jal ra, reverse_bits_software

    # Step 2: XOR with original
    xor a0, a0, s0

    # Step 3: Rotate and reverse again
    slli t0, a0, 13
    srli t1, a0, 19
    or a0, t0, t1
    jal ra, reverse_bits_software

    lw s0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret


##############################################################################
# Main Application: Network Packet Processing
# Simulates processing 20 network packets with various bit operations
##############################################################################
process_network_packets:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    # Result storage base
    lui s2, 0x80009
    li s1, 0                 # Result index

    # Simulate 20 network packets with different operations

    # Packet 1-5: CRC reflection for polynomial evaluation
    li a0, 0x12345678
    jal ra, crc32_reflect
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0xABCDEF00
    jal ra, crc32_reflect
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0x55AA55AA
    jal ra, crc32_reflect
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0xFFFFFFFF
    jal ra, crc32_reflect
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0x00000001
    jal ra, crc32_reflect
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    # Packet 6-10: Endian conversion for protocol headers
    lui a0, 0xDEADC
    addi a0, a0, -0x111     # DEADC000 - 111 = DEADBEEF
    jal ra, endian_swap_bitwise
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0xCAFEBABE
    jal ra, endian_swap_bitwise
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0x13579BDF
    jal ra, endian_swap_bitwise
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0x2468ACE0
    jal ra, endian_swap_bitwise
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0xF0F0F0F0
    jal ra, endian_swap_bitwise
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    # Packet 11-20: Hash computation for authentication
    li a0, 0x11111111
    jal ra, hash_with_reversal
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0x22222222
    jal ra, hash_with_reversal
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0x33333333
    jal ra, hash_with_reversal
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0x44444444
    jal ra, hash_with_reversal
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0x55555555
    jal ra, hash_with_reversal
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0x66666666
    jal ra, hash_with_reversal
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0x77777777
    jal ra, hash_with_reversal
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0x88888888
    jal ra, hash_with_reversal
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0x99999999
    jal ra, hash_with_reversal
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    li a0, 0xAAAAAAAA
    jal ra, hash_with_reversal
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)
    addi s1, s1, 1

    # Store completion marker
    lui a0, 0xD0000
    addi a0, a0, 0x0E
    slli t0, s1, 2
    add t0, t0, s2
    sw a0, 0(t0)

    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
