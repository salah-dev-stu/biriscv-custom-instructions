##############################################################################
# Test SLLI by 4 - check if bit 3 of each nibble is corrupted
##############################################################################

.section .text
.globl _start

_start:
    lui sp, 0x80010
    lui s2, 0x80009

    # Test 1: SLLI 0x0F0F0F0F by 4
    lui t0, 0x0F0F0
    addi t1, x0, 0x0F0
    slli t1, t1, 4
    addi t1, t1, 0x0F
    or t0, t0, t1            # t0 = 0x0F0F0F0F
    slli t2, t0, 4           # Should be 0xF0F0F0F0
    sw t2, 0(s2)

    # Test 2: Simple SLLI by 4
    li t0, 0x11111111
    slli t1, t0, 4           # Should be 0x11111110
    sw t1, 4(s2)

    # Test 3: All bits set, then SLLI by 4
    li t0, -1                # 0xFFFFFFFF
    slli t1, t0, 4           # Should be 0xFFFFFFF0
    sw t1, 8(s2)

    # Test 4: Pattern 0x0F0F0F0F (from mask) shifted by 4
    lui t0, 0x0F0F0
    addi t1, x0, 0x0F0
    slli t1, t1, 4
    addi t1, t1, 0x0F
    or t0, t0, t1             # t0 = 0x0F0F0F0F
    slli t1, t0, 4            # Should be 0xF0F0F0F0
    sw t1, 12(s2)

    # Marker
    li t0, 0xC0FFEE00
    sw t0, 16(s2)

    li a0, 0x12345678
    csrw 0x7C1, a0

_done:
    j _done
