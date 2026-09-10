/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

/* x86-32 / AVX-512BW, cdecl ABI. Interior-only morphology. */
#include "asm_macros.S"

.text
.code32
.p2align 6

/* Row(src,dst,width,rx,ry,erode,y,xStart,xEnd,scratch) */
.globl SYM(ksvgMorphologyApplyRowAvx512)
TYPE(SYM(ksvgMorphologyApplyRowAvx512),@function)
SYM(ksvgMorphologyApplyRowAvx512):
    push %ebp; mov %esp,%ebp; push %ebx; push %esi; push %edi; sub $48,%esp
    mov 8(%ebp),%eax; mov %eax,-4(%ebp)
    mov 12(%ebp),%eax; mov %eax,-8(%ebp)
    mov 44(%ebp),%eax; mov %eax,-12(%ebp)
    mov 16(%ebp),%eax; shl $2,%eax; mov %eax,-16(%ebp)
    mov 24(%ebp),%eax; lea 1(%eax,%eax),%eax; mov %eax,-20(%ebp)
    mov 36(%ebp),%eax; sub 20(%ebp),%eax; mov %eax,-24(%ebp)
    mov 40(%ebp),%eax; sub 36(%ebp),%eax; mov %eax,-40(%ebp)
    mov -40(%ebp),%eax; mov 20(%ebp),%edx; lea (%eax,%edx,2),%eax; mov %eax,-28(%ebp)
    mov -28(%ebp),%eax; mov %eax,%edx; shr $4,%eax; and $15,%edx; mov %eax,-32(%ebp); mov %edx,-36(%ebp)
    mov 20(%ebp),%eax; lea 1(%eax,%eax),%eax; mov %eax,-44(%ebp)
    mov 32(%ebp),%eax; sub 24(%ebp),%eax; imul 16(%ebp),%eax; add -24(%ebp),%eax
    mov 8(%ebp),%edx; lea (%edx,%eax,4),%edx; mov %edx,-4(%ebp)
    cmpl $0,28(%ebp); jne .L512_e

.L512_d:
    mov -12(%ebp),%edi; mov -32(%ebp),%esi
.L512_dg:
    test %esi,%esi; jz .L512_dt
    vpxorq %zmm0,%zmm0,%zmm0; mov -4(%ebp),%eax; mov -20(%ebp),%ecx
.L512_dr:
    vmovdqu32 (%eax),%zmm1; vpmaxub %zmm1,%zmm0,%zmm0; add -16(%ebp),%eax; dec %ecx; jnz .L512_dr
    vmovdqu32 %zmm0,(%edi); add $64,%edi; addl $64,-4(%ebp); dec %esi; jmp .L512_dg
.L512_dt:
    mov -36(%ebp),%esi; test %esi,%esi; jz .L512_dh
.L512_dtc:
    vpxorq %zmm0,%zmm0,%zmm0; mov -4(%ebp),%eax; mov -20(%ebp),%ecx
.L512_dtr:
    mov (%eax),%edx; vmovd %edx,%xmm1; vpbroadcastd %xmm1,%zmm1; vpmaxub %zmm1,%zmm0,%zmm0
    add -16(%ebp),%eax; dec %ecx; jnz .L512_dtr
    vmovd %xmm0,%edx; mov %edx,(%edi); add $4,%edi; addl $4,-4(%ebp); dec %esi; jnz .L512_dtc
    jmp .L512_dh

.L512_e:
    mov -12(%ebp),%edi; mov -32(%ebp),%esi
.L512_eg:
    test %esi,%esi; jz .L512_et
    mov $-1,%eax; kmovd %eax,%k1; vpmovm2d %k1,%zmm0; mov -4(%ebp),%eax; mov -20(%ebp),%ecx
.L512_er:
    vmovdqu32 (%eax),%zmm1; vpminub %zmm1,%zmm0,%zmm0; add -16(%ebp),%eax; dec %ecx; jnz .L512_er
    vmovdqu32 %zmm0,(%edi); add $64,%edi; addl $64,-4(%ebp); dec %esi; jmp .L512_eg
.L512_et:
    mov -36(%ebp),%esi; test %esi,%esi; jz .L512_eh
.L512_etc:
    mov $-1,%eax; kmovd %eax,%k1; vpmovm2d %k1,%zmm0; mov -4(%ebp),%eax; mov -20(%ebp),%ecx
.L512_etr:
    mov (%eax),%edx; vmovd %edx,%xmm1; vpbroadcastd %xmm1,%zmm1; vpminub %zmm1,%zmm0,%zmm0
    add -16(%ebp),%eax; dec %ecx; jnz .L512_etr
    vmovd %xmm0,%edx; mov %edx,(%edi); add $4,%edi; addl $4,-4(%ebp); dec %esi; jnz .L512_etc

.L512_dh:
    mov -40(%ebp),%ecx; mov 12(%ebp),%eax; mov 32(%ebp),%edx; imul 16(%ebp),%edx; add 36(%ebp),%edx; lea (%eax,%edx,4),%eax; mov %eax,-8(%ebp); mov -12(%ebp),%edi
.L512_dh_px:
    vpxorq %zmm0,%zmm0,%zmm0; mov %edi,%eax; mov -44(%ebp),%edx; shr $4,%edx
.L512_dh_v:
    test %edx,%edx; jz .L512_dh_t
    vmovdqu32 (%eax),%zmm1; vpmaxub %zmm1,%zmm0,%zmm0; add $64,%eax; dec %edx; jnz .L512_dh_v
.L512_dh_t:
    mov -44(%ebp),%edx; and $15,%edx
.L512_dh_tl:
    test %edx,%edx; jz .L512_dh_r
    mov (%eax),%ebx; vmovd %ebx,%xmm1; vpbroadcastd %xmm1,%zmm1; vpmaxub %zmm1,%zmm0,%zmm0; add $4,%eax; dec %edx; jmp .L512_dh_tl
.L512_dh_r:
    vextracti64x4 $1,%zmm0,%ymm1; vpmaxub %ymm1,%ymm0,%ymm0; vextracti128 $1,%ymm0,%xmm1; vpmaxub %xmm1,%xmm0,%xmm0
    vpsrldq $8,%xmm0,%xmm1; vpmaxub %xmm1,%xmm0,%xmm0; vpsrldq $4,%xmm0,%xmm1; vpmaxub %xmm1,%xmm0,%xmm0
    vmovd %xmm0,%eax; mov -8(%ebp),%edx; mov %eax,(%edx); add $4,%edx; mov %edx,-8(%ebp); add $4,%edi; dec %ecx; jnz .L512_dh_px
    jmp .L512_done

.L512_eh:
    mov -40(%ebp),%ecx; mov 12(%ebp),%eax; mov 32(%ebp),%edx; imul 16(%ebp),%edx; add 36(%ebp),%edx; lea (%eax,%edx,4),%eax; mov %eax,-8(%ebp); mov -12(%ebp),%edi
.L512_eh_px:
    mov $-1,%eax; kmovd %eax,%k1; vpmovm2d %k1,%zmm0; mov %edi,%eax; mov -44(%ebp),%edx; shr $4,%edx
.L512_eh_v:
    test %edx,%edx; jz .L512_eh_t
    vmovdqu32 (%eax),%zmm1; vpminub %zmm1,%zmm0,%zmm0; add $64,%eax; dec %edx; jnz .L512_eh_v
.L512_eh_t:
    mov -44(%ebp),%edx; and $15,%edx
.L512_eh_tl:
    test %edx,%edx; jz .L512_eh_r
    mov (%eax),%ebx; vmovd %ebx,%xmm1; vpbroadcastd %xmm1,%zmm1; vpminub %zmm1,%zmm0,%zmm0; add $4,%eax; dec %edx; jmp .L512_eh_tl
.L512_eh_r:
    vextracti64x4 $1,%zmm0,%ymm1; vpminub %ymm1,%ymm0,%ymm0; vextracti128 $1,%ymm0,%xmm1; vpminub %xmm1,%xmm0,%xmm0
    vpsrldq $8,%xmm0,%xmm1; vpminub %xmm1,%xmm0,%xmm0; vpsrldq $4,%xmm0,%xmm1; vpminub %xmm1,%xmm0,%xmm0
    vmovd %xmm0,%eax; mov -8(%ebp),%edx; mov %eax,(%edx); add $4,%edx; mov %edx,-8(%ebp); add $4,%edi; dec %ecx; jnz .L512_eh_px

.L512_done:
    vzeroupper; add $48,%esp; pop %edi; pop %esi; pop %ebx; pop %ebp; ret
//// SIZE(SYM(ksvgMorphologyApplyRowAvx512))
