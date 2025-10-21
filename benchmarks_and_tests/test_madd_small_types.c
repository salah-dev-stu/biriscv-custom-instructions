// Test MADD pattern recognition with smaller data types
#include <stdint.h>

// Test with 16-bit signed integers (short)
int32_t test_madd_short(short a, short b, int32_t c) {
    // Should generate MADD with sign-extended operands
    return a * b + c;
}

// Test with 8-bit signed integers (char)
int32_t test_madd_char(int8_t a, int8_t b, int32_t c) {
    // Should generate MADD with sign-extended operands
    return a * b + c;
}

// Test with 16-bit in array processing
int32_t dot_product_short(short *vec1, short *vec2, int len) {
    int32_t sum = 0;
    for (int i = 0; i < len; i++) {
        sum += vec1[i] * vec2[i];  // Each iteration should use MADD
    }
    return sum;
}

// Test with 8-bit in array processing
int32_t dot_product_char(int8_t *vec1, int8_t *vec2, int len) {
    int32_t sum = 0;
    for (int i = 0; i < len; i++) {
        sum += vec1[i] * vec2[i];  // Each iteration should use MADD
    }
    return sum;
}

// Mixed: 16-bit multiply with existing accumulator
int32_t accumulate_short(int32_t accumulator, short x, short y) {
    return accumulator + x * y;  // Commuted form
}
