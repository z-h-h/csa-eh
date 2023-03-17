//===-- PPCSubtarget.h - Define Subtarget for the PPC ----------*- C++ -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares the PowerPC specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_POWERPC_PPCSUBTARGET_H
#define LLVM_LIB_TARGET_POWERPC_PPCSUBTARGET_H

#include "PPCFrameLowering.h"
#include "PPCISelLowering.h"
#include "PPCInstrInfo.h"
#include "llvm/ADT/Triple.h"
#include "llvm/CodeGen/GlobalISel/CallLowering.h"
#include "llvm/CodeGen/GlobalISel/LegalizerInfo.h"
#include "llvm/CodeGen/GlobalISel/RegisterBankInfo.h"
#include "llvm/CodeGen/SelectionDAGTargetInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/MC/MCInstrItineraries.h"
#include <string>

#define GET_SUBTARGETINFO_HEADER
#include "PPCGenSubtargetInfo.inc"

// GCC #defines PPC on Linux but we use it as our namespace name
#undef PPC

namespace llvm {
class StringRef;

namespace PPC {
  // -m directive values.
enum {
  DIR_NONE,
  DIR_32,
  DIR_440,
  DIR_601,
  DIR_602,
  DIR_603,
  DIR_7400,
  DIR_750,
  DIR_970,
  DIR_A2,
  DIR_E500,
  DIR_E500mc,
  DIR_E5500,
  DIR_PWR3,
  DIR_PWR4,
  DIR_PWR5,
  DIR_PWR5X,
  DIR_PWR6,
  DIR_PWR6X,
  DIR_PWR7,
  DIR_PWR8,
  DIR_PWR9,
  DIR_PWR10,
  DIR_PWR_FUTURE,
  DIR_64
};
}

class GlobalValue;

class PPCSubtarget : public PPCGenSubtargetInfo {
public:
  enum POPCNTDKind {
    POPCNTD_Unavailable,
    POPCNTD_Slow,
    POPCNTD_Fast
  };

protected:
  /// TargetTriple - What processor and OS we're targeting.
  Triple TargetTriple;

  /// stackAlignment - The minimum alignment known to hold of the stack frame on
  /// entry to the function and which must be maintained by every function.
  Align StackAlignment;

  /// Selected instruction itineraries (one entry per itinerary class.)
  InstrItineraryData InstrItins;

  /// Which cpu directive was used.
  unsigned CPUDirective;

  /// Used by the ISel to turn in optimizations for POWER4-derived architectures
  bool HasMFOCRF;
  bool Has64BitSupport;
  bool Use64BitRegs;
  bool UseCRBits;
  bool HasHardFloat;
  bool IsPPC64;
  bool HasAltivec;
  bool HasFPU;
  bool HasSPE;
  bool HasEFPU2;
  bool HasVSX;
  bool NeedsTwoConstNR;
  bool HasP8Vector;
  bool HasP8Altivec;
  bool HasP8Crypto;
  bool HasP9Vector;
  bool HasP9Altivec;
  bool HasP10Vector;
  bool HasPrefixInstrs;
  bool HasPCRelativeMemops;
  bool HasMMA;
  bool HasROPProtection;
  bool HasFCPSGN;
  bool HasFSQRT;
  bool HasFRE, HasFRES, HasFRSQRTE, HasFRSQRTES;
  bool HasRecipPrec;
  bool HasSTFIWX;
  bool HasLFIWAX;
  bool HasFPRND;
  bool HasFPCVT;
  bool HasISEL;
  bool HasBPERMD;
  bool HasExtDiv;
  bool HasCMPB;
  bool HasLDBRX;
  bool IsBookE;
  bool HasOnlyMSYNC;
  bool IsE500;
  bool IsPPC4xx;
  bool IsPPC6xx;
  bool FeatureMFTB;
  bool AllowsUnalignedFPAccess;
  bool DeprecatedDST;
  bool IsLittleEndian;
  bool HasICBT;
  bool HasInvariantFunctionDescriptors;
  bool HasPartwordAtomics;
  bool HasDirectMove;
  bool HasHTM;
  bool HasFloat128;
  bool HasFusion;
  bool HasStoreFusion;
  bool HasAddiLoadFusion;
  bool HasAddisLoadFusion;
  bool IsISA3_0;
  bool IsISA3_1;
  bool UseLongCalls;
  bool SecurePlt;
  bool VectorsUseTwoUnits;
  bool UsePPCPreRASchedStrategy;
  bool UsePPCPostRASchedStrategy;
  bool PairedVectorMemops;
  bool PredictableSelectIsExpensive;
  bool HasModernAIXAs;
  bool IsAIX;

  POPCNTDKind HasPOPCNTD;

  const PPCTargetMachine &TM;
  PPCFrameLowering FrameLowering;
  PPCInstrInfo InstrInfo;
  PPCTargetLowering TLInfo;
  SelectionDAGTargetInfo TSInfo;

  /// GlobalISel related APIs.
  std::unique_ptr<CallLowering> CallLoweringInfo;
  std::unique_ptr<LegalizerInfo> Legalizer;
  std::unique_ptr<RegisterBankInfo> RegBankInfo;
  std::unique_ptr<InstructionSelector> InstSelector;

public:
  /// This constructor initializes the data members to match that
  /// of the specified triple.
  ///
  PPCSubtarget(const Triple &TT, const std::string &CPU, const std::string &FS,
               const PPCTargetMachine &TM);

  /// ParseSubtargetFeatures - Parses features string setting specified
  /// subtarget options.  Definition of function is auto generated by tblgen.
  void ParseSubtargetFeatures(StringRef CPU, StringRef TuneCPU, StringRef FS);

  /// getStackAlignment - Returns the minimum alignment known to hold of the
  /// stack frame on entry to the function and which must be maintained by every
  /// function for this subtarget.
  Align getStackAlignment() const { return StackAlignment; }

  /// getCPUDirective - Returns the -m directive specified for the cpu.
  ///
  unsigned getCPUDirective() const { return CPUDirective; }

  /// getInstrItins - Return the instruction itineraries based on subtarget
  /// selection.
  const InstrItineraryData *getInstrItineraryData() const override {
    return &InstrItins;
  }

  const PPCFrameLowering *getFrameLowering() const override {
    return &FrameLowering;
  }
  const PPCInstrInfo *getInstrInfo() const override { return &InstrInfo; }
  const PPCTargetLowering *getTargetLowering() const override {
    return &TLInfo;
  }
  const SelectionDAGTargetInfo *getSelectionDAGInfo() const override {
    return &TSInfo;
  }
  const PPCRegisterInfo *getRegisterInfo() const override {
    return &getInstrInfo()->getRegisterInfo();
  }
  const PPCTargetMachine &getTargetMachine() const { return TM; }

  /// initializeSubtargetDependencies - Initializes using a CPU and feature string
  /// so that we can use initializer lists for subtarget initialization.
  PPCSubtarget &initializeSubtargetDependencies(StringRef CPU, StringRef FS);

private:
  void initializeEnvironment();
  void initSubtargetFeatures(StringRef CPU, StringRef FS);

public:
  /// isPPC64 - Return true if we are generating code for 64-bit pointer mode.
  ///
  bool isPPC64() const;

  /// has64BitSupport - Return true if the selected CPU supports 64-bit
  /// instructions, regardless of whether we are in 32-bit or 64-bit mode.
  bool has64BitSupport() const { return Has64BitSupport; }
  // useSoftFloat - Return true if soft-float option is turned on.
  bool useSoftFloat() const {
    if (isAIXABI() && !HasHardFloat)
      report_fatal_error("soft-float is not yet supported on AIX.");
    return !HasHardFloat;
  }

  /// use64BitRegs - Return true if in 64-bit mode or if we should use 64-bit
  /// registers in 32-bit mode when possible.  This can only true if
  /// has64BitSupport() returns true.
  bool use64BitRegs() const { return Use64BitRegs; }

  /// useCRBits - Return true if we should store and manipulate i1 values in
  /// the individual condition register bits.
  bool useCRBits() const { return UseCRBits; }

  // isLittleEndian - True if generating little-endian code
  bool isLittleEndian() const { return IsLittleEndian; }

  // Specific obvious features.
  bool hasFCPSGN() const { return HasFCPSGN; }
  bool hasFSQRT() const { return HasFSQRT; }
  bool hasFRE() const { return HasFRE; }
  bool hasFRES() const { return HasFRES; }
  bool hasFRSQRTE() const { return HasFRSQRTE; }
  bool hasFRSQRTES() const { return HasFRSQRTES; }
  bool hasRecipPrec() const { return HasRecipPrec; }
  bool hasSTFIWX() const { return HasSTFIWX; }
  bool hasLFIWAX() const { return HasLFIWAX; }
  bool hasFPRND() const { return HasFPRND; }
  bool hasFPCVT() const { return HasFPCVT; }
  bool hasAltivec() const { return HasAltivec; }
  bool hasSPE() const { return HasSPE; }
  bool hasEFPU2() const { return HasEFPU2; }
  bool hasFPU() const { return HasFPU; }
  bool hasVSX() const { return HasVSX; }
  bool needsTwoConstNR() const { return NeedsTwoConstNR; }
  bool hasP8Vector() const { return HasP8Vector; }
  bool hasP8Altivec() const { return HasP8Altivec; }
  bool hasP8Crypto() const { return HasP8Crypto; }
  bool hasP9Vector() const { return HasP9Vector; }
  bool hasP9Altivec() const { return HasP9Altivec; }
  bool hasP10Vector() const { return HasP10Vector; }
  bool hasPrefixInstrs() const { return HasPrefixInstrs; }
  bool hasPCRelativeMemops() const { return HasPCRelativeMemops; }
  bool hasMMA() const { return HasMMA; }
  bool hasROPProtection() const { return HasROPProtection; }
  bool pairedVectorMemops() const { return PairedVectorMemops; }
  bool hasMFOCRF() const { return HasMFOCRF; }
  bool hasISEL() const { return HasISEL; }
  bool hasBPERMD() const { return HasBPERMD; }
  bool hasExtDiv() const { return HasExtDiv; }
  bool hasCMPB() const { return HasCMPB; }
  bool hasLDBRX() const { return HasLDBRX; }
  bool isBookE() const { return IsBookE; }
  bool hasOnlyMSYNC() const { return HasOnlyMSYNC; }
  bool isPPC4xx() const { return IsPPC4xx; }
  bool isPPC6xx() const { return IsPPC6xx; }
  bool isSecurePlt() const {return SecurePlt; }
  bool vectorsUseTwoUnits() const {return VectorsUseTwoUnits; }
  bool isE500() const { return IsE500; }
  bool isFeatureMFTB() const { return FeatureMFTB; }
  bool allowsUnalignedFPAccess() const { return AllowsUnalignedFPAccess; }
  bool isDeprecatedDST() const { return DeprecatedDST; }
  bool hasICBT() const { return HasICBT; }
  bool hasInvariantFunctionDescriptors() const {
    return HasInvariantFunctionDescriptors;
  }
  bool usePPCPreRASchedStrategy() const { return UsePPCPreRASchedStrategy; }
  bool usePPCPostRASchedStrategy() const { return UsePPCPostRASchedStrategy; }
  bool hasPartwordAtomics() const { return HasPartwordAtomics; }
  bool hasDirectMove() const { return HasDirectMove; }

  Align getPlatformStackAlignment() const {
    return Align(16);
  }

  unsigned  getRedZoneSize() const {
    if (isPPC64())
      // 288 bytes = 18*8 (FPRs) + 18*8 (GPRs, GPR13 reserved)
      return 288;

    // AIX PPC32: 220 bytes = 18*8 (FPRs) + 19*4 (GPRs);
    // PPC32 SVR4ABI has no redzone.
    return isAIXABI() ? 220 : 0;
  }

  bool hasHTM() const { return HasHTM; }
  bool hasFloat128() const { return HasFloat128; }
  bool isISA3_0() const { return IsISA3_0; }
  bool isISA3_1() const { return IsISA3_1; }
  bool useLongCalls() const { return UseLongCalls; }
  bool hasFusion() const { return HasFusion; }
  bool hasStoreFusion() const { return HasStoreFusion; }
  bool hasAddiLoadFusion() const { return HasAddiLoadFusion; }
  bool hasAddisLoadFusion() const { return HasAddisLoadFusion; }
  bool needsSwapsForVSXMemOps() const {
    return hasVSX() && isLittleEndian() && !hasP9Vector();
  }

  POPCNTDKind hasPOPCNTD() const { return HasPOPCNTD; }

  const Triple &getTargetTriple() const { return TargetTriple; }

  bool isTargetELF() const { return TargetTriple.isOSBinFormatELF(); }
  bool isTargetMachO() const { return TargetTriple.isOSBinFormatMachO(); }
  bool isTargetLinux() const { return TargetTriple.isOSLinux(); }

  bool isAIXABI() const { return TargetTriple.isOSAIX(); }
  bool isSVR4ABI() const { return !isAIXABI(); }
  bool isELFv2ABI() const;

  bool is64BitELFABI() const { return  isSVR4ABI() && isPPC64(); }
  bool is32BitELFABI() const { return  isSVR4ABI() && !isPPC64(); }
  bool isUsingPCRelativeCalls() const;

  /// Originally, this function return hasISEL(). Now we always enable it,
  /// but may expand the ISEL instruction later.
  bool enableEarlyIfConversion() const override { return true; }

  /// Scheduling customization.
  bool enableMachineScheduler() const override;
  /// Pipeliner customization.
  bool enableMachinePipeliner() const override;
  /// Machine Pipeliner customization
  bool useDFAforSMS() const override;
  /// This overrides the PostRAScheduler bit in the SchedModel for each CPU.
  bool enablePostRAScheduler() const override;
  AntiDepBreakMode getAntiDepBreakMode() const override;
  void getCriticalPathRCs(RegClassVector &CriticalPathRCs) const override;

  void overrideSchedPolicy(MachineSchedPolicy &Policy,
                           unsigned NumRegionInstrs) const override;
  bool useAA() const override;

  bool enableSubRegLiveness() const override;

  /// True if the GV will be accessed via an indirect symbol.
  bool isGVIndirectSymbol(const GlobalValue *GV) const;

  /// True if the ABI is descriptor based.
  bool usesFunctionDescriptors() const {
    // Both 32-bit and 64-bit AIX are descriptor based. For ELF only the 64-bit
    // v1 ABI uses descriptors.
    return isAIXABI() || (is64BitELFABI() && !isELFv2ABI());
  }

  unsigned descriptorTOCAnchorOffset() const {
    assert(usesFunctionDescriptors() &&
           "Should only be called when the target uses descriptors.");
    return IsPPC64 ? 8 : 4;
  }

  unsigned descriptorEnvironmentPointerOffset() const {
    assert(usesFunctionDescriptors() &&
           "Should only be called when the target uses descriptors.");
    return IsPPC64 ? 16 : 8;
  }

  MCRegister getEnvironmentPointerRegister() const {
    assert(usesFunctionDescriptors() &&
           "Should only be called when the target uses descriptors.");
     return IsPPC64 ? PPC::X11 : PPC::R11;
  }

  MCRegister getTOCPointerRegister() const {
    assert((is64BitELFABI() || isAIXABI()) &&
           "Should only be called when the target is a TOC based ABI.");
    return IsPPC64 ? PPC::X2 : PPC::R2;
  }

  MCRegister getStackPointerRegister() const {
    return IsPPC64 ? PPC::X1 : PPC::R1;
  }

  bool isXRaySupported() const override { return IsPPC64 && IsLittleEndian; }

  bool isPredictableSelectIsExpensive() const {
    return PredictableSelectIsExpensive;
  }

  // GlobalISEL
  const CallLowering *getCallLowering() const override;
  const RegisterBankInfo *getRegBankInfo() const override;
  const LegalizerInfo *getLegalizerInfo() const override;
  InstructionSelector *getInstructionSelector() const override;
};
} // End llvm namespace

#endif
