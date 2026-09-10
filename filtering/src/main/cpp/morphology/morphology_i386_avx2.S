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

/* x86-32 / AVX2, cdecl ABI. Interior-only morphology. */
#include "asm_macros.S"

.text
.code32
.p2align 5

/* Row(src,dst,width,rx,ry,erode,y,xStart,xEnd,scratch) */
.globl SYM(ksvgMorphologyApplyRowAvx2)
TYPE(SYM(ksvgMorphologyApplyRowAvx2),@function)
SYM(ksvgMorphologyApplyRowAvx2):
    push %ebp; mov %esp,%ebp; push %ebx; push %esi; push %edi; sub $48,%esp
    # locals same layout as SSE2 file.
    mov 8(%ebp),%eax; mov %eax,-4(%ebp)
    mov 12(%ebp),%eax; mov %eax,-8(%ebp)
    mov 44(%ebp),%eax; mov %eax,-12(%ebp)
    mov 16(%ebp),%eax; shl $2,%eax; mov %eax,-16(%ebp)
    mov 24(%ebp),%eax; lea 1(%eax,%eax),%eax; mov %eax,-20(%ebp)
    mov 36(%ebp),%eax; sub 20(%ebp),%eax; mov %eax,-24(%ebp)
    mov 40(%ebp),%eax; sub 36(%ebp),%eax; mov %eax,-40(%ebp)
    mov -40(%ebp),%eax; mov 20(%ebp),%edx; lea (%eax,%edx,2),%eax; mov %eax,-28(%ebp)
    mov -28(%ebp),%eax; mov %eax,%edx; shr $3,%eax; and $7,%edx; mov %eax,-32(%ebp); mov %edx,-36(%ebp)
    mov 20(%ebp),%eax; lea 1(%eax,%eax),%eax; mov %eax,-44(%ebp)
    mov 32(%ebp),%eax; sub 24(%ebp),%eax; imul 16(%ebp),%eax; add -24(%ebp),%eax
    mov 8(%ebp),%edx; lea (%edx,%eax,4),%edx; mov %edx,-4(%ebp)
    cmpl $0,28(%ebp); jne .Lra32_evert

.Lra32_dvert:
    mov -12(%ebp),%edi; mov -32(%ebp),%esi
.Lra32_dg:
    test %esi,%esi; jz .Lra32_dt
    vpxor %ymm0,%ymm0,%ymm0; mov -4(%ebp),%eax; mov -20(%ebp),%ecx
.Lra32_dr:
    vmovdqu (%eax),%ymm1; vpmaxub %ymm1,%ymm0,%ymm0; add -16(%ebp),%eax; dec %ecx; jnz .Lra32_dr
    vmovdqu %ymm0,(%edi); add $32,%edi; addl $32,-4(%ebp); dec %esi; jmp .Lra32_dg
.Lra32_dt:
    mov -36(%ebp),%esi; test %esi,%esi; jz .Lra32_hmax
.Lra32_dtc:
    vpxor %ymm0,%ymm0,%ymm0; mov -4(%ebp),%eax; mov -20(%ebp),%ecx
.Lra32_dtr:
    mov (%eax),%edx; vmovd %edx,%xmm1; vpbroadcastd %xmm1,%ymm1; vpmaxub %ymm1,%ymm0,%ymm0
    add -16(%ebp),%eax; dec %ecx; jnz .Lra32_dtr
    vmovd %xmm0,%edx; mov %edx,(%edi); add $4,%edi; addl $4,-4(%ebp); dec %esi; jnz .Lra32_dtc
    jmp .Lra32_hmax
.Lra32_evert:
    mov -12(%ebp),%edi; mov -32(%ebp),%esi
.Lra32_eg:
    test %esi,%esi; jz .Lra32_et
    vpcmpeqd %ymm0,%ymm0,%ymm0; mov -4(%ebp),%eax; mov -20(%ebp),%ecx
.Lra32_er:
    vmovdqu (%eax),%ymm1; vpminub %ymm1,%ymm0,%ymm0; add -16(%ebp),%eax; dec %ecx; jnz .Lra32_er
    vmovdqu %ymm0,(%edi); add $32,%edi; addl $32,-4(%ebp); dec %esi; jmp .Lra32_eg
.Lra32_et:
    mov -36(%ebp),%esi; test %esi,%esi; jz .Lra32_hmin
.Lra32_etc:
    vpcmpeqd %ymm0,%ymm0,%ymm0; mov -4(%ebp),%eax; mov -20(%ebp),%ecx
.Lra32_etr:
    mov (%eax),%edx; vmovd %edx,%xmm1; vpbroadcastd %xmm1,%ymm1; vpminub %ymm1,%ymm0,%ymm0
    add -16(%ebp),%eax; dec %ecx; jnz .Lra32_etr
    vmovd %xmm0,%edx; mov %edx,(%edi); add $4,%edi; addl $4,-4(%ebp); dec %esi; jnz .Lra32_etc

.Lra32_hmax:
    mov -40(%ebp),%ecx; mov 12(%ebp),%eax; mov 32(%ebp),%edx; imul 16(%ebp),%edx; add 36(%ebp),%edx; lea (%eax,%edx,4),%eax; mov %eax,-8(%ebp)
    mov -12(%ebp),%edi
.Lra32_hmax_px:
    vpxor %ymm0,%ymm0,%ymm0; mov %edi,%eax; mov -44(%ebp),%edx; shr $3,%edx
.Lra32_hmax_vec:
    test %edx,%edx; jz .Lra32_hmax_tail
    vmovdqu (%eax),%ymm1; vpmaxub %ymm1,%ymm0,%ymm0; add $32,%eax; dec %edx; jnz .Lra32_hmax_vec
.Lra32_hmax_tail:
    mov -44(%ebp),%edx; and $7,%edx
.Lra32_hmax_t:
    test %edx,%edx; jz .Lra32_hmax_red
    mov (%eax),%ebx; vmovd %ebx,%xmm1; vpbroadcastd %xmm1,%ymm1; vpmaxub %ymm1,%ymm0,%ymm0; add $4,%eax; dec %edx; jmp .Lra32_hmax_t
.Lra32_hmax_red:
    vextracti128 $1,%ymm0,%xmm1
    vpsrldq $8,%xmm0,%xmm2; vpmaxub %xmm2,%xmm0,%xmm0; vpsrldq $4,%xmm0,%xmm2; vpmaxub %xmm2,%xmm0,%xmm0
    vpsrldq $8,%xmm1,%xmm2; vpmaxub %xmm2,%xmm1,%xmm1; vpsrldq $4,%xmm1,%xmm2; vpmaxub %xmm2,%xmm1,%xmm1
    vpmaxub %xmm1,%xmm0,%xmm0
    vmovd %xmm0,%eax; mov -8(%ebp),%edx; mov %eax,(%edx); add $4,%edx; mov %edx,-8(%ebp); add $4,%edi; dec %ecx; jnz .Lra32_hmax_px
    jmp .Lra32_done
.Lra32_hmin:
    mov -40(%ebp),%ecx; mov 12(%ebp),%eax; mov 32(%ebp),%edx; imul 16(%ebp),%edx; add 36(%ebp),%edx; lea (%eax,%edx,4),%eax; mov %eax,-8(%ebp); mov -12(%ebp),%edi
.Lra32_hmin_px:
    vpcmpeqd %ymm0,%ymm0,%ymm0; mov %edi,%eax; mov -44(%ebp),%edx; shr $3,%edx
.Lra32_hmin_vec:
    test %edx,%edx; jz .Lra32_hmin_tail
    vmovdqu (%eax),%ymm1; vpminub %ymm1,%ymm0,%ymm0; add $32,%eax; dec %edx; jnz .Lra32_hmin_vec
.Lra32_hmin_tail:
    mov -44(%ebp),%edx; and $7,%edx
.Lra32_hmin_t:
    test %edx,%edx; jz .Lra32_hmin_red
    mov (%eax),%ebx; vmovd %ebx,%xmm1; vpbroadcastd %xmm1,%ymm1; vpminub %ymm1,%ymm0,%ymm0; add $4,%eax; dec %edx; jmp .Lra32_hmin_t
.Lra32_hmin_red:
    vextracti128 $1,%ymm0,%xmm1
    vpsrldq $8,%xmm0,%xmm2; vpminub %xmm2,%xmm0,%xmm0; vpsrldq $4,%xmm0,%xmm2; vpminub %xmm2,%xmm0,%xmm0
    vpsrldq $8,%xmm1,%xmm2; vpminub %xmm2,%xmm1,%xmm1; vpsrldq $4,%xmm1,%xmm2; vpminub %xmm2,%xmm1,%xmm1
    vpminub %xmm1,%xmm0,%xmm0
    vmovd %xmm0,%eax; mov -8(%ebp),%edx; mov %eax,(%edx); add $4,%edx; mov %edx,-8(%ebp); add $4,%edi; dec %ecx; jnz .Lra32_hmin_px
.Lra32_done:
    vzeroupper; add $48,%esp; pop %edi; pop %esi; pop %ebx; pop %ebp; ret
//// SIZE(SYM(ksvgMorphologyApplyRowAvx2))
