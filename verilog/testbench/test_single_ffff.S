##############################################################################
# Minimal test - reverse 0xFFFFFFFF only
##############################################################################

.section .text
.globl _start

_start:
    lui sp, 0x80010
    lui s2, 0x80009

    # Test ONLY 0xFFFFFFFF
    li a0, -1                # 0xFFFFFFFF
    jal ra, reverse_bits_software
    sw a0, 0(s2)

    # Marker
    li a0, 0xC0FFEE00
    sw a0, 4(s2)

    li a0, 0x12345678
    csrw 0x7C1, a0

_done:
    j _done


##############################################################################
# Software Bit Reverse Function
##############################################################################
reverse_bits_software:
    addi sp, sp, -20
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw t3, 12(sp)
    sw t4, 16(sp)

    mv t0, a0

    # Stage 1: Swap 16-bit halves
    srli t1, t0, 16
    lui t2, 0xFFFF
    addi t2, t2, -1
    and t1, t1, t2
    and t3, t0, t2
    slli t3, t3, 16
    or t0, t1, t3

    # Stage 2: Swap bytes
    srli t1, t0, 8
    lui t2, 0x00FF0
    addi t2, t2, 0xFF
    and t1, t1, t2
    and t3, t0, t2
    slli t3, t3, 8
    or t0, t1, t3

    # Stage 3: Swap nibbles
    srli t1, t0, 4
    lui t2, 0x0F0F0
    addi t3, x0, 0x0F0
    slli t3, t3, 4
    addi t3, t3, 0x0F
    or t2, t2, t3
    and t1, t1, t2
    and t3, t0, t2
    slli t3, t3, 4
    or t0, t1, t3

    # Stage 4: Swap 2-bit pairs
    srli t1, t0, 2
    lui t2, 0x33333
    addi t3, x0, 0x333
    or t2, t2, t3
    and t1, t1, t2
    and t3, t0, t2
    slli t3, t3, 2
    or t0, t1, t3

    # Stage 5: Swap individual bits
    srli t1, t0, 1
    lui t2, 0x55555
    addi t3, x0, 0x555
    or t2, t2, t3
    and t1, t1, t2
    and t3, t0, t2
    slli t3, t3, 1
    or t0, t1, t3

    mv a0, t0

    lw t4, 16(sp)
    lw t3, 12(sp)
    lw t2, 8(sp)
    lw t1, 4(sp)
    lw t0, 0(sp)
    addi sp, sp, 20
    ret
