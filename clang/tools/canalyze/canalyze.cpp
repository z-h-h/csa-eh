//===--- tools/canalyze++/canalyze.cpp - Canalyze++ tool ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
//  This file implements a canalyze++ tool that runs the clang static analyzer
//  based on the info stored in a compilation database.
//
//  Note: This is not a part of the original LLVM/Clang project.
//
//===----------------------------------------------------------------------===//

#include "clang/StaticAnalyzer/Frontend/FrontendActions.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/Tooling.h"
#include "llvm/Support/PrettyStackTrace.h"
#include "llvm/Support/Signals.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace clang;
using namespace tooling;

namespace {

cl::OptionCategory CanalyzeCategory("Canalyze++ options");

// User options.
cl::opt<std::string> OutputDir("o",
                               cl::desc("Write reports to directory <output>."),
                               cl::init("reports"), cl::cat(CanalyzeCategory));

// Hidden debug options.
cl::opt<bool> DebugVerify("debug-verify",
                          cl::desc("Verify diagnostic messages."),
                          cl::init(false), cl::cat(CanalyzeCategory),
                          cl::Hidden);

void PrintVersion(raw_ostream &OS) {
  // TODO: Finish this function.
  outs() << __PRETTY_FUNCTION__ << '\n';
}

CommandLineArguments CanalyzeArgumentAdjuster(const CommandLineArguments &Args,
                                              StringRef File) {
  CommandLineArguments Ret;

  // Keep the compiler at the front.
  auto I = Args.begin();
  Ret.emplace_back(*I++);

  // Add default analyzer options below.
  Ret.emplace_back("--analyze");

  for (auto E = Args.end(); I != E; ++I) {
    StringRef A(*I);

    if (A.startswith("-Werror")) {
      continue;
    } else if (A.startswith("-o")) {
      if ("-o" == A)
        ++I;
      continue;
    }

    Ret.emplace_back(A);
  }

  if (DebugVerify) {
    Ret.emplace_back("-Xclang");
    Ret.emplace_back("-verify");
  }
  Ret.emplace_back("-o");
  Ret.emplace_back(OutputDir);

  return Ret;
}

} // namespace

int main(int argc, const char *argv[]) {
  sys::PrintStackTraceOnErrorSignal(argv[0]);
  EnablePrettyStackTrace();

  cl::SetVersionPrinter(PrintVersion);
  auto Options =
      CommonOptionsParser::create(argc, argv, CanalyzeCategory, cl::ZeroOrMore);
  if (!Options) {
    errs() << Options.takeError();
    return 1;
  }

  auto &CDB = Options->getCompilations();
  auto &SrcList = Options->getSourcePathList();
  if (SrcList.empty()) {
    errs() << "No input files.\n";
    return 1;
  }
  ClangTool Tool(CDB, SrcList);
  Tool.clearArgumentsAdjusters();
  Tool.appendArgumentsAdjuster(getClangStripDependencyFileAdjuster());
  Tool.appendArgumentsAdjuster(CanalyzeArgumentAdjuster);

  return Tool.run(newFrontendActionFactory<ento::AnalysisAction>().get());
}
