##############################################################################
# Real-World TERNLOG Optimized Program (HARDWARE BITWISE OPERATIONS)
#
# Application: Network Packet Filtering with Boolean Logic
#
# This program simulates real-world bitwise logical operations used in:
# 1. ACL (Access Control List) filtering with bitmasks
# 2. Protocol field extraction and manipulation
# 3. Data validation with XOR checksums
# 4. Conditional data masking for security
#
# Uses TERNLOG custom instruction (fast single-cycle operation)
##############################################################################

.section .text
.globl _start

_start:
    # Initialize stack pointer
    lui sp, 0x80010          # SP = 0x80010000

    # Run packet filtering tasks
    jal ra, process_filtered_packets

    # Signal completion
    li a0, 0xF00DFACE
    csrw 0x7C1, a0

_done:
    j _done


##############################################################################
# Boolean Logic Functions using TERNLOG
# Format: ternlog rd, rs1, rs2, imm8
# Each function uses a specific imm8 value for the desired operation
##############################################################################

# Function: Copy source A (identity) - imm8=0x50
# Input: a0 = source A, a1 = source B (unused)
# Output: a0 = A
copy_a:
    .word 0x54b5057b         # ternlog a0, a0, a1, 0x50
    ret

# Function: Copy source B - imm8=0x44
# Input: a0 = source A (unused), a1 = source B
# Output: a0 = B
copy_b:
    .word 0x44b5457b         # ternlog a0, a0, a1, 0x44
    ret

# Function: AND operation - imm8=0x40
# Input: a0 = source A, a1 = source B
# Output: a0 = A AND B
and_op:
    .word 0x44b5057b         # ternlog a0, a0, a1, 0x40
    ret

# Function: OR operation - imm8=0x54
# Input: a0 = source A, a1 = source B
# Output: a0 = A OR B
or_op:
    .word 0x54b5457b         # ternlog a0, a0, a1, 0x54
    ret

# Function: XOR operation - imm8=0x14
# Input: a0 = source A, a1 = source B
# Output: a0 = A XOR B
xor_op:
    .word 0x14b5457b         # ternlog a0, a0, a1, 0x14
    ret

# Function: NAND operation - imm8=0x15
# Input: a0 = source A, a1 = source B
# Output: a0 = NOT (A AND B)
nand_op:
    .word 0x14b5557b         # ternlog a0, a0, a1, 0x15
    ret

# Function: NOR operation - imm8=0x01
# Input: a0 = source A, a1 = source B
# Output: a0 = NOT (A OR B)
nor_op:
    .word 0x04b5157b         # ternlog a0, a0, a1, 0x01
    ret

# Function: A AND NOT B - imm8=0x10
# Input: a0 = source A, a1 = source B
# Output: a0 = A AND (NOT B)
andnot_op:
    .word 0x14b5057b         # ternlog a0, a0, a1, 0x10
    ret

# Function: XNOR operation - imm8=0x41
# Input: a0 = source A, a1 = source B
# Output: a0 = NOT (A XOR B)
xnor_op:
    .word 0x44b5157b         # ternlog a0, a0, a1, 0x41
    ret

# Function: Implies (A -> B = NOT A OR B) - imm8=0x45
# Input: a0 = source A, a1 = source B
# Output: a0 = (NOT A) OR B
implies_op:
    .word 0x44b5557b         # ternlog a0, a0, a1, 0x45
    ret


##############################################################################
# ACL Filtering Function
# Applies Access Control List rules using boolean logic
# Input: a0 = packet header, a1 = ACL mask, a2 = ACL pattern
# Output: a0 = 1 if allowed, 0 if blocked
##############################################################################
acl_filter:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    mv s0, a0                # Save packet header
    mv s1, a1                # Save mask
    mv s2, a2                # Save pattern

    # Extract relevant fields: header AND mask (single instruction!)
    mv a0, s0
    mv a1, s1
    jal ra, and_op
    mv s0, a0                # s0 = masked header

    # Compare with pattern using XNOR (single instruction!)
    mv a0, s0
    mv a1, s2
    jal ra, xnor_op

    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret


##############################################################################
# Protocol Field Manipulation
# Extract and modify protocol fields using bitwise operations
# Input: a0 = packet data, a1 = extract mask, a2 = set mask
# Output: a0 = modified packet
##############################################################################
protocol_field_manip:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    mv s0, a0                # Save packet
    mv s1, a1                # Save extract mask
    mv s2, a2                # Save set mask

    # Clear bits: packet AND NOT extract_mask (single TERNLOG instruction!)
    mv a0, s0
    mv a1, s1
    jal ra, andnot_op
    mv s0, a0                # s0 = cleared packet

    # Set new bits: cleared OR set_mask (single TERNLOG instruction!)
    mv a0, s0
    mv a1, s2
    jal ra, or_op

    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret


##############################################################################
# XOR Checksum Calculation
# Compute XOR checksum for data validation
# Input: a0 = data1, a1 = data2, a2 = data3
# Output: a0 = checksum (data1 XOR data2 XOR data3)
##############################################################################
xor_checksum:
    addi sp, sp, -12
    sw ra, 8(sp)
    sw s0, 4(sp)
    sw s1, 0(sp)

    mv s0, a0                # Save data1
    mv s1, a2                # Save data3

    # XOR data1 and data2 (single TERNLOG instruction!)
    mv a0, s0
    jal ra, xor_op
    mv s0, a0                # s0 = data1 XOR data2

    # XOR with data3 (single TERNLOG instruction!)
    mv a0, s0
    mv a1, s1
    jal ra, xor_op

    lw s1, 0(sp)
    lw s0, 4(sp)
    lw ra, 8(sp)
    addi sp, sp, 12
    ret


##############################################################################
# Data Masking for Security
# Apply conditional masking based on security level
# Input: a0 = sensitive data, a1 = user permissions, a2 = mask pattern
# Output: a0 = masked data (shows only authorized bits)
##############################################################################
security_mask:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    mv s0, a0                # Save data
    mv s1, a1                # Save permissions
    mv s2, a2                # Save mask

    # Compute visible bits: permissions AND data (single TERNLOG!)
    mv a0, s1
    mv a1, s0
    jal ra, and_op
    mv s0, a0                # s0 = visible bits

    # Compute masked bits: (NOT permissions) AND mask_pattern
    # This requires NOT then AND, but with TERNLOG we can use A AND NOT B
    mv a0, s2                # mask_pattern
    mv a1, s1                # permissions
    jal ra, andnot_op        # mask AND NOT permissions (single TERNLOG!)
    mv s1, a0                # s1 = masked bits

    # Combine: visible OR masked (single TERNLOG!)
    mv a0, s0
    mv a1, s1
    jal ra, or_op

    lw s2, 0(sp)
    lw s1, 4(sp)
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret


##############################################################################
# Main Application: Process Filtered Network Packets
# Simulates 12 packet filtering operations
##############################################################################
process_filtered_packets:
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s0, 12(sp)
    sw s1, 8(sp)
    sw s2, 4(sp)
    sw s3, 0(sp)

    # Result storage base
    lui s3, 0x80009
    li s2, 0                 # Result index

    # Test data patterns
    lui s0, 0xAAAAB
    addi s0, s0, -1366       # s0 = 0xAAAAAAAA
    lui s1, 0xCCCCD
    addi s1, s1, -820        # s1 = 0xCCCCCCCC

    # Operation 1: ACL Filter
    li a0, 0x12345678
    li a1, 0xFF00FF00
    li a2, 0x12003400
    jal ra, acl_filter
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 2: Protocol field manipulation
    li a0, 0xABCDEF00
    li a1, 0x0000FF00
    li a2, 0x00005500
    jal ra, protocol_field_manip
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 3: XOR checksum
    li a0, 0x11111111
    li a1, 0x22222222
    li a2, 0x44444444
    jal ra, xor_checksum
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 4: Security masking
    li a0, 0xDEADBEEF
    li a1, 0x0F0F0F0F
    li a2, 0xFFFFFFFF
    jal ra, security_mask
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 5: Copy A
    mv a0, s0
    mv a1, s1
    jal ra, copy_a
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 6: XOR
    mv a0, s0
    mv a1, s1
    jal ra, xor_op
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 7: AND filter
    li a0, 0xFFFF0000
    li a1, 0x0000FFFF
    jal ra, and_op
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 8: OR combine
    li a0, 0xF0F0F0F0
    li a1, 0x0F0F0F0F
    jal ra, or_op
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 9: NAND
    mv a0, s0
    mv a1, s1
    jal ra, nand_op
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 10: AND NOT
    mv a0, s0
    mv a1, s1
    jal ra, andnot_op
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 11: Implies
    mv a0, s0
    mv a1, s1
    jal ra, implies_op
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 12: NOR
    li a0, 0x00000000
    li a1, 0x00000000
    jal ra, nor_op
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Store completion marker
    lui a0, 0xC0DE0
    addi a0, a0, 0x0D
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)

    lw s3, 0(sp)
    lw s2, 4(sp)
    lw s1, 8(sp)
    lw s0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    ret
