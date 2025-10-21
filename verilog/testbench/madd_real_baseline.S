# MADD Performance Test - BASELINE (using MUL+ADD)
# Tests real-world multiply-add workloads without MADD instruction
# Benchmarks: Dot product, polynomial evaluation, FIR filter, weighted sum

.section .text
.globl _start

_start:
    # Initialize result storage pointer
    lui x31, 0x80009        # x31 = 0x80009000 (result storage)
    li x30, 0               # x30 = result index

    #================================================================
    # TEST 1: Dot Product (8 elements)
    # v1 = [1, 2, 3, 4, 5, 6, 7, 8]
    # v2 = [8, 7, 6, 5, 4, 3, 2, 1]
    # result = 1*8 + 2*7 + 3*6 + 4*5 + 5*4 + 6*3 + 7*2 + 8*1
    #        = 8 + 14 + 18 + 20 + 20 + 18 + 14 + 8 = 120
    #================================================================
dot_product:
    li x10, 0               # accumulator = 0

    # Element 1: 1 * 8
    li x1, 1
    li x2, 8
    mul x3, x1, x2          # x3 = 1 * 8 = 8
    add x10, x10, x3        # acc += 8

    # Element 2: 2 * 7
    li x1, 2
    li x2, 7
    mul x3, x1, x2          # x3 = 2 * 7 = 14
    add x10, x10, x3        # acc += 14

    # Element 3: 3 * 6
    li x1, 3
    li x2, 6
    mul x3, x1, x2          # x3 = 3 * 6 = 18
    add x10, x10, x3        # acc += 18

    # Element 4: 4 * 5
    li x1, 4
    li x2, 5
    mul x3, x1, x2          # x3 = 4 * 5 = 20
    add x10, x10, x3        # acc += 20

    # Element 5: 5 * 4
    li x1, 5
    li x2, 4
    mul x3, x1, x2          # x3 = 5 * 4 = 20
    add x10, x10, x3        # acc += 20

    # Element 6: 6 * 3
    li x1, 6
    li x2, 3
    mul x3, x1, x2          # x3 = 6 * 3 = 18
    add x10, x10, x3        # acc += 18

    # Element 7: 7 * 2
    li x1, 7
    li x2, 2
    mul x3, x1, x2          # x3 = 7 * 2 = 14
    add x10, x10, x3        # acc += 14

    # Element 8: 8 * 1
    li x1, 8
    li x2, 1
    mul x3, x1, x2          # x3 = 8 * 1 = 8
    add x10, x10, x3        # acc += 8

    # Store result (120)
    slli x29, x30, 2
    add x29, x29, x31
    sw x10, 0(x29)
    addi x30, x30, 1

    #================================================================
    # TEST 2: Polynomial Evaluation using Horner's method
    # P(x) = 3x^3 + 2x^2 + 5x + 7  where x = 4
    # Horner: ((3*x + 2)*x + 5)*x + 7
    #       = ((3*4 + 2)*4 + 5)*4 + 7
    #       = ((12 + 2)*4 + 5)*4 + 7
    #       = (14*4 + 5)*4 + 7
    #       = (56 + 5)*4 + 7
    #       = 61*4 + 7
    #       = 244 + 7 = 251
    #================================================================
polynomial:
    li x1, 4                # x = 4
    li x10, 3               # coeff a3 = 3

    # Step 1: 3*4 + 2
    mul x3, x10, x1         # x3 = 3 * 4 = 12
    li x2, 2
    add x10, x3, x2         # x10 = 12 + 2 = 14

    # Step 2: 14*4 + 5
    mul x3, x10, x1         # x3 = 14 * 4 = 56
    li x2, 5
    add x10, x3, x2         # x10 = 56 + 5 = 61

    # Step 3: 61*4 + 7
    mul x3, x10, x1         # x3 = 61 * 4 = 244
    li x2, 7
    add x10, x3, x2         # x10 = 244 + 7 = 251

    # Store result (251)
    slli x29, x30, 2
    add x29, x29, x31
    sw x10, 0(x29)
    addi x30, x30, 1

    #================================================================
    # TEST 3: 4-tap FIR Filter
    # Input samples: [10, 20, 30, 40]
    # Coefficients:  [1, 2, 3, 4]
    # Output = 1*10 + 2*20 + 3*30 + 4*40
    #        = 10 + 40 + 90 + 160 = 300
    #================================================================
fir_filter:
    li x10, 0               # accumulator = 0

    # Tap 1: 1 * 10
    li x1, 1
    li x2, 10
    mul x3, x1, x2
    add x10, x10, x3

    # Tap 2: 2 * 20
    li x1, 2
    li x2, 20
    mul x3, x1, x2
    add x10, x10, x3

    # Tap 3: 3 * 30
    li x1, 3
    li x2, 30
    mul x3, x1, x2
    add x10, x10, x3

    # Tap 4: 4 * 40
    li x1, 4
    li x2, 40
    mul x3, x1, x2
    add x10, x10, x3

    # Store result (300)
    slli x29, x30, 2
    add x29, x29, x31
    sw x10, 0(x29)
    addi x30, x30, 1

    #================================================================
    # TEST 4: Weighted Sum (6 values)
    # Values:  [100, 200, 150, 300, 250, 180]
    # Weights: [1, 2, 1, 3, 2, 1]
    # Result = 1*100 + 2*200 + 1*150 + 3*300 + 2*250 + 1*180
    #        = 100 + 400 + 150 + 900 + 500 + 180 = 2230
    #================================================================
weighted_sum:
    li x10, 0               # accumulator = 0

    # Value 1: 1 * 100
    li x1, 1
    li x2, 100
    mul x3, x1, x2
    add x10, x10, x3

    # Value 2: 2 * 200
    li x1, 2
    li x2, 200
    mul x3, x1, x2
    add x10, x10, x3

    # Value 3: 1 * 150
    li x1, 1
    li x2, 150
    mul x3, x1, x2
    add x10, x10, x3

    # Value 4: 3 * 300
    li x1, 3
    li x2, 300
    mul x3, x1, x2
    add x10, x10, x3

    # Value 5: 2 * 250
    li x1, 2
    li x2, 250
    mul x3, x1, x2
    add x10, x10, x3

    # Value 6: 1 * 180
    li x1, 1
    li x2, 180
    mul x3, x1, x2
    add x10, x10, x3

    # Store result (2230)
    slli x29, x30, 2
    add x29, x29, x31
    sw x10, 0(x29)
    addi x30, x30, 1

    #================================================================
    # TEST 5: Matrix-Vector Multiplication (3x3 matrix * 3x1 vector)
    # Matrix M = [[2, 3, 4],
    #             [5, 6, 7],
    #             [8, 9, 1]]
    # Vector v = [10, 20, 30]
    # Result = [2*10 + 3*20 + 4*30,  = 200
    #           5*10 + 6*20 + 7*30,  = 380
    #           8*10 + 9*20 + 1*30]  = 290
    #================================================================
matrix_vector:
    # Row 1: 2*10 + 3*20 + 4*30 = 200
    li x10, 0
    li x1, 2
    li x2, 10
    mul x3, x1, x2
    add x10, x10, x3

    li x1, 3
    li x2, 20
    mul x3, x1, x2
    add x10, x10, x3

    li x1, 4
    li x2, 30
    mul x3, x1, x2
    add x10, x10, x3

    # Store row 1 result (200)
    slli x29, x30, 2
    add x29, x29, x31
    sw x10, 0(x29)
    addi x30, x30, 1

    # Row 2: 5*10 + 6*20 + 7*30 = 380
    li x10, 0
    li x1, 5
    li x2, 10
    mul x3, x1, x2
    add x10, x10, x3

    li x1, 6
    li x2, 20
    mul x3, x1, x2
    add x10, x10, x3

    li x1, 7
    li x2, 30
    mul x3, x1, x2
    add x10, x10, x3

    # Store row 2 result (380)
    slli x29, x30, 2
    add x29, x29, x31
    sw x10, 0(x29)
    addi x30, x30, 1

    # Row 3: 8*10 + 9*20 + 1*30 = 290
    li x10, 0
    li x1, 8
    li x2, 10
    mul x3, x1, x2
    add x10, x10, x3

    li x1, 9
    li x2, 20
    mul x3, x1, x2
    add x10, x10, x3

    li x1, 1
    li x2, 30
    mul x3, x1, x2
    add x10, x10, x3

    # Store row 3 result (290)
    slli x29, x30, 2
    add x29, x29, x31
    sw x10, 0(x29)
    addi x30, x30, 1

    # Signal completion
    li x28, 1
    csrw 0x8B2, x28

end_loop:
    j end_loop
