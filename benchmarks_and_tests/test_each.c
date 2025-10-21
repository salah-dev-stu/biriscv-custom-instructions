int test_madd(int a, int b, int c) {
    return __builtin_riscv_biriscv_madd(a, b, c);
}
int test_cmov(int a, int b, int c) {
    return __builtin_riscv_biriscv_cmov(a, b, c);
}
int test_ternlog(int a, int b, int c) {
    return __builtin_riscv_biriscv_ternlog(a, b, c, 0xCA);
}
