# BiRISCV Custom Instructions - Fixed Compilation Instructions

## Prerequisites

Before compiling programs, you need:

1. **Custom LLVM compiler** (built following the instructions in the README)
2. **RISC-V GNU toolchain** for linking:
   ```bash
   # On macOS
   brew tap riscv-software-src/riscv
   brew install riscv-gnu-toolchain
   
   # On Linux (Ubuntu/Debian)
   sudo apt-get install gcc-riscv64-unknown-elf
   ```

## Compiling Programs

**Important:** The paths below assume `llvm-project` is in the same parent directory as this repo.

### Generate assembly to see custom instructions (recommended for analysis):
```bash
# From biriscv-custom-instructions/benchmarks_and_tests/

# With custom instructions (xbiriscv0p1)
../../llvm-project/install/bin/clang -O3 -march=rv32im_xbiriscv0p1 -mabi=ilp32 \
    -target riscv32-unknown-elf -S \
    video_motion_benchmark.c -o benchmark_custom.S

# Without custom instructions (standard RV32IM for comparison)
../../llvm-project/install/bin/clang -O3 -march=rv32im -mabi=ilp32 \
    -target riscv32-unknown-elf -S \
    video_motion_benchmark.c -o benchmark_standard.S
```

### Compile to object file (no linking):
```bash
# From biriscv-custom-instructions/benchmarks_and_tests/
../../llvm-project/install/bin/clang -O3 -march=rv32im_xbiriscv0p1 -mabi=ilp32 \
    -target riscv32-unknown-elf \
    -c video_motion_benchmark.c -o benchmark.o
```

### Compile to ELF executable (requires RISC-V toolchain):
```bash
# From biriscv-custom-instructions/benchmarks_and_tests/

# Note: Add a main() function to video_motion_benchmark.c first:
# int main(void) {
#     uint32_t result = video_encoder_benchmark();
#     return 0;
# }

../../llvm-project/install/bin/clang -O3 -march=rv32im_xbiriscv0p1 -mabi=ilp32 \
    -target riscv32-unknown-elf \
    --sysroot=/opt/homebrew/Cellar/riscv-gnu-toolchain/main/riscv64-unknown-elf \
    --gcc-toolchain=/opt/homebrew/Cellar/riscv-gnu-toolchain/main \
    video_motion_benchmark.c -o benchmark.elf

# Note: Adjust paths if your RISC-V toolchain is installed elsewhere
# Linux users: Replace /opt/homebrew with your installation path
```

### Compile any C program:
```bash
# Assembly output (simplest, works without additional setup)
../../llvm-project/install/bin/clang -O3 -march=rv32im_xbiriscv0p1 -mabi=ilp32 \
    -target riscv32-unknown-elf -S \
    your_program.c -o output.S

# Object file
../../llvm-project/install/bin/clang -O3 -march=rv32im_xbiriscv0p1 -mabi=ilp32 \
    -target riscv32-unknown-elf -c \
    your_program.c -o output.o

# Executable (requires main() function and RISC-V toolchain)
../../llvm-project/install/bin/clang -O3 -march=rv32im_xbiriscv0p1 -mabi=ilp32 \
    -target riscv32-unknown-elf \
    --sysroot=/opt/homebrew/Cellar/riscv-gnu-toolchain/main/riscv64-unknown-elf \
    --gcc-toolchain=/opt/homebrew/Cellar/riscv-gnu-toolchain/main \
    your_program.c -o output.elf
```

**Key flag:** `-march=rv32im_xbiriscv0p1` enables the custom instruction set extension.

### Automated comparison script:
```bash
# From biriscv-custom-instructions/benchmarks_and_tests/
./run_benchmark_comparison.sh
```

This automatically generates both assembly files and shows:
- Instruction count with/without custom instructions
- Usage count for each custom instruction (CSEL, BREV, MADD, etc.)
- Assembly snippets showing the optimizations

## Troubleshooting

**"cannot find crt0.o" error:**
- Install the RISC-V GNU toolchain (see Prerequisites above)
- Adjust `--sysroot` and `--gcc-toolchain` paths to match your installation

**"undefined reference to main" error:**
- Your C file needs a `main()` function for executable linking
- Alternatively, compile to object file with `-c` flag

**For quick analysis:**
- Use assembly output (`-S` flag) - this always works without additional setup
- Compare `benchmark_custom.S` vs `benchmark_standard.S` to see custom instructions
