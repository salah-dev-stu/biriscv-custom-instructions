##############################################################################
# Test shift operations to verify SRLI bug
##############################################################################

.section .text
.globl _start

_start:
    lui sp, 0x80010
    lui s2, 0x80009

    # Test 1: SRLI with small shift
    lui a0, 0x12345
    addi a0, a0, 0x678          # 0x12345678
    srli a0, a0, 4              # Should be 0x01234567
    sw a0, 0(s2)

    # Test 2: SRLI with medium shift
    lui a0, 0xABCDE
    addi a0, a0, -0x123         # 0xABCDDEDD (approximately)
    srli a0, a0, 16             # Upper 16 bits
    sw a0, 4(s2)

    # Test 3: SRLI by 31 (the failing case)
    lui a0, 0x80000             # 0x80000000
    srli a0, a0, 31             # Should be 0x00000001
    sw a0, 8(s2)

    # Test 4: SRLI by 1
    li a0, -1                    # 0xFFFFFFFF
    srli a0, a0, 1              # Should be 0x7FFFFFFF
    sw a0, 12(s2)

    # Test 5: SRL (register version) by 31
    lui a0, 0x80000
    li a1, 31
    srl a0, a0, a1              # Should be 0x00000001
    sw a0, 16(s2)

    # Test 6: SLLI then SRLI
    li a0, 1
    slli a0, a0, 31             # 0x80000000
    srli a0, a0, 31             # Should be 0x00000001
    sw a0, 20(s2)

    # Marker
    li a0, 0xC0FFEE00
    sw a0, 24(s2)

    li a0, 0x12345678
    csrw 0x7C1, a0

_done:
    j _done
