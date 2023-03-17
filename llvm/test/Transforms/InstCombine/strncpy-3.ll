; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instcombine -S | FileCheck %s


@str = constant [2 x i8] c"a\00"
@str2 = constant [3 x i8] c"abc"
@str3 = constant [4 x i8] c"abcd"

declare i8* @strncpy(i8*, i8*, i64)


define void @fill_with_zeros(i8* %dst) {
; CHECK-LABEL: @fill_with_zeros(
; CHECK-NEXT:    [[TMP1:%.*]] = bitcast i8* [[DST:%.*]] to i32*
; CHECK-NEXT:    store i32 97, i32* [[TMP1]], align 1
; CHECK-NEXT:    ret void
;
  tail call i8* @strncpy(i8* %dst, i8* getelementptr inbounds ([2 x i8], [2 x i8]* @str, i64 0, i64 0), i64 4)
  ret void
}

define void @fill_with_zeros2(i8* %dst) {
; CHECK-LABEL: @fill_with_zeros2(
; CHECK-NEXT:    [[TMP1:%.*]] = bitcast i8* [[DST:%.*]] to i32*
; CHECK-NEXT:    store i32 6513249, i32* [[TMP1]], align 1
; CHECK-NEXT:    ret void
;
  tail call i8* @strncpy(i8* %dst, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @str2, i64 0, i64 0), i64 4)
  ret void
}

define void @fill_with_zeros3(i8* %dst) {
; CHECK-LABEL: @fill_with_zeros3(
; CHECK-NEXT:    [[TMP1:%.*]] = bitcast i8* [[DST:%.*]] to i32*
; CHECK-NEXT:    store i32 1684234849, i32* [[TMP1]], align 1
; CHECK-NEXT:    ret void
;
  tail call i8* @strncpy(i8* %dst, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str3, i64 0, i64 0), i64 4)
  ret void
}

define void @fill_with_zeros4(i8* %dst) {
; CHECK-LABEL: @fill_with_zeros4(
; CHECK-NEXT:    call void @llvm.memcpy.p0i8.p0i8.i64(i8* noundef nonnull align 1 dereferenceable(128) [[DST:%.*]], i8* noundef nonnull align 1 dereferenceable(128) getelementptr inbounds ([129 x i8], [129 x i8]* @str.2, i64 0, i64 0), i64 128, i1 false)
; CHECK-NEXT:    ret void
;
  tail call i8* @strncpy(i8* %dst, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str3, i64 0, i64 0), i64 128)
  ret void
}

define void @no_simplify(i8* %dst) {
; CHECK-LABEL: @no_simplify(
; CHECK-NEXT:    [[TMP1:%.*]] = tail call i8* @strncpy(i8* noundef nonnull dereferenceable(1) [[DST:%.*]], i8* noundef nonnull dereferenceable(5) getelementptr inbounds ([4 x i8], [4 x i8]* @str3, i64 0, i64 0), i64 129)
; CHECK-NEXT:    ret void
;
  tail call i8* @strncpy(i8* %dst, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str3, i64 0, i64 0), i64 129)
  ret void
}
