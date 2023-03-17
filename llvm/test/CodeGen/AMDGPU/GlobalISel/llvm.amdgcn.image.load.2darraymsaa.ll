; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -global-isel -mtriple=amdgcn-mesa-mesa3d -mcpu=tahiti -verify-machineinstrs < %s | FileCheck -check-prefix=GFX6 %s
; RUN: llc -global-isel -mtriple=amdgcn-mesa-mesa3d -mcpu=gfx1010 -verify-machineinstrs < %s | FileCheck -check-prefix=GFX10 %s

define amdgpu_ps <4 x float> @load_2darraymsaa_v4f32_xyzw(<8 x i32> inreg %rsrc, i32 %s, i32 %t, i32 %slice, i32 %fragid) {
; GFX6-LABEL: load_2darraymsaa_v4f32_xyzw:
; GFX6:       ; %bb.0:
; GFX6-NEXT:    s_mov_b32 s0, s2
; GFX6-NEXT:    s_mov_b32 s1, s3
; GFX6-NEXT:    s_mov_b32 s2, s4
; GFX6-NEXT:    s_mov_b32 s3, s5
; GFX6-NEXT:    s_mov_b32 s4, s6
; GFX6-NEXT:    s_mov_b32 s5, s7
; GFX6-NEXT:    s_mov_b32 s6, s8
; GFX6-NEXT:    s_mov_b32 s7, s9
; GFX6-NEXT:    image_load v[0:3], v[0:3], s[0:7] dmask:0xf unorm da
; GFX6-NEXT:    s_waitcnt vmcnt(0)
; GFX6-NEXT:    ; return to shader part epilog
;
; GFX10-LABEL: load_2darraymsaa_v4f32_xyzw:
; GFX10:       ; %bb.0:
; GFX10-NEXT:    s_mov_b32 s0, s2
; GFX10-NEXT:    s_mov_b32 s1, s3
; GFX10-NEXT:    s_mov_b32 s2, s4
; GFX10-NEXT:    s_mov_b32 s3, s5
; GFX10-NEXT:    s_mov_b32 s4, s6
; GFX10-NEXT:    s_mov_b32 s5, s7
; GFX10-NEXT:    s_mov_b32 s6, s8
; GFX10-NEXT:    s_mov_b32 s7, s9
; GFX10-NEXT:    image_load v[0:3], v[0:3], s[0:7] dmask:0xf dim:SQ_RSRC_IMG_2D_MSAA_ARRAY unorm
; GFX10-NEXT:    s_waitcnt vmcnt(0)
; GFX10-NEXT:    ; return to shader part epilog
  %v = call <4 x float> @llvm.amdgcn.image.load.2darraymsaa.v4f32.i32(i32 15, i32 %s, i32 %t, i32 %slice, i32 %fragid, <8 x i32> %rsrc, i32 0, i32 0)
  ret <4 x float> %v
}

define amdgpu_ps <4 x float> @load_2darraymsaa_v4f32_xyzw_tfe(<8 x i32> inreg %rsrc, i32 addrspace(1)* inreg %out, i32 %s, i32 %t, i32 %slice, i32 %fragid) {
; GFX6-LABEL: load_2darraymsaa_v4f32_xyzw_tfe:
; GFX6:       ; %bb.0:
; GFX6-NEXT:    v_mov_b32_e32 v5, v0
; GFX6-NEXT:    v_mov_b32_e32 v0, 0
; GFX6-NEXT:    s_mov_b32 s0, s2
; GFX6-NEXT:    s_mov_b32 s1, s3
; GFX6-NEXT:    s_mov_b32 s2, s4
; GFX6-NEXT:    s_mov_b32 s3, s5
; GFX6-NEXT:    s_mov_b32 s4, s6
; GFX6-NEXT:    s_mov_b32 s5, s7
; GFX6-NEXT:    s_mov_b32 s6, s8
; GFX6-NEXT:    s_mov_b32 s7, s9
; GFX6-NEXT:    v_mov_b32_e32 v6, v1
; GFX6-NEXT:    v_mov_b32_e32 v7, v2
; GFX6-NEXT:    v_mov_b32_e32 v8, v3
; GFX6-NEXT:    v_mov_b32_e32 v1, v0
; GFX6-NEXT:    v_mov_b32_e32 v2, v0
; GFX6-NEXT:    v_mov_b32_e32 v3, v0
; GFX6-NEXT:    v_mov_b32_e32 v4, v0
; GFX6-NEXT:    image_load v[0:4], v[5:8], s[0:7] dmask:0xf unorm tfe da
; GFX6-NEXT:    s_mov_b32 s8, s10
; GFX6-NEXT:    s_mov_b32 s9, s11
; GFX6-NEXT:    s_mov_b32 s10, -1
; GFX6-NEXT:    s_mov_b32 s11, 0xf000
; GFX6-NEXT:    s_waitcnt vmcnt(0)
; GFX6-NEXT:    buffer_store_dword v4, off, s[8:11], 0
; GFX6-NEXT:    s_waitcnt vmcnt(0) expcnt(0)
; GFX6-NEXT:    ; return to shader part epilog
;
; GFX10-LABEL: load_2darraymsaa_v4f32_xyzw_tfe:
; GFX10:       ; %bb.0:
; GFX10-NEXT:    v_mov_b32_e32 v9, 0
; GFX10-NEXT:    v_mov_b32_e32 v5, v0
; GFX10-NEXT:    v_mov_b32_e32 v6, v1
; GFX10-NEXT:    v_mov_b32_e32 v7, v2
; GFX10-NEXT:    v_mov_b32_e32 v8, v3
; GFX10-NEXT:    v_mov_b32_e32 v10, v9
; GFX10-NEXT:    v_mov_b32_e32 v11, v9
; GFX10-NEXT:    v_mov_b32_e32 v12, v9
; GFX10-NEXT:    v_mov_b32_e32 v13, v9
; GFX10-NEXT:    v_mov_b32_e32 v0, v9
; GFX10-NEXT:    s_mov_b32 s0, s2
; GFX10-NEXT:    s_mov_b32 s1, s3
; GFX10-NEXT:    s_mov_b32 s2, s4
; GFX10-NEXT:    s_mov_b32 s3, s5
; GFX10-NEXT:    s_mov_b32 s4, s6
; GFX10-NEXT:    s_mov_b32 s5, s7
; GFX10-NEXT:    s_mov_b32 s6, s8
; GFX10-NEXT:    s_mov_b32 s7, s9
; GFX10-NEXT:    v_mov_b32_e32 v1, v10
; GFX10-NEXT:    v_mov_b32_e32 v2, v11
; GFX10-NEXT:    v_mov_b32_e32 v3, v12
; GFX10-NEXT:    v_mov_b32_e32 v4, v13
; GFX10-NEXT:    image_load v[0:4], v[5:8], s[0:7] dmask:0xf dim:SQ_RSRC_IMG_2D_MSAA_ARRAY unorm tfe
; GFX10-NEXT:    s_waitcnt vmcnt(0)
; GFX10-NEXT:    global_store_dword v9, v4, s[10:11]
; GFX10-NEXT:    s_waitcnt_vscnt null, 0x0
; GFX10-NEXT:    ; return to shader part epilog
  %v = call { <4 x float>, i32 } @llvm.amdgcn.image.load.2darraymsaa.sl_v4f32i32s.i32(i32 15, i32 %s, i32 %t, i32 %slice, i32 %fragid, <8 x i32> %rsrc, i32 1, i32 0)
  %v.vec = extractvalue { <4 x float>, i32 } %v, 0
  %v.err = extractvalue { <4 x float>, i32 } %v, 1
  store i32 %v.err, i32 addrspace(1)* %out, align 4
  ret <4 x float> %v.vec
}

define amdgpu_ps <4 x float> @load_2darraymsaa_v4f32_xyzw_tfe_lwe(<8 x i32> inreg %rsrc, i32 addrspace(1)* inreg %out, i32 %s, i32 %t, i32 %slice, i32 %fragid) {
; GFX6-LABEL: load_2darraymsaa_v4f32_xyzw_tfe_lwe:
; GFX6:       ; %bb.0:
; GFX6-NEXT:    v_mov_b32_e32 v5, v0
; GFX6-NEXT:    v_mov_b32_e32 v0, 0
; GFX6-NEXT:    s_mov_b32 s0, s2
; GFX6-NEXT:    s_mov_b32 s1, s3
; GFX6-NEXT:    s_mov_b32 s2, s4
; GFX6-NEXT:    s_mov_b32 s3, s5
; GFX6-NEXT:    s_mov_b32 s4, s6
; GFX6-NEXT:    s_mov_b32 s5, s7
; GFX6-NEXT:    s_mov_b32 s6, s8
; GFX6-NEXT:    s_mov_b32 s7, s9
; GFX6-NEXT:    v_mov_b32_e32 v6, v1
; GFX6-NEXT:    v_mov_b32_e32 v7, v2
; GFX6-NEXT:    v_mov_b32_e32 v8, v3
; GFX6-NEXT:    v_mov_b32_e32 v1, v0
; GFX6-NEXT:    v_mov_b32_e32 v2, v0
; GFX6-NEXT:    v_mov_b32_e32 v3, v0
; GFX6-NEXT:    v_mov_b32_e32 v4, v0
; GFX6-NEXT:    image_load v[0:4], v[5:8], s[0:7] dmask:0xf unorm tfe lwe da
; GFX6-NEXT:    s_mov_b32 s8, s10
; GFX6-NEXT:    s_mov_b32 s9, s11
; GFX6-NEXT:    s_mov_b32 s10, -1
; GFX6-NEXT:    s_mov_b32 s11, 0xf000
; GFX6-NEXT:    s_waitcnt vmcnt(0)
; GFX6-NEXT:    buffer_store_dword v4, off, s[8:11], 0
; GFX6-NEXT:    s_waitcnt vmcnt(0) expcnt(0)
; GFX6-NEXT:    ; return to shader part epilog
;
; GFX10-LABEL: load_2darraymsaa_v4f32_xyzw_tfe_lwe:
; GFX10:       ; %bb.0:
; GFX10-NEXT:    v_mov_b32_e32 v9, 0
; GFX10-NEXT:    v_mov_b32_e32 v5, v0
; GFX10-NEXT:    v_mov_b32_e32 v6, v1
; GFX10-NEXT:    v_mov_b32_e32 v7, v2
; GFX10-NEXT:    v_mov_b32_e32 v8, v3
; GFX10-NEXT:    v_mov_b32_e32 v10, v9
; GFX10-NEXT:    v_mov_b32_e32 v11, v9
; GFX10-NEXT:    v_mov_b32_e32 v12, v9
; GFX10-NEXT:    v_mov_b32_e32 v13, v9
; GFX10-NEXT:    v_mov_b32_e32 v0, v9
; GFX10-NEXT:    s_mov_b32 s0, s2
; GFX10-NEXT:    s_mov_b32 s1, s3
; GFX10-NEXT:    s_mov_b32 s2, s4
; GFX10-NEXT:    s_mov_b32 s3, s5
; GFX10-NEXT:    s_mov_b32 s4, s6
; GFX10-NEXT:    s_mov_b32 s5, s7
; GFX10-NEXT:    s_mov_b32 s6, s8
; GFX10-NEXT:    s_mov_b32 s7, s9
; GFX10-NEXT:    v_mov_b32_e32 v1, v10
; GFX10-NEXT:    v_mov_b32_e32 v2, v11
; GFX10-NEXT:    v_mov_b32_e32 v3, v12
; GFX10-NEXT:    v_mov_b32_e32 v4, v13
; GFX10-NEXT:    image_load v[0:4], v[5:8], s[0:7] dmask:0xf dim:SQ_RSRC_IMG_2D_MSAA_ARRAY unorm tfe lwe
; GFX10-NEXT:    s_waitcnt vmcnt(0)
; GFX10-NEXT:    global_store_dword v9, v4, s[10:11]
; GFX10-NEXT:    s_waitcnt_vscnt null, 0x0
; GFX10-NEXT:    ; return to shader part epilog
  %v = call { <4 x float>, i32 } @llvm.amdgcn.image.load.2darraymsaa.sl_v4f32i32s.i32(i32 15, i32 %s, i32 %t, i32 %slice, i32 %fragid, <8 x i32> %rsrc, i32 3, i32 0)
  %v.vec = extractvalue { <4 x float>, i32 } %v, 0
  %v.err = extractvalue { <4 x float>, i32 } %v, 1
  store i32 %v.err, i32 addrspace(1)* %out, align 4
  ret <4 x float> %v.vec
}

declare <4 x float> @llvm.amdgcn.image.load.2darraymsaa.v4f32.i32(i32 immarg, i32, i32, i32, i32, <8 x i32>, i32 immarg, i32 immarg) #0
declare { <4 x float>, i32 } @llvm.amdgcn.image.load.2darraymsaa.sl_v4f32i32s.i32(i32 immarg, i32, i32, i32, i32, <8 x i32>, i32 immarg, i32 immarg) #0

attributes #0 = { nounwind readonly }
