//===-- RISCVInstrInfoBiRiscV.td - BiRiscV instructions -----*- tablegen -*-===//
//
// BiRiscV Custom Instructions
// Custom instruction set for BiRiscV processor
//
//===----------------------------------------------------------------------===//
//
// This file describes the BiRiscV-specific instructions.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// BiRiscV Opcodes
//===----------------------------------------------------------------------===//

// BiRiscV uses the CUSTOM_3 opcode (0x7B / 0b1111011) for all instructions
// CUSTOM_3 (0x7B) already defined as OPC_CUSTOM_3 in RISCVInstrFormats.td

//===----------------------------------------------------------------------===//
// Operand Definitions
//===----------------------------------------------------------------------===//

// 8-bit immediate for TERNLOG instruction
def ternlog_imm8 : RISCVOp<i32>, TImmLeaf<i32, [{return isUInt<8>(Imm);}]> {
  let ParserMatchClass = UImmAsmOperand<8>;
  let DecoderMethod = "decodeTernlogImm8";
  let OperandType = "OPERAND_UIMM8";
}

//===----------------------------------------------------------------------===//
// Instruction Class Templates
//===----------------------------------------------------------------------===//

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {

// R-type instruction for BREV (rd, rs1)
class BiRiscVInstR<bits<7> funct7, bits<3> funct3, RISCVOpcode opcode,
                   string opcodestr>
    : RVInstR<funct7, funct3, opcode, (outs GPR:$rd),
              (ins GPR:$rs1), opcodestr, "$rd, $rs1"> {
  let rs2 = 0b00000;
}

// R4-type instruction for CSEL, MADD, CMOV (rd, rs1, rs2, rs3)
class BiRiscVInstR4<bits<2> funct2, bits<3> funct3, RISCVOpcode opcode,
                    string opcodestr>
    : RVInstR4<funct2, funct3, opcode, (outs GPR:$rd),
               (ins GPR:$rs1, GPR:$rs2, GPR:$rs3),
               opcodestr, "$rd, $rs1, $rs2, $rs3">;

// Custom instruction format for TERNLOG (rd, rs1, rs2, imm8)
// TERNLOG encoding (R4-type with SPLIT immediate, no rs3):
//   imm8[7:3] → bits[31:27] (uses rs3 field position)
//   funct2=10 → bits[26:25]
//   rs2[4:0]  → bits[24:20]
//   rs1[4:0]  → bits[19:15]
//   imm8[2:0] → bits[14:12] (uses funct3 field position)
//   rd[4:0]   → bits[11:7]
//   opcode    → bits[6:0] = 0x7B
// Note: Hardware implementation uses rs1, rs2, and constant 0 as the 3 inputs to the LUT
class BiRiscVInstR4Imm<bits<2> funct2, RISCVOpcode opcode, string opcodestr>
    : RVInst<(outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2, ternlog_imm8:$imm8),
             opcodestr, "$rd, $rs1, $rs2, $imm8", [], InstFormatR4> {
  bits<8> imm8;
  bits<5> rs2;
  bits<5> rs1;
  bits<5> rd;

  // Split 8-bit immediate encoding
  let Inst{31-27} = imm8{7-3};   // Upper 5 bits of imm8
  let Inst{26-25} = funct2;       // funct2 = 0b10
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = imm8{2-0};   // Lower 3 bits of imm8
  let Inst{11-7} = rd;
  let Inst{6-0} = opcode.Value;
}

} // hasSideEffects = 0, mayLoad = 0, mayStore = 0

//===----------------------------------------------------------------------===//
// Instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasStdExtXBiRiscV, IsRV32] in {

// BREV - Bit Reverse
// rd[i] = rs1[31-i]
// Opcode: 0x7B, funct7: 0x10, funct3: 0x4
def BREV : BiRiscVInstR<0b0010000, 0b100, OPC_CUSTOM_3, "brev">,
           Sched<[]>;

// CSEL - Conditional Select
// rd = (rs3 == 0) ? rs1 : rs2
// Opcode: 0x7B, funct2: 0b00, funct3: 0x0
def CSEL : BiRiscVInstR4<0b00, 0b000, OPC_CUSTOM_3, "csel">,
           Sched<[]>;

// MADD - Multiply-Add
// rd = rs1 * rs2 + rs3
// Opcode: 0x7B, funct2: 0b01, funct3: 0x0
def MADD : BiRiscVInstR4<0b01, 0b000, OPC_CUSTOM_3, "madd">,
           Sched<[]>;

// CMOV - Conditional Move
// rd = (rs3 != 0) ? rs1 : rs2
// Opcode: 0x7B, funct2: 0b11, funct3: 0x1
def CMOV : BiRiscVInstR4<0b11, 0b001, OPC_CUSTOM_3, "cmov">,
           Sched<[]>;

// SAD - Sum of Absolute Differences
// rd = |rs1[7:0] - rs2[7:0]| + |rs1[15:8] - rs2[15:8]| +
//      |rs1[23:16] - rs2[23:16]| + |rs1[31:24] - rs2[31:24]| + rs3
// Opcode: 0x7B, funct2: 0b11, funct3: 0x2
def SAD : BiRiscVInstR4<0b11, 0b010, OPC_CUSTOM_3, "sad">,
          Sched<[]>;

// TERNLOG - Ternary Logic
// rd = ternary_logic(rs1, rs2, 0, imm8)  [third input hardwired to 0]
// Opcode: 0x7B, funct2: 0b10 (not 0b11!)
def TERNLOG : BiRiscVInstR4Imm<0b10, OPC_CUSTOM_3, "ternlog">,
              Sched<[]>;

} // let Predicates

//===----------------------------------------------------------------------===//
// Pseudo-instructions and codegen patterns
//===----------------------------------------------------------------------===//

let Predicates = [HasStdExtXBiRiscV] in {

// Pattern to match bitreverse intrinsic
def : Pat<(int_riscv_biriscv_brev GPR:$rs1),
          (BREV GPR:$rs1)>;

// Pattern to match conditional select intrinsic
def : Pat<(int_riscv_biriscv_csel GPR:$rs1, GPR:$rs2, GPR:$rs3),
          (CSEL GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

// Pattern to match multiply-add intrinsic
def : Pat<(int_riscv_biriscv_madd GPR:$rs1, GPR:$rs2, GPR:$rs3),
          (MADD GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

// Pattern to match conditional move intrinsic
def : Pat<(int_riscv_biriscv_cmov GPR:$rs1, GPR:$rs2, GPR:$rs3),
          (CMOV GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

// Pattern to match sum of absolute differences intrinsic
def : Pat<(int_riscv_biriscv_sad GPR:$rs1, GPR:$rs2, GPR:$rs3),
          (SAD GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

// Pattern to match ternary logic intrinsic
// Note: Hardware uses rs1, rs2, and constant 0 as the 3 inputs to the LUT
def : Pat<(int_riscv_biriscv_ternlog GPR:$rs1, GPR:$rs2, ternlog_imm8:$imm8),
          (TERNLOG GPR:$rs1, GPR:$rs2, $imm8)>;

//===----------------------------------------------------------------------===//
// Automatic Pattern Recognition (non-intrinsic patterns)
//===----------------------------------------------------------------------===//

// MADD: Multiply-Add patterns
// Pattern: rd = rs1 * rs2 + rs3

// Basic 32-bit: (a * b) + c
def : Pat<(i32 (add (mul GPR:$rs1, GPR:$rs2), GPR:$rs3)),
          (MADD GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

// Commuted: c + (a * b)
def : Pat<(i32 (add GPR:$rs3, (mul GPR:$rs1, GPR:$rs2))),
          (MADD GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

// 16-bit sign-extended: sext16(a) * sext16(b) + c
def : Pat<(i32 (add (mul (sext_inreg GPR:$rs1, i16), (sext_inreg GPR:$rs2, i16)), GPR:$rs3)),
          (MADD GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

// 16-bit sign-extended commuted: c + sext16(a) * sext16(b)
def : Pat<(i32 (add GPR:$rs3, (mul (sext_inreg GPR:$rs1, i16), (sext_inreg GPR:$rs2, i16)))),
          (MADD GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

// 8-bit sign-extended: sext8(a) * sext8(b) + c
def : Pat<(i32 (add (mul (sext_inreg GPR:$rs1, i8), (sext_inreg GPR:$rs2, i8)), GPR:$rs3)),
          (MADD GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

// 8-bit sign-extended commuted: c + sext8(a) * sext8(b)
def : Pat<(i32 (add GPR:$rs3, (mul (sext_inreg GPR:$rs1, i8), (sext_inreg GPR:$rs2, i8)))),
          (MADD GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

// 16-bit zero-extended: zext16(a) * zext16(b) + c
def : Pat<(i32 (add (mul (and GPR:$rs1, 0xFFFF), (and GPR:$rs2, 0xFFFF)), GPR:$rs3)),
          (MADD GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

// 16-bit zero-extended commuted: c + zext16(a) * zext16(b)
def : Pat<(i32 (add GPR:$rs3, (mul (and GPR:$rs1, 0xFFFF), (and GPR:$rs2, 0xFFFF)))),
          (MADD GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

// 8-bit zero-extended: zext8(a) * zext8(b) + c
def : Pat<(i32 (add (mul (and GPR:$rs1, 0xFF), (and GPR:$rs2, 0xFF)), GPR:$rs3)),
          (MADD GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

// 8-bit zero-extended commuted: c + zext8(a) * zext8(b)
def : Pat<(i32 (add GPR:$rs3, (mul (and GPR:$rs1, 0xFF), (and GPR:$rs2, 0xFF)))),
          (MADD GPR:$rs1, GPR:$rs2, GPR:$rs3)>;

//===----------------------------------------------------------------------===//
// CSEL/CMOV: Conditional Select/Move patterns
//===----------------------------------------------------------------------===//

// CSEL: rd = (rs3 == 0) ? rs1 : rs2
// CMOV: rd = (rs3 != 0) ? rs1 : rs2

// Pattern 1: Generic select - cond ? a : b
// SELECT treats non-zero as true, so: (cond != 0) ? a : b  ->  CMOV a, b, cond
def : Pat<(select (XLenVT GPR:$cond), (XLenVT GPR:$true_val), (XLenVT GPR:$false_val)),
          (CMOV GPR:$true_val, GPR:$false_val, GPR:$cond)>;

// Pattern 2: Select with zero value - cond ? a : 0
def : Pat<(select (XLenVT GPR:$cond), (XLenVT GPR:$true_val), (XLenVT 0)),
          (CMOV GPR:$true_val, (XLenVT X0), GPR:$cond)>;

// Pattern 3: Select with zero value - cond ? 0 : b
def : Pat<(select (XLenVT GPR:$cond), (XLenVT 0), (XLenVT GPR:$false_val)),
          (CSEL GPR:$false_val, (XLenVT X0), GPR:$cond)>;

// Pattern 4: select with riscv_seteq - (cond == 0) ? a : b  ->  CSEL a, b, cond
// Note: riscv_seteq means condition is true when cond==0
def : Pat<(select (riscv_seteq (XLenVT GPR:$cond)), (XLenVT GPR:$true_val), (XLenVT GPR:$false_val)),
          (CSEL GPR:$true_val, GPR:$false_val, GPR:$cond)>;

// Pattern 5: select with riscv_setne - (cond != 0) ? a : b  ->  CMOV a, b, cond
// Note: riscv_setne means condition is true when cond!=0
def : Pat<(select (riscv_setne (XLenVT GPR:$cond)), (XLenVT GPR:$true_val), (XLenVT GPR:$false_val)),
          (CMOV GPR:$true_val, GPR:$false_val, GPR:$cond)>;

// Pattern 6: select with zero - (cond == 0) ? a : 0
def : Pat<(select (riscv_seteq (XLenVT GPR:$cond)), (XLenVT GPR:$true_val), (XLenVT 0)),
          (CSEL GPR:$true_val, (XLenVT X0), GPR:$cond)>;

// Pattern 7: select with zero - (cond != 0) ? a : 0
def : Pat<(select (riscv_setne (XLenVT GPR:$cond)), (XLenVT GPR:$true_val), (XLenVT 0)),
          (CMOV GPR:$true_val, (XLenVT X0), GPR:$cond)>;

// Pattern 8: select with zero - (cond == 0) ? 0 : b
def : Pat<(select (riscv_seteq (XLenVT GPR:$cond)), (XLenVT 0), (XLenVT GPR:$false_val)),
          (CMOV GPR:$false_val, (XLenVT X0), GPR:$cond)>;

// Pattern 9: select with zero - (cond != 0) ? 0 : b
def : Pat<(select (riscv_setne (XLenVT GPR:$cond)), (XLenVT 0), (XLenVT GPR:$false_val)),
          (CSEL GPR:$false_val, (XLenVT X0), GPR:$cond)>;

//===----------------------------------------------------------------------===//
// BREV: Bit Reverse patterns
//===----------------------------------------------------------------------===//

// BREV: rd[i] = rs1[31-i]

// Pattern to match LLVM's bitreverse intrinsic
// When user calls __builtin_bitreverse32(x), LLVM generates (bitreverse i32 x)
def : Pat<(bitreverse (XLenVT GPR:$rs1)),
          (BREV GPR:$rs1)>;

} // Predicates = [HasStdExtXBiRiscV]
