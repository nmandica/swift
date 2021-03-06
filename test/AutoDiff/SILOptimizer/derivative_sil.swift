// RUN: %target-swift-frontend -emit-sil -verify -Xllvm -sil-print-after=differentiation -o /dev/null 2>&1 %s | %FileCheck %s -check-prefix=CHECK-SIL
// REQUIRES: asserts

// Simple generated derivative code FileCheck tests.

import _Differentiation

extension Float {
  @_silgen_name("add")
  static func add(_ x: Float, _ y: Float) -> Float {
    return x + y
  }

  @derivative(of: add)
  static func addVJP(_ x: Float, _ y: Float) -> (
    value: Float, pullback: (Float) -> (Float, Float)
  ) {
    return (add(x, y), { v in (v, v) })
  }
}

@_silgen_name("foo")
@differentiable
func foo(_ x: Float) -> Float {
  let y = Float.add(x, x)
  return y
}

// CHECK-SIL-LABEL: sil hidden [ossa] @AD__foo__vjp_src_0_wrt_0 : $@convention(thin) (Float) -> (Float, @owned @callee_guaranteed (Float) -> Float) {
// CHECK-SIL: bb0([[X:%.*]] : $Float):
// CHECK-SIL:   [[ADD_ORIG_REF:%.*]] = function_ref @add : $@convention(method) (Float, Float, @thin Float.Type) -> Float
// CHECK-SIL:   [[ADD_JVP_REF:%.*]] = differentiability_witness_function [jvp] [parameters 0 1] [results 0] @add
// CHECK-SIL:   [[ADD_VJP_REF:%.*]] = differentiability_witness_function [vjp] [parameters 0 1] [results 0] @add
// CHECK-SIL:   [[ADD_DIFF_FN:%.*]] = differentiable_function [parameters 0 1] [[ADD_ORIG_REF]] : $@convention(method) (Float, Float, @thin Float.Type) -> Float with_derivative {[[ADD_JVP_REF]] : $@convention(method) (Float, Float, @thin Float.Type) -> (Float, @owned @callee_guaranteed (Float, Float) -> Float), [[ADD_VJP_REF]] : $@convention(method) (Float, Float, @thin Float.Type) -> (Float, @owned @callee_guaranteed (Float) -> (Float, Float))}
// CHECK-SIL:   [[ADD_VJP_FN:%.*]] = differentiable_function_extract [vjp] [[ADD_DIFF_FN]]
// CHECK-SIL:   end_borrow [[ADD_DIFF_FN]]
// CHECK-SIL:   [[ADD_RESULT:%.*]] = apply [[ADD_VJP_FN]]([[X]], [[X]], {{.*}})
// CHECK-SIL:   ([[ORIG_RES:%.*]], [[ADD_PB:%.*]]) = destructure_tuple [[ADD_RESULT]]
// CHECK-SIL:   [[PB_STRUCT:%.*]] = struct $_AD__foo_bb0__PB__src_0_wrt_0 ([[ADD_PB]] : $@callee_guaranteed (Float) -> (Float, Float))
// CHECK-SIL:   [[PB_REF:%.*]] = function_ref @AD__foo__pullback_src_0_wrt_0 : $@convention(thin) (Float, @owned _AD__foo_bb0__PB__src_0_wrt_0) -> Float
// CHECK-SIL:   [[PB_FN:%.*]] = partial_apply [callee_guaranteed] [[PB_REF]]([[PB_STRUCT]])
// CHECK-SIL:   [[VJP_RESULT:%.*]] = tuple ([[ORIG_RES]] : $Float, [[PB_FN]] : $@callee_guaranteed (Float) -> Float)
// CHECK-SIL:   return [[VJP_RESULT]] : $(Float, @callee_guaranteed (Float) -> Float)
// CHECK-SIL: }

// CHECK-SIL-LABEL: sil private [ossa] @AD__foo__pullback_src_0_wrt_0 : $@convention(thin) (Float, @owned _AD__foo_bb0__PB__src_0_wrt_0) -> Float {
// CHECK-SIL: bb0([[SEED:%.*]] : $Float, [[PB_STRUCT:%.*]] : @owned $_AD__foo_bb0__PB__src_0_wrt_0):
// CHECK-SIL:   [[ADD_PB:%.*]] = destructure_struct [[PB_STRUCT]] : $_AD__foo_bb0__PB__src_0_wrt_0
// CHECK-SIL:   [[ADD_PB_RES:%.*]] = apply [[ADD_PB]]([[SEED]]) : $@callee_guaranteed (Float) -> (Float, Float)
// CHECK-SIL:   ([[DX_1:%.*]], [[DX_2:%.*]]) = destructure_tuple [[ADD_PB_RES]] : $(Float, Float)
// CHECK-SIL:   [[TMP_BUF_RES:%.*]] = alloc_stack $Float
// CHECK-SIL:   [[TMP_BUF_LHS:%.*]] = alloc_stack $Float
// CHECK-SIL:   [[TMP_BUF_RHS:%.*]] = alloc_stack $Float
// CHECK-SIL:   store [[DX_1]] to [trivial] [[TMP_BUF_LHS]] : $*Float
// CHECK-SIL:   store [[DX_2]] to [trivial] [[TMP_BUF_RHS]] : $*Float
// CHECK-SIL:   [[PLUS_FN:%.*]] = witness_method $Float, #AdditiveArithmetic."+"
// CHECK-SIL:   apply [[PLUS_FN]]<Float>([[TMP_BUF_RES]], [[TMP_BUF_RHS]], [[TMP_BUF_LHS]], {{.*}})
// CHECK-SIL:   destroy_addr [[TMP_BUF_LHS]] : $*Float
// CHECK-SIL:   destroy_addr [[TMP_BUF_RHS]] : $*Float
// CHECK-SIL:   dealloc_stack [[TMP_BUF_RHS]] : $*Float
// CHECK-SIL:   dealloc_stack [[TMP_BUF_LHS]] : $*Float
// CHECK-SIL:   [[DX:%.*]] = load [trivial] [[TMP_BUF_RES]] : $*Float
// CHECK-SIL:   dealloc_stack [[TMP_BUF_RES]] : $*Float
// CHECK-SIL:   return [[DX]] : $Float
// CHECK-SIL: }
