//===-- RISCVBiRiscVPatterns.cpp - BiRiscV Pattern Recognition ------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This pass looks for patterns that can be optimized using BiRiscV custom
// instructions, particularly the SAD (Sum of Absolute Differences) instruction.
//
// The SAD instruction computes:
//   rd = |rs1[7:0] - rs2[7:0]| + |rs1[15:8] - rs2[15:8]| +
//        |rs1[23:16] - rs2[23:16]| + |rs1[31:24] - rs2[31:24]| + rs3
//
// This pass recognizes C code patterns like:
//   acc += abs((int8_t)(a >> 0) - (int8_t)(b >> 0));
//   acc += abs((int8_t)(a >> 8) - (int8_t)(b >> 8));
//   acc += abs((int8_t)(a >> 16) - (int8_t)(b >> 16));
//   acc += abs((int8_t)(a >> 24) - (int8_t)(b >> 24));
//
// And replaces them with a single SAD instruction call.
//
//===----------------------------------------------------------------------===//

#include "RISCV.h"
#include "RISCVSubtarget.h"
#include "RISCVTargetMachine.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicsRISCV.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Pass.h"

using namespace llvm;
using namespace PatternMatch;

#define DEBUG_TYPE "riscv-biriscv-patterns"

namespace {

class RISCVBiRiscVPatterns : public FunctionPass {
  const DataLayout *DL = nullptr;
  const RISCVSubtarget *ST = nullptr;

public:
  static char ID; // Pass identification

  RISCVBiRiscVPatterns() : FunctionPass(ID) {}

  bool runOnFunction(Function &Fn) override;

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
    AU.addRequired<TargetPassConfig>();
  }

  StringRef getPassName() const override {
    return "RISCV BiRiscV Pattern Recognition";
  }

private:
  bool trySADReplacement(Instruction *Add);
  bool matchByteExtraction(Value *V, Value *&BaseValue, unsigned &ByteIndex);
  bool matchAbsoluteDifference(Value *V, Value *&LHS, Value *&RHS);
};

} // end anonymous namespace

char RISCVBiRiscVPatterns::ID = 0;

INITIALIZE_PASS(RISCVBiRiscVPatterns, DEBUG_TYPE,
                "RISCV BiRiscV Pattern Recognition", false, false)

FunctionPass *llvm::createRISCVBiRiscVPatternsPass() {
  return new RISCVBiRiscVPatterns();
}

// Helper function to match byte extraction patterns:
// Pattern 1: (sra (shl x, 24-8*i), 24)  - extracts byte i with sign extension
// Pattern 2: (and (lshr x, 8*i), 0xFF)  - extracts byte i with zero extension
// Pattern 3: (trunc (lshr x, 8*i))      - extracts byte i via truncation
bool RISCVBiRiscVPatterns::matchByteExtraction(Value *V, Value *&BaseValue,
                                                unsigned &ByteIndex) {

  // Look through casts (ZExt, SExt, Trunc) to find the actual byte extraction
  // This is necessary because LLVM may insert casts for type conversions
  if (auto *CI = dyn_cast<CastInst>(V)) {
    if (CI->getOpcode() == Instruction::ZExt ||
        CI->getOpcode() == Instruction::SExt ||
        CI->getOpcode() == Instruction::Trunc) {
      // Recursively match on the source of the cast
      return matchByteExtraction(CI->getOperand(0), BaseValue, ByteIndex);
    }
  }

  // Try to match: (ashr (shl X, C1), 24) where C1 = 24, 16, 8, 0
  Value *ShiftVal;
  const APInt *ShiftAmt1, *ShiftAmt2;

  // Pattern: (ashr (shl X, C1), 24)
  if (match(V, m_AShr(m_Shl(m_Value(ShiftVal), m_APInt(ShiftAmt1)),
                      m_APInt(ShiftAmt2)))) {
    if (ShiftAmt2->getZExtValue() == 24) {
      unsigned shift = ShiftAmt1->getZExtValue();
      if (shift == 24) { ByteIndex = 0; BaseValue = ShiftVal; return true; }
      if (shift == 16) { ByteIndex = 1; BaseValue = ShiftVal; return true; }
      if (shift == 8)  { ByteIndex = 2; BaseValue = ShiftVal; return true; }
      if (shift == 0)  { ByteIndex = 3; BaseValue = ShiftVal; return true; }
    }
  }

  // Pattern: (ashr X, 24) - extracts top byte
  if (match(V, m_AShr(m_Value(ShiftVal), m_APInt(ShiftAmt1)))) {
    if (ShiftAmt1->getZExtValue() == 24) {
      ByteIndex = 3;
      BaseValue = ShiftVal;
      return true;
    }
  }

  // Pattern: (and (lshr X, C), 0xFF)
  if (match(V, m_And(m_LShr(m_Value(ShiftVal), m_APInt(ShiftAmt1)),
                     m_SpecificInt(0xFF)))) {
    unsigned shift = ShiftAmt1->getZExtValue();
    if (shift == 0)  { ByteIndex = 0; BaseValue = ShiftVal; return true; }
    if (shift == 8)  { ByteIndex = 1; BaseValue = ShiftVal; return true; }
    if (shift == 16) { ByteIndex = 2; BaseValue = ShiftVal; return true; }
    if (shift == 24) { ByteIndex = 3; BaseValue = ShiftVal; return true; }
  }

  // Pattern: (and X, 0xFF) - extracts byte 0
  if (match(V, m_And(m_Value(ShiftVal), m_SpecificInt(0xFF)))) {
    ByteIndex = 0;
    BaseValue = ShiftVal;
    return true;
  }

  // Pattern: (lshr X, C) where C = 8, 16, or 24 (without explicit and mask)
  // This happens when LLVM knows the upper bits are already zero
  if (match(V, m_LShr(m_Value(ShiftVal), m_APInt(ShiftAmt1)))) {
    unsigned shift = ShiftAmt1->getZExtValue();
    if (shift == 8)  { ByteIndex = 1; BaseValue = ShiftVal; return true; }
    if (shift == 16) { ByteIndex = 2; BaseValue = ShiftVal; return true; }
    if (shift == 24) { ByteIndex = 3; BaseValue = ShiftVal; return true; }
  }

  // Pattern: load from memory (getelementptr ptr, offset)
  // This is for cases like: uint8_t x = ptr[i]
  // We need to extract the base pointer and offset
  if (auto *LI = dyn_cast<LoadInst>(V)) {
    Value *Ptr = LI->getPointerOperand();

    // Check if it's a direct load from base pointer (offset 0)
    if (isa<Argument>(Ptr) || isa<AllocaInst>(Ptr)) {
      ByteIndex = 0;
      BaseValue = Ptr;
      return true;
    }

    // Check if it's a GEP (getelementptr) with constant offset
    if (auto *GEP = dyn_cast<GetElementPtrInst>(Ptr)) {
      if (GEP->getNumIndices() == 1) {
        Value *BasePtr = GEP->getPointerOperand();
        Value *Idx = GEP->getOperand(1);

        if (auto *CI = dyn_cast<ConstantInt>(Idx)) {
          uint64_t offset = CI->getZExtValue();
          if (offset <= 3) {
            ByteIndex = offset;
            BaseValue = BasePtr;
            return true;
          }
        }
      }
    }
  }

  return false;
}

// Helper function to match absolute difference patterns:
// Pattern 1: call @llvm.abs.i32(sub(a, b), ...)
// Pattern 2: select (icmp a > b), sub(a, b), sub(b, a)
bool RISCVBiRiscVPatterns::matchAbsoluteDifference(Value *V, Value *&LHS, Value *&RHS) {
  // Pattern 1: abs intrinsic call
  if (auto *Call = dyn_cast<CallInst>(V)) {
    if (auto *Callee = Call->getCalledFunction()) {
      if (Callee->getIntrinsicID() == Intrinsic::abs) {
        Value *AbsInput = Call->getArgOperand(0);
        if (auto *Sub = dyn_cast<BinaryOperator>(AbsInput)) {
          if (Sub->getOpcode() == Instruction::Sub) {
            LHS = Sub->getOperand(0);
            RHS = Sub->getOperand(1);
            return true;
          }
        }
      }
    }
  }

  // Pattern 2: select-based abs
  // Match: select (icmp X, Y), sub(X, Y), sub(Y, X)
  if (auto *Select = dyn_cast<SelectInst>(V)) {
    Value *TrueVal = Select->getTrueValue();
    Value *FalseVal = Select->getFalseValue();

    // Both branches must be subtractions
    auto *TrueSub = dyn_cast<BinaryOperator>(TrueVal);
    auto *FalseSub = dyn_cast<BinaryOperator>(FalseVal);

    if (TrueSub && FalseSub &&
        TrueSub->getOpcode() == Instruction::Sub &&
        FalseSub->getOpcode() == Instruction::Sub) {

      Value *TrueOp0 = TrueSub->getOperand(0);
      Value *TrueOp1 = TrueSub->getOperand(1);
      Value *FalseOp0 = FalseSub->getOperand(0);
      Value *FalseOp1 = FalseSub->getOperand(1);

      // Check if it's abs pattern: sub(A,B) and sub(B,A)
      if (TrueOp0 == FalseOp1 && TrueOp1 == FalseOp0) {
        LHS = TrueOp0;
        RHS = TrueOp1;
        return true;
      }
    }
  }

  return false;
}

// Try to match SAD pattern iteratively (no recursive lambdas)
bool RISCVBiRiscVPatterns::trySADReplacement(Instruction *RootAdd) {
  // Must be an add instruction with 32-bit integer type
  if (RootAdd->getOpcode() != Instruction::Add || !RootAdd->getType()->isIntegerTy(32))
    return false;

  // Collect all values in the addition chain iteratively
  SmallVector<Value *, 16> Addends;
  SmallVector<BinaryOperator *, 16> AddChain;
  SmallVector<Value *, 16> Worklist;

  Worklist.push_back(RootAdd);

  // Iteratively explore the add chain
  while (!Worklist.empty()) {
    Value *V = Worklist.pop_back_val();

    if (auto *BO = dyn_cast<BinaryOperator>(V)) {
      if (BO->getOpcode() == Instruction::Add &&
          BO->getType()->isIntegerTy(32)) {
        // Track this add instruction
        AddChain.push_back(BO);
        // Explore both operands
        Worklist.push_back(BO->getOperand(0));
        Worklist.push_back(BO->getOperand(1));
        continue;
      }
    }

    // Not an add, this is a leaf value
    Addends.push_back(V);
  }

  // We need at least 4 abs operations + maybe an accumulator
  if (Addends.size() < 4)
    return false;

  // Try to find 4 absolute difference operations
  struct AbsDiffInfo {
    Value *BaseA;
    Value *BaseB;
    unsigned ByteIndex;
    Value *AbsValue;
  };

  SmallVector<AbsDiffInfo, 4> FoundAbsDiffs;
  Value *Accumulator = nullptr;

  for (Value *Addend : Addends) {
    // Try to match absolute difference (both abs() intrinsic and select-based)
    Value *DiffLHS, *DiffRHS;
    if (matchAbsoluteDifference(Addend, DiffLHS, DiffRHS)) {
      // Try to match byte extraction on both sides
      Value *BaseA, *BaseB;
      unsigned ByteIdxA, ByteIdxB;

      if (matchByteExtraction(DiffLHS, BaseA, ByteIdxA) &&
          matchByteExtraction(DiffRHS, BaseB, ByteIdxB) &&
          ByteIdxA == ByteIdxB) {
        // Found a valid abs(extract(a,i) - extract(b,i))
        FoundAbsDiffs.push_back({BaseA, BaseB, ByteIdxA, Addend});
        continue;
      }
    }

    // If not an abs-diff, could be the accumulator
    if (!Accumulator)
      Accumulator = Addend;
  }

  // We need exactly 4 byte absolute differences
  if (FoundAbsDiffs.size() != 4)
    return false;

  // Verify all 4 bytes are covered (0, 1, 2, 3)
  bool BytesSeen[4] = {false, false, false, false};
  for (const auto &Info : FoundAbsDiffs) {
    if (Info.ByteIndex >= 4)
      return false;
    BytesSeen[Info.ByteIndex] = true;
  }

  if (!BytesSeen[0] || !BytesSeen[1] || !BytesSeen[2] || !BytesSeen[3])
    return false;

  // Verify all diffs use the same base values
  Value *BaseA = FoundAbsDiffs[0].BaseA;
  Value *BaseB = FoundAbsDiffs[0].BaseB;
  for (const auto &Info : FoundAbsDiffs) {
    if (Info.BaseA != BaseA || Info.BaseB != BaseB)
      return false;
  }

  // If no accumulator found, use zero
  if (!Accumulator)
    Accumulator = ConstantInt::get(RootAdd->getType(), 0);

  // SUCCESS! Replace with SAD intrinsic
  IRBuilder<> Builder(RootAdd);

  Function *SADFn = Intrinsic::getOrInsertDeclaration(
      RootAdd->getModule(), Intrinsic::riscv_biriscv_sad);

  // Check if BaseA and BaseB are pointers (memory load case)
  // If so, we need to load and pack the bytes first
  Value *PackedA = BaseA;
  Value *PackedB = BaseB;

  if (BaseA->getType()->isPointerTy()) {
    // Memory load case: load 4 bytes and pack them into i32
    // Create loads for each byte
    SmallVector<Value *, 4> BytesA, BytesB;

    for (unsigned i = 0; i < 4; i++) {
      // Create GEP for offset i
      Value *PtrA = Builder.CreateConstGEP1_32(Builder.getInt8Ty(), BaseA, i);
      Value *PtrB = Builder.CreateConstGEP1_32(Builder.getInt8Ty(), BaseB, i);

      // Load the bytes
      Value *ByteA = Builder.CreateLoad(Builder.getInt8Ty(), PtrA);
      Value *ByteB = Builder.CreateLoad(Builder.getInt8Ty(), PtrB);

      // Zero-extend to i32
      BytesA.push_back(Builder.CreateZExt(ByteA, Builder.getInt32Ty()));
      BytesB.push_back(Builder.CreateZExt(ByteB, Builder.getInt32Ty()));
    }

    // Pack bytes into i32: (byte3 << 24) | (byte2 << 16) | (byte1 << 8) | byte0
    PackedA = BytesA[0];
    PackedB = BytesB[0];

    for (unsigned i = 1; i < 4; i++) {
      Value *ShiftedA = Builder.CreateShl(BytesA[i], i * 8);
      Value *ShiftedB = Builder.CreateShl(BytesB[i], i * 8);
      PackedA = Builder.CreateOr(PackedA, ShiftedA);
      PackedB = Builder.CreateOr(PackedB, ShiftedB);
    }
  }

  Value *SADResult = Builder.CreateCall(SADFn, {PackedA, PackedB, Accumulator});

  RootAdd->replaceAllUsesWith(SADResult);

  // Clean up dead instructions
  for (auto *Inst : AddChain) {
    if (Inst->use_empty() && Inst != RootAdd)
      Inst->eraseFromParent();
  }

  if (RootAdd->use_empty())
    RootAdd->eraseFromParent();

  return true;
}

bool RISCVBiRiscVPatterns::runOnFunction(Function &Fn) {
  if (skipFunction(Fn))
    return false;

  auto &TPC = getAnalysis<TargetPassConfig>();
  auto &TM = TPC.getTM<RISCVTargetMachine>();
  ST = &TM.getSubtarget<RISCVSubtarget>(Fn);
  DL = &Fn.getDataLayout();

  // Check if BiRiscV extension is enabled
  if (!ST->hasStdExtXBiRiscV())
    return false;

  bool MadeChange = false;

  // Walk through all instructions looking for patterns
  for (BasicBlock &BB : Fn) {
    for (Instruction &I : make_early_inc_range(BB)) {
      if (auto *Add = dyn_cast<BinaryOperator>(&I)) {
        if (trySADReplacement(Add))
          MadeChange = true;
      }
    }
  }

  return MadeChange;
}
