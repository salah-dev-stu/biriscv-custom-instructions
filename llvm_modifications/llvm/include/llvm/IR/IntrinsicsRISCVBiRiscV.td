//===- IntrinsicsRISCVBiRiscV.td - BiRiscV intrinsics ------*- tablegen -*-===//
//
// BiRiscV Custom Instructions
// Custom instruction set for BiRiscV processor
//
//===----------------------------------------------------------------------===//
//
// This file defines all of the BiRiscV custom intrinsics for RISC-V.
//
//===----------------------------------------------------------------------===//

// Single operand intrinsic (BREV)
class BiRiscVIntrinsicGpr
    : DefaultAttrsIntrinsic<[llvm_i32_ty], [llvm_i32_ty],
                            [IntrNoMem, IntrSpeculatable]>;

// Three operand intrinsics (CSEL, MADD, CMOV)
class BiRiscVIntrinsicGprGprGpr
    : DefaultAttrsIntrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
                            [IntrNoMem, IntrSpeculatable]>;

// Three operand intrinsic with immediate (TERNLOG: rs1, rs2, imm8)
// Note: Hardware uses rs1, rs2, and constant 0 as the 3 inputs to the LUT
class BiRiscVIntrinsicGprGprImm
    : DefaultAttrsIntrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
                            [IntrNoMem, IntrSpeculatable, ImmArg<ArgIndex<2>>]>;

let TargetPrefix = "riscv" in {
  // BREV - Bit Reverse
  // rd[i] = rs1[31-i]
  def int_riscv_biriscv_brev : BiRiscVIntrinsicGpr;

  // CSEL - Conditional Select
  // rd = (rs3 == 0) ? rs1 : rs2
  def int_riscv_biriscv_csel : BiRiscVIntrinsicGprGprGpr;

  // MADD - Multiply-Add
  // rd = rs1 * rs2 + rs3
  def int_riscv_biriscv_madd : BiRiscVIntrinsicGprGprGpr;

  // CMOV - Conditional Move
  // rd = (rs3 != 0) ? rs1 : rs2
  def int_riscv_biriscv_cmov : BiRiscVIntrinsicGprGprGpr;

  // SAD - Sum of Absolute Differences
  // rd = |rs1[7:0] - rs2[7:0]| + |rs1[15:8] - rs2[15:8]| +
  //      |rs1[23:16] - rs2[23:16]| + |rs1[31:24] - rs2[31:24]| + rs3
  def int_riscv_biriscv_sad : BiRiscVIntrinsicGprGprGpr;

  // TERNLOG - Ternary Logic
  // rd = ternary_logic(rs1, rs2, imm8)
  // Note: Hardware uses rs1, rs2, and constant 0 as the 3 inputs to the LUT
  def int_riscv_biriscv_ternlog : BiRiscVIntrinsicGprGprImm;
} // TargetPrefix = "riscv"
