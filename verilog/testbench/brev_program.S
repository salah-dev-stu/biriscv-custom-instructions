##############################################################################
# BREV Test Program (HARDWARE BIT REVERSAL)
#
# This program reverses bits using the BREV custom instruction
# Single instruction per reversal
# For performance comparison with software bit reversal baseline
##############################################################################

.section .text
.globl _start

_start:
    # Initialize stack pointer
    lui sp, 0x80010          # SP = 0x80010000

    # Test bit reversal using BREV instruction
    jal ra, test_bit_reverse_brev

    # Finish - write to CSR to signal completion
    li a0, 0x12345678        # Success marker
    csrw 0x7C1, a0

_done:
    j _done                   # Infinite loop


##############################################################################
# Test: Reverse multiple values using BREV instruction
##############################################################################
test_bit_reverse_brev:
    addi sp, sp, -12
    sw ra, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    # Result storage base address
    lui s2, 0x80009

    # Test 1: 0x00000000
    li x5, 0x00000000
    .word 0x2002C57B        # brev x10, x5
    sw x10, 0(s2)

    # Test 2: 0xFFFFFFFF
    li x6, -1               # 0xFFFFFFFF
    .word 0x200345FB        # brev x11, x6
    sw x11, 4(s2)

    # Test 3: 0x55555555 (alternating 01...)
    lui x7, 0x55555
    addi x7, x7, 0x555
    .word 0x2003C67B        # brev x12, x7
    sw x12, 8(s2)

    # Test 4: 0xAAAAAAAA (alternating 10...)
    lui x8, 0xAAAAB
    addi x8, x8, -0x556     # 0xAAAAB000 - 0x556 = 0xAAAAAAAA
    .word 0x200446FB        # brev x13, x8
    sw x13, 12(s2)

    # Test 5: 0x0000000F
    li x9, 0x0F
    .word 0x2004C77B        # brev x14, x9
    sw x14, 16(s2)

    # Test 6: 0xF0000000
    lui x15, 0xF0000
    .word 0x2007C7FB        # brev x15, x15
    sw x15, 20(s2)

    # Test 7: 0x00000001 (LSB set)
    li x16, 0x01
    .word 0x0008083B        # brev x16, x16
    sw x16, 24(s2)

    # Test 8: 0x80000000 (MSB set)
    lui x17, 0x80000
    .word 0x2008C8FB        # brev x17, x17
    sw x17, 28(s2)

    # Test 9: 0x12345678
    lui x21, 0x12345
    addi x21, x21, 0x678
    .word 0x200ACB7B        # brev x22, x21
    sw x22, 32(s2)

    # Test 10: 0xDEADBEEF
    lui x23, 0xDEADC
    addi x23, x23, -0x111   # 0xDEADC000 - 0x111 = 0xDEADBEEF
    .word 0x200BCC7B        # brev x24, x23
    sw x24, 36(s2)

    # Add completion marker
    lui x25, 0x0BEEF
    addi x25, x25, 0x00D    # Marker for BREV completion (0x0BEEF00D)
    sw x25, 40(s2)

    lw s2, 0(sp)
    lw s1, 4(sp)
    lw ra, 8(sp)
    addi sp, sp, 12
    ret
