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

#include "asm_macros.S"


.text
.p2align 5
.LvA:
.byte 0,0x80,0x80,0x80, 4,0x80,0x80,0x80, 8,0x80,0x80,0x80, 12,0x80,0x80,0x80
.byte 0,0x80,0x80,0x80, 4,0x80,0x80,0x80, 8,0x80,0x80,0x80, 12,0x80,0x80,0x80
.p2align 5
.LvR:
.byte 1,0x80,0x80,0x80, 5,0x80,0x80,0x80, 9,0x80,0x80,0x80, 13,0x80,0x80,0x80
.byte 1,0x80,0x80,0x80, 5,0x80,0x80,0x80, 9,0x80,0x80,0x80, 13,0x80,0x80,0x80
.p2align 5
.LvG:
.byte 2,0x80,0x80,0x80, 6,0x80,0x80,0x80, 10,0x80,0x80,0x80, 14,0x80,0x80,0x80
.byte 2,0x80,0x80,0x80, 6,0x80,0x80,0x80, 10,0x80,0x80,0x80, 14,0x80,0x80,0x80
.p2align 5
.LvB:
.byte 3,0x80,0x80,0x80, 7,0x80,0x80,0x80, 11,0x80,0x80,0x80, 15,0x80,0x80,0x80
.byte 3,0x80,0x80,0x80, 7,0x80,0x80,0x80, 11,0x80,0x80,0x80, 15,0x80,0x80,0x80
.p2align 5
.Lhpack:
.byte 0,4,8,12, 0x80,0x80,0x80,0x80, 0x80,0x80,0x80,0x80, 0x80,0x80,0x80,0x80
.byte 0,4,8,12, 0x80,0x80,0x80,0x80, 0x80,0x80,0x80,0x80, 0x80,0x80,0x80,0x80

.globl SYM(ksvgBlurVerticalAvx2_i386)
TYPE(SYM(ksvgBlurVerticalAvx2_i386),@function)
SYM(ksvgBlurVerticalAvx2_i386):
    pushl %ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    # locals: 0..31 A mask, 32..63 R, 64..95 G, 96..127 B, 128=x2, 132=row0 source
    subl $136, %esp
    # 156=dst 160=pin 164=stride 168=gptr 172=rct 176=x1 180=x2
    movl 156(%esp), %edi
    movl 160(%esp), %esi
    movl 164(%esp), %edx
    movl 168(%esp), %ecx
    movl 172(%esp), %ebx
    movl 176(%esp), %ebp
    movl 180(%esp), %eax
    movl %eax, 128(%esp)
    leal (%esi,%ebp,4), %esi

    call 1f
1:  popl %eax
    leal (.LvA-1b)(%eax), %eax
    vmovdqu (%eax), %ymm4
    vmovdqu %ymm4, 0(%esp)
    leal (.LvR-.LvA)(%eax), %eax
    vmovdqu (%eax), %ymm4
    vmovdqu %ymm4, 32(%esp)
    leal (.LvG-.LvR)(%eax), %eax
    vmovdqu (%eax), %ymm4
    vmovdqu %ymm4, 64(%esp)
    leal (.LvB-.LvG)(%eax), %eax
    vmovdqu (%eax), %ymm4
    vmovdqu %ymm4, 96(%esp)

    cmpl 128(%esp), %ebp
    jge .AV_done
.AV_group:
    movl %esi, 132(%esp)
    vxorps %ymm0,%ymm0,%ymm0
    vxorps %ymm1,%ymm1,%ymm1
    vxorps %ymm2,%ymm2,%ymm2
    vxorps %ymm3,%ymm3,%ymm3

    movl 168(%esp), %ecx
    leal (%ecx,%ebx,4), %eax             # weight end
.AV_row:
    vbroadcastss (%ecx), %ymm4
    vmovdqu (%esi), %ymm5

    vpshufb 0(%esp), %ymm5, %ymm6
    vcvtdq2ps %ymm6, %ymm6
    vmulps %ymm4, %ymm6, %ymm6
    vaddps %ymm6, %ymm0, %ymm0

    vpshufb 32(%esp), %ymm5, %ymm6
    vcvtdq2ps %ymm6, %ymm6
    vmulps %ymm4, %ymm6, %ymm6
    vaddps %ymm6, %ymm1, %ymm1

    vpshufb 64(%esp), %ymm5, %ymm6
    vcvtdq2ps %ymm6, %ymm6
    vmulps %ymm4, %ymm6, %ymm6
    vaddps %ymm6, %ymm2, %ymm2

    vpshufb 96(%esp), %ymm5, %ymm6
    vcvtdq2ps %ymm6, %ymm6
    vmulps %ymm4, %ymm6, %ymm6
    vaddps %ymm6, %ymm3, %ymm3

    addl %edx, %esi
    addl $4, %ecx
    cmpl %eax, %ecx
    jne .AV_row

    vunpcklps %ymm1,%ymm0,%ymm4
    vunpckhps %ymm1,%ymm0,%ymm5
    vunpcklps %ymm3,%ymm2,%ymm6
    vunpckhps %ymm3,%ymm2,%ymm7
    vshufps $0x44,%ymm6,%ymm4,%ymm0
    vshufps $0xEE,%ymm6,%ymm4,%ymm1
    vshufps $0x44,%ymm7,%ymm5,%ymm2
    vshufps $0xEE,%ymm7,%ymm5,%ymm3
    vmovups %xmm0,0(%edi)
    vmovups %xmm1,16(%edi)
    vmovups %xmm2,32(%edi)
    vmovups %xmm3,48(%edi)
    vextractf128 $1,%ymm0,%xmm0
    vextractf128 $1,%ymm1,%xmm1
    vextractf128 $1,%ymm2,%xmm2
    vextractf128 $1,%ymm3,%xmm3
    vmovups %xmm0,64(%edi)
    vmovups %xmm1,80(%edi)
    vmovups %xmm2,96(%edi)
    vmovups %xmm3,112(%edi)

    movl 132(%esp), %esi
    addl $8,%esi
    addl $128,%edi
    addl $8,%ebp
    cmpl 128(%esp),%ebp
    jl .AV_group
.AV_done:
    vzeroupper
    addl $136,%esp
    popl %edi
    popl %esi
    popl %ebx
    popl %ebp
    ret
//// SIZE(SYM(ksvgBlurVerticalAvx2_i386))

.globl SYM(ksvgBlurHorizontalAvx2_i386)
TYPE(SYM(ksvgBlurHorizontalAvx2_i386),@function)
SYM(ksvgBlurHorizontalAvx2_i386):
    pushl %ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    subl $4, %esp
    # 24=dst 28=pin 32=gptr 36=rct 40=x1 44=x2
    movl 24(%esp), %edi
    movl 28(%esp), %esi
    movl 32(%esp), %edx
    movl 36(%esp), %ecx
    movl 40(%esp), %ebp
    movl 44(%esp), %ebx

    call 2f
2:  popl %eax
    leal (.Lhpack-2b)(%eax), %eax
    vmovdqu (%eax), %ymm7

    # current input = pin + x1*16
    leal (%esi,%ebp,8), %eax
    leal (%eax,%ebp,8), %esi

.AH_pair_check:
    movl %ebp, %eax
    incl %eax
    cmpl %ebx, %eax
    jge .AH_tail

    movl %ecx, %eax                     # remaining rows
    movl 32(%esp), %edx                 # weight pointer
    vbroadcastss (%edx), %ymm0
    vmulps (%esi), %ymm0, %ymm1
    addl $4, %edx
    addl $32, %esi
    decl %eax
    jz .AH_pair_store
.AH_row:
    vbroadcastss (%edx), %ymm0
    vmulps (%esi), %ymm0, %ymm2
    vaddps %ymm2, %ymm1, %ymm1
    addl $4, %edx
    addl $16, %esi
    decl %eax
    jnz .AH_row
.AH_pair_store:
    vcvtps2dq %ymm1,%ymm1
    vpshufb %ymm7,%ymm1,%ymm1
    vmovd %xmm1,(%edi)
    vextracti128 $1,%ymm1,%xmm2
    vmovd %xmm2,4(%edi)
    addl $8,%edi

    addl $2,%ebp
    # Reconstruct next pair source directly. This avoids carrying a row-end pointer.
    movl 28(%esp), %esi
    movl %ebp, %eax
    leal (%esi,%eax,8), %esi
    leal (%esi,%eax,8), %esi
    jmp .AH_pair_check

.AH_tail:
    cmpl %ebx,%ebp
    jge .AH_done
    movl 28(%esp), %esi
    movl %ebp,%eax
    leal (%esi,%eax,8),%esi
    leal (%esi,%eax,8),%esi
    movl 32(%esp),%edx
    movl %ecx,%eax
    vbroadcastss (%edx),%xmm0
    movups (%esi),%xmm1
    mulps %xmm0,%xmm1
    addl $4,%edx
    decl %eax
    jz .AH_tail_store
.AH_tail_row:
    addl $16,%esi
    movss (%edx),%xmm0
    shufps $0,%xmm0,%xmm0
    movups (%esi),%xmm2
    mulps %xmm0,%xmm2
    addps %xmm2,%xmm1
    addl $4,%edx
    decl %eax
    jnz .AH_tail_row
.AH_tail_store:
    cvtps2dq %xmm1,%xmm1
    pshufb %xmm7,%xmm1
    movd %xmm1,(%edi)
.AH_done:
    vzeroupper
    addl $4,%esp
    popl %edi
    popl %esi
    popl %ebx
    popl %ebp
    ret
//// SIZE(SYM(ksvgBlurHorizontalAvx2_i386))
GNU_STACK
