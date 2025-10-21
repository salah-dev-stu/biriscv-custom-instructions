##############################################################################
# CMOV BASELINE Real-World Test Program (WITHOUT CMOV)
#
# Uses traditional branches for conditional assignments
# Tests common CMOV use cases: clamping, conditional updates, thresholding
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
# Test 1: Value Clamping (BASELINE - using branches)
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

    # Clamp to minimum (0)
    # Branch: value < 0 ? value = 0
    bgez t0, check_max
    li t0, 0
    j store_clamped

check_max:
    # Clamp to maximum (255)
    # Branch: value > 255 ? value = 255
    li t1, 255
    ble t0, t1, store_clamped
    li t0, 255

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
# Test 2: Conditional Update (BASELINE - using branches)
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

    # Branch: value > threshold ? update sum
    # sum = (value > 10) ? value : sum
    ble t0, t3, skip_update
    mv t5, t0                # Update sum with new value

skip_update:
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
# Test 3: Saturating Addition (BASELINE - using branches)
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

    # Add 30
    li t0, 30
    add t1, s1, t0           # t1 = 200 + 30 = 230
    blt t1, s2, sat_ok_1
    mv t1, s2                # Saturate to 255
sat_ok_1:
    mv s1, t1

    # Add 40
    li t0, 40
    add t1, s1, t0           # t1 = 230 + 40 = 270
    blt t1, s2, sat_ok_2
    mv t1, s2                # Saturate to 255
sat_ok_2:
    mv s1, t1

    # Add 50 (should saturate)
    li t0, 50
    add t1, s1, t0           # t1 = 255 + 50 = 305
    blt t1, s2, sat_ok_3
    mv t1, s2                # Saturate to 255
sat_ok_3:
    mv s1, t1

    # Add 60 (already saturated)
    li t0, 60
    add t1, s1, t0           # t1 = 255 + 60 = 315
    blt t1, s2, sat_ok_4
    mv t1, s2                # Saturate to 255
sat_ok_4:
    mv s1, t1

    # Store result (should be 255)
    lui t0, 0x80009
    sw s1, 36(t0)

    lw ra, 0(sp)
    addi sp, sp, 4
    ret


##############################################################################
# Test 4: Conditional Assignment Chain (BASELINE - using branches)
# Chain of conditional assignments simulating state machine
##############################################################################
test_assignment_chain:
    addi sp, sp, -4
    sw ra, 0(sp)

    li t0, 10                # state = 10
    li t6, 5                 # loop counter

    # State machine transitions with conditions
chain_loop:
    # Transition 1: state > 8 ? state = 20 : keep state
    li t1, 8
    ble t0, t1, chain_2
    li t0, 20

chain_2:
    # Transition 2: state < 25 ? state = 30 : keep state
    li t1, 25
    bge t0, t1, chain_3
    li t0, 30

chain_3:
    # Transition 3: state == 30 ? state = 40 : keep state
    li t1, 30
    bne t0, t1, chain_4
    li t0, 40

chain_4:
    # Transition 4: state >= 35 ? state = 50 : keep state
    li t1, 35
    blt t0, t1, chain_continue
    li t0, 50

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
    li t1, 0xC0DE0001        # Baseline completion marker
    sw t1, 44(t0)
    ret
