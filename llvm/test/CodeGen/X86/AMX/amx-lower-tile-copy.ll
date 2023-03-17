; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+amx-int8 -mattr=+avx512f -verify-machineinstrs | FileCheck %s

define dso_local void @test1(i8 *%buf) nounwind {
; CHECK-LABEL: test1:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    pushq %rbp
; CHECK-NEXT:    pushq %r15
; CHECK-NEXT:    pushq %r14
; CHECK-NEXT:    pushq %rbx
; CHECK-NEXT:    subq $4056, %rsp # imm = 0xFD8
; CHECK-NEXT:    vpxord %zmm0, %zmm0, %zmm0
; CHECK-NEXT:    vmovdqu64 %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $1, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    ldtilecfg {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movl $64, %eax
; CHECK-NEXT:    movw $8, %r14w
; CHECK-NEXT:    tileloadd (%rdi,%rax), %tmm3
; CHECK-NEXT:    xorl %eax, %eax
; CHECK-NEXT:    testb %al, %al
; CHECK-NEXT:    jne .LBB0_3
; CHECK-NEXT:  # %bb.1: # %loop.header.preheader
; CHECK-NEXT:    movq %rdi, %rbx
; CHECK-NEXT:    xorl %ebp, %ebp
; CHECK-NEXT:    movl $32, %r15d
; CHECK-NEXT:    .p2align 4, 0x90
; CHECK-NEXT:  .LBB0_2: # %loop.header
; CHECK-NEXT:    # =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    movabsq $64, %rax
; CHECK-NEXT:    tilestored %tmm3, 2048(%rsp,%rax) # 1024-byte Folded Spill
; CHECK-NEXT:    vzeroupper
; CHECK-NEXT:    callq foo
; CHECK-NEXT:    ldtilecfg {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movabsq $64, %rax
; CHECK-NEXT:    tileloadd 2048(%rsp,%rax), %tmm3 # 1024-byte Folded Reload
; CHECK-NEXT:    tileloadd (%rbx,%r15), %tmm0
; CHECK-NEXT:    tileloadd (%rbx,%r15), %tmm1
; CHECK-NEXT:    # implicit-def: $rax
; CHECK-NEXT:    movq %rax, {{[-0-9]+}}(%r{{[sb]}}p) # 8-byte Spill
; CHECK-NEXT:    movabsq $64, %rax
; CHECK-NEXT:    tilestored %tmm3, 1024(%rsp,%rax) # 1024-byte Folded Spill
; CHECK-NEXT:    tileloadd {{[-0-9]+}}(%r{{[sb]}}p), %tmm2 # 1024-byte Folded Reload
; CHECK-NEXT:    movq {{[-0-9]+}}(%r{{[sb]}}p), %rax # 8-byte Reload
; CHECK-NEXT:    tdpbssd %tmm1, %tmm0, %tmm2
; CHECK-NEXT:    tilestored %tmm2, (%rbx,%r15)
; CHECK-NEXT:    incl %ebp
; CHECK-NEXT:    cmpw $100, %bp
; CHECK-NEXT:    jl .LBB0_2
; CHECK-NEXT:  .LBB0_3: # %exit
; CHECK-NEXT:    addq $4056, %rsp # imm = 0xFD8
; CHECK-NEXT:    popq %rbx
; CHECK-NEXT:    popq %r14
; CHECK-NEXT:    popq %r15
; CHECK-NEXT:    popq %rbp
; CHECK-NEXT:    tilerelease
; CHECK-NEXT:    vzeroupper
; CHECK-NEXT:    retq
entry:
  %t1 = tail call x86_amx @llvm.x86.tileloadd64.internal(i16 8, i16 8, i8* %buf, i64 64)
  br i1 undef, label %loop.header, label %exit

loop.header:
  %ivphi = phi i16 [0, %entry], [%iv, %loop.latch]
  call void @foo()
  br label %loop.body

loop.body:
  %t2 = tail call x86_amx @llvm.x86.tileloadd64.internal(i16 8, i16 8, i8* %buf, i64 32)
  %t3 = tail call x86_amx @llvm.x86.tileloadd64.internal(i16 8, i16 8, i8* %buf, i64 32)
  %t4 = tail call x86_amx @llvm.x86.tdpbssd.internal(i16 8, i16 8, i16 8, x86_amx %t1, x86_amx %t2, x86_amx %t3)
  tail call void @llvm.x86.tilestored64.internal(i16 8, i16 8, i8* %buf, i64 32, x86_amx %t4)
  br label %loop.latch

loop.latch:
  %iv = add i16 %ivphi, 1
  %c = icmp slt i16 %iv, 100
  br i1 %c, label %loop.header, label %exit

exit:
  ret void
}

define dso_local void @test2(i8 *%buf) nounwind {
; CHECK-LABEL: test2:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    pushq %rbp
; CHECK-NEXT:    pushq %r15
; CHECK-NEXT:    pushq %r14
; CHECK-NEXT:    pushq %rbx
; CHECK-NEXT:    subq $4056, %rsp # imm = 0xFD8
; CHECK-NEXT:    vpxord %zmm0, %zmm0, %zmm0
; CHECK-NEXT:    vmovdqu64 %zmm0, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $1, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movb $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $8, {{[0-9]+}}(%rsp)
; CHECK-NEXT:    ldtilecfg {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movw $8, %r14w
; CHECK-NEXT:    tilezero %tmm3
; CHECK-NEXT:    xorl %eax, %eax
; CHECK-NEXT:    testb %al, %al
; CHECK-NEXT:    jne .LBB1_3
; CHECK-NEXT:  # %bb.1: # %loop.header.preheader
; CHECK-NEXT:    movq %rdi, %rbx
; CHECK-NEXT:    xorl %ebp, %ebp
; CHECK-NEXT:    movl $32, %r15d
; CHECK-NEXT:    .p2align 4, 0x90
; CHECK-NEXT:  .LBB1_2: # %loop.header
; CHECK-NEXT:    # =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    movabsq $64, %rax
; CHECK-NEXT:    tilestored %tmm3, 2048(%rsp,%rax) # 1024-byte Folded Spill
; CHECK-NEXT:    vzeroupper
; CHECK-NEXT:    callq foo
; CHECK-NEXT:    ldtilecfg {{[0-9]+}}(%rsp)
; CHECK-NEXT:    movabsq $64, %rax
; CHECK-NEXT:    tileloadd 2048(%rsp,%rax), %tmm3 # 1024-byte Folded Reload
; CHECK-NEXT:    tileloadd (%rbx,%r15), %tmm0
; CHECK-NEXT:    tileloadd (%rbx,%r15), %tmm1
; CHECK-NEXT:    # implicit-def: $rax
; CHECK-NEXT:    movq %rax, {{[-0-9]+}}(%r{{[sb]}}p) # 8-byte Spill
; CHECK-NEXT:    movabsq $64, %rax
; CHECK-NEXT:    tilestored %tmm3, 1024(%rsp,%rax) # 1024-byte Folded Spill
; CHECK-NEXT:    tileloadd {{[-0-9]+}}(%r{{[sb]}}p), %tmm2 # 1024-byte Folded Reload
; CHECK-NEXT:    movq {{[-0-9]+}}(%r{{[sb]}}p), %rax # 8-byte Reload
; CHECK-NEXT:    tdpbssd %tmm1, %tmm0, %tmm2
; CHECK-NEXT:    tilestored %tmm2, (%rbx,%r15)
; CHECK-NEXT:    incl %ebp
; CHECK-NEXT:    cmpw $100, %bp
; CHECK-NEXT:    jl .LBB1_2
; CHECK-NEXT:  .LBB1_3: # %exit
; CHECK-NEXT:    addq $4056, %rsp # imm = 0xFD8
; CHECK-NEXT:    popq %rbx
; CHECK-NEXT:    popq %r14
; CHECK-NEXT:    popq %r15
; CHECK-NEXT:    popq %rbp
; CHECK-NEXT:    tilerelease
; CHECK-NEXT:    vzeroupper
; CHECK-NEXT:    retq
entry:
  %t1 = tail call x86_amx @llvm.x86.tilezero.internal(i16 8, i16 8)
  br i1 undef, label %loop.header, label %exit

loop.header:
  %ivphi = phi i16 [0, %entry], [%iv, %loop.latch]
  call void @foo()
  br label %loop.body

loop.body:
  %t2 = tail call x86_amx @llvm.x86.tileloadd64.internal(i16 8, i16 8, i8* %buf, i64 32)
  %t3 = tail call x86_amx @llvm.x86.tileloadd64.internal(i16 8, i16 8, i8* %buf, i64 32)
  %t4 = tail call x86_amx @llvm.x86.tdpbssd.internal(i16 8, i16 8, i16 8, x86_amx %t1, x86_amx %t2, x86_amx %t3)
  tail call void @llvm.x86.tilestored64.internal(i16 8, i16 8, i8* %buf, i64 32, x86_amx %t4)
  br label %loop.latch

loop.latch:
  %iv = add i16 %ivphi, 1
  %c = icmp slt i16 %iv, 100
  br i1 %c, label %loop.header, label %exit

exit:
  ret void
}

declare dso_local void @foo()
declare x86_amx @llvm.x86.tilezero.internal(i16, i16)
declare x86_amx @llvm.x86.tileloadd64.internal(i16, i16, i8*, i64)
declare x86_amx @llvm.x86.tdpbssd.internal(i16, i16, i16, x86_amx, x86_amx, x86_amx)
declare void @llvm.x86.tilestored64.internal(i16, i16, i8*, i64, x86_amx)
