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
.p2align 4
.LvR:
.byte 1,0x80,0x80,0x80, 5,0x80,0x80,0x80, 9,0x80,0x80,0x80, 13,0x80,0x80,0x80
.byte 1,0x80,0x80,0x80, 5,0x80,0x80,0x80, 9,0x80,0x80,0x80, 13,0x80,0x80,0x80
.p2align 4
.LvG:
.byte 2,0x80,0x80,0x80, 6,0x80,0x80,0x80, 10,0x80,0x80,0x80, 14,0x80,0x80,0x80
.byte 2,0x80,0x80,0x80, 6,0x80,0x80,0x80, 10,0x80,0x80,0x80, 14,0x80,0x80,0x80
.p2align 4
.LvB:
.byte 3,0x80,0x80,0x80, 7,0x80,0x80,0x80, 11,0x80,0x80,0x80, 15,0x80,0x80,0x80
.byte 3,0x80,0x80,0x80, 7,0x80,0x80,0x80, 11,0x80,0x80,0x80, 15,0x80,0x80,0x80
.p2align 5
.Lhpack:
.byte 0,4,8,12, 0x80,0x80,0x80,0x80, 0x80,0x80,0x80,0x80, 0x80,0x80,0x80,0x80
.byte 0,4,8,12, 0x80,0x80,0x80,0x80, 0x80,0x80,0x80,0x80, 0x80,0x80,0x80,0x80

.globl SYM(ksvgBlurVerticalAvx2_x86_64)
TYPE(SYM(ksvgBlurVerticalAvx2_x86_64),@function)
SYM(ksvgBlurVerticalAvx2_x86_64):
    push %r12
    mov 16(%rsp), %r11d
    mov %r11d, %eax
    sub %r9d, %eax
    and $~7, %eax
    jle .AV_done
    add %r9d, %eax
    mov %eax, %r11d
    movslq %edx, %rdx
    # Keep A/R masks resident; G/B are memory operands. This avoids 2 loads per row
    # without consuming the accumulator/transpose registers needed later.
.AV_group:
    vmovdqa .LvA(%rip), %ymm14
    vmovdqa .LvR(%rip), %ymm15
    mov %r9d, %eax
    shl $2, %rax
    lea (%rsi,%rax), %r10
    vxorps %ymm0,%ymm0,%ymm0
    vxorps %ymm1,%ymm1,%ymm1
    vxorps %ymm2,%ymm2,%ymm2
    vxorps %ymm3,%ymm3,%ymm3
    xor %eax,%eax
    mov %rcx,%r12
.AV_row:
    vbroadcastss (%r12),%ymm4
    vmovdqu (%r10),%ymm5
    vpshufb %ymm14,%ymm5,%ymm6
    vpshufb %ymm15,%ymm5,%ymm7
    vpshufb .LvG(%rip),%ymm5,%ymm8
    vpshufb .LvB(%rip),%ymm5,%ymm9
    vcvtdq2ps %ymm6,%ymm6
    vcvtdq2ps %ymm7,%ymm7
    vcvtdq2ps %ymm8,%ymm8
    vcvtdq2ps %ymm9,%ymm9
    vmulps %ymm4,%ymm6,%ymm6
    vmulps %ymm4,%ymm7,%ymm7
    vmulps %ymm4,%ymm8,%ymm8
    vmulps %ymm4,%ymm9,%ymm9
    vaddps %ymm6,%ymm0,%ymm0
    vaddps %ymm7,%ymm1,%ymm1
    vaddps %ymm8,%ymm2,%ymm2
    vaddps %ymm9,%ymm3,%ymm3
    add %rdx,%r10
    add $4,%r12
    inc %eax
    cmp %r8d,%eax
    jl .AV_row
    vunpcklps %ymm1,%ymm0,%ymm4
    vunpckhps %ymm1,%ymm0,%ymm5
    vunpcklps %ymm3,%ymm2,%ymm6
    vunpckhps %ymm3,%ymm2,%ymm7
    vshufps $0x44,%ymm6,%ymm4,%ymm8
    vshufps $0xEE,%ymm6,%ymm4,%ymm9
    vshufps $0x44,%ymm7,%ymm5,%ymm10
    vshufps $0xEE,%ymm7,%ymm5,%ymm11
    vmovups %xmm8,0(%rdi)
    vmovups %xmm9,16(%rdi)
    vmovups %xmm10,32(%rdi)
    vmovups %xmm11,48(%rdi)
    vextractf128 $1,%ymm8,%xmm12
    vextractf128 $1,%ymm9,%xmm13
    vextractf128 $1,%ymm10,%xmm14
    vextractf128 $1,%ymm11,%xmm15
    vmovups %xmm12,64(%rdi)
    vmovups %xmm13,80(%rdi)
    vmovups %xmm14,96(%rdi)
    vmovups %xmm15,112(%rdi)
    add $128,%rdi
    add $8,%r9d
    cmp %r11d,%r9d
    jl .AV_group
.AV_done:
    vzeroupper
    pop %r12
    ret
//// SIZE(SYM(ksvgBlurVerticalAvx2_x86_64))

.globl SYM(ksvgBlurHorizontalAvx2_x86_64)
TYPE(SYM(ksvgBlurHorizontalAvx2_x86_64),@function)
SYM(ksvgBlurHorizontalAvx2_x86_64):
    push %r12
    mov %rdx, %r12
    cmp %r9d,%r8d
    jge .AH_done
    vmovdqa .Lhpack(%rip), %ymm15
.AH_loop:
    mov %r9d,%eax
    sub %r8d,%eax
    cmp $2,%eax
    jl .AH_tail
    mov %r8d,%eax
    shl $4,%rax
    lea (%rsi,%rax),%r11
    vbroadcastss (%r12),%ymm0
    vmulps (%r11),%ymm0,%ymm1
    mov $1,%r10d
    lea 4(%r12),%rax
    add $16,%r11
.AH_rows:
    vbroadcastss (%rax),%ymm0
    vmulps (%r11),%ymm0,%ymm2
    vaddps %ymm2,%ymm1,%ymm1
    add $4,%rax
    add $16,%r11
    inc %r10d
    cmp %ecx,%r10d
    jl .AH_rows
    vcvtps2dq %ymm1,%ymm1
    vpshufb %ymm15,%ymm1,%ymm1
    vmovd %xmm1,(%rdi)
    vextracti128 $1,%ymm1,%xmm2
    vmovd %xmm2,4(%rdi)
    add $8,%rdi
    add $2,%r8d
    jmp .AH_loop
.AH_tail:
    cmp %r9d,%r8d
    jge .AH_done
    mov %r8d,%eax
    shl $4,%rax
    lea (%rsi,%rax),%r11
    movss (%r12),%xmm0
    shufps $0,%xmm0,%xmm0
    movups (%r11),%xmm1
    mulps %xmm0,%xmm1
    mov $1,%r10d
    lea 4(%r12),%rax
    add $16,%r11
.AH_tail_rows:
    movss (%rax),%xmm0
    shufps $0,%xmm0,%xmm0
    movups (%r11),%xmm3
    mulps %xmm0,%xmm3
    addps %xmm3,%xmm1
    add $4,%rax
    add $16,%r11
    inc %r10d
    cmp %ecx,%r10d
    jl .AH_tail_rows
    cvtps2dq %xmm1,%xmm1
    pshufb .Lhpack(%rip),%xmm1
    movd %xmm1,(%rdi)
    add $4,%rdi
    inc %r8d
    jmp .AH_loop
.AH_done:
    vzeroupper
    pop %r12
    ret
//// SIZE(SYM(ksvgBlurHorizontalAvx2_x86_64))
GNU_STACK
