# CMOV Instruction Test Program
# Tests the custom CMOV (Conditional Move) instruction
# Operation: rd = (rs3 != 0) ? rs1 : rs2

.section .text
.globl _start

_start:
    # Initialize test values in registers
    li x1, 0x1111      # x1 = 0x1111 (value to select when rs3 != 0)
    li x2, 0x2222      # x2 = 0x2222 (value to select when rs3 == 0)
    li x3, 0           # x3 = 0      (condition register, zero)
    li x4, 1           # x4 = 1      (condition register, non-zero)
    li x5, 100         # x5 = 100    (another non-zero value)

    # Test 1: CMOV with rs3 = 0 (should select rs2)
    # cmov x10, x1, x2, x3
    # Expected: x10 = 0x2222 (because x3 == 0)
    # Encoding: rs3=x3[31:27], funct2=11[26:25], rs2=x2[24:20], rs1=x1[19:15], funct3=001[14:12], rd=x10[11:7], opcode=0x7B[6:0]
    .word 0x1E20957B

    # Test 2: CMOV with rs3 != 0 (should select rs1)
    # cmov x11, x1, x2, x4
    # Expected: x11 = 0x1111 (because x4 != 0)
    .word 0x262095FB

    # Test 3: CMOV with larger non-zero rs3
    # cmov x12, x1, x2, x5
    # Expected: x12 = 0x1111 (because x5 != 0)
    .word 0x2E20967B

    # Test 4: CMOV with same source registers, zero condition
    # cmov x13, x1, x1, x3
    # Expected: x13 = 0x1111 (x3 == 0, selects x1 from rs2)
    .word 0x1E1096FB

    # Test 5: CMOV with same source registers, non-zero condition
    # cmov x14, x2, x2, x4
    # Expected: x14 = 0x2222 (x4 != 0, selects x2 from rs1)
    .word 0x2621077B

    # Test 6: CMOV selecting from zero register (rs1=x0), zero condition
    # cmov x15, x0, x1, x3
    # Expected: x15 = 0x1111 (x3 == 0, selects x1 from rs2)
    .word 0x1E1017FB

    # Test 7: CMOV selecting from zero register (rs1=x0), non-zero condition
    # cmov x16, x0, x1, x4
    # Expected: x16 = 0x0000 (x4 != 0, selects x0 from rs1)
    .word 0x2610187B

    # Test 8: CMOV with negative condition value
    # cmov x17, x1, x2, x6
    li x6, -1          # x6 = -1 (0xFFFFFFFF, non-zero)
    # Expected: x17 = 0x1111 (x6 != 0, selects x1)
    .word 0x362098FB

    # Test 9: CMOV selecting to x0 (should have no effect)
    # cmov x0, x1, x2, x4
    # Expected: x0 = 0x0000 (x0 is hardwired to zero)
    .word 0x2620107B

    # Test 10: Chain of CMOVs to test data dependencies
    li x7, 0x3333
    li x8, 0x4444
    li x9, 1
    # cmov x18, x7, x8, x9  -> x18 = 0x3333
    .word 0x4E83997B
    # cmov x19, x18, x8, x3 -> x19 = 0x4444 (uses result from previous CMOV)
    .word 0x1E891DFB

    # Verification: Store results to memory for inspection
    li x20, 0x80000000  # Base address for result storage
    sw x10, 0(x20)      # Store test 1 result
    sw x11, 4(x20)      # Store test 2 result
    sw x12, 8(x20)      # Store test 3 result
    sw x13, 12(x20)     # Store test 4 result
    sw x14, 16(x20)     # Store test 5 result
    sw x15, 20(x20)     # Store test 6 result
    sw x16, 24(x20)     # Store test 7 result
    sw x17, 28(x20)     # Store test 8 result
    sw x18, 32(x20)     # Store test 9 result
    sw x19, 36(x20)     # Store test 10 result

    # Print test summary marker
    li x21, 0xC0DE000D  # Success marker
    sw x21, 40(x20)

    # Exit simulation (write to CSR_SIM_CTRL)
    li x17, 0x00000000  # Exit code 0
    csrw 0x8b2, x17     # Write to CSR_SIM_CTRL to exit

    # Loop forever (in case CSR write doesn't exit)
end_loop:
    j end_loop

.section .data
# No data section needed for this test
