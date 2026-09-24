/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Intel x86-64 point-light specular SIMD kernels.
 *
 * PointLightingParams layout (13 x float):
 *   +00 invDx       +04 invDy       +08 k
 *   +12 lightX     +16 lightY     +20 lightZ
 *   +24 lr         +28 lg         +32 lb
 *   +36 ss         +40 ux0        +44 uy
 *   +48 dux
 *
 * srcT/srcM/srcB point at the x-1 pixel of the processed chunk.
 * ux0 is the user-space X coordinate of the first output pixel; uy is
 * the row Y coordinate and dux is the user-space X increment per pixel.
 */

#include "asm_macros.S"
#include "math_pow_macros.S"
#include "lighting_x86_64_avx2_macros.S"

/*
 * Description:
 *   Scalar L2S gather + max-channel-alpha byte pack, matching the
 *   point-specular scalar path (LUT != NULL) bit-for-bit. Gathers three bytes
 *   from \lut: lane 1 of \xmm, lane 0 of \xmm, and the scalar index \scl,
 *   then computes alpha = max(R, G, B) with unsigned cmovs (cmoval/cmovbel)
 *   and packs: (max << 24) | (R << 16) | (G << 8) | B.
 *
 * Inputs:
 *   \lut        = base of the L2S table (e.g. %r14)
 *   \xmm        = XMM register holding per-lane packed indices (lanes 0/1)
 *   \lane1q, \lane1d = 64-bit index view / 32-bit value view of the lane-1 reg
 *   \lane0q, \lane0d = same pair for the lane-0 reg (holds the packed result)
 *   \sclq, \scld     = same pair for the scalar-index reg
 *   \tmp        = scratch 32-bit GPR (alpha)
 *
 * Output:
 *   \lane0d     = packed 0xAARRGGBB pixel
 *
 * Clobbers:
 *   \lane1d, \lane0d, \scld, \tmp
 *   Upper 32 bits of the 64-bit registers are untouched.
 */
.macro L2S_GATHER_CMOV_PACK lut, xmm, lane1q, lane1d, lane0q, lane0d, sclq, scld, tmp
    vpextrd      $1, \xmm, \lane1d
    movzbl       (\lut,\lane1q), \lane1d
    vmovd        \xmm, \lane0d
    movzbl       (\lut,\lane0q), \lane0d
    movzbl       (\lut,\sclq), \scld
    cmpl         \lane0d, \lane1d
    movl         \lane0d, \tmp
    cmoval       \lane1d, \tmp
    cmpl         \scld, \tmp
    cmovbel      \scld, \tmp
    shll         $24, \tmp
    shll         $16, \lane1d
    shll         $8, \lane0d
    orl          \lane1d, \lane0d
    orl          \tmp, \lane0d
    orl          \scld, \lane0d
.endm

.globl SYM(ksvgLightingPointSpecularRowAvx2)
.p2align 4, 0x90
SYM(ksvgLightingPointSpecularRowAvx2):
.cfi_startproc
    testl        %r8d, %r8d
    jle          LBB0_4
    pushq        %rbp
.cfi_def_cfa_offset 16
.cfi_offset %rbp, -16
    movq         %rsp, %rbp
.cfi_def_cfa_register %rbp
    pushq        %r15
    pushq        %r14
    pushq        %r13
    pushq        %r12
    pushq        %rbx
    subq         $72, %rsp
.cfi_offset %rbx, -56
.cfi_offset %r12, -48
.cfi_offset %r13, -40
.cfi_offset %r14, -32
.cfi_offset %r15, -24
    movq         %rcx, %r15
    movq         %rdx, %r12
    movq         %rsi, %r13
    movq         %rdi, %r14
    xorl         %ebx, %ebx
    vmovss       %xmm0, -48(%rbp)
    movq         %r9, -56(%rbp)
    movl         %r8d, -44(%rbp)
.p2align 4, 0x90
LBB0_2:
    vmovups      (%r9), %ymm3
    vmovups      20(%r9), %ymm1
    vcvtsi2ss    %ebx, %xmm4, %xmm2
    vmovups      %ymm1, -92(%rbp)
    vmovups      %ymm3, -112(%rbp)
    vmulss       48(%r9), %xmm2, %xmm1
    vaddss       40(%r9), %xmm1, %xmm1
    vmovss       %xmm1, -72(%rbp)
    movq         %r14, %rdi
    movq         %r13, %rsi
    movq         %r12, %rdx
    movq         %r15, %rcx
    leaq         -112(%rbp), %r8
    xorl         %r9d, %r9d
    vzeroupper
    // Both wrappers share core8 below (non-linear and linear differ only in
    // the final L2S conversion inside core8's scalar packs).
    callq        SYM(core8)
    movl         -44(%rbp), %r8d
    movq         -56(%rbp), %r9
    vmovss       -48(%rbp), %xmm0
// xmm0 = mem[0],zero,zero,zero
    addq         $32, %r15
    addq         $32, %r12
    addq         $32, %r13
    addq         $32, %r14
    addl         $8, %ebx
    cmpl         %r8d, %ebx
    jl           LBB0_2
    addq         $72, %rsp
    popq         %rbx
    popq         %r12
    popq         %r13
    popq         %r14
    popq         %r15
    popq         %rbp
LBB0_4:
    retq
.cfi_endproc
POINT_LIT4
.p2align 2, 0x0
LCPI1_0:
.long	0x3f800000  // float 1
LCPI1_2:
.long	255  // 0xff
LCPI1_5:
.long	0x00000000  // float 0
POINT_CONST
.p2align 5, 0x0
LCPI1_1:
.long	0x00000000  // float 0
.long	0x3f800000  // float 1
.long	0x40000000  // float 2
.long	0x40400000  // float 3
.long	0x40800000  // float 4
.long	0x40a00000  // float 5
.long	0x40c00000  // float 6
.long	0x40e00000  // float 7
LCPI1_6:
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
LCPI1_3:
.long	8  // 0x8
.long	16  // 0x10
.long	8  // 0x8
.long	16  // 0x10
.long	8  // 0x8
.long	16  // 0x10
.long	8  // 0x8
.long	16  // 0x10
LCPI1_4:
.long	16  // 0x10
.long	8  // 0x8
.long	16  // 0x10
.long	8  // 0x8
.long	16  // 0x10
.long	8  // 0x8
.long	16  // 0x10
.long	8  // 0x8
EMIT_LOG2_POLY_8
EMIT_EXP2_POLY_8
EMIT_POW_COMMON_CONSTANTS
POINT_TEXT
.p2align 4, 0x90
SYM(core8):
    // Shared 8-pixel kernel: Sobel window, normalize, per-lane powf for the
    // specular exponent, then scalar L2S packs (or the vector-pack path).
.cfi_startproc
    pushq        %rbp
.cfi_def_cfa_offset 16
.cfi_offset %rbp, -16
    movq         %rsp, %rbp
.cfi_def_cfa_register %rbp
    pushq        %r15
    pushq        %r14
    pushq        %rbx
    andq         $-32, %rsp
    subq         $288, %rsp  // imm = 0x120
.cfi_offset %rbx, -40
.cfi_offset %r14, -32
.cfi_offset %r15, -24
    movq         %r8, %r15
    vbroadcastss 36(%r8), %ymm1
    vbroadcastss (%r8), %ymm4
    vbroadcastss 4(%r8), %ymm2
    vmovdqu      (%rdi), %ymm3
    vmovdqu      4(%rdi), %ymm5
    vmovdqu      8(%rdi), %ymm6
    ALPHA_FSCALE %ymm3, %ymm3, %ymm1, %ymm3
    ALPHA_FSCALE %ymm5, %ymm5, %ymm1, %ymm5
    ALPHA_FSCALE %ymm6, %ymm6, %ymm1, %ymm6
    vmovdqu      (%rsi), %ymm7
    vmovdqu      8(%rsi), %ymm8
    ALPHA_FSCALE %ymm7, %ymm7, %ymm1, %ymm7
    ALPHA_FSCALE %ymm8, %ymm8, %ymm1, %ymm8
    vmovdqu      (%rdx), %ymm9
    vmovdqu      4(%rdx), %ymm10
    vmovdqu      8(%rdx), %ymm11
    ALPHA_FSCALE %ymm9, %ymm9, %ymm1, %ymm9
    vpsrld       $24, %ymm10, %ymm10
    vpsrld       $24, %ymm11, %ymm11
    vcvtdq2ps    %ymm11, %ymm11
    vmulps       %ymm1, %ymm11, %ymm11
    vaddps       %ymm6, %ymm8, %ymm12
    vaddps       %ymm11, %ymm8, %ymm8
    vaddps       %ymm8, %ymm12, %ymm8
    vaddps       %ymm7, %ymm9, %ymm12
    vaddps       %ymm7, %ymm12, %ymm7
    vaddps       %ymm7, %ymm3, %ymm7
    vsubps       %ymm7, %ymm8, %ymm7
    vdivps       %ymm4, %ymm7, %ymm4
    vcvtdq2ps    %ymm10, %ymm7
    vmulps       %ymm7, %ymm1, %ymm7
    vaddps       %ymm7, %ymm9, %ymm8
    vaddps       %ymm7, %ymm11, %ymm7
    vaddps       %ymm7, %ymm8, %ymm7
    vaddps       %ymm6, %ymm5, %ymm6
    vaddps       %ymm6, %ymm5, %ymm5
    vaddps       %ymm5, %ymm3, %ymm3
    vsubps       %ymm3, %ymm7, %ymm3
    vdivps       %ymm2, %ymm3, %ymm3
    vxorps       %xmm2, %xmm2, %xmm2
    vsubps       %ymm4, %ymm2, %ymm4
    vsubps       %ymm3, %ymm2, %ymm3
    vmulps       %ymm4, %ymm4, %ymm5
    vmulps       %ymm3, %ymm3, %ymm6
    vaddps       %ymm6, %ymm5, %ymm6
    vbroadcastss LCPI1_0(%rip), %ymm5  // ymm5 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    vaddps       %ymm5, %ymm6, %ymm6
    vsqrtps      %ymm6, %ymm7
    vdivps       %ymm7, %ymm4, %ymm6
    vdivps       %ymm7, %ymm3, %ymm4
    movq         %r9, %r14
    vdivps       %ymm7, %ymm5, %ymm3
    vmovss       %xmm0, 16(%rsp)
    movq         %rcx, %rbx
    vbroadcastss 40(%r8), %ymm0
    vbroadcastss 48(%r8), %ymm7
    vmulps       LCPI1_1(%rip), %ymm7, %ymm7
    vmovdqu      4(%rsi), %ymm8
    vaddps       %ymm7, %ymm0, %ymm0
    vbroadcastss 12(%r8), %ymm7
    vsubps       %ymm0, %ymm7, %ymm0
    vmovss       16(%r8), %xmm7  // xmm7 = mem[0],zero,zero,zero
    vsubss       44(%r8), %xmm7, %xmm7
    vbroadcastss %xmm7, %ymm9
    vbroadcastss 20(%r8), %ymm10
    ALPHA_FSCALE %ymm8, %ymm8, %ymm1, %ymm1
    vsubps       %ymm1, %ymm10, %ymm1
    vmulps       %ymm0, %ymm0, %ymm8
    vmulss       %xmm7, %xmm7, %xmm7
    vbroadcastss %xmm7, %ymm7
    vaddps       %ymm7, %ymm8, %ymm7
    vmulps       %ymm1, %ymm1, %ymm8
    vaddps       %ymm7, %ymm8, %ymm7
    vsqrtps      %ymm7, %ymm10
    vcmpneq_oqps %ymm2, %ymm10, %ymm7
    vdivps       %ymm10, %ymm0, %ymm0
    vandps       %ymm0, %ymm7, %ymm0
    vdivps       %ymm10, %ymm9, %ymm9
    vandps       %ymm9, %ymm7, %ymm9
    vdivps       %ymm10, %ymm1, %ymm1
    vandps       %ymm1, %ymm7, %ymm1
    vaddps       %ymm5, %ymm1, %ymm1
    vblendvps    %ymm7, %ymm1, %ymm5, %ymm1
    vmulps       %ymm0, %ymm0, %ymm7
    vmulps       %ymm9, %ymm9, %ymm8
    vaddps       %ymm7, %ymm8, %ymm7
    vmulps       %ymm1, %ymm1, %ymm8
    vaddps       %ymm7, %ymm8, %ymm7
    vsqrtps      %ymm7, %ymm7
    vcmpneq_oqps %ymm2, %ymm7, %ymm8
    vdivps       %ymm7, %ymm0, %ymm0
    vandps       %ymm0, %ymm8, %ymm0
    vmulps       %ymm0, %ymm6, %ymm0
    vdivps       %ymm7, %ymm9, %ymm6
    vandps       %ymm6, %ymm8, %ymm6
    vmulps       %ymm6, %ymm4, %ymm4
    vaddps       %ymm4, %ymm0, %ymm0
    vdivps       %ymm7, %ymm1, %ymm1
    vandps       %ymm1, %ymm8, %ymm1
    vmulps       %ymm1, %ymm3, %ymm1
    vaddps       %ymm0, %ymm1, %ymm0
    vmaxps       %ymm2, %ymm0, %ymm0
    // Full-vector specular: POW8 over all 8 lanes (no per-lane calls).
    // %ymm9 stays live (light dir); scratch is %ymm8 (dead: Sobel temp).
    // %ymm10-%ymm15 dead (len spilled/unused); GPRs untouched. Intensity
    // matches the old per-lane clamp01 bit-for-bit (min/max exact, NaN
    // inputs impossible: zero-guarded normalize upstream, max-clamped base).
    vbroadcastss 16(%rsp), %ymm1  // exponent
    POW8_AVX2 %ymm0, %ymm1, %ymm8  // p vec = pow(ndoth, exp)
    vbroadcastss 8(%r15), %ymm1  // k
    vmulps       %ymm1, %ymm0, %ymm2  // k * p
    vxorps       %ymm3, %ymm3, %ymm3
    vmaxps       %ymm3, %ymm2, %ymm2  // max(0, .)
    vbroadcastss LCPI1_0(%rip), %ymm3  // 1.0f
    vminps       %ymm3, %ymm2, %ymm2  // intensity_vec = clamp01(k*p)
    vmovaps      %ymm2, 128(%rsp)  // park for linear lane extracts
    vmovsd       24(%r15), %xmm3  // xmm3 = mem[0],zero
    vshufps      $225, %xmm3, %xmm3, %xmm0  // xmm0 = xmm3[1,0,2,3]
    vbroadcastsd %xmm0, %ymm1
    vmovss       32(%r15), %xmm0  // xmm0 = mem[0],zero,zero,zero
    // With an L2S table, scalar gather packs (below); otherwise take the
    // vector-pack fast path (.LBB1_17).
  testq        %r14, %r14
  je           LBB1_17
    // Linear path: extract lanes for the scalar packs (only lane 0 of
    // each dest is read downstream: vmulss/vbroadcastss/vcvttss2si).
    vmovss       128(%rsp), %xmm6  // lane0
    vmovss       132(%rsp), %xmm11  // lane1
    vmovss       136(%rsp), %xmm10  // lane2
    vmovss       140(%rsp), %xmm9  // lane3
    vmovss       144(%rsp), %xmm8  // lane4
    vmovss       148(%rsp), %xmm7  // lane5
    vmovss       152(%rsp), %xmm5  // lane6
    vmovss       156(%rsp), %xmm2  // lane7
    vmulss       %xmm6, %xmm0, %xmm3
    vaddss       LCPI1_6(%rip), %xmm3, %xmm3  // +0.5 round-half-up
    vroundss     $11, %xmm3, %xmm3, %xmm3
    vcvttss2si   %xmm3, %edx
    cmpl         $255, %edx
    movl         $255, %eax
    cmovgel      %eax, %edx
    xorl         %ecx, %ecx
    testl        %edx, %edx
    cmovlel      %ecx, %edx
    vbroadcastss %xmm6, %xmm3
    vmulps       %xmm3, %xmm1, %xmm3
    vaddps       LCPI1_6(%rip), %xmm3, %xmm3  // +0.5 round-half-up
    vroundps     $11, %xmm3, %xmm3
    vcvttps2dq   %xmm3, %xmm4
    vpbroadcastd LCPI1_2(%rip), %xmm3  // xmm3 = [255,255,255,255]
    vpminsd      %xmm3, %xmm4, %xmm6
    vpxor        %xmm4, %xmm4, %xmm4
    vpmaxsd      %xmm4, %xmm6, %xmm6
    L2S_GATHER_CMOV_PACK %r14, %xmm6, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
    vmulss       %xmm0, %xmm11, %xmm6
    vaddss       LCPI1_6(%rip), %xmm6, %xmm6  // +0.5 round-half-up
    vroundss     $11, %xmm6, %xmm6, %xmm6
    vcvttss2si   %xmm6, %edx
    movl         %edi, (%rbx)
    cmpl         $255, %edx
    cmovgel      %eax, %edx
    testl        %edx, %edx
    cmovlel      %ecx, %edx
    vbroadcastss %xmm11, %xmm6
    vmulps       %xmm6, %xmm1, %xmm6
    vaddps       LCPI1_6(%rip), %xmm6, %xmm6  // +0.5 round-half-up
    vroundps     $11, %xmm6, %xmm6
    vcvttps2dq   %xmm6, %xmm6
    vpminsd      %xmm3, %xmm6, %xmm6
    vpmaxsd      %xmm4, %xmm6, %xmm6
    L2S_GATHER_CMOV_PACK %r14, %xmm6, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
    vmulss       %xmm0, %xmm10, %xmm6
    vaddss       LCPI1_6(%rip), %xmm6, %xmm6  // +0.5 round-half-up
    vroundss     $11, %xmm6, %xmm6, %xmm6
    vcvttss2si   %xmm6, %edx
    movl         %edi, 4(%rbx)
    cmpl         $255, %edx
    cmovgel      %eax, %edx
    testl        %edx, %edx
    cmovlel      %ecx, %edx
    vbroadcastss %xmm10, %xmm6
    vmulps       %xmm6, %xmm1, %xmm6
    vaddps       LCPI1_6(%rip), %xmm6, %xmm6  // +0.5 round-half-up
    vroundps     $11, %xmm6, %xmm6
    vcvttps2dq   %xmm6, %xmm6
    vpminsd      %xmm3, %xmm6, %xmm6
    vpmaxsd      %xmm4, %xmm6, %xmm6
    L2S_GATHER_CMOV_PACK %r14, %xmm6, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
    vmulss       %xmm0, %xmm9, %xmm6
    vaddss       LCPI1_6(%rip), %xmm6, %xmm6  // +0.5 round-half-up
    vroundss     $11, %xmm6, %xmm6, %xmm6
    vcvttss2si   %xmm6, %edx
    movl         %edi, 8(%rbx)
    cmpl         $255, %edx
    cmovgel      %eax, %edx
    testl        %edx, %edx
    cmovlel      %ecx, %edx
    vbroadcastss %xmm9, %xmm6
    vmulps       %xmm6, %xmm1, %xmm6
    vaddps       LCPI1_6(%rip), %xmm6, %xmm6  // +0.5 round-half-up
    vroundps     $11, %xmm6, %xmm6
    vcvttps2dq   %xmm6, %xmm6
    vpminsd      %xmm3, %xmm6, %xmm6
    vpmaxsd      %xmm4, %xmm6, %xmm6
    L2S_GATHER_CMOV_PACK %r14, %xmm6, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
    vmulss       %xmm0, %xmm8, %xmm6
    vaddss       LCPI1_6(%rip), %xmm6, %xmm6  // +0.5 round-half-up
    vroundss     $11, %xmm6, %xmm6, %xmm6
    vcvttss2si   %xmm6, %edx
    movl         %edi, 12(%rbx)
    cmpl         $255, %edx
    cmovgel      %eax, %edx
    testl        %edx, %edx
    cmovlel      %ecx, %edx
    vbroadcastss %xmm8, %xmm6
    vmulps       %xmm6, %xmm1, %xmm6
    vaddps       LCPI1_6(%rip), %xmm6, %xmm6  // +0.5 round-half-up
    vroundps     $11, %xmm6, %xmm6
    vcvttps2dq   %xmm6, %xmm6
    vpminsd      %xmm3, %xmm6, %xmm6
    vpmaxsd      %xmm4, %xmm6, %xmm6
    L2S_GATHER_CMOV_PACK %r14, %xmm6, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
    vmulss       %xmm7, %xmm0, %xmm6
    vaddss       LCPI1_6(%rip), %xmm6, %xmm6  // +0.5 round-half-up
    vroundss     $11, %xmm6, %xmm6, %xmm6
    vcvttss2si   %xmm6, %edx
    movl         %edi, 16(%rbx)
    cmpl         $255, %edx
    cmovgel      %eax, %edx
    testl        %edx, %edx
    cmovlel      %ecx, %edx
    vbroadcastss %xmm7, %xmm6
    vmulps       %xmm6, %xmm1, %xmm6
    vaddps       LCPI1_6(%rip), %xmm6, %xmm6  // +0.5 round-half-up
    vroundps     $11, %xmm6, %xmm6
    vcvttps2dq   %xmm6, %xmm6
    vpminsd      %xmm3, %xmm6, %xmm6
    vpmaxsd      %xmm4, %xmm6, %xmm6
    L2S_GATHER_CMOV_PACK %r14, %xmm6, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
    vmulss       %xmm5, %xmm0, %xmm6
    vaddss       LCPI1_6(%rip), %xmm6, %xmm6  // +0.5 round-half-up
    vroundss     $11, %xmm6, %xmm6, %xmm6
    vcvttss2si   %xmm6, %edx
    movl         %edi, 20(%rbx)
    cmpl         $255, %edx
    cmovgel      %eax, %edx
    testl        %edx, %edx
    cmovlel      %ecx, %edx
    vbroadcastss %xmm5, %xmm5
    vmulps       %xmm5, %xmm1, %xmm5
    vaddps       LCPI1_6(%rip), %xmm5, %xmm5  // +0.5 round-half-up
    vroundps     $11, %xmm5, %xmm5
    vcvttps2dq   %xmm5, %xmm5
    vpminsd      %xmm3, %xmm5, %xmm5
    vpmaxsd      %xmm4, %xmm5, %xmm5
    L2S_GATHER_CMOV_PACK %r14, %xmm5, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
    vmulss       %xmm2, %xmm0, %xmm0
    vaddss       LCPI1_6(%rip), %xmm0, %xmm0  // +0.5 round-half-up
    vroundss     $11, %xmm0, %xmm0, %xmm0
    vcvttss2si   %xmm0, %edx
    movl         %edi, 24(%rbx)
    cmpl         $255, %edx
    cmovll       %edx, %eax
    testl        %eax, %eax
    cmovlel      %ecx, %eax
    vbroadcastss %xmm2, %xmm0
    vmulps       %xmm0, %xmm1, %xmm0
    vaddps       LCPI1_6(%rip), %xmm0, %xmm0  // +0.5 round-half-up
    vroundps     $11, %xmm0, %xmm0
    vcvttps2dq   %xmm0, %xmm0
    vpminsd      %xmm3, %xmm0, %xmm0
    vpmaxsd      %xmm4, %xmm0, %xmm0
    L2S_GATHER_CMOV_PACK %r14, %xmm0, %rcx, %ecx, %rdx, %edx, %rax, %eax, %esi
    movl         %edx, 28(%rbx)
    jmp          LBB1_18
LBB1_17:
    // Vector path: intensity_vec already in %ymm2 (see above); vector
    // scale/round/truncate/clamp (no LUT needed).
    vmulps       %ymm2, %ymm1, %ymm1
    vaddps       LCPI1_6(%rip), %ymm1, %ymm1  // +0.5 round-half-up
    vroundps     $11, %ymm1, %ymm1
    vcvttps2dq   %ymm1, %ymm1
    vpbroadcastd LCPI1_2(%rip), %ymm4  // ymm4 = [255,255,255,255,255,255,255,255]
    vpminsd      %ymm4, %ymm1, %ymm1
    vxorps       %xmm5, %xmm5, %xmm5
    vpmaxsd      %ymm5, %ymm1, %ymm1
    vbroadcastsd %xmm3, %ymm3
    vmulps       %ymm2, %ymm3, %ymm3
    vaddps       LCPI1_6(%rip), %ymm3, %ymm3  // +0.5 round-half-up
    vroundps     $11, %ymm3, %ymm3
    vcvttps2dq   %ymm3, %ymm3
    vpminsd      %ymm4, %ymm3, %ymm3
    vpmaxsd      %ymm5, %ymm3, %ymm3
    vbroadcastss %xmm0, %ymm0
    vmulps       %ymm2, %ymm0, %ymm0
    vaddps       LCPI1_6(%rip), %ymm0, %ymm0  // +0.5 round-half-up
    vroundps     $11, %ymm0, %ymm0
    vcvttps2dq   %ymm0, %ymm0
    vpminsd      %ymm4, %ymm0, %ymm0
    vpmaxsd      %ymm5, %ymm0, %ymm0
    vpblendd     $170, %ymm1, %ymm3, %ymm2  // ymm2 = ymm3[0],ymm1[1],ymm3[2],ymm1[3],ymm3[4],ymm1[5],ymm3[6],ymm1[7]
    vpblendd     $170, %ymm3, %ymm1, %ymm4  // ymm4 = ymm1[0],ymm3[1],ymm1[2],ymm3[3],ymm1[4],ymm3[5],ymm1[6],ymm3[7]
    vpmaxud      %ymm4, %ymm2, %ymm2
    vpmaxud      %ymm0, %ymm2, %ymm2
    vpslld       $24, %ymm2, %ymm2
    vpsllvd      LCPI1_3(%rip), %ymm1, %ymm1
    vpsllvd      LCPI1_4(%rip), %ymm3, %ymm3
    vpor         %ymm3, %ymm1, %ymm1
    vpor         %ymm0, %ymm2, %ymm0
    vpor         %ymm0, %ymm1, %ymm0
    vmovdqu      %ymm0, (%rbx)
LBB1_18:
    // Shared epilogue (frame restore + return).
    leaq         -24(%rbp), %rsp
    popq         %rbx
    popq         %r14
    popq         %r15
    popq         %rbp
    vzeroupper
    retq
.cfi_endproc
.globl SYM(ksvgLightingPointSpecularRowAvx2Linear)
.p2align 4, 0x90
SYM(ksvgLightingPointSpecularRowAvx2Linear):
.cfi_startproc
    testl        %r8d, %r8d
    jle          LBB2_4
    pushq        %rbp
.cfi_def_cfa_offset 16
.cfi_offset %rbp, -16
    movq         %rsp, %rbp
.cfi_def_cfa_register %rbp
    pushq        %r15
    pushq        %r14
    pushq        %r13
    pushq        %r12
    pushq        %rbx
    subq         $72, %rsp
.cfi_offset %rbx, -56
.cfi_offset %r12, -48
.cfi_offset %r13, -40
.cfi_offset %r14, -32
.cfi_offset %r15, -24
    movq         %rcx, %r15
    movq         %rdx, %r12
    movq         %rsi, %r13
    movq         %rdi, %r14
    xorl         %ebx, %ebx
    vmovss       %xmm0, -48(%rbp)
    movq         %r9, -56(%rbp)
    movl         %r8d, -44(%rbp)
.p2align 4, 0x90
LBB2_2:
    vmovups      (%r9), %ymm3
    vmovups      20(%r9), %ymm1
    vcvtsi2ss    %ebx, %xmm4, %xmm2
    vmovups      %ymm1, -92(%rbp)
    vmovups      %ymm3, -112(%rbp)
    vmulss       48(%r9), %xmm2, %xmm1
    vaddss       40(%r9), %xmm1, %xmm1
    vmovss       %xmm1, -72(%rbp)
    movq         %r14, %rdi
    movq         %r13, %rsi
    movq         %r12, %rdx
    movq         %r15, %rcx
    leaq         -112(%rbp), %r8
    movq         16(%rbp), %r9
    vzeroupper
    callq        SYM(core8)
    movl         -44(%rbp), %r8d
    movq         -56(%rbp), %r9
    vmovss       -48(%rbp), %xmm0
// xmm0 = mem[0],zero,zero,zero
    addq         $32, %r15
    addq         $32, %r12
    addq         $32, %r13
    addq         $32, %r14
    addl         $8, %ebx
    cmpl         %r8d, %ebx
    jl           LBB2_2
    addq         $72, %rsp
    popq         %rbx
    popq         %r12
    popq         %r13
    popq         %r14
    popq         %r15
    popq         %rbp
LBB2_4:
    retq
.cfi_endproc
GNU_STACK
