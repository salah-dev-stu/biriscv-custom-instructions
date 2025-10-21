// Test MADD pattern recognition with unsigned (zero-extended) types
#include <stdint.h>

// Test with unsigned 16-bit integers
int32_t test_madd_ushort(uint16_t a, uint16_t b, int32_t c) {
    // Should generate MADD with zero-extended operands
    return a * b + c;
}

// Test with unsigned 8-bit integers
int32_t test_madd_uchar(uint8_t a, uint8_t b, int32_t c) {
    // Should generate MADD with zero-extended operands
    return a * b + c;
}

// Test with unsigned 16-bit in array processing
int32_t dot_product_ushort(uint16_t *vec1, uint16_t *vec2, int len) {
    int32_t sum = 0;
    for (int i = 0; i < len; i++) {
        sum += vec1[i] * vec2[i];  // Each iteration should use MADD
    }
    return sum;
}

// Test with unsigned 8-bit in array processing
int32_t dot_product_uchar(uint8_t *vec1, uint8_t *vec2, int len) {
    int32_t sum = 0;
    for (int i = 0; i < len; i++) {
        sum += vec1[i] * vec2[i];  // Each iteration should use MADD
    }
    return sum;
}

// Mixed: unsigned 16-bit multiply with existing accumulator
int32_t accumulate_ushort(int32_t accumulator, uint16_t x, uint16_t y) {
    return accumulator + x * y;  // Commuted form
}
