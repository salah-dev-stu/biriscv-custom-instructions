// Test various nested select patterns

// Simple 2-level nesting
int test_nested_2level(int x, int y, int a, int b, int c) {
    return x ? (y ? a : b) : c;
}

// 3-level nesting
int test_nested_3level(int x, int y, int z, int a, int b, int c, int d) {
    return x ? (y ? (z ? a : b) : c) : d;
}

// Nested in false branch
int test_nested_false(int x, int y, int a, int b, int c) {
    return x ? a : (y ? b : c);
}

// Both branches nested
int test_nested_both(int w, int x, int y, int z, int a, int b, int c, int d) {
    return w ? (x ? a : b) : (y ? c : d);
}

// Nested with same values (should optimize)
int test_nested_same(int x, int y, int a, int b) {
    return x ? (y ? a : b) : b;
}

// Complex nesting with arithmetic
int test_nested_arith(int x, int y, int a, int b, int c) {
    return x ? (y ? a + 1 : b + 2) : c + 3;
}

// Chained ternary (different from nested)
int test_chained(int a, int b, int c) {
    return (a == 0) ? 1 : (b == 0) ? 2 : (c == 0) ? 3 : 4;
}
