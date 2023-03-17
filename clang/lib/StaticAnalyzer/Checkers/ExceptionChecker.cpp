//===- ExceptionChecker - Various exception issues checker -----*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This defines ExceptionChecker, which checks for various exception issues.
//
//===----------------------------------------------------------------------===//

#include "clang/StaticAnalyzer/Checkers/BuiltinCheckerRegistration.h"
#include "clang/StaticAnalyzer/Core/Checker.h"
#include "clang/StaticAnalyzer/Core/PathSensitive/CheckerContext.h"

using namespace clang;
using namespace ento;

namespace {
class ExceptionChecker
    : public Checker<check::EndFunction, check::PreStmt<CXXThrowExpr>> {
  BugType BT_1{this, "Throw out of destructor", "Exception"};
  BugType BT_2{this, "Re-throw without exception", "Exception"};

  void reportBug(const BugType &BT, StringRef Desc, ProgramStateRef State,
                 CheckerContext &C) const;

public:
  void checkEndFunction(const ReturnStmt *RS, CheckerContext &C) const;
  void checkPreStmt(const CXXThrowExpr *CTE, CheckerContext &C) const;
};
} // namespace

void ExceptionChecker::reportBug(const BugType &BT, StringRef Desc,
                                 ProgramStateRef State,
                                 CheckerContext &C) const {
  ExplodedNode *N = C.generateErrorNode(State);
  if (!N)
    return;
  auto R = std::make_unique<PathSensitiveBugReport>(BT, Desc, N);
  C.emitReport(std::move(R));
}

void ExceptionChecker::checkEndFunction(const ReturnStmt *RS,
                                        CheckerContext &C) const {
  ProgramStateRef State = C.getState();
  const StackFrameContext *SFC = C.getStackFrame();
  if (!State->hasUncaughtThrow() || SFC->inTopFrame())
    return;
  const auto &E = SFC->getCallSiteCFGElement();
  if (!E.getAs<CFGImplicitDtor>())
    return;
  reportBug(BT_1, "Exception being thrown out of destructor", State, C);
}

void ExceptionChecker::checkPreStmt(const CXXThrowExpr *CTE,
                                    CheckerContext &C) const {
  ProgramStateRef State = C.getState();
  if (CTE->getSubExpr() || !State->getCaughtVals().empty())
    return;
  reportBug(BT_2, "Re-throw without an existing exception", State, C);
}

void ento::registerExceptionChecker(CheckerManager &Mgr) {
  Mgr.registerChecker<ExceptionChecker>();
}

bool ento::shouldRegisterExceptionChecker(const CheckerManager &mgr) {
  return true;
}
