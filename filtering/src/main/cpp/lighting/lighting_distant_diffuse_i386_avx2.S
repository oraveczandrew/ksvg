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
.long	0x3f800000  # float 1
.LCPI0_1:
.long	0x3f000000  # float 0.5
.LCPI0_2:
.long	255  # 0xff
.LCPI0_3:
.long	4278190080  # 0xff000000
.text
.globl SYM(ksvgLightingDistantDiffuseRowAvx2)
.p2align 4, 0x90
.type SYM(ksvgLightingDistantDiffuseRowAvx2), @function
SYM(ksvgLightingDistantDiffuseRowAvx2):
    CFI_START
    pushl        %ebp
    CFI_DEF_CFA_OFFSET(8)
    pushl        %ebx
    CFI_DEF_CFA_OFFSET(12)
    pushl        %edi
    CFI_DEF_CFA_OFFSET(16)
    pushl        %esi
    CFI_DEF_CFA_OFFSET(20)
    subl         $396, %esp
    CFI_DEF_CFA_OFFSET(416)
    CFI_OFFSET(%esi, -20)
    CFI_OFFSET(%edi, -16)
    CFI_OFFSET(%ebx, -12)
    CFI_OFFSET(%ebp, -8)
    calll        .L0$pb
.L0$pb:
    popl         %ebx
.Ltmp0:
    addl         $_GLOBAL_OFFSET_TABLE_+(.Ltmp0-.L0$pb), %ebx
    movl         432(%esp), %eax  # count
    testl        %eax, %eax
    jle          .LBB0_3
    movl         436(%esp), %ebp  # params
    movl         424(%esp), %edx  # srcB
    movl         420(%esp), %esi  # srcM
    movl         416(%esp), %edi  # srcT
    vmovss       36(%ebp), %xmm0
    vdivss       4(%ebp), %xmm0, %xmm1
    vdivss       (%ebp), %xmm0, %xmm0
    vbroadcastss %xmm0, %ymm0
    vmovups      %ymm0, 352(%esp)
    vbroadcastss %xmm1, %ymm0
    vmovups      %ymm0, 320(%esp)
    vbroadcastss 12(%ebp), %ymm0
    vmovups      %ymm0, 288(%esp)
    vbroadcastss 16(%ebp), %ymm0
    vmovups      %ymm0, 256(%esp)
    vbroadcastss 20(%ebp), %ymm0
    vmovups      %ymm0, 224(%esp)
    vbroadcastss 8(%ebp), %ymm0
    vmovups      %ymm0, 192(%esp)
    vbroadcastss 24(%ebp), %ymm0
    vmovups      %ymm0, 160(%esp)
    vbroadcastss 28(%ebp), %ymm0
    vmovups      %ymm0, 128(%esp)
    vbroadcastss 32(%ebp), %ymm0
    vmovups      %ymm0, 96(%esp)
    xorl         %ebp, %ebp  # loop counter
    movl         428(%esp), %ecx  # dst
    vbroadcastss .LCPI0_0@GOTOFF(%ebx), %ymm0
    vmovups      %ymm0, 64(%esp)
    vbroadcastss .LCPI0_1@GOTOFF(%ebx), %ymm0
    vmovups      %ymm0, 32(%esp)
    vpbroadcastd .LCPI0_2@GOTOFF(%ebx), %ymm4
    vpbroadcastd .LCPI0_3@GOTOFF(%ebx), %ymm0
    vmovdqu      %ymm0, (%esp)
.p2align 4, 0x90
.LBB0_2:
    # Main loop, 8 pixels per iteration: Sobel window, normalize, dot with
    # the distant-light direction, clamp, per-channel pack, store.
    vmovdqu      (%edi,%ebp,4), %ymm6
    vmovdqu      4(%edi,%ebp,4), %ymm0
    vpsrld       $24, %ymm6, %ymm7
    vpsrld       $24, %ymm0, %ymm0
    vmovdqu      8(%edi,%ebp,4), %ymm6
    vpsrld       $24, %ymm6, %ymm6
    vmovdqu      (%esi,%ebp,4), %ymm5
    vmovdqu      8(%esi,%ebp,4), %ymm1
    vpsrld       $24, %ymm5, %ymm5
    vpsrld       $24, %ymm1, %ymm1
    vpsubd       %ymm5, %ymm1, %ymm1
    vmovdqu      (%edx,%ebp,4), %ymm5
    vmovdqu      4(%edx,%ebp,4), %ymm2
    vpsrld       $24, %ymm5, %ymm5
    vpsrld       $24, %ymm2, %ymm2
    vpsubd       %ymm0, %ymm2, %ymm0
    vmovdqu      8(%edx,%ebp,4), %ymm2
    vpsrld       $24, %ymm2, %ymm2
    vpsubd       %ymm7, %ymm6, %ymm3
    vcvtdq2ps    %ymm3, %ymm3
    vcvtdq2ps    %ymm1, %ymm1
    vaddps       %ymm1, %ymm1, %ymm1
    vaddps       %ymm3, %ymm1, %ymm1
    vpsubd       %ymm5, %ymm2, %ymm3
    vcvtdq2ps    %ymm3, %ymm3
    vaddps       %ymm3, %ymm1, %ymm1
    vpsubd       %ymm7, %ymm5, %ymm3
    vcvtdq2ps    %ymm3, %ymm3
    vcvtdq2ps    %ymm0, %ymm0
    vaddps       %ymm0, %ymm0, %ymm0
    vaddps       %ymm3, %ymm0, %ymm0
    vmulps       352(%esp), %ymm1, %ymm1
    vpsubd       %ymm6, %ymm2, %ymm2
    vcvtdq2ps    %ymm2, %ymm2
    vaddps       %ymm2, %ymm0, %ymm0
    vmulps       320(%esp), %ymm0, %ymm0
    vpxor        %xmm5, %xmm5, %xmm5
    # Surface normal n = (-dx, -dy, 1) / |..|, dotted with the light
    # direction and clamped: intensity = min(k * max(dot, 0), 1).
    vsubps       %ymm1, %ymm5, %ymm1
    vsubps       %ymm0, %ymm5, %ymm0
    vmulps       %ymm1, %ymm1, %ymm2
    vmulps       %ymm0, %ymm0, %ymm3
    vaddps       %ymm3, %ymm2, %ymm2
    vmovups      64(%esp), %ymm3
    vaddps       %ymm3, %ymm2, %ymm2
    vsqrtps      %ymm2, %ymm2
    vdivps       %ymm2, %ymm1, %ymm1
    vmulps       288(%esp), %ymm1, %ymm1
    vdivps       %ymm2, %ymm0, %ymm0
    vmulps       256(%esp), %ymm0, %ymm0
    vaddps       %ymm0, %ymm1, %ymm0
    vdivps       %ymm2, %ymm3, %ymm1
    vmulps       224(%esp), %ymm1, %ymm1
    vaddps       %ymm1, %ymm0, %ymm0
    vmaxps       %ymm0, %ymm5, %ymm0
    vmulps       192(%esp), %ymm0, %ymm0
    vminps       %ymm0, %ymm3, %ymm6
    vmulps       128(%esp), %ymm6, %ymm0
    vmovups      32(%esp), %ymm2
    vaddps       %ymm2, %ymm0, %ymm0
    vcvttps2dq   %ymm0, %ymm0
    vpminsd      %ymm4, %ymm0, %ymm0
    vpmaxsd      %ymm5, %ymm0, %ymm0
    vmulps       96(%esp), %ymm6, %ymm1
    vaddps       %ymm2, %ymm1, %ymm1
    vcvttps2dq   %ymm1, %ymm1
    vpminsd      %ymm4, %ymm1, %ymm1
    vpmaxsd      %ymm5, %ymm1, %ymm1
    vpslld       $8, %ymm0, %ymm0
    vpor         %ymm0, %ymm1, %ymm0
    vmulps       160(%esp), %ymm6, %ymm1
    vaddps       %ymm2, %ymm1, %ymm1
    vcvttps2dq   %ymm1, %ymm1
    vpminsd      %ymm4, %ymm1, %ymm1
    vpmaxsd      %ymm5, %ymm1, %ymm1
    vpslld       $16, %ymm1, %ymm1
    vpor         (%esp), %ymm1, %ymm1
    vpor         %ymm1, %ymm0, %ymm0
    vmovdqu      %ymm0, (%ecx,%ebp,4)
    addl         $8, %ebp
    cmpl         %eax, %ebp
    jl           .LBB0_2
.LBB0_3:
    vzeroupper
    addl         $396, %esp
    popl         %esi
    popl         %edi
    popl         %ebx
    popl         %ebp
    retl
.Lfunc_end0:
    SIZE(SYM(ksvgLightingDistantDiffuseRowAvx2))
    CFI_END

    RODATA4
.p2align 2, 0x0
.LCPI1_0:
.long	0x3f800000  # float 1
.LCPI1_1:
.long	0x3f000000  # float 0.5
.text
.globl SYM(ksvgLightingDistantDiffuseRowAvx2Linear)
.p2align 4, 0x90
.type SYM(ksvgLightingDistantDiffuseRowAvx2Linear), @function
SYM(ksvgLightingDistantDiffuseRowAvx2Linear):
    CFI_START
    pushl        %ebp
    CFI_DEF_CFA_OFFSET(8)
    CFI_OFFSET(%ebp, -8)
    movl         %esp, %ebp
    CFI_DEF_CFA_REGISTER(%ebp)
    pushl        %ebx
    pushl        %edi
    pushl        %esi
    andl         $-32, %esp
    subl         $480, %esp
    CFI_OFFSET(%esi, -20)
    CFI_OFFSET(%edi, -16)
    CFI_OFFSET(%ebx, -12)
    calll        .L1$pb
.L1$pb:
    popl         %ebx
.Ltmp1:
    addl         $_GLOBAL_OFFSET_TABLE_+(.Ltmp1-.L1$pb), %ebx
    cmpl         $0, 24(%ebp)  # count
    jle          .LBB1_17
    movl         28(%ebp), %esi  # params
    vmovss       36(%esi), %xmm0
    vdivss       4(%esi), %xmm0, %xmm1
    vdivss       (%esi), %xmm0, %xmm0
    vbroadcastss %xmm0, %ymm0
    vmovaps      %ymm0, 256(%esp)
    vbroadcastss %xmm1, %ymm0
    vmovaps      %ymm0, 224(%esp)
    vmovss       8(%esi), %xmm0
    vmovss       %xmm0, 28(%esp)
    vmovss       12(%esi), %xmm0
    vmovss       %xmm0, 24(%esp)
    vmovss       16(%esi), %xmm0
    vmovss       %xmm0, 20(%esp)
    vmovss       20(%esi), %xmm5
    vmovss       24(%esi), %xmm6
    vmovss       28(%esi), %xmm7
    movl         ksvg_linear_to_srgb_lut@GOT(%ebx), %eax
    vmovss       32(%esi), %xmm0
    xorl         %esi, %esi  # loop counter
    vbroadcastss .LCPI1_0@GOTOFF(%ebx), %ymm1
    vmovaps      %ymm1, 192(%esp)
    vmovss       .LCPI1_0@GOTOFF(%ebx), %xmm1
    vmovss       .LCPI1_1@GOTOFF(%ebx), %xmm2
    jmp          .LBB1_2
.p2align 4, 0x90
.LBB1_16:
    addl         $8, %esi
    cmpl         24(%ebp), %esi
    jge          .LBB1_17
.LBB1_2:
    # Linear-kernel main loop (window/normalize/dot as above); the 8-pixel
    # child loop below finishes each pixel via scalar L2S conversion.
    movl         8(%ebp), %edx  # srcT
    vmovdqu      (%edx,%esi,4), %ymm3
    vmovdqu      4(%edx,%esi,4), %ymm4
    vpsrld       $24, %ymm3, %ymm3
    vmovdqa      %ymm3, 32(%esp)
    vpsrld       $24, %ymm4, %ymm3
    vmovdqa      %ymm3, 160(%esp)
    vmovdqu      8(%edx,%esi,4), %ymm3
    vpsrld       $24, %ymm3, %ymm3
    vmovdqa      %ymm3, 64(%esp)
    movl         12(%ebp), %edx  # srcM
    vmovdqu      (%edx,%esi,4), %ymm3
    vmovdqu      8(%edx,%esi,4), %ymm4
    vpsrld       $24, %ymm3, %ymm3
    vmovdqa      %ymm3, 128(%esp)
    vpsrld       $24, %ymm4, %ymm3
    vpsubd       128(%esp), %ymm3, %ymm3
    vmovdqa      %ymm3, 96(%esp)
    movl         16(%ebp), %edx  # srcB
    vmovdqu      (%edx,%esi,4), %ymm3
    vmovups      4(%edx,%esi,4), %ymm4
    vmovaps      %ymm4, 128(%esp)
    vpsrld       $24, %ymm3, %ymm4
    vmovdqa      128(%esp), %ymm3
    vpsrld       $24, %ymm3, %ymm3
    vpsubd       160(%esp), %ymm3, %ymm3
    vmovdqa      %ymm3, 320(%esp)
    vmovdqu      8(%edx,%esi,4), %ymm3
    vpsrld       $24, %ymm3, %ymm3
    vmovdqa      %ymm3, 160(%esp)
    vmovdqa      64(%esp), %ymm3
    vpsubd       32(%esp), %ymm3, %ymm3  # srcT index 0,2
    vcvtdq2ps    %ymm3, %ymm3
    vmovaps      %ymm3, 288(%esp)
    vcvtdq2ps    96(%esp), %ymm3
    vaddps       %ymm3, %ymm3, %ymm3
    vaddps       288(%esp), %ymm3, %ymm3
    vmovaps      %ymm3, 96(%esp)
    vmovdqa      160(%esp), %ymm3
    vpsubd       %ymm4, %ymm3, %ymm3
    vcvtdq2ps    %ymm3, %ymm3
    vaddps       96(%esp), %ymm3, %ymm3
    vmovaps      %ymm3, 96(%esp)
    vpsubd       32(%esp), %ymm4, %ymm3
    vcvtdq2ps    %ymm3, %ymm4
    vcvtdq2ps    320(%esp), %ymm3
    vaddps       %ymm3, %ymm3, %ymm3
    vaddps       %ymm4, %ymm3, %ymm3
    vmovaps      %ymm3, 32(%esp)
    vmovaps      96(%esp), %ymm3
    vmulps       256(%esp), %ymm3, %ymm4
    vmovdqa      160(%esp), %ymm3
    vpsubd       64(%esp), %ymm3, %ymm3
    vcvtdq2ps    %ymm3, %ymm3
    vaddps       32(%esp), %ymm3, %ymm3
    vmulps       224(%esp), %ymm3, %ymm3
    vmovaps      %ymm3, 32(%esp)
    vxorps       %xmm3, %xmm3, %xmm3
    vsubps       %ymm4, %ymm3, %ymm4
    vmovaps      %ymm4, 64(%esp)
    vsubps       32(%esp), %ymm3, %ymm3
    vmovaps      %ymm3, 32(%esp)
    vmulps       %ymm4, %ymm4, %ymm4
    vmovaps      32(%esp), %ymm3
    vmulps       %ymm3, %ymm3, %ymm3
    vaddps       %ymm3, %ymm4, %ymm3
    vaddps       192(%esp), %ymm3, %ymm3
    vsqrtps      %ymm3, %ymm3
    vmovaps      64(%esp), %ymm4
    vdivps       %ymm3, %ymm4, %ymm4
    vmovaps      %ymm4, 64(%esp)
    vmovaps      32(%esp), %ymm4
    vdivps       %ymm3, %ymm4, %ymm4
    vmovaps      %ymm4, 32(%esp)
    vmovaps      192(%esp), %ymm4
    vdivps       %ymm3, %ymm4, %ymm3
    vmovaps      64(%esp), %ymm4
    vmovaps      %ymm4, 416(%esp)
    vmovaps      32(%esp), %ymm4
    vmovaps      %ymm4, 384(%esp)
    vmovaps      %ymm3, 352(%esp)
    xorl         %edi, %edi  # child loop counter
.LBB1_3:
    # Per-pixel finish: dot, clamp, R/G/B scale + round + truncate with
    # branch clamps, scalar L2S gathers, force-alpha pack, store.
    vmovss       24(%esp), %xmm3
    vmulss       416(%esp,%edi,4), %xmm3, %xmm3
    vmovss       20(%esp), %xmm4
    vmulss       384(%esp,%edi,4), %xmm4, %xmm4
    vaddss       %xmm4, %xmm3, %xmm3
    vmulss       352(%esp,%edi,4), %xmm5, %xmm4
    vaddss       %xmm4, %xmm3, %xmm3
    vxorps       %xmm4, %xmm4, %xmm4
    vmaxss       %xmm3, %xmm4, %xmm3
    vmulss       28(%esp), %xmm3, %xmm3
    vminss       %xmm3, %xmm1, %xmm3
    vmulss       %xmm3, %xmm6, %xmm4
    vaddss       %xmm2, %xmm4, %xmm4
    vcvttss2si   %xmm4, %edx
    cmpl         $255, %edx
    jl           .LBB1_5
    movl         $255, %edx
.LBB1_5:
    testl        %edx, %edx
    jg           .LBB1_7
    xorl         %edx, %edx
.LBB1_7:
    vmulss       %xmm3, %xmm7, %xmm4
    vaddss       %xmm2, %xmm4, %xmm4
    vcvttss2si   %xmm4, %ecx
    cmpl         $255, %ecx
    jl           .LBB1_9
    movl         $255, %ecx
.LBB1_9:
    testl        %ecx, %ecx
    jg           .LBB1_11
    xorl         %ecx, %ecx
.LBB1_11:
    vmulss       %xmm3, %xmm0, %xmm3
    vaddss       %xmm2, %xmm3, %xmm3
    vcvttss2si   %xmm3, %ebx  # TEMP EBX! wait.
# Loop uses ebx as GOT base! I must NOT clobber it.
# I'll use another register for ebx temp.
# available: eax, edx, ecx, edi, esi.
# esi is loop counter. edi is child loop counter. eax is lut. edx is pixel part. ecx is pixel part.
# I'll use a stack slot for ebx temp.
    movl         %ebx, 348(%esp)  # SAVE GOT BASE
    movl         %eax, 344(%esp)  # SAVE LUT POINTER
    vcvttss2si   %xmm3, %eax
    cmpl         $255, %eax
    jl           .LBB1_13
    movl         $255, %eax
.LBB1_13:
    testl        %eax, %eax
    jg           .LBB1_15
    xorl         %eax, %eax
.LBB1_15:
    movl         344(%esp), %ebx  # LUT POINTER
    movzbl       (%ebx,%edx), %edx
    movzbl       (%ebx,%ecx), %ecx
    movzbl       (%ebx,%eax), %eax
    shll         $16, %edx
    orl          %eax, %edx
    shll         $8, %ecx
    orl          %edx, %ecx
    orl          $-16777216, %ecx  # diffuse alpha is always 255 (no max needed)
    movl         20(%ebp), %edx  # dst
# esi is loop counter (0, 8, 16...)
# edi is sub-loop index (0..7)
# pixel index = esi + edi
    movl         %esi, %eax
    addl         %edi, %eax
    movl         %ecx, (%edx,%eax,4)
    movl         348(%esp), %ebx  # RESTORE GOT BASE
    movl         344(%esp), %eax  # RESTORE LUT POINTER
    incl         %edi
    cmpl         $8, %edi
    je           .LBB1_16
    jmp          .LBB1_3
.LBB1_17:
    vzeroupper
    leal         -12(%ebp), %esp
    popl         %esi
    popl         %edi
    popl         %ebx
    popl         %ebp
    retl
.Lfunc_end1:
    SIZE(SYM(ksvgLightingDistantDiffuseRowAvx2Linear))
    CFI_END

    ADDRSIG
