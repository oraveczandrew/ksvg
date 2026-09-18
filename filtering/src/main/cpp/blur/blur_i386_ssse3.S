/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "asm_macros.S"

.text
.p2align 4
.Lcvte_mask:
.byte 0,0x80,0x80,0x80, 1,0x80,0x80,0x80, 2,0x80,0x80,0x80, 3,0x80,0x80,0x80
.p2align 4
.Lpack_mask:
.byte 0,4,8,12, 0x80,0x80,0x80,0x80, 0x80,0x80,0x80,0x80, 0x80,0x80,0x80,0x80

/*
 * void rsdIntrinsicBlurVFU4_K_i386_ssse3(
 *     void* dst, const void* pin, int stride, const void* gptr, int rct, int x1, int x2);
 *
 * i386 cdecl ABI (stack parameters):
 *   esp+28 = dst, esp+32 = pin, esp+36 = stride, esp+40 = gptr, esp+44 = rct, esp+48 = x1, esp+52 = x2
 *   (offsets relative to esp after prologue pushes and allocations)
 */
.globl SYM(rsdIntrinsicBlurVFU4_K_i386_ssse3)
TYPE(SYM(rsdIntrinsicBlurVFU4_K_i386_ssse3), @function)
SYM(rsdIntrinsicBlurVFU4_K_i386_ssse3):
    pushl %ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    subl $8, %esp
    movl 28(%esp), %edi                 # dst
    movl 32(%esp), %esi                 # pin
    movl 36(%esp), %edx                 # stride
    movl 40(%esp), %ecx                 # gptr base
    movl 44(%esp), %ebx                 # rct
    movl 48(%esp), %ebp                 # x1
    movl 52(%esp), %eax                 # x2
    movl %eax, 0(%esp)

    # source = pin + x1 * 4
    leal (%esi, %ebp, 4), %esi

    call 1f
1:  popl %eax
    leal (.Lcvte_mask-1b)(%eax), %eax
    movdqa (%eax), %xmm7                # invariant u8->4x32 mask

    cmpl 0(%esp), %ebp
    jge .LV_done
.LV_pair:
    movl %esi, 4(%esp)                  # row-0 source
    pxor %xmm0, %xmm0
    pxor %xmm1, %xmm1

    movl 40(%esp), %ecx                 # weight pointer
    leal (%ecx, %ebx, 4), %eax            # weight end
.LV_row:
    movss (%ecx), %xmm2
    shufps $0, %xmm2, %xmm2

    movd (%esi), %xmm3
    pshufb %xmm7, %xmm3
    cvtdq2ps %xmm3, %xmm3
    mulps %xmm2, %xmm3
    addps %xmm3, %xmm0

    movd 4(%esi), %xmm3
    pshufb %xmm7, %xmm3
    cvtdq2ps %xmm3, %xmm3
    mulps %xmm2, %xmm3
    addps %xmm3, %xmm1

    addl %edx, %esi
    addl $4, %ecx
    cmpl %eax, %ecx
    jne .LV_row

    movups %xmm0, (%edi)
    movups %xmm1, 16(%edi)
    movl 4(%esp), %esi
    addl $8, %esi
    addl $32, %edi
    addl $2, %ebp
    cmpl 0(%esp), %ebp
    jl .LV_pair
.LV_done:
    addl $8, %esp
    popl %edi
    popl %esi
    popl %ebx
    popl %ebp
    ret
# SIZE(SYM(rsdIntrinsicBlurVFU4_K_i386_ssse3))

/*
 * void rsdIntrinsicBlurHFU4_K_i386_ssse3(
 *     void* dst, const void* pin, const void* gptr, int rct, int x1, int x2);
 *
 * i386 cdecl ABI (stack parameters):
 *   esp+20 = dst, esp+24 = pin, esp+28 = gptr, esp+32 = rct, esp+36 = x1, esp+40 = x2
 */
.globl SYM(rsdIntrinsicBlurHFU4_K_i386_ssse3)
TYPE(SYM(rsdIntrinsicBlurHFU4_K_i386_ssse3), @function)
SYM(rsdIntrinsicBlurHFU4_K_i386_ssse3):
    pushl %ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    movl 20(%esp), %edi                 # dst
    movl 24(%esp), %esi                 # current input column
    movl 28(%esp), %edx                 # gptr base / current weight ptr
    movl 32(%esp), %ecx                 # rct
    movl 36(%esp), %ebp                 # current x
    movl 40(%esp), %ebx                 # x2

    # current input = pin + x1 * 16
    leal (%esi, %ebp, 8), %eax
    leal (%eax, %ebp, 8), %esi

    call 2f
2:  popl %eax
    leal (.Lpack_mask-2b)(%eax), %eax
    movdqa (%eax), %xmm7                 # invariant pack mask

    cmpl %ebx, %ebp
    jge .LH_done
.LH_pixel:
    movl %esi, %eax                     # row pointer
    movl 28(%esp), %edx                 # reset weight pointer

    movss (%edx), %xmm0
    shufps $0, %xmm0, %xmm0
    movups (%eax), %xmm1
    mulps %xmm0, %xmm1
    addl $4, %edx
    addl $16, %eax

    decl %ecx                            # rct == 1 -> store directly
    jz .LH_store
.LH_row:
    movss (%edx), %xmm0
    shufps $0, %xmm0, %xmm0
    movups (%eax), %xmm2
    mulps %xmm0, %xmm2
    addps %xmm2, %xmm1
    addl $4, %edx
    addl $16, %eax
    decl %ecx
    jnz .LH_row
.LH_store:
    cvtps2dq %xmm1, %xmm1
    pshufb %xmm7, %xmm1
    movd %xmm1, (%edi)

    movl 32(%esp), %ecx                 # restore constant rct
    addl $16, %esi                      # next input column
    addl $4, %edi
    incl %ebp
    cmpl %ebx, %ebp
    jl .LH_pixel
.LH_done:
    popl %edi
    popl %esi
    popl %ebx
    popl %ebp
    ret
# SIZE(SYM(rsdIntrinsicBlurHFU4_K_i386_ssse3))
