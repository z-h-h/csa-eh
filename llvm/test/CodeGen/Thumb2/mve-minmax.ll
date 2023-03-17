; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=thumbv8.1m.main-none-none-eabi -mattr=+mve,+fullfp16 -verify-machineinstrs %s -o - | FileCheck %s --check-prefix=CHECK --check-prefix=CHECK-MVE
; RUN: llc -mtriple=thumbv8.1m.main-none-none-eabi -mattr=+mve.fp -verify-machineinstrs %s -o - | FileCheck %s --check-prefix=CHECK --check-prefix=CHECK-MVEFP

define arm_aapcs_vfpcc <16 x i8> @smin_v16i8(<16 x i8> %s1, <16 x i8> %s2) {
; CHECK-LABEL: smin_v16i8:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vmin.s8 q0, q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = icmp slt <16 x i8> %s1, %s2
  %1 = select <16 x i1> %0, <16 x i8> %s1, <16 x i8> %s2
  ret <16 x i8> %1
}

define arm_aapcs_vfpcc <8 x i16> @smin_v8i16(<8 x i16> %s1, <8 x i16> %s2) {
; CHECK-LABEL: smin_v8i16:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vmin.s16 q0, q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = icmp slt <8 x i16> %s1, %s2
  %1 = select <8 x i1> %0, <8 x i16> %s1, <8 x i16> %s2
  ret <8 x i16> %1
}

define arm_aapcs_vfpcc <4 x i32> @smin_v4i32(<4 x i32> %s1, <4 x i32> %s2) {
; CHECK-LABEL: smin_v4i32:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vmin.s32 q0, q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = icmp slt <4 x i32> %s1, %s2
  %1 = select <4 x i1> %0, <4 x i32> %s1, <4 x i32> %s2
  ret <4 x i32> %1
}

define arm_aapcs_vfpcc <2 x i64> @smin_v2i64(<2 x i64> %s1, <2 x i64> %s2) {
; CHECK-LABEL: smin_v2i64:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    .save {r7, lr}
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    vmov r2, s6
; CHECK-NEXT:    movs r0, #0
; CHECK-NEXT:    vmov r3, s2
; CHECK-NEXT:    vmov r12, s7
; CHECK-NEXT:    vmov r1, s3
; CHECK-NEXT:    vmov lr, s1
; CHECK-NEXT:    subs r2, r3, r2
; CHECK-NEXT:    vmov r3, s0
; CHECK-NEXT:    vmov r2, s4
; CHECK-NEXT:    sbcs.w r1, r1, r12
; CHECK-NEXT:    vmov r12, s5
; CHECK-NEXT:    mov.w r1, #0
; CHECK-NEXT:    it lt
; CHECK-NEXT:    movlt r1, #1
; CHECK-NEXT:    cmp r1, #0
; CHECK-NEXT:    csetm r1, ne
; CHECK-NEXT:    subs r2, r3, r2
; CHECK-NEXT:    sbcs.w r2, lr, r12
; CHECK-NEXT:    it lt
; CHECK-NEXT:    movlt r0, #1
; CHECK-NEXT:    cmp r0, #0
; CHECK-NEXT:    csetm r0, ne
; CHECK-NEXT:    vmov q2[2], q2[0], r0, r1
; CHECK-NEXT:    vmov q2[3], q2[1], r0, r1
; CHECK-NEXT:    vbic q1, q1, q2
; CHECK-NEXT:    vand q0, q0, q2
; CHECK-NEXT:    vorr q0, q0, q1
; CHECK-NEXT:    pop {r7, pc}
entry:
  %0 = icmp slt <2 x i64> %s1, %s2
  %1 = select <2 x i1> %0, <2 x i64> %s1, <2 x i64> %s2
  ret <2 x i64> %1
}

define arm_aapcs_vfpcc <16 x i8> @umin_v16i8(<16 x i8> %s1, <16 x i8> %s2) {
; CHECK-LABEL: umin_v16i8:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vmin.u8 q0, q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = icmp ult <16 x i8> %s1, %s2
  %1 = select <16 x i1> %0, <16 x i8> %s1, <16 x i8> %s2
  ret <16 x i8> %1
}

define arm_aapcs_vfpcc <8 x i16> @umin_v8i16(<8 x i16> %s1, <8 x i16> %s2) {
; CHECK-LABEL: umin_v8i16:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vmin.u16 q0, q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = icmp ult <8 x i16> %s1, %s2
  %1 = select <8 x i1> %0, <8 x i16> %s1, <8 x i16> %s2
  ret <8 x i16> %1
}

define arm_aapcs_vfpcc <4 x i32> @umin_v4i32(<4 x i32> %s1, <4 x i32> %s2) {
; CHECK-LABEL: umin_v4i32:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vmin.u32 q0, q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = icmp ult <4 x i32> %s1, %s2
  %1 = select <4 x i1> %0, <4 x i32> %s1, <4 x i32> %s2
  ret <4 x i32> %1
}

define arm_aapcs_vfpcc <2 x i64> @umin_v2i64(<2 x i64> %s1, <2 x i64> %s2) {
; CHECK-LABEL: umin_v2i64:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    .save {r7, lr}
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    vmov r2, s6
; CHECK-NEXT:    movs r0, #0
; CHECK-NEXT:    vmov r3, s2
; CHECK-NEXT:    vmov r12, s7
; CHECK-NEXT:    vmov r1, s3
; CHECK-NEXT:    vmov lr, s1
; CHECK-NEXT:    subs r2, r3, r2
; CHECK-NEXT:    vmov r3, s0
; CHECK-NEXT:    vmov r2, s4
; CHECK-NEXT:    sbcs.w r1, r1, r12
; CHECK-NEXT:    vmov r12, s5
; CHECK-NEXT:    mov.w r1, #0
; CHECK-NEXT:    it lo
; CHECK-NEXT:    movlo r1, #1
; CHECK-NEXT:    cmp r1, #0
; CHECK-NEXT:    csetm r1, ne
; CHECK-NEXT:    subs r2, r3, r2
; CHECK-NEXT:    sbcs.w r2, lr, r12
; CHECK-NEXT:    it lo
; CHECK-NEXT:    movlo r0, #1
; CHECK-NEXT:    cmp r0, #0
; CHECK-NEXT:    csetm r0, ne
; CHECK-NEXT:    vmov q2[2], q2[0], r0, r1
; CHECK-NEXT:    vmov q2[3], q2[1], r0, r1
; CHECK-NEXT:    vbic q1, q1, q2
; CHECK-NEXT:    vand q0, q0, q2
; CHECK-NEXT:    vorr q0, q0, q1
; CHECK-NEXT:    pop {r7, pc}
entry:
  %0 = icmp ult <2 x i64> %s1, %s2
  %1 = select <2 x i1> %0, <2 x i64> %s1, <2 x i64> %s2
  ret <2 x i64> %1
}


define arm_aapcs_vfpcc <16 x i8> @smax_v16i8(<16 x i8> %s1, <16 x i8> %s2) {
; CHECK-LABEL: smax_v16i8:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vmax.s8 q0, q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = icmp sgt <16 x i8> %s1, %s2
  %1 = select <16 x i1> %0, <16 x i8> %s1, <16 x i8> %s2
  ret <16 x i8> %1
}

define arm_aapcs_vfpcc <8 x i16> @smax_v8i16(<8 x i16> %s1, <8 x i16> %s2) {
; CHECK-LABEL: smax_v8i16:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vmax.s16 q0, q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = icmp sgt <8 x i16> %s1, %s2
  %1 = select <8 x i1> %0, <8 x i16> %s1, <8 x i16> %s2
  ret <8 x i16> %1
}

define arm_aapcs_vfpcc <4 x i32> @smax_v4i32(<4 x i32> %s1, <4 x i32> %s2) {
; CHECK-LABEL: smax_v4i32:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vmax.s32 q0, q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = icmp sgt <4 x i32> %s1, %s2
  %1 = select <4 x i1> %0, <4 x i32> %s1, <4 x i32> %s2
  ret <4 x i32> %1
}

define arm_aapcs_vfpcc <2 x i64> @smax_v2i64(<2 x i64> %s1, <2 x i64> %s2) {
; CHECK-LABEL: smax_v2i64:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    .save {r7, lr}
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    vmov r2, s2
; CHECK-NEXT:    movs r0, #0
; CHECK-NEXT:    vmov r3, s6
; CHECK-NEXT:    vmov r12, s3
; CHECK-NEXT:    vmov r1, s7
; CHECK-NEXT:    vmov lr, s5
; CHECK-NEXT:    subs r2, r3, r2
; CHECK-NEXT:    vmov r3, s4
; CHECK-NEXT:    vmov r2, s0
; CHECK-NEXT:    sbcs.w r1, r1, r12
; CHECK-NEXT:    vmov r12, s1
; CHECK-NEXT:    mov.w r1, #0
; CHECK-NEXT:    it lt
; CHECK-NEXT:    movlt r1, #1
; CHECK-NEXT:    cmp r1, #0
; CHECK-NEXT:    csetm r1, ne
; CHECK-NEXT:    subs r2, r3, r2
; CHECK-NEXT:    sbcs.w r2, lr, r12
; CHECK-NEXT:    it lt
; CHECK-NEXT:    movlt r0, #1
; CHECK-NEXT:    cmp r0, #0
; CHECK-NEXT:    csetm r0, ne
; CHECK-NEXT:    vmov q2[2], q2[0], r0, r1
; CHECK-NEXT:    vmov q2[3], q2[1], r0, r1
; CHECK-NEXT:    vbic q1, q1, q2
; CHECK-NEXT:    vand q0, q0, q2
; CHECK-NEXT:    vorr q0, q0, q1
; CHECK-NEXT:    pop {r7, pc}
entry:
  %0 = icmp sgt <2 x i64> %s1, %s2
  %1 = select <2 x i1> %0, <2 x i64> %s1, <2 x i64> %s2
  ret <2 x i64> %1
}

define arm_aapcs_vfpcc <16 x i8> @umax_v16i8(<16 x i8> %s1, <16 x i8> %s2) {
; CHECK-LABEL: umax_v16i8:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vmax.u8 q0, q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = icmp ugt <16 x i8> %s1, %s2
  %1 = select <16 x i1> %0, <16 x i8> %s1, <16 x i8> %s2
  ret <16 x i8> %1
}

define arm_aapcs_vfpcc <8 x i16> @umax_v8i16(<8 x i16> %s1, <8 x i16> %s2) {
; CHECK-LABEL: umax_v8i16:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vmax.u16 q0, q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = icmp ugt <8 x i16> %s1, %s2
  %1 = select <8 x i1> %0, <8 x i16> %s1, <8 x i16> %s2
  ret <8 x i16> %1
}

define arm_aapcs_vfpcc <4 x i32> @umax_v4i32(<4 x i32> %s1, <4 x i32> %s2) {
; CHECK-LABEL: umax_v4i32:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vmax.u32 q0, q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = icmp ugt <4 x i32> %s1, %s2
  %1 = select <4 x i1> %0, <4 x i32> %s1, <4 x i32> %s2
  ret <4 x i32> %1
}

define arm_aapcs_vfpcc <2 x i64> @umax_v2i64(<2 x i64> %s1, <2 x i64> %s2) {
; CHECK-LABEL: umax_v2i64:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    .save {r7, lr}
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    vmov r2, s2
; CHECK-NEXT:    movs r0, #0
; CHECK-NEXT:    vmov r3, s6
; CHECK-NEXT:    vmov r12, s3
; CHECK-NEXT:    vmov r1, s7
; CHECK-NEXT:    vmov lr, s5
; CHECK-NEXT:    subs r2, r3, r2
; CHECK-NEXT:    vmov r3, s4
; CHECK-NEXT:    vmov r2, s0
; CHECK-NEXT:    sbcs.w r1, r1, r12
; CHECK-NEXT:    vmov r12, s1
; CHECK-NEXT:    mov.w r1, #0
; CHECK-NEXT:    it lo
; CHECK-NEXT:    movlo r1, #1
; CHECK-NEXT:    cmp r1, #0
; CHECK-NEXT:    csetm r1, ne
; CHECK-NEXT:    subs r2, r3, r2
; CHECK-NEXT:    sbcs.w r2, lr, r12
; CHECK-NEXT:    it lo
; CHECK-NEXT:    movlo r0, #1
; CHECK-NEXT:    cmp r0, #0
; CHECK-NEXT:    csetm r0, ne
; CHECK-NEXT:    vmov q2[2], q2[0], r0, r1
; CHECK-NEXT:    vmov q2[3], q2[1], r0, r1
; CHECK-NEXT:    vbic q1, q1, q2
; CHECK-NEXT:    vand q0, q0, q2
; CHECK-NEXT:    vorr q0, q0, q1
; CHECK-NEXT:    pop {r7, pc}
entry:
  %0 = icmp ugt <2 x i64> %s1, %s2
  %1 = select <2 x i1> %0, <2 x i64> %s1, <2 x i64> %s2
  ret <2 x i64> %1
}


define arm_aapcs_vfpcc <4 x float> @maxnm_float32_t(<4 x float> %src1, <4 x float> %src2) {
; CHECK-MVE-LABEL: maxnm_float32_t:
; CHECK-MVE:       @ %bb.0: @ %entry
; CHECK-MVE-NEXT:    vmaxnm.f32 s11, s7, s3
; CHECK-MVE-NEXT:    vmaxnm.f32 s10, s6, s2
; CHECK-MVE-NEXT:    vmaxnm.f32 s9, s5, s1
; CHECK-MVE-NEXT:    vmaxnm.f32 s8, s4, s0
; CHECK-MVE-NEXT:    vmov q0, q2
; CHECK-MVE-NEXT:    bx lr
;
; CHECK-MVEFP-LABEL: maxnm_float32_t:
; CHECK-MVEFP:       @ %bb.0: @ %entry
; CHECK-MVEFP-NEXT:    vmaxnm.f32 q0, q1, q0
; CHECK-MVEFP-NEXT:    bx lr
entry:
  %cmp = fcmp fast ogt <4 x float> %src2, %src1
  %0 = select <4 x i1> %cmp, <4 x float> %src2, <4 x float> %src1
  ret <4 x float> %0
}

define arm_aapcs_vfpcc <8 x half> @minnm_float16_t(<8 x half> %src1, <8 x half> %src2) {
; CHECK-MVE-LABEL: minnm_float16_t:
; CHECK-MVE:       @ %bb.0: @ %entry
; CHECK-MVE-NEXT:    vmov q2, q0
; CHECK-MVE-NEXT:    vmovx.f16 s2, s4
; CHECK-MVE-NEXT:    vmovx.f16 s0, s8
; CHECK-MVE-NEXT:    vmovx.f16 s14, s5
; CHECK-MVE-NEXT:    vminnm.f16 s12, s2, s0
; CHECK-MVE-NEXT:    vminnm.f16 s0, s4, s8
; CHECK-MVE-NEXT:    vins.f16 s0, s12
; CHECK-MVE-NEXT:    vmovx.f16 s12, s9
; CHECK-MVE-NEXT:    vminnm.f16 s12, s14, s12
; CHECK-MVE-NEXT:    vminnm.f16 s1, s5, s9
; CHECK-MVE-NEXT:    vins.f16 s1, s12
; CHECK-MVE-NEXT:    vmovx.f16 s12, s10
; CHECK-MVE-NEXT:    vmovx.f16 s14, s6
; CHECK-MVE-NEXT:    vminnm.f16 s2, s6, s10
; CHECK-MVE-NEXT:    vminnm.f16 s12, s14, s12
; CHECK-MVE-NEXT:    vmovx.f16 s14, s7
; CHECK-MVE-NEXT:    vins.f16 s2, s12
; CHECK-MVE-NEXT:    vmovx.f16 s12, s11
; CHECK-MVE-NEXT:    vminnm.f16 s12, s14, s12
; CHECK-MVE-NEXT:    vminnm.f16 s3, s7, s11
; CHECK-MVE-NEXT:    vins.f16 s3, s12
; CHECK-MVE-NEXT:    bx lr
;
; CHECK-MVEFP-LABEL: minnm_float16_t:
; CHECK-MVEFP:       @ %bb.0: @ %entry
; CHECK-MVEFP-NEXT:    vminnm.f16 q0, q1, q0
; CHECK-MVEFP-NEXT:    bx lr
entry:
  %cmp = fcmp fast ogt <8 x half> %src2, %src1
  %0 = select <8 x i1> %cmp, <8 x half> %src1, <8 x half> %src2
  ret <8 x half> %0
}

define arm_aapcs_vfpcc <2 x double> @maxnm_float64_t(<2 x double> %src1, <2 x double> %src2) {
; CHECK-LABEL: maxnm_float64_t:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    .save {r4, lr}
; CHECK-NEXT:    push {r4, lr}
; CHECK-NEXT:    .vsave {d8, d9, d10, d11}
; CHECK-NEXT:    vpush {d8, d9, d10, d11}
; CHECK-NEXT:    vmov q4, q1
; CHECK-NEXT:    vmov q5, q0
; CHECK-NEXT:    vmov r0, r1, d9
; CHECK-NEXT:    vmov r2, r3, d11
; CHECK-NEXT:    bl __aeabi_dcmpgt
; CHECK-NEXT:    vmov r12, r1, d8
; CHECK-NEXT:    cmp r0, #0
; CHECK-NEXT:    vmov r2, r3, d10
; CHECK-NEXT:    it ne
; CHECK-NEXT:    movne r0, #1
; CHECK-NEXT:    cmp r0, #0
; CHECK-NEXT:    csetm r4, ne
; CHECK-NEXT:    mov r0, r12
; CHECK-NEXT:    bl __aeabi_dcmpgt
; CHECK-NEXT:    cmp r0, #0
; CHECK-NEXT:    it ne
; CHECK-NEXT:    movne r0, #1
; CHECK-NEXT:    cmp r0, #0
; CHECK-NEXT:    csetm r0, ne
; CHECK-NEXT:    vmov q0[2], q0[0], r0, r4
; CHECK-NEXT:    vmov q0[3], q0[1], r0, r4
; CHECK-NEXT:    vbic q1, q5, q0
; CHECK-NEXT:    vand q0, q4, q0
; CHECK-NEXT:    vorr q0, q0, q1
; CHECK-NEXT:    vpop {d8, d9, d10, d11}
; CHECK-NEXT:    pop {r4, pc}
entry:
  %cmp = fcmp fast ogt <2 x double> %src2, %src1
  %0 = select <2 x i1> %cmp, <2 x double> %src2, <2 x double> %src1
  ret <2 x double> %0
}
