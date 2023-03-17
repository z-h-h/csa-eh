//===- Transforms/Instrumentation/InstrProfiling.h --------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
/// \file
/// This file provides the interface for LLVM's PGO Instrumentation lowering
/// pass.
//===----------------------------------------------------------------------===//

#ifndef LLVM_TRANSFORMS_INSTRUMENTATION_INSTRPROFILING_H
#define LLVM_TRANSFORMS_INSTRUMENTATION_INSTRPROFILING_H

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/PassManager.h"
#include "llvm/ProfileData/InstrProf.h"
#include "llvm/Transforms/Instrumentation.h"
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <vector>

namespace llvm {

class TargetLibraryInfo;
using LoadStorePair = std::pair<Instruction *, Instruction *>;

/// Instrumentation based profiling lowering pass. This pass lowers
/// the profile instrumented code generated by FE or the IR based
/// instrumentation pass.
class InstrProfiling : public PassInfoMixin<InstrProfiling> {
public:
  InstrProfiling() : IsCS(false) {}
  InstrProfiling(const InstrProfOptions &Options, bool IsCS = false)
      : Options(Options), IsCS(IsCS) {}

  PreservedAnalyses run(Module &M, ModuleAnalysisManager &AM);
  bool run(Module &M,
           std::function<const TargetLibraryInfo &(Function &F)> GetTLI);

private:
  InstrProfOptions Options;
  Module *M;
  Triple TT;
  std::function<const TargetLibraryInfo &(Function &F)> GetTLI;
  struct PerFunctionProfileData {
    uint32_t NumValueSites[IPVK_Last + 1];
    GlobalVariable *RegionCounters = nullptr;
    GlobalVariable *DataVar = nullptr;

    PerFunctionProfileData() {
      memset(NumValueSites, 0, sizeof(uint32_t) * (IPVK_Last + 1));
    }
  };
  DenseMap<GlobalVariable *, PerFunctionProfileData> ProfileDataMap;
  std::vector<GlobalValue *> UsedVars;
  std::vector<GlobalVariable *> ReferencedNames;
  GlobalVariable *NamesVar;
  size_t NamesSize;

  // Is this lowering for the context-sensitive instrumentation.
  bool IsCS;

  // vector of counter load/store pairs to be register promoted.
  std::vector<LoadStorePair> PromotionCandidates;

  int64_t TotalCountersPromoted = 0;

  /// Lower instrumentation intrinsics in the function. Returns true if there
  /// any lowering.
  bool lowerIntrinsics(Function *F);

  /// Register-promote counter loads and stores in loops.
  void promoteCounterLoadStores(Function *F);

  /// Returns true if relocating counters at runtime is enabled.
  bool isRuntimeCounterRelocationEnabled() const;

  /// Returns true if profile counter update register promotion is enabled.
  bool isCounterPromotionEnabled() const;

  /// Count the number of instrumented value sites for the function.
  void computeNumValueSiteCounts(InstrProfValueProfileInst *Ins);

  /// Replace instrprof_value_profile with a call to runtime library.
  void lowerValueProfileInst(InstrProfValueProfileInst *Ins);

  /// Replace instrprof_increment with an increment of the appropriate value.
  void lowerIncrement(InstrProfIncrementInst *Inc);

  /// Force emitting of name vars for unused functions.
  void lowerCoverageData(GlobalVariable *CoverageNamesVar);

  /// Get the region counters for an increment, creating them if necessary.
  ///
  /// If the counter array doesn't yet exist, the profile data variables
  /// referring to them will also be created.
  GlobalVariable *getOrCreateRegionCounters(InstrProfIncrementInst *Inc);

  /// Emit the section with compressed function names.
  void emitNameData();

  /// Emit value nodes section for value profiling.
  void emitVNodes();

  /// Emit runtime registration functions for each profile data variable.
  void emitRegistration();

  /// Emit the necessary plumbing to pull in the runtime initialization.
  /// Returns true if a change was made.
  bool emitRuntimeHook();

  /// Add uses of our data variables and runtime hook.
  void emitUses();

  /// Create a static initializer for our data, on platforms that need it,
  /// and for any profile output file that was specified.
  void emitInitialization();
};

} // end namespace llvm

#endif // LLVM_TRANSFORMS_INSTRUMENTATION_INSTRPROFILING_H
