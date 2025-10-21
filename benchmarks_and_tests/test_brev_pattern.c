// Test BREV pattern recognition
#include <stdint.h>

// Test 1: Using __builtin_bitreverse32 (if available)
uint32_t test_builtin_bitreverse32(uint32_t x) {
    return __builtin_bitreverse32(x);
}

// Test 2: Using __builtin_bitreverse8
uint8_t test_builtin_bitreverse8(uint8_t x) {
    return __builtin_bitreverse8(x);
}

// Test 3: Manual bit reversal (common pattern in C)
uint32_t test_manual_bitreverse(uint32_t x) {
    uint32_t result = 0;
    for (int i = 0; i < 32; i++) {
        result = (result << 1) | (x & 1);
        x >>= 1;
    }
    return result;
}

// Test 4: Optimized manual reversal
uint32_t test_manual_optimized(uint32_t x) {
    x = ((x & 0xAAAAAAAA) >> 1) | ((x & 0x55555555) << 1);
    x = ((x & 0xCCCCCCCC) >> 2) | ((x & 0x33333333) << 2);
    x = ((x & 0xF0F0F0F0) >> 4) | ((x & 0x0F0F0F0F) << 4);
    x = ((x & 0xFF00FF00) >> 8) | ((x & 0x00FF00FF) << 8);
    x = (x >> 16) | (x << 16);
    return x;
}
