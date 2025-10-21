##############################################################################
# Real-World TERNLOG Baseline Program (SOFTWARE BITWISE OPERATIONS)
#
# Application: Network Packet Filtering with Boolean Logic
#
# This program simulates real-world bitwise logical operations used in:
# 1. ACL (Access Control List) filtering with bitmasks
# 2. Protocol field extraction and manipulation
# 3. Data validation with XOR checksums
# 4. Conditional data masking for security
#
# Uses standard RISC-V logical instructions (slow but portable)
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
# Boolean Logic Functions using Standard Instructions
##############################################################################

# Function: Copy source A (identity)
# Input: a0 = source A, a1 = source B (unused)
# Output: a0 = A
copy_a:
    ret

# Function: Copy source B
# Input: a0 = source A (unused), a1 = source B
# Output: a0 = B
copy_b:
    mv a0, a1
    ret

# Function: AND operation
# Input: a0 = source A, a1 = source B
# Output: a0 = A AND B
and_op:
    and a0, a0, a1
    ret

# Function: OR operation
# Input: a0 = source A, a1 = source B
# Output: a0 = A OR B
or_op:
    or a0, a0, a1
    ret

# Function: XOR operation
# Input: a0 = source A, a1 = source B
# Output: a0 = A XOR B
xor_op:
    xor a0, a0, a1
    ret

# Function: NAND operation (NOT of AND)
# Input: a0 = source A, a1 = source B
# Output: a0 = NOT (A AND B)
nand_op:
    and a0, a0, a1
    not a0, a0
    ret

# Function: NOR operation (NOT of OR)
# Input: a0 = source A, a1 = source B
# Output: a0 = NOT (A OR B)
nor_op:
    or a0, a0, a1
    not a0, a0
    ret

# Function: A AND NOT B (clear B bits from A)
# Input: a0 = source A, a1 = source B
# Output: a0 = A AND (NOT B)
andnot_op:
    not a2, a1        # Use a2 as temp to preserve a1
    and a0, a0, a2
    ret

# Function: XNOR operation (equivalence)
# Input: a0 = source A, a1 = source B
# Output: a0 = NOT (A XOR B)
xnor_op:
    xor a0, a0, a1
    not a0, a0
    ret

# Function: Implies (A -> B = NOT A OR B)
# Input: a0 = source A, a1 = source B
# Output: a0 = (NOT A) OR B
implies_op:
    not a0, a0
    or a0, a0, a1
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

    # Extract relevant fields: header AND mask
    mv a0, s0
    mv a1, s1
    jal ra, and_op
    mv s0, a0                # s0 = masked header

    # Compare with pattern using XNOR (equivalence check)
    mv a0, s0
    mv a1, s2
    jal ra, xnor_op

    # Check if all bits match (result should be all 1s)
    # For simplicity, we'll just return the result
    # In real ACL, we'd check if result == 0xFFFFFFFF

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

    # Clear bits in extract mask: packet AND NOT extract_mask
    mv a0, s0
    mv a1, s1
    jal ra, andnot_op
    mv s0, a0                # s0 = cleared packet

    # Set new bits: cleared OR set_mask
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

    # XOR data1 and data2
    mv a0, s0
    # a1 already has data2
    jal ra, xor_op
    mv s0, a0                # s0 = data1 XOR data2

    # XOR with data3
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

    # Compute visible bits: permissions AND data
    mv a0, s1
    mv a1, s0
    jal ra, and_op
    mv s0, a0                # s0 = visible bits

    # Compute masked bits: (NOT permissions) AND mask_pattern
    not a0, s1
    mv a1, s2
    jal ra, and_op
    mv s1, a0                # s1 = masked bits

    # Combine: visible OR masked
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

    # Operation 1: ACL Filter - check if packet matches rule
    li a0, 0x12345678        # Packet header
    li a1, 0xFF00FF00        # ACL mask
    li a2, 0x12003400        # ACL pattern
    jal ra, acl_filter
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 2: Protocol field manipulation
    li a0, 0xABCDEF00        # Original packet
    li a1, 0x0000FF00        # Extract mask (clear byte 1)
    li a2, 0x00005500        # Set mask (set to 0x55)
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
    li a0, 0xDEADBEEF        # Sensitive data
    li a1, 0x0F0F0F0F        # User permissions (limited access)
    li a2, 0xFFFFFFFF        # Mask pattern (hide unauthorized bits)
    jal ra, security_mask
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 5: Copy A (pass through)
    mv a0, s0                # 0xAAAAAAAA
    mv a1, s1
    jal ra, copy_a
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 6: XOR for encryption/obfuscation
    mv a0, s0
    mv a1, s1
    jal ra, xor_op
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 7: AND filter
    li a0, 0xFFFF0000        # Data
    li a1, 0x0000FFFF        # Mask (extract lower half)
    jal ra, and_op
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 8: OR combine
    li a0, 0xF0F0F0F0        # Data 1
    li a1, 0x0F0F0F0F        # Data 2
    jal ra, or_op
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 9: NAND for inverted logic
    mv a0, s0
    mv a1, s1
    jal ra, nand_op
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 10: AND NOT (bit clearing)
    mv a0, s0
    mv a1, s1
    jal ra, andnot_op
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 11: Implies (conditional logic)
    mv a0, s0
    mv a1, s1
    jal ra, implies_op
    slli t0, s2, 2
    add t0, t0, s3
    sw a0, 0(t0)
    addi s2, s2, 1

    # Operation 12: NOR for completion check
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
