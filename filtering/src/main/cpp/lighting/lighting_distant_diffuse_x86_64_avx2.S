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

#ifdef __APPLE__
#define SYM(x) _##x
#define TYPE(x,y)
#define SIZE(x)
#else
#define SYM(x) x
#define TYPE(x,y) .type x,y
#define SIZE(x) .size x,.-x
#endif

.text
.p2align 5
.globl SYM(ksvgLightingDistantDiffuseRowAvx2)
TYPE(SYM(ksvgLightingDistantDiffuseRowAvx2), @function)
SYM(ksvgLightingDistantDiffuseRowAvx2):
    // SysV x86-64: rdi=srcT, rsi=srcM, rdx=srcB, rcx=dst, r8=count, r9=params

    test    %r8d, %r8d
    jz      .Ldone

    push    %rbx
    push    %rbp

    // Load Params
    vbroadcastss .Lone(%rip), %ymm0
    vdivss  0(%r9), %xmm0, %xmm1
    vbroadcastss %xmm1, %ymm6           // ymm6 = 1/invDx
    vdivss  4(%r9), %xmm0, %xmm1
    vbroadcastss %xmm1, %ymm7           // ymm7 = 1/invDy

    vbroadcastss 8(%r9), %ymm8           // k
    vbroadcastss 12(%r9), %ymm9          // lx
    vbroadcastss 16(%r9), %ymm10         // ly
    vbroadcastss 20(%r9), %ymm11         // lz
    vbroadcastss 24(%r9), %ymm12         // lr
    vbroadcastss 28(%r9), %ymm13         // lg
    vbroadcastss 32(%r9), %ymm14         // lb
    vbroadcastss 36(%r9), %ymm15         // ss

    mov     %r8d, %r10d

.Lloop:
    // rowT height
    vmovups 0(%rdi), %ymm0
    vpsrld  $24, %ymm0, %ymm0
    vcvtdq2ps %ymm0, %ymm0
    vmulps  %ymm15, %ymm0, %ymm0        // hT_l

    vmovups 4(%rdi), %ymm1
    vpsrld  $24, %ymm1, %ymm1
    vcvtdq2ps %ymm1, %ymm1
    vmulps  %ymm15, %ymm1, %ymm1        // hT_m

    vmovups 8(%rdi), %ymm2
    vpsrld  $24, %ymm2, %ymm2
    vcvtdq2ps %ymm2, %ymm2
    vmulps  %ymm15, %ymm2, %ymm2        // hT_r

    // sumT = lT + 2*mT + rT
    vaddps  %ymm1, %ymm1, %ymm3
    vaddps  %ymm0, %ymm3, %ymm3
    vaddps  %ymm2, %ymm3, %ymm3         // xmm3 = sumT

    // dx_rel = rT - lT
    vsubps  %ymm0, %ymm2, %ymm4

    // rowM height
    vmovups 0(%rsi), %ymm0
    vpsrld  $24, %ymm0, %ymm0
    vcvtdq2ps %ymm0, %ymm0
    vmulps  %ymm15, %ymm0, %ymm0        // hM_l

    vmovups 8(%rsi), %ymm2
    vpsrld  $24, %ymm2, %ymm2
    vcvtdq2ps %ymm2, %ymm2
    vmulps  %ymm15, %ymm2, %ymm2        // hM_r

    // dx_rel += 2*(rM - lM)
    vsubps  %ymm0, %ymm2, %ymm5
    vaddps  %ymm5, %ymm5, %ymm5
    vaddps  %ymm5, %ymm4, %ymm4

    // rowB height
    vmovups 0(%rdx), %ymm0
    vpsrld  $24, %ymm0, %ymm0
    vcvtdq2ps %ymm0, %ymm0
    vmulps  %ymm15, %ymm0, %ymm0        // hB_l

    vmovups 4(%rdx), %ymm1
    vpsrld  $24, %ymm1, %ymm1
    vcvtdq2ps %ymm1, %ymm1
    vmulps  %ymm15, %ymm1, %ymm1        // hB_m

    vmovups 8(%rdx), %ymm2
    vpsrld  $24, %ymm2, %ymm2
    vcvtdq2ps %ymm2, %ymm2
    vmulps  %ymm15, %ymm2, %ymm2        // hB_r

    // sumB = lB + 2*mB + rB
    vaddps  %ymm1, %ymm1, %ymm5
    vaddps  %ymm0, %ymm5, %ymm5
    vaddps  %ymm2, %ymm5, %ymm5         // xmm5 = sumB

    // final dx_rel += rB - lB
    vsubps  %ymm0, %ymm2, %ymm0
    vaddps  %ymm0, %ymm4, %ymm4

    // dx = dx_rel * scaleX, dy = (sumB - sumT) * scaleY
    vmulps  %ymm6, %ymm4, %ymm4
    vsubps  %ymm3, %ymm5, %ymm5
    vmulps  %ymm7, %ymm5, %ymm5

    // n = (-dx, -dy, 1)
    vxorps  %ymm0, %ymm0, %ymm0
    vsubps  %ymm4, %ymm0, %ymm0         // nx
    vxorps  %ymm1, %ymm1, %ymm1
    vsubps  %ymm5, %ymm1, %ymm1         // ny

    vmulps  %ymm0, %ymm0, %ymm2
    vmulps  %ymm1, %ymm1, %ymm4         // reuse ymm4
    vaddps  %ymm4, %ymm2, %ymm2
    vbroadcastss .Lone(%rip), %ymm4
    vaddps  %ymm4, %ymm2, %ymm2         // nLen^2

    vrsqrtps %ymm2, %ymm3
    vmulps  %ymm3, %ymm3, %ymm4
    vmulps  %ymm2, %ymm4, %ymm4
    vbroadcastss .Lhalf(%rip), %ymm5
    vmulps  %ymm5, %ymm4, %ymm4
    vbroadcastss .Lthree_halves(%rip), %ymm5
    vsubps  %ymm4, %ymm5, %ymm5
    vmulps  %ymm3, %ymm5, %ymm3         // 1/nLen

    vmulps  %ymm3, %ymm0, %ymm0         // nx
    vmulps  %ymm3, %ymm1, %ymm1         // ny

    vmulps  %ymm9, %ymm0, %ymm0
    vmulps  %ymm10, %ymm1, %ymm1
    vaddps  %ymm1, %ymm0, %ymm0
    vmulps  %ymm11, %ymm3, %ymm3
    vaddps  %ymm3, %ymm0, %ymm0         // dot

    vmaxps  .Lzero(%rip), %ymm0, %ymm0
    vmulps  %ymm8, %ymm0, %ymm0
    vbroadcastss .Lone(%rip), %ymm4
    vminps  %ymm4, %ymm0, %ymm0         // intensity

    // Pack
    vmulps  %ymm12, %ymm0, %ymm1
    vmulps  %ymm13, %ymm0, %ymm2
    vmulps  %ymm14, %ymm0, %ymm0

    vbroadcastss .Lhalf(%rip), %ymm3
    vaddps  %ymm3, %ymm1, %ymm1
    vaddps  %ymm3, %ymm2, %ymm2
    vaddps  %ymm3, %ymm0, %ymm0

    vcvttps2dq %ymm1, %ymm1
    vcvttps2dq %ymm2, %ymm2
    vcvttps2dq %ymm0, %ymm0

    vpslld  $16, %ymm1, %ymm1
    vpslld  $8, %ymm2, %ymm2
    vpor    %ymm1, %ymm0, %ymm0
    vpor    %ymm2, %ymm0, %ymm0
    vpor    .LmaskAlphaShifted(%rip), %ymm0, %ymm0

    vmovups %ymm0, (%rcx)

    add     $32, %rdi
    add     $32, %rsi
    add     $32, %rdx
    add     $32, %rcx
    sub     $8, %r10d
    jnz     .Lloop

    vzeroupper
    pop     %rbp
    pop     %rbx
.Ldone:
    ret

#ifdef __APPLE__
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 5
.Lzero:             .float 0.0
.Lone:              .float 1.0
.Lhalf:             .float 0.5
.Lthree_halves:     .float 1.5
.LmaskAlphaShifted: .long 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000

//// SIZE(ksvgLightingDistantDiffuseRowAvx2)
