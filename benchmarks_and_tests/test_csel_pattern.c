// Test CSEL pattern recognition
#include <stdint.h>

// CSEL: rd = (rs3 == 0) ? rs1 : rs2

// Pattern 1: Direct comparison with zero (equals)
int32_t test_csel_eq_zero(int32_t cond, int32_t a, int32_t b) {
    return (cond == 0) ? a : b;
}

// Pattern 2: Direct comparison with zero (not equals)
int32_t test_csel_ne_zero(int32_t cond, int32_t a, int32_t b) {
    return (cond != 0) ? a : b;
}

// Pattern 3: Generic boolean condition
int32_t test_csel_generic(int32_t cond, int32_t a, int32_t b) {
    return cond ? a : b;
}

// Pattern 4: With zero as one of the values
int32_t test_csel_zero_true(int32_t cond, int32_t a) {
    return (cond == 0) ? a : 0;
}

int32_t test_csel_zero_false(int32_t cond, int32_t b) {
    return (cond == 0) ? 0 : b;
}

// Pattern 5: Comparison result
int32_t test_csel_comparison(int32_t x, int32_t y, int32_t a, int32_t b) {
    return (x == y) ? a : b;
}

// Pattern 6: Min/max using conditional select
int32_t min_csel(int32_t a, int32_t b) {
    return (a < b) ? a : b;
}

int32_t max_csel(int32_t a, int32_t b) {
    return (a > b) ? a : b;
}

// Pattern 7: Clamp to zero (ReLU-like)
int32_t clamp_to_zero(int32_t x) {
    return (x < 0) ? 0 : x;
}

// Pattern 8: Absolute value using select
int32_t abs_csel(int32_t x) {
    return (x < 0) ? -x : x;
}
