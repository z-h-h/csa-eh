; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instcombine -S 2>&1 | FileCheck %s
target datalayout = "e-m:e-p:32:32-i64:64-v128:64:128-a:0:32-n32-S64"

; We are really checking that this doesn't loop forever. We would never
; actually get to the checks here if it did.

define void @timeout(i16* nocapture readonly %cinfo) {
; CHECK-LABEL: @timeout(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[FOR_BODY:%.*]]
; CHECK:       for.body:
; CHECK-NEXT:    [[ARRAYIDX15:%.*]] = getelementptr inbounds i16, i16* [[CINFO:%.*]], i32 2
; CHECK-NEXT:    [[L:%.*]] = load i16, i16* [[ARRAYIDX15]], align 2
; CHECK-NEXT:    [[CMP17:%.*]] = icmp eq i16 [[L]], 0
; CHECK-NEXT:    [[EXTRACT_T1:%.*]] = trunc i16 [[L]] to i8
; CHECK-NEXT:    br i1 [[CMP17]], label [[IF_THEN:%.*]], label [[IF_END:%.*]]
; CHECK:       if.then:
; CHECK-NEXT:    [[DOTPRE:%.*]] = load i16, i16* [[ARRAYIDX15]], align 2
; CHECK-NEXT:    [[EXTRACT_T:%.*]] = trunc i16 [[DOTPRE]] to i8
; CHECK-NEXT:    br label [[IF_END]]
; CHECK:       if.end:
; CHECK-NEXT:    [[P_OFF0:%.*]] = phi i8 [ [[EXTRACT_T]], [[IF_THEN]] ], [ [[EXTRACT_T1]], [[FOR_BODY]] ]
; CHECK-NEXT:    [[SUB:%.*]] = add i8 [[P_OFF0]], -1
; CHECK-NEXT:    store i8 [[SUB]], i8* undef, align 1
; CHECK-NEXT:    br label [[FOR_BODY]]
;
entry:
  br label %for.body

for.body:
  %arrayidx15 = getelementptr inbounds i16, i16* %cinfo, i32 2
  %l = load i16, i16* %arrayidx15, align 2
  %cmp17 = icmp eq i16 %l, 0
  br i1 %cmp17, label %if.then, label %if.end

if.then:
  %.pre = load i16, i16* %arrayidx15, align 2
  br label %if.end

if.end:
  %p = phi i16 [ %.pre, %if.then ], [ %l, %for.body ]
  %conv19 = trunc i16 %p to i8
  %sub = add i8 %conv19, -1
  store i8 %sub, i8* undef, align 1
  br label %for.body
}
