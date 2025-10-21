// Test file to see what IR patterns LLVM generates for SAD-like code
// This will help us understand what patterns to match in TableGen

#include <stdint.h>

// Helper to get absolute difference of unsigned bytes
static inline uint32_t absdiff_u8(uint8_t a, uint8_t b) {
    return (a > b) ? (a - b) : (b - a);
}

// Helper for signed absolute value
static inline int32_t abs_i32(int32_t x) {
    return (x < 0) ? -x : x;
}

// Manual SAD implementation - what pattern does this generate?
uint32_t manual_sad_bytes(uint8_t *a, uint8_t *b, uint32_t acc) {
    acc += absdiff_u8(a[0], b[0]);
    acc += absdiff_u8(a[1], b[1]);
    acc += absdiff_u8(a[2], b[2]);
    acc += absdiff_u8(a[3], b[3]);
    return acc;
}

// SAD with packed 32-bit values - extract bytes manually
uint32_t manual_sad_packed(uint32_t a, uint32_t b, uint32_t acc) {
    uint8_t a0 = (a >> 0) & 0xFF;
    uint8_t a1 = (a >> 8) & 0xFF;
    uint8_t a2 = (a >> 16) & 0xFF;
    uint8_t a3 = (a >> 24) & 0xFF;

    uint8_t b0 = (b >> 0) & 0xFF;
    uint8_t b1 = (b >> 8) & 0xFF;
    uint8_t b2 = (b >> 16) & 0xFF;
    uint8_t b3 = (b >> 24) & 0xFF;

    acc += absdiff_u8(a0, b0);
    acc += absdiff_u8(a1, b1);
    acc += absdiff_u8(a2, b2);
    acc += absdiff_u8(a3, b3);

    return acc;
}

// Using custom abs function
uint32_t manual_sad_abs(uint32_t a, uint32_t b, uint32_t acc) {
    int8_t a0 = (a >> 0) & 0xFF;
    int8_t a1 = (a >> 8) & 0xFF;
    int8_t a2 = (a >> 16) & 0xFF;
    int8_t a3 = (a >> 24) & 0xFF;

    int8_t b0 = (b >> 0) & 0xFF;
    int8_t b1 = (b >> 8) & 0xFF;
    int8_t b2 = (b >> 16) & 0xFF;
    int8_t b3 = (b >> 24) & 0xFF;

    acc += abs_i32(a0 - b0);
    acc += abs_i32(a1 - b1);
    acc += abs_i32(a2 - b2);
    acc += abs_i32(a3 - b3);

    return acc;
}

// Compare with builtin
uint32_t builtin_sad(uint32_t a, uint32_t b, uint32_t acc) {
    return __builtin_riscv_biriscv_sad(a, b, acc);
}
