##############################################################################
# Test SLLI by 16 - check if specific bits are corrupted
##############################################################################

.section .text
.globl _start

_start:
    lui sp, 0x80010
    lui s2, 0x80009

    # Test 1: SLLI 0x0000FFFF by 16
    lui t0, 0
    addi t0, t0, -1          # t0 = 0xFFFFFFFF
    lui t1, 0xFFFF
    addi t1, t1, -1          # t1 = 0x0000FFFF
    and t0, t0, t1           # t0 = 0x0000FFFF
    slli t2, t0, 16          # Should be 0xFFFF0000
    sw t2, 0(s2)

    # Test 2: SLLI 0x00001111 by 16
    li t0, 0x1111
    slli t1, t0, 16          # Should be 0x11110000
    sw t1, 4(s2)

    # Test 3: SLLI 0x0000AAAA by 16
    lui t0, 1
    addi t0, t0, -0x556      # 0x0000AAAA
    slli t1, t0, 16          # Should be 0xAAAA0000
    sw t1, 8(s2)

    # Test 4: SLLI all ones by 16
    li t0, -1                # 0xFFFFFFFF
    lui t1, 0xFFFF
    addi t1, t1, -1          # 0x0000FFFF
    and t0, t0, t1           # t0 = 0x0000FFFF
    slli t0, t0, 16          # Should be 0xFFFF0000
    sw t0, 12(s2)

    # Marker
    li t0, 0xC0FFEE00
    sw t0, 16(s2)

    li a0, 0x12345678
    csrw 0x7C1, a0

_done:
    j _done
