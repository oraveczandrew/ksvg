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

/* x86-32 AVX-512F distant-light diffuse kernel. cdecl ABI. */
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
.p2align 6
.globl SYM(ksvgLightingDistantDiffuseAvx512)
TYPE(SYM(ksvgLightingDistantDiffuseAvx512), @function)
SYM(ksvgLightingDistantDiffuseAvx512):
    push    %ebp
    mov     %esp, %ebp
    push    %esi
    push    %edi
    push    %ebx

    mov     8(%ebp), %esi
    mov     12(%ebp), %edi
    mov     16(%ebp), %ebx
    mov     20(%ebp), %ecx

    vbroadcastss 24(%ebp), %zmm6    # invDx
    vbroadcastss 28(%ebp), %zmm7    # invDy
    vbroadcastss 32(%ebp), %zmm8    # k
    vbroadcastss 36(%ebp), %zmm9    # lx
    vbroadcastss 40(%ebp), %zmm10   # ly
    vbroadcastss 44(%ebp), %zmm11   # lz

    mov     48(%ebp), %edx

    vbroadcastss .Ltwo, %zmm4
    vpxorq  %zmm5, %zmm5, %zmm5     # zero
    vbroadcastss .Lone, %zmm12

.Lloop:
    test    %ecx, %ecx
    jz      .Ldone

    vmovups 0(%esi), %zmm0
    vmovups 4(%esi), %zmm1
    vmovups 8(%esi), %zmm2
    vmovups 0(%edi), %zmm3
    vmovups 4(%edi), %zmm13
    vmovups 8(%edi), %zmm14

    vmulps  %zmm4, %zmm3, %zmm15
    vaddps  %zmm0, %zmm15, %zmm15
    vmovups 0(%ebx), %zmm3
    vaddps  %zmm3, %zmm15, %zmm15   # sumL

    vmulps  %zmm4, %zmm14, %zmm3
    vaddps  %zmm2, %zmm3, %zmm3
    vmovups 8(%ebx), %zmm14
    vaddps  %zmm14, %zmm3, %zmm3    # sumR

    vmovups 4(%ebx), %zmm14
    vmulps  %zmm4, %zmm14, %zmm14
    vmovups 0(%ebx), %zmm2
    vaddps  %zmm2, %zmm14, %zmm14
    vmovups 8(%ebx), %zmm2
    vaddps  %zmm2, %zmm14, %zmm14   # sumB

    vmulps  %zmm4, %zmm1, %zmm1
    vaddps  %zmm0, %zmm1, %zmm1
    vmovups 8(%esi), %zmm0
    vaddps  %zmm0, %zmm1, %zmm1     # sumT

    vsubps  %zmm15, %zmm3, %zmm3
    vdivps  %zmm6, %zmm3, %zmm3     # dx
    vsubps  %zmm1, %zmm14, %zmm14
    vdivps  %zmm7, %zmm14, %zmm14    # dy

    vsubps  %zmm3, %zmm5, %zmm0     # nx
    vsubps  %zmm14, %zmm5, %zmm1    # ny

    vmulps  %zmm0, %zmm0, %zmm2
    vmulps  %zmm1, %zmm1, %zmm1
    vaddps  %zmm1, %zmm2, %zmm2
    vaddps  %zmm12, %zmm2, %zmm2    # nLen^2
    vsqrtps %zmm2, %zmm2           # nLen

    vdivps  %zmm2, %zmm0, %zmm0
    vdivps  %zmm2, %zmm1, %zmm1
    vdivps  %zmm2, %zmm12, %zmm3    # nz

    vmulps  %zmm9, %zmm0, %zmm0
    vmulps  %zmm10, %zmm1, %zmm1
    vmulps  %zmm11, %zmm3, %zmm3
    vaddps  %zmm1, %zmm0, %zmm0
    vaddps  %zmm3, %zmm0, %zmm0

    vmaxps  %zmm5, %zmm0, %zmm0
    vmulps  %zmm8, %zmm0, %zmm0
    vminps  %zmm12, %zmm0, %zmm0

    vmovups %zmm0, (%edx)

    add     $64, %esi
    add     $64, %edi
    add     $64, %ebx
    add     $64, %edx
    sub     $16, %ecx
    jnz     .Lloop

.Ldone:
    vzeroupper
    pop     %ebx
    pop     %edi
    pop     %esi
    pop     %ebp
    ret

.section .rodata
.p2align 6
.Lone:  .float 1.0
.Ltwo:  .float 2.0

SIZE(SYM(ksvgLightingDistantDiffuseAvx512))
