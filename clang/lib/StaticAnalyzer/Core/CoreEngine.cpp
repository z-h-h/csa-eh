//===- CoreEngine.cpp - Path-Sensitive Dataflow Engine --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
//  This file defines a generic engine for intraprocedural, path-sensitive,
//  dataflow analysis via graph reachability engine.
//
//===----------------------------------------------------------------------===//

#include "clang/StaticAnalyzer/Core/PathSensitive/CoreEngine.h"
#include "clang/AST/Expr.h"
#include "clang/AST/ExprCXX.h"
#include "clang/AST/Stmt.h"
#include "clang/AST/StmtCXX.h"
#include "clang/Analysis/AnalysisDeclContext.h"
#include "clang/Analysis/CFG.h"
#include "clang/Analysis/ProgramPoint.h"
#include "clang/Basic/LLVM.h"
#include "clang/StaticAnalyzer/Core/AnalyzerOptions.h"
#include "clang/StaticAnalyzer/Core/PathSensitive/BlockCounter.h"
#include "clang/StaticAnalyzer/Core/PathSensitive/ExplodedGraph.h"
#include "clang/StaticAnalyzer/Core/PathSensitive/ExprEngine.h"
#include "clang/StaticAnalyzer/Core/PathSensitive/FunctionSummary.h"
#include "clang/StaticAnalyzer/Core/PathSensitive/WorkList.h"
#include "llvm/ADT/Optional.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/ErrorHandling.h"
#include <algorithm>
#include <cassert>
#include <memory>
#include <utility>

using namespace clang;
using namespace ento;

#define DEBUG_TYPE "CoreEngine"

STATISTIC(NumSteps,
            "The # of steps executed.");
STATISTIC(NumReachedMaxSteps,
            "The # of times we reached the max number of steps.");
STATISTIC(NumPathsExplored,
            "The # of paths explored by the analyzer.");
STATISTIC(NumExceptionPathsExplored,
            "The # of exception paths explored by the analyzer.");
STATISTIC(NumCFGBlocks,
            "The # of CFG blocks.");
STATISTIC(NumMergedCFGBlocks,
            "The # of merged CFG blocks.");
STATISTIC(NumUnmergedCFGBlocks,
            "The # of unmerged CFG Blocks.");

llvm::DenseSet<const CFG*> VisitedCFG;

//===----------------------------------------------------------------------===//
// Core analysis engine.
//===----------------------------------------------------------------------===//

static std::unique_ptr<WorkList> generateWorkList(AnalyzerOptions &Opts) {
  switch (Opts.getExplorationStrategy()) {
    case ExplorationStrategyKind::DFS:
      return WorkList::makeDFS();
    case ExplorationStrategyKind::BFS:
      return WorkList::makeBFS();
    case ExplorationStrategyKind::BFSBlockDFSContents:
      return WorkList::makeBFSBlockDFSContents();
    case ExplorationStrategyKind::UnexploredFirst:
      return WorkList::makeUnexploredFirst();
    case ExplorationStrategyKind::UnexploredFirstQueue:
      return WorkList::makeUnexploredFirstPriorityQueue();
    case ExplorationStrategyKind::UnexploredFirstLocationQueue:
      return WorkList::makeUnexploredFirstPriorityLocationQueue();
  }
  llvm_unreachable("Unknown AnalyzerOptions::ExplorationStrategyKind");
}

CoreEngine::CoreEngine(ExprEngine &exprengine, FunctionSummariesTy *FS,
                       AnalyzerOptions &Opts)
    : ExprEng(exprengine), WList(generateWorkList(Opts)),
      BCounterFactory(G.getAllocator()), FunctionSummaries(FS) {}

/// ExecuteWorkList - Run the worklist algorithm for a maximum number of steps.
bool CoreEngine::ExecuteWorkList(const LocationContext *L, unsigned Steps,
                                   ProgramStateRef InitState) {
  if (!VisitedCFG.contains(L->getCFG())) {
    const CFG *cfg = L->getCFG();
    VisitedCFG.insert(cfg);
    NumCFGBlocks += cfg->getNumBlockIDs();
    NumMergedCFGBlocks += cfg->getNumMergedBlocks();
    NumUnmergedCFGBlocks += cfg->getNumUnmergedBlocks();
  }

  if (G.num_roots() == 0) { // Initialize the analysis by constructing
    // the root if none exists.

    const CFGBlock *Entry = &(L->getCFG()->getEntry());

    assert(Entry->empty() && "Entry block must be empty.");

    assert(Entry->succ_size() == 1 && "Entry block must have 1 successor.");

    // Mark the entry block as visited.
    FunctionSummaries->markVisitedBasicBlock(Entry->getBlockID(),
                                             L->getDecl(),
                                             L->getCFG()->getNumBlockIDs());

    // Get the solitary successor.
    const CFGBlock *Succ = *(Entry->succ_begin());

    // Construct an edge representing the
    // starting location in the function.
    BlockEdge StartLoc(Entry, Succ, L);

    // Set the current block counter to being empty.
    WList->setBlockCounter(BCounterFactory.GetEmptyCounter());

    if (!InitState)
      InitState = ExprEng.getInitialState(L);

    bool IsNew;
    ExplodedNode *Node = G.getNode(StartLoc, InitState, false, &IsNew);
    assert(IsNew);
    G.addRoot(Node);

    NodeBuilderContext BuilderCtx(*this, StartLoc.getDst(), Node);
    ExplodedNodeSet DstBegin;
    ExprEng.processBeginOfFunction(BuilderCtx, Node, DstBegin, StartLoc);

    enqueue(DstBegin);
  }

  // Check if we have a steps limit
  bool UnlimitedSteps = Steps == 0;
  // Cap our pre-reservation in the event that the user specifies
  // a very large number of maximum steps.
  const unsigned PreReservationCap = 4000000;
  if(!UnlimitedSteps)
    G.reserve(std::min(Steps,PreReservationCap));

  while (WList->hasWork()) {
    if (!UnlimitedSteps) {
      if (Steps == 0) {
        NumReachedMaxSteps++;
        break;
      }
      --Steps;
    }

    NumSteps++;

    const WorkListUnit& WU = WList->dequeue();

    // Set the current block counter.
    WList->setBlockCounter(WU.getBlockCounter());

    // Retrieve the node.
    ExplodedNode *Node = WU.getNode();

    dispatchWorkItem(Node, Node->getLocation(), WU);
  }
  ExprEng.processEndWorklist();
  return WList->hasWork();
}

void CoreEngine::dispatchWorkItem(ExplodedNode* Pred, ProgramPoint Loc,
                                  const WorkListUnit& WU) {
  // Dispatch on the location type.
  switch (Loc.getKind()) {
    case ProgramPoint::BlockEdgeKind:
      HandleBlockEdge(Loc.castAs<BlockEdge>(), Pred);
      break;

    case ProgramPoint::BlockEntranceKind:
      HandleBlockEntrance(Loc.castAs<BlockEntrance>(), Pred);
      break;

    case ProgramPoint::BlockExitKind:
      assert(false && "BlockExit location never occur in forward analysis.");
      break;

    case ProgramPoint::CallEnterKind:
      HandleCallEnter(Loc.castAs<CallEnter>(), Pred);
      break;

    case ProgramPoint::CallExitBeginKind:
      ExprEng.processCallExit(Pred);
      break;

    case ProgramPoint::CallExitEndKind:
      if (Pred->getState()->hasUncaughtThrow()) {
        // Returning from a function where exception being thrown
        CFGElement E = (*WU.getBlock())[WU.getIndex()];
        if (E.getAs<CFGImplicitDtor>()) {
          // Destructor throws an exception (see ExceptionChecker)
          return;
        }
        CFGStmt Stmt = E.castAs<CFGStmt>();
        ProgramStateRef State = Pred->getState();
        const CFGBlock *Try = Stmt.getTryBlock();
        if (Try != &Pred->getCFG().getExit()) {
          State = State->setUncaughtThrow(false);
          State = State->setTryBlockIdx(Stmt.getDtorIdx());
        }
        BlockEdge BE(WU.getBlock(), Try, Pred->getLocationContext());
        generateNode(BE, State, Pred);
      } else if (WU.getBlock()->isTryBlock()) {
        // Returning from an automatic object dtor in try block
        const CFGBlock *Try = WU.getBlock();
        int PrevIdx = WU.getIndex() - 1;
        auto PrevDtor = (*Try)[PrevIdx].castAs<CFGAutomaticObjDtor>();
        int NextIdx = PrevDtor.getNextDtorIdx();
        NextIdx = NextIdx == -1 ? Try->size() : NextIdx;
        HandlePostStmt(Try, NextIdx, Pred);
      } else {
        // Normal call return
        HandlePostStmt(WU.getBlock(), WU.getIndex(), Pred);
      }
      break;

    case ProgramPoint::PostImplicitCallKind:
      // Some automatic obj dtors could not be inlined. (e.g. STL containers)
      // If so, there would be a PIC rather than CEE
      if (WU.getBlock()->isTryBlock()) {
        // Returning from an automatic object dtor in try block
        const CFGBlock *Try = WU.getBlock();
        int PrevIdx = WU.getIndex() - 1;
        auto PrevDtor = (*Try)[PrevIdx].castAs<CFGAutomaticObjDtor>();
        int NextIdx = PrevDtor.getNextDtorIdx();
        NextIdx = NextIdx == -1 ? Try->size() : NextIdx;
        HandlePostStmt(Try, NextIdx, Pred);
      } else {
        // Normal call return
        HandlePostStmt(WU.getBlock(), WU.getIndex(), Pred);
      }
      break;

    case ProgramPoint::EpsilonKind: {
      assert(Pred->hasSinglePred() &&
             "Assume epsilon has exactly one predecessor by construction");
      ExplodedNode *PNode = Pred->getFirstPred();
      dispatchWorkItem(Pred, PNode->getLocation(), WU);
      break;
    }
    default:
      assert(Loc.getAs<PostStmt>() ||
             Loc.getAs<PostInitializer>() ||
             Loc.getAs<LoopExit>() ||
             Loc.getAs<PostAllocatorCall>());
      HandlePostStmt(WU.getBlock(), WU.getIndex(), Pred);
      break;
  }
}

bool CoreEngine::ExecuteWorkListWithInitialState(const LocationContext *L,
                                                 unsigned Steps,
                                                 ProgramStateRef InitState,
                                                 ExplodedNodeSet &Dst) {
  bool DidNotFinish = ExecuteWorkList(L, Steps, InitState);
  for (ExplodedGraph::eop_iterator I = G.eop_begin(), E = G.eop_end(); I != E;
       ++I) {
    Dst.Add(*I);
  }
  return DidNotFinish;
}

static ExplodedNode *CheckAndPopCaughtVals(const CFGBlock *Src, const CFGBlock *Dst,
                                  ExplodedNode *Pred, ExplodedGraph &G) {
  const auto &SrcQue = Src->getCatchStmts();
  const auto &DstQue = Dst->getCatchStmts();
  // SrcQue & DstQue should have the same prefixes
  // FIXME: a goto statement might cause totally different
  int Min = SrcQue.size() > DstQue.size() ? DstQue.size() : SrcQue.size();
  for (int i = 0; i < Min; i++)
    assert(SrcQue[i] == DstQue[i]);
  int Pop = SrcQue.size() - DstQue.size();
  if (Pop > 0) {
    ProgramStateRef NewState = Pred->getState()->popCaughtVals(Pop);
    ExplodedNode *UpdatedNode = G.getNode(Pred->getLocation(), NewState);
    UpdatedNode->addPredecessor(Pred, G);
    return UpdatedNode;
  }
  return Pred;
}

void CoreEngine::HandleBlockEdge(const BlockEdge &L, ExplodedNode *Pred) {
  Pred = CheckAndPopCaughtVals(L.getSrc(), L.getDst(), Pred, G);
  const CFGBlock *Blk = L.getDst();
  NodeBuilderContext BuilderCtx(*this, Blk, Pred);

  // Mark this block as visited.
  const LocationContext *LC = Pred->getLocationContext();
  FunctionSummaries->markVisitedBasicBlock(Blk->getBlockID(),
                                           LC->getDecl(),
                                           LC->getCFG()->getNumBlockIDs());

  // Display a prunable path note to the user if it's a virtual bases branch
  // and we're taking the path that skips virtual base constructors.
  if (L.getSrc()->getTerminator().isVirtualBaseBranch() &&
      L.getDst() == *L.getSrc()->succ_begin()) {
    ProgramPoint P = L.withTag(getNoteTags().makeNoteTag(
        [](BugReporterContext &, PathSensitiveBugReport &) -> std::string {
          // TODO: Just call out the name of the most derived class
          // when we know it.
          return "Virtual base initialization skipped because "
                 "it has already been handled by the most derived class";
        }, /*IsPrunable=*/true));
    // Perform the transition.
    ExplodedNodeSet Dst;
    NodeBuilder Bldr(Pred, Dst, BuilderCtx);
    Pred = Bldr.generateNode(P, Pred->getState(), Pred);
    if (!Pred)
      return;
  }

  // Check if we are entering the EXIT block.
  if (Blk == &(L.getLocationContext()->getCFG()->getExit())) {
    assert(L.getLocationContext()->getCFG()->getExit().empty() &&
           "EXIT block cannot contain Stmts.");

    // Get return statement..
    const ReturnStmt *RS = nullptr;
    if (!L.getSrc()->empty()) {
      CFGElement LastElement = L.getSrc()->back();
      if (Optional<CFGStmt> LastStmt = LastElement.getAs<CFGStmt>()) {
        RS = dyn_cast<ReturnStmt>(LastStmt->getStmt());
      } else if (Optional<CFGAutomaticObjDtor> AutoDtor =
                 LastElement.getAs<CFGAutomaticObjDtor>()) {
        RS = dyn_cast<ReturnStmt>(AutoDtor->getTriggerStmt());
      }
    }

    // Process the final state transition.
    ExprEng.processEndOfFunction(BuilderCtx, Pred, RS);

    // This path is done. Don't enqueue any more nodes.
    return;
  }

  // Call into the ExprEngine to process entering the CFGBlock.
  ExplodedNodeSet dstNodes;
  BlockEntrance BE(Blk, Pred->getLocationContext());
  NodeBuilderWithSinks nodeBuilder(Pred, dstNodes, BuilderCtx, BE);
  ExprEng.processCFGBlockEntrance(L, nodeBuilder, Pred);

  // Auto-generate a node.
  if (!nodeBuilder.hasGeneratedNodes()) {
    nodeBuilder.generateNode(Pred->State, Pred);
  }

  // Enqueue nodes onto the worklist.
  enqueue(dstNodes);
}

void CoreEngine::HandleBlockEntrance(const BlockEntrance &L,
                                       ExplodedNode *Pred) {
  // Increment the block counter.
  const LocationContext *LC = Pred->getLocationContext();
  unsigned BlockId = L.getBlock()->getBlockID();
  BlockCounter Counter = WList->getBlockCounter();
  Counter = BCounterFactory.IncrementCount(Counter, LC->getStackFrame(),
                                           BlockId);
  WList->setBlockCounter(Counter);

  const CFGBlock *B = L.getBlock();
  int Idx = 0;
  if (B->isTryBlock())
    Idx = Pred->getState()->getTryBlockIdx();
  Idx = Idx == -1 ? B->size() : Idx;

  if (Idx == (int)B->size()) {
    HandleBlockExit(L.getBlock(), Pred);
  } else {
    NodeBuilderContext Ctx(*this, L.getBlock(), Pred);
    ExprEng.processCFGElement((*B)[Idx], Pred, Idx, &Ctx);
  }
}

void CoreEngine::HandleBlockExit(const CFGBlock * B, ExplodedNode *Pred) {
  if (const Stmt *Term = B->getTerminatorStmt()) {
    switch (Term->getStmtClass()) {
      default:
        llvm_unreachable("Analysis for this terminator not implemented.");

      case Stmt::CXXBindTemporaryExprClass:
        HandleCleanupTemporaryBranch(
            cast<CXXBindTemporaryExpr>(Term), B, Pred);
        return;

      // Model static initializers.
      case Stmt::DeclStmtClass:
        HandleStaticInit(cast<DeclStmt>(Term), B, Pred);
        return;

      case Stmt::BinaryOperatorClass: // '&&' and '||'
        HandleBranch(cast<BinaryOperator>(Term)->getLHS(), Term, B, Pred);
        return;

      case Stmt::BinaryConditionalOperatorClass:
      case Stmt::ConditionalOperatorClass:
        HandleBranch(cast<AbstractConditionalOperator>(Term)->getCond(),
                     Term, B, Pred);
        return;

        // FIXME: Use constant-folding in CFG construction to simplify this
        // case.

      case Stmt::ChooseExprClass:
        HandleBranch(cast<ChooseExpr>(Term)->getCond(), Term, B, Pred);
        return;

      case Stmt::CXXTryStmtClass:
        HandleTryStmt(B, B->getTerminator().getNextDtorIdx(), Pred);
        return;

      case Stmt::DoStmtClass:
        HandleBranch(cast<DoStmt>(Term)->getCond(), Term, B, Pred);
        return;

      case Stmt::CXXForRangeStmtClass:
        HandleBranch(cast<CXXForRangeStmt>(Term)->getCond(), Term, B, Pred);
        return;

      case Stmt::ForStmtClass:
        HandleBranch(cast<ForStmt>(Term)->getCond(), Term, B, Pred);
        return;

      case Stmt::ContinueStmtClass:
      case Stmt::BreakStmtClass:
      case Stmt::GotoStmtClass:
        break;

      case Stmt::IfStmtClass:
        HandleBranch(cast<IfStmt>(Term)->getCond(), Term, B, Pred);
        return;

      case Stmt::IndirectGotoStmtClass: {
        // Only 1 successor: the indirect goto dispatch block.
        assert(B->succ_size() == 1);

        IndirectGotoNodeBuilder
           builder(Pred, B, cast<IndirectGotoStmt>(Term)->getTarget(),
                   *(B->succ_begin()), this);

        ExprEng.processIndirectGoto(builder);
        return;
      }

      case Stmt::ObjCForCollectionStmtClass:
        // In the case of ObjCForCollectionStmt, it appears twice in a CFG:
        //
        //  (1) inside a basic block, which represents the binding of the
        //      'element' variable to a value.
        //  (2) in a terminator, which represents the branch.
        //
        // For (1), ExprEngine will bind a value (i.e., 0 or 1) indicating
        // whether or not collection contains any more elements.  We cannot
        // just test to see if the element is nil because a container can
        // contain nil elements.
        HandleBranch(Term, Term, B, Pred);
        return;

      case Stmt::SwitchStmtClass: {
        SwitchNodeBuilder builder(Pred, B, cast<SwitchStmt>(Term)->getCond(),
                                    this);

        ExprEng.processSwitch(builder);
        return;
      }

      case Stmt::WhileStmtClass:
        HandleBranch(cast<WhileStmt>(Term)->getCond(), Term, B, Pred);
        return;

      case Stmt::GCCAsmStmtClass:
        assert(cast<GCCAsmStmt>(Term)->isAsmGoto() && "Encountered GCCAsmStmt without labels");
        // TODO: Handle jumping to labels
        return;
    }
  }

  if (B->getTerminator().isVirtualBaseBranch()) {
    HandleVirtualBaseBranch(B, Pred);
    return;
  }

  assert(B->succ_size() == 1 &&
         "Blocks with no terminator should have at most 1 successor.");

  // If this block is a top level pseudo try block, mark uncaught throw.
  if (B == B->getParent()->getPseudoTryBlock()) {
    generateNode(BlockEdge(B, *(B->succ_begin()), Pred->getLocationContext()),
                 Pred->getState()->setUncaughtThrow(true), Pred);
    return;
  }

  generateNode(BlockEdge(B, *(B->succ_begin()), Pred->getLocationContext()),
               Pred->State, Pred);
}

void CoreEngine::HandleTryStmt(const CFGBlock *TryBlock, int NextDtorIdx,
                               ExplodedNode *Pred) {
  QualType ThrownType = Pred->State->getThrownVals().back().second;
  for (CFGBlock::const_succ_iterator it = TryBlock->succ_begin(),
                                     et = TryBlock->succ_end() - 1;
       it != et; ++it) {
    const CFGBlock *CatchBlock = *it;
    Optional<CFGStmt> CS = CatchBlock->front().getAs<CFGStmt>();
    const CXXCatchStmt *CatchStmt = dyn_cast<CXXCatchStmt>(CS->getStmt());
    QualType CaughtType = CatchStmt->getCaughtType();
    if (MatchThrownTypeAndCaughtType(ThrownType, CaughtType)) {
      generateNode(BlockEdge(TryBlock, CatchBlock, Pred->getLocationContext()),
                   Pred->State, Pred);
      return;
    }
  }
  const CFGBlock *B = *(TryBlock->succ_rbegin());
  // The last choice should be upper try block or catch all or exit
  ProgramStateRef S = Pred->getState();
  if (B->isTryBlock())
    S = S->setTryBlockIdx(NextDtorIdx);
  else if (B == &Pred->getCFG().getExit())
    S = S->setUncaughtThrow(true);
  generateNode(BlockEdge(TryBlock, B, Pred->getLocationContext()), S, Pred);
}

bool CoreEngine::MatchThrownTypeAndCaughtType(QualType ThrownType,
                                              QualType CaughtType) {
  ThrownType = ThrownType.getCanonicalType();
  CaughtType = CaughtType.getCanonicalType();

  if (ThrownType.isMoreQualifiedThan(CaughtType)) {
    return false;
  }

  // FIXME: Currently 'catch (const T*)' cannot match 'throw new T()'
  CaughtType = CaughtType.getUnqualifiedType();
  ThrownType = ThrownType.getUnqualifiedType();

  // If caughtType is a reference type, get the pointee type
  if (const ReferenceType *referenceType =
          dyn_cast_or_null<ReferenceType>(CaughtType.getTypePtr())) {
    CaughtType = referenceType->getPointeeType();
  }

  if (ThrownType.getTypePtr() == CaughtType.getTypePtr()) {
    return true;
  }

  // If thrownType & caughtType are both class types
  const CXXRecordDecl *ThrownClass = ThrownType->getAsCXXRecordDecl();
  const CXXRecordDecl *CaughtClass = CaughtType->getAsCXXRecordDecl();
  if (ThrownClass && CaughtClass) {
    return ThrownClass->isDerivedFrom(CaughtClass);
  }

  // If thrownType & caughtType are both pointer types
  const PointerType *ThrownPointerType =
      dyn_cast_or_null<PointerType>(ThrownType.getTypePtr());
  const PointerType *CaughtPointerType =
      dyn_cast_or_null<PointerType>(CaughtType.getTypePtr());
  if (ThrownPointerType && CaughtPointerType) {
    // And they both point to class types
    const CXXRecordDecl *ThrownClass =
        ThrownPointerType->getPointeeType()->getAsCXXRecordDecl();
    const CXXRecordDecl *CaughtClass =
        CaughtPointerType->getPointeeType()->getAsCXXRecordDecl();
    if (ThrownClass && CaughtClass) {
      return ThrownClass->isDerivedFrom(CaughtClass);
    }
  }

  return false;
}

void CoreEngine::HandleCallEnter(const CallEnter &CE, ExplodedNode *Pred) {
  NodeBuilderContext BuilderCtx(*this, CE.getEntry(), Pred);
  ExprEng.processCallEnter(BuilderCtx, CE, Pred);
}

void CoreEngine::HandleBranch(const Stmt *Cond, const Stmt *Term,
                                const CFGBlock * B, ExplodedNode *Pred) {
  assert(B->succ_size() == 2);
  NodeBuilderContext Ctx(*this, B, Pred);
  ExplodedNodeSet Dst;
  ExprEng.processBranch(Cond, Ctx, Pred, Dst, *(B->succ_begin()),
                       *(B->succ_begin() + 1));
  // Enqueue the new frontier onto the worklist.
  enqueue(Dst);
}

void CoreEngine::HandleCleanupTemporaryBranch(const CXXBindTemporaryExpr *BTE,
                                              const CFGBlock *B,
                                              ExplodedNode *Pred) {
  assert(B->succ_size() == 2);
  NodeBuilderContext Ctx(*this, B, Pred);
  ExplodedNodeSet Dst;
  ExprEng.processCleanupTemporaryBranch(BTE, Ctx, Pred, Dst, *(B->succ_begin()),
                                       *(B->succ_begin() + 1));
  // Enqueue the new frontier onto the worklist.
  enqueue(Dst);
}

void CoreEngine::HandleStaticInit(const DeclStmt *DS, const CFGBlock *B,
                                  ExplodedNode *Pred) {
  assert(B->succ_size() == 2);
  NodeBuilderContext Ctx(*this, B, Pred);
  ExplodedNodeSet Dst;
  ExprEng.processStaticInitializer(DS, Ctx, Pred, Dst,
                                  *(B->succ_begin()), *(B->succ_begin()+1));
  // Enqueue the new frontier onto the worklist.
  enqueue(Dst);
}

void CoreEngine::HandlePostStmt(const CFGBlock *B, unsigned StmtIdx,
                                ExplodedNode *Pred) {
  assert(B);
  assert(!B->empty());

  if (auto PS = Pred->getLocation().getAs<PostStmt>()) {
    if (isa<CXXThrowExpr>(PS->getStmt())) {
      CFGStmt CS = (*B)[StmtIdx - 1].castAs<CFGStmt>();
      BlockEdge BE(Pred->getCFGBlock(), CS.getTryBlock(),
                   Pred->getLocationContext());
      generateNode(BE, Pred->getState(), Pred);
      return;
    }
  }

  if (StmtIdx == B->size())
    HandleBlockExit(B, Pred);
  else {
    NodeBuilderContext Ctx(*this, B, Pred);
    ExprEng.processCFGElement((*B)[StmtIdx], Pred, StmtIdx, &Ctx);
  }
}

void CoreEngine::HandleVirtualBaseBranch(const CFGBlock *B,
                                         ExplodedNode *Pred) {
  const LocationContext *LCtx = Pred->getLocationContext();
  if (const auto *CallerCtor = dyn_cast_or_null<CXXConstructExpr>(
          LCtx->getStackFrame()->getCallSite())) {
    switch (CallerCtor->getConstructionKind()) {
    case CXXConstructExpr::CK_NonVirtualBase:
    case CXXConstructExpr::CK_VirtualBase: {
      BlockEdge Loc(B, *B->succ_begin(), LCtx);
      HandleBlockEdge(Loc, Pred);
      return;
    }
    default:
      break;
    }
  }

  // We either don't see a parent stack frame because we're in the top frame,
  // or the parent stack frame doesn't initialize our virtual bases.
  BlockEdge Loc(B, *(B->succ_begin() + 1), LCtx);
  HandleBlockEdge(Loc, Pred);
}

/// generateNode - Utility method to generate nodes, hook up successors,
///  and add nodes to the worklist.
void CoreEngine::generateNode(const ProgramPoint &Loc,
                              ProgramStateRef State,
                              ExplodedNode *Pred) {
  bool IsNew;
  ExplodedNode *Node = G.getNode(Loc, State, false, &IsNew);

  if (Pred)
    Node->addPredecessor(Pred, G); // Link 'Node' with its predecessor.
  else {
    assert(IsNew);
    G.addRoot(Node); // 'Node' has no predecessor.  Make it a root.
  }

  // Only add 'Node' to the worklist if it was freshly generated.
  if (IsNew) WList->enqueue(Node);
}

void CoreEngine::enqueueStmtNode(ExplodedNode *N,
                                 const CFGBlock *Block, unsigned Idx) {
  assert(Block);
  assert(!N->isSink());

  // Check if this node entered a callee.
  if (N->getLocation().getAs<CallEnter>()) {
    // Still use the index of the CallExpr. It's needed to create the callee
    // StackFrameContext.
    WList->enqueue(N, Block, Idx);
    return;
  }

  // Do not create extra nodes. Move to the next CFG element.
  if (N->getLocation().getAs<PostInitializer>() ||
      N->getLocation().getAs<PostImplicitCall>()||
      N->getLocation().getAs<LoopExit>()) {
    WList->enqueue(N, Block, Idx+1);
    return;
  }

  if (N->getLocation().getAs<EpsilonPoint>()) {
    WList->enqueue(N, Block, Idx);
    return;
  }

  if ((*Block)[Idx].getKind() == CFGElement::NewAllocator) {
    WList->enqueue(N, Block, Idx+1);
    return;
  }

  // At this point, we know we're processing a normal statement.
  CFGStmt CS = (*Block)[Idx].castAs<CFGStmt>();
  PostStmt Loc(CS.getStmt(), N->getLocationContext());

  if (Loc == N->getLocation().withTag(nullptr)) {
    // Note: 'N' should be a fresh node because otherwise it shouldn't be
    // a member of Deferred.
    WList->enqueue(N, Block, Idx+1);
    return;
  }

  bool IsNew;
  ExplodedNode *Succ = G.getNode(Loc, N->getState(), false, &IsNew);
  Succ->addPredecessor(N, G);

  if (IsNew)
    WList->enqueue(Succ, Block, Idx+1);
}

ExplodedNode *CoreEngine::generateCallExitBeginNode(ExplodedNode *N,
                                                    const ReturnStmt *RS) {
  // Create a CallExitBegin node and enqueue it.
  const auto *LocCtx = cast<StackFrameContext>(N->getLocationContext());

  // Use the callee location context.
  CallExitBegin Loc(LocCtx, RS);

  bool isNew;
  ExplodedNode *Node = G.getNode(Loc, N->getState(), false, &isNew);
  Node->addPredecessor(N, G);
  return isNew ? Node : nullptr;
}

void CoreEngine::enqueue(ExplodedNodeSet &Set) {
  for (const auto I : Set)
    WList->enqueue(I);
}

void CoreEngine::enqueue(ExplodedNodeSet &Set,
                         const CFGBlock *Block, unsigned Idx) {
  for (const auto I : Set)
    enqueueStmtNode(I, Block, Idx);
}

void CoreEngine::enqueueEndOfFunction(ExplodedNodeSet &Set, const ReturnStmt *RS) {
  for (auto I : Set) {
    // If we are in an inlined call, generate CallExitBegin node.
    if (I->getLocationContext()->getParent()) {
      I = generateCallExitBeginNode(I, RS);
      if (I)
        WList->enqueue(I);
    } else {
      // TODO: We should run remove dead bindings here.
      G.addEndOfPath(I);
      if (I->getState()->getThrowExpr())
        NumExceptionPathsExplored++;
      NumPathsExplored++;
    }
  }
}

void NodeBuilder::anchor() {}

ExplodedNode* NodeBuilder::generateNodeImpl(const ProgramPoint &Loc,
                                            ProgramStateRef State,
                                            ExplodedNode *FromN,
                                            bool MarkAsSink) {
  HasGeneratedNodes = true;
  bool IsNew;
  ExplodedNode *N = C.Eng.G.getNode(Loc, State, MarkAsSink, &IsNew);
  N->addPredecessor(FromN, C.Eng.G);
  Frontier.erase(FromN);

  if (!IsNew)
    return nullptr;

  if (!MarkAsSink)
    Frontier.Add(N);

  return N;
}

void NodeBuilderWithSinks::anchor() {}

StmtNodeBuilder::~StmtNodeBuilder() {
  if (EnclosingBldr)
    for (const auto I : Frontier)
      EnclosingBldr->addNodes(I);
}

void BranchNodeBuilder::anchor() {}

ExplodedNode *BranchNodeBuilder::generateNode(ProgramStateRef State,
                                              bool branch,
                                              ExplodedNode *NodePred) {
  // If the branch has been marked infeasible we should not generate a node.
  if (!isFeasible(branch))
    return nullptr;

  ProgramPoint Loc = BlockEdge(C.Block, branch ? DstT:DstF,
                               NodePred->getLocationContext());
  ExplodedNode *Succ = generateNodeImpl(Loc, State, NodePred);
  return Succ;
}

ExplodedNode*
IndirectGotoNodeBuilder::generateNode(const iterator &I,
                                      ProgramStateRef St,
                                      bool IsSink) {
  bool IsNew;
  ExplodedNode *Succ =
      Eng.G.getNode(BlockEdge(Src, I.getBlock(), Pred->getLocationContext()),
                    St, IsSink, &IsNew);
  Succ->addPredecessor(Pred, Eng.G);

  if (!IsNew)
    return nullptr;

  if (!IsSink)
    Eng.WList->enqueue(Succ);

  return Succ;
}

ExplodedNode*
SwitchNodeBuilder::generateCaseStmtNode(const iterator &I,
                                        ProgramStateRef St) {
  bool IsNew;
  ExplodedNode *Succ =
      Eng.G.getNode(BlockEdge(Src, I.getBlock(), Pred->getLocationContext()),
                    St, false, &IsNew);
  Succ->addPredecessor(Pred, Eng.G);
  if (!IsNew)
    return nullptr;

  Eng.WList->enqueue(Succ);
  return Succ;
}

ExplodedNode*
SwitchNodeBuilder::generateDefaultCaseNode(ProgramStateRef St,
                                           bool IsSink) {
  // Get the block for the default case.
  assert(Src->succ_rbegin() != Src->succ_rend());
  CFGBlock *DefaultBlock = *Src->succ_rbegin();

  // Sanity check for default blocks that are unreachable and not caught
  // by earlier stages.
  if (!DefaultBlock)
    return nullptr;

  bool IsNew;
  ExplodedNode *Succ =
      Eng.G.getNode(BlockEdge(Src, DefaultBlock, Pred->getLocationContext()),
                    St, IsSink, &IsNew);
  Succ->addPredecessor(Pred, Eng.G);

  if (!IsNew)
    return nullptr;

  if (!IsSink)
    Eng.WList->enqueue(Succ);

  return Succ;
}
