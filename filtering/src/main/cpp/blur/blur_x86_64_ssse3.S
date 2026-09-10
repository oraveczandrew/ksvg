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
.p2align 4
.Lcvte_mask:
.byte 0,0x80,0x80,0x80, 1,0x80,0x80,0x80, 2,0x80,0x80,0x80, 3,0x80,0x80,0x80
.p2align 4
.Lpack_mask:
.byte 0,4,8,12, 0x80,0x80,0x80,0x80, 0x80,0x80,0x80,0x80, 0x80,0x80,0x80,0x80

.globl SYM(rsdIntrinsicBlurVFU4_K_x86_64_ssse3)
TYPE(SYM(rsdIntrinsicBlurVFU4_K_x86_64_ssse3),@function)
SYM(rsdIntrinsicBlurVFU4_K_x86_64_ssse3):
    push %r12
    # rdi=dst rsi=pin edx=stride rcx=gptr r8d=rct r9d=x1; after push, x2 is at [rsp+16]
    mov 16(%rsp), %r10d
    movslq %edx, %rdx
    movdqa .Lcvte_mask(%rip), %xmm7
    cmp %r10d, %r9d
    jge .LV_done
.LV_pair:
    mov %r9d, %eax
    shl $2, %rax
    lea (%rsi,%rax), %r11
    pxor %xmm0, %xmm0
    pxor %xmm1, %xmm1
    xor %eax, %eax
    mov %rcx, %r12
.LV_row:
    movss (%r12), %xmm2
    shufps $0, %xmm2, %xmm2
    movd (%r11), %xmm3
    pshufb %xmm7, %xmm3
    cvtdq2ps %xmm3, %xmm3
    mulps %xmm2, %xmm3
    addps %xmm3, %xmm0
    movd 4(%r11), %xmm3
    pshufb %xmm7, %xmm3
    cvtdq2ps %xmm3, %xmm3
    mulps %xmm2, %xmm3
    addps %xmm3, %xmm1
    add %rdx, %r11
    add $4, %r12
    inc %eax
    cmp %r8d, %eax
    jl .LV_row
    movups %xmm0, (%rdi)
    movups %xmm1, 16(%rdi)
    add $32, %rdi
    add $2, %r9d
    cmp %r10d, %r9d
    jl .LV_pair
.LV_done:
    pop %r12
    ret
//// SIZE(SYM(rsdIntrinsicBlurVFU4_K_x86_64_ssse3))

.globl SYM(rsdIntrinsicBlurHFU4_K_x86_64_ssse3)
TYPE(SYM(rsdIntrinsicBlurHFU4_K_x86_64_ssse3),@function)
SYM(rsdIntrinsicBlurHFU4_K_x86_64_ssse3):
    push %r12
    # rdi=dst rsi=pin rdx=gptr ecx=rct r8d=x1 r9d=x2
    cmp %r9d, %r8d
    jge .LH_done
    movdqa .Lpack_mask(%rip), %xmm7
    mov %rdx, %r12
.LH_pixel:
    mov %r8d, %eax
    shl $4, %rax
    lea (%rsi,%rax), %r11
    movss (%r12), %xmm0
    shufps $0, %xmm0, %xmm0
    movups (%r11), %xmm1
    mulps %xmm0, %xmm1
    mov $1, %r10d
    lea 4(%r12), %rax
    add $16, %r11
.LH_row:
    movss (%rax), %xmm0
    shufps $0, %xmm0, %xmm0
    movups (%r11), %xmm2
    mulps %xmm0, %xmm2
    addps %xmm2, %xmm1
    add $4, %rax
    add $16, %r11
    inc %r10d
    cmp %ecx, %r10d
    jl .LH_row
    cvtps2dq %xmm1, %xmm1
    pshufb %xmm7, %xmm1
    movd %xmm1, (%rdi)
    add $4, %rdi
    inc %r8d
    cmp %r9d, %r8d
    jl .LH_pixel
.LH_done:
    pop %r12
    ret
//// SIZE(SYM(rsdIntrinsicBlurHFU4_K_x86_64_ssse3))
#ifndef __APPLE__
.section .note.GNU-stack,"",@progbits
#endif
