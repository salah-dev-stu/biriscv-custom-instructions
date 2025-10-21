/*
 * BiRiscV Custom Instructions - Compiler Test Program
 *
 * This program tests all 5 custom instructions through LLVM builtin functions:
 * - BREV (Bit Reverse)
 * - CSEL (Conditional Select)
 * - MADD (Multiply-Add)
 * - CMOV (Conditional Move)
 * - TERNLOG (Ternary Logic)
 *
 * Compile with:
 *   clang -O2 --target=riscv32 -march=rv32i_xbiriscv0p1 -S test_biriscv_builtins.c
 *
 * Expected output: Assembly file with brev, csel, madd, cmov, ternlog instructions
 */

#include <stdint.h>

//=============================================================================
// Test 1: BREV - Bit Reverse
//=============================================================================

uint32_t test_brev_basic(uint32_t x) {
    return __builtin_riscv_biriscv_brev(x);
}

// Test with known values
void test_brev_values(void) {
    volatile uint32_t result;

    // Test 1: All zeros
    result = __builtin_riscv_biriscv_brev(0x00000000);
    // Expected: 0x00000000

    // Test 2: All ones
    result = __builtin_riscv_biriscv_brev(0xFFFFFFFF);
    // Expected: 0xFFFFFFFF

    // Test 3: Known pattern
    result = __builtin_riscv_biriscv_brev(0x12345678);
    // Expected: 0x1E6A2C48

    // Test 4: Alternating bits
    result = __builtin_riscv_biriscv_brev(0xAAAAAAAA);
    // Expected: 0x55555555

    // Test 5: Single bit
    result = __builtin_riscv_biriscv_brev(0x00000001);
    // Expected: 0x80000000
}

//=============================================================================
// Test 2: CSEL - Conditional Select (rs3 == 0 ? rs1 : rs2)
//=============================================================================

uint32_t test_csel_basic(uint32_t a, uint32_t b, uint32_t cond) {
    return __builtin_riscv_biriscv_csel(a, b, cond);
}

void test_csel_values(void) {
    volatile uint32_t result;

    // Test 1: Condition is zero (should select first argument)
    result = __builtin_riscv_biriscv_csel(0xAAAAAAAA, 0xBBBBBBBB, 0);
    // Expected: 0xAAAAAAAA

    // Test 2: Condition is non-zero (should select second argument)
    result = __builtin_riscv_biriscv_csel(0xAAAAAAAA, 0xBBBBBBBB, 1);
    // Expected: 0xBBBBBBBB

    // Test 3: Condition is large non-zero
    result = __builtin_riscv_biriscv_csel(0x11111111, 0x22222222, 0xFFFFFFFF);
    // Expected: 0x22222222

    // Test 4: Both operands same
    result = __builtin_riscv_biriscv_csel(0x12345678, 0x12345678, 5);
    // Expected: 0x12345678 (same either way)
}

//=============================================================================
// Test 3: MADD - Multiply-Add (rs1 * rs2 + rs3)
//=============================================================================

uint32_t test_madd_basic(uint32_t a, uint32_t b, uint32_t c) {
    return __builtin_riscv_biriscv_madd(a, b, c);
}

void test_madd_values(void) {
    volatile uint32_t result;

    // Test 1: Simple multiply-add
    result = __builtin_riscv_biriscv_madd(3, 4, 5);
    // Expected: 17 (3*4 + 5 = 12 + 5)

    // Test 2: Zero multiply
    result = __builtin_riscv_biriscv_madd(0, 100, 50);
    // Expected: 50 (0*100 + 50 = 0 + 50)

    // Test 3: Zero add
    result = __builtin_riscv_biriscv_madd(7, 8, 0);
    // Expected: 56 (7*8 + 0)

    // Test 4: Larger values
    result = __builtin_riscv_biriscv_madd(100, 200, 300);
    // Expected: 20300 (100*200 + 300)

    // Test 5: With one operand = 1
    result = __builtin_riscv_biriscv_madd(1, 0xABCD, 0x1234);
    // Expected: 0xBE01 (1*0xABCD + 0x1234)
}

//=============================================================================
// Test 4: CMOV - Conditional Move (rs3 != 0 ? rs1 : rs2)
//=============================================================================

uint32_t test_cmov_basic(uint32_t a, uint32_t b, uint32_t cond) {
    return __builtin_riscv_biriscv_cmov(a, b, cond);
}

void test_cmov_values(void) {
    volatile uint32_t result;

    // Test 1: Condition is zero (should select second argument)
    result = __builtin_riscv_biriscv_cmov(0xAAAAAAAA, 0xBBBBBBBB, 0);
    // Expected: 0xBBBBBBBB

    // Test 2: Condition is non-zero (should select first argument)
    result = __builtin_riscv_biriscv_cmov(0xAAAAAAAA, 0xBBBBBBBB, 1);
    // Expected: 0xAAAAAAAA

    // Test 3: Condition is large non-zero
    result = __builtin_riscv_biriscv_cmov(0x11111111, 0x22222222, 0xFFFFFFFF);
    // Expected: 0x11111111

    // Test 4: Verify CMOV is opposite of CSEL
    // CSEL(a, b, 0) should equal CMOV(b, a, 0)
    result = __builtin_riscv_biriscv_cmov(0xBBBBBBBB, 0xAAAAAAAA, 0);
    // Expected: 0xAAAAAAAA
}

//=============================================================================
// Test 5: TERNLOG - Ternary Logic
//=============================================================================

uint32_t test_ternlog_and(uint32_t a, uint32_t b) {
    // 0x80 = a & b & 0 (third input hardwired to 0)
    return __builtin_riscv_biriscv_ternlog(a, b, 0x80);
}

uint32_t test_ternlog_or(uint32_t a, uint32_t b) {
    // 0xFE = a | b | 0 (third input hardwired to 0)
    return __builtin_riscv_biriscv_ternlog(a, b, 0xFE);
}

uint32_t test_ternlog_maj(uint32_t a, uint32_t b) {
    // 0xE8 = majority function (for 2 inputs + constant 0)
    return __builtin_riscv_biriscv_ternlog(a, b, 0xE8);
}

void test_ternlog_values(void) {
    volatile uint32_t result;

    // Test 1: AND operation (imm=0x80) - a & b & 0
    result = __builtin_riscv_biriscv_ternlog(0xF0F0F0F0, 0xFF00FF00, 0x80);
    // Expected: 0x00000000 (since third input is 0)

    // Test 2: OR operation (imm=0xFE) - a | b | 0
    result = __builtin_riscv_biriscv_ternlog(0x000000FF, 0x0000FF00, 0xFE);
    // Expected: 0x0000FFFF (a | b)

    // Test 3: Select a (imm=0xF0)
    result = __builtin_riscv_biriscv_ternlog(0xFFFFFFFF, 0x00000000, 0xF0);
    // Expected: 0xFFFFFFFF (selects first operand)

    // Test 4: XOR operation (imm=0x66) - a ^ b
    result = __builtin_riscv_biriscv_ternlog(0xAAAAAAAA, 0xCCCCCCCC, 0x66);
    // Expected: 0x66666666 (XOR of two operands)

    // Test 5: AND-NOT operation (imm=0x20) - a & ~b
    result = __builtin_riscv_biriscv_ternlog(0x12345678, 0xABCDEF00, 0x20);
    // Expected: computed per truth table
}

//=============================================================================
// Test 6: Inline Helper Functions (for performance)
//=============================================================================

static inline uint32_t reverse_bits(uint32_t x) {
    return __builtin_riscv_biriscv_brev(x);
}

static inline uint32_t select_if_zero(uint32_t if_zero, uint32_t if_nonzero, uint32_t condition) {
    return __builtin_riscv_biriscv_csel(if_zero, if_nonzero, condition);
}

static inline uint32_t multiply_add(uint32_t a, uint32_t b, uint32_t c) {
    return __builtin_riscv_biriscv_madd(a, b, c);
}

// Test that inlining works correctly
uint32_t test_inlined_operations(uint32_t x, uint32_t y, uint32_t z) {
    uint32_t reversed = reverse_bits(x);
    uint32_t selected = select_if_zero(y, z, reversed);
    return multiply_add(selected, 2, 1000);
}

//=============================================================================
// Test 7: Combined Operations
//=============================================================================

// Compute CRC with bit reversal
uint32_t crc32_with_reflection(uint32_t data) {
    uint32_t reversed = __builtin_riscv_biriscv_brev(data);
    // XOR with polynomial (simplified)
    return reversed ^ 0xEDB88320;
}

// Conditional absolute value using CSEL
int32_t conditional_abs(int32_t x) {
    int32_t neg = -x;
    // If x < 0 (sign bit set), select -x, else select x
    int32_t sign = x >> 31;  // All 1s if negative, all 0s if positive
    return __builtin_riscv_biriscv_csel((uint32_t)x, (uint32_t)neg, sign);
}

// Polynomial evaluation using MADD: ax^2 + bx + c
uint32_t polynomial_eval(uint32_t x, uint32_t a, uint32_t b, uint32_t c) {
    uint32_t x_squared = x * x;
    uint32_t ax2 = a * x_squared;
    return __builtin_riscv_biriscv_madd(b, x, ax2 + c);
}

//=============================================================================
// Main Test Function
//=============================================================================

int main(void) {
    volatile uint32_t test_result;

    // Run all test suites
    test_brev_values();
    test_csel_values();
    test_madd_values();
    test_cmov_values();
    test_ternlog_values();

    // Test combined operations
    test_result = crc32_with_reflection(0x12345678);
    test_result = conditional_abs(-42);
    test_result = polynomial_eval(5, 2, 3, 7);
    test_result = test_inlined_operations(0xABCD, 100, 200);

    // Success marker
    test_result = 0xDEADBEEF;

    return 0;
}
