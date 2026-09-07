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
.p2align 4
.globl SYM(ksvgLightingDistantDiffuseRowSse2)
TYPE(SYM(ksvgLightingDistantDiffuseRowSse2), @function)
SYM(ksvgLightingDistantDiffuseRowSse2):
    // SysV x86-64: rdi=srcT, rsi=srcM, rdx=srcB, rcx=dst, r8=count, r9=params

    test    %r8d, %r8d
    jz      .Ldone

    push    %rbx
    push    %rbp

    // Load Params
    movss   .Lone(%rip), %xmm0
    divss   0(%r9), %xmm0
    shufps  $0, %xmm0, %xmm0
    movaps  %xmm0, %xmm6            // xmm6 = 1/invDx

    movss   .Lone(%rip), %xmm0
    divss   4(%r9), %xmm0
    shufps  $0, %xmm0, %xmm0
    movaps  %xmm0, %xmm7            // xmm7 = 1/invDy

    movss   8(%r9), %xmm8           // k
    shufps  $0, %xmm8, %xmm8
    movss   12(%r9), %xmm9          // lx
    shufps  $0, %xmm9, %xmm9
    movss   16(%r9), %xmm10         // ly
    shufps  $0, %xmm10, %xmm10
    movss   20(%r9), %xmm11         // lz
    shufps  $0, %xmm11, %xmm11
    movss   24(%r9), %xmm12         // lr
    shufps  $0, %xmm12, %xmm12
    movss   28(%r9), %xmm13         // lg
    shufps  $0, %xmm13, %xmm13
    movss   32(%r9), %xmm14         // lb
    shufps  $0, %xmm14, %xmm14
    movss   36(%r9), %xmm15         // ss
    shufps  $0, %xmm15, %xmm15

    mov     %r8d, %r10d

.Lloop:
    // rowT height
    movups  0(%rdi), %xmm0
    psrld   $24, %xmm0
    cvtdq2ps %xmm0, %xmm0
    mulps   %xmm15, %xmm0           // hT_l

    movups  4(%rdi), %xmm1
    psrld   $24, %xmm1
    cvtdq2ps %xmm1, %xmm1
    mulps   %xmm15, %xmm1           // hT_m

    movups  8(%rdi), %xmm2
    psrld   $24, %xmm2
    cvtdq2ps %xmm2, %xmm2
    mulps   %xmm15, %xmm2           // hT_r

    // sumT = lT + 2*mT + rT
    movaps  %xmm1, %xmm3
    addps   %xmm3, %xmm3
    addps   %xmm0, %xmm3
    addps   %xmm2, %xmm3            // xmm3 = sumT

    // dx_rel = rT - lT
    movaps  %xmm2, %xmm4
    subps   %xmm0, %xmm4

    // rowM height
    movups  0(%rsi), %xmm0
    psrld   $24, %xmm0
    cvtdq2ps %xmm0, %xmm0
    mulps   %xmm15, %xmm0           // hM_l

    movups  8(%rsi), %xmm2
    psrld   $24, %xmm2
    cvtdq2ps %xmm2, %xmm2
    mulps   %xmm15, %xmm2           // hM_r

    // dx_rel += 2*(rM - lM)
    movaps  %xmm2, %xmm5
    subps   %xmm0, %xmm5
    addps   %xmm5, %xmm5
    addps   %xmm5, %xmm4

    // rowB height
    movups  0(%rdx), %xmm0
    psrld   $24, %xmm0
    cvtdq2ps %xmm0, %xmm0
    mulps   %xmm15, %xmm0           // hB_l

    movups  4(%rdx), %xmm1
    psrld   $24, %xmm1
    cvtdq2ps %xmm1, %xmm1
    mulps   %xmm15, %xmm1           // hB_m

    movups  8(%rdx), %xmm2
    psrld   $24, %xmm2
    cvtdq2ps %xmm2, %xmm2
    mulps   %xmm15, %xmm2           // hB_r

    // sumB = lB + 2*mB + rB
    movaps  %xmm1, %xmm5
    addps   %xmm5, %xmm5
    addps   %xmm0, %xmm5
    addps   %xmm2, %xmm5            // xmm5 = sumB

    // final dx_rel += rB - lB
    subps   %xmm0, %xmm2
    addps   %xmm2, %xmm4            // final dx_rel

    // dx = dx_rel * scaleX, dy = (sumB - sumT) * scaleY
    mulps   %xmm6, %xmm4            // xmm4 = dx
    subps   %xmm3, %xmm5
    mulps   %xmm7, %xmm5            // xmm5 = dy

    // n = (-dx, -dy, 1)
    xorps   %xmm0, %xmm0
    subps   %xmm4, %xmm0            // nx
    xorps   %xmm1, %xmm1
    subps   %xmm5, %xmm1            // ny

    movaps  %xmm0, %xmm2
    mulps   %xmm0, %xmm2            // nx^2
    movaps  %xmm1, %xmm3
    mulps   %xmm1, %xmm3
    addps   %xmm3, %xmm2
    addps   .Lone(%rip), %xmm2      // nLen^2

    rsqrtps %xmm2, %xmm3            // estimate
    // One NR iteration for precision
    movaps  %xmm3, %xmm4
    mulps   %xmm3, %xmm4
    mulps   %xmm2, %xmm4
    mulps   .Lhalf(%rip), %xmm4
    movaps  .Lthree_halves(%rip), %xmm5
    subps   %xmm4, %xmm5
    mulps   %xmm3, %xmm5            // xmm5 = 1/nLen

    mulps   %xmm5, %xmm0            // nx
    mulps   %xmm5, %xmm1            // ny
    // nz = xmm5

    mulps   %xmm9, %xmm0
    mulps   %xmm10, %xmm1
    addps   %xmm1, %xmm0
    mulps   %xmm11, %xmm5
    addps   %xmm5, %xmm0            // dot

    maxps   .Lzero(%rip), %xmm0
    mulps   %xmm8, %xmm0
    minps   .Lone(%rip), %xmm0      // intensity

    // Pack
    movaps  %xmm0, %xmm1
    mulps   %xmm12, %xmm1           // outR
    movaps  %xmm0, %xmm2
    mulps   %xmm13, %xmm2           // outG
    mulps   %xmm14, %xmm0           // outB

    addps   .Lhalf(%rip), %xmm1
    addps   .Lhalf(%rip), %xmm2
    addps   .Lhalf(%rip), %xmm0

    cvttps2dq %xmm1, %xmm1
    cvttps2dq %xmm2, %xmm2
    cvttps2dq %xmm0, %xmm0

    pslld   $16, %xmm1
    pslld   $8, %xmm2
    por     %xmm1, %xmm0
    por     %xmm2, %xmm0
    por     .LmaskAlphaShifted(%rip), %xmm0

    movups  %xmm0, (%rcx)

    add     $16, %rdi
    add     $16, %rsi
    add     $16, %rdx
    add     $16, %rcx
    sub     $4, %r10d
    jnz     .Lloop

    pop     %rbp
    pop     %rbx
.Ldone:
    ret

#ifdef __APPLE__
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 4
.Lzero:             .float 0.0, 0.0, 0.0, 0.0
.Lone:              .float 1.0, 1.0, 1.0, 1.0
.Lhalf:             .float 0.5, 0.5, 0.5, 0.5
.Lthree_halves:     .float 1.5, 1.5, 1.5, 1.5
.LmaskAlphaShifted: .long 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000

//// SIZE(ksvgLightingDistantDiffuseRowSse2)
