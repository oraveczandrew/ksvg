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
#include "lighting_x86_64_ssse3_macros.S"
#include "math_pow_macros.S"

.text
.p2align 4
.globl SYM(ksvgLightingDistantSpecularRowSsse3)
TYPE(SYM(ksvgLightingDistantSpecularRowSsse3), @function)
SYM(ksvgLightingDistantSpecularRowSsse3):
CFI_START
    pushq          %rbp
    CFI_DEF_CFA_OFFSET(16)
    pushq          %r15
    CFI_DEF_CFA_OFFSET(24)
    pushq          %r14
    CFI_DEF_CFA_OFFSET(32)
    pushq          %r13
    CFI_DEF_CFA_OFFSET(40)
    pushq          %r12
    CFI_DEF_CFA_OFFSET(48)
    pushq          %rbx
    CFI_DEF_CFA_OFFSET(56)
    subq           $168, %rsp
    CFI_DEF_CFA_OFFSET(224)
    CFI_OFFSET(%rbx, -56)
    CFI_OFFSET(%r12, -48)
    CFI_OFFSET(%r13, -40)
    CFI_OFFSET(%r14, -32)
    CFI_OFFSET(%r15, -24)
    CFI_OFFSET(%rbp, -16)
    movq           %rcx, 24(%rsp)
    movq           %rdx, 72(%rsp)
    movq           %rsi, 64(%rsp)
    movq           %rdi, 56(%rsp)
    testl          %r8d, %r8d
    jle            .LBB1_15
    // Normalize the distant light direction once (half-vector base).
    movq           %r9, %rbx
    movq           %r8, %rax
    movss          (%r9), %xmm1  // xmm1 = mem[0],zero,zero,zero
    movss          4(%r9), %xmm2  // xmm2 = mem[0],zero,zero,zero
    shufps         $0, %xmm1, %xmm1  // xmm1 = xmm1[0,0,0,0]
    movaps         %xmm1, 144(%rsp)
    shufps         $0, %xmm2, %xmm2  // xmm2 = xmm2[0,0,0,0]
    movaps         %xmm2, 128(%rsp)
    movss          12(%r9), %xmm1  // xmm1 = mem[0],zero,zero,zero
    movaps         %xmm1, %xmm4
    shufps         $0, %xmm1, %xmm4  // xmm4 = xmm4[0,0],xmm1[0,0]
    movss          16(%r9), %xmm2  // xmm2 = mem[0],zero,zero,zero
    movaps         %xmm2, %xmm5
    movss          20(%r9), %xmm3  // xmm3 = mem[0],zero,zero,zero
    addss          .LCPI1_0(%rip), %xmm3
    shufps         $0, %xmm2, %xmm5  // xmm5 = xmm5[0,0],xmm2[0,0]
    movaps         %xmm3, %xmm6
    shufps         $0, %xmm3, %xmm6  // xmm6 = xmm6[0,0],xmm3[0,0]
    mulss          %xmm2, %xmm2
    mulss          %xmm1, %xmm1
    addss          %xmm2, %xmm1
    mulss          %xmm3, %xmm3
    addss          %xmm1, %xmm3
    shufps         $0, %xmm3, %xmm3  // xmm3 = xmm3[0,0,0,0]
    sqrtps         %xmm3, %xmm1
    divps          %xmm1, %xmm4
    movaps         %xmm4, 112(%rsp)
    divps          %xmm1, %xmm5
    movaps         %xmm5, 96(%rsp)
    divps          %xmm1, %xmm6
    movaps         %xmm6, 80(%rsp)
    movss          %xmm0, 16(%rsp)
    decl           %eax
    shrl           $2, %eax
    shlq           $4, %rax
    addq           $16, %rax
    movq           %rax, 48(%rsp)
    xorl           %r12d, %r12d
    jmp            .LBB1_2
.LBB1_14:
    addq           $16, %r12
    cmpq           %r12, 48(%rsp)
    je             .LBB1_15
.LBB1_2:
    // Main loop: Sobel window, normalize, per-pixel specular tails below.
    movq           56(%rsp), %rax
    movdqu         (%rax,%r12), %xmm0
    movdqu         4(%rax,%r12), %xmm1
    movdqu         8(%rax,%r12), %xmm2
    psrld          $24, %xmm0
    cvtdq2ps       %xmm0, %xmm0
    movss          36(%rbx), %xmm4  // xmm4 = mem[0],zero,zero,zero
    shufps         $0, %xmm4, %xmm4  // xmm4 = xmm4[0,0,0,0]
    mulps          %xmm4, %xmm0
    ALPHA_FSCALE   %xmm1, %xmm4
    ALPHA_FSCALE   %xmm2, %xmm4
    movq           64(%rsp), %rax
    movdqu         (%rax,%r12), %xmm3
    movdqu         8(%rax,%r12), %xmm5
    ALPHA_FSCALE_X %xmm3, %xmm6, %xmm4
    ALPHA_FSCALE_X %xmm5, %xmm3, %xmm4
    movq           72(%rsp), %rax
    movdqu         (%rax,%r12), %xmm5
    movdqu         4(%rax,%r12), %xmm7
    movdqu         8(%rax,%r12), %xmm8
    ALPHA_FSCALE_X %xmm5, %xmm9, %xmm4
    ALPHA_FSCALE_X %xmm7, %xmm5, %xmm4
    ALPHA_FSCALE_X %xmm8, %xmm7, %xmm4
    addps          %xmm3, %xmm3
    addps          %xmm2, %xmm3
    addps          %xmm7, %xmm3
    addps          %xmm6, %xmm6
    addps          %xmm0, %xmm6
    addps          %xmm9, %xmm6
    subps          %xmm6, %xmm3
    divps          144(%rsp), %xmm3
    addps          %xmm5, %xmm5
    addps          %xmm9, %xmm5
    addps          %xmm7, %xmm5
    addps          %xmm1, %xmm1
    addps          %xmm0, %xmm1
    addps          %xmm2, %xmm1
    subps          %xmm1, %xmm5
    divps          128(%rsp), %xmm5
    xorps          %xmm0, %xmm0
    subps          %xmm3, %xmm0
    xorps          %xmm1, %xmm1
    subps          %xmm5, %xmm1
    movaps         %xmm1, %xmm2
    mulps          %xmm1, %xmm2
    movaps         %xmm0, %xmm3
    mulps          %xmm0, %xmm3
    addps          %xmm2, %xmm3
    movaps         .LCPI1_1(%rip), %xmm4  // xmm4 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    addps          %xmm4, %xmm3
    sqrtps         %xmm3, %xmm2
    divps          %xmm2, %xmm0
    mulps          112(%rsp), %xmm0
    divps          %xmm2, %xmm1
    mulps          96(%rsp), %xmm1
    addps          %xmm0, %xmm1
    divps          %xmm2, %xmm4
    mulps          80(%rsp), %xmm4
    addps          %xmm1, %xmm4
    maxps          .LCPI1_2(%rip), %xmm4
    // Full SIMD specular: p = pow(dot, exp), intensity, vector pack.
    movss          16(%rsp), %xmm5
    shufps         $0, %xmm5, %xmm5
    POW4_SSSE3     %xmm4, %xmm5
    movss          8(%rbx), %xmm0
    shufps         $0, %xmm0, %xmm0  // k
    mulps          %xmm4, %xmm0  // k * p
    xorps          %xmm1, %xmm1  // 0
    maxps          %xmm1, %xmm0
    movaps         .LCPI1_1(%rip), %xmm1  // 1.0
    minps          %xmm1, %xmm0  // intensity
    movss          24(%rbx), %xmm1
    shufps         $0, %xmm1, %xmm1
    mulps          %xmm0, %xmm1  // lr * I
    movss          28(%rbx), %xmm2
    shufps         $0, %xmm2, %xmm2
    mulps          %xmm0, %xmm2  // lg * I
    movss          32(%rbx), %xmm3
    shufps         $0, %xmm3, %xmm3
    mulps          %xmm0, %xmm3  // lb * I
    movss          .Lhalf(%rip), %xmm5
    shufps         $0, %xmm5, %xmm5
    addps          %xmm5, %xmm1
    addps          %xmm5, %xmm2
    addps          %xmm5, %xmm3
    xorps          %xmm0, %xmm0  // 0
    maxps          %xmm0, %xmm1
    maxps          %xmm0, %xmm2
    maxps          %xmm0, %xmm3
    movss          .Lfloat_255(%rip), %xmm5
    shufps         $0, %xmm5, %xmm5  // 255.0
    minps          %xmm5, %xmm1
    minps          %xmm5, %xmm2
    minps          %xmm5, %xmm3
    cvttps2dq      %xmm1, %xmm1
    cvttps2dq      %xmm2, %xmm2
    cvttps2dq      %xmm3, %xmm3
    pslld          $16, %xmm1
    pslld          $8, %xmm2
    por            %xmm2, %xmm1
    por            %xmm3, %xmm1
    // Alpha = max(R, G, B), same byte sequence as the linear block below.
    movdqa         %xmm1, %xmm2
    psrld          $8, %xmm2
    pand           .Ls_rgb_low_mask(%rip), %xmm2
    movdqa         %xmm1, %xmm3
    psrld          $16, %xmm3
    pand           .Ls_rgb_low_mask(%rip), %xmm3
    pmaxub         %xmm3, %xmm2
    movdqa         %xmm1, %xmm3
    pand           .Ls_rgb_low_mask(%rip), %xmm3
    pmaxub         %xmm3, %xmm2
    pslld          $24, %xmm2
    pand           .Ls_rgb_mask(%rip), %xmm1
    por            %xmm2, %xmm1
    movq           24(%rsp), %rax
    movdqu         %xmm1, (%rax,%r12)
    jmp            .LBB1_14
.LBB1_15:
    addq           $168, %rsp
    CFI_DEF_CFA_OFFSET(56)
    popq           %rbx
    CFI_DEF_CFA_OFFSET(48)
    popq           %r12
    CFI_DEF_CFA_OFFSET(40)
    popq           %r13
    CFI_DEF_CFA_OFFSET(32)
    popq           %r14
    CFI_DEF_CFA_OFFSET(24)
    popq           %r15
    CFI_DEF_CFA_OFFSET(16)
    popq           %rbp
    CFI_DEF_CFA_OFFSET(8)
    retq
.Lfunc_end1:
CFI_END

.text
.p2align 4
.globl SYM(ksvgLightingDistantSpecularRowSsse3Linear)
TYPE(SYM(ksvgLightingDistantSpecularRowSsse3Linear), @function)
SYM(ksvgLightingDistantSpecularRowSsse3Linear):
CFI_START
    pushq          %rbp
    CFI_DEF_CFA_OFFSET(16)
    pushq          %r15
    CFI_DEF_CFA_OFFSET(24)
    pushq          %r14
    CFI_DEF_CFA_OFFSET(32)
    pushq          %r13
    CFI_DEF_CFA_OFFSET(40)
    pushq          %r12
    CFI_DEF_CFA_OFFSET(48)
    pushq          %rbx
    CFI_DEF_CFA_OFFSET(56)
    subq           $168, %rsp
    CFI_DEF_CFA_OFFSET(224)
    CFI_OFFSET(%rbx, -56)
    CFI_OFFSET(%r12, -48)
    CFI_OFFSET(%r13, -40)
    CFI_OFFSET(%r14, -32)
    CFI_OFFSET(%r15, -24)
    CFI_OFFSET(%rbp, -16)
    movq           %rcx, 24(%rsp)
    movq           %rdx, 72(%rsp)
    movq           %rsi, 64(%rsp)
    movq           %rdi, 56(%rsp)
    testl          %r8d, %r8d
    jle            .LBB2_15
    // Normalize the distant light direction once (half-vector base).
    movq           %r9, %rbx
    movq           %r8, %rax
    movss          (%r9), %xmm1  // xmm1 = mem[0],zero,zero,zero
    movss          4(%r9), %xmm2  // xmm2 = mem[0],zero,zero,zero
    shufps         $0, %xmm1, %xmm1  // xmm1 = xmm1[0,0,0,0]
    movaps         %xmm1, 144(%rsp)
    shufps         $0, %xmm2, %xmm2  // xmm2 = xmm2[0,0,0,0]
    movaps         %xmm2, 128(%rsp)
    movss          12(%r9), %xmm1  // xmm1 = mem[0],zero,zero,zero
    movaps         %xmm1, %xmm4
    shufps         $0, %xmm1, %xmm4  // xmm4 = xmm4[0,0],xmm1[0,0]
    movss          16(%r9), %xmm2  // xmm2 = mem[0],zero,zero,zero
    movaps         %xmm2, %xmm5
    movss          20(%r9), %xmm3  // xmm3 = mem[0],zero,zero,zero
    addss          .LCPI1_0(%rip), %xmm3
    shufps         $0, %xmm2, %xmm5  // xmm5 = xmm5[0,0],xmm2[0,0]
    movaps         %xmm3, %xmm6
    shufps         $0, %xmm3, %xmm6  // xmm6 = xmm6[0,0],xmm3[0,0]
    mulss          %xmm2, %xmm2
    mulss          %xmm1, %xmm1
    addss          %xmm2, %xmm1
    mulss          %xmm3, %xmm3
    addss          %xmm1, %xmm3
    shufps         $0, %xmm3, %xmm3  // xmm3 = xmm3[0,0,0,0]
    sqrtps         %xmm3, %xmm1
    divps          %xmm1, %xmm4
    movaps         %xmm4, 112(%rsp)
    divps          %xmm1, %xmm5
    movaps         %xmm5, 96(%rsp)
    divps          %xmm1, %xmm6
    movaps         %xmm6, 80(%rsp)
    movss          %xmm0, 16(%rsp)
    decl           %eax
    shrl           $2, %eax
    shlq           $4, %rax
    addq           $16, %rax
    movq           %rax, 48(%rsp)
    xorl           %r12d, %r12d
    jmp            .LBB2_2
.LBB2_14:
	/* Inline SSSE3 amortized linear->sRGB for the completed 4-pixel block. */
    movdqu         (%rax,%r12), %xmm0
    pxor           %xmm7, %xmm7
    movdqa         %xmm0, %xmm1
    psrlw          $4, %xmm1
    pand           .Ls_nibble(%rip), %xmm1
    movdqa         %xmm0, %xmm2
    pand           .Ls_nibble(%rip), %xmm2

    movdqa         .Ls_base(%rip), %xmm3
    pshufb         %xmm1, %xmm3
    movdqa         .Ls_slope(%rip), %xmm4
    pshufb         %xmm1, %xmm4
    movdqa         %xmm4, %xmm5
    punpcklbw      %xmm7, %xmm5
    movdqa         %xmm2, %xmm6
    punpcklbw      %xmm7, %xmm6
    pmaddubsw      %xmm6, %xmm5
    movdqa         %xmm4, %xmm6
    punpckhbw      %xmm7, %xmm6
    movdqa         %xmm2, %xmm4
    punpckhbw      %xmm7, %xmm4
    pmaddubsw      %xmm4, %xmm6
    paddw          .Ls_rounding(%rip), %xmm5
    psrlw          $5, %xmm5
    paddw          .Ls_rounding(%rip), %xmm6
    psrlw          $5, %xmm6
    packuswb       %xmm6, %xmm5
    paddb          %xmm3, %xmm5

    movdqa         %xmm0, %xmm3
    psrlw          $3, %xmm3
    pand           .Ls_group_mask(%rip), %xmm3
    movdqa         %xmm3, %xmm4
    psubb          .Ls_group16(%rip), %xmm4
    movdqa         .Ls_corr_hi(%rip), %xmm6
    pshufb         %xmm4, %xmm6
    movdqa         %xmm3, %xmm4
    psrlw          $4, %xmm4
    pand           .Ls_one(%rip), %xmm4
    psllw          $7, %xmm4
    por            %xmm3, %xmm4
    movdqa         .Ls_corr_lo(%rip), %xmm3
    pshufb         %xmm4, %xmm3
    por            %xmm6, %xmm3
    movdqa         %xmm2, %xmm4
    pand           .Ls_low3(%rip), %xmm4
    movdqa         .Ls_onehot(%rip), %xmm6
    pshufb         %xmm4, %xmm6
    pand           %xmm6, %xmm3
    pminub         .Ls_one(%rip), %xmm3
    psubb          %xmm3, %xmm5
    movdqa         .Ls_exact(%rip), %xmm3
    pshufb         %xmm2, %xmm3
    pcmpeqb        %xmm7, %xmm1
    pand           %xmm1, %xmm3
    pandn          %xmm5, %xmm1
    por            %xmm3, %xmm1

	/* Specular alpha = max(sRGB R,G,B). */
    movdqa         %xmm1, %xmm2
    psrld          $8, %xmm2
    pand           .Ls_rgb_low_mask(%rip), %xmm2
    movdqa         %xmm1, %xmm3
    psrld          $16, %xmm3
    pand           .Ls_rgb_low_mask(%rip), %xmm3
    pmaxub         %xmm3, %xmm2
    movdqa         %xmm1, %xmm3
    pand           .Ls_rgb_low_mask(%rip), %xmm3
    pmaxub         %xmm3, %xmm2
    pslld          $24, %xmm2
    pand           .Ls_rgb_mask(%rip), %xmm1
    por            %xmm2, %xmm1
    movdqu         %xmm1, (%rax,%r12)
    addq           $16, %r12
    cmpq           %r12, 48(%rsp)
    je             .LBB2_15
.LBB2_2:
    // Main loop: Sobel window, normalize, per-pixel specular tails below.
    movq           56(%rsp), %rax
    movdqu         (%rax,%r12), %xmm0
    movdqu         4(%rax,%r12), %xmm1
    movdqu         8(%rax,%r12), %xmm2
    psrld          $24, %xmm0
    cvtdq2ps       %xmm0, %xmm0
    movss          36(%rbx), %xmm4  // xmm4 = mem[0],zero,zero,zero
    shufps         $0, %xmm4, %xmm4  // xmm4 = xmm4[0,0,0,0]
    mulps          %xmm4, %xmm0
    ALPHA_FSCALE   %xmm1, %xmm4
    ALPHA_FSCALE   %xmm2, %xmm4
    movq           64(%rsp), %rax
    movdqu         (%rax,%r12), %xmm3
    movdqu         8(%rax,%r12), %xmm5
    ALPHA_FSCALE_X %xmm3, %xmm6, %xmm4
    ALPHA_FSCALE_X %xmm5, %xmm3, %xmm4
    movq           72(%rsp), %rax
    movdqu         (%rax,%r12), %xmm5
    movdqu         4(%rax,%r12), %xmm7
    movdqu         8(%rax,%r12), %xmm8
    ALPHA_FSCALE_X %xmm5, %xmm9, %xmm4
    ALPHA_FSCALE_X %xmm7, %xmm5, %xmm4
    ALPHA_FSCALE_X %xmm8, %xmm7, %xmm4
    addps          %xmm3, %xmm3
    addps          %xmm2, %xmm3
    addps          %xmm7, %xmm3
    addps          %xmm6, %xmm6
    addps          %xmm0, %xmm6
    addps          %xmm9, %xmm6
    subps          %xmm6, %xmm3
    divps          144(%rsp), %xmm3
    addps          %xmm5, %xmm5
    addps          %xmm9, %xmm5
    addps          %xmm7, %xmm5
    addps          %xmm1, %xmm1
    addps          %xmm0, %xmm1
    addps          %xmm2, %xmm1
    subps          %xmm1, %xmm5
    divps          128(%rsp), %xmm5
    xorps          %xmm0, %xmm0
    subps          %xmm3, %xmm0
    xorps          %xmm1, %xmm1
    subps          %xmm5, %xmm1
    movaps         %xmm1, %xmm2
    mulps          %xmm1, %xmm2
    movaps         %xmm0, %xmm3
    mulps          %xmm0, %xmm3
    addps          %xmm2, %xmm3
    movaps         .LCPI1_1(%rip), %xmm4  // xmm4 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    addps          %xmm4, %xmm3
    sqrtps         %xmm3, %xmm2
    divps          %xmm2, %xmm0
    mulps          112(%rsp), %xmm0
    divps          %xmm2, %xmm1
    mulps          96(%rsp), %xmm1
    addps          %xmm0, %xmm1
    divps          %xmm2, %xmm4
    mulps          80(%rsp), %xmm4
    addps          %xmm1, %xmm4
    maxps          .LCPI1_2(%rip), %xmm4
    // Full SIMD specular (linear light): p = pow(dot, exp), intensity,
    // vector linear pack; the amortized LUT block below converts in place.
    movss          16(%rsp), %xmm5
    shufps         $0, %xmm5, %xmm5
    POW4_SSSE3     %xmm4, %xmm5
    movss          8(%rbx), %xmm0
    shufps         $0, %xmm0, %xmm0  // k
    mulps          %xmm4, %xmm0  // k * p
    xorps          %xmm1, %xmm1  // 0
    maxps          %xmm1, %xmm0
    movaps         .LCPI1_1(%rip), %xmm1  // 1.0
    minps          %xmm1, %xmm0  // intensity
    movss          24(%rbx), %xmm1
    shufps         $0, %xmm1, %xmm1
    mulps          %xmm0, %xmm1  // lr * I
    movss          28(%rbx), %xmm2
    shufps         $0, %xmm2, %xmm2
    mulps          %xmm0, %xmm2  // lg * I
    movss          32(%rbx), %xmm3
    shufps         $0, %xmm3, %xmm3
    mulps          %xmm0, %xmm3  // lb * I
    movss          .Lhalf(%rip), %xmm5
    shufps         $0, %xmm5, %xmm5
    addps          %xmm5, %xmm1
    addps          %xmm5, %xmm2
    addps          %xmm5, %xmm3
    xorps          %xmm0, %xmm0  // 0
    maxps          %xmm0, %xmm1
    maxps          %xmm0, %xmm2
    maxps          %xmm0, %xmm3
    movss          .Lfloat_255(%rip), %xmm5
    shufps         $0, %xmm5, %xmm5  // 255.0
    minps          %xmm5, %xmm1
    minps          %xmm5, %xmm2
    minps          %xmm5, %xmm3
    cvttps2dq      %xmm1, %xmm1
    cvttps2dq      %xmm2, %xmm2
    cvttps2dq      %xmm3, %xmm3
    pslld          $16, %xmm1
    pslld          $8, %xmm2
    por            %xmm2, %xmm1
    por            %xmm3, %xmm1  // (R << 16) | (G << 8) | B
    movq           24(%rsp), %rax
    movdqu         %xmm1, (%rax,%r12)
    jmp            .LBB2_14
.LBB2_15:
    addq           $168, %rsp
    CFI_DEF_CFA_OFFSET(56)
    popq           %rbx
    CFI_DEF_CFA_OFFSET(48)
    popq           %r12
    CFI_DEF_CFA_OFFSET(40)
    popq           %r13
    CFI_DEF_CFA_OFFSET(32)
    popq           %r14
    CFI_DEF_CFA_OFFSET(24)
    popq           %r15
    CFI_DEF_CFA_OFFSET(16)
    popq           %rbp
    CFI_DEF_CFA_OFFSET(8)
    retq
.Lfunc_end2:
CFI_END

RODATA
.p2align 4
.LCPI1_0:
.long	0x3f800000
.p2align 4  // float 1
.LCPI1_1:
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.LCPI1_2:
.zero	16

RODATA
.p2align 4
.Lhalf:
.long	0x3f000000  // 0.5f round-half-up bias (matches scalar floor(v+0.5f))

EMIT_LOG2_POLY_8
EMIT_EXP2_POLY_8
EMIT_POW_COMMON_CONSTANTS

RODATA
.p2align 4
.Ls_exact: .byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69
.Ls_base: .byte 0,72,100,121,137,152,165,177,188,198,208,217,225,233,241,248
.Ls_slope: .byte 0,58,41,31,31,27,24,22,20,19,16,15,16,16,15,16
.Ls_nibble: .byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
.Ls_group_mask: .byte 31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
.Ls_low3: .byte 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
.Ls_one: .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.Ls_group16: .byte 16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16
.Ls_onehot: .byte 1,2,4,8,16,32,64,128,1,2,4,8,16,32,64,128
.Ls_corr_lo: .byte 0,0,7,241,5,0,7,0,0,240,0,194,0,64,0,1
.Ls_corr_hi: .byte 16,0,0,0,42,0,1,0,0,0,0,168,0,80,128,170
.Ls_alpha: .long 0xff000000,0xff000000,0xff000000,0xff000000
.Ls_rgb_mask: .long 0x00ffffff,0x00ffffff,0x00ffffff,0x00ffffff
.Ls_rgb_low_mask: .long 0x000000ff,0x000000ff,0x000000ff,0x000000ff
.Ls_rounding: .short 16,16,16,16,16,16,16,16
GNU_STACK
