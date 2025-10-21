##############################################################################
# BREV Comprehensive Sanity Check
#
# Tests BREV with challenging real-world scenarios:
# 1. Branch-based conditional bit reversal
# 2. BREV combined with shifts and rotations
# 3. BREV in loops with counters
# 4. BREV with arithmetic operations
# 5. Edge cases and corner cases
# 6. Double reversal (should give original value)
#
# All results are compared and branches are taken based on BREV output
##############################################################################

.section .text
.globl _start

_start:
    # Initialize stack pointer and counters
    lui sp, 0x80010          # SP = 0x80010000
    lui s10, 0x80009         # s10 = result storage base
    li s11, 0                # s11 = test counter
    li t6, 0                 # t6 = pass counter

    ##########################################################################
    # Test 1: Basic sanity - 0x12345678 with branch verification
    # Expected: 0x1E6A2C48
    ##########################################################################
    li a0, 0x12345678
    .word 0x2005457B         # brev a0, a0
    lui a1, 0x1E6A3
    addi a1, a1, -0x3B8      # a1 = 0x1E6A2C48 (expected)

    # Branch based on result
    beq a0, a1, test1_pass
    li a2, 0xBAD00001        # FAIL marker
    j test1_done
test1_pass:
    li a2, 0x600D0001        # PASS marker
    addi t6, t6, 1           # Increment pass counter
test1_done:
    slli t0, s11, 2
    add t0, t0, s10
    sw a2, 0(t0)
    addi s11, s11, 1

    ##########################################################################
    # Test 2: Double reversal should give original
    # BREV(BREV(x)) == x for all x
    ##########################################################################
    li a0, 0xABCD1234
    mv a3, a0                # Save original
    .word 0x2005457B         # brev a0, a0 (first reversal)
    .word 0x2005457B         # brev a0, a0 (second reversal)

    beq a0, a3, test2_pass
    li a2, 0xBAD00002
    j test2_done
test2_pass:
    li a2, 0x600D0002
    addi t6, t6, 1
test2_done:
    slli t0, s11, 2
    add t0, t0, s10
    sw a2, 0(t0)
    addi s11, s11, 1

    ##########################################################################
    # Test 3: BREV combined with left shift
    # Take 0x0000FFFF, shift left 16, then BREV
    # 0x0000FFFF << 16 = 0xFFFF0000
    # BREV(0xFFFF0000) = 0x0000FFFF (reversed)
    ##########################################################################
    li a0, 0x0000FFFF
    slli a0, a0, 16          # a0 = 0xFFFF0000
    .word 0x2005457B         # brev a0, a0
    li a1, 0x0000FFFF        # Expected result

    beq a0, a1, test3_pass
    li a2, 0xBAD00003
    j test3_done
test3_pass:
    li a2, 0x600D0003
    addi t6, t6, 1
test3_done:
    slli t0, s11, 2
    add t0, t0, s10
    sw a2, 0(t0)
    addi s11, s11, 1

    ##########################################################################
    # Test 4: Multiple BREV operations in sequence
    # Test with different single-bit patterns
    ##########################################################################
    # Test bit 0 set
    li a0, 0x00000001
    mv a3, a0
    .word 0x2005457B         # brev a0, a0
    .word 0x2005457B         # brev a0, a0 back
    bne a0, a3, test4_fail

    # Test bit 16 set
    li a0, 0x00010000
    mv a3, a0
    .word 0x2005457B         # brev a0, a0
    .word 0x2005457B         # brev a0, a0 back
    bne a0, a3, test4_fail

    # Test bit 31 set
    lui a0, 0x80000
    mv a3, a0
    .word 0x2005457B         # brev a0, a0
    .word 0x2005457B         # brev a0, a0 back
    bne a0, a3, test4_fail

    # All passed
    li a2, 0x600D0004
    addi t6, t6, 1
    j test4_done

test4_fail:
    li a2, 0xBAD00004

test4_done:
    slli t0, s11, 2
    add t0, t0, s10
    sw a2, 0(t0)
    addi s11, s11, 1

    ##########################################################################
    # Test 5: BREV with arithmetic - CRC-like operation
    # Compute: (x BREV x) XOR (shift(BREV(x), 8))
    ##########################################################################
    li a0, 0x12345678
    .word 0x2005457B         # brev a0, a0 -> 0x1E6A2C48

    # XOR with original
    li a1, 0x12345678
    xor a0, a0, a1           # a0 = 0x1E6A2C48 XOR 0x12345678

    # Shift result left by 8
    slli a0, a0, 8

    # BREV the result
    .word 0x2005457B         # brev a0, a0

    # Just verify it's non-zero (any operation happened)
    bnez a0, test5_pass
    li a2, 0xBAD00005
    j test5_done
test5_pass:
    li a2, 0x600D0005
    addi t6, t6, 1
test5_done:
    slli t0, s11, 2
    add t0, t0, s10
    sw a2, 0(t0)
    addi s11, s11, 1

    ##########################################################################
    # Test 6: Conditional BREV based on comparison
    # If value > threshold, BREV it, else shift it
    ##########################################################################
    li a0, 0x80000000        # Test value (MSB set)
    li a1, 0x7FFFFFFF        # Threshold

    # Unsigned comparison
    bgtu a0, a1, do_brev
    # Value <= threshold, shift instead
    slli a0, a0, 1
    j compare_done

do_brev:
    .word 0x2005457B         # brev a0, a0

compare_done:
    # Should have taken BREV path, result should be 0x00000001
    li a1, 0x00000001
    beq a0, a1, test6_pass
    li a2, 0xBAD00006
    j test6_done
test6_pass:
    li a2, 0x600D0006
    addi t6, t6, 1
test6_done:
    slli t0, s11, 2
    add t0, t0, s10
    sw a2, 0(t0)
    addi s11, s11, 1

    ##########################################################################
    # Test 7: Triple BREV - should return original
    # BREV(BREV(BREV(x))) == BREV(x)
    ##########################################################################
    li a0, 0x9A7B3C1D        # Random value
    .word 0x2005457B         # brev a0, a0
    mv a3, a0                # Save first BREV result
    .word 0x2005457B         # brev a0, a0
    .word 0x2005457B         # brev a0, a0

    beq a0, a3, test7_pass
    li a2, 0xBAD00007
    j test7_done
test7_pass:
    li a2, 0x600D0007
    addi t6, t6, 1
test7_done:
    slli t0, s11, 2
    add t0, t0, s10
    sw a2, 0(t0)
    addi s11, s11, 1

    ##########################################################################
    # Test 8: BREV in function call with return value check
    ##########################################################################
    lui a0, 0xDEADC
    addi a0, a0, -0x111      # a0 = 0xDEADBEEF
    jal ra, brev_function

    # Expected: 0xF77DB57B
    lui a1, 0xF77DB
    addi a1, a1, 0x57B       # a1 = 0xF77DB57B

    beq a0, a1, test8_pass
    li a2, 0xBAD00008
    j test8_done
test8_pass:
    li a2, 0x600D0008
    addi t6, t6, 1
test8_done:
    slli t0, s11, 2
    add t0, t0, s10
    sw a2, 0(t0)
    addi s11, s11, 1

    ##########################################################################
    # Test 9: BREV on palindromic value
    # 0x80000001 reversed should also be 0x80000001
    ##########################################################################
    lui a0, 0x80000
    addi a0, a0, 1           # a0 = 0x80000001

    mv a3, a0                # Save original
    .word 0x2005457B         # brev a0, a0

    # Palindromic value should equal itself when reversed
    beq a0, a3, test9_pass
    li a2, 0xBAD00009
    j test9_done
test9_pass:
    li a2, 0x600D0009
    addi t6, t6, 1
test9_done:
    slli t0, s11, 2
    add t0, t0, s10
    sw a2, 0(t0)
    addi s11, s11, 1

    ##########################################################################
    # Test 10: Verify BREV doesn't affect zero and all-ones
    ##########################################################################
    li a0, 0x00000000
    .word 0x2005457B         # brev a0, a0
    bnez a0, test10_fail

    li a0, 0xFFFFFFFF
    .word 0x2005457B         # brev a0, a0
    li a1, 0xFFFFFFFF
    bne a0, a1, test10_fail

    li a2, 0x600D000A
    addi t6, t6, 1
    j test10_done
test10_fail:
    li a2, 0xBAD0000A
test10_done:
    slli t0, s11, 2
    add t0, t0, s10
    sw a2, 0(t0)
    addi s11, s11, 1

    ##########################################################################
    # Final summary: Store pass count and total count
    ##########################################################################
    slli t0, s11, 2
    add t0, t0, s10
    sw t6, 0(t0)             # Pass count
    addi s11, s11, 1

    slli t0, s11, 2
    add t0, t0, s10
    li t1, 10                # Total tests
    sw t1, 0(t0)             # Total count

    # Signal completion
    li a0, 0xD000000E
    csrw 0x7C1, a0

_done:
    j _done

##############################################################################
# Helper function: BREV wrapper
##############################################################################
brev_function:
    .word 0x2005457B         # brev a0, a0
    ret
