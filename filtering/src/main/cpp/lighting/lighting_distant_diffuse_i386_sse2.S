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

/* x86-32 SSE2 distant-light diffuse kernel. cdecl ABI. */
#include "asm_macros.S"


.text
.code32
.p2align 4
.globl SYM(ksvgLightingDistantDiffuseRowSse2)
TYPE(SYM(ksvgLightingDistantDiffuseRowSse2), @function)
SYM(ksvgLightingDistantDiffuseRowSse2):
    push    %ebp
    mov     %esp, %ebp
    push    %esi
    push    %edi
    push    %ebx
    and     $-16, %esp      # 16-byte align: i386 entry esp is 12 mod 16
    sub     $128, %esp

    mov     8(%ebp), %esi
    mov     12(%ebp), %edi
    mov     16(%ebp), %ebx
    mov     24(%ebp), %ecx
    mov     28(%ebp), %eax

    // --- Constants ---
    mov     $0x3f800000, %edx  # 1.0
    movd    %edx, %xmm0
    shufps  $0, %xmm0, %xmm0
    movaps  %xmm0, 64(%esp)

    mov     $0x3f000000, %edx  # 0.5
    movd    %edx, %xmm0
    shufps  $0, %xmm0, %xmm0
    movaps  %xmm0, 80(%esp)

    mov     $0x3fc00000, %edx  # 1.5
    movd    %edx, %xmm0
    shufps  $0, %xmm0, %xmm0
    movaps  %xmm0, 48(%esp)

    mov     $0x40000000, %edx  # 2.0
    movd    %edx, %xmm6
    shufps  $0, %xmm6, %xmm6
    movaps  %xmm6, 96(%esp)    # 96(esp) = 2.0 (frees xmm6 as scratch for i386)

    // Precalculate Scales
    movaps  64(%esp), %xmm0    # 1.0
    divss   0(%eax), %xmm0
    shufps  $0, %xmm0, %xmm0
    movss   36(%eax), %xmm1    # ss
    shufps  $0, %xmm1, %xmm1
    mulps   %xmm1, %xmm0
    movaps  %xmm0, 0(%esp)     # scaleX = (1/invDx)*ss (raw alpha heights, no /255)

    movaps  64(%esp), %xmm0    # 1.0
    divss   4(%eax), %xmm0
    shufps  $0, %xmm0, %xmm0
    mulps   %xmm1, %xmm0
    movaps  %xmm0, 16(%esp)    # scaleY = (1/invDy)*ss

    movss   8(%eax), %xmm0     # k
    shufps  $0, %xmm0, %xmm0
    movaps  %xmm0, 32(%esp)

    movss   12(%eax), %xmm3    # lx
    shufps  $0, %xmm3, %xmm3
    movss   16(%eax), %xmm4    # ly
    shufps  $0, %xmm4, %xmm4
    movss   20(%eax), %xmm5    # lz
    shufps  $0, %xmm5, %xmm5

    mov     20(%ebp), %edx     # dst pointer

.Lloop:
    test    %ecx, %ecx
    jz      .Ldone

    // --- Sobel Gradient ---
    movups  0(%esi), %xmm0
    psrld   $24, %xmm0
    cvtdq2ps %xmm0, %xmm0      # h_lT

    movups  8(%esi), %xmm2
    psrld   $24, %xmm2
    cvtdq2ps %xmm2, %xmm2      # h_rT

    movaps  %xmm2, %xmm7
    subps   %xmm0, %xmm7       # dx_rel

    movups  4(%esi), %xmm1
    psrld   $24, %xmm1
    cvtdq2ps %xmm1, %xmm1      # h_mT
    mulps   96(%esp), %xmm1
    addps   %xmm0, %xmm1
    addps   %xmm2, %xmm1       # sumT_rel in xmm1

    // Row M
    movups  0(%edi), %xmm0
    psrld   $24, %xmm0
    cvtdq2ps %xmm0, %xmm0
    movups  8(%edi), %xmm2
    psrld   $24, %xmm2
    cvtdq2ps %xmm2, %xmm2
    subps   %xmm0, %xmm2
    mulps   96(%esp), %xmm2
    addps   %xmm2, %xmm7       # dx_rel

    // Row B
    movups  0(%ebx), %xmm0
    psrld   $24, %xmm0
    cvtdq2ps %xmm0, %xmm0
    movups  8(%ebx), %xmm2
    psrld   $24, %xmm2
    cvtdq2ps %xmm2, %xmm2
    movaps  %xmm2, %xmm6
    subps   %xmm0, %xmm6
    addps   %xmm6, %xmm7      # final dx_rel

    movups  4(%ebx), %xmm6
    psrld   $24, %xmm6
    cvtdq2ps %xmm6, %xmm6
    mulps   96(%esp), %xmm6
    addps   %xmm0, %xmm6
    addps   %xmm2, %xmm6      # sumB_rel

    subps   %xmm1, %xmm6      # dy_rel

    mulps   0(%esp), %xmm7     # dx
    mulps   16(%esp), %xmm6    # dy

    // n = (-dx, -dy, 1)
    xorps   %xmm0, %xmm0
    subps   %xmm7, %xmm0       # nx
    xorps   %xmm1, %xmm1
    subps   %xmm6, %xmm1      # ny

    movaps  %xmm0, %xmm2
    mulps   %xmm0, %xmm2
    movaps  %xmm1, %xmm7
    mulps   %xmm1, %xmm7
    addps   %xmm7, %xmm2
    addps   64(%esp), %xmm2    # nLen^2

    rsqrtps %xmm2, %xmm7       # estimate
    movaps  %xmm7, %xmm6
    mulps   %xmm7, %xmm6
    mulps   %xmm2, %xmm6
    mulps   80(%esp), %xmm6   # 0.5 * x * r^2
    movaps  48(%esp), %xmm2    # 1.5
    subps   %xmm6, %xmm2
    mulps   %xmm7, %xmm2       # 1/nLen in xmm2

    mulps   %xmm2, %xmm0       # nx
    mulps   %xmm2, %xmm1       # ny
    # nz = xmm2

    mulps   %xmm3, %xmm0
    mulps   %xmm4, %xmm1
    addps   %xmm1, %xmm0
    mulps   %xmm5, %xmm2
    addps   %xmm2, %xmm0       # dot

    xorps   %xmm1, %xmm1
    maxps   %xmm1, %xmm0
    mulps   32(%esp), %xmm0    # intensity
    minps   64(%esp), %xmm0

    // Pack to ARGB
    mov     28(%ebp), %eax     # reload params
    movss   24(%eax), %xmm1    # lr
    shufps  $0, %xmm1, %xmm1
    mulps   %xmm0, %xmm1
    addps   80(%esp), %xmm1    # +0.5
    cvttps2dq %xmm1, %xmm1

    movss   28(%eax), %xmm2    # lg
    shufps  $0, %xmm2, %xmm2
    mulps   %xmm0, %xmm2
    addps   80(%esp), %xmm2    # +0.5
    cvttps2dq %xmm2, %xmm2

    movss   32(%eax), %xmm6   # lb
    shufps  $0, %xmm6, %xmm6
    mulps   %xmm0, %xmm6
    addps   80(%esp), %xmm6   # +0.5
    cvttps2dq %xmm6, %xmm6

    pslld   $16, %xmm1
    pslld   $8, %xmm2
    por     %xmm1, %xmm6
    por     %xmm2, %xmm6
    mov     $0xFF000000, %eax
    movd    %eax, %xmm0
    shufps  $0, %xmm0, %xmm0
    por     %xmm0, %xmm6

    movups  %xmm6, (%edx)

    add     $16, %esi
    add     $16, %edi
    add     $16, %ebx
    add     $16, %edx
    sub     $4, %ecx
    jnz     .Lloop

.Ldone:
    lea     -12(%ebp), %esp # saved regs sit at ebp-12..ebp (the `and -16` dropped stack)
    pop     %ebx
    pop     %edi
    pop     %esi
    pop     %ebp
    ret

//// SIZE(SYM(ksvgLightingDistantDiffuseRowSse2))
