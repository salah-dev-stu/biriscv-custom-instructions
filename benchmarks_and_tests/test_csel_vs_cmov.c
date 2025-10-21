// Explicitly test CSEL vs CMOV usage

// CSEL: rd = (rs3 == 0) ? rs1 : rs2
// CMOV: rd = (rs3 != 0) ? rs1 : rs2

// Test 1: Condition == 0, should use CSEL
int test_cond_eq_zero(int cond, int a, int b) {
    return (cond == 0) ? a : b;
}

// Test 2: Condition != 0, should use CMOV  
int test_cond_ne_zero(int cond, int a, int b) {
    return (cond != 0) ? a : b;
}

// Test 3: Simple condition (non-zero is true), should use CMOV
int test_simple_cond(int cond, int a, int b) {
    return cond ? a : b;
}

// Test 4: Inverted condition, should use CSEL
int test_inverted_cond(int cond, int a, int b) {
    return !cond ? a : b;
}

// Test 5: (cond == 0) ? a : 0, should use CSEL with zero
int test_csel_zero(int cond, int a) {
    return (cond == 0) ? a : 0;
}

// Test 6: (cond != 0) ? a : 0, should use CMOV with zero
int test_cmov_zero(int cond, int a) {
    return (cond != 0) ? a : 0;
}

// Test 7: (cond == 0) ? 0 : b, should use CMOV with zero
int test_csel_zero_false(int cond, int b) {
    return (cond == 0) ? 0 : b;
}

// Test 8: (cond != 0) ? 0 : b, should use CSEL with zero
int test_cmov_zero_false(int cond, int b) {
    return (cond != 0) ? 0 : b;
}
