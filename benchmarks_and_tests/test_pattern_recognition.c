// Test file for BiRiscV automatic pattern recognition
// This should generate MADD, CSEL, and CMOV instructions without using intrinsics

#include <stdint.h>

// Test 1: MADD pattern - multiply-add
int32_t test_madd_pattern(int32_t a, int32_t b, int32_t c) {
    // Should generate: MADD result, a, b, c
    return (a * b) + c;
}

// Test 2: MADD pattern - commuted (c + a*b)
int32_t test_madd_commuted(int32_t a, int32_t b, int32_t c) {
    // Should generate: MADD result, a, b, c
    return c + (a * b);
}

// Test 3: CSEL pattern - conditional select when cond == 0
int32_t test_csel_pattern(int32_t cond, int32_t val_if_zero, int32_t val_if_nonzero) {
    // Should generate: CSEL result, val_if_zero, val_if_nonzero, cond
    return (cond == 0) ? val_if_zero : val_if_nonzero;
}

// Test 4: CMOV pattern - conditional move when cond != 0
int32_t test_cmov_pattern(int32_t cond, int32_t val_if_nonzero, int32_t val_if_zero) {
    // Should generate: CMOV result, val_if_nonzero, val_if_zero, cond
    return (cond != 0) ? val_if_nonzero : val_if_zero;
}

// Test 5: Generic select - should use CMOV by default
int32_t test_select_generic(int32_t cond, int32_t true_val, int32_t false_val) {
    // Should generate: CMOV result, true_val, false_val, cond
    return cond ? true_val : false_val;
}

// Test 6: Absolute value using CSEL pattern
int32_t test_abs_csel(int32_t x) {
    // Should generate CSEL with sign test
    // if (x < 0) return -x; else return x;
    int32_t is_negative = (x < 0);
    return is_negative ? -x : x;
}

// Test 7: Min function using CSEL/CMOV
int32_t test_min(int32_t a, int32_t b) {
    // Should generate conditional select based on comparison
    return (a < b) ? a : b;
}

// Test 8: Max function using CSEL/CMOV
int32_t test_max(int32_t a, int32_t b) {
    // Should generate conditional select based on comparison
    return (a > b) ? a : b;
}

// Test 9: Combined pattern - MADD + CMOV
int32_t test_madd_cmov(int32_t a, int32_t b, int32_t c, int32_t cond, int32_t alternative) {
    // First: MADD to compute a*b+c
    int32_t product_sum = (a * b) + c;
    // Then: CMOV to select based on condition
    return cond ? product_sum : alternative;
}

// Test 10: Clamp function using multiple conditional selects
int32_t test_clamp(int32_t value, int32_t min, int32_t max) {
    // Should generate multiple CSEL/CMOV instructions
    if (value < min) return min;
    if (value > max) return max;
    return value;
}

// Test 11: Sign function (-1, 0, or 1)
int32_t test_sign(int32_t x) {
    // Should use CSEL/CMOV for conditional logic
    if (x > 0) return 1;
    if (x < 0) return -1;
    return 0;
}

// Test 12: Polynomial evaluation with MADD pattern
// Evaluate: ax^2 + bx + c using Horner's method: x(ax + b) + c
int32_t test_polynomial(int32_t a, int32_t b, int32_t c, int32_t x) {
    // First MADD: ax + b (but x*a + b)
    // Second MADD: (ax+b)*x + c
    int32_t temp = a * x + b;  // Should use MADD
    return temp * x + c;        // Should use MADD
}
