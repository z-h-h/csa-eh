; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -constraint-elimination -S %s | FileCheck %s

declare void @llvm.assume(i1)

define i1 @n_unknown(i32* %dst, i32 %n, i32 %i) {
; CHECK-LABEL: @n_unknown(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SUB:%.*]] = add i32 [[N:%.*]], -1
; CHECK-NEXT:    [[IDXPROM:%.*]] = zext i32 [[SUB]] to i64
; CHECK-NEXT:    [[PTR_N_SUB_1:%.*]] = getelementptr i32, i32* [[DST:%.*]], i64 [[IDXPROM]]
; CHECK-NEXT:    [[CMP_PTR_DST:%.*]] = icmp uge i32* [[PTR_N_SUB_1]], [[DST]]
; CHECK-NEXT:    br i1 [[CMP_PTR_DST]], label [[PRE_BB_2:%.*]], label [[EXIT:%.*]]
; CHECK:       exit:
; CHECK-NEXT:    ret i1 false
; CHECK:       pre.bb.2:
; CHECK-NEXT:    [[PRE_2:%.*]] = icmp uge i32 [[I:%.*]], 0
; CHECK-NEXT:    br i1 [[PRE_2]], label [[TGT_BB:%.*]], label [[EXIT]]
; CHECK:       tgt.bb:
; CHECK-NEXT:    [[CMP1:%.*]] = icmp ult i32 [[I]], [[N]]
; CHECK-NEXT:    ret i1 [[CMP1]]
;
entry:
  %sub = add i32 %n, -1
  %idxprom = zext i32 %sub to i64
  %ptr.n.sub.1 = getelementptr i32, i32* %dst, i64 %idxprom
  %cmp.ptr.dst = icmp uge i32* %ptr.n.sub.1, %dst
  br i1 %cmp.ptr.dst, label %pre.bb.2, label %exit

exit:
  ret i1 false

pre.bb.2:
  %pre.2 = icmp uge i32 %i, 0
  br i1 %pre.2, label %tgt.bb, label %exit

tgt.bb:
  %cmp1 = icmp ult i32 %i, %n
  ret i1 %cmp1
}

define i1 @n_known_zero_due_to_nuw(i32* %dst, i32 %n, i32 %i) {
; CHECK-LABEL: @n_known_zero_due_to_nuw(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SUB:%.*]] = add i32 [[N:%.*]], -1
; CHECK-NEXT:    [[IDXPROM:%.*]] = zext i32 [[SUB]] to i64
; CHECK-NEXT:    [[PTR_N_SUB_1:%.*]] = getelementptr i32, i32* [[DST:%.*]], i64 [[IDXPROM]]
; CHECK-NEXT:    [[CMP_PTR_DST:%.*]] = icmp uge i32* [[PTR_N_SUB_1]], [[DST]]
; CHECK-NEXT:    br i1 [[CMP_PTR_DST]], label [[PRE_BB_2:%.*]], label [[EXIT:%.*]]
; CHECK:       exit:
; CHECK-NEXT:    ret i1 false
; CHECK:       pre.bb.2:
; CHECK-NEXT:    [[PRE_2:%.*]] = icmp uge i32 [[I:%.*]], 0
; CHECK-NEXT:    br i1 [[PRE_2]], label [[TGT_BB:%.*]], label [[EXIT]]
; CHECK:       tgt.bb:
; CHECK-NEXT:    [[CMP1:%.*]] = icmp ult i32 [[I]], [[N]]
; CHECK-NEXT:    ret i1 [[CMP1]]
;
entry:
  %sub = add i32 %n, -1
  %idxprom = zext i32 %sub to i64
  %ptr.n.sub.1 = getelementptr i32, i32* %dst, i64 %idxprom
  %cmp.ptr.dst = icmp uge i32* %ptr.n.sub.1, %dst
  br i1 %cmp.ptr.dst, label %pre.bb.2, label %exit

exit:
  ret i1 false

pre.bb.2:
  %pre.2 = icmp uge i32 %i, 0
  br i1 %pre.2, label %tgt.bb, label %exit

tgt.bb:
  %cmp1 = icmp ult i32 %i, %n
  ret i1 %cmp1
}

define i4 @ptr_N_signed_positive_explicit_check_constant_step(i8* %src, i8* %lower, i8* %upper, i16 %N) {
; CHECK-LABEL: @ptr_N_signed_positive_explicit_check_constant_step(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[N_POS:%.*]] = icmp sge i16 [[N:%.*]], 0
; CHECK-NEXT:    br i1 [[N_POS]], label [[ENTRY_1:%.*]], label [[TRAP_BB:%.*]]
; CHECK:       entry.1:
; CHECK-NEXT:    [[SRC_END:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i16 [[N]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC]], [[LOWER:%.*]]
; CHECK-NEXT:    [[CMP_SRC_END:%.*]] = icmp uge i8* [[SRC_END]], [[UPPER:%.*]]
; CHECK-NEXT:    [[OR_PRECOND_0:%.*]] = or i1 [[CMP_SRC_START]], [[CMP_SRC_END]]
; CHECK-NEXT:    br i1 [[OR_PRECOND_0]], label [[TRAP_BB]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[STEP_ULT_N:%.*]] = icmp ult i16 1, [[N]]
; CHECK-NEXT:    br i1 [[STEP_ULT_N]], label [[PTR_CHECK:%.*]], label [[EXIT:%.*]]
; CHECK:       ptr.check:
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i16 1
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 false, false
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;

entry:
  %N.pos = icmp sge i16 %N, 0
  br i1 %N.pos, label %entry.1, label %trap.bb

entry.1:
  %src.end = getelementptr inbounds i8, i8* %src, i16 %N
  %cmp.src.start = icmp ult i8* %src, %lower
  %cmp.src.end = icmp uge i8* %src.end, %upper
  %or.precond.0 = or i1 %cmp.src.start, %cmp.src.end
  br i1 %or.precond.0, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %step.ult.N = icmp ult i16 1, %N
  br i1 %step.ult.N, label %ptr.check, label %exit

ptr.check:
  %src.step = getelementptr inbounds i8, i8* %src, i16 1
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}

; Same as ptr_N_signed_positive_explicit_check_constant_step, but without inbounds.
define i4 @ptr_N_signed_positive_explicit_check_constant_step_no_inbonds(i8* %src, i8* %lower, i8* %upper, i16 %N) {
; CHECK-LABEL: @ptr_N_signed_positive_explicit_check_constant_step_no_inbonds(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[N_POS:%.*]] = icmp sge i16 [[N:%.*]], 0
; CHECK-NEXT:    br i1 [[N_POS]], label [[ENTRY_1:%.*]], label [[TRAP_BB:%.*]]
; CHECK:       entry.1:
; CHECK-NEXT:    [[SRC_END:%.*]] = getelementptr i8, i8* [[SRC:%.*]], i16 [[N]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC]], [[LOWER:%.*]]
; CHECK-NEXT:    [[CMP_SRC_END:%.*]] = icmp uge i8* [[SRC_END]], [[UPPER:%.*]]
; CHECK-NEXT:    [[OR_PRECOND_0:%.*]] = or i1 [[CMP_SRC_START]], [[CMP_SRC_END]]
; CHECK-NEXT:    br i1 [[OR_PRECOND_0]], label [[TRAP_BB]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[STEP_ULT_N:%.*]] = icmp ult i16 1, [[N]]
; CHECK-NEXT:    br i1 [[STEP_ULT_N]], label [[PTR_CHECK:%.*]], label [[EXIT:%.*]]
; CHECK:       ptr.check:
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr i8, i8* [[SRC]], i16 1
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 [[CMP_STEP_START]], [[CMP_STEP_END]]
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;

entry:
  %N.pos = icmp sge i16 %N, 0
  br i1 %N.pos, label %entry.1, label %trap.bb

entry.1:
  %src.end = getelementptr i8, i8* %src, i16 %N
  %cmp.src.start = icmp ult i8* %src, %lower
  %cmp.src.end = icmp uge i8* %src.end, %upper
  %or.precond.0 = or i1 %cmp.src.start, %cmp.src.end
  br i1 %or.precond.0, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %step.ult.N = icmp ult i16 1, %N
  br i1 %step.ult.N, label %ptr.check, label %exit

ptr.check:
  %src.step = getelementptr i8, i8* %src, i16 1
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}

define i4 @ptr_N_and_step_signed_positive_explicit_check_constant_step(i8* %src, i8* %lower, i8* %upper, i16 %N, i16 %step) {
; CHECK-LABEL: @ptr_N_and_step_signed_positive_explicit_check_constant_step(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[N_POS:%.*]] = icmp sge i16 [[N:%.*]], 0
; CHECK-NEXT:    [[STEP_POS:%.*]] = icmp sge i16 [[STEP:%.*]], 0
; CHECK-NEXT:    [[AND_1:%.*]] = and i1 [[N_POS]], [[STEP_POS]]
; CHECK-NEXT:    br i1 [[AND_1]], label [[ENTRY_1:%.*]], label [[TRAP_BB:%.*]]
; CHECK:       entry.1:
; CHECK-NEXT:    [[SRC_END:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i16 [[N]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC]], [[LOWER:%.*]]
; CHECK-NEXT:    [[CMP_SRC_END:%.*]] = icmp uge i8* [[SRC_END]], [[UPPER:%.*]]
; CHECK-NEXT:    [[OR_PRECOND_0:%.*]] = or i1 [[CMP_SRC_START]], [[CMP_SRC_END]]
; CHECK-NEXT:    br i1 [[OR_PRECOND_0]], label [[TRAP_BB]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[STEP_UGE_0:%.*]] = icmp uge i16 [[STEP]], 0
; CHECK-NEXT:    [[STEP_ULT_N:%.*]] = icmp ult i16 [[STEP]], [[N]]
; CHECK-NEXT:    [[AND_2:%.*]] = and i1 [[STEP_UGE_0]], [[STEP_ULT_N]]
; CHECK-NEXT:    br i1 [[AND_2]], label [[PTR_CHECK:%.*]], label [[EXIT:%.*]]
; CHECK:       ptr.check:
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i16 1
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 false, false
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;

entry:
  %N.pos = icmp sge i16 %N, 0
  %step.pos = icmp sge i16 %step, 0
  %and.1 = and i1 %N.pos, %step.pos
  br i1 %and.1, label %entry.1, label %trap.bb

entry.1:
  %src.end = getelementptr inbounds i8, i8* %src, i16 %N
  %cmp.src.start = icmp ult i8* %src, %lower
  %cmp.src.end = icmp uge i8* %src.end, %upper
  %or.precond.0 = or i1 %cmp.src.start, %cmp.src.end
  br i1 %or.precond.0, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %step.uge.0 = icmp uge i16 %step, 0
  %step.ult.N = icmp ult i16 %step, %N
  %and.2 = and i1 %step.uge.0, %step.ult.N
  br i1 %and.2, label %ptr.check, label %exit

ptr.check:
  %src.step = getelementptr inbounds i8, i8* %src, i16 1
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}

define i4 @ptr_N_and_step_signed_positive_unsigned_checks_only(i8* %src, i8* %lower, i8* %upper, i16 %N, i16 %step) {
; CHECK-LABEL: @ptr_N_and_step_signed_positive_unsigned_checks_only(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SRC_END:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i16 [[N:%.*]]
; CHECK-NEXT:    [[NO_OVERFLOW:%.*]] = icmp ule i8* [[SRC]], [[SRC_END]]
; CHECK-NEXT:    br i1 [[NO_OVERFLOW]], label [[ENTRY_1:%.*]], label [[TRAP_BB:%.*]]
; CHECK:       entry.1:
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC]], [[LOWER:%.*]]
; CHECK-NEXT:    [[CMP_SRC_END:%.*]] = icmp uge i8* [[SRC_END]], [[UPPER:%.*]]
; CHECK-NEXT:    [[OR_PRECOND_0:%.*]] = or i1 [[CMP_SRC_START]], [[CMP_SRC_END]]
; CHECK-NEXT:    br i1 [[OR_PRECOND_0]], label [[TRAP_BB]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[STEP_UGE_0:%.*]] = icmp uge i16 [[STEP:%.*]], 0
; CHECK-NEXT:    [[STEP_ULT_N:%.*]] = icmp ult i16 [[STEP]], [[N]]
; CHECK-NEXT:    [[AND_2:%.*]] = and i1 [[STEP_UGE_0]], [[STEP_ULT_N]]
; CHECK-NEXT:    br i1 [[AND_2]], label [[PTR_CHECK:%.*]], label [[EXIT:%.*]]
; CHECK:       ptr.check:
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i16 1
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 false, false
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;
entry:
  %src.end = getelementptr inbounds i8, i8* %src, i16 %N
  %no.overflow = icmp ule i8* %src, %src.end
  br i1 %no.overflow, label %entry.1, label %trap.bb

entry.1:
  %cmp.src.start = icmp ult i8* %src, %lower
  %cmp.src.end = icmp uge i8* %src.end, %upper
  %or.precond.0 = or i1 %cmp.src.start, %cmp.src.end
  br i1 %or.precond.0, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %step.uge.0 = icmp uge i16 %step, 0
  %step.ult.N = icmp ult i16 %step, %N
  %and.2 = and i1 %step.uge.0, %step.ult.N
  br i1 %and.2, label %ptr.check, label %exit

ptr.check:
  %src.step = getelementptr inbounds i8, i8* %src, i16 1
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}

define i4 @ptr_N_signed_positive(i8* %src, i8* %lower, i8* %upper, i16 %N, i16 %step) {
; CHECK-LABEL: @ptr_N_signed_positive(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SRC_END:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i16 [[N:%.*]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC]], [[LOWER:%.*]]
; CHECK-NEXT:    [[CMP_SRC_END:%.*]] = icmp uge i8* [[SRC_END]], [[UPPER:%.*]]
; CHECK-NEXT:    [[N_NEG:%.*]] = icmp slt i16 [[N]], 0
; CHECK-NEXT:    [[OR_PRECOND_0:%.*]] = or i1 [[CMP_SRC_START]], [[CMP_SRC_END]]
; CHECK-NEXT:    [[OR_PRECOND_1:%.*]] = or i1 [[OR_PRECOND_0]], [[N_NEG]]
; CHECK-NEXT:    br i1 [[OR_PRECOND_1]], label [[TRAP_BB:%.*]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[STEP_POS:%.*]] = icmp uge i16 [[STEP:%.*]], 0
; CHECK-NEXT:    [[STEP_ULT_N:%.*]] = icmp ult i16 [[STEP]], [[N]]
; CHECK-NEXT:    [[AND_STEP:%.*]] = and i1 [[STEP_POS]], [[STEP_ULT_N]]
; CHECK-NEXT:    br i1 [[AND_STEP]], label [[PTR_CHECK:%.*]], label [[EXIT:%.*]]
; CHECK:       ptr.check:
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i16 [[STEP]]
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 [[CMP_STEP_START]], [[CMP_STEP_END]]
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;
entry:
  %src.end = getelementptr inbounds i8, i8* %src, i16 %N
  %cmp.src.start = icmp ult i8* %src, %lower
  %cmp.src.end = icmp uge i8* %src.end, %upper
  %N.neg = icmp slt i16 %N, 0
  %or.precond.0 = or i1 %cmp.src.start, %cmp.src.end
  %or.precond.1 = or i1 %or.precond.0, %N.neg
  br i1 %or.precond.1, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %step.pos = icmp uge i16 %step, 0
  %step.ult.N = icmp ult i16 %step, %N
  %and.step = and i1 %step.pos, %step.ult.N
  br i1 %and.step, label %ptr.check, label %exit

ptr.check:
  %src.step = getelementptr inbounds i8, i8* %src, i16 %step
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}

define i4 @ptr_N_could_be_negative(i8* %src, i8* %lower, i8* %upper, i16 %N, i16 %step) {
; CHECK-LABEL: @ptr_N_could_be_negative(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SRC_END:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i16 [[N:%.*]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC]], [[LOWER:%.*]]
; CHECK-NEXT:    [[CMP_SRC_END:%.*]] = icmp uge i8* [[SRC_END]], [[UPPER:%.*]]
; CHECK-NEXT:    [[OR_PRECOND_0:%.*]] = or i1 [[CMP_SRC_START]], [[CMP_SRC_END]]
; CHECK-NEXT:    br i1 [[OR_PRECOND_0]], label [[TRAP_BB:%.*]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[STEP_POS:%.*]] = icmp uge i16 [[STEP:%.*]], 0
; CHECK-NEXT:    [[STEP_ULT_N:%.*]] = icmp ult i16 [[STEP]], [[N]]
; CHECK-NEXT:    [[AND_STEP:%.*]] = and i1 [[STEP_POS]], [[STEP_ULT_N]]
; CHECK-NEXT:    br i1 [[AND_STEP]], label [[PTR_CHECK:%.*]], label [[EXIT:%.*]]
; CHECK:       ptr.check:
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i16 [[STEP]]
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 false, false
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;
entry:
  %src.end = getelementptr inbounds i8, i8* %src, i16 %N
  %cmp.src.start = icmp ult i8* %src, %lower
  %cmp.src.end = icmp uge i8* %src.end, %upper
  %or.precond.0 = or i1 %cmp.src.start, %cmp.src.end
  br i1 %or.precond.0, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %step.pos = icmp uge i16 %step, 0
  %step.ult.N = icmp ult i16 %step, %N
  %and.step = and i1 %step.pos, %step.ult.N
  br i1 %and.step, label %ptr.check, label %exit

ptr.check:
  %src.step = getelementptr inbounds i8, i8* %src, i16 %step
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}

define i4 @ptr_src_uge_end(i8* %src, i8* %lower, i8* %upper, i16 %N, i16 %step) {
; CHECK-LABEL: @ptr_src_uge_end(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SRC_END:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i16 [[N:%.*]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC]], [[LOWER:%.*]]
; CHECK-NEXT:    [[CMP_SRC_END:%.*]] = icmp uge i8* [[SRC_END]], [[UPPER:%.*]]
; CHECK-NEXT:    [[CMP_OVERFLOW:%.*]] = icmp ugt i8* [[SRC]], [[SRC_END]]
; CHECK-NEXT:    [[OR_PRECOND_0:%.*]] = or i1 [[CMP_SRC_START]], [[CMP_SRC_END]]
; CHECK-NEXT:    [[OR_PRECOND_1:%.*]] = or i1 [[OR_PRECOND_0]], [[CMP_OVERFLOW]]
; CHECK-NEXT:    br i1 [[OR_PRECOND_1]], label [[TRAP_BB:%.*]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[STEP_POS:%.*]] = icmp uge i16 [[STEP:%.*]], 0
; CHECK-NEXT:    [[STEP_ULT_N:%.*]] = icmp ult i16 [[STEP]], [[N]]
; CHECK-NEXT:    [[AND_STEP:%.*]] = and i1 [[STEP_POS]], [[STEP_ULT_N]]
; CHECK-NEXT:    br i1 [[AND_STEP]], label [[PTR_CHECK:%.*]], label [[EXIT:%.*]]
; CHECK:       ptr.check:
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i16 [[STEP]]
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 [[CMP_STEP_START]], [[CMP_STEP_END]]
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;
entry:
  %src.end = getelementptr inbounds i8, i8* %src, i16 %N
  %cmp.src.start = icmp ult i8* %src, %lower
  %cmp.src.end = icmp uge i8* %src.end, %upper
  %cmp.overflow = icmp ugt i8* %src, %src.end
  %or.precond.0 = or i1 %cmp.src.start, %cmp.src.end
  %or.precond.1 = or i1 %or.precond.0, %cmp.overflow
  br i1 %or.precond.1, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %step.pos = icmp uge i16 %step, 0
  %step.ult.N = icmp ult i16 %step, %N
  %and.step = and i1 %step.pos, %step.ult.N
  br i1 %and.step, label %ptr.check, label %exit

ptr.check:
  %src.step = getelementptr inbounds i8, i8* %src, i16 %step
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}

define i4 @inc_ptr_N_could_be_negative(i8* %src, i8* %lower, i8* %upper, i16 %N, i16 %step) {
; CHECK-LABEL: @inc_ptr_N_could_be_negative(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SRC_END:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i16 [[N:%.*]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC]], [[LOWER:%.*]]
; CHECK-NEXT:    [[CMP_SRC_END:%.*]] = icmp uge i8* [[SRC_END]], [[UPPER:%.*]]
; CHECK-NEXT:    [[OR_PRECOND_0:%.*]] = or i1 [[CMP_SRC_START]], [[CMP_SRC_END]]
; CHECK-NEXT:    br i1 [[OR_PRECOND_0]], label [[TRAP_BB:%.*]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[STEP_POS:%.*]] = icmp uge i16 [[STEP:%.*]], 0
; CHECK-NEXT:    [[NEXT:%.*]] = add nuw nsw i16 [[STEP]], 2
; CHECK-NEXT:    [[STEP_ULT_N:%.*]] = icmp ult i16 [[NEXT]], [[N]]
; CHECK-NEXT:    [[AND_STEP:%.*]] = and i1 [[STEP_POS]], [[STEP_ULT_N]]
; CHECK-NEXT:    br i1 [[AND_STEP]], label [[PTR_CHECK:%.*]], label [[EXIT:%.*]]
; CHECK:       ptr.check:
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i16 [[STEP]]
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 false, false
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;
entry:
  %src.end = getelementptr inbounds i8, i8* %src, i16 %N
  %cmp.src.start = icmp ult i8* %src, %lower
  %cmp.src.end = icmp uge i8* %src.end, %upper
  %or.precond.0 = or i1 %cmp.src.start, %cmp.src.end
  br i1 %or.precond.0, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %step.pos = icmp uge i16 %step, 0
  %next = add nsw nuw i16 %step, 2
  %step.ult.N = icmp ult i16 %next, %N
  %and.step = and i1 %step.pos, %step.ult.N
  br i1 %and.step, label %ptr.check, label %exit

ptr.check:
  %src.step = getelementptr inbounds i8, i8* %src, i16 %step
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}

define i4 @inc_ptr_src_uge_end(i8* %src, i8* %lower, i8* %upper, i16 %N, i16 %step) {
; CHECK-LABEL: @inc_ptr_src_uge_end(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SRC_END:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i16 [[N:%.*]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC]], [[LOWER:%.*]]
; CHECK-NEXT:    [[CMP_SRC_END:%.*]] = icmp uge i8* [[SRC_END]], [[UPPER:%.*]]
; CHECK-NEXT:    [[CMP_OVERFLOW:%.*]] = icmp ugt i8* [[SRC]], [[SRC_END]]
; CHECK-NEXT:    [[OR_PRECOND_0:%.*]] = or i1 [[CMP_SRC_START]], [[CMP_SRC_END]]
; CHECK-NEXT:    [[OR_PRECOND_1:%.*]] = or i1 [[OR_PRECOND_0]], [[CMP_OVERFLOW]]
; CHECK-NEXT:    br i1 [[OR_PRECOND_1]], label [[TRAP_BB:%.*]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[STEP_POS:%.*]] = icmp uge i16 [[STEP:%.*]], 0
; CHECK-NEXT:    [[NEXT:%.*]] = add nuw nsw i16 [[STEP]], 2
; CHECK-NEXT:    [[STEP_ULT_N:%.*]] = icmp ult i16 [[NEXT]], [[N]]
; CHECK-NEXT:    [[AND_STEP:%.*]] = and i1 [[STEP_POS]], [[STEP_ULT_N]]
; CHECK-NEXT:    br i1 [[AND_STEP]], label [[PTR_CHECK:%.*]], label [[EXIT:%.*]]
; CHECK:       ptr.check:
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i16 [[STEP]]
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 [[CMP_STEP_START]], [[CMP_STEP_END]]
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;
entry:
  %src.end = getelementptr inbounds i8, i8* %src, i16 %N
  %cmp.src.start = icmp ult i8* %src, %lower
  %cmp.src.end = icmp uge i8* %src.end, %upper
  %cmp.overflow = icmp ugt i8* %src, %src.end
  %or.precond.0 = or i1 %cmp.src.start, %cmp.src.end
  %or.precond.1 = or i1 %or.precond.0, %cmp.overflow
  br i1 %or.precond.1, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %step.pos = icmp uge i16 %step, 0
  %next = add nsw nuw i16 %step, 2
  %step.ult.N = icmp ult i16 %next, %N
  %and.step = and i1 %step.pos, %step.ult.N
  br i1 %and.step, label %ptr.check, label %exit

ptr.check:
  %src.step = getelementptr inbounds i8, i8* %src, i16 %step
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}

define i4 @inc_ptr_src_uge_end_no_nsw_add(i8* %src, i8* %lower, i8* %upper, i16 %idx, i16 %N, i16 %step) {
; CHECK-LABEL: @inc_ptr_src_uge_end_no_nsw_add(
; CHECK-NEXT:  entry.1:
; CHECK-NEXT:    [[IDX_POS:%.*]] = icmp sge i16 [[IDX:%.*]], 0
; CHECK-NEXT:    br i1 [[IDX_POS]], label [[ENTRY:%.*]], label [[TRAP_BB:%.*]]
; CHECK:       entry:
; CHECK-NEXT:    [[SRC_IDX:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i16 [[IDX]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC_IDX]], [[LOWER:%.*]]
; CHECK-NEXT:    br i1 [[CMP_SRC_START]], label [[TRAP_BB]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[NEXT:%.*]] = add i16 [[IDX]], 2
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i16 [[NEXT]]
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER:%.*]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 [[CMP_STEP_START]], [[CMP_STEP_END]]
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT:%.*]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;
entry.1:
  %idx.pos = icmp sge i16 %idx, 0
  br i1 %idx.pos, label %entry, label %trap.bb

entry:
  %src.idx = getelementptr inbounds i8, i8* %src, i16 %idx
  %cmp.src.start = icmp ult i8* %src.idx, %lower
  br i1 %cmp.src.start, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %next = add i16 %idx, 2
  %src.step = getelementptr inbounds i8, i8* %src, i16 %next
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}

define i4 @inc_ptr_src_uge_end_no_nsw_add_sge_0(i8* %src, i8* %lower, i8* %upper, i16 %idx, i16 %N, i16 %step) {
; CHECK-LABEL: @inc_ptr_src_uge_end_no_nsw_add_sge_0(
; CHECK-NEXT:  entry.1:
; CHECK-NEXT:    [[IDX_POS:%.*]] = icmp sge i16 [[IDX:%.*]], 0
; CHECK-NEXT:    br i1 [[IDX_POS]], label [[ENTRY:%.*]], label [[TRAP_BB:%.*]]
; CHECK:       entry:
; CHECK-NEXT:    [[SRC_IDX:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i16 [[IDX]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC_IDX]], [[LOWER:%.*]]
; CHECK-NEXT:    br i1 [[CMP_SRC_START]], label [[TRAP_BB]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[NEXT:%.*]] = add i16 [[IDX]], 2
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i16 [[NEXT]]
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER:%.*]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 [[CMP_STEP_START]], [[CMP_STEP_END]]
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT:%.*]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;
entry.1:
  %idx.pos = icmp sge i16 %idx, 0
  br i1 %idx.pos, label %entry, label %trap.bb

entry:
  %src.idx = getelementptr inbounds i8, i8* %src, i16 %idx
  %cmp.src.start = icmp ult i8* %src.idx, %lower
  br i1 %cmp.src.start, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %next = add i16 %idx, 2
  %src.step = getelementptr inbounds i8, i8* %src, i16 %next
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}




; N might be negative, meaning %src.end could be < %src! Cannot remove checks!
define i4 @ptr_N_unsigned_positive(i8* %src, i8* %lower, i8* %upper, i16 %N, i16 %step) {
; CHECK-LABEL: @ptr_N_unsigned_positive(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SRC_END:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i16 [[N:%.*]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC]], [[LOWER:%.*]]
; CHECK-NEXT:    [[CMP_SRC_END:%.*]] = icmp uge i8* [[SRC_END]], [[UPPER:%.*]]
; CHECK-NEXT:    [[N_NEG:%.*]] = icmp ult i16 [[N]], 0
; CHECK-NEXT:    [[OR_PRECOND_0:%.*]] = or i1 [[CMP_SRC_START]], [[CMP_SRC_END]]
; CHECK-NEXT:    [[OR_PRECOND_1:%.*]] = or i1 [[OR_PRECOND_0]], [[N_NEG]]
; CHECK-NEXT:    br i1 [[OR_PRECOND_1]], label [[TRAP_BB:%.*]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[STEP_POS:%.*]] = icmp uge i16 [[STEP:%.*]], 0
; CHECK-NEXT:    [[STEP_ULT_N:%.*]] = icmp ult i16 [[STEP]], [[N]]
; CHECK-NEXT:    [[AND_STEP:%.*]] = and i1 [[STEP_POS]], [[STEP_ULT_N]]
; CHECK-NEXT:    br i1 [[AND_STEP]], label [[PTR_CHECK:%.*]], label [[EXIT:%.*]]
; CHECK:       ptr.check:
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i16 [[STEP]]
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 [[CMP_STEP_START]], [[CMP_STEP_END]]
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;
entry:
  %src.end = getelementptr inbounds i8, i8* %src, i16 %N
  %cmp.src.start = icmp ult i8* %src, %lower
  %cmp.src.end = icmp uge i8* %src.end, %upper
  %N.neg = icmp ult i16 %N, 0
  %or.precond.0 = or i1 %cmp.src.start, %cmp.src.end
  %or.precond.1 = or i1 %or.precond.0, %N.neg
  br i1 %or.precond.1, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %step.pos = icmp uge i16 %step, 0
  %step.ult.N = icmp ult i16 %step, %N
  %and.step = and i1 %step.pos, %step.ult.N
  br i1 %and.step, label %ptr.check, label %exit

ptr.check:
  %src.step = getelementptr inbounds i8, i8* %src, i16 %step
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}

define i4 @ptr_N_signed_positive_assume(i8* %src, i8* %lower, i8* %upper, i16 %N, i16 %step) {
; CHECK-LABEL: @ptr_N_signed_positive_assume(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SRC_END:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i16 [[N:%.*]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC]], [[LOWER:%.*]]
; CHECK-NEXT:    [[CMP_SRC_END:%.*]] = icmp uge i8* [[SRC_END]], [[UPPER:%.*]]
; CHECK-NEXT:    [[N_NEG:%.*]] = icmp slt i16 [[N]], 0
; CHECK-NEXT:    call void @llvm.assume(i1 [[N_NEG]])
; CHECK-NEXT:    [[OR_PRECOND_0:%.*]] = or i1 [[CMP_SRC_START]], [[CMP_SRC_END]]
; CHECK-NEXT:    br i1 [[OR_PRECOND_0]], label [[TRAP_BB:%.*]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[STEP_POS:%.*]] = icmp uge i16 [[STEP:%.*]], 0
; CHECK-NEXT:    [[STEP_ULT_N:%.*]] = icmp ult i16 [[STEP]], [[N]]
; CHECK-NEXT:    [[AND_STEP:%.*]] = and i1 [[STEP_POS]], [[STEP_ULT_N]]
; CHECK-NEXT:    br i1 [[AND_STEP]], label [[PTR_CHECK:%.*]], label [[EXIT:%.*]]
; CHECK:       ptr.check:
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i16 [[STEP]]
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 false, false
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;
entry:
  %src.end = getelementptr inbounds i8, i8* %src, i16 %N
  %cmp.src.start = icmp ult i8* %src, %lower
  %cmp.src.end = icmp uge i8* %src.end, %upper
  %N.neg = icmp slt i16 %N, 0
  call void @llvm.assume(i1 %N.neg)
  %or.precond.0 = or i1 %cmp.src.start, %cmp.src.end
  br i1 %or.precond.0, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %step.pos = icmp uge i16 %step, 0
  %step.ult.N = icmp ult i16 %step, %N
  %and.step = and i1 %step.pos, %step.ult.N
  br i1 %and.step, label %ptr.check, label %exit

ptr.check:
  %src.step = getelementptr inbounds i8, i8* %src, i16 %step
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}

define i4 @ptr_N_step_zext_n_zext(i8* %src, i8* %lower, i8* %upper, i16 %N, i16 %step) {
; CHECK-LABEL: @ptr_N_step_zext_n_zext(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[N_ADD_1:%.*]] = add nuw nsw i16 [[N:%.*]], 1
; CHECK-NEXT:    [[N_ADD_1_EXT:%.*]] = zext i16 [[N_ADD_1]] to i32
; CHECK-NEXT:    [[SRC_END:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i32 [[N_ADD_1_EXT]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC]], [[LOWER:%.*]]
; CHECK-NEXT:    [[CMP_SRC_END:%.*]] = icmp uge i8* [[SRC_END]], [[UPPER:%.*]]
; CHECK-NEXT:    [[OR_PRECOND_0:%.*]] = or i1 [[CMP_SRC_START]], [[CMP_SRC_END]]
; CHECK-NEXT:    br i1 [[OR_PRECOND_0]], label [[TRAP_BB:%.*]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[STEP_ADD_1:%.*]] = add nuw nsw i16 [[STEP:%.*]], 1
; CHECK-NEXT:    [[STEP_ADD_1_EXT:%.*]] = zext i16 [[STEP_ADD_1]] to i32
; CHECK-NEXT:    [[STEP_ULT_N:%.*]] = icmp ult i32 [[STEP_ADD_1_EXT]], [[N_ADD_1_EXT]]
; CHECK-NEXT:    br i1 [[STEP_ULT_N]], label [[PTR_CHECK:%.*]], label [[EXIT:%.*]]
; CHECK:       ptr.check:
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i32 [[STEP_ADD_1_EXT]]
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 [[CMP_STEP_START]], false
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;

entry:
  %N.add.1 = add nuw nsw i16 %N, 1
  %N.add.1.ext = zext i16 %N.add.1 to i32
  %src.end = getelementptr inbounds i8, i8* %src, i32 %N.add.1.ext
  %cmp.src.start = icmp ult i8* %src, %lower
  %cmp.src.end = icmp uge i8* %src.end, %upper
  %or.precond.0 = or i1 %cmp.src.start, %cmp.src.end
  br i1 %or.precond.0, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %step.add.1 = add nuw nsw i16 %step, 1
  %step.add.1.ext = zext i16 %step.add.1 to i32
  %step.ult.N = icmp ult i32 %step.add.1.ext, %N.add.1.ext
  br i1 %step.ult.N, label %ptr.check, label %exit

ptr.check:
  %src.step = getelementptr inbounds i8, i8* %src, i32 %step.add.1.ext
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}

define i4 @ptr_N_step_zext_n_zext_out_of_bounds(i8* %src, i8* %lower, i8* %upper, i16 %N, i16 %step) {
; CHECK-LABEL: @ptr_N_step_zext_n_zext_out_of_bounds(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[N_ADD_2:%.*]] = add nuw nsw i16 [[N:%.*]], 2
; CHECK-NEXT:    [[N_ADD_2_EXT:%.*]] = zext i16 [[N_ADD_2]] to i32
; CHECK-NEXT:    [[SRC_END:%.*]] = getelementptr inbounds i8, i8* [[SRC:%.*]], i32 [[N_ADD_2_EXT]]
; CHECK-NEXT:    [[CMP_SRC_START:%.*]] = icmp ult i8* [[SRC]], [[LOWER:%.*]]
; CHECK-NEXT:    [[CMP_SRC_END:%.*]] = icmp uge i8* [[SRC_END]], [[UPPER:%.*]]
; CHECK-NEXT:    [[OR_PRECOND_0:%.*]] = or i1 [[CMP_SRC_START]], [[CMP_SRC_END]]
; CHECK-NEXT:    br i1 [[OR_PRECOND_0]], label [[TRAP_BB:%.*]], label [[STEP_CHECK:%.*]]
; CHECK:       trap.bb:
; CHECK-NEXT:    ret i4 2
; CHECK:       step.check:
; CHECK-NEXT:    [[STEP_ADD_2:%.*]] = add nuw nsw i16 [[STEP:%.*]], 2
; CHECK-NEXT:    [[STEP_ADD_2_EXT:%.*]] = zext i16 [[STEP_ADD_2]] to i32
; CHECK-NEXT:    [[STEP_EXT:%.*]] = zext i16 [[STEP]] to i32
; CHECK-NEXT:    [[STEP_ULT_N:%.*]] = icmp ult i32 [[STEP_EXT]], [[N_ADD_2_EXT]]
; CHECK-NEXT:    br i1 [[STEP_ULT_N]], label [[PTR_CHECK:%.*]], label [[EXIT:%.*]]
; CHECK:       ptr.check:
; CHECK-NEXT:    [[SRC_STEP:%.*]] = getelementptr inbounds i8, i8* [[SRC]], i32 [[STEP_ADD_2_EXT]]
; CHECK-NEXT:    [[CMP_STEP_START:%.*]] = icmp ult i8* [[SRC_STEP]], [[LOWER]]
; CHECK-NEXT:    [[CMP_STEP_END:%.*]] = icmp uge i8* [[SRC_STEP]], [[UPPER]]
; CHECK-NEXT:    [[OR_CHECK:%.*]] = or i1 [[CMP_STEP_START]], [[CMP_STEP_END]]
; CHECK-NEXT:    br i1 [[OR_CHECK]], label [[TRAP_BB]], label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i4 3
;

entry:
  %N.add.2 = add nuw nsw i16 %N, 2
  %N.add.2.ext = zext i16 %N.add.2 to i32
  %src.end = getelementptr inbounds i8, i8* %src, i32 %N.add.2.ext
  %cmp.src.start = icmp ult i8* %src, %lower
  %cmp.src.end = icmp uge i8* %src.end, %upper
  %or.precond.0 = or i1 %cmp.src.start, %cmp.src.end
  br i1 %or.precond.0, label %trap.bb, label %step.check

trap.bb:
  ret i4 2

step.check:
  %step.add.2 = add nuw nsw i16 %step, 2
  %step.add.2.ext = zext i16 %step.add.2 to i32
  %step.ext = zext i16 %step to i32
  %step.ult.N = icmp ult i32 %step.ext, %N.add.2.ext
  br i1 %step.ult.N, label %ptr.check, label %exit

ptr.check:
  %src.step = getelementptr inbounds i8, i8* %src, i32 %step.add.2.ext
  %cmp.step.start = icmp ult i8* %src.step, %lower
  %cmp.step.end = icmp uge i8* %src.step, %upper
  %or.check = or i1 %cmp.step.start, %cmp.step.end
  br i1 %or.check, label %trap.bb, label %exit

exit:
  ret i4 3
}
