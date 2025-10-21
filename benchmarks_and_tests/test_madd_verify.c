// Test MADD pattern correctness - verify results are correct
#include <stdint.h>
#include <stdio.h>

// Test basic 32-bit MADD
int32_t test_madd_32bit(int32_t a, int32_t b, int32_t c) {
    return a * b + c;
}

// Test 16-bit MADD
int32_t test_madd_16bit(int16_t a, int16_t b, int32_t c) {
    return a * b + c;
}

// Test 8-bit MADD
int32_t test_madd_8bit(int8_t a, int8_t b, int32_t c) {
    return a * b + c;
}

// Test commuted form
int32_t test_madd_commuted(int32_t a, int32_t b, int32_t c) {
    return c + a * b;
}

// Verification function
int verify_result(const char* test_name, int32_t result, int32_t expected) {
    if (result == expected) {
        printf("PASS: %s = %d (expected %d)\n", test_name, result, expected);
        return 1;
    } else {
        printf("FAIL: %s = %d (expected %d)\n", test_name, result, expected);
        return 0;
    }
}

int main() {
    int passed = 0;
    int total = 0;
    int32_t result;

    printf("Testing MADD pattern recognition correctness...\n\n");

    // Test 1: Basic positive numbers
    result = test_madd_32bit(3, 4, 5);
    total++;
    passed += verify_result("test_madd_32bit(3, 4, 5)", result, 17);  // 3*4+5 = 12+5 = 17

    // Test 2: With zero
    result = test_madd_32bit(10, 0, 7);
    total++;
    passed += verify_result("test_madd_32bit(10, 0, 7)", result, 7);  // 10*0+7 = 0+7 = 7

    // Test 3: Negative numbers
    result = test_madd_32bit(-3, 5, 10);
    total++;
    passed += verify_result("test_madd_32bit(-3, 5, 10)", result, -5);  // -3*5+10 = -15+10 = -5

    // Test 4: Large numbers
    result = test_madd_32bit(1000, 2000, 500);
    total++;
    passed += verify_result("test_madd_32bit(1000, 2000, 500)", result, 2000500);  // 1000*2000+500

    // Test 5: 16-bit positive
    result = test_madd_16bit(100, 200, 300);
    total++;
    passed += verify_result("test_madd_16bit(100, 200, 300)", result, 20300);  // 100*200+300 = 20000+300

    // Test 6: 16-bit negative
    result = test_madd_16bit(-50, 30, 1000);
    total++;
    passed += verify_result("test_madd_16bit(-50, 30, 1000)", result, -500);  // -50*30+1000 = -1500+1000

    // Test 7: 8-bit positive
    result = test_madd_8bit(10, 12, 50);
    total++;
    passed += verify_result("test_madd_8bit(10, 12, 50)", result, 170);  // 10*12+50 = 120+50

    // Test 8: 8-bit negative
    result = test_madd_8bit(-5, 6, 100);
    total++;
    passed += verify_result("test_madd_8bit(-5, 6, 100)", result, 70);  // -5*6+100 = -30+100

    // Test 9: Commuted form
    result = test_madd_commuted(7, 8, 9);
    total++;
    passed += verify_result("test_madd_commuted(7, 8, 9)", result, 65);  // 9+7*8 = 9+56 = 65

    // Test 10: Edge case - max positive accumulation
    result = test_madd_32bit(0x7FFF, 0x7FFF, 0x1000);
    total++;
    passed += verify_result("test_madd_32bit(0x7FFF, 0x7FFF, 0x1000)", result, 0x3FFF1001);

    // Test 11: Polynomial evaluation (nested MADD)
    // (2*x + 3)*x + 4 where x=5
    // = (2*5 + 3)*5 + 4 = (10+3)*5 + 4 = 13*5 + 4 = 65 + 4 = 69
    int32_t x = 5;
    result = (2 * x + 3) * x + 4;
    total++;
    passed += verify_result("Polynomial (2*x+3)*x+4 where x=5", result, 69);

    // Test 12: Accumulation pattern
    int32_t sum = 0;
    sum = test_madd_32bit(2, 3, sum);  // sum = 0 + 2*3 = 6
    sum = test_madd_32bit(4, 5, sum);  // sum = 6 + 4*5 = 26
    sum = test_madd_32bit(1, 10, sum); // sum = 26 + 1*10 = 36
    total++;
    passed += verify_result("Accumulation pattern", sum, 36);

    printf("\n========================================\n");
    printf("Results: %d/%d tests passed\n", passed, total);

    if (passed == total) {
        printf("SUCCESS: All MADD patterns produce correct results!\n");
        return 0;
    } else {
        printf("FAILURE: Some tests failed!\n");
        return 1;
    }
}
