# TERNLOG Simple Test - 2-source + 8-bit immediate version
# Third input to LUT is constant 0

.section .text
.globl _start

_start:
    # Initialize test values
    li x1, 0xAAAAAAAA  # x1 = 10101010...
    li x2, 0xCCCCCCCC  # x2 = 11001100...

    # Test 1: imm8=0xF0 - Copy A
    # For c=0: imm8[{a,b,0}] = imm8[{a,b,0}]
    #   a=0,b=0 -> imm8[0] = 0
    #   a=0,b=1 -> imm8[2] = 0
    #   a=1,b=0 -> imm8[4] = 1
    #   a=1,b=1 -> imm8[6] = 1
    # Expected: 0xAAAAAAAA (copy of x1)
    .word 0xF420857B  # ternlog x10, x1, x2, 0xF0

    # Test 2: imm8=0xCC - Copy B
    # For c=0: bits [0,2,4,6] = [0,1,0,1]
    # Expected: 0xCCCCCCCC (copy of x2)
    .word 0xCC20C5FB  # ternlog x11, x1, x2, 0xCC

    # Test 3: imm8=0x88 - AND
    # For c=0: bits [0,2,4,6] = [0,0,0,1]
    # a=0,b=0->0, a=0,b=1->0, a=1,b=0->0, a=1,b=1->1
    # Expected: 0x88888888 (a AND b)
    .word 0x8C2086FB  # ternlog x12, x1, x2, 0x88

    # Store results (use address after program code)
    li x31, 0x80001000
    sw x10, 0(x31)
    sw x11, 4(x31)
    sw x12, 8(x31)

    # Exit
    li x30, 0
    csrw 0x8b2, x30

end_loop:
    j end_loop
