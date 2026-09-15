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
#include "turbulence_noise_common.S"

.text
    TEXT_SECTION
    CONST8_SECTION
.p2align 3, 0x0  # # -- Begin function applySse2
LCPI0_0: TURB_DBL_1_256
LCPI0_18: TURB_DBL_1
LCPI0_19: TURB_DBL_4096
LCPI0_20: TURB_DBL_NEG_1
LCPI0_21: TURB_DBL_3
LCPI0_23: TURB_DBL_0_5
    CONST16_SECTION
.p2align 4, 0x0
LCPI0_1: TURB_PERMUTATION_DATA
LCPI0_17:
    TURB_DBL_255
    TURB_DBL_127_5
LCPI0_22:
.long 4294967295  # # double NaN
.long 2147483647
.long 4294967295  # # double NaN
.long 2147483647
    TEXT_SECTION
.globl SYM(ksvgTurbulenceApplySse2_i386)
.Lksvg_pcrel_get_pc_edx:
    movl    (%esp), %edx
    retl

TYPE(ksvgTurbulenceApplySse2_i386, @function)
.p2align 4, 0x90
    SYM(ksvgTurbulenceApplySse2_i386):  # # @applySse2
.cfi_startproc
# # %bb.0:
    pushl   %ebp
.cfi_def_cfa_offset 8
.cfi_offset %ebp, -8
    movl    %esp, %ebp
.cfi_def_cfa_register %ebp
    pushl   %ebx
    pushl   %edi
    pushl   %esi
    subl    $69868, %esp  # # imm = 0x1108C
.cfi_offset %esi, -20
.cfi_offset %edi, -16
.cfi_offset %ebx, -12
    fnstcw  -69840(%ebp)
    movzwl  -69840(%ebp), %eax
    andl    $-3073, %eax
    orl     $1024, %eax
    movw    %ax, -69842(%ebp)
    fldcw   -69842(%ebp)
	# Hot scalar constants cached in the local frame.
    movl    $0, -69776(%ebp)
    movl    $1064304640, -69772(%ebp)
    movl    $0, -69784(%ebp)
    movl    $1072693248, -69780(%ebp)
    movl    $0, -69792(%ebp)
    movl    $1085276160, -69788(%ebp)
    movl    $0, -69800(%ebp)
    movl    $3220176896, -69796(%ebp)
    movl    $0, -69808(%ebp)
    movl    $1074266112, -69804(%ebp)
    movl    $0, -69816(%ebp)
    movl    $1071644672, -69812(%ebp)
    movl    $0, -69832(%ebp)
    movl    $1081073664, -69828(%ebp)  # # 255.0
    movl    $0, -69824(%ebp)
    movl    $1080025088, -69820(%ebp)  # # 127.5
    movl    132(%ebp), %eax
    testl   %eax, %eax
    jg      LBB0_2
# # %bb.1:
    leal    2147483646(%eax), %ecx
    leal    2147483645(%eax), %edx
    cmpl    $2147483646, %edx  # # imm = 0x7FFFFFFE
    cmovbl  %eax, %ecx
    movl    $1, %eax
    subl    %ecx, %eax
LBB0_2:
    cmpl    $2147483646, %eax  # # imm = 0x7FFFFFFE
    movl    $2147483646, %ecx  # # imm = 0x7FFFFFFE
    cmovbl  %eax, %ecx
    movl    16(%ebp), %ebx
    xorl    %esi, %esi
    movl    $-2092037281, %edi  # # imm = 0x834E0B5F
    movsd   -69776(%ebp), %xmm0  # # xmm0 = [3.90625E-3,0.0E+0]
    xorpd   %xmm1, %xmm1
    jmp     LBB0_3
LBB0_5:
    movapd  %xmm3, %xmm4
    mulsd   %xmm3, %xmm4
    movapd  %xmm2, %xmm5
    mulsd   %xmm2, %xmm5
    addsd   %xmm4, %xmm5
    xorps   %xmm4, %xmm4
    sqrtsd  %xmm5, %xmm4
    divsd   %xmm4, %xmm2
    movsd   %xmm2, -67196(%ebp, %esi, 8)
    divsd   %xmm4, %xmm3
    movsd   %xmm3, -63084(%ebp, %esi, 8)
    incl    %esi
    cmpl    $256, %esi  # # imm = 0x100
    je      LBB0_6
.p2align 4, 0x90
LBB0_3:
    movl    %ecx, %eax
    imull   %edi
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %ecx
    cmovgl  %edx, %ecx
    leal    511(%ecx), %eax
    testl   %ecx, %ecx
    cmovnsl %ecx, %eax
    andl    $-512, %eax  # # imm = 0xFE00
    negl    %eax
    addl    %ecx, %eax
    addl    $-256, %eax
    xorps   %xmm2, %xmm2
    cvtsi2sd %eax, %xmm2
    movl    %ecx, %eax
    imull   %edi
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %ecx
    cmovgl  %edx, %ecx
    leal    511(%ecx), %eax
    testl   %ecx, %ecx
    cmovnsl %ecx, %eax
    andl    $-512, %eax  # # imm = 0xFE00
    negl    %eax
    addl    %ecx, %eax
    addl    $-256, %eax
    xorps   %xmm3, %xmm3
    cvtsi2sd %eax, %xmm3
    mulsd   %xmm0, %xmm2
    mulsd   %xmm0, %xmm3
    ucomisd %xmm1, %xmm2
    jne     LBB0_5
    jp      LBB0_5
    ucomisd %xmm1, %xmm3
    jne     LBB0_5
    jnp     LBB0_3
    jmp     LBB0_5
LBB0_6:
    xorl    %esi, %esi
    movl    $-2092037281, %edi  # # imm = 0x834E0B5F
    xorpd   %xmm1, %xmm1
    jmp     LBB0_7
LBB0_9:
    movapd  %xmm3, %xmm4
    mulsd   %xmm3, %xmm4
    movapd  %xmm2, %xmm5
    mulsd   %xmm2, %xmm5
    addsd   %xmm4, %xmm5
    xorps   %xmm4, %xmm4
    sqrtsd  %xmm5, %xmm4
    divsd   %xmm4, %xmm2
    movsd   %xmm2, -58972(%ebp, %esi, 8)
    divsd   %xmm4, %xmm3
    movsd   %xmm3, -54860(%ebp, %esi, 8)
    incl    %esi
    cmpl    $256, %esi  # # imm = 0x100
    je      LBB0_10
.p2align 4, 0x90
LBB0_7:
    movl    %ecx, %eax
    imull   %edi
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %ecx
    cmovgl  %edx, %ecx
    leal    511(%ecx), %eax
    testl   %ecx, %ecx
    cmovnsl %ecx, %eax
    andl    $-512, %eax  # # imm = 0xFE00
    negl    %eax
    addl    %ecx, %eax
    addl    $-256, %eax
    xorps   %xmm2, %xmm2
    cvtsi2sd %eax, %xmm2
    movl    %ecx, %eax
    imull   %edi
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %ecx
    cmovgl  %edx, %ecx
    leal    511(%ecx), %eax
    testl   %ecx, %ecx
    cmovnsl %ecx, %eax
    andl    $-512, %eax  # # imm = 0xFE00
    negl    %eax
    addl    %ecx, %eax
    addl    $-256, %eax
    xorps   %xmm3, %xmm3
    cvtsi2sd %eax, %xmm3
    mulsd   %xmm0, %xmm2
    mulsd   %xmm0, %xmm3
    ucomisd %xmm1, %xmm2
    jne     LBB0_9
    jp      LBB0_9
    ucomisd %xmm1, %xmm3
    jne     LBB0_9
    jnp     LBB0_7
    jmp     LBB0_9
LBB0_10:
    xorl    %esi, %esi
    movl    $-2092037281, %edi  # # imm = 0x834E0B5F
    xorpd   %xmm1, %xmm1
    jmp     LBB0_11
LBB0_13:
    movapd  %xmm3, %xmm4
    mulsd   %xmm3, %xmm4
    movapd  %xmm2, %xmm5
    mulsd   %xmm2, %xmm5
    addsd   %xmm4, %xmm5
    xorps   %xmm4, %xmm4
    sqrtsd  %xmm5, %xmm4
    divsd   %xmm4, %xmm2
    movsd   %xmm2, -50748(%ebp, %esi, 8)
    divsd   %xmm4, %xmm3
    movsd   %xmm3, -46636(%ebp, %esi, 8)
    incl    %esi
    cmpl    $256, %esi  # # imm = 0x100
    je      LBB0_14
.p2align 4, 0x90
LBB0_11:
    movl    %ecx, %eax
    imull   %edi
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %ecx
    cmovgl  %edx, %ecx
    leal    511(%ecx), %eax
    testl   %ecx, %ecx
    cmovnsl %ecx, %eax
    andl    $-512, %eax  # # imm = 0xFE00
    negl    %eax
    addl    %ecx, %eax
    addl    $-256, %eax
    xorps   %xmm2, %xmm2
    cvtsi2sd %eax, %xmm2
    movl    %ecx, %eax
    imull   %edi
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %ecx
    cmovgl  %edx, %ecx
    leal    511(%ecx), %eax
    testl   %ecx, %ecx
    cmovnsl %ecx, %eax
    andl    $-512, %eax  # # imm = 0xFE00
    negl    %eax
    addl    %ecx, %eax
    addl    $-256, %eax
    xorps   %xmm3, %xmm3
    cvtsi2sd %eax, %xmm3
    mulsd   %xmm0, %xmm2
    mulsd   %xmm0, %xmm3
    ucomisd %xmm1, %xmm2
    jne     LBB0_13
    jp      LBB0_13
    ucomisd %xmm1, %xmm3
    jne     LBB0_13
    jnp     LBB0_11
    jmp     LBB0_13
LBB0_14:
    xorl    %esi, %esi
    movl    $-2092037281, %edi  # # imm = 0x834E0B5F
    xorpd   %xmm1, %xmm1
    jmp     LBB0_15
LBB0_17:
    movapd  %xmm3, %xmm4
    mulsd   %xmm3, %xmm4
    movapd  %xmm2, %xmm5
    mulsd   %xmm2, %xmm5
    addsd   %xmm4, %xmm5
    xorps   %xmm4, %xmm4
    sqrtsd  %xmm5, %xmm4
    divsd   %xmm4, %xmm2
    movsd   %xmm2, -42524(%ebp, %esi, 8)
    divsd   %xmm4, %xmm3
    movsd   %xmm3, -38412(%ebp, %esi, 8)
    incl    %esi
    cmpl    $256, %esi  # # imm = 0x100
    je      LBB0_18
.p2align 4, 0x90
LBB0_15:
    movl    %ecx, %eax
    imull   %edi
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %ecx
    cmovgl  %edx, %ecx
    leal    511(%ecx), %eax
    testl   %ecx, %ecx
    cmovnsl %ecx, %eax
    andl    $-512, %eax  # # imm = 0xFE00
    negl    %eax
    addl    %ecx, %eax
    addl    $-256, %eax
    xorps   %xmm2, %xmm2
    cvtsi2sd %eax, %xmm2
    movl    %ecx, %eax
    imull   %edi
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %ecx
    cmovgl  %edx, %ecx
    leal    511(%ecx), %eax
    testl   %ecx, %ecx
    cmovnsl %ecx, %eax
    andl    $-512, %eax  # # imm = 0xFE00
    negl    %eax
    addl    %ecx, %eax
    addl    $-256, %eax
    xorps   %xmm3, %xmm3
    cvtsi2sd %eax, %xmm3
    mulsd   %xmm0, %xmm2
    mulsd   %xmm0, %xmm3
    ucomisd %xmm1, %xmm2
    jne     LBB0_17
    jp      LBB0_17
    ucomisd %xmm1, %xmm3
    jne     LBB0_17
    jnp     LBB0_15
    jmp     LBB0_17
LBB0_18:
    pushl   %edx
    calll   .Lksvg_pcrel_get_pc_edx
1:
    movaps  (LCPI0_1-1b)(%edx), %xmm0
    movaps  %xmm0, -69768(%ebp)
    movaps  (LCPI0_1+16-1b)(%edx), %xmm0
    movaps  %xmm0, -69752(%ebp)
    movaps  (LCPI0_1+32-1b)(%edx), %xmm0
    movaps  %xmm0, -69736(%ebp)
    movaps  (LCPI0_1+48-1b)(%edx), %xmm0
    movaps  %xmm0, -69720(%ebp)
    movaps  (LCPI0_1+64-1b)(%edx), %xmm0
    movaps  %xmm0, -69704(%ebp)
    movaps  (LCPI0_1+80-1b)(%edx), %xmm0
    movaps  %xmm0, -69688(%ebp)
    movaps  (LCPI0_1+96-1b)(%edx), %xmm0
    movaps  %xmm0, -69672(%ebp)
    movaps  (LCPI0_1+112-1b)(%edx), %xmm0
    movaps  %xmm0, -69656(%ebp)
    movaps  (LCPI0_1+128-1b)(%edx), %xmm0
    movaps  %xmm0, -69640(%ebp)
    movaps  (LCPI0_1+144-1b)(%edx), %xmm0
    movaps  %xmm0, -69624(%ebp)
    movaps  (LCPI0_1+160-1b)(%edx), %xmm0
    movaps  %xmm0, -69608(%ebp)
    movaps  (LCPI0_1+176-1b)(%edx), %xmm0
    movaps  %xmm0, -69592(%ebp)
    movaps  (LCPI0_1+192-1b)(%edx), %xmm0
    movaps  %xmm0, -69576(%ebp)
    movaps  (LCPI0_1+208-1b)(%edx), %xmm0
    movaps  %xmm0, -69560(%ebp)
    movaps  (LCPI0_1+224-1b)(%edx), %xmm0
    movaps  %xmm0, -69544(%ebp)
    movapd  (LCPI0_1+240-1b)(%edx), %xmm0
    movapd  %xmm0, -69528(%ebp)
    popl    %edx
    movl    $256, %esi  # # imm = 0x100
    movl    $-2092037281, %edi  # # imm = 0x834E0B5F
.p2align 4, 0x90
LBB0_19:
    movl    %ecx, %eax
    imull   %edi
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %ecx
    cmovgl  %edx, %ecx
    leal    255(%ecx), %eax
    testl   %ecx, %ecx
    cmovnsl %ecx, %eax
    andl    $-256, %eax
    movl    %ecx, %edx
    subl    %eax, %edx
    movzbl  -69769(%ebp, %esi), %eax
    movb    -69768(%ebp, %edx), %ah
    movb    %ah, -69769(%ebp, %esi)
    movb    %al, -69768(%ebp, %edx)
    decl    %esi
    cmpl    $1, %esi
    ja      LBB0_19
# # %bb.20:
    xorl    %eax, %eax
    movl    $15033, %ecx  # # imm = 0x3AB9
.p2align 4, 0x90
LBB0_21:
    movzbl  -69768(%ebp, %eax), %edx
    movb    %dl, -69512(%ebp, %eax)
    movl    %edx, -69252(%ebp, %eax, 4)
    movl    %edx, -68228(%ebp, %eax, 4)
    movsd   -67196(%ebp, %eax, 8), %xmm0  # # xmm0 = mem[0],zero
    movsd   -63084(%ebp, %eax, 8), %xmm1  # # xmm1 = mem[0],zero
    movsd   %xmm0, -65148(%ebp, %eax, 8)
    movsd   %xmm1, -61036(%ebp, %eax, 8)
    movsd   %xmm0, -94432(%ebp, %ecx, 4)
    movsd   %xmm1, -77984(%ebp, %ecx, 4)
    movsd   %xmm0, -86240(%ebp, %ecx, 4)
    movsd   %xmm1, -69792(%ebp, %ecx, 4)
    movsd   -58972(%ebp, %eax, 8), %xmm0  # # xmm0 = mem[0],zero
    movsd   -54860(%ebp, %eax, 8), %xmm1  # # xmm1 = mem[0],zero
    movsd   %xmm0, -56924(%ebp, %eax, 8)
    movsd   %xmm1, -52812(%ebp, %eax, 8)
    movsd   %xmm0, -94424(%ebp, %ecx, 4)
    movsd   %xmm1, -77976(%ebp, %ecx, 4)
    movsd   %xmm0, -86232(%ebp, %ecx, 4)
    movsd   %xmm1, -69784(%ebp, %ecx, 4)
    movsd   -50748(%ebp, %eax, 8), %xmm0  # # xmm0 = mem[0],zero
    movsd   -46636(%ebp, %eax, 8), %xmm1  # # xmm1 = mem[0],zero
    movsd   %xmm0, -48700(%ebp, %eax, 8)
    movsd   %xmm1, -44588(%ebp, %eax, 8)
    movsd   %xmm0, -94416(%ebp, %ecx, 4)
    movsd   %xmm1, -77968(%ebp, %ecx, 4)
    movsd   %xmm0, -86224(%ebp, %ecx, 4)
    movsd   %xmm1, -69776(%ebp, %ecx, 4)
    movsd   -42524(%ebp, %eax, 8), %xmm0  # # xmm0 = mem[0],zero
    movsd   -38412(%ebp, %eax, 8), %xmm1  # # xmm1 = mem[0],zero
    movsd   %xmm0, -40476(%ebp, %eax, 8)
    movsd   %xmm1, -36364(%ebp, %eax, 8)
    movsd   %xmm0, -94408(%ebp, %ecx, 4)
    movsd   %xmm1, -77960(%ebp, %ecx, 4)
    movsd   %xmm0, -86216(%ebp, %ecx, 4)
    movsd   %xmm1, -69768(%ebp, %ecx, 4)
    incl    %eax
    addl    $8, %ecx
    cmpl    $258, %eax  # # imm = 0x102
    jne     LBB0_21
# # %bb.22:
    imull   12(%ebp), %ebx
    shll    $2, %ebx
    movl    8(%ebp), %edi
    movl    %ebx, %ecx
    shrl    $2, %ecx
    xorl    %eax, %eax
    rep     stosl
    cmpl    $0, 52(%ebp)
    setg    -13(%ebp)  # # 1-byte Folded Spill
    cmpl    $0, 56(%ebp)
    setg    %al
    movl    60(%ebp), %ecx
    cmpl    $32, %ecx
    movl    $32, %edx
    cmovll  %ecx, %edx
    movl    %edx, -36(%ebp)  # # 4-byte Spill
    movl    24(%ebp), %ecx
    cmpl    32(%ebp), %ecx
    jge     LBB0_36
# # %bb.23:
    orb     %al, -13(%ebp)  # # 1-byte Folded Spill
    xorl    %eax, %eax
    movsd   -69784(%ebp), %xmm0  # # xmm0 = [1.0E+0,0.0E+0]
    movsd   %xmm0, -32(%ebp)  # # 8-byte Spill
    cmpl    $1, 64(%ebp)
    sete    %al
    je      LBB0_25
# # %bb.24:
    xorps   %xmm0, %xmm0
    movsd   %xmm0, -32(%ebp)  # # 8-byte Spill
LBB0_25:
    movl    52(%ebp), %ecx
    addl    $4096, %ecx  # # imm = 0x1000
    movl    %ecx, -88(%ebp)  # # 4-byte Spill
    movzbl  -13(%ebp), %ecx  # # 1-byte Folded Reload
    movl    %ecx, -80(%ebp)  # # 4-byte Spill
    movsd   -69832(%ebp, %eax, 8), %xmm0  # # xmm0 = mem[0],zero
    movsd   %xmm0, -48(%ebp)  # # 8-byte Spill
    movsd   44(%ebp), %xmm0  # # xmm0 = mem[0],zero
    movddup %xmm0, %xmm0  # # xmm0 = xmm0[0,0]
    movapd  %xmm0, -296(%ebp)  # # 16-byte Spill
    movsd   36(%ebp), %xmm0  # # xmm0 = mem[0],zero
    movddup %xmm0, %xmm0  # # xmm0 = xmm0[0,0]
    movapd  %xmm0, -312(%ebp)  # # 16-byte Spill
    movl    24(%ebp), %eax
    movl    %eax, -20(%ebp)  # # 4-byte Spill
    jmp     LBB0_26
.p2align 4, 0x90
LBB0_35:
    movl    -20(%ebp), %eax  # # 4-byte Reload
    incl    %eax
    movl    %eax, -20(%ebp)  # # 4-byte Spill
    cmpl    32(%ebp), %eax
    je      LBB0_36
LBB0_26:  # # =>This Loop Header: Depth=1
                                        # #     Child Loop BB0_28 Depth 2
                                        # #     Child Loop BB0_33 Depth 2
                                        # #       Child Loop BB0_38 Depth 3
    cmpl    $0, 60(%ebp)
    jle     LBB0_31
    movl    -20(%ebp), %ecx  # # 4-byte Reload
    movl    %ecx, %eax
    subl    24(%ebp), %eax
    xorps   %xmm0, %xmm0
    cvtsi2sd %eax, %xmm0
    xorps   %xmm1, %xmm1
    cvtsi2sd %ecx, %xmm1
    mulsd   76(%ebp), %xmm1
    addsd   92(%ebp), %xmm1
    divsd   124(%ebp), %xmm1
    unpcklpd %xmm0, %xmm1  # # xmm1 = xmm1[0],xmm0[0]
    mulpd   -296(%ebp), %xmm1  # # 16-byte Folded Reload
    leal    -1400(%ebp), %esi
    movl    -36(%ebp), %edx  # # 4-byte Reload
    movl    56(%ebp), %edi
    jmp     LBB0_28
.p2align 4, 0x90
LBB0_30:
    movl    -72(%ebp), %edx  # # 4-byte Reload
    movzbl  %bl, %eax
    movl    %eax, (%esi)
    movzbl  %cl, %eax
    movl    %eax, 4(%esi)
    movsd   -104(%ebp), %xmm2  # # 8-byte Reload
                                        # # xmm2 = mem[0],zero
    subsd   %xmm0, %xmm2
    movsd   %xmm2, 8(%esi)
    movapd  %xmm2, %xmm0
    addsd   -69800(%ebp), %xmm0
    movsd   %xmm0, 16(%esi)
    movapd  %xmm2, %xmm0
    mulsd   %xmm2, %xmm0
    addsd   %xmm2, %xmm2
    movsd   -69808(%ebp), %xmm1  # # xmm1 = [3.0E+0,0.0E+0]
    subsd   %xmm2, %xmm1
    mulsd   %xmm0, %xmm1
    movl    -80(%ebp), %ecx  # # 4-byte Reload
                                        # # kill: def $cl killed $cl killed $ecx
    shll    %cl, %edi
    movsd   %xmm1, 24(%esi)
    movapd  -136(%ebp), %xmm0  # # 16-byte Reload
    addpd   %xmm0, %xmm0
    addl    $32, %esi
    decl    %edx
    movapd  %xmm0, %xmm1
    je      LBB0_31
LBB0_28:  # #   Parent Loop BB0_26 Depth=1
    movapd  %xmm1, -136(%ebp)  # # 16-byte Spill
    movl    %edx, -72(%ebp)  # # 4-byte Spill
    addsd   -69792(%ebp), %xmm1
    movsd   %xmm1, -104(%ebp)  # # 8-byte Spill
    movsd   %xmm1, (%esp)
    fldl    (%esp)
    frndint
    fstpl   -216(%ebp)
    movsd   -216(%ebp), %xmm0  # # xmm0 = mem[0],zero
    cvttsd2si %xmm0, %ebx
    leal    1(%ebx), %ecx
    testl   %edi, %edi
    setg    %al
    andb    -13(%ebp), %al  # # 1-byte Folded Reload
    cmpb    $1, %al
    jne     LBB0_30
    movsd   %xmm0, -56(%ebp)  # # 8-byte Spill
    movaps  -136(%ebp), %xmm0  # # 16-byte Reload
    movhps  %xmm0, (%esp)
    movl    %ecx, -24(%ebp)  # # 4-byte Spill
    fldl    (%esp)
    frndint
    movsd   -56(%ebp), %xmm0  # # 8-byte Reload
                                        # # xmm0 = mem[0],zero
    fstpl   -208(%ebp)
    cvttsd2si -208(%ebp), %eax
    addl    %edi, %eax
    addl    $4096, %eax  # # imm = 0x1000
    cmpl    %ebx, %eax
    movl    %edi, %ecx
    movl    $0, %edx
    cmovgl  %edx, %ecx
    subl    %ecx, %ebx
    movl    -24(%ebp), %ecx  # # 4-byte Reload
    cmpl    %eax, %ecx
    movl    %edi, %eax
    cmovll  %edx, %eax
    subl    %eax, %ecx
    jmp     LBB0_30
.p2align 4, 0x90
LBB0_31:
    movl    20(%ebp), %eax
    cmpl    28(%ebp), %eax
    jge     LBB0_35
    movl    -20(%ebp), %eax  # # 4-byte Reload
    imull   12(%ebp), %eax
    movl    8(%ebp), %ecx
    leal    (%ecx, %eax, 4), %eax
    movl    %eax, -76(%ebp)  # # 4-byte Spill
    movl    20(%ebp), %ecx
    jmp     LBB0_33
.p2align 4, 0x90
LBB0_34:
    xorpd   %xmm0, %xmm0
    movapd  %xmm0, -72(%ebp)  # # 16-byte Spill
    xorpd   %xmm3, %xmm3
LBB0_45:
    movapd  %xmm3, -104(%ebp)  # # 16-byte Spill
    movsd   -32(%ebp), %xmm0  # # 8-byte Reload
                                        # # xmm0 = mem[0],zero
    addsd   %xmm3, %xmm0
    mulsd   -48(%ebp), %xmm0  # # 8-byte Folded Reload
    movsd   -69816(%ebp), %xmm1  # # xmm1 = [5.0E-1,0.0E+0]
    addsd   %xmm1, %xmm0
    movsd   %xmm0, (%esp)
    fldl    (%esp)
    frndint
    fstpl   -168(%ebp)
    cvttsd2si -168(%ebp), %esi
    cmpl    $255, %esi
    movl    $255, %eax
    cmovgel %eax, %esi
    testl   %esi, %esi
    movl    $0, %eax
    cmovlel %eax, %esi
    xorl    %ebx, %ebx
    movapd  -104(%ebp), %xmm0  # # 16-byte Reload
    unpckhpd %xmm0, %xmm0  # # xmm0 = xmm0[1,1]
    addsd   -32(%ebp), %xmm0  # # 8-byte Folded Reload
    mulsd   -48(%ebp), %xmm0  # # 8-byte Folded Reload
    addsd   -69816(%ebp), %xmm0
    movsd   %xmm0, (%esp)
    fldl    (%esp)
    frndint
    fstpl   -160(%ebp)
    cvttsd2si -160(%ebp), %edi
    cmpl    $255, %edi
    movl    $255, %eax
    cmovgel %eax, %edi
    testl   %edi, %edi
    cmovlel %ebx, %edi
    movsd   -32(%ebp), %xmm0  # # 8-byte Reload
                                        # # xmm0 = mem[0],zero
    addsd   -72(%ebp), %xmm0  # # 16-byte Folded Reload
    mulsd   -48(%ebp), %xmm0  # # 8-byte Folded Reload
    addsd   -69816(%ebp), %xmm0
    movsd   %xmm0, (%esp)
    fldl    (%esp)
    frndint
    fstpl   -184(%ebp)
    cvttsd2si -184(%ebp), %ebx
    cmpl    $255, %ebx
    movl    $255, %eax
    cmovgel %eax, %ebx
    testl   %ebx, %ebx
    movl    $0, %eax
    cmovlel %eax, %ebx
    movapd  -72(%ebp), %xmm0  # # 16-byte Reload
    unpckhpd %xmm0, %xmm0  # # xmm0 = xmm0[1,1]
    addsd   -32(%ebp), %xmm0  # # 8-byte Folded Reload
    mulsd   -48(%ebp), %xmm0  # # 8-byte Folded Reload
    addsd   -69816(%ebp), %xmm0
    movsd   %xmm0, (%esp)
    fldl    (%esp)
    frndint
    fstpl   -176(%ebp)
    cvttsd2si -176(%ebp), %eax
    cmpl    $255, %eax
    movl    $255, %ecx
    cmovgel %ecx, %eax
    testl   %eax, %eax
    movl    $0, %ecx
    cmovlel %ecx, %eax
    shll    $24, %eax
    orl     %ebx, %eax
    shll    $16, %esi
    shll    $8, %edi
    orl     %esi, %edi
    orl     %eax, %edi
    movl    -76(%ebp), %eax  # # 4-byte Reload
    movl    -84(%ebp), %ecx  # # 4-byte Reload
    movl    %edi, (%eax, %ecx, 4)
    incl    %ecx
    cmpl    28(%ebp), %ecx
    je      LBB0_35
LBB0_33:  # #   Parent Loop BB0_26 Depth=1
                                        # # =>  This Loop Header: Depth=2
                                        # #       Child Loop BB0_38 Depth 3
    cmpl    $0, 60(%ebp)
    movl    %ecx, -84(%ebp)  # # 4-byte Spill
    jle     LBB0_34
    movl    %ecx, %eax
    subl    20(%ebp), %eax
    xorps   %xmm0, %xmm0
    cvtsi2sd %eax, %xmm0
    xorps   %xmm1, %xmm1
    cvtsi2sd %ecx, %xmm1
    mulsd   68(%ebp), %xmm1
    addsd   84(%ebp), %xmm1
    divsd   116(%ebp), %xmm1
    unpcklpd %xmm0, %xmm1  # # xmm1 = xmm1[0],xmm0[0]
    mulpd   -312(%ebp), %xmm1  # # 16-byte Folded Reload
    xorpd   %xmm3, %xmm3
    leal    -1400(%ebp), %eax
    movl    %eax, -56(%ebp)  # # 4-byte Spill
    movl    -36(%ebp), %eax  # # 4-byte Reload
    xorpd   %xmm0, %xmm0
    movapd  %xmm0, -72(%ebp)  # # 16-byte Spill
    movsd   -69784(%ebp), %xmm4  # # xmm4 = [1.0E+0,0.0E+0]
    movl    52(%ebp), %edi
    jmp     LBB0_38
.p2align 4, 0x90
LBB0_44:
    movapd  -104(%ebp), %xmm3  # # 16-byte Reload
    movl    -24(%ebp), %eax  # # 4-byte Reload
    movapd  -232(%ebp), %xmm4  # # 16-byte Reload
    movddup %xmm4, %xmm2  # # xmm2 = xmm4[0,0]
    divpd   %xmm2, %xmm0
    addpd   %xmm0, %xmm3
    divpd   %xmm2, %xmm1
    movapd  -72(%ebp), %xmm0  # # 16-byte Reload
    addpd   %xmm1, %xmm0
    movapd  %xmm0, -72(%ebp)  # # 16-byte Spill
    movapd  -136(%ebp), %xmm1  # # 16-byte Reload
    addpd   %xmm1, %xmm1
    addsd   %xmm4, %xmm4
    addl    $32, -56(%ebp)  # # 4-byte Folded Spill
    decl    %eax
    movl    52(%ebp), %edi
    je      LBB0_45
LBB0_38:  # #   Parent Loop BB0_26 Depth=1
                                        # #     Parent Loop BB0_33 Depth=2
    movaps  %xmm4, -232(%ebp)  # # 16-byte Spill
    movl    %eax, -24(%ebp)  # # 4-byte Spill
    movapd  %xmm3, -104(%ebp)  # # 16-byte Spill
    xorl    %esi, %esi
    cmpb    $0, -13(%ebp)  # # 1-byte Folded Reload
    movapd  %xmm1, -136(%ebp)  # # 16-byte Spill
    je      LBB0_40
    movhpd  %xmm1, (%esp)
    fldl    (%esp)
    frndint
    movapd  -136(%ebp), %xmm1  # # 16-byte Reload
    fstpl   -200(%ebp)
    cvttsd2si -200(%ebp), %esi
    addl    -88(%ebp), %esi  # # 4-byte Folded Reload
LBB0_40:
    addsd   -69792(%ebp), %xmm1
    movsd   %xmm1, -120(%ebp)  # # 8-byte Spill
    movsd   %xmm1, (%esp)
    fldl    (%esp)
    frndint
    movsd   -120(%ebp), %xmm1  # # 8-byte Reload
                                        # # xmm1 = mem[0],zero
    fstpl   -192(%ebp)
    movsd   -192(%ebp), %xmm0  # # xmm0 = mem[0],zero
    cvttsd2si %xmm0, %ecx
    leal    1(%ecx), %eax
    subsd   %xmm0, %xmm1
    movsd   %xmm1, -280(%ebp)
    movapd  %xmm1, %xmm0
    addsd   -69800(%ebp), %xmm0
    movsd   %xmm0, -272(%ebp)
    testl   %edi, %edi
    jle     LBB0_42
    cmpl    %ecx, %esi
    movl    %edi, %edx
    movl    $0, %ebx
    cmovgl  %ebx, %edx
    subl    %edx, %ecx
    cmpl    %esi, %eax
    movl    %edi, %edx
    cmovll  %ebx, %edx
    subl    %edx, %eax
LBB0_42:
    movzbl  %cl, %esi
    movzbl  %al, %eax
    movl    -56(%ebp), %ecx  # # 4-byte Reload
    movl    (%ecx), %edi
    movl    4(%ecx), %edx
    movl    %edx, -152(%ebp)  # # 4-byte Spill
    movl    -69252(%ebp, %esi, 4), %ebx
    movl    -69252(%ebp, %eax, 4), %esi
    movl    %esi, -120(%ebp)  # # 4-byte Spill
    leal    (%ebx, %edi), %eax
    movzbl  -69252(%ebp, %eax, 4), %eax
    addl    %esi, %edi
    movzbl  -69252(%ebp, %edi, 4), %esi
    addl    %edx, %ebx
    movzbl  -69252(%ebp, %ebx, 4), %ebx
    shll    $5, %eax
    shll    $5, %esi
    shll    $5, %ebx
    movups  8(%ecx), %xmm0
    movddup 8(%ecx), %xmm2  # # xmm2 = mem[0,0]
    movapd  %xmm2, -360(%ebp)  # # 16-byte Spill
    movaps  %xmm0, -264(%ebp)
    movapd  %xmm1, %xmm0
    mulsd   %xmm1, %xmm0
    addsd   %xmm1, %xmm1
    movsd   -69808(%ebp), %xmm6  # # xmm6 = [3.0E+0,0.0E+0]
    subsd   %xmm1, %xmm6
    mulsd   %xmm0, %xmm6
    movsd   %xmm6, -248(%ebp)
    movsd   24(%ecx), %xmm0  # # xmm0 = mem[0],zero
    movaps  %xmm0, -376(%ebp)  # # 16-byte Spill
    movsd   %xmm0, -240(%ebp)
    movddup -280(%ebp), %xmm3  # # xmm3 = mem[0,0]
    movddup -272(%ebp), %xmm5  # # xmm5 = mem[0,0]
    leal    -34300(%ebp), %edi
    movupd  (%edi, %eax), %xmm0
    mulpd   %xmm3, %xmm0
    movapd  %xmm3, %xmm4
    movapd  %xmm3, -344(%ebp)  # # 16-byte Spill
    movupd  16448(%edi, %eax), %xmm3
    movl    %eax, %edx
    mulpd   %xmm2, %xmm3
    addpd   %xmm0, %xmm3
    movupd  (%edi, %esi), %xmm0
    mulpd   %xmm5, %xmm0
    movapd  %xmm5, -328(%ebp)  # # 16-byte Spill
    movupd  16448(%edi, %esi), %xmm7
    movl    %esi, %ecx
    mulpd   %xmm2, %xmm7
    addpd   %xmm0, %xmm7
    movupd  (%edi, %ebx), %xmm0
    mulpd   %xmm4, %xmm0
    movddup -256(%ebp), %xmm4  # # xmm4 = mem[0,0]
    movupd  16448(%edi, %ebx), %xmm2
    mulpd   %xmm4, %xmm2
    addpd   %xmm0, %xmm2
    movl    -120(%ebp), %eax  # # 4-byte Reload
    addl    -152(%ebp), %eax  # # 4-byte Folded Reload
    movzbl  -69252(%ebp, %eax, 4), %esi
    shll    $5, %esi
    movupd  (%edi, %esi), %xmm1
    mulpd   %xmm5, %xmm1
    movupd  16448(%edi, %esi), %xmm0
    mulpd   %xmm4, %xmm0
    addpd   %xmm1, %xmm0
    movddup %xmm6, %xmm1  # # xmm1 = xmm6[0,0]
    movapd  %xmm1, -152(%ebp)  # # 16-byte Spill
    subpd   %xmm3, %xmm7
    mulpd   %xmm1, %xmm7
    addpd   %xmm3, %xmm7
    subpd   %xmm2, %xmm0
    mulpd   %xmm1, %xmm0
    addpd   %xmm2, %xmm0
    movddup -376(%ebp), %xmm1  # # 16-byte Folded Reload
                                        # # xmm1 = mem[0,0]
    movapd  %xmm1, -120(%ebp)  # # 16-byte Spill
    subpd   %xmm7, %xmm0
    mulpd   %xmm1, %xmm0
    addpd   %xmm7, %xmm0
    movupd  16(%edi, %edx), %xmm1
    movapd  -344(%ebp), %xmm5  # # 16-byte Reload
    mulpd   %xmm5, %xmm1
    movupd  16464(%edi, %edx), %xmm2
    movapd  -360(%ebp), %xmm3  # # 16-byte Reload
    mulpd   %xmm3, %xmm2
    addpd   %xmm1, %xmm2
    movupd  16464(%edi, %ecx), %xmm7
    mulpd   %xmm3, %xmm7
    movupd  16(%edi, %ecx), %xmm1
    movapd  -328(%ebp), %xmm6  # # 16-byte Reload
    mulpd   %xmm6, %xmm1
    addpd   %xmm1, %xmm7
    movupd  16(%edi, %ebx), %xmm1
    mulpd   %xmm5, %xmm1
    movupd  16464(%edi, %ebx), %xmm3
    mulpd   %xmm4, %xmm3
    addpd   %xmm1, %xmm3
    movupd  16(%edi, %esi), %xmm5
    mulpd   %xmm6, %xmm5
    movupd  16464(%edi, %esi), %xmm1
    mulpd   %xmm4, %xmm1
    addpd   %xmm5, %xmm1
    subpd   %xmm2, %xmm7
    movapd  -152(%ebp), %xmm4  # # 16-byte Reload
    mulpd   %xmm4, %xmm7
    addpd   %xmm2, %xmm7
    subpd   %xmm3, %xmm1
    mulpd   %xmm4, %xmm1
    addpd   %xmm3, %xmm1
    subpd   %xmm7, %xmm1
    mulpd   -120(%ebp), %xmm1  # # 16-byte Folded Reload
    addpd   %xmm7, %xmm1
    cmpl    $1, 64(%ebp)
    je      LBB0_44
    pcmpeqd %xmm2, %xmm2
    psrlq   $1, %xmm2
    andpd   %xmm2, %xmm0
    andpd   %xmm2, %xmm1
    jmp     LBB0_44
LBB0_36:
    fldcw   -69840(%ebp)
    addl    $69868, %esp  # # imm = 0x1108C
    popl    %esi
    popl    %edi
    popl    %ebx
    popl    %ebp
    retl
.cfi_endproc
                                        # # -- End function
    ////    SIZE(SYM(ksvgTurbulenceApplySse2_i386))
