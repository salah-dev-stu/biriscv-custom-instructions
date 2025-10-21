##############################################################################
# Simple Memory Test - No computation, just load and store
# This will help identify if the issue is in memory or computation
##############################################################################

.section .text
.globl _start

_start:
    lui sp, 0x80010          # SP = 0x80010000
    lui s2, 0x80009          # Storage base

    # Test 1: Store 0xFFFFFFFF directly (no computation)
    li a0, -1
    sw a0, 0(s2)

    # Test 2: Store 0xAAAAAAAA directly
    lui a0, 0xAAAAA
    addi a0, a0, -0x556
    sw a0, 4(s2)

    # Test 3: Store 0x12345678 directly
    lui a0, 0x12345
    addi a0, a0, 0x678
    sw a0, 8(s2)

    # Test 4: Load and store (read from one location, write to another)
    lw a0, 0(s2)
    sw a0, 12(s2)

    # Test 5: Simple AND operation
    li a0, -1                # 0xFFFFFFFF
    li a1, -1                # 0xFFFFFFFF
    and a0, a0, a1           # Should still be 0xFFFFFFFF
    sw a0, 16(s2)

    # Test 6: Simple OR operation
    li a0, 0
    li a1, -1
    or a0, a0, a1            # Should be 0xFFFFFFFF
    sw a0, 20(s2)

    # Test 7: Simple shift left
    li a0, 1
    slli a0, a0, 31          # Should be 0x80000000
    sw a0, 24(s2)

    # Test 8: Simple shift right
    lui a0, 0x80000          # 0x80000000
    srli a0, a0, 31          # Should be 0x00000001
    sw a0, 28(s2)

    # Completion marker
    li a0, 0xC0FFEE00
    sw a0, 32(s2)

    # Signal completion
    li a0, 0x12345678
    csrw 0x7C1, a0

_done:
    j _done
