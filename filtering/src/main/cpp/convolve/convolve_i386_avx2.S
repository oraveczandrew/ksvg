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
.p2align 2, 0x0
.LCPI0_0:
.long 0x437f0000  # float 255
.LCPI0_1:
.byte 255  # 0xff
.byte 0  # 0x0
.byte 0  # 0x0
.byte 0  # 0x0
.LCPI0_4:
.long 0x3f000000  # float 0.5
.p2align 5, 0x0
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
.byte 17  # 0x11
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.byte 21  # 0x15
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.byte 25  # 0x19
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.byte 29  # 0x1d
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
.byte 18  # 0x12
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.byte 22  # 0x16
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.byte 26  # 0x1a
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.byte 30  # 0x1e
.byte 128  # 0x80
.byte 128  # 0x80
.byte 128  # 0x80
.LCPI0_5:
.zero 32
.text

.globl SYM(ksvgConvolveApplyInteriorAvx2)
.p2align 4, 0x90
TYPE(SYM(ksvgConvolveApplyInteriorAvx2), @function)
    SYM(ksvgConvolveApplyInteriorAvx2):
.cfi_startproc
    pushl   %ebp
.cfi_def_cfa_offset 8
    pushl   %ebx
.cfi_def_cfa_offset 12
    pushl   %edi
.cfi_def_cfa_offset 16
    pushl   %esi
.cfi_def_cfa_offset 20
    subl    $236, %esp
.cfi_def_cfa_offset 256
.cfi_offset %esi, -20
.cfi_offset %edi, -16
.cfi_offset %ebx, -12
.cfi_offset %ebp, -8
    call    1f
1:  popl	%eax
    leal    .LCPI0_0-1b(%eax), %eax
    movd    (%eax), %xmm0
    vmovd   %xmm0, 104(%esp)
    movd    4(%eax), %xmm0
    vmovd   %xmm0, 96(%esp)
    movd    8(%eax), %xmm0
    vmovd   %xmm0, 100(%esp)
    leal    .LCPI0_2-.LCPI0_0(%eax), %eax
    vmovdqu (%eax), %ymm0
    vmovdqu %ymm0, (%esp)
    vmovdqu 32(%eax), %ymm0
    vmovdqu %ymm0, 32(%esp)
    vmovdqu 64(%eax), %ymm0
    vmovdqu %ymm0, 64(%esp)
    movl    284(%esp), %ecx
    movl    276(%esp), %esi
    movl    264(%esp), %edx
    movl    268(%esp), %eax
    subl    %esi, %edx
    leal    (%edx, %ecx), %ebp
    incl    %ebp
    subl    280(%esp), %eax
    leal    1(%eax), %edi
    testl   %edi, %edi
    jle     .LBB0_23
    incl    %edx
    cmpl    $8, %edx
    jge     .LBB0_2
.LBB0_23:
    andl    $-8, %ebp
    movl    %ebp, %eax
    addl    $236, %esp
.cfi_def_cfa_offset 20
    popl    %esi
.cfi_def_cfa_offset 16
    popl    %edi
.cfi_def_cfa_offset 12
    popl    %ebx
.cfi_def_cfa_offset 8
    popl    %ebp
.cfi_def_cfa_offset 4
    vzeroupper
    retl
.LBB0_2:
.cfi_def_cfa_offset 256
    movl    300(%esp), %edx
    movl    288(%esp), %edi
    vmovss  296(%esp), %xmm0
    addl    %edi, %eax
    incl    %eax
    movl    %eax, 144(%esp)
    vmulss  104(%esp), %xmm0, %xmm0
    vbroadcastss %xmm0, %ymm0
    vmovups %ymm0, 192(%esp)
    leal    8(%ecx), %eax
    movl    %eax, 140(%esp)
    vbroadcastss 96(%esp), %ymm2
    leal    (, %esi, 4), %eax
    movl    %eax, 136(%esp)
    movl    264(%esp), %eax
    leal    (, %eax, 4), %ebx
    movl    %edi, %eax
    movl    256(%esp), %edi
    movl    %ebp, 128(%esp)
    vmovups %ymm2, 160(%esp)
    jmp     .LBB0_3
.p2align 4, 0x90
.LBB0_22:
    movl    148(%esp), %eax
    incl    %eax
    movl    124(%esp), %edi
    addl    %ebx, %edi
    cmpl    144(%esp), %eax
    jge     .LBB0_23
.LBB0_3:  # =>This Loop Header: Depth=1
    # Child Loop BB0_4 Depth 2
    # Child Loop BB0_9 Depth 3
    # Child Loop BB0_11 Depth 4
    # Child Loop BB0_14 Depth 4
    # Child Loop BB0_25 Depth 3
    # Child Loop BB0_26 Depth 4
    movl    %edi, 124(%esp)
    movl    %eax, 148(%esp)
    imull   264(%esp), %eax
    movl    260(%esp), %edi
    leal    (%edi, %eax, 4), %eax
    movl    %eax, 152(%esp)
    movl    124(%esp), %eax
    movl    %eax, 120(%esp)
    movl    140(%esp), %eax
    movl    %ecx, 132(%esp)
    jmp     .LBB0_4
.p2align 4, 0x90
.LBB0_21:
    vbroadcastss 292(%esp), %ymm4
    vdivps  %ymm4, %ymm5, %ymm3
    vmovups 192(%esp), %ymm5
    vaddps  %ymm3, %ymm5, %ymm3
    vbroadcastss 100(%esp), %ymm6
    vaddps  %ymm6, %ymm3, %ymm3
    vroundps $1, %ymm3, %ymm3
    vcvttps2dq %ymm3, %ymm3
    vdivps  %ymm4, %ymm0, %ymm0
    vxorps  %xmm4, %xmm4, %xmm4
    vpmaxsd %ymm4, %ymm3, %ymm3
    vpminsd %ymm2, %ymm3, %ymm3
    vpslld  $24, %ymm1, %ymm1
    vpslld  $16, %ymm3, %ymm3
    vpor    %ymm3, %ymm1, %ymm1
    vaddps  %ymm0, %ymm5, %ymm0
    vaddps  %ymm6, %ymm0, %ymm0
    vroundps $1, %ymm0, %ymm0
    vcvttps2dq %ymm0, %ymm0
    vbroadcastss 292(%esp), %ymm3
    vdivps  %ymm3, %ymm7, %ymm3
    vpmaxsd %ymm4, %ymm0, %ymm0
    vpminsd %ymm2, %ymm0, %ymm0
    vaddps  %ymm3, %ymm5, %ymm3
    vaddps  %ymm6, %ymm3, %ymm3
    vroundps $1, %ymm3, %ymm3
    vcvttps2dq %ymm3, %ymm3
    vpmaxsd %ymm4, %ymm3, %ymm3
    vpminsd %ymm2, %ymm3, %ymm3
    vpslld  $8, %ymm0, %ymm0
    vpor    %ymm0, %ymm3, %ymm0
    vpor    %ymm0, %ymm1, %ymm0
    movl    152(%esp), %eax
    movl    132(%esp), %edi
    vmovdqu %ymm0, (%eax, %edi, 4)
    movl    156(%esp), %edi
    leal    8(%edi), %eax
    addl    $32, 120(%esp)
    movl    %edi, 132(%esp)
    cmpl    %ebp, %eax
    jg      .LBB0_22
.LBB0_4:  # Parent Loop BB0_3 Depth=1
    # =>  This Loop Header: Depth=2
    # Child Loop BB0_9 Depth 3
    # Child Loop BB0_11 Depth 4
    # Child Loop BB0_14 Depth 4
    # Child Loop BB0_25 Depth 3
    # Child Loop BB0_26 Depth 4
    movl    %eax, 156(%esp)
    cmpl    $0, 280(%esp)
    jle     .LBB0_5
    testl   %esi, %esi
    jle     .LBB0_5
    testl   %edx, %edx
    je      .LBB0_24
    xorl    %ebp, %ebp
    vxorps  %xmm3, %xmm3, %xmm3
    vxorps  %xmm5, %xmm5, %xmm5
    movl    120(%esp), %eax
    movl    272(%esp), %edx
    vxorps  %xmm0, %xmm0, %xmm0
    vxorps  %xmm7, %xmm7, %xmm7
    jmp     .LBB0_9
.p2align 4, 0x90
.LBB0_17:
    incl    %ebp
    addl    136(%esp), %edx
    addl    %ebx, %eax
    cmpl    280(%esp), %ebp
    je      .LBB0_18
.LBB0_9:  # Parent Loop BB0_3 Depth=1
    # Parent Loop BB0_4 Depth=2
    # =>    This Loop Header: Depth=3
    # Child Loop BB0_11 Depth 4
    # Child Loop BB0_14 Depth 4
    xorl    %edi, %edi
    cmpl    288(%esp), %ebp
    jne     .LBB0_10
    vmovaps %ymm3, %ymm1
    jmp     .LBB0_14
.p2align 4, 0x90
.LBB0_16:
    vbroadcastss (%edx, %edi, 4), %ymm1
    vandps  %ymm6, %ymm2, %ymm4
    vcvtdq2ps %ymm4, %ymm4
    vmulps  %ymm4, %ymm1, %ymm4
    vaddps  %ymm4, %ymm7, %ymm7
    vpshufb (%esp), %ymm6, %ymm4
    vcvtdq2ps %ymm4, %ymm4
    vmulps  %ymm4, %ymm1, %ymm4
    vaddps  %ymm4, %ymm0, %ymm0
    vpshufb 32(%esp), %ymm6, %ymm4
    vcvtdq2ps %ymm4, %ymm4
    vmulps  %ymm4, %ymm1, %ymm1
    vaddps  %ymm1, %ymm5, %ymm5
    incl    %edi
    vmovaps %ymm3, %ymm1
    cmpl    %edi, %esi
    je      .LBB0_17
.LBB0_14:  # Parent Loop BB0_3 Depth=1
    # Parent Loop BB0_4 Depth=2
    # Parent Loop BB0_9 Depth=3
    # =>      This Inner Loop Header: Depth=4
    vmovups (%eax, %edi, 4), %ymm6
    vmovaps %ymm6, %ymm3
    cmpl    %edi, %ecx
    je      .LBB0_16
    vmovaps %ymm1, %ymm3
    jmp     .LBB0_16
.p2align 4, 0x90
.LBB0_10:
    vmovdqa 32(%esp), %ymm2
.p2align 4, 0x90
.LBB0_11:  # Parent Loop BB0_3 Depth=1
    # Parent Loop BB0_4 Depth=2
    # Parent Loop BB0_9 Depth=3
    # =>      This Inner Loop Header: Depth=4
    vmovups (%eax, %edi, 4), %ymm1
    vbroadcastss (%edx, %edi, 4), %ymm6
    vandps  160(%esp), %ymm1, %ymm4
    vcvtdq2ps %ymm4, %ymm4
    vmulps  %ymm4, %ymm6, %ymm4
    vaddps  %ymm4, %ymm7, %ymm7
    vpshufb (%esp), %ymm1, %ymm4
    vcvtdq2ps %ymm4, %ymm4
    vmulps  %ymm4, %ymm6, %ymm4
    vaddps  %ymm4, %ymm0, %ymm0
    vpshufb %ymm2, %ymm1, %ymm1
    vcvtdq2ps %ymm1, %ymm1
    vmulps  %ymm1, %ymm6, %ymm1
    vaddps  %ymm1, %ymm5, %ymm5
    incl    %edi
    cmpl    %edi, %esi
    jne     .LBB0_11
    vmovups 160(%esp), %ymm2
    jmp     .LBB0_17
.p2align 4, 0x90
.LBB0_5:
    vxorps  %xmm7, %xmm7, %xmm7
    vxorps  %xmm1, %xmm1, %xmm1
    vxorps  %xmm0, %xmm0, %xmm0
    vxorps  %xmm5, %xmm5, %xmm5
    vxorps  %xmm6, %xmm6, %xmm6
    testl   %edx, %edx
    jne     .LBB0_21
    jmp     .LBB0_20
.p2align 4, 0x90
.LBB0_18:
    vpsrld  $24, %ymm3, %ymm1
    vxorps  %xmm6, %xmm6, %xmm6
    movl    128(%esp), %ebp
    movl    300(%esp), %edx
    testl   %edx, %edx
    jne     .LBB0_21
    jmp     .LBB0_20
.LBB0_24:
    xorl    %eax, %eax
    vxorps  %xmm6, %xmm6, %xmm6
    movl    120(%esp), %edx
    movl    272(%esp), %ebp
    vxorps  %xmm5, %xmm5, %xmm5
    vxorps  %xmm0, %xmm0, %xmm0
    vxorps  %xmm7, %xmm7, %xmm7
.p2align 4, 0x90
.LBB0_25:  # Parent Loop BB0_3 Depth=1
    # Parent Loop BB0_4 Depth=2
    # =>    This Loop Header: Depth=3
    # Child Loop BB0_26 Depth 4
    xorl    %edi, %edi
    vmovups 160(%esp), %ymm2
.p2align 4, 0x90
.LBB0_26:  # Parent Loop BB0_3 Depth=1
    # Parent Loop BB0_4 Depth=2
    # Parent Loop BB0_25 Depth=3
    # =>      This Inner Loop Header: Depth=4
    vmovups (%edx, %edi, 4), %ymm1
    vbroadcastss (%ebp, %edi, 4), %ymm3
    vandps  %ymm1, %ymm2, %ymm4
    vcvtdq2ps %ymm4, %ymm4
    vmulps  %ymm4, %ymm3, %ymm4
    vaddps  %ymm4, %ymm7, %ymm7
    vpshufb (%esp), %ymm1, %ymm4
    vcvtdq2ps %ymm4, %ymm4
    vmulps  %ymm4, %ymm3, %ymm4
    vaddps  %ymm4, %ymm0, %ymm0
    vpshufb 32(%esp), %ymm1, %ymm4
    vcvtdq2ps %ymm4, %ymm4
    vmulps  %ymm4, %ymm3, %ymm4
    vaddps  %ymm4, %ymm5, %ymm5
    vpsrld  $24, %ymm1, %ymm1
    vcvtdq2ps %ymm1, %ymm1
    vmulps  %ymm1, %ymm3, %ymm1
    vaddps  %ymm1, %ymm6, %ymm6
    incl    %edi
    cmpl    %edi, %esi
    jne     .LBB0_26
    incl    %eax
    addl    136(%esp), %ebp
    addl    %ebx, %edx
    cmpl    280(%esp), %eax
    jne     .LBB0_25
    vxorps  %xmm1, %xmm1, %xmm1
    movl    128(%esp), %ebp
    movl    300(%esp), %edx
    vmovups 160(%esp), %ymm2
    testl   %edx, %edx
    jne     .LBB0_21
.p2align 4, 0x90
.LBB0_20:
    vbroadcastss 292(%esp), %ymm1
    vdivps  %ymm1, %ymm6, %ymm1
    vaddps  192(%esp), %ymm1, %ymm1
    vbroadcastss 100(%esp), %ymm3
    vaddps  %ymm3, %ymm1, %ymm1
    vroundps $1, %ymm1, %ymm1
    vcvttps2dq %ymm1, %ymm1
    vpmaxsd 64(%esp), %ymm1, %ymm1
    vpminsd %ymm2, %ymm1, %ymm1
    jmp     .LBB0_21
.Lfunc_end0:
    # // SIZE(SYM(ksvgConvolveApplyInteriorAvx2))
.cfi_endproc
    GNU_STACK
    ADDRSIG
