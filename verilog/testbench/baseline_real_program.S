##############################################################################
# BASELINE Real-World Test Program (WITHOUT CSEL)
#
# This is the baseline version of csel_real_program.S
# Uses traditional branches instead of CSEL for performance comparison
# Both versions run on the SAME modified BiRiscV core
##############################################################################

.section .text
.globl _start

_start:
    # Initialize stack pointer
    lui sp, 0x80010          # SP = 0x80010000

    # Test 1: Array max/min finder using branches
    jal ra, test_array_max_min

    # Test 2: Conditional accumulator (sum positive values only)
    jal ra, test_conditional_sum

    # Test 3: Absolute value using branches
    jal ra, test_abs_value

    # Test 4: Branch-based conditional selection
    jal ra, test_branch_interaction

    # Test 5: Data hazards with branches
    jal ra, test_data_hazards

    # Test 6: Array element swap based on condition
    jal ra, test_conditional_swap

    # Store final results to memory for verification
    jal ra, store_results

    # Finish - write to CSR to signal completion
    li a0, 0x12345678        # Success marker
    csrw 0x7C1, a0

_done:
    j _done                   # Infinite loop


##############################################################################
# Test 1: Array Maximum/Minimum Finder (BASELINE - using branches)
##############################################################################
test_array_max_min:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    # Create array in memory (same data as CSEL version)
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

    # Update maximum using branch
    # if (current > max) max = current
    bgt t0, s1, update_max
    j check_min
update_max:
    mv s1, t0

check_min:
    # Update minimum using branch
    # if (current < min) min = current
    blt t0, s2, update_min
    j loop_continue
update_min:
    mv s2, t0

loop_continue:
    addi s0, s0, 4        # Next element
    addi t6, t6, -1       # Decrement counter
    bnez t6, max_min_loop # Continue loop

    # Store results (max in 0x80009000, min in 0x80009004)
    lui t0, 0x80009
    sw s1, 0(t0)          # Store max (should be 99)
    sw s2, 4(t0)          # Store min (should be -88)

    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret


##############################################################################
# Test 2: Conditional Sum (BASELINE - using branches)
##############################################################################
test_conditional_sum:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw s0, 0(sp)

    # Array: 10, -5, 20, -15, 30, -25, 40 (same as CSEL version)
    lui s0, 0x8000A       # Array address
    li t0, 10
    sw t0, 0(s0)
    li t0, -5
    sw t0, 4(s0)
    li t0, 20
    sw t0, 8(s0)
    li t0, -15
    sw t0, 12(s0)
    li t0, 30
    sw t0, 16(s0)
    li t0, -25
    sw t0, 20(s0)
    li t0, 40
    sw t0, 24(s0)

    li t5, 0              # sum = 0
    li t6, 7              # count
    mv t4, s0             # array pointer

sum_loop:
    lw t0, 0(t4)          # Load element

    # Add to sum only if positive using branch
    # if (t0 >= 0) sum += t0
    bltz t0, skip_add     # Branch if negative
    add t5, t5, t0        # Add positive value
skip_add:

    addi t4, t4, 4
    addi t6, t6, -1
    bnez t6, sum_loop

    # Store result (should be 100: 10+20+30+40)
    lui t0, 0x80009
    sw t5, 8(t0)

    lw s0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret


##############################################################################
# Test 3: Absolute Value (BASELINE - using branches)
##############################################################################
test_abs_value:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Test abs() on several values: -42, 17, -99, 0, 255
    li a0, -42
    jal ra, abs_func
    mv s3, a0             # Store result

    li a0, 17
    jal ra, abs_func
    add s3, s3, a0        # Accumulate

    li a0, -99
    jal ra, abs_func
    add s3, s3, a0        # Accumulate

    li a0, 0
    jal ra, abs_func
    add s3, s3, a0        # Accumulate

    li a0, 255
    jal ra, abs_func
    add s3, s3, a0        # Accumulate (should be 42+17+99+0+255 = 413)

    # Store result
    lui t0, 0x80009
    sw s3, 12(t0)

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Absolute value function using branches
abs_func:
    # if (a0 < 0) a0 = -a0
    bltz a0, negate_value
    ret
negate_value:
    sub a0, x0, a0        # a0 = -a0
    ret


##############################################################################
# Test 4: Branch Interactions (BASELINE)
##############################################################################
test_branch_interaction:
    addi sp, sp, -4
    sw ra, 0(sp)

    li t5, 0              # result accumulator
    li t6, 10             # loop counter
    li t4, 5              # threshold

branch_loop:
    # Compute value based on counter
    mv t0, t6
    slli t1, t0, 1        # t1 = counter * 2

    # Branch based on threshold
    blt t6, t4, branch_less

branch_greater:
    # Path 1: counter >= 5
    li t2, 100
    li t3, 50
    bge t6, t4, select_100  # if counter >= threshold, use 100
    mv t0, t3
    j branch_merge
select_100:
    mv t0, t2
    j branch_merge

branch_less:
    # Path 2: counter < 5
    li t2, 20
    li t3, 10
    bge t4, t6, select_20   # if threshold >= counter, use 20
    mv t0, t3
    j branch_merge
select_20:
    mv t0, t2

branch_merge:
    add t5, t5, t0        # Accumulate result

    addi t6, t6, -1
    bnez t6, branch_loop

    # Store result
    lui t0, 0x80009
    sw t5, 16(t0)

    lw ra, 0(sp)
    addi sp, sp, 4
    ret


##############################################################################
# Test 5: Data Hazards (BASELINE - using branches)
##############################################################################
test_data_hazards:
    addi sp, sp, -4
    sw ra, 0(sp)

    li t0, 10
    li t1, 20
    li t2, 0              # condition = 0

    # Chain 1: conditional move with branch
    # t3 = (t2 == 0) ? t0 : t1
    beqz t2, select_t0_1
    mv t3, t1
    j chain_2
select_t0_1:
    mv t3, t0

chain_2:
    # Use result immediately (RAW hazard)
    li t4, 30
    li t2, 1              # condition = 1
    # t5 = (t2 == 0) ? t3 : t4
    beqz t2, select_t3
    mv t5, t4
    j chain_3
select_t3:
    mv t5, t3

chain_3:
    # Another immediate use (double RAW)
    li t2, 0
    # t6 = (t2 == 0) ? t5 : t0
    beqz t2, select_t5
    mv t6, t0
    j load_test
select_t5:
    mv t6, t5

load_test:
    # Load-to-conditional hazard
    lui a0, 0x80008
    lw t0, 0(a0)          # Load from memory
    li t2, 0
    # s1 = (t2 == 0) ? t0 : t1
    beqz t2, select_t0_2
    mv s1, t1
    j store_test
select_t0_2:
    mv s1, t0

store_test:
    # Conditional-to-store hazard
    sw s1, 0(a0)          # Store result immediately

    # Conditional with both operands from recent operations
    li t2, 1
    # a0 = (t2 == 0) ? t3 : t5
    beqz t2, select_t3_final
    mv a0, t5
    j hazard_done
select_t3_final:
    mv a0, t3

hazard_done:
    # Store final result
    lui t0, 0x80009
    sw a0, 20(t0)
    sw t6, 24(t0)

    lw ra, 0(sp)
    addi sp, sp, 4
    ret


##############################################################################
# Test 6: Conditional Array Element Swap (BASELINE - using branches)
##############################################################################
test_conditional_swap:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Array: [30, 10, 50, 20, 40] (same as CSEL version)
    lui s0, 0x8000B
    li t0, 30
    sw t0, 0(s0)
    li t0, 10
    sw t0, 4(s0)
    li t0, 50
    sw t0, 8(s0)
    li t0, 20
    sw t0, 12(s0)
    li t0, 40
    sw t0, 16(s0)

    # Bubble sort one pass using branches
    li t6, 4              # pairs to check
    mv t5, s0             # pointer

swap_loop:
    lw t0, 0(t5)          # a[i]
    lw t1, 4(t5)          # a[i+1]

    # Compare and swap if a[i] > a[i+1]
    ble t0, t1, no_swap   # if a[i] <= a[i+1], don't swap

    # Swap needed
    sw t1, 0(t5)          # a[i] = a[i+1]
    sw t0, 4(t5)          # a[i+1] = a[i] (old a[i])
    j swap_continue

no_swap:
    # No swap - elements already in order

swap_continue:
    addi t5, t5, 4        # Next pair
    addi t6, t6, -1
    bnez t6, swap_loop

    # Load final array (partially sorted after one pass)
    lw t0, 0(s0)
    lw t1, 4(s0)
    lw t2, 8(s0)
    lw t3, 12(s0)
    lw t4, 16(s0)

    # Store for verification
    lui a0, 0x80009
    sw t0, 28(a0)
    sw t1, 32(a0)
    sw t2, 36(a0)
    sw t3, 40(a0)
    sw t4, 44(a0)

    lw ra, 0(sp)
    addi sp, sp, 4
    ret


##############################################################################
# Store all results to designated memory region for verification
##############################################################################
store_results:
    # Results already stored throughout tests
    # Just add a summary marker
    lui t0, 0x80009
    li t1, 0xDEADBEEF    # Marker that tests completed
    sw t1, 48(t0)
    ret
