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
    CONST4_SECTION
.p2align 2, 0x0
LCPI0_0: .long 0xfffffe00
LCPI0_1: .long 0xffffff00
LCPI0_18: .long 255
    CONST16_SECTION
.p2align 4, 0x0
LCPI0_2:
    TURB_DBL_1_256
    TURB_DBL_1_256
LCPI0_14:
    .space 8
    TURB_DBL_1
LCPI0_16:
    TURB_DBL_255
    TURB_DBL_255
LCPI0_17:
    TURB_DBL_0_5
    TURB_DBL_0_5
LCPI0_21:
    TURB_DBL_1
    TURB_DBL_1
LCPI0_22:
    TURB_DBL_127_5
    TURB_DBL_127_5
LCPI0_25:
    .long 16
    .long 8
    .space 8
LCPI0_26:
    .space 16
    CONST_SECTION
.p2align 5, 0x0
LCPI0_3:
    TURB_PERMUTATION_DATA
    CONST8_SECTION
.p2align 3, 0x0
LCPI0_11: TURB_DBL_4096
LCPI0_12: TURB_DBL_NEG_1
LCPI0_13: TURB_DBL_3
LCPI0_15:
.long 4294967295  # double NaN
.long 2147483647
LCPI0_19:
.long 0  # double 255
.long 1081073664
LCPI0_20:
.long 0  # double 0.5
.long 1071644672
LCPI0_23:
.long 0  # double 1
.long 1072693248
LCPI0_24:
.long 0  # double 127.5
.long 1080025088
LCPI0_27:
.long 0  # double 0.00390625
.long 1064304640
    TEXT_SECTION
.globl SYM(ksvgTurbulenceApplyAvx2_i386)
.Lksvg_pcrel_get_pc_edx:
    movl    (%esp), %edx
    retl

TYPE(ksvgTurbulenceApplyAvx2_i386, @function)
.p2align 4, 0x90
    SYM(ksvgTurbulenceApplyAvx2_i386):
.cfi_startproc
    pushl   %ebp
.cfi_def_cfa_offset 8
.cfi_offset %ebp, -8
    movl    %esp, %ebp
.cfi_def_cfa_register %ebp
    pushl   %ebx
    pushl   %edi
    pushl   %esi
    andl    $-32, %esp
    subl    $69664, %esp  # imm = 0x10FE0
.cfi_offset %esi, -20
.cfi_offset %edi, -16
.cfi_offset %ebx, -12
	# Hot constants cached in the local frame.
    movl    $0, -69376(%ebp)
    movl    $1085276160, -69372(%ebp)
    movl    $0, -69384(%ebp)
    movl    $3220176896, -69380(%ebp)
    movl    $0, -69392(%ebp)
    movl    $1074266112, -69388(%ebp)
    movl    $0, -69400(%ebp)
    movl    $1081073664, -69396(%ebp)
    movl    $0, -69408(%ebp)
    movl    $1071644672, -69404(%ebp)
    movl    $0, -69416(%ebp)
    movl    $1072693248, -69412(%ebp)
    movl    $0, -69424(%ebp)
    movl    $1080025088, -69420(%ebp)
    movl    $0, -69432(%ebp)
    movl    $1064304640, -69428(%ebp)
    movl    $0, -69440(%ebp)
    movl    $1072693248, -69436(%ebp)
    movl    $0, -69448(%ebp)
    movl    $1072693248, -69444(%ebp)
    movl    $0, -69456(%ebp)
    movl    $1071644672, -69452(%ebp)
    movl    $0, -69472(%ebp)
    movl    $1080025088, -69468(%ebp)
    movl    $0, -69488(%ebp)
    movl    $0, -69484(%ebp)
    movl    $0, -69480(%ebp)
    movl    $1072693248, -69476(%ebp)  # [0.0, 1.0]
    movl    $524304, -69504(%ebp)  # [16, 8, 0, 0] as dwords
    movl    132(%ebp), %eax
    testl   %eax, %eax
    jg      LBB0_2
    leal    2147483646(%eax), %ecx
    leal    2147483645(%eax), %edx
    cmpl    $2147483646, %edx  # imm = 0x7FFFFFFE
    cmovbl  %eax, %ecx
    movl    $1, %eax
    subl    %ecx, %eax
LBB0_2:
    cmpl    $2147483646, %eax  # imm = 0x7FFFFFFE
    movl    $2147483646, %ecx  # imm = 0x7FFFFFFE
    cmovbl  %eax, %ecx
    pushl   %edx
    calll   .Lksvg_pcrel_get_pc_edx
1:
    leal    (LCPI0_0-1b)(%edx), %edx
    vpbroadcastd (%edx), %xmm0  # xmm0 = [4294966784,4294966784,4294966784,4294966784]
    popl    %edx
    xorl    %edi, %edi
    movl    $-2092037281, %ebx  # imm = 0x834E0B5F
    pushl   %edx
    calll   .Lksvg_pcrel_get_pc_edx
1:
    leal    (LCPI0_1-1b)(%edx), %edx
    vpbroadcastd (%edx), %xmm1  # xmm1 = [4294967040,4294967040,4294967040,4294967040]
    popl    %edx
    vmovddup -69432(%ebp), %xmm2  # xmm2 = [3.90625E-3,3.90625E-3]
                                        # xmm2 = mem[0,0]
    vxorpd  %xmm3, %xmm3, %xmm3
    vpcmpeqd %xmm4, %xmm4, %xmm4
.p2align 4, 0x90
LBB0_3:
    movl    %ecx, %eax
    imull   %ebx
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %esi
    cmovgl  %edx, %esi
    movl    %esi, %eax
    imull   %ebx
    addl    %esi, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # imm = 0x1F31D
    movl    %esi, %ecx
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %ecx
    cmovgl  %edx, %ecx
    vmovd   %ecx, %xmm5
    vpinsrd $1, %esi, %xmm5, %xmm5
    vpsrad  $31, %xmm5, %xmm6
    vpsrld  $23, %xmm6, %xmm6
    vpaddd  %xmm6, %xmm5, %xmm6
    vpand   %xmm0, %xmm6, %xmm6
    vpsubd  %xmm6, %xmm5, %xmm5
    vpaddd  %xmm1, %xmm5, %xmm5
    vcvtdq2pd %xmm5, %xmm5
    vmulpd  %xmm2, %xmm5, %xmm5
    vcmpeqpd %xmm3, %xmm5, %xmm6
    vtestpd %xmm4, %xmm6
    jb      LBB0_3
    vmulsd  %xmm5, %xmm5, %xmm6
    vmovsd  %xmm6, 64(%esp)
    vshufpd $1, %xmm5, %xmm5, %xmm7  # xmm7 = xmm5[1,0]
    vmulsd  %xmm7, %xmm7, %xmm6
    vaddsd  64(%esp), %xmm6, %xmm6
    vsqrtsd %xmm6, %xmm6, %xmm6
    vdivsd  %xmm6, %xmm7, %xmm7
    vmovsd  %xmm7, 3788(%esp, %edi, 8)
    vdivsd  %xmm6, %xmm5, %xmm5
    vmovsd  %xmm5, 7900(%esp, %edi, 8)
    incl    %edi
    cmpl    $256, %edi  # imm = 0x100
    jne     LBB0_3
    xorl    %edi, %edi
    movl    $-2092037281, %ebx  # imm = 0x834E0B5F
    vxorpd  %xmm3, %xmm3, %xmm3
    vpcmpeqd %xmm4, %xmm4, %xmm4
.p2align 4, 0x90
LBB0_6:
    movl    %ecx, %eax
    imull   %ebx
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %esi
    cmovgl  %edx, %esi
    movl    %esi, %eax
    imull   %ebx
    addl    %esi, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # imm = 0x1F31D
    movl    %esi, %ecx
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %ecx
    cmovgl  %edx, %ecx
    vmovd   %ecx, %xmm5
    vpinsrd $1, %esi, %xmm5, %xmm5
    vpsrad  $31, %xmm5, %xmm6
    vpsrld  $23, %xmm6, %xmm6
    vpaddd  %xmm6, %xmm5, %xmm6
    vpand   %xmm0, %xmm6, %xmm6
    vpsubd  %xmm6, %xmm5, %xmm5
    vpaddd  %xmm1, %xmm5, %xmm5
    vcvtdq2pd %xmm5, %xmm5
    vmulpd  %xmm2, %xmm5, %xmm5
    vcmpeqpd %xmm3, %xmm5, %xmm6
    vtestpd %xmm4, %xmm6
    jb      LBB0_6
    vmulsd  %xmm5, %xmm5, %xmm6
    vmovsd  %xmm6, 64(%esp)
    vshufpd $1, %xmm5, %xmm5, %xmm7  # xmm7 = xmm5[1,0]
    vmulsd  %xmm7, %xmm7, %xmm6
    vaddsd  64(%esp), %xmm6, %xmm6
    vsqrtsd %xmm6, %xmm6, %xmm6
    vdivsd  %xmm6, %xmm7, %xmm7
    vmovsd  %xmm7, 12012(%esp, %edi, 8)
    vdivsd  %xmm6, %xmm5, %xmm5
    vmovsd  %xmm5, 16124(%esp, %edi, 8)
    incl    %edi
    cmpl    $256, %edi  # imm = 0x100
    jne     LBB0_6
    xorl    %edi, %edi
    movl    $-2092037281, %ebx  # imm = 0x834E0B5F
    vxorpd  %xmm3, %xmm3, %xmm3
    vpcmpeqd %xmm4, %xmm4, %xmm4
.p2align 4, 0x90
LBB0_9:
    movl    %ecx, %eax
    imull   %ebx
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %esi
    cmovgl  %edx, %esi
    movl    %esi, %eax
    imull   %ebx
    addl    %esi, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # imm = 0x1F31D
    movl    %esi, %ecx
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %ecx
    cmovgl  %edx, %ecx
    vmovd   %ecx, %xmm5
    vpinsrd $1, %esi, %xmm5, %xmm5
    vpsrad  $31, %xmm5, %xmm6
    vpsrld  $23, %xmm6, %xmm6
    vpaddd  %xmm6, %xmm5, %xmm6
    vpand   %xmm0, %xmm6, %xmm6
    vpsubd  %xmm6, %xmm5, %xmm5
    vpaddd  %xmm1, %xmm5, %xmm5
    vcvtdq2pd %xmm5, %xmm5
    vmulpd  %xmm2, %xmm5, %xmm5
    vcmpeqpd %xmm3, %xmm5, %xmm6
    vtestpd %xmm4, %xmm6
    jb      LBB0_9
    vmulsd  %xmm5, %xmm5, %xmm6
    vmovsd  %xmm6, 64(%esp)
    vshufpd $1, %xmm5, %xmm5, %xmm7  # xmm7 = xmm5[1,0]
    vmulsd  %xmm7, %xmm7, %xmm6
    vaddsd  64(%esp), %xmm6, %xmm6
    vsqrtsd %xmm6, %xmm6, %xmm6
    vdivsd  %xmm6, %xmm7, %xmm7
    vmovsd  %xmm7, 20236(%esp, %edi, 8)
    vdivsd  %xmm6, %xmm5, %xmm5
    vmovsd  %xmm5, 24348(%esp, %edi, 8)
    incl    %edi
    cmpl    $256, %edi  # imm = 0x100
    jne     LBB0_9
    xorl    %edi, %edi
    movl    $-2092037281, %ebx  # imm = 0x834E0B5F
    vxorpd  %xmm3, %xmm3, %xmm3
    vpcmpeqd %xmm4, %xmm4, %xmm4
.p2align 4, 0x90
LBB0_12:
    movl    %ecx, %eax
    imull   %ebx
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %esi
    cmovgl  %edx, %esi
    movl    %esi, %eax
    imull   %ebx
    addl    %esi, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # imm = 0x1F31D
    movl    %esi, %ecx
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # imm = 0xF4EC
    leal    (%ecx, %eax), %edx
    testl   %edx, %edx
    leal    2147483647(%ecx, %eax), %ecx
    cmovgl  %edx, %ecx
    vmovd   %ecx, %xmm5
    vpinsrd $1, %esi, %xmm5, %xmm5
    vpsrad  $31, %xmm5, %xmm6
    vpsrld  $23, %xmm6, %xmm6
    vpaddd  %xmm6, %xmm5, %xmm6
    vpand   %xmm0, %xmm6, %xmm6
    vpsubd  %xmm6, %xmm5, %xmm5
    vpaddd  %xmm1, %xmm5, %xmm5
    vcvtdq2pd %xmm5, %xmm5
    vmulpd  %xmm2, %xmm5, %xmm5
    vcmpeqpd %xmm3, %xmm5, %xmm6
    vtestpd %xmm4, %xmm6
    jb      LBB0_12
    vmulsd  %xmm5, %xmm5, %xmm6
    vmovsd  %xmm6, 64(%esp)
    vshufpd $1, %xmm5, %xmm5, %xmm7  # xmm7 = xmm5[1,0]
    vmulsd  %xmm7, %xmm7, %xmm6
    vaddsd  64(%esp), %xmm6, %xmm6
    vsqrtsd %xmm6, %xmm6, %xmm6
    vdivsd  %xmm6, %xmm7, %xmm7
    vmovsd  %xmm7, 28460(%esp, %edi, 8)
    vdivsd  %xmm6, %xmm5, %xmm5
    vmovsd  %xmm5, 32572(%esp, %edi, 8)
    incl    %edi
    cmpl    $256, %edi  # imm = 0x100
    jne     LBB0_12
    pushl   %edx
    calll   .Lksvg_pcrel_get_pc_edx
1:
    vmovaps (LCPI0_3-1b)(%edx), %ymm0
    # Permutation-identity stores below run with esp 4 bytes low (inside the
    # pushl %edx above), so each destination is compensated by +4 (1220, not
    # 1216); otherwise the table lands shifted and the shuffle corrupts it.
    vmovups %ymm0, 1220(%esp)
    vmovaps (LCPI0_3+32-1b)(%edx), %ymm0
    vmovups %ymm0, 1252(%esp)
    vmovaps (LCPI0_3+64-1b)(%edx), %ymm0
    vmovups %ymm0, 1284(%esp)
    vmovaps (LCPI0_3+96-1b)(%edx), %ymm0
    vmovups %ymm0, 1316(%esp)
    vmovaps (LCPI0_3+128-1b)(%edx), %ymm0
    vmovups %ymm0, 1348(%esp)
    vmovaps (LCPI0_3+160-1b)(%edx), %ymm0
    vmovups %ymm0, 1380(%esp)
    vmovaps (LCPI0_3+192-1b)(%edx), %ymm0
    vmovups %ymm0, 1412(%esp)
    vmovapd (LCPI0_3+224-1b)(%edx), %ymm0
    vmovupd %ymm0, 1444(%esp)
    popl    %edx
    movl    $256, %esi  # imm = 0x100
    movl    $-2092037281, %ebx  # imm = 0x834E0B5F
.p2align 4, 0x90
LBB0_15:
    movl    %ecx, %eax
    imull   %ebx
    addl    %ecx, %edx
    movl    %edx, %eax
    shrl    $31, %eax
    sarl    $16, %edx
    addl    %eax, %edx
    imull   $127773, %edx, %eax  # imm = 0x1F31D
    subl    %eax, %ecx
    imull   $16807, %ecx, %eax  # imm = 0x41A7
    imull   $-2836, %edx, %ecx  # imm = 0xF4EC
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
    movzbl  1215(%esp, %esi), %eax
    movb    1216(%esp, %edx), %ah
    movb    %ah, 1215(%esp, %esi)
    movb    %al, 1216(%esp, %edx)
    decl    %esi
    cmpl    $1, %esi
    ja      LBB0_15
    xorl    %eax, %eax
    movl    $15033, %ecx  # imm = 0x3AB9
.p2align 4, 0x90
LBB0_17:
    movzbl  1216(%esp, %eax), %edx
    movb    %dl, 1472(%esp, %eax)
    movl    %edx, 1732(%esp, %eax, 4)
    movl    %edx, 2756(%esp, %eax, 4)
    vmovsd  3788(%esp, %eax, 8), %xmm0  # xmm0 = mem[0],zero
    vmovsd  7900(%esp, %eax, 8), %xmm1  # xmm1 = mem[0],zero
    vmovsd  %xmm0, 5836(%esp, %eax, 8)
    vmovsd  %xmm1, 9948(%esp, %eax, 8)
    vmovsd  %xmm0, -23448(%esp, %ecx, 4)
    vmovsd  %xmm1, -7000(%esp, %ecx, 4)
    vmovsd  %xmm0, -15256(%esp, %ecx, 4)
    vmovsd  %xmm1, 1192(%esp, %ecx, 4)
    vmovsd  12012(%esp, %eax, 8), %xmm0  # xmm0 = mem[0],zero
    vmovsd  16124(%esp, %eax, 8), %xmm1  # xmm1 = mem[0],zero
    vmovsd  %xmm0, 14060(%esp, %eax, 8)
    vmovsd  %xmm1, 18172(%esp, %eax, 8)
    vmovsd  %xmm0, -23440(%esp, %ecx, 4)
    vmovsd  %xmm1, -6992(%esp, %ecx, 4)
    vmovsd  %xmm0, -15248(%esp, %ecx, 4)
    vmovsd  %xmm1, 1200(%esp, %ecx, 4)
    vmovsd  20236(%esp, %eax, 8), %xmm0  # xmm0 = mem[0],zero
    vmovsd  24348(%esp, %eax, 8), %xmm1  # xmm1 = mem[0],zero
    vmovsd  %xmm0, 22284(%esp, %eax, 8)
    vmovsd  %xmm1, 26396(%esp, %eax, 8)
    vmovsd  %xmm0, -23432(%esp, %ecx, 4)
    vmovsd  %xmm1, -6984(%esp, %ecx, 4)
    vmovsd  %xmm0, -15240(%esp, %ecx, 4)
    vmovsd  %xmm1, 1208(%esp, %ecx, 4)
    vmovsd  28460(%esp, %eax, 8), %xmm0  # xmm0 = mem[0],zero
    vmovq   32572(%esp, %eax, 8), %xmm1  # xmm1 = mem[0],zero
    vmovsd  %xmm0, 30508(%esp, %eax, 8)
    vmovq   %xmm1, 34620(%esp, %eax, 8)
    vmovsd  %xmm0, -23424(%esp, %ecx, 4)
    vmovq   %xmm1, -6976(%esp, %ecx, 4)
    vmovsd  %xmm0, -15232(%esp, %ecx, 4)
    vmovq   %xmm1, 1216(%esp, %ecx, 4)
    incl    %eax
    addl    $8, %ecx
    cmpl    $258, %eax  # imm = 0x102
    jne     LBB0_17
    movl    16(%ebp), %eax
    imull   12(%ebp), %eax
    shll    $2, %eax
    movl    8(%ebp), %edi
    movl    %eax, %ecx
    shrl    $2, %ecx
    xorl    %eax, %eax
    vzeroupper
    rep     stosl
    movl    52(%ebp), %edx
    testl   %edx, %edx
    setg    %ah
    cmpl    $0, 56(%ebp)
    setg    %al
    movl    60(%ebp), %ecx
    cmpl    $32, %ecx
    movl    $32, %esi
    cmovll  %ecx, %esi
    movl    %esi, 28(%esp)
    movl    24(%ebp), %ecx
    cmpl    32(%ebp), %ecx
    jge     LBB0_30
    orb     %al, %ah
    movb    %ah, 23(%esp)
    movzbl  %ah, %eax
    movl    %eax, 56(%esp)
    leal    4096(%edx), %eax
    movl    %eax, 60(%esp)
    xorl    %esi, %esi
    movl    24(%ebp), %eax
    movl    %eax, 24(%esp)
    jmp     LBB0_20
.p2align 4, 0x90
LBB0_29:
    movl    24(%esp), %eax
    incl    %eax
    movl    %eax, 24(%esp)
    cmpl    32(%ebp), %eax
    je      LBB0_30
LBB0_20:
    cmpl    $0, 60(%ebp)
    jle     LBB0_25
    movl    24(%esp), %ecx
    movl    %ecx, %eax
    subl    24(%ebp), %eax
    vxorps  %xmm6, %xmm6, %xmm6
    vcvtsi2sd %eax, %xmm6, %xmm0
    vxorps  %xmm6, %xmm6, %xmm6
    vcvtsi2sd %ecx, %xmm6, %xmm3
    vmovsd  44(%ebp), %xmm1  # xmm1 = mem[0],zero
    vmulsd  %xmm1, %xmm0, %xmm4
    vmulsd  76(%ebp), %xmm3, %xmm0
    vaddsd  92(%ebp), %xmm0, %xmm0
    vdivsd  124(%ebp), %xmm0, %xmm0
    vmulsd  %xmm1, %xmm0, %xmm5
    # Channel/generator structs relocated 192->336: at 192 they overlap the
    # ebp-addressed Hot frame constants for some stack alignments, letting
    # the per-row struct build corrupt the ratio/pack inputs. [336,1360)
    # is free (byte tables there are dead during pixels).
    leal    336(%esp), %eax
    movl    28(%esp), %ebx
    movl    56(%ebp), %edi
    jmp     LBB0_22
.p2align 4, 0x90
LBB0_24:
    movl    64(%esp), %ebx
    movzbl  %dl, %edx
    movl    %edx, (%eax)
    movzbl  %cl, %ecx
    movl    %ecx, 4(%eax)
    vsubsd  %xmm7, %xmm6, %xmm0
    vmovsd  %xmm0, 8(%eax)
    vaddsd  -69384(%ebp), %xmm0, %xmm3
    vmovsd  %xmm3, 16(%eax)
    vmulsd  %xmm0, %xmm0, %xmm3
    vaddsd  %xmm0, %xmm0, %xmm0
    vmovsd  -69392(%ebp), %xmm1  # xmm1 = [3.0E+0,0.0E+0]
    vsubsd  %xmm0, %xmm1, %xmm0
    vmulsd  %xmm0, %xmm3, %xmm0
    vmovsd  %xmm0, 24(%eax)
    movl    56(%esp), %ecx
    shll    %cl, %edi
    vaddsd  %xmm5, %xmm5, %xmm5
    vaddsd  %xmm4, %xmm4, %xmm4
    addl    $32, %eax
    decl    %ebx
    je      LBB0_25
LBB0_22:
    movl    %ebx, 64(%esp)
    vaddsd  -69376(%ebp), %xmm5, %xmm6
    vroundsd $9, %xmm6, %xmm6, %xmm7
    vcvttsd2si %xmm7, %edx
    leal    1(%edx), %ecx
    testl   %edi, %edi
    setg    %bl
    andb    23(%esp), %bl
    cmpb    $1, %bl
    jne     LBB0_24
    vroundsd $9, %xmm4, %xmm4, %xmm0
    vcvttsd2si %xmm0, %ebx
    leal    (%edi, %ebx), %esi
    addl    $4096, %esi  # imm = 0x1000
    movl    %esi, 40(%esp)
    cmpl    %edx, %esi
    movl    %edi, %esi
    movl    $0, %ebx
    cmovgl  %ebx, %esi
    subl    %esi, %edx
    cmpl    40(%esp), %ecx
    movl    %edi, %esi
    cmovll  %ebx, %esi
    subl    %esi, %ecx
    xorl    %esi, %esi
    jmp     LBB0_24
.p2align 4, 0x90
LBB0_25:
    movl    20(%ebp), %eax
    cmpl    28(%ebp), %eax
    movl    52(%ebp), %ebx
    jge     LBB0_29
    movl    24(%esp), %eax
    imull   12(%ebp), %eax
    movl    8(%ebp), %ecx
    leal    (%ecx, %eax, 4), %eax
    movl    %eax, 52(%esp)
    movl    20(%ebp), %edi
    jmp     LBB0_27
.p2align 4, 0x90
LBB0_39:
    # Fractal R/G: broadcast single-double constants (packed mem loads would
    # also pick up neighboring constants for the second lane).
    vmovddup -69440(%ebp), %xmm1  # [+1.0,+1.0] fractal offset (xmm1 dead)
    vaddpd  %xmm1, %xmm2, %xmm0
    vmovddup -69472(%ebp), %xmm1  # [127.5,127.5] fractal scale
    vmulpd  %xmm1, %xmm0, %xmm0
    vmovddup -69456(%ebp), %xmm1  # [+0.5,+0.5] rounding offset
    vaddpd  %xmm1, %xmm0, %xmm0
    vroundpd $9, %xmm0, %xmm0
    vcvttpd2dq %xmm0, %xmm0
    vextractf128 $1, %ymm2, %xmm1
    vmovsd  -69416(%ebp), %xmm3  # xmm3 = [1.0E+0,0.0E+0]
    vaddsd  %xmm3, %xmm1, %xmm2
    vmovsd  -69424(%ebp), %xmm4  # xmm4 = [1.275E+2,0.0E+0]
    vmulsd  %xmm4, %xmm2, %xmm2
    vmovsd  -69408(%ebp), %xmm6  # xmm6 = [5.0E-1,0.0E+0]
    vaddsd  %xmm6, %xmm2, %xmm2
    vroundsd $9, %xmm2, %xmm2, %xmm2
    vcvttsd2si %xmm2, %ecx
    vpcmpeqd %xmm7, %xmm7, %xmm7
    vpsrld  $24, %xmm7, %xmm7  # xmm7 = [255,255,255,255]
    cmpl    $255, %ecx
    movl    $255, %edx
    cmovgel %edx, %ecx
    vpminsd %xmm7, %xmm0, %xmm0
    testl   %ecx, %ecx
    cmovlel %esi, %ecx
    vpxor   %xmm5, %xmm5, %xmm5
    vpmaxsd %xmm5, %xmm0, %xmm5
    vshufpd $1, %xmm1, %xmm1, %xmm0  # xmm0 = xmm1[1,0]
    vaddsd  %xmm3, %xmm0, %xmm0
    vmovapd %xmm6, %xmm2
    vmulsd  %xmm4, %xmm0, %xmm0
LBB0_40:
    movl    32(%esp), %edi
    # Pack shifts [16,8,0,0] via LCPI0_25 (PC-relative): the old frame slot
    # `vmovd -69504(%ebp)` reads a clobbered slot (channel structs overlap
    # the Hot frame constants) and only sets lane0 (dropping G's <<8).
    pushl   %edx  # save 255 (live as cmov source below)
    calll   .Lksvg_pcrel_get_pc_edx
22:
    leal    (LCPI0_25-22b)(%edx), %edx
    vmovdqu (%edx), %xmm1  # [16,8,0,0] shift counts
    popl    %edx  # restore 255
    vpsllvd %xmm1, %xmm5, %xmm1
    vaddsd  %xmm2, %xmm0, %xmm0
    vroundsd $9, %xmm0, %xmm0, %xmm0
    vcvttsd2si %xmm0, %eax
    cmpl    $255, %eax
    cmovgel %edx, %eax
    testl   %eax, %eax
    cmovlel %esi, %eax
    vmovd   %xmm1, %edx
    orl     %ecx, %edx
    vpextrd $1, %xmm1, %ecx
    orl     %ecx, %edx
    shll    $24, %eax
    orl     %eax, %edx
    movl    52(%esp), %eax
    movl    %edx, (%eax, %edi, 4)
    incl    %edi
    cmpl    28(%ebp), %edi
    je      LBB0_29
LBB0_27:
    cmpl    $0, 60(%ebp)
    movl    %edi, 32(%esp)
    jle     LBB0_28
    movl    %edi, %eax
    subl    20(%ebp), %eax
    vxorps  %xmm7, %xmm7, %xmm7
    vcvtsi2sd %eax, %xmm7, %xmm0
    vxorps  %xmm7, %xmm7, %xmm7
    vcvtsi2sd %edi, %xmm7, %xmm3
    vmulsd  68(%ebp), %xmm3, %xmm3
    vaddsd  84(%ebp), %xmm3, %xmm3
    vdivsd  116(%ebp), %xmm3, %xmm3
    vmovsd  36(%ebp), %xmm1  # xmm1 = mem[0],zero
    vmulsd  %xmm1, %xmm3, %xmm3
    vmulsd  %xmm1, %xmm0, %xmm0
    vblendpd $2, -69488(%ebp), %xmm0, %xmm4  # xmm4 = xmm0[0],mem[1]
    vxorpd  %xmm2, %xmm2, %xmm2
    # (struct base relocated 192->336; see note at the row-setup leal above.)
    leal    336(%esp), %ecx
    movl    28(%esp), %eax
    jmp     LBB0_32
.p2align 4, 0x90
LBB0_36:
    xorl    %esi, %esi
    vmovapd 64(%esp), %ymm2
    vmovsd  40(%esp), %xmm3
                                        # xmm3 = mem[0],zero
    vmovapd 160(%esp), %ymm4
    movl    36(%esp), %eax
    vpermpd $85, %ymm4, %ymm1  # ymm1 = ymm4[1,1,1,1]
    vdivpd  %ymm1, %ymm0, %ymm0
    vaddpd  %ymm0, %ymm2, %ymm2
    vaddsd  %xmm3, %xmm3, %xmm3
    vaddpd  %xmm4, %xmm4, %xmm4
    addl    $32, %ecx
    decl    %eax
    movl    52(%ebp), %ebx
    je      LBB0_37
LBB0_32:
    movl    %eax, 36(%esp)
    vmovsd  %xmm3, 40(%esp)
    vaddsd  -69376(%ebp), %xmm3, %xmm0
    vroundsd $9, %xmm0, %xmm0, %xmm3
    vcvttsd2si %xmm3, %edx
    leal    1(%edx), %eax
    vsubsd  %xmm3, %xmm0, %xmm7
    vmovsd  %xmm7, 112(%esp)
    vaddsd  -69384(%ebp), %xmm7, %xmm0
    vmovsd  %xmm0, 120(%esp)
    testl   %ebx, %ebx
    vmovapd %ymm2, 64(%esp)
    vmovapd %ymm4, 160(%esp)
    jle     LBB0_34
    vroundsd $9, %xmm4, %xmm4, %xmm0
    vcvttsd2si %xmm0, %esi
    addl    60(%esp), %esi
    cmpl    %edx, %esi
    movl    %ebx, %edi
    movl    $0, %ebx
    cmovgl  %ebx, %edi
    xorl    %ebx, %ebx
    subl    %edi, %edx
    cmpl    %esi, %eax
    movl    52(%ebp), %esi
    cmovll  %ebx, %esi
    subl    %esi, %eax
LBB0_34:
    movzbl  %dl, %esi
    movzbl  %al, %edi
    movl    (%ecx), %edx
    movl    4(%ecx), %ebx
    movl    1732(%esp, %esi, 4), %eax
    movl    1732(%esp, %edi, 4), %esi
    leal    (%eax, %edx), %edi
    addl    %esi, %edx
    addl    %ebx, %eax
    addl    %ebx, %esi
    movzbl  1732(%esp, %edi, 4), %edi
    shll    $5, %edi
    vmovups 8(%ecx), %xmm0
    vmovups %xmm0, 128(%esp)
    vmulsd  %xmm7, %xmm7, %xmm0
    vaddsd  %xmm7, %xmm7, %xmm3
    vmovsd  -69392(%ebp), %xmm1  # xmm1 = [3.0E+0,0.0E+0]
    vsubsd  %xmm3, %xmm1, %xmm3
    vmulsd  %xmm3, %xmm0, %xmm0
    vmovsd  %xmm0, 144(%esp)
    vmovsd  24(%ecx), %xmm0  # xmm0 = mem[0],zero
    vmovsd  %xmm0, 152(%esp)
    vbroadcastsd 112(%esp), %ymm0
    vbroadcastsd 128(%esp), %ymm1
    leal    36684(%esp), %ebx
    vmulpd  (%ebx, %edi), %ymm0, %ymm7
    vmulpd  16448(%ebx, %edi), %ymm1, %ymm3
    movzbl  1732(%esp, %edx, 4), %edx
    shll    $5, %edx
    vbroadcastsd 120(%esp), %ymm2
    vmulpd  (%ebx, %edx), %ymm2, %ymm4
    vmulpd  16448(%ebx, %edx), %ymm1, %ymm1
    movzbl  1732(%esp, %eax, 4), %eax
    shll    $5, %eax
    vmovddup 16(%ecx), %xmm5  # xmm5 = mem[0,0]
    vbroadcastsd %xmm5, %ymm5
    vmulpd  (%ebx, %eax), %ymm0, %ymm0
    vmulpd  16448(%ebx, %eax), %ymm5, %ymm6
    movzbl  1732(%esp, %esi, 4), %eax
    shll    $5, %eax
    vmulpd  (%ebx, %eax), %ymm2, %ymm2
    vmulpd  16448(%ebx, %eax), %ymm5, %ymm5
    vaddpd  %ymm3, %ymm7, %ymm3
    vaddpd  %ymm1, %ymm4, %ymm1
    vaddpd  %ymm6, %ymm0, %ymm0
    vaddpd  %ymm5, %ymm2, %ymm2
    vbroadcastsd 144(%esp), %ymm4
    vsubpd  %ymm3, %ymm1, %ymm1
    vmulpd  %ymm1, %ymm4, %ymm1
    vaddpd  %ymm1, %ymm3, %ymm1
    vsubpd  %ymm0, %ymm2, %ymm2
    vmulpd  %ymm2, %ymm4, %ymm2
    vaddpd  %ymm2, %ymm0, %ymm0
    vbroadcastsd 152(%esp), %ymm2
    vsubpd  %ymm1, %ymm0, %ymm0
    vmulpd  %ymm0, %ymm2, %ymm0
    vaddpd  %ymm0, %ymm1, %ymm0
    cmpl    $1, 64(%ebp)
    je      LBB0_36
    vpcmpeqd %ymm7, %ymm7, %ymm7
    vpsrlq  $1, %ymm7, %ymm7
    vandpd  %ymm7, %ymm0, %ymm0
    jmp     LBB0_36
.p2align 4, 0x90
LBB0_28:
    vxorpd  %xmm2, %xmm2, %xmm2
LBB0_37:
    cmpl    $1, 64(%ebp)
    je      LBB0_39
    vmovddup -69400(%ebp), %xmm1
    vmulpd  %xmm1, %xmm2, %xmm0
    # Rounding offset +0.5 for BOTH lanes: broadcast the single double
    # (a packed vaddpd here would also add the neighboring +1.0 constant
    # to the G lane).
    vmovddup -69456(%ebp), %xmm1
    vaddpd  %xmm1, %xmm0, %xmm0
    vroundpd $9, %xmm0, %xmm0
    vcvttpd2dq %xmm0, %xmm0
    vpcmpeqd %xmm1, %xmm1, %xmm1
    vpsrld  $24, %xmm1, %xmm1
    vpminsd %xmm1, %xmm0, %xmm0
    vpxor   %xmm5, %xmm5, %xmm5
    vpmaxsd %xmm5, %xmm0, %xmm5
    vextractf128 $1, %ymm2, %xmm0
    vmovsd  -69400(%ebp), %xmm3  # xmm3 = [2.55E+2,0.0E+0]
    vmulsd  %xmm3, %xmm0, %xmm1
    vmovsd  -69408(%ebp), %xmm2  # xmm2 = [5.0E-1,0.0E+0]
    vaddsd  %xmm2, %xmm1, %xmm1
    vroundsd $9, %xmm1, %xmm1, %xmm1
    vcvttsd2si %xmm1, %ecx
    cmpl    $255, %ecx
    movl    $255, %edx
    cmovgel %edx, %ecx
    testl   %ecx, %ecx
    cmovlel %esi, %ecx
    vshufpd $1, %xmm0, %xmm0, %xmm0  # xmm0 = xmm0[1,0]
    vmulsd  %xmm3, %xmm0, %xmm0
    jmp     LBB0_40
LBB0_30:
    leal    -12(%ebp), %esp
    popl    %esi
    popl    %edi
    popl    %ebx
    popl    %ebp
    vzeroupper
    retl
.cfi_endproc
    #    SIZE(SYM(ksvgTurbulenceApplyAvx2_i386))
GNU_STACK
