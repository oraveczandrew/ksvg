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

/* x86-32 AVX2 distant-light diffuse kernel. cdecl ABI. */
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
.p2align 5
.globl SYM(ksvgLightingDistantDiffuseAvx2)
TYPE(SYM(ksvgLightingDistantDiffuseAvx2), @function)
SYM(ksvgLightingDistantDiffuseAvx2):
    push    %ebp
    mov     %esp, %ebp
    push    %esi
    push    %edi
    push    %ebx

    mov     8(%ebp), %esi
    mov     12(%ebp), %edi
    mov     16(%ebp), %ebx
    mov     20(%ebp), %ecx

    vbroadcastss 24(%ebp), %ymm6    # invDx
    vbroadcastss 28(%ebp), %ymm7    # invDy
    vbroadcastss 32(%ebp), %ymm8    # k
    vbroadcastss 36(%ebp), %ymm9    # lx
    vbroadcastss 40(%ebp), %ymm10   # ly
    vbroadcastss 44(%ebp), %ymm11   # lz

    mov     48(%ebp), %edx

    vbroadcastss .Ltwo, %ymm4
    vxorps  %ymm5, %ymm5, %ymm5     # zero
    vbroadcastss .Lone, %ymm12

.Lloop:
    test    %ecx, %ecx
    jz      .Ldone

    vmovups 0(%esi), %ymm0
    vmovups 4(%esi), %ymm1
    vmovups 8(%esi), %ymm2
    vmovups 0(%edi), %ymm3
    vmovups 4(%edi), %ymm13
    vmovups 8(%edi), %ymm14

    vmulps  %ymm4, %ymm3, %ymm15
    vaddps  %ymm0, %ymm15, %ymm15
    vmovups 0(%ebx), %ymm3
    vaddps  %ymm3, %ymm15, %ymm15   # sumL

    vmulps  %ymm4, %ymm14, %ymm3
    vaddps  %ymm2, %ymm3, %ymm3
    vmovups 8(%ebx), %ymm14
    vaddps  %ymm14, %ymm3, %ymm3    # sumR

    vmovups 4(%ebx), %ymm14
    vmulps  %ymm4, %ymm14, %ymm14
    vmovups 0(%ebx), %ymm2
    vaddps  %ymm2, %ymm14, %ymm14
    vmovups 8(%ebx), %ymm2
    vaddps  %ymm2, %ymm14, %ymm14   # sumB

    vmulps  %ymm4, %ymm1, %ymm1
    vaddps  %ymm0, %ymm1, %ymm1
    vmovups 8(%esi), %ymm0
    vaddps  %ymm0, %ymm1, %ymm1     # sumT

    vsubps  %ymm15, %ymm3, %ymm3
    vdivps  %ymm6, %ymm3, %ymm3     # dx
    vsubps  %ymm1, %ymm14, %ymm14
    vdivps  %ymm7, %ymm14, %ymm14    # dy

    vsubps  %ymm3, %ymm5, %ymm0     # nx
    vsubps  %ymm14, %ymm5, %ymm1    # ny

    vmulps  %ymm0, %ymm0, %ymm2
    vmla.f32 %ymm2, %ymm1, %ymm1    # wait, vmla is not for x86. Use vmulps + vaddps or vfmadd if supported.
                                    # AVX2 doesn't guarantee FMA unless specifically checked.
                                    # The project uses -ffp-contract=off for bit-exactness, so better avoid FMA.
    vmulps  %ymm1, %ymm1, %ymm1
    vaddps  %ymm1, %ymm2, %ymm2
    vaddps  %ymm12, %ymm2, %ymm2    # nLen^2
    vsqrtps %ymm2, %ymm2           # nLen

    vdivps  %ymm2, %ymm0, %ymm0
    vdivps  %ymm2, %ymm1, %ymm1
    vdivps  %ymm2, %ymm12, %ymm3    # nz

    vmulps  %ymm9, %ymm0, %ymm0
    vmulps  %ymm10, %ymm1, %ymm1
    vmulps  %ymm11, %ymm3, %ymm3
    vaddps  %ymm1, %ymm0, %ymm0
    vaddps  %ymm3, %ymm0, %ymm0

    vmaxps  %ymm5, %ymm0, %ymm0
    vmulps  %ymm8, %ymm0, %ymm0
    vminps  %ymm12, %ymm0, %ymm0

    vmovups %ymm0, (%edx)

    add     $32, %esi
    add     $32, %edi
    add     $32, %ebx
    add     $32, %edx
    sub     $8, %ecx
    jnz     .Lloop

.Ldone:
    vzeroupper
    pop     %ebx
    pop     %edi
    pop     %esi
    pop     %ebp
    ret

.section .rodata
.p2align 5
.Lone:  .float 1.0
.Ltwo:  .float 2.0

SIZE(SYM(ksvgLightingDistantDiffuseAvx2))
