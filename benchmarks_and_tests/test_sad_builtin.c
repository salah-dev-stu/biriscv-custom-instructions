// Test file for SAD (Sum of Absolute Differences) builtin
// Compile with: clang --target=riscv32 -march=rv32i_xbiriscv0p1 -c test_sad_builtin.c

#include <stdint.h>

// Basic SAD test
uint32_t test_sad_basic(uint32_t a, uint32_t b, uint32_t acc) {
    return __builtin_riscv_biriscv_sad(a, b, acc);
}

// SAD with zero accumulator
uint32_t test_sad_no_acc(uint32_t a, uint32_t b) {
    return __builtin_riscv_biriscv_sad(a, b, 0);
}

// Motion estimation use case - compare two pixel blocks
uint32_t compute_sad_4bytes(uint32_t block1, uint32_t block2) {
    return __builtin_riscv_biriscv_sad(block1, block2, 0);
}

// Accumulate multiple SADs (simulating larger block comparison)
uint32_t compute_sad_multi(uint32_t *block1, uint32_t *block2, int count) {
    uint32_t acc = 0;
    for (int i = 0; i < count; i++) {
        acc = __builtin_riscv_biriscv_sad(block1[i], block2[i], acc);
    }
    return acc;
}

// Test with literals
uint32_t test_sad_literals(void) {
    return __builtin_riscv_biriscv_sad(0x01020304, 0x01020305, 0);
}

// Inline comparison and decision
uint32_t find_best_match(uint32_t current, uint32_t candidate1, uint32_t candidate2) {
    uint32_t sad1 = __builtin_riscv_biriscv_sad(current, candidate1, 0);
    uint32_t sad2 = __builtin_riscv_biriscv_sad(current, candidate2, 0);
    return (sad1 < sad2) ? sad1 : sad2;
}
