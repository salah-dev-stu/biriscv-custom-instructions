// Test nested/chained MADD patterns
#include <stdint.h>

// Polynomial evaluation: ax^2 + bx + c
// This should generate TWO MADD instructions
int32_t polynomial_quadratic(int32_t x, int32_t a, int32_t b, int32_t c) {
    // Step 1: a*x + b  (MADD)
    // Step 2: (a*x + b)*x + c  (MADD)
    return (a * x + b) * x + c;
}

// Polynomial evaluation: ax^3 + bx^2 + cx + d
// This should generate THREE MADD instructions
int32_t polynomial_cubic(int32_t x, int32_t a, int32_t b, int32_t c, int32_t d) {
    // Step 1: a*x + b  (MADD)
    // Step 2: (a*x + b)*x + c  (MADD)
    // Step 3: ((a*x + b)*x + c)*x + d  (MADD)
    return ((a * x + b) * x + c) * x + d;
}

// Horner's method for polynomial: a*x^2 + b*x + c
int32_t horner_quadratic(int32_t x, int32_t a, int32_t b, int32_t c) {
    int32_t temp = a * x + b;    // MADD
    return temp * x + c;          // MADD
}

// Multiple independent MADD operations
int32_t multiple_madd(int32_t a, int32_t b, int32_t c, int32_t d, int32_t e, int32_t f) {
    int32_t r1 = a * b + c;  // MADD
    int32_t r2 = d * e + f;  // MADD
    return r1 + r2;
}

// Chained accumulation (dot product style)
int32_t accumulate_chain(int32_t a1, int32_t b1, int32_t a2, int32_t b2, int32_t a3, int32_t b3) {
    int32_t sum = 0;
    sum = a1 * b1 + sum;  // MADD
    sum = a2 * b2 + sum;  // MADD
    sum = a3 * b3 + sum;  // MADD
    return sum;
}

// Nested with different types
int32_t nested_mixed(int16_t a, int16_t b, int32_t c, int32_t d) {
    // First: a*b + c  (MADD with sign-extend)
    // Second: result * d + something
    int32_t temp = a * b + c;
    return temp * d + 100;
}

// Matrix multiply-add pattern: C = A*B + C
// C[0] += A[0] * B[0]
// C[0] += A[1] * B[1]
int32_t matrix_mac_element(int32_t *A, int32_t *B, int32_t C) {
    C += A[0] * B[0];  // MADD
    C += A[1] * B[1];  // MADD
    C += A[2] * B[2];  // MADD
    return C;
}

// Complex expression with multiple MADD opportunities
int32_t complex_expr(int32_t a, int32_t b, int32_t c, int32_t d, int32_t e) {
    // (a*b + c) + (d*e + 10)
    // Should generate 2 MADD operations
    return (a * b + c) + (d * e + 10);
}

// FIR filter tap (very common in DSP)
int32_t fir_tap_3(int32_t x0, int32_t x1, int32_t x2, int32_t h0, int32_t h1, int32_t h2) {
    int32_t acc = 0;
    acc += x0 * h0;  // MADD (first iteration, acc=0)
    acc += x1 * h1;  // MADD
    acc += x2 * h2;  // MADD
    return acc;
}
