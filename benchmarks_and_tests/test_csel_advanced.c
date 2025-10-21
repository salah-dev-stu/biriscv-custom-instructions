// Test more complex CSEL/CMOV patterns

// Test 1: Select with constant values (not zero)
int test_const_select(int cond, int a, int b) {
    return cond ? 42 : 100;
}

// Test 2: Nested selects
int test_nested_select(int x, int y, int z, int a, int b, int c) {
    return x ? (y ? a : b) : (z ? b : c);
}

// Test 3: Select with arithmetic operations
int test_select_arithmetic(int cond, int a, int b, int c) {
    return cond ? (a + b) : (a + c);
}

// Test 4: Select combined with AND
int test_select_and(int cond, int mask, int value) {
    return cond ? (value & mask) : value;
}

// Test 5: Select combined with OR
int test_select_or(int cond, int mask, int value) {
    return cond ? (value | mask) : value;
}

// Test 6: Select with shift operations
int test_select_shift(int cond, int value, int shift) {
    return cond ? (value << shift) : (value >> shift);
}

// Test 7: Ternary chain (multiple conditions)
int test_ternary_chain(int a, int b, int c) {
    return (a > 0) ? 1 : (b > 0) ? 2 : (c > 0) ? 3 : 0;
}

// Test 8: Select with negation
int test_select_negation(int cond, int value) {
    return cond ? -value : value;
}

// Test 9: Select between same value (should optimize)
int test_select_same(int cond, int value) {
    return cond ? value : value;
}

// Test 10: Select with bitmask selection
int test_bitmask(int cond, int value) {
    return cond ? (value & 0xFF) : (value & 0xFFFF);
}
