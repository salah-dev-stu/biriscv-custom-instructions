##############################################################################
# CSEL Proof Test - Different Input Data to Prove CSEL Actually Works
##############################################################################

.section .text
.globl _start

_start:
    lui sp, 0x80010          # SP = 0x80010000

    # Test 1: Max/Min with DIFFERENT array
    jal ra, test_array_max_min

    # Finish
    li a0, 0x12345678
    csrw 0x7C1, a0

_done:
    j _done

##############################################################################
# Test 1: Array Maximum/Minimum Finder
# CHANGED ARRAY: [100, 5, -200, 77, 3, -9, 250, -1]
# Expected: Max = 250, Min = -200
##############################################################################
test_array_max_min:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    # Create DIFFERENT array in memory
    lui s0, 0x80008
    li t0, 100           # Changed from 42
    sw t0, 0(s0)
    li t0, 5             # Changed from -17
    sw t0, 4(s0)
    li t0, -200          # Changed from 99
    sw t0, 8(s0)
    li t0, 77            # Changed from -5
    sw t0, 12(s0)
    li t0, 3             # Changed from 63
    sw t0, 16(s0)
    li t0, -9            # Changed from -88
    sw t0, 20(s0)
    li t0, 250           # Changed from 7
    sw t0, 24(s0)
    li t0, -1            # Changed from 0
    sw t0, 28(s0)

    # Initialize max and min
    lw s1, 0(s0)          # max = first element (100)
    lw s2, 0(s0)          # min = first element (100)
    addi s0, s0, 4
    li t6, 7

max_min_loop:
    lw t0, 0(s0)

    # Update maximum using CSEL
    sub t1, t0, s1        # t1 = current - max
    srli t3, t1, 31       # t3 = sign bit
    .word 0xE09284FB      # csel s1, t0, s1, t3

    # Update minimum using CSEL
    sub t2, s2, t0        # t2 = min - current
    srli t4, t2, 31       # t4 = sign bit
    .word 0xE922897B      # csel s2, t0, s2, t4

    addi s0, s0, 4
    addi t6, t6, -1
    bnez t6, max_min_loop

    # Store results
    lui t0, 0x80009
    sw s1, 0(t0)          # Should be 250 (0xFA)
    sw s2, 4(t0)          # Should be -200 (0xFFFFFF38)

    li t1, 0xDEADBEEF
    sw t1, 48(t0)

    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
