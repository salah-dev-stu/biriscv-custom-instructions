# CSEL Instruction Test Program
# Tests the custom CSEL (Conditional Select) instruction
# Operation: rd = (rs3 == 0) ? rs1 : rs2

.section .text
.globl _start

_start:
    # Initialize test values in registers
    li x1, 0x1111      # x1 = 0x1111 (value to select when rs3 == 0)
    li x2, 0x2222      # x2 = 0x2222 (value to select when rs3 != 0)
    li x3, 0           # x3 = 0      (condition register, zero)
    li x4, 1           # x4 = 1      (condition register, non-zero)
    li x5, 100         # x5 = 100    (another non-zero value)

    # Test 1: CSEL with rs3 = 0 (should select rs1)
    # csel x10, x1, x2, x3
    # Expected: x10 = 0x1111 (because x3 == 0)
    .word 0x1820857B   # Encoding: rs3=x3, rs2=x2, rs1=x1, rd=x10

    # Test 2: CSEL with rs3 != 0 (should select rs2)
    # csel x11, x1, x2, x4
    # Expected: x11 = 0x2222 (because x4 != 0)
    .word 0x202085FB   # Encoding: rs3=x4, rs2=x2, rs1=x1, rd=x11

    # Test 3: CSEL with larger non-zero rs3
    # csel x12, x1, x2, x5
    # Expected: x12 = 0x2222 (because x5 != 0)
    .word 0x2820867B   # Encoding: rs3=x5, rs2=x2, rs1=x1, rd=x12

    # Test 4: CSEL with same source registers
    # csel x13, x1, x1, x3
    # Expected: x13 = 0x1111 (x3 == 0, selects x1)
    .word 0x181086FB   # Encoding: rs3=x3, rs2=x1, rs1=x1, rd=x13

    # Test 5: CSEL with same source registers, non-zero condition
    # csel x14, x2, x2, x4
    # Expected: x14 = 0x2222 (x4 != 0, selects x2)
    .word 0x2021077B   # Encoding: rs3=x4, rs2=x2, rs1=x2, rd=x14

    # Test 6: CSEL selecting zero register
    # csel x15, x0, x1, x3
    # Expected: x15 = 0x0000 (x3 == 0, selects x0 which is always 0)
    .word 0x181007FB   # Encoding: rs3=x3, rs2=x1, rs1=x0, rd=x15

    # Test 7: CSEL selecting zero register with non-zero condition
    # csel x16, x0, x1, x4
    # Expected: x16 = 0x1111 (x4 != 0, selects x1)
    .word 0x2010087B   # Encoding: rs3=x4, rs2=x1, rs1=x0, rd=x16

    # Verification: Store results to memory for inspection
    li x20, 0x80000000  # Base address for result storage
    sw x10, 0(x20)      # Store test 1 result
    sw x11, 4(x20)      # Store test 2 result
    sw x12, 8(x20)      # Store test 3 result
    sw x13, 12(x20)     # Store test 4 result
    sw x14, 16(x20)     # Store test 5 result
    sw x15, 20(x20)     # Store test 6 result
    sw x16, 24(x20)     # Store test 7 result

    # Exit simulation (write to CSR_SIM_CTRL)
    li x17, 0x00000000  # Exit code 0
    csrw 0x8b2, x17     # Write to CSR_SIM_CTRL to exit

    # Loop forever (in case CSR write doesn't exit)
end_loop:
    j end_loop

.section .data
# No data section needed for this test
