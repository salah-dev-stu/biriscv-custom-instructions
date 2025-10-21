// Comprehensive test of BREV pattern recognition
#include <stdint.h>

// ============================================================================
// Pattern 1: __builtin_bitreverse32() - the obvious one
// ============================================================================
uint32_t pattern1_builtin(uint32_t x) {
    return __builtin_bitreverse32(x);
}

// ============================================================================
// Pattern 2: __builtin_bitreverse16() - does it work for 16-bit?
// ============================================================================
uint16_t pattern2_builtin16(uint16_t x) {
    return __builtin_bitreverse16(x);
}

// ============================================================================
// Pattern 3: __builtin_bitreverse8() - does it work for 8-bit?
// ============================================================================
uint8_t pattern3_builtin8(uint8_t x) {
    return __builtin_bitreverse8(x);
}

// ============================================================================
// Pattern 4: Manual bit twiddling - swap pairs, nibbles, bytes, halfwords
// ============================================================================
uint32_t pattern4_manual_optimized(uint32_t x) {
    // This is the classic bit-twiddling hack for reversing bits
    x = ((x & 0xAAAAAAAA) >> 1) | ((x & 0x55555555) << 1);  // swap pairs
    x = ((x & 0xCCCCCCCC) >> 2) | ((x & 0x33333333) << 2);  // swap nibbles
    x = ((x & 0xF0F0F0F0) >> 4) | ((x & 0x0F0F0F0F) << 4);  // swap bytes
    x = ((x & 0xFF00FF00) >> 8) | ((x & 0x00FF00FF) << 8);  // swap halfwords
    x = (x >> 16) | (x << 16);                               // swap words
    return x;
}

// ============================================================================
// Pattern 5: Simplified manual - fewer steps
// ============================================================================
uint32_t pattern5_manual_simple(uint32_t x) {
    x = ((x >> 1) & 0x55555555) | ((x & 0x55555555) << 1);
    x = ((x >> 2) & 0x33333333) | ((x & 0x33333333) << 2);
    x = ((x >> 4) & 0x0F0F0F0F) | ((x & 0x0F0F0F0F) << 4);
    x = ((x >> 8) & 0x00FF00FF) | ((x & 0x00FF00FF) << 8);
    x = (x >> 16) | (x << 16);
    return x;
}

// ============================================================================
// Pattern 6: Loop-based reversal - probably WON'T be recognized
// ============================================================================
uint32_t pattern6_loop(uint32_t x) {
    uint32_t result = 0;
    for (int i = 0; i < 32; i++) {
        result = (result << 1) | (x & 1);
        x >>= 1;
    }
    return result;
}

// ============================================================================
// Pattern 7: Unrolled loop - might be recognized
// ============================================================================
uint32_t pattern7_unrolled(uint32_t x) {
    uint32_t result = 0;
    result = (result << 1) | (x & 1); x >>= 1;
    result = (result << 1) | (x & 1); x >>= 1;
    result = (result << 1) | (x & 1); x >>= 1;
    result = (result << 1) | (x & 1); x >>= 1;
    result = (result << 1) | (x & 1); x >>= 1;
    result = (result << 1) | (x & 1); x >>= 1;
    result = (result << 1) | (x & 1); x >>= 1;
    result = (result << 1) | (x & 1); x >>= 1;
    // ... (only showing first 8 iterations)
    return result;
}

// ============================================================================
// Pattern 8: Cast through different sizes
// ============================================================================
uint32_t pattern8_cast(uint32_t x) {
    return (uint32_t)__builtin_bitreverse32((uint32_t)x);
}

// ============================================================================
// Pattern 9: In expression context
// ============================================================================
uint32_t pattern9_expression(uint32_t x, uint32_t y) {
    return __builtin_bitreverse32(x) ^ y;
}

// ============================================================================
// Pattern 10: Reverse then mask - common pattern
// ============================================================================
uint32_t pattern10_reverse_and_mask(uint32_t x) {
    return __builtin_bitreverse32(x) & 0xFF;
}

// ============================================================================
// Pattern 11: Multiple reversals
// ============================================================================
uint32_t pattern11_double_reverse(uint32_t x) {
    // Double reverse should optimize to identity
    return __builtin_bitreverse32(__builtin_bitreverse32(x));
}

// ============================================================================
// Pattern 12: Constant value reverse - should be compile-time
// ============================================================================
uint32_t pattern12_constant(void) {
    return __builtin_bitreverse32(0x12345678);
}
