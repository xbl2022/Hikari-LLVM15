; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -passes=sroa -S | FileCheck %s
target datalayout = "e-p:64:64:64-p1:16:16:16-p3:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-n8:16:32:64"

declare void @llvm.memcpy.p0.p0.i32(ptr nocapture, ptr nocapture readonly, i32, i1)
declare void @llvm.memcpy.p1.p0.i32(ptr addrspace(1) nocapture, ptr nocapture readonly, i32, i1)
declare void @llvm.memcpy.p0.p1.i32(ptr nocapture, ptr addrspace(1) nocapture readonly, i32, i1)
declare void @llvm.memcpy.p1.p1.i32(ptr addrspace(1) nocapture, ptr addrspace(1) nocapture readonly, i32, i1)


; Make sure an illegal bitcast isn't introduced
define void @test_address_space_1_1(ptr addrspace(1) %a, ptr addrspace(1) %b) {
; CHECK-LABEL: @test_address_space_1_1(
; CHECK-NEXT:    [[AA_0_COPYLOAD:%.*]] = load <2 x i64>, ptr addrspace(1) [[A:%.*]], align 2
; CHECK-NEXT:    store <2 x i64> [[AA_0_COPYLOAD]], ptr addrspace(1) [[B:%.*]], align 2
; CHECK-NEXT:    ret void
;
  %aa = alloca <2 x i64>, align 16
  call void @llvm.memcpy.p0.p1.i32(ptr align 2 %aa, ptr addrspace(1) align 2 %a, i32 16, i1 false)
  call void @llvm.memcpy.p1.p0.i32(ptr addrspace(1) align 2 %b, ptr align 2 %aa, i32 16, i1 false)
  ret void
}

define void @test_address_space_1_0(ptr addrspace(1) %a, ptr %b) {
; CHECK-LABEL: @test_address_space_1_0(
; CHECK-NEXT:    [[AA_0_COPYLOAD:%.*]] = load <2 x i64>, ptr addrspace(1) [[A:%.*]], align 2
; CHECK-NEXT:    store <2 x i64> [[AA_0_COPYLOAD]], ptr [[B:%.*]], align 2
; CHECK-NEXT:    ret void
;
  %aa = alloca <2 x i64>, align 16
  call void @llvm.memcpy.p0.p1.i32(ptr align 2 %aa, ptr addrspace(1) align 2 %a, i32 16, i1 false)
  call void @llvm.memcpy.p0.p0.i32(ptr align 2 %b, ptr align 2 %aa, i32 16, i1 false)
  ret void
}

define void @test_address_space_0_1(ptr %a, ptr addrspace(1) %b) {
; CHECK-LABEL: @test_address_space_0_1(
; CHECK-NEXT:    [[AA_0_COPYLOAD:%.*]] = load <2 x i64>, ptr [[A:%.*]], align 2
; CHECK-NEXT:    store <2 x i64> [[AA_0_COPYLOAD]], ptr addrspace(1) [[B:%.*]], align 2
; CHECK-NEXT:    ret void
;
  %aa = alloca <2 x i64>, align 16
  call void @llvm.memcpy.p0.p0.i32(ptr align 2 %aa, ptr align 2 %a, i32 16, i1 false)
  call void @llvm.memcpy.p1.p0.i32(ptr addrspace(1) align 2 %b, ptr align 2 %aa, i32 16, i1 false)
  ret void
}

%struct.struct_test_27.0.13 = type { i32, float, i64, i8, [4 x i32] }

define void @copy_struct([5 x i64] %in.coerce, ptr addrspace(1) align 4 %ptr) {
; CHECK-LABEL: @copy_struct(
; CHECK-NEXT:  for.end:
; CHECK-NEXT:    [[IN_COERCE_FCA_0_EXTRACT:%.*]] = extractvalue [5 x i64] [[IN_COERCE:%.*]], 0
; CHECK-NEXT:    [[IN_COERCE_FCA_1_EXTRACT:%.*]] = extractvalue [5 x i64] [[IN_COERCE]], 1
; CHECK-NEXT:    [[IN_COERCE_FCA_2_EXTRACT:%.*]] = extractvalue [5 x i64] [[IN_COERCE]], 2
; CHECK-NEXT:    [[IN_COERCE_FCA_3_EXTRACT:%.*]] = extractvalue [5 x i64] [[IN_COERCE]], 3
; CHECK-NEXT:    [[IN_SROA_2_4_EXTRACT_SHIFT:%.*]] = lshr i64 [[IN_COERCE_FCA_2_EXTRACT]], 32
; CHECK-NEXT:    [[IN_SROA_2_4_EXTRACT_TRUNC:%.*]] = trunc i64 [[IN_SROA_2_4_EXTRACT_SHIFT]] to i32
; CHECK-NEXT:    store i32 [[IN_SROA_2_4_EXTRACT_TRUNC]], ptr addrspace(1) [[PTR:%.*]], align 4
; CHECK-NEXT:    [[IN_SROA_4_20_PTR_SROA_IDX:%.*]] = getelementptr inbounds i8, ptr addrspace(1) [[PTR]], i16 4
; CHECK-NEXT:    store i64 [[IN_COERCE_FCA_3_EXTRACT]], ptr addrspace(1) [[IN_SROA_4_20_PTR_SROA_IDX]], align 4
; CHECK-NEXT:    [[IN_SROA_5_20_PTR_SROA_IDX:%.*]] = getelementptr inbounds i8, ptr addrspace(1) [[PTR]], i16 12
; CHECK-NEXT:    store i32 undef, ptr addrspace(1) [[IN_SROA_5_20_PTR_SROA_IDX]], align 4
; CHECK-NEXT:    ret void
;
for.end:
  %in = alloca %struct.struct_test_27.0.13, align 8
  store [5 x i64] %in.coerce, ptr %in, align 8
  %scevgep9 = getelementptr %struct.struct_test_27.0.13, ptr %in, i32 0, i32 4, i32 0
  call void @llvm.memcpy.p1.p0.i32(ptr addrspace(1) align 4 %ptr, ptr align 4 %scevgep9, i32 16, i1 false)
  ret void
}

%union.anon = type { ptr }

@g = common global i32 0, align 4
@l = common addrspace(3) global i32 0, align 4

; If pointers from different address spaces have different sizes, make sure an
; illegal bitcast isn't introduced
define void @pr27557() {
; CHECK-LABEL: @pr27557(
; CHECK-NEXT:    [[DOTSROA_0:%.*]] = alloca ptr, align 8
; CHECK-NEXT:    store ptr @g, ptr [[DOTSROA_0]], align 8
; CHECK-NEXT:    store ptr addrspace(3) @l, ptr [[DOTSROA_0]], align 8
; CHECK-NEXT:    ret void
;
  %1 = alloca %union.anon, align 8
  store ptr @g, ptr %1, align 8
  store ptr addrspace(3) @l, ptr %1, align 8
  ret void
}

@l2 = common addrspace(2) global i32 0, align 4

; If pointers from different address spaces have the same size, that pointer
; should be promoted through the pair of `ptrtoint`/`inttoptr`.
define ptr @pr27557.alt() {
; CHECK-LABEL: @pr27557.alt(
; CHECK-NEXT:    ret ptr inttoptr (i64 ptrtoint (ptr addrspace(2) @l2 to i64) to ptr)
;
  %1 = alloca %union.anon, align 8
  store ptr addrspace(2) @l2, ptr %1, align 8
  %2 = load ptr, ptr %1, align 8
  ret ptr %2
}

; Make sure pre-splitting doesn't try to introduce an illegal bitcast
define float @presplit(ptr addrspace(1) %p) {
; CHECK-LABEL: @presplit(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[L1:%.*]] = load i32, ptr addrspace(1) [[P:%.*]], align 4
; CHECK-NEXT:    [[P_SROA_IDX:%.*]] = getelementptr inbounds i8, ptr addrspace(1) [[P]], i16 4
; CHECK-NEXT:    [[L2:%.*]] = load i32, ptr addrspace(1) [[P_SROA_IDX]], align 4
; CHECK-NEXT:    [[TMP0:%.*]] = bitcast i32 [[L1]] to float
; CHECK-NEXT:    [[TMP1:%.*]] = bitcast i32 [[L2]] to float
; CHECK-NEXT:    [[RET:%.*]] = fadd float [[TMP0]], [[TMP1]]
; CHECK-NEXT:    ret float [[RET]]
;
entry:
  %b = alloca i64
  %b.gep2 = getelementptr [2 x float], ptr %b, i32 0, i32 1
  %l = load i64, ptr addrspace(1) %p
  store i64 %l, ptr %b
  %f1 = load float, ptr %b
  %f2 = load float, ptr %b.gep2
  %ret = fadd float %f1, %f2
  ret float %ret
}

; Test load from and store to non-zero address space.
define void @test_load_store_diff_addr_space(ptr addrspace(1) %complex1, ptr addrspace(1) %complex2) {
; CHECK-LABEL: @test_load_store_diff_addr_space(
; CHECK-NEXT:    [[V13:%.*]] = load i32, ptr addrspace(1) [[COMPLEX1:%.*]], align 4
; CHECK-NEXT:    [[COMPLEX1_SROA_IDX:%.*]] = getelementptr inbounds i8, ptr addrspace(1) [[COMPLEX1]], i16 4
; CHECK-NEXT:    [[V14:%.*]] = load i32, ptr addrspace(1) [[COMPLEX1_SROA_IDX]], align 4
; CHECK-NEXT:    [[TMP1:%.*]] = bitcast i32 [[V13]] to float
; CHECK-NEXT:    [[TMP2:%.*]] = bitcast i32 [[V14]] to float
; CHECK-NEXT:    [[SUM:%.*]] = fadd float [[TMP1]], [[TMP2]]
; CHECK-NEXT:    [[TMP3:%.*]] = bitcast float [[SUM]] to i32
; CHECK-NEXT:    [[TMP4:%.*]] = bitcast float [[SUM]] to i32
; CHECK-NEXT:    store i32 [[TMP3]], ptr addrspace(1) [[COMPLEX2:%.*]], align 4
; CHECK-NEXT:    [[COMPLEX2_SROA_IDX:%.*]] = getelementptr inbounds i8, ptr addrspace(1) [[COMPLEX2]], i16 4
; CHECK-NEXT:    store i32 [[TMP4]], ptr addrspace(1) [[COMPLEX2_SROA_IDX]], align 4
; CHECK-NEXT:    ret void
;
  %a = alloca i64
  %a.gep2 = getelementptr [2 x float], ptr %a, i32 0, i32 1
  %v1 = load i64, ptr addrspace(1) %complex1
  store i64 %v1, ptr %a
  %f1 = load float, ptr %a
  %f2 = load float, ptr %a.gep2
  %sum = fadd float %f1, %f2
  store float %sum, ptr %a
  store float %sum, ptr %a.gep2
  %v2 = load i64, ptr %a
  store i64 %v2, ptr addrspace(1) %complex2
  ret void
}