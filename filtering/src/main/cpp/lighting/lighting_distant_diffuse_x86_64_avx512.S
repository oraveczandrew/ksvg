/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "asm_macros.S"


.text
.p2align 6
.globl SYM(ksvgLightingDistantDiffuseRowAvx512)
TYPE(SYM(ksvgLightingDistantDiffuseRowAvx512), @function)
SYM(ksvgLightingDistantDiffuseRowAvx512):
    // SysV x86-64: rdi=srcT, rsi=srcM, rdx=srcB, rcx=dst, r8=count, r9=params

    test    %r8d, %r8d
    jz      .Ldone

    // Load Params
    vbroadcastss .Lone(%rip), %zmm0
    vdivss  0(%r9), %xmm0, %xmm1
    vbroadcastss %xmm1, %zmm6           // 1/invDx
    vdivss  4(%r9), %xmm0, %xmm1
    vbroadcastss %xmm1, %zmm7           // 1/invDy

    vbroadcastss 8(%r9), %zmm8
    vbroadcastss 12(%r9), %zmm9
    vbroadcastss 16(%r9), %zmm10
    vbroadcastss 20(%r9), %zmm11
    vbroadcastss 24(%r9), %zmm12
    vbroadcastss 28(%r9), %zmm13
    vbroadcastss 32(%r9), %zmm14
    vbroadcastss 36(%r9), %zmm15

    mov     %r8d, %r10d

.Lloop:
    // Row T: alpha values stay integer until dx/dy are formed.
    vmovdqu32 0(%rdi), %zmm0
    vpsrld    $24, %zmm0, %zmm0              // hT_l
    vmovdqu32 4(%rdi), %zmm1
    vpsrld    $24, %zmm1, %zmm1              // hT_m
    vmovdqu32 8(%rdi), %zmm2
    vpsrld    $24, %zmm2, %zmm2              // hT_r

    vpaddd     %zmm1, %zmm1, %zmm3
    vpaddd    %zmm0, %zmm3, %zmm3
    vpaddd    %zmm2, %zmm3, %zmm3           // sumT
    vpsubd    %zmm0, %zmm2, %zmm4           // dx_rel

    // Row M
    vmovdqu32 0(%rsi), %zmm0
    vpsrld    $24, %zmm0, %zmm0              // hM_l
    vmovdqu32 8(%rsi), %zmm2
    vpsrld    $24, %zmm2, %zmm2              // hM_r
    vpsubd    %zmm0, %zmm2, %zmm5
    vpslld    $1, %zmm5, %zmm5
    vpaddd    %zmm5, %zmm4, %zmm4

    // Row B
    vmovdqu32 0(%rdx), %zmm0
    vpsrld    $24, %zmm0, %zmm0              // hB_l
    vmovdqu32 4(%rdx), %zmm1
    vpsrld    $24, %zmm1, %zmm1              // hB_m
    vmovdqu32 8(%rdx), %zmm2
    vpsrld    $24, %zmm2, %zmm2              // hB_r
    vpaddd     %zmm1, %zmm1, %zmm5
    vpaddd    %zmm0, %zmm5, %zmm5
    vpaddd    %zmm2, %zmm5, %zmm5           // sumB

    vpsubd    %zmm0, %zmm2, %zmm0
    vpaddd    %zmm0, %zmm4, %zmm4           // final dx_rel
    vpsubd    %zmm3, %zmm5, %zmm5           // dy_rel

    vcvtdq2ps %zmm4, %zmm4
    vcvtdq2ps %zmm5, %zmm5
    vmulps    %zmm6, %zmm4, %zmm4           // dx
    vmulps    %zmm7, %zmm5, %zmm5           // dy

    // n = (-dx, -dy, 1)
    vpxorq    %zmm0, %zmm0, %zmm0
    vsubps    %zmm4, %zmm0, %zmm0
    vpxorq    %zmm1, %zmm1, %zmm1
    vsubps    %zmm5, %zmm1, %zmm1

    vmulps    %zmm0, %zmm0, %zmm2
    vmulps    %zmm1, %zmm1, %zmm4
    vaddps    %zmm4, %zmm2, %zmm2
    vaddps    .Lone(%rip){1to16}, %zmm2, %zmm2

    vrsqrt14ps %zmm2, %zmm3
    vmulps    %zmm3, %zmm3, %zmm4
    vmulps    %zmm2, %zmm4, %zmm4
    vmulps    .Lhalf(%rip){1to16}, %zmm4, %zmm4
    vsubps    .Lthree_halves(%rip){1to16}, %zmm4, %zmm5
    vmulps    %zmm3, %zmm5, %zmm3

    // dot
    vmulps    %zmm9, %zmm0, %zmm0
    vmulps    %zmm10, %zmm1, %zmm1
    vaddps    %zmm1, %zmm0, %zmm0
    vfmadd213ps %zmm11, %zmm3, %zmm0

    vpxorq    %zmm1, %zmm1, %zmm1
    vmaxps    %zmm1, %zmm0, %zmm0
    vmulps    %zmm8, %zmm0, %zmm0
    vminps    .Lone(%rip){1to16}, %zmm0, %zmm0

    vmulps    %zmm12, %zmm0, %zmm1
    vmulps    %zmm13, %zmm0, %zmm2
    vmulps    %zmm14, %zmm0, %zmm0
    vaddps    .Lhalf(%rip){1to16}, %zmm1, %zmm1
    vaddps    .Lhalf(%rip){1to16}, %zmm2, %zmm2
    vaddps    .Lhalf(%rip){1to16}, %zmm0, %zmm0

    vcvttps2dq %zmm1, %zmm1
    vcvttps2dq %zmm2, %zmm2
    vcvttps2dq %zmm0, %zmm0
    vpslld    $16, %zmm1, %zmm1
    vpslld    $8, %zmm2, %zmm2
    vporq     %zmm1, %zmm0, %zmm0
    vporq     %zmm2, %zmm0, %zmm0
    vporq     .LmaskAlphaShifted(%rip), %zmm0, %zmm0
    vmovdqu32 %zmm0, (%rcx)

    add       $64, %rdi
    add       $64, %rsi
    add       $64, %rdx
    add       $64, %rcx
    sub       $16, %r10d
    jnz       .Lloop

    vzeroupper
.Ldone:
    ret

#ifdef __APPLE__
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 6
.Lzero:             .float 0.0
.Lone:              .float 1.0
.Lhalf:             .float 0.5
.Lthree_halves:     .float 1.5
.LmaskAlphaShifted: .long 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000

//// SIZE(ksvgLightingDistantDiffuseRowAvx512)
