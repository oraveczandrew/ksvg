#include "asm_macros.S"

/* Spot-light + specular Intel SIMD kernels.
 *
 * SpotLightingParams (17 x float):
 *   +00 invDx  +04 invDy  +08 k
 *   +12 lightX +16 lightY +20 lightZ
 *   +24 lr +28 lg +32 lb +36 ss
 *   +40 ux0 +44 uy +48 dux
 *   +52 spotDirX +56 spotDirY +60 spotDirZ +64 spotCos
 *
 * srcT/srcM/srcB point to x-1 of the first output pixel.
 * spotDir is normalized; spotCos is cosine(cutoff).
 * Linear variants convert the packed intensity through the exact 256-entry
 * Linear->sRGB LUT (L2S_SPOT), matching ColorLuts.LINEAR_TO_SRGB.
 * C++ supplies lr/lg/lb already in linear-light space.
 */
RODATA
.p2align 5

RODATA
.p2align 5
.Lspot_idx8: .long 0x00000000,0x3f800000,0x40000000,0x40400000,0x40800000,0x40a00000,0x40c00000,0x40e00000
RODATA
.p2align 4
.Lspot_idx4: .long 0,1,2,3
POINT_LIT4
.p2align 2
.Lspot_zero: .long 0x00000000
.Lspot_one:  .long 0x3f800000
.Lspot_255:  .long 0x437f0000
.Lspot_half: .long 0x3f000000

.macro L2S_SPOT reg
    movl \reg, %r10d
    movzbl (%r15,%r10,1), %r10d
    movl %r10d, \reg
.endm

RODATA
.p2align 5
.Lspot_l2s_data:
    .byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69
    .byte 71,73,75,77,79,81,83,85,86,88,90,92,93,95,96,98
    .byte 99,101,102,104,105,106,108,109,110,112,113,114,115,117,118,119
    .byte 120,121,122,124,125,126,127,128,129,130,131,132,133,134,135,136
    .byte 137,138,139,140,141,142,143,144,145,146,147,148,148,149,150,151
    .byte 152,153,154,155,155,156,157,158,159,159,160,161,162,163,163,164
    .byte 165,166,167,167,168,169,170,170,171,172,173,173,174,175,175,176
    .byte 177,178,178,179,180,180,181,182,182,183,184,185,185,186,187,187
    .byte 188,189,189,190,190,191,192,192,193,194,194,195,196,196,197,197
    .byte 198,199,199,200,200,201,202,202,203,203,204,205,205,206,206,207
    .byte 208,208,209,209,210,210,211,212,212,213,213,214,214,215,215,216
    .byte 216,217,218,218,219,219,220,220,221,221,222,222,223,223,224,224
    .byte 225,226,226,227,227,228,228,229,229,230,230,231,231,232,232,233
    .byte 233,234,234,235,235,236,236,237,237,238,238,238,239,239,240,240
    .byte 241,241,242,242,243,243,244,244,245,245,246,246,246,247,247,248
    .byte 248,249,249,250,250,251,251,251,252,252,253,253,254,254,255,255

TEXT_SECTION

.globl SYM(ksvgLightingSpotSpecularRowAvx2)
.p2align 4
SYM(ksvgLightingSpotSpecularRowAvx2):
    testl %r8d, %r8d
    jle .Lspot_avx2_ret
    pushq %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    movq %r9, %rbp
    movq %rdi, %r12
    movq %rsi, %r13
    movq %rdx, %r14
    movq %rcx, %r15
    movl %r8d, %ebx
    subq $72, %rsp
    movss %xmm0, 68(%rsp)
    movups 0(%rbp), %xmm0
    movups %xmm0, 0(%rsp)
    movups 16(%rbp), %xmm0
    movups %xmm0, 16(%rsp)
    movups 32(%rbp), %xmm0
    movups %xmm0, 32(%rsp)
    movups 48(%rbp), %xmm0
    movups %xmm0, 48(%rsp)
    movss 64(%rbp), %xmm0
    movss %xmm0, 64(%rsp)
.Lspot_avx2_loop:
    movss 68(%rsp), %xmm0
    leaq 0(%rsp), %r9
    movq %r12, %rdi
    movq %r13, %rsi
    movq %r14, %rdx
    movq %r15, %rcx
    movl $8, %r8d
    callq .Lspot_avx2_core
    movss 48(%rsp), %xmm0
    addss %xmm0, %xmm0
    addss %xmm0, %xmm0
    addss %xmm0, %xmm0
    movss %xmm0, %xmm1
    movss 40(%rsp), %xmm0
    addss %xmm1, %xmm0
    movss %xmm0, 40(%rsp)
    addq $32, %r12
    addq $32, %r13
    addq $32, %r14
    addq $32, %r15
    subl $8, %ebx
    jg .Lspot_avx2_loop
    addq $72, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
.Lspot_avx2_ret:
    retq

.p2align 4
.Lspot_avx2_core:
    pushq %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $80, %rsp
    movq %r9, %rbp
    movq %rcx, %r14
    movd %xmm0, %r13d

    vmovdqu 0(%rdi), %ymm0
    vmovdqu 4(%rdi), %ymm1
    vmovdqu 8(%rdi), %ymm2
    vmovdqu 0(%rsi), %ymm3
    vmovdqu 4(%rsi), %ymm4
    vmovdqu 8(%rsi), %ymm5
    vmovdqu 0(%rdx), %ymm6
    vmovdqu 4(%rdx), %ymm7
    vmovdqu 8(%rdx), %ymm8
    vpsrld $24, %ymm0, %ymm0
    vpsrld $24, %ymm1, %ymm1
    vpsrld $24, %ymm2, %ymm2
    vpsrld $24, %ymm3, %ymm3
    vpsrld $24, %ymm4, %ymm4
    vpsrld $24, %ymm5, %ymm5
    vpsrld $24, %ymm6, %ymm6
    vpsrld $24, %ymm7, %ymm7
    vpsrld $24, %ymm8, %ymm8
    vcvtdq2ps %ymm0, %ymm0
    vcvtdq2ps %ymm1, %ymm1
    vcvtdq2ps %ymm2, %ymm2
    vcvtdq2ps %ymm3, %ymm3
    vcvtdq2ps %ymm4, %ymm4
    vcvtdq2ps %ymm5, %ymm5
    vcvtdq2ps %ymm6, %ymm6
    vcvtdq2ps %ymm7, %ymm7
    vcvtdq2ps %ymm8, %ymm8
    vbroadcastss 36(%rbp), %ymm11
    vmulps %ymm11, %ymm0, %ymm0
    vmulps %ymm11, %ymm1, %ymm1
    vmulps %ymm11, %ymm2, %ymm2
    vmulps %ymm11, %ymm3, %ymm3
    vmulps %ymm11, %ymm4, %ymm4
    vmulps %ymm11, %ymm5, %ymm5
    vmulps %ymm11, %ymm6, %ymm6
    vmulps %ymm11, %ymm7, %ymm7
    vmulps %ymm11, %ymm8, %ymm8
    vaddps %ymm2, %ymm8, %ymm9
    vaddps %ymm5, %ymm5, %ymm11
    vaddps %ymm11, %ymm9, %ymm9
    vaddps %ymm0, %ymm6, %ymm10
    vaddps %ymm3, %ymm3, %ymm11
    vaddps %ymm11, %ymm10, %ymm10
    vsubps %ymm10, %ymm9, %ymm9
    vaddps %ymm6, %ymm8, %ymm10
    vaddps %ymm7, %ymm7, %ymm11
    vaddps %ymm11, %ymm10, %ymm10
    vaddps %ymm0, %ymm2, %ymm11
    vaddps %ymm1, %ymm1, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vsubps %ymm11, %ymm10, %ymm10
    vbroadcastss 0(%rbp), %ymm0
    vdivps %ymm0, %ymm9, %ymm9
    vbroadcastss 4(%rbp), %ymm0
    vdivps %ymm0, %ymm10, %ymm10
    vxorps %ymm0, %ymm0, %ymm0
    vsubps %ymm9, %ymm0, %ymm9
    vsubps %ymm10, %ymm0, %ymm10
    vmulps %ymm9, %ymm9, %ymm11
    vmulps %ymm10, %ymm10, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vbroadcastss .Lspot_one(%rip), %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vsqrtps %ymm11, %ymm11
    vdivps %ymm11, %ymm0, %ymm12
    vmulps %ymm12, %ymm9, %ymm9
    vmulps %ymm12, %ymm10, %ymm10
    vmovdqu 4(%rsi), %ymm13
    vpsrld $24, %ymm13, %ymm13
    vcvtdq2ps %ymm13, %ymm13
    vbroadcastss 36(%rbp), %ymm0
    vmulps %ymm0, %ymm13, %ymm13
    vbroadcastss 40(%rbp), %ymm11
    vbroadcastss 48(%rbp), %ymm0
    vmulps .Lspot_idx8(%rip), %ymm0, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vbroadcastss 12(%rbp), %ymm14
    vsubps %ymm11, %ymm14, %ymm14
    vbroadcastss 16(%rbp), %ymm15
    vbroadcastss 44(%rbp), %ymm0
    vsubps %ymm0, %ymm15, %ymm15
    vbroadcastss 20(%rbp), %ymm1
    vsubps %ymm13, %ymm1, %ymm13
    vmulps %ymm14, %ymm14, %ymm0
    vmulps %ymm15, %ymm15, %ymm1
    vaddps %ymm1, %ymm0, %ymm0
    vmulps %ymm13, %ymm13, %ymm1
    vaddps %ymm1, %ymm0, %ymm0
    vsqrtps %ymm0, %ymm0
    vxorps %ymm6, %ymm6, %ymm6
    vcmpps $4, %ymm6, %ymm0, %ymm6
    vbroadcastss .Lspot_one(%rip), %ymm7
    vdivps %ymm0, %ymm7, %ymm7
    vmulps %ymm7, %ymm14, %ymm14
    vmulps %ymm7, %ymm15, %ymm15
    vmulps %ymm7, %ymm13, %ymm13
    vandps %ymm6, %ymm14, %ymm14
    vandps %ymm6, %ymm15, %ymm15
    vandps %ymm6, %ymm13, %ymm13
    vxorps %ymm0, %ymm0, %ymm0
    vsubps %ymm14, %ymm0, %ymm6
    vbroadcastss 52(%rbp), %ymm1
    vmulps %ymm1, %ymm6, %ymm6
    vsubps %ymm15, %ymm0, %ymm1
    vbroadcastss 56(%rbp), %ymm2
    vmulps %ymm2, %ymm1, %ymm1
    vaddps %ymm1, %ymm6, %ymm6
    vsubps %ymm13, %ymm0, %ymm1
    vbroadcastss 60(%rbp), %ymm2
    vmulps %ymm2, %ymm1, %ymm1
    vaddps %ymm1, %ymm6, %ymm6
    vmaxps %ymm0, %ymm6, %ymm6
    vbroadcastss .Lspot_one(%rip), %ymm7
    vminps %ymm7, %ymm6, %ymm6
    vbroadcastss 64(%rbp), %ymm7
    vmovaps %ymm7, %ymm1
    vcmpps $2, %ymm6, %ymm7, %ymm7
    vcmpps $3, %ymm1, %ymm1, %ymm1
    vorps %ymm1, %ymm7, %ymm7
    vandps %ymm7, %ymm6, %ymm6
    vmovaps %ymm14, %ymm7
    vmovaps %ymm15, %ymm1
    vmovaps %ymm13, %ymm2
    vbroadcastss .Lspot_one(%rip), %ymm0
    vaddps %ymm0, %ymm2, %ymm2
    vmulps %ymm7, %ymm7, %ymm11
    vmulps %ymm1, %ymm1, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vmulps %ymm2, %ymm2, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vsqrtps %ymm11, %ymm11
    vxorps %ymm0, %ymm0, %ymm0
    vcmpps $4, %ymm0, %ymm11, %ymm0
    vbroadcastss .Lspot_one(%rip), %ymm8
    vdivps %ymm11, %ymm8, %ymm8
    vmulps %ymm8, %ymm7, %ymm7
    vmulps %ymm8, %ymm1, %ymm1
    vmulps %ymm8, %ymm2, %ymm2
    vandps %ymm0, %ymm7, %ymm7
    vandps %ymm0, %ymm1, %ymm1
    vandps %ymm0, %ymm2, %ymm2
    vmulps %ymm7, %ymm9, %ymm11
    vmulps %ymm1, %ymm10, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vmulps %ymm2, %ymm12, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vxorps %ymm0, %ymm0, %ymm0
    vmaxps %ymm0, %ymm11, %ymm11
    vmovups %ymm11, 0(%rsp)
    vmovups %ymm6, 32(%rsp)
    leaq .Lspot_l2s_data(%rip), %r15
    vzeroupper
    vmovss 0(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 32(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 0(%r14)
    vmovss 4(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 36(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 4(%r14)
    vmovss 8(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 40(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 8(%r14)
    vmovss 12(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 44(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 12(%r14)
    vmovss 16(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 48(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 16(%r14)
    vmovss 20(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 52(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 20(%r14)
    vmovss 24(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 56(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 24(%r14)
    vmovss 28(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 60(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 28(%r14)
    vmovd %r13d, %xmm0
    addq $80, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbp
    retq
.globl SYM(ksvgLightingSpotSpecularRowAvx2Linear)
.p2align 4
SYM(ksvgLightingSpotSpecularRowAvx2Linear):
    testl %r8d, %r8d
    jle .Lspot_avx2_retLinear
    pushq %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    movq %r9, %rbp
    movq %rdi, %r12
    movq %rsi, %r13
    movq %rdx, %r14
    movq %rcx, %r15
    movl %r8d, %ebx
    subq $72, %rsp
    movss %xmm0, 68(%rsp)
    movups 0(%rbp), %xmm0
    movups %xmm0, 0(%rsp)
    movups 16(%rbp), %xmm0
    movups %xmm0, 16(%rsp)
    movups 32(%rbp), %xmm0
    movups %xmm0, 32(%rsp)
    movups 48(%rbp), %xmm0
    movups %xmm0, 48(%rsp)
    movss 64(%rbp), %xmm0
    movss %xmm0, 64(%rsp)
    .Lspot_avx2_loopLinear:
    movss 68(%rsp), %xmm0
    leaq 0(%rsp), %r9
    movq %r12, %rdi
    movq %r13, %rsi
    movq %r14, %rdx
    movq %r15, %rcx
    movl $8, %r8d
    callq .Lspot_avx2_coreLinear
    movss 48(%rsp), %xmm0
    addss %xmm0, %xmm0
    addss %xmm0, %xmm0
    addss %xmm0, %xmm0
    movss %xmm0, %xmm1
    movss 40(%rsp), %xmm0
    addss %xmm1, %xmm0
    movss %xmm0, 40(%rsp)
    addq $32, %r12
    addq $32, %r13
    addq $32, %r14
    addq $32, %r15
    subl $8, %ebx
    jg .Lspot_avx2_loopLinear
    addq $72, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
.Lspot_avx2_retLinear:
    retq

.p2align 4
.Lspot_avx2_coreLinear:
    pushq %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $80, %rsp
    movq %r9, %rbp
    movq %rcx, %r14
    movd %xmm0, %r13d

    vmovdqu 0(%rdi), %ymm0
    vmovdqu 4(%rdi), %ymm1
    vmovdqu 8(%rdi), %ymm2
    vmovdqu 0(%rsi), %ymm3
    vmovdqu 4(%rsi), %ymm4
    vmovdqu 8(%rsi), %ymm5
    vmovdqu 0(%rdx), %ymm6
    vmovdqu 4(%rdx), %ymm7
    vmovdqu 8(%rdx), %ymm8
    vpsrld $24, %ymm0, %ymm0
    vpsrld $24, %ymm1, %ymm1
    vpsrld $24, %ymm2, %ymm2
    vpsrld $24, %ymm3, %ymm3
    vpsrld $24, %ymm4, %ymm4
    vpsrld $24, %ymm5, %ymm5
    vpsrld $24, %ymm6, %ymm6
    vpsrld $24, %ymm7, %ymm7
    vpsrld $24, %ymm8, %ymm8
    vcvtdq2ps %ymm0, %ymm0
    vcvtdq2ps %ymm1, %ymm1
    vcvtdq2ps %ymm2, %ymm2
    vcvtdq2ps %ymm3, %ymm3
    vcvtdq2ps %ymm4, %ymm4
    vcvtdq2ps %ymm5, %ymm5
    vcvtdq2ps %ymm6, %ymm6
    vcvtdq2ps %ymm7, %ymm7
    vcvtdq2ps %ymm8, %ymm8
    vbroadcastss 36(%rbp), %ymm11
    vmulps %ymm11, %ymm0, %ymm0
    vmulps %ymm11, %ymm1, %ymm1
    vmulps %ymm11, %ymm2, %ymm2
    vmulps %ymm11, %ymm3, %ymm3
    vmulps %ymm11, %ymm4, %ymm4
    vmulps %ymm11, %ymm5, %ymm5
    vmulps %ymm11, %ymm6, %ymm6
    vmulps %ymm11, %ymm7, %ymm7
    vmulps %ymm11, %ymm8, %ymm8
    vaddps %ymm2, %ymm8, %ymm9
    vaddps %ymm5, %ymm5, %ymm11
    vaddps %ymm11, %ymm9, %ymm9
    vaddps %ymm0, %ymm6, %ymm10
    vaddps %ymm3, %ymm3, %ymm11
    vaddps %ymm11, %ymm10, %ymm10
    vsubps %ymm10, %ymm9, %ymm9
    vaddps %ymm6, %ymm8, %ymm10
    vaddps %ymm7, %ymm7, %ymm11
    vaddps %ymm11, %ymm10, %ymm10
    vaddps %ymm0, %ymm2, %ymm11
    vaddps %ymm1, %ymm1, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vsubps %ymm11, %ymm10, %ymm10
    vbroadcastss 0(%rbp), %ymm0
    vdivps %ymm0, %ymm9, %ymm9
    vbroadcastss 4(%rbp), %ymm0
    vdivps %ymm0, %ymm10, %ymm10
    vxorps %ymm0, %ymm0, %ymm0
    vsubps %ymm9, %ymm0, %ymm9
    vsubps %ymm10, %ymm0, %ymm10
    vmulps %ymm9, %ymm9, %ymm11
    vmulps %ymm10, %ymm10, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vbroadcastss .Lspot_one(%rip), %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vsqrtps %ymm11, %ymm11
    vdivps %ymm11, %ymm0, %ymm12
    vmulps %ymm12, %ymm9, %ymm9
    vmulps %ymm12, %ymm10, %ymm10
    vmovdqu 4(%rsi), %ymm13
    vpsrld $24, %ymm13, %ymm13
    vcvtdq2ps %ymm13, %ymm13
    vbroadcastss 36(%rbp), %ymm0
    vmulps %ymm0, %ymm13, %ymm13
    vbroadcastss 40(%rbp), %ymm11
    vbroadcastss 48(%rbp), %ymm0
    vmulps .Lspot_idx8(%rip), %ymm0, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vbroadcastss 12(%rbp), %ymm14
    vsubps %ymm11, %ymm14, %ymm14
    vbroadcastss 16(%rbp), %ymm15
    vbroadcastss 44(%rbp), %ymm0
    vsubps %ymm0, %ymm15, %ymm15
    vbroadcastss 20(%rbp), %ymm1
    vsubps %ymm13, %ymm1, %ymm13
    vmulps %ymm14, %ymm14, %ymm0
    vmulps %ymm15, %ymm15, %ymm1
    vaddps %ymm1, %ymm0, %ymm0
    vmulps %ymm13, %ymm13, %ymm1
    vaddps %ymm1, %ymm0, %ymm0
    vsqrtps %ymm0, %ymm0
    vxorps %ymm6, %ymm6, %ymm6
    vcmpps $4, %ymm6, %ymm0, %ymm6
    vbroadcastss .Lspot_one(%rip), %ymm7
    vdivps %ymm0, %ymm7, %ymm7
    vmulps %ymm7, %ymm14, %ymm14
    vmulps %ymm7, %ymm15, %ymm15
    vmulps %ymm7, %ymm13, %ymm13
    vandps %ymm6, %ymm14, %ymm14
    vandps %ymm6, %ymm15, %ymm15
    vandps %ymm6, %ymm13, %ymm13
    vxorps %ymm0, %ymm0, %ymm0
    vsubps %ymm14, %ymm0, %ymm6
    vbroadcastss 52(%rbp), %ymm1
    vmulps %ymm1, %ymm6, %ymm6
    vsubps %ymm15, %ymm0, %ymm1
    vbroadcastss 56(%rbp), %ymm2
    vmulps %ymm2, %ymm1, %ymm1
    vaddps %ymm1, %ymm6, %ymm6
    vsubps %ymm13, %ymm0, %ymm1
    vbroadcastss 60(%rbp), %ymm2
    vmulps %ymm2, %ymm1, %ymm1
    vaddps %ymm1, %ymm6, %ymm6
    vmaxps %ymm0, %ymm6, %ymm6
    vbroadcastss .Lspot_one(%rip), %ymm7
    vminps %ymm7, %ymm6, %ymm6
    vbroadcastss 64(%rbp), %ymm7
    vmovaps %ymm7, %ymm1
    vcmpps $2, %ymm6, %ymm7, %ymm7
    vcmpps $3, %ymm1, %ymm1, %ymm1
    vorps %ymm1, %ymm7, %ymm7
    vandps %ymm7, %ymm6, %ymm6
    vmovaps %ymm14, %ymm7
    vmovaps %ymm15, %ymm1
    vmovaps %ymm13, %ymm2
    vbroadcastss .Lspot_one(%rip), %ymm0
    vaddps %ymm0, %ymm2, %ymm2
    vmulps %ymm7, %ymm7, %ymm11
    vmulps %ymm1, %ymm1, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vmulps %ymm2, %ymm2, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vsqrtps %ymm11, %ymm11
    vxorps %ymm0, %ymm0, %ymm0
    vcmpps $4, %ymm0, %ymm11, %ymm0
    vbroadcastss .Lspot_one(%rip), %ymm8
    vdivps %ymm11, %ymm8, %ymm8
    vmulps %ymm8, %ymm7, %ymm7
    vmulps %ymm8, %ymm1, %ymm1
    vmulps %ymm8, %ymm2, %ymm2
    vandps %ymm0, %ymm7, %ymm7
    vandps %ymm0, %ymm1, %ymm1
    vandps %ymm0, %ymm2, %ymm2
    vmulps %ymm7, %ymm9, %ymm11
    vmulps %ymm1, %ymm10, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vmulps %ymm2, %ymm12, %ymm0
    vaddps %ymm0, %ymm11, %ymm11
    vxorps %ymm0, %ymm0, %ymm0
    vmaxps %ymm0, %ymm11, %ymm11
    vmovups %ymm11, 0(%rsp)
    vmovups %ymm6, 32(%rsp)
    leaq .Lspot_l2s_data(%rip), %r15
    vzeroupper
    vmovss 0(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 32(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    L2S_SPOT %eax
    L2S_SPOT %ecx
    L2S_SPOT %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 0(%r14)
    vmovss 4(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 36(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    L2S_SPOT %eax
    L2S_SPOT %ecx
    L2S_SPOT %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 4(%r14)
    vmovss 8(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 40(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    L2S_SPOT %eax
    L2S_SPOT %ecx
    L2S_SPOT %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 8(%r14)
    vmovss 12(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 44(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    L2S_SPOT %eax
    L2S_SPOT %ecx
    L2S_SPOT %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 12(%r14)
    vmovss 16(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 48(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    L2S_SPOT %eax
    L2S_SPOT %ecx
    L2S_SPOT %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 16(%r14)
    vmovss 20(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 52(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    L2S_SPOT %eax
    L2S_SPOT %ecx
    L2S_SPOT %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 20(%r14)
    vmovss 24(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 56(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    L2S_SPOT %eax
    L2S_SPOT %ecx
    L2S_SPOT %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 24(%r14)
    vmovss 28(%rsp), %xmm0
    vmovd %r13d, %xmm1
    CALL(powf)
    vmulss 8(%rbp), %xmm0, %xmm0
    vmulss 60(%rsp), %xmm0, %xmm0
    vmaxss .Lspot_zero(%rip), %xmm0, %xmm0
    vminss .Lspot_one(%rip), %xmm0, %xmm0
    vmulss 24(%rbp), %xmm0, %xmm1
    vmulss 28(%rbp), %xmm0, %xmm2
    vmulss 32(%rbp), %xmm0, %xmm3
    vmaxss .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss .Lspot_zero(%rip), %xmm3, %xmm3
    vminss .Lspot_255(%rip), %xmm1, %xmm1
    vminss .Lspot_255(%rip), %xmm2, %xmm2
    vminss .Lspot_255(%rip), %xmm3, %xmm3
    vaddss .Lspot_half(%rip), %xmm1, %xmm1
    vroundss $11, %xmm1, %xmm1, %xmm1
    vaddss .Lspot_half(%rip), %xmm2, %xmm2
    vroundss $11, %xmm2, %xmm2, %xmm2
    vaddss .Lspot_half(%rip), %xmm3, %xmm3
    vroundss $11, %xmm3, %xmm3, %xmm3
    vcvttss2si %xmm1, %eax
    vcvttss2si %xmm2, %ecx
    vcvttss2si %xmm3, %edx
    L2S_SPOT %eax
    L2S_SPOT %ecx
    L2S_SPOT %edx
    movl %eax, %edi
    cmpl %ecx, %edi
    cmovl %ecx, %edi
    cmpl %edx, %edi
    cmovl %edx, %edi
    shll $24, %edi
    shll $16, %eax
    shll $8, %ecx
    orl %ecx, %eax
    orl %edx, %eax
    orl %edi, %eax
    movl %eax, 28(%r14)
    vmovd %r13d, %xmm0
    addq $80, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbp
    retq
