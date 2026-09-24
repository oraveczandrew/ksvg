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

#include "asm_macros.S"
#include "math_pow_macros.S"
#include "lighting_x86_64_avx2_macros.S"

/*
 * Description:
 *   Amortized linear->sRGB conversion for one byte 0..255: exact value for
 *   0..15 via table entry 0, otherwise base + slope interpolation followed by
 *   the per-bit correction set (correction_lo/correction_hi AND onehot).
 *   Matches the pre-existing file-local definition in
 *   lighting_distant_specular_x86_64_avx2.S.
 *
 * Inputs:
 *   \reg  = 32-bit general-purpose register holding the linear intensity (0..255)
 *   %r11  = base of a .Lspec_l2s_data-shaped LUT (loaded by the caller)
 *
 * Output:
 *   \reg  = sRGB byte value, stored through %r9d (top bits zeroed)
 *
 * Clobbers:
 *   \reg      (in-place)
 *   %r8d, %r9d, %r10d
 *
 * Uses \@-suffixed local labels; caller keeps its loop index / loop limit in
 * its own registers.
 */
.macro L2S1 reg
    movl         \reg, %r10d
    cmpl         $16, %r10d
    jb           .Lspec_l2s_exact_\@

    movl         %r10d, %r9d
    shrl         $4, %r9d
    movl         %r9d, %r8d
    movzbl       16(%r11,%r9,1), %r9d
    movzbl       32(%r11,%r8,1), %r8d
    andl         $15, %r10d
    imull        %r10d, %r8d
    addl         $16, %r8d
    shrl         $5, %r8d
    addl         %r8d, %r9d

    movl         \reg, %r10d
    shrl         $3, %r10d
    movl         %r10d, %r8d
    andl         $7, %r8d
    cmpl         $16, %r10d
    jb           .Lspec_l2s_corr_lo_\@
    subl         $16, %r10d
    movzbl       64(%r11,%r10,1), %r10d
    jmp          .Lspec_l2s_corr_mask_\@
.Lspec_l2s_corr_lo_\@:
    movzbl       48(%r11,%r10,1), %r10d
.Lspec_l2s_corr_mask_\@:
    movzbl       80(%r11,%r8,1), %r8d
    testb        %r8b, %r10b
    setne        %r8b
    movzbl       %r8b, %r8d
    subl         %r8d, %r9d
    movl         %r9d, \reg
    jmp          .Lspec_l2s_done_\@

.Lspec_l2s_exact_\@:
    movzbl       0(%r11,%r10,1), %r10d
    movl         %r10d, \reg
.Lspec_l2s_done_\@:
.endm

.text
.p2align 4
.globl SYM(ksvgLightingDistantSpecularRowAvx2)
TYPE(SYM(ksvgLightingDistantSpecularRowAvx2), @function)
SYM(ksvgLightingDistantSpecularRowAvx2):
    pushq        %rbp
    movq         %rsp, %rbp
    pushq        %r15
    pushq        %r14
    pushq        %r13
    pushq        %r12
    pushq        %rbx
    andq         $-64, %rsp
    subq         $320, %rsp  // imm = 0x140
    movq         %rdx, 48(%rsp)
    movq         %rsi, 40(%rsp)
    movq         %rdi, 32(%rsp)
    testl        %r8d, %r8d
    jle          .LBB1_20
    // Normalize the distant light direction once: l = (lx, ly, lz + 1) / |..|
    // (specular half-vector base; the +1 folds in the (0, 0, 1) view term).
    movq         %r9, %rbx
    movq         %rcx, %r15
    movq         %r8, %rax
    vbroadcastss (%r9), %ymm1
    vmovaps      %ymm1, 224(%rsp)
    vbroadcastss 12(%r9), %ymm1
    vbroadcastss 16(%r9), %ymm2
    vmovss       20(%r9), %xmm3  // xmm3 = mem[0],zero,zero,zero
    vaddss       .LCPI1_0(%rip), %xmm3, %xmm3
    vmulss       %xmm2, %xmm2, %xmm4
    vmulss       %xmm1, %xmm1, %xmm5
    vaddss       %xmm4, %xmm5, %xmm4
    vmulss       %xmm3, %xmm3, %xmm5
    vaddss       %xmm4, %xmm5, %xmm4
    vbroadcastss %xmm4, %ymm4
    vsqrtps      %ymm4, %ymm4
    vdivps       %ymm4, %ymm1, %ymm1
    vmovaps      %ymm1, 192(%rsp)
    vdivps       %ymm4, %ymm2, %ymm1
    vmovaps      %ymm1, 160(%rsp)
    vbroadcastss %xmm3, %ymm1
    vdivps       %ymm4, %ymm1, %ymm1
    vmovaps      %ymm1, 128(%rsp)
    vbroadcastss 4(%r9), %ymm1
    vmovaps      %ymm1, 96(%rsp)
    vextractps     $0, %xmm0, 56(%rsp)
    decl         %eax
    shrl         $3, %eax
    incl         %eax
    movq         %rax, 24(%rsp)
    xorl         %r13d, %r13d
    xorl         %r12d, %r12d
    jmp          .LBB1_2
.LBB1_19:
    addq         $8, %r13
    incq         %r12
    addq         $32, %r15
    cmpq         24(%rsp), %r12
    je           .LBB1_20
.LBB1_2:
    // Sobel window: load row alphas, scale to heights (h = (alpha >> 24) * ss).
    vbroadcastss 36(%rbx), %ymm0
    movq         32(%rsp), %rax
    vmovdqu      (%rax,%r13,4), %ymm1
    vmovdqu      4(%rax,%r13,4), %ymm2
    vmovdqu      8(%rax,%r13,4), %ymm3
    ALPHA_FSCALE %ymm1, %ymm1, %ymm0, %ymm1
    ALPHA_FSCALE %ymm2, %ymm2, %ymm0, %ymm2
    ALPHA_FSCALE %ymm3, %ymm3, %ymm0, %ymm3
    movq         40(%rsp), %rax
    vmovdqu      (%rax,%r13,4), %ymm4
    vmovdqu      8(%rax,%r13,4), %ymm5
    ALPHA_FSCALE %ymm4, %ymm4, %ymm0, %ymm4
    ALPHA_FSCALE %ymm5, %ymm5, %ymm0, %ymm5
    movq         48(%rsp), %rax
    vmovdqu      (%rax,%r13,4), %ymm6
    vmovdqu      4(%rax,%r13,4), %ymm7
    vmovdqu      8(%rax,%r13,4), %ymm8
    ALPHA_FSCALE %ymm6, %ymm6, %ymm0, %ymm6
    vpsrld       $24, %ymm7, %ymm7
    vcvtdq2ps    %ymm7, %ymm7
    vpsrld       $24, %ymm8, %ymm8
    vcvtdq2ps    %ymm8, %ymm8
    vmulps       %ymm0, %ymm8, %ymm8
    // 1:2:1 row sums + x/y derivatives, scaled by 1/invDx and 1/invDy.
    vaddps       %ymm5, %ymm5, %ymm5
    vaddps       %ymm3, %ymm5, %ymm5
    vaddps       %ymm5, %ymm8, %ymm5
    vaddps       %ymm4, %ymm4, %ymm4
    vaddps       %ymm1, %ymm4, %ymm4
    vaddps       %ymm6, %ymm4, %ymm4
    vsubps       %ymm4, %ymm5, %ymm4
    vdivps       224(%rsp), %ymm4, %ymm4
    vmulps       %ymm7, %ymm0, %ymm0
    vaddps       %ymm0, %ymm0, %ymm0
    vaddps       %ymm6, %ymm0, %ymm0
    vaddps       %ymm0, %ymm8, %ymm0
    vaddps       %ymm2, %ymm2, %ymm2
    vaddps       %ymm1, %ymm2, %ymm1
    vaddps       %ymm3, %ymm1, %ymm1
    vsubps       %ymm1, %ymm0, %ymm0
    vdivps       96(%rsp), %ymm0, %ymm0
    // Surface normal n = (-dx, -dy, 1) / |..|, dotted with the scaled light
    // dirs and clamped: dot = max(0, n.l).
    vxorps       %xmm5, %xmm5, %xmm5
    vsubps       %ymm4, %ymm5, %ymm1
    vsubps       %ymm0, %ymm5, %ymm0
    vmulps       %ymm0, %ymm0, %ymm2
    vmulps       %ymm1, %ymm1, %ymm3
    vaddps       %ymm2, %ymm3, %ymm2
    vbroadcastss .LCPI1_0(%rip), %ymm3  // ymm3 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    vaddps       %ymm3, %ymm2, %ymm2
    vsqrtps      %ymm2, %ymm2
    vdivps       %ymm2, %ymm1, %ymm1
    vdivps       %ymm2, %ymm0, %ymm0
    vmulps       192(%rsp), %ymm1, %ymm1
    vmulps       160(%rsp), %ymm0, %ymm0
    vaddps       %ymm0, %ymm1, %ymm0
    vdivps       %ymm2, %ymm3, %ymm1
    vmulps       128(%rsp), %ymm1, %ymm1
    vaddps       %ymm0, %ymm1, %ymm0
    vmaxps       %ymm5, %ymm0, %ymm0

    // Full SIMD Specular Path (Fast Approximation)
    vbroadcastss 56(%rsp), %ymm1  // exponent
    POW8_AVX2 %ymm0, %ymm1, %ymm9

    // intensity = k * p clamped to [0, 1]
    vbroadcastss 8(%rbx), %ymm1  // k
    vmulps    %ymm1, %ymm0, %ymm0
    vxorps    %ymm1, %ymm1, %ymm1
    vmaxps    %ymm1, %ymm0, %ymm0
    vbroadcastss .LCPI1_0(%rip), %ymm1  // 1.0f
    vminps    %ymm1, %ymm0, %ymm0

    // R/G/B = intensity * lr/lg/lb
    vbroadcastss 24(%rbx), %ymm1  // lr
    vmulps    %ymm0, %ymm1, %ymm1
    vbroadcastss 28(%rbx), %ymm2  // lg
    vmulps    %ymm0, %ymm2, %ymm2
    vbroadcastss 32(%rbx), %ymm3  // lb
    vmulps    %ymm0, %ymm3, %ymm3

    // Round-half-up and clamp to [0, 255]
    vbroadcastss .Lhalf(%rip), %ymm4
    vaddps    %ymm4, %ymm1, %ymm1
    vaddps    %ymm4, %ymm2, %ymm2
    vaddps    %ymm4, %ymm3, %ymm3

    vcvttps2dq %ymm1, %ymm1
    vcvttps2dq %ymm2, %ymm2
    vcvttps2dq %ymm3, %ymm3

    vpxor     %xmm4, %xmm4, %xmm4
    vpmaxsd   %ymm4, %ymm1, %ymm1
    vpmaxsd   %ymm4, %ymm2, %ymm2
    vpmaxsd   %ymm4, %ymm3, %ymm3
    vmovdqa   .L255_epi32(%rip), %ymm4
    vpminsd   %ymm4, %ymm1, %ymm1
    vpminsd   %ymm4, %ymm2, %ymm2
    vpminsd   %ymm4, %ymm3, %ymm3

    // Alpha = max(R, G, B)
    vpmaxsd   %ymm1, %ymm2, %ymm4
    vpmaxsd   %ymm4, %ymm3, %ymm4

    // Pack: (A << 24) | (R << 16) | (G << 8) | B
    vpslld    $24, %ymm4, %ymm4
    vpslld    $16, %ymm1, %ymm1
    vpslld    $8, %ymm2, %ymm2
    vpor      %ymm4, %ymm1, %ymm1
    vpor      %ymm2, %ymm3, %ymm2
    vpor      %ymm1, %ymm2, %ymm1

    vmovdqu   %ymm1, (%r15)
    jmp          .LBB1_19
.LBB1_20:
    leaq         -40(%rbp), %rsp
    popq         %rbx
    popq         %r12
    popq         %r13
    popq         %r14
    popq         %r15
    popq         %rbp
    retq
.Lfunc_end1:

.text
.p2align 4
.globl SYM(ksvgLightingDistantSpecularRowAvx2Linear)
TYPE(SYM(ksvgLightingDistantSpecularRowAvx2Linear), @function)
SYM(ksvgLightingDistantSpecularRowAvx2Linear):
    pushq        %rbp
    movq         %rsp, %rbp
    pushq        %r15
    pushq        %r14
    pushq        %r13
    pushq        %r12
    pushq        %rbx
    andq         $-64, %rsp
    subq         $320, %rsp  // imm = 0x140
    movq         %rdx, 48(%rsp)
    movq         %rsi, 40(%rsp)
    movq         %rdi, 32(%rsp)
    testl        %r8d, %r8d
    jle          .LBS1_20
    // Normalize the distant light direction once: l = (lx, ly, lz + 1) / |..|
    // (specular half-vector base; the +1 folds in the (0, 0, 1) view term).
    movq         %r9, %rbx
    movq         %rcx, %r15
    movq         %r8, %rax
    vbroadcastss (%r9), %ymm1
    vmovaps      %ymm1, 224(%rsp)
    vbroadcastss 12(%r9), %ymm1
    vbroadcastss 16(%r9), %ymm2
    vmovss       20(%r9), %xmm3  // xmm3 = mem[0],zero,zero,zero
    vaddss       .LCPI1_0(%rip), %xmm3, %xmm3
    vmulss       %xmm2, %xmm2, %xmm4
    vmulss       %xmm1, %xmm1, %xmm5
    vaddss       %xmm4, %xmm5, %xmm4
    vmulss       %xmm3, %xmm3, %xmm5
    vaddss       %xmm4, %xmm5, %xmm4
    vbroadcastss %xmm4, %ymm4
    vsqrtps      %ymm4, %ymm4
    vdivps       %ymm4, %ymm1, %ymm1
    vmovaps      %ymm1, 192(%rsp)
    vdivps       %ymm4, %ymm2, %ymm1
    vmovaps      %ymm1, 160(%rsp)
    vbroadcastss %xmm3, %ymm1
    vdivps       %ymm4, %ymm1, %ymm1
    vmovaps      %ymm1, 128(%rsp)
    vbroadcastss 4(%r9), %ymm1
    vmovaps      %ymm1, 96(%rsp)
    vextractps     $0, %xmm0, 56(%rsp)
    decl         %eax
    shrl         $3, %eax
    incl         %eax
    movq         %rax, 24(%rsp)
    xorl         %r13d, %r13d
    xorl         %r12d, %r12d
    jmp          .LBS1_2
.LBS1_19:
    addq         $8, %r13
    incq         %r12
    addq         $32, %r15
    cmpq         24(%rsp), %r12
    je           .LBS1_20
.LBS1_2:
    vbroadcastss 36(%rbx), %ymm0
    movq         32(%rsp), %rax
    vmovdqu      (%rax,%r13,4), %ymm1
    vmovdqu      4(%rax,%r13,4), %ymm2
    vmovdqu      8(%rax,%r13,4), %ymm3
    ALPHA_FSCALE %ymm1, %ymm1, %ymm0, %ymm1
    ALPHA_FSCALE %ymm2, %ymm2, %ymm0, %ymm2
    ALPHA_FSCALE %ymm3, %ymm3, %ymm0, %ymm3
    movq         40(%rsp), %rax
    vmovdqu      (%rax,%r13,4), %ymm4
    vmovdqu      8(%rax,%r13,4), %ymm5
    ALPHA_FSCALE %ymm4, %ymm4, %ymm0, %ymm4
    ALPHA_FSCALE %ymm5, %ymm5, %ymm0, %ymm5
    movq         48(%rsp), %rax
    vmovdqu      (%rax,%r13,4), %ymm6
    vmovdqu      4(%rax,%r13,4), %ymm7
    vmovdqu      8(%rax,%r13,4), %ymm8
    ALPHA_FSCALE %ymm6, %ymm6, %ymm0, %ymm6
    vpsrld       $24, %ymm7, %ymm7
    vcvtdq2ps    %ymm7, %ymm7
    vpsrld       $24, %ymm8, %ymm8
    vcvtdq2ps    %ymm8, %ymm8
    vmulps       %ymm0, %ymm8, %ymm8
    // 1:2:1 row sums + x/y derivatives, scaled by 1/invDx and 1/invDy.
    vaddps       %ymm5, %ymm5, %ymm5
    vaddps       %ymm3, %ymm5, %ymm5
    vaddps       %ymm5, %ymm8, %ymm5
    vaddps       %ymm4, %ymm4, %ymm4
    vaddps       %ymm1, %ymm4, %ymm4
    vaddps       %ymm6, %ymm4, %ymm4
    vsubps       %ymm4, %ymm5, %ymm4
    vdivps       224(%rsp), %ymm4, %ymm4
    vmulps       %ymm7, %ymm0, %ymm0
    vaddps       %ymm0, %ymm0, %ymm0
    vaddps       %ymm6, %ymm0, %ymm0
    vaddps       %ymm0, %ymm8, %ymm0
    vaddps       %ymm2, %ymm2, %ymm2
    vaddps       %ymm1, %ymm2, %ymm1
    vaddps       %ymm3, %ymm1, %ymm1
    vsubps       %ymm1, %ymm0, %ymm0
    vdivps       96(%rsp), %ymm0, %ymm0
    // Surface normal n = (-dx, -dy, 1) / |..|, dotted with the scaled light
    // dirs and clamped: dot = max(0, n.l).
    vxorps       %xmm5, %xmm5, %xmm5
    vsubps       %ymm4, %ymm5, %ymm1
    vsubps       %ymm0, %ymm5, %ymm0
    vmulps       %ymm0, %ymm0, %ymm2
    vmulps       %ymm1, %ymm1, %ymm3
    vaddps       %ymm2, %ymm3, %ymm2
    vbroadcastss .LCPI1_0(%rip), %ymm3  // ymm3 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    vaddps       %ymm3, %ymm2, %ymm2
    vsqrtps      %ymm2, %ymm2
    vdivps       %ymm2, %ymm1, %ymm1
    vdivps       %ymm2, %ymm0, %ymm0
    vmulps       192(%rsp), %ymm1, %ymm1
    vmulps       160(%rsp), %ymm0, %ymm0
    vaddps       %ymm0, %ymm1, %ymm0
    vdivps       %ymm2, %ymm3, %ymm1
    vmulps       128(%rsp), %ymm1, %ymm1
    vaddps       %ymm0, %ymm1, %ymm0
    vmaxps       %ymm5, %ymm0, %ymm0

    // Full SIMD Specular Path (Fast Approximation) - Linear
    vbroadcastss 56(%rsp), %ymm1  // exponent
    POW8_AVX2 %ymm0, %ymm1, %ymm9

    // intensity = k * p clamped to [0, 1]
    vbroadcastss 8(%rbx), %ymm1  // k
    vmulps    %ymm1, %ymm0, %ymm0
    vxorps    %ymm1, %ymm1, %ymm1
    vmaxps    %ymm1, %ymm0, %ymm0
    vbroadcastss .LCPI1_0(%rip), %ymm1  // 1.0f
    vminps    %ymm1, %ymm0, %ymm0

    // R/G/B = intensity * lr/lg/lb (Linear Light)
    vbroadcastss 24(%rbx), %ymm1  // lr
    vmulps    %ymm0, %ymm1, %ymm1
    vbroadcastss 28(%rbx), %ymm2  // lg
    vmulps    %ymm0, %ymm2, %ymm2
    vbroadcastss 32(%rbx), %ymm3  // lb
    vmulps    %ymm0, %ymm3, %ymm3

    // Round-half-up and clamp to [0, 255]
    vbroadcastss .Lhalf(%rip), %ymm4
    vaddps    %ymm4, %ymm1, %ymm1
    vaddps    %ymm4, %ymm2, %ymm2
    vaddps    %ymm4, %ymm3, %ymm3

    vcvttps2dq %ymm1, %ymm1
    vcvttps2dq %ymm2, %ymm2
    vcvttps2dq %ymm3, %ymm3

    vpxor     %xmm4, %xmm4, %xmm4
    vpmaxsd   %ymm4, %ymm1, %ymm1
    vpmaxsd   %ymm4, %ymm2, %ymm2
    vpmaxsd   %ymm4, %ymm3, %ymm3
    vmovdqa   .L255_epi32(%rip), %ymm4
    vpminsd   %ymm4, %ymm1, %ymm1
    vpminsd   %ymm4, %ymm2, %ymm2
    vpminsd   %ymm4, %ymm3, %ymm3

    // Pack Linear bytes: (R << 16) | (G << 8) | B
    vpslld    $16, %ymm1, %ymm1
    vpslld    $8, %ymm2, %ymm2
    vpor      %ymm1, %ymm2, %ymm1
    vpor      %ymm1, %ymm3, %ymm1
    vmovdqu   %ymm1, 256(%rsp)
    jmp          .LBS1_21

/* The 4-pixel linear->sRGB lane lives in the file-local helper
 * l2s_vec4_avx2 below (a .macro cannot hold shift immediates portably:
 * single-digit $N inside a macro body is a macro-arg reference on newer
 * LLVM and silently assembles to $0 on older LLVM). */
.LBS1_21:
    // Vector linear->sRGB for the completed 8-pixel block: two SSSE3-style
    // 4-pixel lanes via vpshufb (same amortized tables as L2S1, same bytes),
    // then max-channel pack (alpha = max(R,G,B)) + 32-byte store.
    vmovdqu      256(%rsp), %ymm0
    vextracti128 $1, %ymm0, %xmm1
    vmovdqa      %xmm1, 304(%rsp)  // park lane1 input
    call         l2s_vec4_avx2
    vmovdqa      %xmm1, 288(%rsp)  // park lane0 result
    vmovdqa      304(%rsp), %xmm0  // lane1 input
    call         l2s_vec4_avx2
    vmovdqa      288(%rsp), %xmm0  // lane0 result
    vinserti128  $1, %xmm1, %ymm0, %ymm0
    vmovdqu      %ymm0, (%r15)
    jmp          .LBS1_19
.LBS1_20:
    leaq         -40(%rbp), %rsp
    popq         %rbx
    popq         %r12
    popq         %r13
    popq         %r14
    popq         %r15
    popq         %rbp
    retq
.Lfunc_end_linear:
    // SIZE(ksvgLightingDistantSpecularRowAvx2Linear)

/*
 * Description:
 *   One 4-pixel linear->sRGB lane. Straight VEX transliteration of the
 *   proven SSSE3 block: nibble-split interpolation (base + slope*lo),
 *   per-bit correction, exact low-16 select, then max-channel alpha.
 *   Bit-identical to 4x L2S1.
 *
 *   File-local helper (not a .macro): single-digit shift immediates inside
 *   a macro body misassemble on some LLVM versions, so this stays a plain
 *   function. Called twice per 8-pixel block; the two direct calls cost
 *   nothing measurable next to the polynomial above.
 *
 * Inputs:
 *   %xmm0 = 4 linear dwords (0x00RRGGBB each, preserved)
 *
 * Output:
 *   %xmm1 = 4 packed sRGB ARGB dwords
 *
 * Clobbers:
 *   %xmm1-%xmm7. No GPRs touched, so the caller's loop state
 *   (%rbx/%r12/%r13/%r15, all callee-saved) survives the call.
 */
.p2align 4
l2s_vec4_avx2:
    vpxor        %xmm7, %xmm7, %xmm7
    vmovdqa      %xmm0, %xmm1
    vpsrlw       $4, %xmm1, %xmm1
    vpand        .Lvec_l2s_nibble(%rip), %xmm1, %xmm1
    vmovdqa      %xmm0, %xmm2
    vpand        .Lvec_l2s_nibble(%rip), %xmm2, %xmm2
    vmovdqa      .Lspec_l2s_data+16(%rip), %xmm3
    vpshufb      %xmm1, %xmm3, %xmm3
    vmovdqa      .Lspec_l2s_data+32(%rip), %xmm4
    vpshufb      %xmm1, %xmm4, %xmm4
    vmovdqa      %xmm4, %xmm5
    vpunpcklbw   %xmm7, %xmm5, %xmm5
    vmovdqa      %xmm2, %xmm6
    vpunpcklbw   %xmm7, %xmm6, %xmm6
    vpmaddubsw   %xmm6, %xmm5, %xmm5
    vmovdqa      %xmm4, %xmm6
    vpunpckhbw   %xmm7, %xmm6, %xmm6
    vmovdqa      %xmm2, %xmm4
    vpunpckhbw   %xmm7, %xmm4, %xmm4
    vpmaddubsw   %xmm4, %xmm6, %xmm6
    vpaddw       .Lvec_l2s_rounding(%rip), %xmm5, %xmm5
    vpsrlw       $5, %xmm5, %xmm5
    vpaddw       .Lvec_l2s_rounding(%rip), %xmm6, %xmm6
    vpsrlw       $5, %xmm6, %xmm6
    vpackuswb    %xmm6, %xmm5, %xmm5
    vpaddb       %xmm3, %xmm5, %xmm5
    vmovdqa      %xmm0, %xmm3
    vpsrlw       $3, %xmm3, %xmm3
    vpand        .Lvec_l2s_group_mask(%rip), %xmm3, %xmm3
    vmovdqa      %xmm3, %xmm4
    vpsubb       .Lvec_l2s_group16(%rip), %xmm4, %xmm4
    vmovdqa      .Lspec_l2s_data+64(%rip), %xmm6
    vpshufb      %xmm4, %xmm6, %xmm6
    vmovdqa      %xmm3, %xmm4
    vpsrlw       $4, %xmm4, %xmm4
    vpand        .Lvec_l2s_one(%rip), %xmm4, %xmm4
    vpsllw       $7, %xmm4, %xmm4
    vpor         %xmm3, %xmm4, %xmm4
    vmovdqa      .Lspec_l2s_data+48(%rip), %xmm3
    vpshufb      %xmm4, %xmm3, %xmm3
    vpor         %xmm6, %xmm3, %xmm3
    vmovdqa      %xmm2, %xmm4
    vpand        .Lvec_l2s_low3(%rip), %xmm4, %xmm4
    vmovdqa      .Lvec_l2s_onehot16(%rip), %xmm6
    vpshufb      %xmm4, %xmm6, %xmm6
    vpand        %xmm6, %xmm3, %xmm3
    vpminub      .Lvec_l2s_one(%rip), %xmm3, %xmm3
    vpsubb       %xmm3, %xmm5, %xmm5
    vmovdqa      .Lspec_l2s_data(%rip), %xmm3
    vpshufb      %xmm2, %xmm3, %xmm3
    vpcmpeqb     %xmm7, %xmm1, %xmm1
    vpand        %xmm1, %xmm3, %xmm3
    vpandn       %xmm5, %xmm1, %xmm1
    vpor         %xmm3, %xmm1, %xmm1
    vmovdqa      %xmm1, %xmm2
    vpsrld       $8, %xmm2, %xmm2
    vpand        .Lvec_l2s_rgb_low_mask(%rip), %xmm2, %xmm2
    vmovdqa      %xmm1, %xmm3
    vpsrld       $16, %xmm3, %xmm3
    vpand        .Lvec_l2s_rgb_low_mask(%rip), %xmm3, %xmm3
    vpmaxub      %xmm3, %xmm2, %xmm2
    vmovdqa      %xmm1, %xmm3
    vpand        .Lvec_l2s_rgb_low_mask(%rip), %xmm3, %xmm3
    vpmaxub      %xmm3, %xmm2, %xmm2
    vpslld       $24, %xmm2, %xmm2
    vpand        .Lvec_l2s_rgb_mask(%rip), %xmm1, %xmm1
    vpor         %xmm2, %xmm1, %xmm1
    retq

.p2align 4
.Lspec_l2s_data:
    /* exact low 16 */
.byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69
    /* base[16] */
.byte 0,72,100,121,137,152,165,177,188,198,208,217,225,233,241,248
    /* slope[16] */
.byte 0,58,41,31,31,27,24,22,20,19,16,15,16,16,15,16
    /* correction_lo[16] */
.byte 0,0,7,241,5,0,7,0,0,240,0,194,0,64,0,1
    /* correction_hi[16] */
.byte 16,0,0,0,42,0,1,0,0,0,0,168,0,80,128,170
    /* onehot[8] */
.byte 1,2,4,8,16,32,64,128

.p2align 4
/* Vector (2x128-bit lane) linear->sRGB tables for .LBS1_21. Nibble masks
 * and correction constants mirror the SSSE3 .Ls_* set; the exact/base/
 * slope/correction tables are reused in place from .Lspec_l2s_data above. */
.Lvec_l2s_onehot16:
.byte 1,2,4,8,16,32,64,128,1,2,4,8,16,32,64,128
.Lvec_l2s_nibble:
.byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
.Lvec_l2s_group_mask:
.byte 31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
.Lvec_l2s_low3:
.byte 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
.Lvec_l2s_one:
.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.Lvec_l2s_group16:
.byte 16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16
.Lvec_l2s_rounding:
.short 16,16,16,16,16,16,16,16
.Lvec_l2s_rgb_low_mask:
.long 0x000000ff,0x000000ff,0x000000ff,0x000000ff
.Lvec_l2s_rgb_mask:
.long 0x00ffffff,0x00ffffff,0x00ffffff,0x00ffffff
RODATA
.p2align 5
.Lhalf:
.long 0x3f000000  // 0.5f round-half-up bias (matches scalar floor(v+0.5f))

EMIT_LOG2_POLY_8
EMIT_EXP2_POLY_8
EMIT_POW_COMMON_CONSTANTS
.p2align 4
.LCPI1_0:
.long	0x3f800000
.p2align 4  // float 1
GNU_STACK
