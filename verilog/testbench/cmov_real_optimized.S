##############################################################################
# CMOV OPTIMIZED Real-World Test Program (WITH CMOV)
#
# Uses CMOV instruction for branchless conditional assignments
# Tests common CMOV use cases: clamping, conditional updates, thresholding
# MUST produce identical results to cmov_real_baseline.S
##############################################################################

.section .text
.globl _start

_start:
    # Initialize stack pointer
    lui sp, 0x80010          # SP = 0x80010000

    # Test 1: Value clamping (clamp to range [0, 255])
    jal ra, test_clamp_values

    # Test 2: Conditional accumulator (update sum if above threshold)
    jal ra, test_conditional_update

    # Test 3: Saturating arithmetic (prevent overflow)
    jal ra, test_saturating_add

    # Test 4: Conditional assignment chain
    jal ra, test_assignment_chain

    # Store final results to memory for verification
    jal ra, store_results

    # Finish - write to CSR to signal completion
    li a0, 0x12345678        # Success marker
    csrw 0x7C1, a0

_done:
    j _done                   # Infinite loop


##############################################################################
# Test 1: Value Clamping (CMOV - branchless)
# Clamps array values to range [0, 255]
##############################################################################
test_clamp_values:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    # Create array with values needing clamping
    # Values: [-50, 100, 300, -10, 200, 500, 50, -100]
    lui s0, 0x80008          # Array base address
    li t0, -50
    sw t0, 0(s0)
    li t0, 100
    sw t0, 4(s0)
    li t0, 300
    sw t0, 8(s0)
    li t0, -10
    sw t0, 12(s0)
    li t0, 200
    sw t0, 16(s0)
    li t0, 500
    sw t0, 20(s0)
    li t0, 50
    sw t0, 24(s0)
    li t0, -100
    sw t0, 28(s0)

    li t6, 8                 # Counter
    mv s1, s0                # Source pointer
    lui s2, 0x80009          # Destination for clamped values

clamp_loop:
    lw t0, 0(s1)             # Load value

    # Clamp to minimum (0) using CMOV
    # CMOV: value < 0 ? value = 0
    # Get sign bit as condition
    srli t3, t0, 31          # t3 = sign bit (1 if negative)
    li t1, 0                 # min value
    # cmov t0, t1, t0, t3 (if t3!=0, select t1(0), else keep t0)
    .word 0xE65312FB         # rs3=t3(28), funct2=11, rs2=t0(5), rs1=t1(6), funct3=001, rd=t0(5)

    # Clamp to maximum (255) using CMOV
    # CMOV: value > 255 ? value = 255
    li t1, 255
    sub t2, t0, t1           # t2 = value - 255
    srli t3, t2, 31          # t3 = 0 if value > 255, 1 if value <= 255
    xori t3, t3, 1           # t3 = 1 if value > 255, 0 if value <= 255
    # cmov t0, t1, t0, t3 (if t3!=0, select t1(255), else keep t0)
    .word 0xE65312FB         # rs3=t3(28), funct2=11, rs2=t0(5), rs1=t1(6), funct3=001, rd=t0(5)

store_clamped:
    sw t0, 0(s2)             # Store clamped value
    addi s1, s1, 4
    addi s2, s2, 4
    addi t6, t6, -1
    bnez t6, clamp_loop

    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret


##############################################################################
# Test 2: Conditional Update (CMOV - branchless)
# Update accumulator only if value exceeds threshold
##############################################################################
test_conditional_update:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw s0, 0(sp)

    # Array: [5, 15, 8, 22, 3, 18, 12, 30]
    # Threshold: 10
    # Only update sum with values > 10
    lui s0, 0x8000A          # Array address
    li t0, 5
    sw t0, 0(s0)
    li t0, 15
    sw t0, 4(s0)
    li t0, 8
    sw t0, 8(s0)
    li t0, 22
    sw t0, 12(s0)
    li t0, 3
    sw t0, 16(s0)
    li t0, 18
    sw t0, 20(s0)
    li t0, 12
    sw t0, 24(s0)
    li t0, 30
    sw t0, 28(s0)

    li t5, 0                 # sum = 0
    li t6, 8                 # count
    mv t4, s0                # array pointer
    li t3, 10                # threshold

update_loop:
    lw t0, 0(t4)             # Load value

    # CMOV: value > threshold ? update sum (branchless)
    # sum = (value > 10) ? value : sum
    sub t1, t0, t3           # t1 = value - threshold
    sub t2, t3, t0           # t2 = threshold - value
    srli t2, t2, 31          # t2 = 1 if value > threshold, 0 otherwise
    # cmov t5, t0, t5, t2 (if t2!=0, select t0(value), else keep t5(sum))
    .word 0x3FE29F7B         # rs3=t2(7), funct2=11, rs2=t5(30), rs1=t0(5), funct3=001, rd=t5(30)

    addi t4, t4, 4
    addi t6, t6, -1
    bnez t6, update_loop

    # Store result (last value > 10, which is 30)
    lui t0, 0x80009
    sw t5, 32(t0)

    lw s0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret


##############################################################################
# Test 3: Saturating Addition (CMOV - branchless)
# Add values but saturate at maximum instead of wrapping
##############################################################################
test_saturating_add:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Test saturating add with multiple values
    # Starting value: 200
    # Add: [30, 40, 50, 60] with saturation at 255

    li s1, 200               # Initial value
    li s2, 255               # Maximum value

    # Add 30 (saturating)
    li t0, 30
    add t1, s1, t0           # t1 = 200 + 30 = 230
    sub t2, t1, s2           # t2 = result - max
    srli t3, t2, 31          # t3 = 0 if overflow, 1 if ok
    xori t3, t3, 1           # t3 = 1 if overflow, 0 if ok
    # cmov t1, s2, t1, t3 (if overflow, select s2(255), else keep t1)
    .word 0xE669137B         # rs3=t3(28), funct2=11, rs2=t1(6), rs1=s2(18), funct3=001, rd=t1(6)
    mv s1, t1

    # Add 40 (saturating)
    li t0, 40
    add t1, s1, t0           # t1 = 230 + 40 = 270
    sub t2, t1, s2           # t2 = result - max
    srli t3, t2, 31          # t3 = 0 if overflow, 1 if ok
    xori t3, t3, 1           # t3 = 1 if overflow, 0 if ok
    # cmov t1, s2, t1, t3
    .word 0xE669137B
    mv s1, t1

    # Add 50 (should saturate)
    li t0, 50
    add t1, s1, t0           # t1 = 255 + 50 = 305
    sub t2, t1, s2           # t2 = result - max
    srli t3, t2, 31          # t3 = 0 if overflow, 1 if ok
    xori t3, t3, 1           # t3 = 1 if overflow, 0 if ok
    # cmov t1, s2, t1, t3
    .word 0xE669137B
    mv s1, t1

    # Add 60 (already saturated)
    li t0, 60
    add t1, s1, t0           # t1 = 255 + 60 = 315
    sub t2, t1, s2           # t2 = result - max
    srli t3, t2, 31          # t3 = 0 if overflow, 1 if ok
    xori t3, t3, 1           # t3 = 1 if overflow, 0 if ok
    # cmov t1, s2, t1, t3
    .word 0xE669137B
    mv s1, t1

    # Store result (should be 255)
    lui t0, 0x80009
    sw s1, 36(t0)

    lw ra, 0(sp)
    addi sp, sp, 4
    ret


##############################################################################
# Test 4: Conditional Assignment Chain (CMOV - branchless)
# Chain of conditional assignments simulating state machine
##############################################################################
test_assignment_chain:
    addi sp, sp, -4
    sw ra, 0(sp)

    li t0, 10                # state = 10
    li t6, 5                 # loop counter

    # State machine transitions with conditions (branchless)
chain_loop:
    # Transition 1: state > 8 ? state = 20 : keep state
    li t1, 8
    sub t2, t0, t1           # t2 = state - 8
    sub t3, t1, t0           # t3 = 8 - state
    srli t3, t3, 31          # t3 = 1 when state > 8, 0 otherwise
    li t4, 20
    # cmov t0, t4, t0, t3 (when state > 8, select t4(20), else keep t0)
    .word 0xE65E92FB         # rs3=t3(28), funct2=11, rs2=t0(5), rs1=t4(29), funct3=001, rd=t0(5)

    # Transition 2: state < 25 ? state = 30 : keep state
    li t1, 25
    sub t2, t1, t0           # t2 = 25 - state
    srli t3, t2, 31          # t3 = 0 when state < 25, 1 when state >= 25
    xori t3, t3, 1           # t3 = 1 when state < 25, 0 otherwise
    li t4, 30
    # cmov t0, t4, t0, t3
    .word 0xE65E92FB

    # Transition 3: state == 30 ? state = 40 : keep state
    li t1, 30
    sub t2, t0, t1           # t2 = state - 30
    seqz t3, t2              # t3 = 1 when state == 30, 0 otherwise
    li t4, 40
    # cmov t0, t4, t0, t3
    .word 0xE65E92FB

    # Transition 4: state >= 35 ? state = 50 : keep state
    li t1, 35
    sub t2, t0, t1           # t2 = state - 35
    sub t3, t1, t0           # t3 = 35 - state
    srli t3, t3, 31          # t3 = 1 when state >= 35, 0 otherwise
    li t4, 50
    # cmov t0, t4, t0, t3
    .word 0xE65E92FB

chain_continue:
    addi t6, t6, -1
    bnez t6, chain_loop

    # Store final state (should be 50)
    lui t1, 0x80009
    sw t0, 40(t1)

    lw ra, 0(sp)
    addi sp, sp, 4
    ret


##############################################################################
# Store all results to designated memory region for verification
##############################################################################
store_results:
    # Results already stored throughout tests
    # Expected results at 0x80009000:
    # [0-31]:  Clamped values: [0, 100, 255, 0, 200, 255, 50, 0]
    # [32]:    Conditional update: 30
    # [36]:    Saturating add: 255
    # [40]:    Assignment chain: 50

    # Add completion marker
    lui t0, 0x80009
    li t1, 0xC0DE0002        # Optimized completion marker
    sw t1, 44(t0)
    ret
