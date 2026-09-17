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
#include "lighting_i386_ssse3_macros.S"

.text
EMIT_POW1_I386_TABLES

.text

RODATA4
.p2align 2, 0x0  # -- Begin function ksvgLightingDistantSpecularRowAvx2
.LCPI0_0:
.long	0x3f800000  # float 1
.LCPI0_1:
.long	0x3f000000  # float 0.5
.LCPI0_2:
.long	255  # 0xff
.LCPI0_4:
.byte	16  # 0x10
.byte	8  # 0x8
.byte	0  # 0x0
.byte	0  # 0x0
RODATA16
.p2align 4, 0x0
.LCPI0_3:
.long	16  # 0x10
.long	8  # 0x8
.zero	4
.zero	4
.text
.globl SYM(ksvgLightingDistantSpecularRowAvx2)
.p2align 4, 0x90
.type SYM(ksvgLightingDistantSpecularRowAvx2), @function
SYM(ksvgLightingDistantSpecularRowAvx2):
.cfi_startproc
    # %bb.0:
    pushl        %ebp
.cfi_def_cfa_offset 8
.cfi_offset %ebp, -8
    movl         %esp, %ebp
.cfi_def_cfa_register %ebp
    pushl        %ebx
    pushl        %edi
    pushl        %esi
    andl         $-32, %esp
    subl         $320, %esp  # imm = 0x140
.cfi_offset %esi, -20
.cfi_offset %edi, -16
.cfi_offset %ebx, -12
    calll        .L0$pb
.L0$pb:
    popl         %ebx
.Ltmp0:
    addl         $_GLOBAL_OFFSET_TABLE_+(.Ltmp0-.L0$pb), %ebx
    cmpl         $0, 24(%ebp)
    jle          .LBB0_8
    # %bb.1:
    vmovss       32(%ebp), %xmm0  # xmm0 = mem[0],zero,zero,zero
    movl         28(%ebp), %edi
    movl         20(%ebp), %eax
    movl         %eax, 20(%esp)  # 4-byte Spill
    vmovss       36(%edi), %xmm1  # xmm1 = mem[0],zero,zero,zero
    vdivss       4(%edi), %xmm1, %xmm2
    vdivss       (%edi), %xmm1, %xmm1
    vbroadcastss %xmm1, %ymm1
    vmovaps      %ymm1, 160(%esp)  # 32-byte Spill
    vbroadcastss %xmm2, %ymm1
    vmovaps      %ymm1, 128(%esp)  # 32-byte Spill
    vcvtss2sd    %xmm0, %xmm0, %xmm0
    vmovsd       %xmm0, 40(%esp)  # 8-byte Spill
    vbroadcastss .LCPI0_0@GOTOFF(%ebx), %ymm0  # ymm0 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    vmovaps      %ymm0, 96(%esp)  # 32-byte Spill
    vmovss       .LCPI0_0@GOTOFF(%ebx), %xmm7  # xmm7 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
    vmovss       .LCPI0_1@GOTOFF(%ebx), %xmm0  # xmm0 = [5.0E-1,0.0E+0,0.0E+0,0.0E+0]
    vmovss       %xmm0, 28(%esp)  # 4-byte Spill
    vbroadcastss .LCPI0_1@GOTOFF(%ebx), %xmm0  # xmm0 = [5.0E-1,5.0E-1,5.0E-1,5.0E-1]
    vmovaps      %xmm0, 80(%esp)  # 16-byte Spill
    xorl         %ecx, %ecx
    vbroadcastss .LCPI0_2@GOTOFF(%ebx), %xmm0  # xmm0 = [255,255,255,255]
    vmovaps      %xmm0, 64(%esp)  # 16-byte Spill
    vpmovsxbd    .LCPI0_4@GOTOFF(%ebx), %xmm0  # xmm0 = [16,8,0,0]
    vmovdqa      %xmm0, 48(%esp)  # 16-byte Spill
    vmovss       %xmm7, 32(%esp)  # 4-byte Spill
    jmp          .LBB0_2
.p2align 4, 0x90
.LBB0_7:  #   in Loop: Header=BB0_2 Depth=1
    movl         24(%esp), %ecx  # 4-byte Reload
    addl         $8, %ecx
    addl         $32, 20(%esp)  # 4-byte Folded Spill
    cmpl         24(%ebp), %ecx
    jge          .LBB0_8
.LBB0_2:  # =>This Loop Header: Depth=1
    // Main loop, 8 pixels per iteration: Sobel window, normalize, per-pixel
    // specular tails below (pow + intensity + RGB + pack).
    #     Child Loop BB0_3 Depth 2
    // Main loop, 8 pixels per iteration: Sobel window, normalize, per-pixel
    // specular tails below (pow + intensity + RGB + pack).
    movl         8(%ebp), %eax
    vmovdqu      (%eax,%ecx,4), %ymm0
    vmovdqu      4(%eax,%ecx,4), %ymm2
    vpsrld       $24, %ymm0, %ymm1
    vpsrld       $24, %ymm2, %ymm2
    vmovdqu      8(%eax,%ecx,4), %ymm0
    vpsrld       $24, %ymm0, %ymm0
    movl         12(%ebp), %eax
    vmovdqu      (%eax,%ecx,4), %ymm3
    vmovdqu      8(%eax,%ecx,4), %ymm4
    vpsrld       $24, %ymm3, %ymm3
    vpsrld       $24, %ymm4, %ymm4
    vpsubd       %ymm3, %ymm4, %ymm3
    movl         16(%ebp), %eax
    vmovdqu      (%eax,%ecx,4), %ymm4
    vmovdqu      4(%eax,%ecx,4), %ymm5
    vpsrld       $24, %ymm4, %ymm4
    vpsrld       $24, %ymm5, %ymm5
    vpsubd       %ymm2, %ymm5, %ymm2
    movl         %ecx, 24(%esp)  # 4-byte Spill
    vmovdqu      8(%eax,%ecx,4), %ymm5
    vpsrld       $24, %ymm5, %ymm5
    vpsubd       %ymm1, %ymm0, %ymm6
    vcvtdq2ps    %ymm6, %ymm6
    vcvtdq2ps    %ymm3, %ymm3
    vaddps       %ymm3, %ymm3, %ymm3
    vaddps       %ymm6, %ymm3, %ymm3
    vpsubd       %ymm4, %ymm5, %ymm6
    vcvtdq2ps    %ymm6, %ymm6
    vaddps       %ymm6, %ymm3, %ymm3
    vpsubd       %ymm1, %ymm4, %ymm1
    vcvtdq2ps    %ymm1, %ymm1
    vcvtdq2ps    %ymm2, %ymm2
    vaddps       %ymm2, %ymm2, %ymm2
    vaddps       %ymm1, %ymm2, %ymm1
    vmulps       160(%esp), %ymm3, %ymm2  # 32-byte Folded Reload
    vpsubd       %ymm0, %ymm5, %ymm0
    vcvtdq2ps    %ymm0, %ymm0
    vaddps       %ymm0, %ymm1, %ymm0
    vmulps       128(%esp), %ymm0, %ymm0  # 32-byte Folded Reload
    vxorps       %xmm3, %xmm3, %xmm3
    vsubps       %ymm2, %ymm3, %ymm1
    vsubps       %ymm0, %ymm3, %ymm0
    vmulps       %ymm1, %ymm1, %ymm2
    vmulps       %ymm0, %ymm0, %ymm3
    vaddps       %ymm3, %ymm2, %ymm2
    vmovaps      96(%esp), %ymm3  # 32-byte Reload
    vaddps       %ymm3, %ymm2, %ymm2
    vsqrtps      %ymm2, %ymm2
    vdivps       %ymm2, %ymm1, %ymm1
    vdivps       %ymm2, %ymm0, %ymm0
    vdivps       %ymm2, %ymm3, %ymm2
    vmovaps      %ymm1, 256(%esp)
    vmovaps      %ymm0, 224(%esp)
    vmovaps      %ymm2, 192(%esp)
    xorl         %esi, %esi
    jmp          .LBB0_3
.p2align 4, 0x90
.LBB0_6:  #   in Loop: Header=BB0_3 Depth=2
    vmulss       32(%edi), %xmm1, %xmm0
    vaddss       28(%esp), %xmm0, %xmm0  # 4-byte Folded Reload
    vcvttss2si   %xmm0, %eax
    cmpl         $255, %eax
    movl         $255, %ecx
    cmovgel      %ecx, %eax
    testl        %eax, %eax
    movl         $0, %ecx
    cmovlel      %ecx, %eax
    vmovsd       24(%edi), %xmm0  # xmm0 = mem[0],zero
    vbroadcastss %xmm1, %xmm1
    vmulps       %xmm0, %xmm1, %xmm0
    vaddps       80(%esp), %xmm0, %xmm0  # 16-byte Folded Reload
    vcvttps2dq   %xmm0, %xmm0
    vpminsd      64(%esp), %xmm0, %xmm0  # 16-byte Folded Reload
    vxorps       %xmm1, %xmm1, %xmm1
    vpmaxsd      %xmm1, %xmm0, %xmm0
    vmovd        %xmm0, %edx
    vpextrd      $1, %xmm0, %ecx
    cmpl         %ecx, %edx
    cmoval       %edx, %ecx
    cmpl         %eax, %ecx
    cmovbel      %eax, %ecx
    vpsllvd      48(%esp), %xmm0, %xmm0  # 16-byte Folded Reload
    vpshufd      $85, %xmm0, %xmm1  # xmm1 = xmm0[1,1,1,1]
    vpor         %xmm0, %xmm1, %xmm0
    vmovd        %xmm0, %edx
    orl          %eax, %edx
    shll         $24, %ecx
    orl          %ecx, %edx
    movl         20(%esp), %eax  # 4-byte Reload
    movl         %edx, (%eax,%esi,4)
    incl         %esi
    cmpl         $8, %esi
    je           .LBB0_7
.LBB0_3:  #   Parent Loop BB0_2 Depth=1
    # =>  This Inner Loop Header: Depth=2
    vaddss       20(%edi), %xmm7, %xmm0
    vmovss       12(%edi), %xmm1  # xmm1 = mem[0],zero,zero,zero
    vmovss       16(%edi), %xmm2  # xmm2 = mem[0],zero,zero,zero
    vmulss       %xmm1, %xmm1, %xmm3
    vmulss       %xmm2, %xmm2, %xmm4
    vaddss       %xmm4, %xmm3, %xmm3
    vmulss       %xmm0, %xmm0, %xmm4
    vaddss       %xmm3, %xmm4, %xmm3
    vsqrtss      %xmm3, %xmm3, %xmm3
    vdivss       %xmm3, %xmm7, %xmm3
    vmulss       %xmm3, %xmm1, %xmm1
    vmulss       %xmm3, %xmm2, %xmm2
    vmulss       256(%esp,%esi,4), %xmm1, %xmm1
    vmulss       224(%esp,%esi,4), %xmm2, %xmm2
    vmulss       %xmm3, %xmm0, %xmm0
    vaddss       %xmm2, %xmm1, %xmm1
    vmulss       192(%esp,%esi,4), %xmm0, %xmm0
    vaddss       %xmm1, %xmm0, %xmm0
    vxorps       %xmm1, %xmm1, %xmm1
    vmaxss       %xmm0, %xmm1, %xmm0
    # p = pow(ndoth, exponent): inline scalar minimax, no PLT call.
    vmovaps      %xmm0, %xmm1  # pow base
    vmovss       32(%ebp), %xmm2  # exponent
    vzeroupper
    POW1_SSE
    vxorps       %xmm1, %xmm1, %xmm1
    vmovss       32(%esp), %xmm7  # 4-byte Reload
    # xmm7 = mem[0],zero,zero,zero
    movss        %xmm0, 36(%esp)
    vmovss       8(%edi), %xmm0  # xmm0 = mem[0],zero,zero,zero
    vmulss       36(%esp), %xmm0, %xmm0
    vucomiss     %xmm0, %xmm1
    ja           .LBB0_6
    # %bb.4:                                #   in Loop: Header=BB0_3 Depth=2
    vucomiss     %xmm7, %xmm0
    vmovaps      %xmm0, %xmm1
    jbe          .LBB0_6
    # %bb.5:                                #   in Loop: Header=BB0_3 Depth=2
    vmovaps      %xmm7, %xmm1
    jmp          .LBB0_6
.LBB0_8:
    vzeroupper
    leal         -12(%ebp), %esp
    popl         %esi
    popl         %edi
    popl         %ebx
    popl         %ebp
.cfi_def_cfa %esp, 4
    retl
.Lfunc_end0:
.size SYM(ksvgLightingDistantSpecularRowAvx2), .Lfunc_end0-ksvgLightingDistantSpecularRowAvx2
.cfi_endproc
    # -- End function
RODATA4
.p2align 2, 0x0  # -- Begin function ksvgLightingDistantSpecularRowAvx2Linear
.LCPI1_0:
.long	0x3f800000  # float 1
.LCPI1_1:
.long	0x3f000000  # float 0.5
.text
.globl SYM(ksvgLightingDistantSpecularRowAvx2Linear)
.p2align 4, 0x90
.type SYM(ksvgLightingDistantSpecularRowAvx2Linear), @function
SYM(ksvgLightingDistantSpecularRowAvx2Linear):
.cfi_startproc
    # %bb.0:
    pushl        %ebp
.cfi_def_cfa_offset 8
.cfi_offset %ebp, -8
    movl         %esp, %ebp
.cfi_def_cfa_register %ebp
    pushl        %ebx
    pushl        %edi
    pushl        %esi
    andl         $-32, %esp
    subl         $288, %esp  # imm = 0x120
.cfi_offset %esi, -20
.cfi_offset %edi, -16
.cfi_offset %ebx, -12
    calll        .L1$pb
.L1$pb:
    popl         %eax
.Ltmp1:
    addl         $_GLOBAL_OFFSET_TABLE_+(.Ltmp1-.L1$pb), %eax
    movl         %eax, 28(%esp)  # 4-byte Spill
    cmpl         $0, 24(%ebp)
    jle          .LBB1_8
    # %bb.1:
    vmovss       32(%ebp), %xmm0  # xmm0 = mem[0],zero,zero,zero
    movl         28(%ebp), %edi
    movl         20(%ebp), %eax
    movl         %eax, 32(%esp)  # 4-byte Spill
    vmovss       36(%edi), %xmm1  # xmm1 = mem[0],zero,zero,zero
    vdivss       4(%edi), %xmm1, %xmm2
    vdivss       (%edi), %xmm1, %xmm1
    vbroadcastss %xmm1, %ymm1
    vmovaps      %ymm1, 128(%esp)  # 32-byte Spill
    vbroadcastss %xmm2, %ymm1
    vmovaps      %ymm1, 96(%esp)  # 32-byte Spill
    vcvtss2sd    %xmm0, %xmm0, %xmm0
    vmovsd       %xmm0, 56(%esp)  # 8-byte Spill
    movl         28(%esp), %eax  # 4-byte Reload
    vbroadcastss .LCPI1_0@GOTOFF(%eax), %ymm0  # ymm0 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    vmovaps      %ymm0, 64(%esp)  # 32-byte Spill
    vmovss       .LCPI1_0@GOTOFF(%eax), %xmm7  # xmm7 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
    vmovss       .LCPI1_1@GOTOFF(%eax), %xmm0  # xmm0 = [5.0E-1,0.0E+0,0.0E+0,0.0E+0]
    vmovss       %xmm0, 44(%esp)  # 4-byte Spill
    movl         ksvg_linear_to_srgb_lut@GOT(%eax), %eax
    movl         %eax, 40(%esp)  # 4-byte Spill
    xorl         %ecx, %ecx
    vmovss       %xmm7, 48(%esp)  # 4-byte Spill
    jmp          .LBB1_2
.p2align 4, 0x90
.LBB1_7:  #   in Loop: Header=BB1_2 Depth=1
    movl         36(%esp), %ecx  # 4-byte Reload
    addl         $8, %ecx
    addl         $32, 32(%esp)  # 4-byte Folded Spill
    cmpl         24(%ebp), %ecx
    jge          .LBB1_8
.LBB1_2:  # =>This Loop Header: Depth=1
    // Linear-kernel main loop (window/normalize/dot as above); per-pixel
    // finishes below, with scalar L2S conversion on the linear path.
    #     Child Loop BB1_3 Depth 2
    // Linear-kernel main loop (window/normalize/dot as above); per-pixel
    // finishes below, with scalar L2S conversion on the linear path.
    movl         8(%ebp), %eax
    vmovdqu      (%eax,%ecx,4), %ymm0
    vmovdqu      4(%eax,%ecx,4), %ymm2
    vpsrld       $24, %ymm0, %ymm1
    vpsrld       $24, %ymm2, %ymm2
    vmovdqu      8(%eax,%ecx,4), %ymm0
    vpsrld       $24, %ymm0, %ymm0
    movl         12(%ebp), %eax
    vmovdqu      (%eax,%ecx,4), %ymm3
    vmovdqu      8(%eax,%ecx,4), %ymm4
    vpsrld       $24, %ymm3, %ymm3
    vpsrld       $24, %ymm4, %ymm4
    vpsubd       %ymm3, %ymm4, %ymm3
    movl         16(%ebp), %eax
    vmovdqu      (%eax,%ecx,4), %ymm4
    vmovdqu      4(%eax,%ecx,4), %ymm5
    vpsrld       $24, %ymm4, %ymm4
    vpsrld       $24, %ymm5, %ymm5
    vpsubd       %ymm2, %ymm5, %ymm2
    movl         %ecx, 36(%esp)  # 4-byte Spill
    vmovdqu      8(%eax,%ecx,4), %ymm5
    vpsrld       $24, %ymm5, %ymm5
    vpsubd       %ymm1, %ymm0, %ymm6
    vcvtdq2ps    %ymm6, %ymm6
    vcvtdq2ps    %ymm3, %ymm3
    vaddps       %ymm3, %ymm3, %ymm3
    vaddps       %ymm6, %ymm3, %ymm3
    vpsubd       %ymm4, %ymm5, %ymm6
    vcvtdq2ps    %ymm6, %ymm6
    vaddps       %ymm6, %ymm3, %ymm3
    vpsubd       %ymm1, %ymm4, %ymm1
    vcvtdq2ps    %ymm1, %ymm1
    vcvtdq2ps    %ymm2, %ymm2
    vaddps       %ymm2, %ymm2, %ymm2
    vaddps       %ymm1, %ymm2, %ymm1
    vmulps       128(%esp), %ymm3, %ymm2  # 32-byte Folded Reload
    vpsubd       %ymm0, %ymm5, %ymm0
    vcvtdq2ps    %ymm0, %ymm0
    vaddps       %ymm0, %ymm1, %ymm0
    vmulps       96(%esp), %ymm0, %ymm0  # 32-byte Folded Reload
    vxorps       %xmm3, %xmm3, %xmm3
    vsubps       %ymm2, %ymm3, %ymm1
    vsubps       %ymm0, %ymm3, %ymm0
    vmulps       %ymm1, %ymm1, %ymm2
    vmulps       %ymm0, %ymm0, %ymm3
    vaddps       %ymm3, %ymm2, %ymm2
    vmovaps      64(%esp), %ymm3  # 32-byte Reload
    vaddps       %ymm3, %ymm2, %ymm2
    vsqrtps      %ymm2, %ymm2
    vdivps       %ymm2, %ymm1, %ymm1
    vdivps       %ymm2, %ymm0, %ymm0
    vdivps       %ymm2, %ymm3, %ymm2
    vmovaps      %ymm1, 224(%esp)
    vmovaps      %ymm0, 192(%esp)
    vmovaps      %ymm2, 160(%esp)
    xorl         %esi, %esi
    jmp          .LBB1_3
.p2align 4, 0x90
.LBB1_6:  #   in Loop: Header=BB1_3 Depth=2
    vmulss       24(%edi), %xmm2, %xmm0
    vmovss       44(%esp), %xmm1  # 4-byte Reload
    # xmm1 = mem[0],zero,zero,zero
    vaddss       %xmm1, %xmm0, %xmm0
    vcvttss2si   %xmm0, %eax
    cmpl         $255, %eax
    movl         $255, %ebx
    cmovgel      %ebx, %eax
    testl        %eax, %eax
    movl         $0, %edx
    cmovlel      %edx, %eax
    vmulss       28(%edi), %xmm2, %xmm0
    vaddss       %xmm1, %xmm0, %xmm0
    vcvttss2si   %xmm0, %ecx
    cmpl         $255, %ecx
    cmovgel      %ebx, %ecx
    testl        %ecx, %ecx
    cmovlel      %edx, %ecx
    vmulss       32(%edi), %xmm2, %xmm0
    vaddss       %xmm1, %xmm0, %xmm0
    vcvttss2si   %xmm0, %edi
    cmpl         $255, %edi
    cmovgel      %ebx, %edi
    testl        %edi, %edi
    cmovlel      %edx, %edi
    movl         40(%esp), %ebx  # 4-byte Reload
    movzbl       (%ebx,%eax), %edx
    movzbl       (%ebx,%ecx), %eax
    movzbl       (%ebx,%edi), %ecx
    cmpl         %eax, %edx
    movl         %eax, %edi
    cmoval       %edx, %edi
    cmpl         %ecx, %edi
    cmovbel      %ecx, %edi
    shll         $16, %edx
    shll         $8, %eax
    orl          %edx, %eax
    shll         $24, %edi
    orl          %edi, %eax
    movl         28(%ebp), %edi
    orl          %ecx, %eax
    movl         32(%esp), %ecx  # 4-byte Reload
    movl         %eax, (%ecx,%esi,4)
    incl         %esi
    cmpl         $8, %esi
    je           .LBB1_7
.LBB1_3:  #   Parent Loop BB1_2 Depth=1
    # =>  This Inner Loop Header: Depth=2
    vaddss       20(%edi), %xmm7, %xmm0
    vmovss       12(%edi), %xmm1  # xmm1 = mem[0],zero,zero,zero
    vmovss       16(%edi), %xmm2  # xmm2 = mem[0],zero,zero,zero
    vmulss       %xmm1, %xmm1, %xmm3
    vmulss       %xmm2, %xmm2, %xmm4
    vaddss       %xmm4, %xmm3, %xmm3
    vmulss       %xmm0, %xmm0, %xmm4
    vaddss       %xmm3, %xmm4, %xmm3
    vsqrtss      %xmm3, %xmm3, %xmm3
    vdivss       %xmm3, %xmm7, %xmm3
    vmulss       %xmm3, %xmm1, %xmm1
    vmulss       %xmm3, %xmm2, %xmm2
    vmulss       224(%esp,%esi,4), %xmm1, %xmm1
    vmulss       192(%esp,%esi,4), %xmm2, %xmm2
    vmulss       %xmm3, %xmm0, %xmm0
    vaddss       %xmm2, %xmm1, %xmm1
    vmulss       160(%esp,%esi,4), %xmm0, %xmm0
    vaddss       %xmm1, %xmm0, %xmm0
    vxorps       %xmm1, %xmm1, %xmm1
    vmaxss       %xmm0, %xmm1, %xmm0
    # p = pow(ndoth, exponent): inline scalar minimax, no PLT call.
    vmovaps      %xmm0, %xmm1  # pow base
    vmovss       32(%ebp), %xmm2  # exponent
    movl         28(%esp), %ebx  # 4-byte Reload (GOT base for GOTOFF)
    vzeroupper
    POW1_SSE
    vxorps       %xmm2, %xmm2, %xmm2
    vmovss       48(%esp), %xmm7  # 4-byte Reload
    # xmm7 = mem[0],zero,zero,zero
    movss        %xmm0, 52(%esp)
    vmovss       8(%edi), %xmm0  # xmm0 = mem[0],zero,zero,zero
    vmulss       52(%esp), %xmm0, %xmm0
    vucomiss     %xmm0, %xmm2
    ja           .LBB1_6
    # %bb.4:                                #   in Loop: Header=BB1_3 Depth=2
    vucomiss     %xmm7, %xmm0
    vmovaps      %xmm0, %xmm2
    jbe          .LBB1_6
    # %bb.5:                                #   in Loop: Header=BB1_3 Depth=2
    vmovaps      %xmm7, %xmm2
    jmp          .LBB1_6
.LBB1_8:
    vzeroupper
    leal         -12(%ebp), %esp
    popl         %esi
    popl         %edi
    popl         %ebx
    popl         %ebp
.cfi_def_cfa %esp, 4
    retl
.Lfunc_end1:
.size SYM(ksvgLightingDistantSpecularRowAvx2Linear), .Lfunc_end1-ksvgLightingDistantSpecularRowAvx2Linear
.cfi_endproc
    # -- End function

ADDRSIG
