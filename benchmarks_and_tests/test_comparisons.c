// Test comparison-based selects

int test_eq(int a, int b, int x, int y) {
    return (a == b) ? x : y;
}

int test_ne(int a, int b, int x, int y) {
    return (a != b) ? x : y;
}

int test_lt(int a, int b, int x, int y) {
    return (a < b) ? x : y;
}

int test_le(int a, int b, int x, int y) {
    return (a <= b) ? x : y;
}

int test_gt(int a, int b, int x, int y) {
    return (a > b) ? x : y;
}

int test_ge(int a, int b, int x, int y) {
    return (a >= b) ? x : y;
}
