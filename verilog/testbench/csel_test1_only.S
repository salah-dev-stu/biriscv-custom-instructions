##############################################################################
# CSEL Test - Test 1 Only (Array Max/Min)
##############################################################################

.section .text
.globl _start

_start:
    # Initialize stack pointer
    lui sp, 0x80010          # SP = 0x80010000

    # Test 1: Array max/min finder using CSEL
    jal ra, test_array_max_min

    # Finish - write to CSR to signal completion
    li a0, 0x12345678        # Success marker
    csrw 0x7C1, a0

_done:
    j _done                   # Infinite loop


##############################################################################
# Test 1: Array Maximum/Minimum Finder
# Uses CSEL to avoid branches in tight loop
##############################################################################
test_array_max_min:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    # Create array in memory
    lui s0, 0x80008          # Array base address
    li t0, 42
    sw t0, 0(s0)
    li t0, -17
    sw t0, 4(s0)
    li t0, 99
    sw t0, 8(s0)
    li t0, -5
    sw t0, 12(s0)
    li t0, 63
    sw t0, 16(s0)
    li t0, -88
    sw t0, 20(s0)
    li t0, 7
    sw t0, 24(s0)
    li t0, 0              # Sentinel
    sw t0, 28(s0)

    # Initialize max and min
    lw s1, 0(s0)          # max = first element
    lw s2, 0(s0)          # min = first element
    addi s0, s0, 4        # Move to next element
    li t6, 7              # Counter for remaining elements

max_min_loop:
    lw t0, 0(s0)          # Load current element

    # Update maximum using CSEL
    sub t1, t0, s1        # t1 = current - max
    srli t3, t1, 31       # t3 = sign bit (1 if negative, 0 if positive/zero)
    # csel s1, t0, s1, t3   # s1 = (t3 == 0) ? t0 : s1
    .word 0xE09284FB      # Encoding: rs3=t3(x28), rs2=s1(x9), rs1=t0(x5), rd=s1(x9)

    # Update minimum using CSEL
    sub t2, s2, t0        # t2 = min - current
    srli t4, t2, 31       # t4 = sign bit (1 if negative, 0 if positive/zero)
    # csel s2, t0, s2, t4   # s2 = (t4 == 0) ? t0 : s2
    .word 0xE922897B      # Encoding: rs3=t4(x29), rs2=s2(x18), rs1=t0(x5), rd=s2(x18)

    addi s0, s0, 4        # Next element
    addi t6, t6, -1       # Decrement counter
    bnez t6, max_min_loop # Continue loop

    # Store results (max in 0x80009000, min in 0x80009004)
    lui t0, 0x80009
    sw s1, 0(t0)          # Store max (should be 99)
    sw s2, 4(t0)          # Store min (should be -88)

    # Also store completion marker
    li t1, 0xDEADBEEF
    sw t1, 48(t0)

    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
