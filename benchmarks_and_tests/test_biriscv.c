/*
 * BiRiscV Custom Instructions Test Program
 * Tests all 5 custom instructions using LLVM builtins
 */

#include <stdint.h>

// Test CSEL - Conditional Select
// Returns value_if_zero when condition == 0, else value_if_nonzero
int test_csel(int value_if_zero, int value_if_nonzero, int condition) {
    return __builtin_riscv_biriscv_csel(value_if_zero, value_if_nonzero, condition);
}

// Test BREV - Bit Reverse
// Returns input with bits reversed: result[i] = input[31-i]
int test_brev(int input) {
    return __builtin_riscv_biriscv_brev(input);
}

// Test MADD - Multiply-Add
// Returns a * b + c
int test_madd(int a, int b, int c) {
    return __builtin_riscv_biriscv_madd(a, b, c);
}

// Test CMOV - Conditional Move
// Returns value_a when condition != 0, else value_b
int test_cmov(int value_a, int value_b, int condition) {
    return __builtin_riscv_biriscv_cmov(value_a, value_b, condition);
}

// Test TERNLOG - Ternary Logic
// NOTE: The immediate must be a compile-time constant, not a variable
// imm = 0xCA computes: (a & b) | (c & ~a)
int test_ternlog(int a, int b, int c) {
    return __builtin_riscv_biriscv_ternlog(a, b, c, 0xCA);
}

// Test different TERNLOG immediate values
// imm = 0xF0 computes: c (just returns c)
int test_ternlog_f0(int a, int b, int c) {
    return __builtin_riscv_biriscv_ternlog(a, b, c, 0xF0);
}

// Combined test function
int test_combined(int x, int y, int z) {
    // Use multiple BiRiscV instructions in sequence
    int reversed = __builtin_riscv_biriscv_brev(x);
    int product_sum = __builtin_riscv_biriscv_madd(x, y, z);
    int selected = __builtin_riscv_biriscv_csel(reversed, product_sum, z);
    return selected;
}
