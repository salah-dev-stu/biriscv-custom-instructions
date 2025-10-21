//==- BuiltinsRISCVBiRiscV.td - BiRiscV Custom Builtin database ---*- C++ -*-==//
//
// BiRiscV Custom Instructions
// Custom instruction set for BiRiscV processor
//
//===----------------------------------------------------------------------===//
//
// This file defines the BiRiscV-specific builtin function database.
//
//===----------------------------------------------------------------------===//

class RISCVBiRiscVBuiltin<string prototype, string features = ""> : TargetBuiltin {
  let Spellings = ["__builtin_riscv_biriscv_" # NAME];
  let Prototype = prototype;
  let Features = features;
}

let Attributes = [NoThrow, Const] in {
//===----------------------------------------------------------------------===//
// BiRiscV Custom Instructions
//===----------------------------------------------------------------------===//

// CSEL - Conditional Select
// rd = (rs3 == 0) ? rs1 : rs2
def csel : RISCVBiRiscVBuiltin<"int(int, int, int)", "xbiriscv">;

// BREV - Bit Reverse
// rd[i] = rs1[31-i]
def brev : RISCVBiRiscVBuiltin<"int(int)", "xbiriscv">;

// MADD - Multiply-Add
// rd = rs1 * rs2 + rs3
def madd : RISCVBiRiscVBuiltin<"int(int, int, int)", "xbiriscv">;

// TERNLOG - Ternary Logic
// rd = ternary_logic(rs1, rs2, imm8)
// Note: Hardware uses rs1, rs2, and constant 0 as the 3 inputs to the LUT
def ternlog : RISCVBiRiscVBuiltin<"int(int, int, unsigned int)", "xbiriscv">;

// CMOV - Conditional Move
// rd = (rs3 != 0) ? rs1 : rs2
def cmov : RISCVBiRiscVBuiltin<"int(int, int, int)", "xbiriscv">;

// SAD - Sum of Absolute Differences
// rd = |rs1[7:0] - rs2[7:0]| + |rs1[15:8] - rs2[15:8]| +
//      |rs1[23:16] - rs2[23:16]| + |rs1[31:24] - rs2[31:24]| + rs3
def sad : RISCVBiRiscVBuiltin<"int(int, int, int)", "xbiriscv">;

} // Attributes = [NoThrow, Const]
