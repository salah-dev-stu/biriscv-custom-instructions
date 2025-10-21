##############################################################################
# CSEL Real-World Test Program
#
# This program tests CSEL instruction in realistic scenarios:
# - Array operations with conditional moves
# - Loop-based processing with branches
# - Data hazards and pipeline stalls
# - Branch mispredictions with CSEL in branch shadows
# - Load/store sequences with CSEL
# - Register pressure scenarios
##############################################################################

.section .text
.globl _start

_start:
    # Initialize stack pointer
    lui sp, 0x80010          # SP = 0x80010000

    # Test 1: Array max/min finder using CSEL
    # Find maximum and minimum in an array
    jal ra, test_array_max_min

    # Test 2: Conditional accumulator (sum positive values only)
    jal ra, test_conditional_sum

    # Test 3: Branchless absolute value using CSEL
    jal ra, test_abs_value

    # Test 4: CSEL in branch delay slots / branch shadows
    jal ra, test_branch_interaction

    # Test 5: CSEL with data hazards (RAW hazards)
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
    # To find max: if current > max, use current, else use max
    # We check: current - max. If positive (current > max), we want current
    # CSEL: rd = (rs3 == 0) ? rs1 : rs2
    # Strategy: Use sign bit of (current - max) as condition
    sub t1, t0, s1        # t1 = current - max
    srli t3, t1, 31       # t3 = sign bit (1 if negative, 0 if positive/zero)
    # csel s1, t0, s1, t3   # s1 = (t3 == 0) ? t0 : s1  (use current if t3=0, meaning current >= max)
    .word 0xE09284FB      # Encoding: rs3=t3(x28), rs2=s1(x9), rs1=t0(x5), rd=s1(x9)

    # Update minimum using CSEL
    # To find min: if current < min, use current, else use min
    # We check: min - current. If positive (min > current), we want current
    sub t2, s2, t0        # t2 = min - current
    srli t4, t2, 31       # t4 = sign bit (1 if negative, 0 if positive/zero)
    # csel s2, t0, s2, t4   # s2 = (t4 == 0) ? t0 : s2  (use current if t4=0, meaning min >= current)
    .word 0xE922897B      # Encoding: rs3=t4(x29), rs2=s2(x18), rs1=t0(x5), rd=s2(x18)

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
# Test 2: Conditional Sum (sum only positive values)
# Demonstrates CSEL avoiding branches in accumulator pattern
##############################################################################
test_conditional_sum:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw s0, 0(sp)

    # Array: 10, -5, 20, -15, 30, -25, 40
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

    # Add to sum only if positive using CSEL
    # If t0 >= 0, add it; otherwise add 0
    # Strategy: Use sign bit as condition
    srli t3, t0, 31       # t3 = 1 if negative, 0 if positive
    # csel t2, t0, x0, t3   # t2 = (t3 == 0) ? t0 : 0  (select t0 if positive, 0 if negative)
    .word 0xE00283FB      # Encoding: rs3=t3(x28), rs2=x0(x0), rs1=t0(x5), rd=t2(x7)
    add t5, t5, t2        # sum += selected value

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
# Test 3: Branchless Absolute Value
# Multiple consecutive CSEL operations with data dependencies
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

# Absolute value function using CSEL
abs_func:
    # Compute abs(a0): return (a0 < 0) ? -a0 : a0
    sub t0, x0, a0        # t0 = -a0
    srli t1, a0, 31       # t1 = sign bit (1 if negative, 0 if positive)
    # csel a0, a0, t0, t1   # a0 = (t1 == 0) ? a0 : t0  (select a0 if positive, -a0 if negative)
    .word 0x3055057B      # Encoding: rs3=t1(x6), rs2=t0(x5), rs1=a0(x10), rd=a0(x10)
    ret


##############################################################################
# Test 4: CSEL with Branch Interactions
# Tests CSEL in branch shadows and with branch mispredictions
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
    # Use CSEL to select between two values
    li t2, 100
    li t3, 50
    sub a0, t6, t4        # a0 = counter - threshold
    srli a1, a0, 31       # a1 = sign bit (1 if negative, 0 if positive/zero)
    # csel t0, t2, t3, a1   # t0 = (a1 == 0) ? t2 : t3  (select 100 if counter>threshold, else 50)
    .word 0x59C382FB      # Encoding: rs3=a1(x11), rs2=t3(x28), rs1=t2(x7), rd=t0(x5)
    j branch_merge

branch_less:
    # Path 2: counter < 5
    li t2, 20
    li t3, 10
    sub a0, t4, t6        # a0 = threshold - counter
    srli a1, a0, 31       # a1 = sign bit
    # csel t0, t2, t3, a1   # t0 = (a1 == 0) ? t2 : t3
    .word 0x59C382FB      # Encoding: rs3=a1(x11), rs2=t3(x28), rs1=t2(x7), rd=t0(x5)

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
# Test 5: CSEL with Data Hazards (RAW)
# Chain of CSEL operations with dependencies
##############################################################################
test_data_hazards:
    addi sp, sp, -4
    sw ra, 0(sp)

    li t0, 10
    li t1, 20
    li t2, 0              # condition = 0

    # Chain 1: immediate RAW hazard
    # csel t3, t0, t1, t2   # t3 = t0 (condition is 0)
    .word 0x38628E7B      # Encoding: rs3=t2, rs2=t1, rs1=t0, rd=t3

    # Use result immediately in next CSEL (RAW hazard)
    li t4, 30
    li t2, 1              # condition = 1
    # csel t5, t3, t4, t2   # t5 = t4 (condition is 1) - depends on previous t3
    .word 0x39DE0F7B      # Encoding: rs3=t2, rs2=t4, rs1=t3, rd=t5

    # Another immediate use (double RAW)
    li t2, 0
    # csel t6, t5, t0, t2   # t6 = t5 - depends on previous t5
    .word 0x385F0FFB      # Encoding: rs3=t2, rs2=t0, rs1=t5, rd=t6

    # Load-to-CSEL hazard
    lui a0, 0x80008
    lw t0, 0(a0)          # Load from memory
    li t2, 0
    # csel s1, t0, t1, t2   # Use loaded value immediately
    .word 0x386284FB      # Encoding: rs3=t2, rs2=t1, rs1=t0, rd=s1

    # CSEL-to-store hazard
    sw s1, 0(a0)          # Store result immediately

    # CSEL in both operands
    li t2, 1
    # csel a0, t3, t5, t2   # Both t3 and t5 from recent CSEL
    .word 0x39EE057B      # Encoding: rs3=t2, rs2=t5, rs1=t3, rd=a0

    # Store final result
    lui t0, 0x80009
    sw a0, 20(t0)
    sw t6, 24(t0)

    lw ra, 0(sp)
    addi sp, sp, 4
    ret


##############################################################################
# Test 6: Conditional Array Element Swap
# Realistic use case: reorder array elements based on condition
##############################################################################
test_conditional_swap:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Array: [30, 10, 50, 20, 40]
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

    # Bubble sort one pass using CSEL
    li t6, 4              # pairs to check
    mv t5, s0             # pointer

swap_loop:
    lw t0, 0(t5)          # a[i]
    lw t1, 4(t5)          # a[i+1]

    # Compare and swap if a[i] > a[i+1]
    sub t2, t0, t1        # t2 = a[i] - a[i+1]

    # If t2 > 0 (a[i] > a[i+1]), we need to swap
    # Check if we should swap: use sign bit
    srli t3, t2, 31       # t3 = sign bit (1 if negative/no swap, 0 if positive/swap)

    # New a[i]   = (swap) ? a[i+1] : a[i]   = (t3==0) ? t1 : t0
    # csel t4, t1, t0, t3
    .word 0xE0530EFB      # Encoding: rs3=t3(x28), rs2=t0(x5), rs1=t1(x6), rd=t4(x29)
    sw t4, 0(t5)          # Store new a[i]

    # New a[i+1] = (swap) ? a[i]   : a[i+1] = (t3==0) ? t0 : t1
    # csel t4, t0, t1, t3
    .word 0xE0628EFB      # Encoding: rs3=t3(x28), rs2=t1(x6), rs1=t0(x5), rd=t4(x29)
    sw t4, 4(t5)          # Store new a[i+1]

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
