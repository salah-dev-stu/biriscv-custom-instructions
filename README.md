# BiRISCV Custom Instructions

This project extends the BiRISCV dual-issue RISC-V processor with 6 custom instructions for video processing and general computation. I implemented both the hardware (Verilog) and full compiler support (LLVM 21.1.3).

## Custom Instructions

- **CSEL** - Conditional select (branchless conditionals)
- **BREV** - Bit reverse for CRC calculations
- **MADD** - Multiply-add for convolution filters
- **TERNLOG** - Programmable ternary logic gates
- **CMOV** - Conditional move
- **SAD** - Sum of absolute differences for motion estimation

Results: **1.33× speedup** on video motion estimation benchmark.

## Reports

See the `report/` directory for complete documentation:
- **biriscv_custom_instructions_report.pdf** - Full technical report
- **biriscv_custom_instructions_brief.pdf** - Condensed version

## Building the Custom LLVM Compiler

**Important:** You must use LLVM 21.1.3 exactly. The `llvm_modifications/` directory contains files I created and modified - these will be copied into a fresh LLVM source tree. This won't affect any existing LLVM installation.

### 1. Clone LLVM 21.1.3
```bash
# Clone in the same parent directory as this repository
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout llvmorg-21.1.3
```

Your directory structure should be:
```
parent_directory/
├── biriscv-custom-instructions/  (this repo)
└── llvm-project/                 (LLVM 21.1.3)
```

### 2. Copy the BiRISCV files into LLVM
```bash
# From inside llvm-project/
# This copies both new files and modified existing files
cp -r ../biriscv-custom-instructions/llvm_modifications/clang/* clang/
cp -r ../biriscv-custom-instructions/llvm_modifications/llvm/* llvm/
```

This adds:
- New instruction definitions (TableGen files)
- Builtin functions for C/C++
- Pattern matching for automatic optimization
- Disassembler support

### 3. Build the compiler
```bash
mkdir build && cd build
cmake -G Ninja ../llvm \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -DLLVM_TARGETS_TO_BUILD="RISCV" \
    -DCMAKE_INSTALL_PREFIX=../install

ninja
ninja install
```

**Build time:** 1-2 hours depending on your machine.
**Result:** Custom compiler at `llvm-project/install/bin/clang`

## Compiling Programs

**Reminder:** These commands assume llvm-project is in the same parent directory as this repo (as shown in the build instructions above).

### Compile the video benchmark to ELF:
```bash
# From biriscv-custom-instructions/benchmarks_and_tests/
../../llvm-project/install/bin/clang -O3 -march=rv32im_xbiriscv0p1 -mabi=ilp32 \
    -target riscv32-unknown-elf \
    video_motion_benchmark.c -o benchmark.elf
```

### Generate assembly (.S file) to see custom instructions:
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

### Compile any C program:
```bash
# From biriscv-custom-instructions/benchmarks_and_tests/
# Or adjust the path based on where your C file is located

../../llvm-project/install/bin/clang -O3 -march=rv32im_xbiriscv0p1 -mabi=ilp32 \
    -target riscv32-unknown-elf -S \
    your_program.c -o output.S

# Or to executable
../../llvm-project/install/bin/clang -O3 -march=rv32im_xbiriscv0p1 -mabi=ilp32 \
    -target riscv32-unknown-elf \
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

## Repository Structure

```
├── report/                          # PDF reports and documentation
├── verilog/
│   ├── src/                         # Complete BiRISCV processor source
│   │   ├── core/                    # CPU core with custom instructions
│   │   ├── dcache/, icache/         # Cache modules
│   │   ├── tcm/                     # Memory controllers
│   │   └── top/                     # Top-level wrappers
│   ├── testbench/                   # Simulation testbenches
│   └── waveform_screenshots/        # Verification waveforms
├── llvm_modifications/              # LLVM/Clang compiler changes
│   ├── clang/                       # Builtin functions
│   └── llvm/                        # Backend instruction definitions
└── benchmarks_and_tests/            # Test programs and benchmarks
```

## Hardware Implementation

The Verilog source in `verilog/src/core/` contains my modifications to the BiRISCV processor:
- Extended ALU with custom instruction execution
- Modified decoder for new opcodes
- Register file expansion (4→6 read ports for three-operand instructions)

All changes are verified with waveform analysis - see screenshots in `verilog/waveform_screenshots/`.

---

**Author:** Salah Qadah
