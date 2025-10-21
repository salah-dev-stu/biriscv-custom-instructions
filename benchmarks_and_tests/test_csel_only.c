int test_csel(int a, int b, int c) {
    return __builtin_riscv_biriscv_csel(a, b, c);
}
