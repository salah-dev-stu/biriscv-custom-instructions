# MADD Performance Test - OPTIMIZED (using MADD instruction)
# Tests real-world multiply-add workloads with hardware MADD
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

    # Element 1: madd x10, 1, 8, x10 = (1 * 8) + 0 = 8
    li x1, 1
    li x2, 8
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Element 2: madd x10, 2, 7, x10 = (2 * 7) + 8 = 22
    li x1, 2
    li x2, 7
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Element 3: madd x10, 3, 6, x10 = (3 * 6) + 22 = 40
    li x1, 3
    li x2, 6
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Element 4: madd x10, 4, 5, x10 = (4 * 5) + 40 = 60
    li x1, 4
    li x2, 5
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Element 5: madd x10, 5, 4, x10 = (5 * 4) + 60 = 80
    li x1, 5
    li x2, 4
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Element 6: madd x10, 6, 3, x10 = (6 * 3) + 80 = 98
    li x1, 6
    li x2, 3
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Element 7: madd x10, 7, 2, x10 = (7 * 2) + 98 = 112
    li x1, 7
    li x2, 2
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Element 8: madd x10, 8, 1, x10 = (8 * 1) + 112 = 120
    li x1, 8
    li x2, 1
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Store result (120)
    slli x29, x30, 2
    add x29, x29, x31
    sw x10, 0(x29)
    addi x30, x30, 1

    #================================================================
    # TEST 2: Polynomial Evaluation using Horner's method
    # P(x) = 3x^3 + 2x^2 + 5x + 7  where x = 4
    # Horner: ((3*x + 2)*x + 5)*x + 7
    #       = ((3*4 + 2)*4 + 5)*4 + 7 = 251
    #================================================================
polynomial:
    li x1, 4                # x = 4
    li x10, 3               # coeff a3 = 3

    # Step 1: madd x10, 3, 4, 2 = (3 * 4) + 2 = 14
    li x2, 2
    .word 0x1215057B        # madd x10, x10, x1, x2

    # Step 2: madd x10, 14, 4, 5 = (14 * 4) + 5 = 61
    li x2, 5
    .word 0x1215057B        # madd x10, x10, x1, x2

    # Step 3: madd x10, 61, 4, 7 = (61 * 4) + 7 = 251
    li x2, 7
    .word 0x1215057B        # madd x10, x10, x1, x2

    # Store result (251)
    slli x29, x30, 2
    add x29, x29, x31
    sw x10, 0(x29)
    addi x30, x30, 1

    #================================================================
    # TEST 3: 4-tap FIR Filter
    # Input samples: [10, 20, 30, 40]
    # Coefficients:  [1, 2, 3, 4]
    # Output = 1*10 + 2*20 + 3*30 + 4*40 = 300
    #================================================================
fir_filter:
    li x10, 0               # accumulator = 0

    # Tap 1: madd x10, 1, 10, x10 = (1 * 10) + 0 = 10
    li x1, 1
    li x2, 10
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Tap 2: madd x10, 2, 20, x10 = (2 * 20) + 10 = 50
    li x1, 2
    li x2, 20
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Tap 3: madd x10, 3, 30, x10 = (3 * 30) + 50 = 140
    li x1, 3
    li x2, 30
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Tap 4: madd x10, 4, 40, x10 = (4 * 40) + 140 = 300
    li x1, 4
    li x2, 40
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Store result (300)
    slli x29, x30, 2
    add x29, x29, x31
    sw x10, 0(x29)
    addi x30, x30, 1

    #================================================================
    # TEST 4: Weighted Sum (6 values)
    # Values:  [100, 200, 150, 300, 250, 180]
    # Weights: [1, 2, 1, 3, 2, 1]
    # Result = 1*100 + 2*200 + 1*150 + 3*300 + 2*250 + 1*180 = 2230
    #================================================================
weighted_sum:
    li x10, 0               # accumulator = 0

    # Value 1: madd x10, 1, 100, x10
    li x1, 1
    li x2, 100
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Value 2: madd x10, 2, 200, x10
    li x1, 2
    li x2, 200
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Value 3: madd x10, 1, 150, x10
    li x1, 1
    li x2, 150
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Value 4: madd x10, 3, 300, x10
    li x1, 3
    li x2, 300
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Value 5: madd x10, 2, 250, x10
    li x1, 2
    li x2, 250
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Value 6: madd x10, 1, 180, x10
    li x1, 1
    li x2, 180
    .word 0x5220857B        # madd x10, x1, x2, x10

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
    # Result = [200, 380, 290]
    #================================================================
matrix_vector:
    # Row 1: 2*10 + 3*20 + 4*30 = 200
    li x10, 0

    li x1, 2
    li x2, 10
    .word 0x5220857B        # madd x10, x1, x2, x10

    li x1, 3
    li x2, 20
    .word 0x5220857B        # madd x10, x1, x2, x10

    li x1, 4
    li x2, 30
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Store row 1 result (200)
    slli x29, x30, 2
    add x29, x29, x31
    sw x10, 0(x29)
    addi x30, x30, 1

    # Row 2: 5*10 + 6*20 + 7*30 = 380
    li x10, 0

    li x1, 5
    li x2, 10
    .word 0x5220857B        # madd x10, x1, x2, x10

    li x1, 6
    li x2, 20
    .word 0x5220857B        # madd x10, x1, x2, x10

    li x1, 7
    li x2, 30
    .word 0x5220857B        # madd x10, x1, x2, x10

    # Store row 2 result (380)
    slli x29, x30, 2
    add x29, x29, x31
    sw x10, 0(x29)
    addi x30, x30, 1

    # Row 3: 8*10 + 9*20 + 1*30 = 290
    li x10, 0

    li x1, 8
    li x2, 10
    .word 0x5220857B        # madd x10, x1, x2, x10

    li x1, 9
    li x2, 20
    .word 0x5220857B        # madd x10, x1, x2, x10

    li x1, 1
    li x2, 30
    .word 0x5220857B        # madd x10, x1, x2, x10

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
