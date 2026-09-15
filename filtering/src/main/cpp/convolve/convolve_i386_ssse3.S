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
    RODATA4
.p2align 2, 0x0
.LCPI0_0:
.long 0x437f0000  # float 255
    RODATA16
.p2align 4, 0x0
.LCPI0_1:
.byte 255  # 0xff
.byte 0  # 0x0
.byte 0  # 0x0
.byte 0  # 0x0
.byte 255  # 0xff
.byte 0  # 0x0
.byte 0  # 0x0
.byte 0  # 0x0
.byte 255  # 0xff
.byte 0  # 0x0
.byte 0  # 0x0
.byte 0  # 0x0
.byte 255  # 0xff
.byte 0  # 0x0
.byte 0  # 0x0
.byte 0  # 0x0
.LCPI0_2:
.byte 1  # 0x1
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.byte 5  # 0x5
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.byte 9  # 0x9
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.byte 13  # 0xd
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.LCPI0_3:
.byte 2  # 0x2
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.byte 6  # 0x6
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.byte 10  # 0xa
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.byte 14  # 0xe
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.LCPI0_4:
.long 0x3f000000  # float 0.5
.long 0x3f000000  # float 0.5
.long 0x3f000000  # float 0.5
.long 0x3f000000  # float 0.5
.LCPI0_5:
.long 0x3f800000  # float 1
.long 0x3f800000  # float 1
.long 0x3f800000  # float 1
.long 0x3f800000  # float 1
.LCPI0_6:
.zero 16
.text

.globl SYM(ksvgConvolveApplyInteriorSsse3I386)
.p2align 4, 0x90
TYPE(SYM(ksvgConvolveApplyInteriorSsse3I386), @function)
    SYM(ksvgConvolveApplyInteriorSsse3I386):
.cfi_startproc
    pushl   %ebp
.cfi_def_cfa_offset 8
    pushl   %ebx
.cfi_def_cfa_offset 12
    pushl   %edi
.cfi_def_cfa_offset 16
    pushl   %esi
.cfi_def_cfa_offset 20
    subl    $108, %esp
.cfi_def_cfa_offset 128
.cfi_offset %esi, -20
.cfi_offset %edi, -16
.cfi_offset %ebx, -12
.cfi_offset %ebp, -8
    movl    156(%esp), %ecx
    movl    148(%esp), %esi
    movl    136(%esp), %edx
    movl    140(%esp), %eax
    subl    %esi, %edx
    leal    (%edx, %ecx), %ebp
    incl    %ebp
    subl    152(%esp), %eax
    leal    1(%eax), %edi
    testl   %edi, %edi
    jle     .LBB0_23
    incl    %edx
    cmpl    $4, %edx
    jge     .LBB0_2
.LBB0_23:
    andl    $-4, %ebp
    movl    %ebp, %eax
    addl    $108, %esp
.cfi_def_cfa_offset 20
    popl    %esi
.cfi_def_cfa_offset 16
    popl    %edi
.cfi_def_cfa_offset 12
    popl    %ebx
.cfi_def_cfa_offset 8
    popl    %ebp
.cfi_def_cfa_offset 4
    retl
.LBB0_2:
.cfi_def_cfa_offset 128
    movl    172(%esp), %edx
    movl    160(%esp), %edi
    movss   168(%esp), %xmm0
    addl    %edi, %eax
    incl    %eax
    movl    %eax, 32(%esp)
    movss   164(%esp), %xmm1
    mulss   .LCPI0_0, %xmm0
    shufps  $0, %xmm1, %xmm1
    movaps  %xmm1, 48(%esp)
    shufps  $0, %xmm0, %xmm0
    movaps  %xmm0, 64(%esp)
    leal    4(%ecx), %eax
    movl    %eax, 28(%esp)
    movdqa  .LCPI0_3, %xmm2
    leal    (, %esi, 4), %eax
    movl    %eax, 24(%esp)
    movl    136(%esp), %eax
    leal    (, %eax, 4), %ebx
    movl    %edi, %eax
    movl    128(%esp), %edi
    movl    %ebp, 16(%esp)
    jmp     .LBB0_3
.p2align 4, 0x90
.LBB0_22:
    movl    36(%esp), %eax
    incl    %eax
    movl    12(%esp), %edi
    addl    %ebx, %edi
    cmpl    32(%esp), %eax
    jge     .LBB0_23
.LBB0_3:  # =>This Loop Header: Depth=1
    # Child Loop BB0_4 Depth 2
    # Child Loop BB0_9 Depth 3
    # Child Loop BB0_11 Depth 4
    # Child Loop BB0_14 Depth 4
    # Child Loop BB0_25 Depth 3
    # Child Loop BB0_26 Depth 4
    movl    %edi, 12(%esp)
    movl    %eax, 36(%esp)
    imull   136(%esp), %eax
    movl    132(%esp), %edi
    leal    (%edi, %eax, 4), %eax
    movl    %eax, 40(%esp)
    movl    12(%esp), %eax
    movl    %eax, 8(%esp)
    movl    28(%esp), %eax
    movl    %ecx, 20(%esp)
    jmp     .LBB0_4
.p2align 4, 0x90
.LBB0_21:
    divps   48(%esp), %xmm7
    addps   64(%esp), %xmm7
    movaps  .LCPI0_4, %xmm1
    addps   %xmm1, %xmm7
    cvttps2dq %xmm7, %xmm1
    cvtdq2ps %xmm1, %xmm1
    cmpltps %xmm1, %xmm7
    movaps  .LCPI0_5, %xmm3
    andps   %xmm3, %xmm7
    subps   %xmm7, %xmm1
    cvttps2dq %xmm1, %xmm1
    movdqa  .LCPI0_1, %xmm0
    movdqa  %xmm0, %xmm3
    pcmpgtd %xmm1, %xmm3
    pand    %xmm3, %xmm1
    pandn   %xmm0, %xmm3
    por     %xmm1, %xmm3
    movdqa  %xmm3, %xmm1
    xorps   %xmm7, %xmm7
    pcmpgtd %xmm7, %xmm1
    pand    %xmm3, %xmm1
    divps   48(%esp), %xmm6
    addps   64(%esp), %xmm6
    addps   .LCPI0_4, %xmm6
    cvttps2dq %xmm6, %xmm3
    cvtdq2ps %xmm3, %xmm3
    cmpltps %xmm3, %xmm6
    andps   .LCPI0_5, %xmm6
    subps   %xmm6, %xmm3
    cvttps2dq %xmm3, %xmm3
    movdqa  %xmm4, %xmm7
    movdqa  %xmm0, %xmm4
    pcmpgtd %xmm3, %xmm4
    pand    %xmm4, %xmm3
    pandn   %xmm0, %xmm4
    por     %xmm3, %xmm4
    movdqa  %xmm4, %xmm6
    pcmpgtd .LCPI0_6, %xmm6
    pand    %xmm4, %xmm6
    divps   48(%esp), %xmm5
    addps   64(%esp), %xmm5
    addps   .LCPI0_4, %xmm5
    cvttps2dq %xmm5, %xmm3
    cvtdq2ps %xmm3, %xmm3
    cmpltps %xmm3, %xmm5
    andps   .LCPI0_5, %xmm5
    subps   %xmm5, %xmm3
    cvttps2dq %xmm3, %xmm3
    movdqa  %xmm0, %xmm4
    pcmpgtd %xmm3, %xmm4
    pand    %xmm4, %xmm3
    pandn   %xmm0, %xmm4
    por     %xmm3, %xmm4
    movdqa  %xmm4, %xmm3
    pcmpgtd .LCPI0_6, %xmm3
    pand    %xmm4, %xmm3
    pslld   $24, %xmm7
    por     %xmm3, %xmm7
    pslld   $16, %xmm1
    pslld   $8, %xmm6
    por     %xmm1, %xmm6
    por     %xmm7, %xmm6
    movl    40(%esp), %eax
    movl    20(%esp), %edi
    movdqu  %xmm6, (%eax, %edi, 4)
    movl    44(%esp), %edi
    leal    4(%edi), %eax
    addl    $16, 8(%esp)
    movl    %edi, 20(%esp)
    cmpl    %ebp, %eax
    jg      .LBB0_22
.LBB0_4:  # Parent Loop BB0_3 Depth=1
    # =>  This Loop Header: Depth=2
    # Child Loop BB0_9 Depth 3
    # Child Loop BB0_11 Depth 4
    # Child Loop BB0_14 Depth 4
    # Child Loop BB0_25 Depth 3
    # Child Loop BB0_26 Depth 4
    movl    %eax, 44(%esp)
    cmpl    $0, 152(%esp)
    jle     .LBB0_5
    testl   %esi, %esi
    jle     .LBB0_5
    testl   %edx, %edx
    je      .LBB0_24
    xorl    %ebp, %ebp
    xorps   %xmm4, %xmm4
    xorps   %xmm7, %xmm7
    movl    8(%esp), %eax
    movl    144(%esp), %edx
    xorps   %xmm6, %xmm6
    xorps   %xmm5, %xmm5
    jmp     .LBB0_9
.p2align 4, 0x90
.LBB0_17:
    incl    %ebp
    addl    24(%esp), %edx
    addl    %ebx, %eax
    cmpl    152(%esp), %ebp
    je      .LBB0_18
.LBB0_9:  # Parent Loop BB0_3 Depth=1
    # Parent Loop BB0_4 Depth=2
    # =>    This Loop Header: Depth=3
    # Child Loop BB0_11 Depth 4
    # Child Loop BB0_14 Depth 4
    cmpl    160(%esp), %ebp
    jne     .LBB0_10
    xorl    %edi, %edi
    movaps  %xmm4, %xmm3
    jmp     .LBB0_14
.p2align 4, 0x90
.LBB0_16:
    movss   (%edx, %edi, 4), %xmm3
    shufps  $0, %xmm3, %xmm3
    movaps  %xmm1, %xmm4
    andps   .LCPI0_1, %xmm4
    cvtdq2ps %xmm4, %xmm4
    mulps   %xmm3, %xmm4
    addps   %xmm4, %xmm5
    movaps  %xmm1, %xmm4
    pshufb  .LCPI0_2, %xmm4
    cvtdq2ps %xmm4, %xmm4
    mulps   %xmm3, %xmm4
    addps   %xmm4, %xmm6
    movaps  %xmm0, %xmm4
    pshufb  %xmm2, %xmm1
    cvtdq2ps %xmm1, %xmm1
    mulps   %xmm3, %xmm1
    addps   %xmm1, %xmm7
    incl    %edi
    movaps  %xmm0, %xmm3
    cmpl    %edi, %esi
    je      .LBB0_17
.LBB0_14:  # Parent Loop BB0_3 Depth=1
    # Parent Loop BB0_4 Depth=2
    # Parent Loop BB0_9 Depth=3
    # =>      This Inner Loop Header: Depth=4
    movups  (%eax, %edi, 4), %xmm1
    movaps  %xmm1, %xmm0
    cmpl    %edi, %ecx
    je      .LBB0_16
    movaps  %xmm3, %xmm0
    jmp     .LBB0_16
.p2align 4, 0x90
.LBB0_10:
    movaps  %xmm4, 80(%esp)
    xorl    %edi, %edi
    movaps  .LCPI0_1, %xmm2
    movdqa  .LCPI0_2, %xmm0
.p2align 4, 0x90
.LBB0_11:  # Parent Loop BB0_3 Depth=1
    # Parent Loop BB0_4 Depth=2
    # Parent Loop BB0_9 Depth=3
    # =>      This Inner Loop Header: Depth=4
    movups  (%eax, %edi, 4), %xmm4
    movss   (%edx, %edi, 4), %xmm1
    shufps  $0, %xmm1, %xmm1
    movaps  %xmm4, %xmm3
    andps   %xmm2, %xmm3
    cvtdq2ps %xmm3, %xmm3
    mulps   %xmm1, %xmm3
    addps   %xmm3, %xmm5
    movaps  %xmm4, %xmm3
    pshufb  %xmm0, %xmm3
    cvtdq2ps %xmm3, %xmm3
    mulps   %xmm1, %xmm3
    addps   %xmm3, %xmm6
    pshufb  .LCPI0_3, %xmm4
    cvtdq2ps %xmm4, %xmm3
    mulps   %xmm1, %xmm3
    addps   %xmm3, %xmm7
    incl    %edi
    cmpl    %edi, %esi
    jne     .LBB0_11
    movdqa  .LCPI0_3, %xmm2
    movaps  80(%esp), %xmm4
    jmp     .LBB0_17
.p2align 4, 0x90
.LBB0_5:
    xorps   %xmm5, %xmm5
    xorps   %xmm4, %xmm4
    xorps   %xmm6, %xmm6
    xorps   %xmm7, %xmm7
    xorps   %xmm1, %xmm1
    testl   %edx, %edx
    jne     .LBB0_21
    jmp     .LBB0_20
.p2align 4, 0x90
.LBB0_18:
    psrld   $24, %xmm4
    xorps   %xmm1, %xmm1
    movl    16(%esp), %ebp
    movl    172(%esp), %edx
    testl   %edx, %edx
    jne     .LBB0_21
    jmp     .LBB0_20
.LBB0_24:
    xorl    %eax, %eax
    xorps   %xmm1, %xmm1
    movl    8(%esp), %edx
    movl    144(%esp), %ebp
    xorps   %xmm7, %xmm7
    xorps   %xmm6, %xmm6
    xorps   %xmm5, %xmm5
.p2align 4, 0x90
.LBB0_25:  # Parent Loop BB0_3 Depth=1
    # Parent Loop BB0_4 Depth=2
    # =>    This Loop Header: Depth=3
    # Child Loop BB0_26 Depth 4
    xorl    %edi, %edi
    movaps  .LCPI0_1, %xmm0
.p2align 4, 0x90
.LBB0_26:  # Parent Loop BB0_3 Depth=1
    # Parent Loop BB0_4 Depth=2
    # Parent Loop BB0_25 Depth=3
    # =>      This Inner Loop Header: Depth=4
    movups  (%edx, %edi, 4), %xmm3
    movss   (%ebp, %edi, 4), %xmm2
    shufps  $0, %xmm2, %xmm2
    movaps  %xmm3, %xmm4
    andps   %xmm0, %xmm4
    cvtdq2ps %xmm4, %xmm4
    mulps   %xmm2, %xmm4
    addps   %xmm4, %xmm5
    movaps  %xmm3, %xmm4
    pshufb  .LCPI0_2, %xmm4
    cvtdq2ps %xmm4, %xmm4
    mulps   %xmm2, %xmm4
    addps   %xmm4, %xmm6
    movaps  %xmm3, %xmm4
    pshufb  .LCPI0_3, %xmm4
    cvtdq2ps %xmm4, %xmm4
    mulps   %xmm2, %xmm4
    addps   %xmm4, %xmm7
    psrld   $24, %xmm3
    cvtdq2ps %xmm3, %xmm3
    mulps   %xmm2, %xmm3
    addps   %xmm3, %xmm1
    incl    %edi
    cmpl    %edi, %esi
    jne     .LBB0_26
    incl    %eax
    addl    24(%esp), %ebp
    addl    %ebx, %edx
    cmpl    152(%esp), %eax
    jne     .LBB0_25
    xorps   %xmm4, %xmm4
    movl    16(%esp), %ebp
    movl    172(%esp), %edx
    movdqa  .LCPI0_3, %xmm2
    testl   %edx, %edx
    jne     .LBB0_21
.p2align 4, 0x90
.LBB0_20:
    divps   48(%esp), %xmm1
    addps   64(%esp), %xmm1
    addps   .LCPI0_4, %xmm1
    cvttps2dq %xmm1, %xmm2
    cvtdq2ps %xmm2, %xmm2
    cmpltps %xmm2, %xmm1
    andps   .LCPI0_5, %xmm1
    subps   %xmm1, %xmm2
    cvttps2dq %xmm2, %xmm1
    movdqa  .LCPI0_3, %xmm2
    movdqa  .LCPI0_1, %xmm0
    movdqa  %xmm0, %xmm4
    pcmpgtd %xmm1, %xmm4
    movdqa  %xmm1, %xmm3
    pand    %xmm4, %xmm3
    pandn   %xmm0, %xmm4
    por     %xmm3, %xmm4
    pxor    %xmm3, %xmm3
    pcmpgtd %xmm3, %xmm1
    pand    %xmm4, %xmm1
    pcmpgtd %xmm3, %xmm4
    pand    %xmm1, %xmm4
    jmp     .LBB0_21
.Lfunc_end0:
    # // SIZE(SYM(ksvgConvolveApplyInteriorSsse3I386))
.cfi_endproc
    GNU_STACK
    ADDRSIG
