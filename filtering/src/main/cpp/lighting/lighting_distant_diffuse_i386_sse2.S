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

/* x86-32 SSE2 distant-light diffuse kernel. cdecl ABI.
 * void ksvgLightingDistantDiffuseSse2(const float* ht, const float* hm, const float* hb,
 *   int count, float invDx, float invDy, float k, float lx, float ly, float lz, float* out);
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
.code32
.p2align 4
.globl SYM(ksvgLightingDistantDiffuseSse2)
TYPE(SYM(ksvgLightingDistantDiffuseSse2), @function)
SYM(ksvgLightingDistantDiffuseSse2):
    push    %ebp
    mov     %esp, %ebp
    push    %esi
    push    %edi
    push    %ebx

    mov     8(%ebp), %esi      # ht
    mov     12(%ebp), %edi     # hm
    mov     16(%ebp), %ebx     # hb
    mov     20(%ebp), %ecx     # count

    movss   24(%ebp), %xmm6    # invDx
    shufps  $0, %xmm6, %xmm6
    movss   28(%ebp), %xmm7    # invDy
    shufps  $0, %xmm7, %xmm7
    movss   32(%ebp), %xmm8    # k
    shufps  $0, %xmm8, %xmm8
    movss   36(%ebp), %xmm9    # lx
    shufps  $0, %xmm9, %xmm9
    movss   40(%ebp), %xmm10   # ly
    shufps  $0, %xmm10, %xmm10
    movss   44(%ebp), %xmm11   # lz
    shufps  $0, %xmm11, %xmm11

    mov     48(%ebp), %edx     # out

    movaps  .Ltwo, %xmm4
    movaps  .Lzero, %xmm5
    movaps  .Lone, %xmm12

.Lloop:
    test    %ecx, %ecx
    jz      .Ldone

    movups  0(%esi), %xmm0     # lT
    movups  4(%esi), %xmm1     # mT
    movups  8(%esi), %xmm2     # rT
    movups  0(%edi), %xmm3     # lM
    movups  4(%edi), %xmm13    # mM
    movups  8(%edi), %xmm14    # rM

    # sumL = lT + 2*lM + lB
    movaps  %xmm3, %xmm15
    mulps   %xmm4, %xmm15
    addps   %xmm0, %xmm15
    movups  0(%ebx), %xmm3
    addps   %xmm3, %xmm15      # sumL

    # sumR = rT + 2*rM + rB
    movaps  %xmm14, %xmm3
    mulps   %xmm4, %xmm3
    addps   %xmm2, %xmm3
    movups  8(%ebx), %xmm14
    addps   %xmm14, %xmm3      # sumR

    # sumB = lB + 2*mB + rB
    movups  4(%ebx), %xmm14
    mulps   %xmm4, %xmm14
    movups  0(%ebx), %xmm2
    addps   %xmm2, %xmm14
    movups  8(%ebx), %xmm2
    addps   %xmm2, %xmm14      # sumB

    # sumT = lT + 2*mT + rT
    mulps   %xmm4, %xmm1
    addps   %xmm0, %xmm1
    movups  8(%esi), %xmm0
    addps   %xmm0, %xmm1      # sumT

    # dzdx = (sumR - sumL) / invDx
    subps   %xmm15, %xmm3
    divps   %xmm6, %xmm3       # dx

    # dzdy = (sumB - sumT) / invDy
    subps   %xmm1, %xmm14
    divps   %xmm7, %xmm14      # dy

    # n = (-dx, -dy, 1), nLen = sqrt(dx²+dy²+1)
    movaps  %xmm5, %xmm0
    subps   %xmm3, %xmm0       # nx
    movaps  %xmm5, %xmm1
    subps   %xmm14, %xmm1      # ny

    movaps  %xmm0, %xmm2
    mulps   %xmm0, %xmm2
    mulps   %xmm1, %xmm1
    addps   %xmm1, %xmm2
    addps   %xmm12, %xmm2      # nLen^2
    sqrtps  %xmm2, %xmm2       # nLen

    # nx/nLen, ny/nLen, nz/nLen
    divps   %xmm2, %xmm0
    divps   %xmm2, %xmm1
    movaps  %xmm12, %xmm3
    divps   %xmm2, %xmm3       # nz

    # dot = nx*lx + ny*ly + nz*lz
    mulps   %xmm9, %xmm0
    mulps   %xmm10, %xmm1
    mulps   %xmm11, %xmm3
    addps   %xmm1, %xmm0
    addps   %xmm3, %xmm0

    maxps   %xmm5, %xmm0
    mulps   %xmm8, %xmm0
    minps   %xmm12, %xmm0

    movups  %xmm0, (%edx)

    add     $16, %esi
    add     $16, %edi
    add     $16, %ebx
    add     $16, %edx
    sub     $4, %ecx
    jnz     .Lloop

.Ldone:
    pop     %ebx
    pop     %edi
    pop     %esi
    pop     %ebp
    ret

#ifdef __APPLE__
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 4
.Lzero: .float 0.0, 0.0, 0.0, 0.0
.Lone:  .float 1.0, 1.0, 1.0, 1.0
.Ltwo:  .float 2.0, 2.0, 2.0, 2.0

SIZE(SYM(ksvgLightingDistantDiffuseSse2))
