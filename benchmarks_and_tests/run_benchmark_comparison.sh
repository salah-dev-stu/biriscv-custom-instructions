#!/bin/bash

# Script to compile and compare benchmark with and without custom instructions

set -e

CLANG=../build/bin/clang
TEST_FILE=video_motion_benchmark.c
OUTPUT_STD=benchmark_standard
OUTPUT_CUSTOM=benchmark_custom
ASM_STD=benchmark_standard.s
ASM_CUSTOM=benchmark_custom.s

echo "=========================================================================="
echo "BiRISCV Video Motion Estimation Benchmark"
echo "=========================================================================="
echo "Benchmark: Video encoder motion estimation + filtering pipeline"
echo "Frame size: 128x128 pixels (16,384 pixels)"
echo "Motion estimation: 256 blocks x 256 search positions = 65,536 SAD computations"
echo "Total SAD operations: 1,048,576 (16 per block comparison)"
echo "Convolution operations: ~550,000 MADD operations"
echo "CRC operations: 3 frames with BREV"
echo ""

# Check if clang exists
if [ ! -f "$CLANG" ]; then
    echo "ERROR: Clang not found at $CLANG"
    echo "Please build LLVM first"
    exit 1
fi

echo "Step 1: Compiling with standard RV32IM (no custom instructions)..."
$CLANG -O3 -march=rv32im -mabi=ilp32 \
    -target riscv32-unknown-elf \
    -S $TEST_FILE -o $ASM_STD

echo "  Generated assembly: $ASM_STD"

# Count instructions
INST_COUNT_STD=$(grep -E "^\s+(add|sub|mul|and|or|xor|sll|srl|sra|lbu|lw|sw)" $ASM_STD | wc -l)
echo "  Approximate instruction count: $INST_COUNT_STD"
echo ""

echo "Step 2: Compiling with BiRISCV custom instructions (xbiriscv0p1)..."
$CLANG -O3 -march=rv32im_xbiriscv0p1 -mabi=ilp32 \
    -target riscv32-unknown-elf \
    -S $TEST_FILE -o $ASM_CUSTOM

echo "  Generated assembly: $ASM_CUSTOM"

# Count instructions
INST_COUNT_CUSTOM=$(grep -E "^\s+(add|sub|mul|and|or|xor|sll|srl|sra|lbu|lw|sw)" $ASM_CUSTOM | wc -l)
echo "  Approximate instruction count: $INST_COUNT_CUSTOM"

# Count custom instructions
CSEL_COUNT=$(grep -c "csel" $ASM_CUSTOM || true)
BREV_COUNT=$(grep -c "brev" $ASM_CUSTOM || true)
MADD_COUNT=$(grep -c "madd" $ASM_CUSTOM || true)
TERNLOG_COUNT=$(grep -c "ternlog" $ASM_CUSTOM || true)
CMOV_COUNT=$(grep -c "cmov" $ASM_CUSTOM || true)
SAD_COUNT=$(grep -c "sad" $ASM_CUSTOM || true)

echo ""
echo "Custom instruction usage:"
echo "  CSEL:    $CSEL_COUNT"
echo "  BREV:    $BREV_COUNT"
echo "  MADD:    $MADD_COUNT"
echo "  TERNLOG: $TERNLOG_COUNT"
echo "  CMOV:    $CMOV_COUNT"
echo "  SAD:     $SAD_COUNT"
echo ""

# Calculate reduction
if [ $INST_COUNT_STD -gt 0 ]; then
    REDUCTION=$((INST_COUNT_STD - INST_COUNT_CUSTOM))
    PERCENT=$(echo "scale=2; $REDUCTION * 100 / $INST_COUNT_STD" | bc)
    echo "Instruction count reduction: $REDUCTION instructions ($PERCENT%)"
else
    echo "Instruction count reduction: Unable to calculate"
fi

echo ""
echo "=========================================================================="
echo "Assembly Comparison"
echo "=========================================================================="
echo ""
echo "Example: SAD function (core motion estimation)"
echo ""
echo "--- Standard (sad_4pixels function): ---"
grep -A 30 "sad_4pixels:\|block_sad:" $ASM_STD | head -35 || echo "(Function not found)"

echo ""
echo "--- With custom instructions: ---"
grep -A 30 "sad_4pixels:\|block_sad:" $ASM_CUSTOM | head -35 || echo "(Function not found)"

echo ""
echo "=========================================================================="
echo "Detailed Instruction Analysis"
echo "=========================================================================="
echo ""

echo "Searching for specific optimization patterns..."
echo ""

# Look for SAD pattern
echo "1. SAD instruction usage:"
grep -n "sad\s" $ASM_CUSTOM | head -5 || echo "  No SAD instructions found"
echo ""

# Look for MADD pattern
echo "2. MADD instruction usage:"
grep -n "madd\s" $ASM_CUSTOM | head -5 || echo "  No MADD instructions found"
echo ""

# Look for BREV pattern
echo "3. BREV instruction usage:"
grep -n "brev\s" $ASM_CUSTOM | head -5 || echo "  No BREV instructions found"
echo ""

# Look for CSEL pattern
echo "4. CSEL instruction usage:"
grep -n "csel\s" $ASM_CUSTOM | head -5 || echo "  No CSEL instructions found"
echo ""

echo "=========================================================================="
echo "Files generated:"
echo "  Standard assembly:        $ASM_STD"
echo "  Custom inst assembly:     $ASM_CUSTOM"
echo ""
echo "To view full assembly files:"
echo "  less $ASM_STD"
echo "  less $ASM_CUSTOM"
echo ""
echo "To compare side-by-side:"
echo "  diff -y $ASM_STD $ASM_CUSTOM | less"
echo "=========================================================================="
