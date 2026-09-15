#include "asm_macros.S"

/* Spot-light + specular Intel SSSE3 kernels.
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
#ifdef __APPLE__
#define SPOT_TEXT .section __TEXT,__text,regular,pure_instructions
#define SPOT_CONST .section __TEXT,__const
#define SPOT_LIT4 .section __TEXT,__literal4,4byte_literals
#else
#define SPOT_TEXT .text
#define SPOT_CONST .section .rodata
#define SPOT_LIT4 .section .rodata
#endif

SPOT_CONST
.p2align 5
.Lspot_idx8: .long 0,1,2,3,4,5,6,7
SPOT_CONST
.p2align 4
.Lspot_idx4: .long 0,1,2,3
SPOT_LIT4
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

SPOT_CONST
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

SPOT_TEXT

.globl SYM(ksvgLightingSpotSpecularRowSsse3)
.p2align 4
SYM(ksvgLightingSpotSpecularRowSsse3):
    testl %r8d, %r8d
    jle .Lspot_ssse3_ret
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
.Lspot_ssse3_loop:
    movss 68(%rsp), %xmm0
    leaq 0(%rsp), %r9
    movq %r12, %rdi
    movq %r13, %rsi
    movq %r14, %rdx
    movq %r15, %rcx
    movl $4, %r8d
    callq .Lspot_ssse3_core
    subl $4, %ebx
    jle .Lspot_ssse3_done

    movss 48(%rsp), %xmm0
    addss %xmm0, %xmm0
    addss %xmm0, %xmm0
    movss %xmm0, %xmm1
    movss 40(%rsp), %xmm0
    addss %xmm1, %xmm0
    movss %xmm0, 40(%rsp)
    addq $16, %r12
    addq $16, %r13
    addq $16, %r14
    addq $16, %r15

    movss 68(%rsp), %xmm0
    leaq 0(%rsp), %r9
    movq %r12, %rdi
    movq %r13, %rsi
    movq %r14, %rdx
    movq %r15, %rcx
    movl $4, %r8d
    callq .Lspot_ssse3_core
    subl $4, %ebx

    movss 48(%rsp), %xmm0
    addss %xmm0, %xmm0
    addss %xmm0, %xmm0
    movss %xmm0, %xmm1
    movss 40(%rsp), %xmm0
    addss %xmm1, %xmm0
    movss %xmm0, 40(%rsp)
    addq $16, %r12
    addq $16, %r13
    addq $16, %r14
    addq $16, %r15
    jg .Lspot_ssse3_loop

.Lspot_ssse3_done:
    addq $72, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
.Lspot_ssse3_ret:
    retq

.p2align 4
.Lspot_ssse3_core:
    pushq %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $40, %rsp
    movq %r9, %rbp
    movq %rcx, %r14
    movd %xmm0, %r13d

    movdqu 0(%rdi), %xmm0
    movdqu 4(%rdi), %xmm1
    movdqu 8(%rdi), %xmm2
    movdqu 0(%rsi), %xmm3
    movdqu 4(%rsi), %xmm4
    movdqu 8(%rsi), %xmm5
    movdqu 0(%rdx), %xmm6
    movdqu 4(%rdx), %xmm7
    movdqu 8(%rdx), %xmm8
    psrld $24, %xmm0
    psrld $24, %xmm1
    psrld $24, %xmm2
    psrld $24, %xmm3
    psrld $24, %xmm4
    psrld $24, %xmm5
    psrld $24, %xmm6
    psrld $24, %xmm7
    psrld $24, %xmm8
    cvtdq2ps %xmm0, %xmm0
    cvtdq2ps %xmm1, %xmm1
    cvtdq2ps %xmm2, %xmm2
    cvtdq2ps %xmm3, %xmm3
    cvtdq2ps %xmm4, %xmm4
    cvtdq2ps %xmm5, %xmm5
    cvtdq2ps %xmm6, %xmm6
    cvtdq2ps %xmm7, %xmm7
    cvtdq2ps %xmm8, %xmm8
    movss 36(%rbp), %xmm11
    shufps $0, %xmm11, %xmm11
    mulps %xmm11, %xmm0
    mulps %xmm11, %xmm1
    mulps %xmm11, %xmm2
    mulps %xmm11, %xmm3
    mulps %xmm11, %xmm4
    mulps %xmm11, %xmm5
    mulps %xmm11, %xmm6
    mulps %xmm11, %xmm7
    mulps %xmm11, %xmm8
    movaps %xmm2, %xmm9
    addps %xmm8, %xmm9
    movaps %xmm5, %xmm11
    addps %xmm5, %xmm11
    addps %xmm11, %xmm9
    movaps %xmm0, %xmm10
    addps %xmm6, %xmm10
    movaps %xmm3, %xmm11
    addps %xmm3, %xmm11
    addps %xmm11, %xmm10
    subps %xmm10, %xmm9
    movaps %xmm6, %xmm10
    addps %xmm8, %xmm10
    movaps %xmm7, %xmm11
    addps %xmm7, %xmm11
    addps %xmm11, %xmm10
    movaps %xmm0, %xmm11
    addps %xmm2, %xmm11
    movaps %xmm1, %xmm0
    addps %xmm1, %xmm0
    addps %xmm0, %xmm11
    subps %xmm11, %xmm10
    movss 0(%rbp), %xmm0
    shufps $0, %xmm0, %xmm0
    divps %xmm0, %xmm9
    movss 4(%rbp), %xmm0
    shufps $0, %xmm0, %xmm0
    divps %xmm0, %xmm10
    pxor %xmm0, %xmm0
    subps %xmm9, %xmm0
    movaps %xmm0, %xmm9
    pxor %xmm0, %xmm0
    subps %xmm10, %xmm0
    movaps %xmm0, %xmm10
    movaps %xmm9, %xmm11
    mulps %xmm9, %xmm11
    movaps %xmm10, %xmm0
    mulps %xmm10, %xmm0
    addps %xmm0, %xmm11
    movss .Lspot_one(%rip), %xmm0
    shufps $0, %xmm0, %xmm0
    addps %xmm0, %xmm11
    sqrtps %xmm11, %xmm11
    movss .Lspot_one(%rip), %xmm0
    shufps $0, %xmm0, %xmm0
    divps %xmm11, %xmm0
    movaps %xmm0, %xmm12
    mulps %xmm0, %xmm9
    mulps %xmm0, %xmm10
    movdqu 4(%rsi), %xmm13
    psrld $24, %xmm13
    cvtdq2ps %xmm13, %xmm13
    movss 36(%rbp), %xmm0
    shufps $0, %xmm0, %xmm0
    mulps %xmm0, %xmm13
    movss 40(%rbp), %xmm11
    shufps $0, %xmm11, %xmm11
    movss 48(%rbp), %xmm0
    shufps $0, %xmm0, %xmm0
    movdqa .Lspot_idx4(%rip), %xmm8
    cvtdq2ps %xmm8, %xmm8
    mulps %xmm0, %xmm8
    addps %xmm8, %xmm11
    movss 12(%rbp), %xmm14
    shufps $0, %xmm14, %xmm14
    subps %xmm11, %xmm14
    movss 16(%rbp), %xmm15
    shufps $0, %xmm15, %xmm15
    movss 44(%rbp), %xmm0
    shufps $0, %xmm0, %xmm0
    subps %xmm0, %xmm15
    movss 20(%rbp), %xmm0
    shufps $0, %xmm0, %xmm0
    subps %xmm13, %xmm0
    movaps %xmm0, %xmm13
    movaps %xmm14, %xmm0
    mulps %xmm14, %xmm0
    movaps %xmm15, %xmm1
    mulps %xmm15, %xmm1
    addps %xmm1, %xmm0
    movaps %xmm13, %xmm1
    mulps %xmm13, %xmm1
    addps %xmm1, %xmm0
    sqrtps %xmm0, %xmm0
    pxor %xmm6, %xmm6
    cmpps $4, %xmm0, %xmm6
    movss .Lspot_one(%rip), %xmm7
    shufps $0, %xmm7, %xmm7
    divps %xmm0, %xmm7
    mulps %xmm7, %xmm14
    mulps %xmm7, %xmm15
    mulps %xmm7, %xmm13
    andps %xmm6, %xmm14
    andps %xmm6, %xmm15
    andps %xmm6, %xmm13
    pxor %xmm0, %xmm0
    movaps %xmm14, %xmm6
    subps %xmm6, %xmm0
    movss 52(%rbp), %xmm1
    shufps $0, %xmm1, %xmm1
    mulps %xmm1, %xmm0
    movaps %xmm15, %xmm1
    pxor %xmm7, %xmm7
    subps %xmm15, %xmm7
    movss 56(%rbp), %xmm2
    shufps $0, %xmm2, %xmm2
    mulps %xmm2, %xmm7
    addps %xmm7, %xmm0
    pxor %xmm7, %xmm7
    subps %xmm13, %xmm7
    movss 60(%rbp), %xmm2
    shufps $0, %xmm2, %xmm2
    mulps %xmm2, %xmm7
    addps %xmm7, %xmm0
    pxor %xmm7, %xmm7
    maxps %xmm7, %xmm0
    movss .Lspot_one(%rip), %xmm7
    shufps $0, %xmm7, %xmm7
    minps %xmm7, %xmm0
    movss 64(%rbp), %xmm7
    shufps $0, %xmm7, %xmm7
    movaps %xmm7, %xmm5
    cmpps $2, %xmm0, %xmm7
    cmpps $3, %xmm5, %xmm5
    orps %xmm5, %xmm7
    andps %xmm7, %xmm0
    movups %xmm0, 16(%rsp)
    movaps %xmm14, %xmm7
    movaps %xmm15, %xmm1
    movaps %xmm13, %xmm2
    movss .Lspot_one(%rip), %xmm0
    shufps $0, %xmm0, %xmm0
    addps %xmm0, %xmm2
    movaps %xmm7, %xmm11
    mulps %xmm7, %xmm11
    movaps %xmm1, %xmm0
    mulps %xmm1, %xmm0
    addps %xmm0, %xmm11
    movaps %xmm2, %xmm0
    mulps %xmm2, %xmm0
    addps %xmm0, %xmm11
    sqrtps %xmm11, %xmm11
    pxor %xmm8, %xmm8
    cmpps $4, %xmm11, %xmm8
    movss .Lspot_one(%rip), %xmm0
    shufps $0, %xmm0, %xmm0
    divps %xmm11, %xmm0
    mulps %xmm0, %xmm7
    mulps %xmm0, %xmm1
    mulps %xmm0, %xmm2
    andps %xmm8, %xmm7
    andps %xmm8, %xmm1
    andps %xmm8, %xmm2
    movaps %xmm7, %xmm11
    mulps %xmm9, %xmm11
    movaps %xmm1, %xmm0
    mulps %xmm10, %xmm0
    addps %xmm0, %xmm11
    movaps %xmm2, %xmm0
    mulps %xmm12, %xmm0
    addps %xmm0, %xmm11
    pxor %xmm0, %xmm0
    maxps %xmm0, %xmm11
    movups %xmm11, 0(%rsp)
    leaq .Lspot_l2s_data(%rip), %r15
    movss 0(%rsp), %xmm0
    movd %r13d, %xmm1
    CALL(powf)
    mulss 8(%rbp), %xmm0
    mulss 16(%rsp), %xmm0
    maxss .Lspot_zero(%rip), %xmm0
    minss .Lspot_one(%rip), %xmm0
    movaps %xmm0, %xmm1
    movaps %xmm0, %xmm2
    mulss 24(%rbp), %xmm0
    mulss 28(%rbp), %xmm1
    mulss 32(%rbp), %xmm2
    maxss .Lspot_zero(%rip), %xmm0
    maxss .Lspot_zero(%rip), %xmm1
    maxss .Lspot_zero(%rip), %xmm2
    minss .Lspot_255(%rip), %xmm0
    minss .Lspot_255(%rip), %xmm1
    minss .Lspot_255(%rip), %xmm2
    addss .Lspot_half(%rip), %xmm0
    addss .Lspot_half(%rip), %xmm1
    addss .Lspot_half(%rip), %xmm2
    cvttss2si %xmm0, %eax
    cvttss2si %xmm1, %ecx
    cvttss2si %xmm2, %edx
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
    movss 4(%rsp), %xmm0
    movd %r13d, %xmm1
    CALL(powf)
    mulss 8(%rbp), %xmm0
    mulss 20(%rsp), %xmm0
    maxss .Lspot_zero(%rip), %xmm0
    minss .Lspot_one(%rip), %xmm0
    movaps %xmm0, %xmm1
    movaps %xmm0, %xmm2
    mulss 24(%rbp), %xmm0
    mulss 28(%rbp), %xmm1
    mulss 32(%rbp), %xmm2
    maxss .Lspot_zero(%rip), %xmm0
    maxss .Lspot_zero(%rip), %xmm1
    maxss .Lspot_zero(%rip), %xmm2
    minss .Lspot_255(%rip), %xmm0
    minss .Lspot_255(%rip), %xmm1
    minss .Lspot_255(%rip), %xmm2
    addss .Lspot_half(%rip), %xmm0
    addss .Lspot_half(%rip), %xmm1
    addss .Lspot_half(%rip), %xmm2
    cvttss2si %xmm0, %eax
    cvttss2si %xmm1, %ecx
    cvttss2si %xmm2, %edx
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
    movss 8(%rsp), %xmm0
    movd %r13d, %xmm1
    CALL(powf)
    mulss 8(%rbp), %xmm0
    mulss 24(%rsp), %xmm0
    maxss .Lspot_zero(%rip), %xmm0
    minss .Lspot_one(%rip), %xmm0
    movaps %xmm0, %xmm1
    movaps %xmm0, %xmm2
    mulss 24(%rbp), %xmm0
    mulss 28(%rbp), %xmm1
    mulss 32(%rbp), %xmm2
    maxss .Lspot_zero(%rip), %xmm0
    maxss .Lspot_zero(%rip), %xmm1
    maxss .Lspot_zero(%rip), %xmm2
    minss .Lspot_255(%rip), %xmm0
    minss .Lspot_255(%rip), %xmm1
    minss .Lspot_255(%rip), %xmm2
    addss .Lspot_half(%rip), %xmm0
    addss .Lspot_half(%rip), %xmm1
    addss .Lspot_half(%rip), %xmm2
    cvttss2si %xmm0, %eax
    cvttss2si %xmm1, %ecx
    cvttss2si %xmm2, %edx
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
    movss 12(%rsp), %xmm0
    movd %r13d, %xmm1
    CALL(powf)
    mulss 8(%rbp), %xmm0
    mulss 28(%rsp), %xmm0
    maxss .Lspot_zero(%rip), %xmm0
    minss .Lspot_one(%rip), %xmm0
    movaps %xmm0, %xmm1
    movaps %xmm0, %xmm2
    mulss 24(%rbp), %xmm0
    mulss 28(%rbp), %xmm1
    mulss 32(%rbp), %xmm2
    maxss .Lspot_zero(%rip), %xmm0
    maxss .Lspot_zero(%rip), %xmm1
    maxss .Lspot_zero(%rip), %xmm2
    minss .Lspot_255(%rip), %xmm0
    minss .Lspot_255(%rip), %xmm1
    minss .Lspot_255(%rip), %xmm2
    addss .Lspot_half(%rip), %xmm0
    addss .Lspot_half(%rip), %xmm1
    addss .Lspot_half(%rip), %xmm2
    cvttss2si %xmm0, %eax
    cvttss2si %xmm1, %ecx
    cvttss2si %xmm2, %edx
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
    movd %r13d, %xmm0
    addq $40, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbp
    retq
.globl SYM(ksvgLightingSpotSpecularRowSsse3Linear)
.p2align 4
SYM(ksvgLightingSpotSpecularRowSsse3Linear):
    testl %r8d, %r8d
    jle .Lspot_ssse3_retLinear
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
.Lspot_ssse3_loopLinear:
    movss 68(%rsp), %xmm0
    leaq 0(%rsp), %r9
    movq %r12, %rdi
    movq %r13, %rsi
    movq %r14, %rdx
    movq %r15, %rcx
    movl $4, %r8d
    callq .Lspot_ssse3_coreLinear
    subl $4, %ebx
    jle .Lspot_ssse3_doneLinear

    movss 48(%rsp), %xmm0
    addss %xmm0, %xmm0
    addss %xmm0, %xmm0
    movss %xmm0, %xmm1
    movss 40(%rsp), %xmm0
    addss %xmm1, %xmm0
    movss %xmm0, 40(%rsp)
    addq $16, %r12
    addq $16, %r13
    addq $16, %r14
    addq $16, %r15

    movss 68(%rsp), %xmm0
    leaq 0(%rsp), %r9
    movq %r12, %rdi
    movq %r13, %rsi
    movq %r14, %rdx
    movq %r15, %rcx
    movl $4, %r8d
    callq .Lspot_ssse3_coreLinear
    subl $4, %ebx

    movss 48(%rsp), %xmm0
    addss %xmm0, %xmm0
    addss %xmm0, %xmm0
    movss %xmm0, %xmm1
    movss 40(%rsp), %xmm0
    addss %xmm1, %xmm0
    movss %xmm0, 40(%rsp)
    addq $16, %r12
    addq $16, %r13
    addq $16, %r14
    addq $16, %r15
    jg .Lspot_ssse3_loopLinear

.Lspot_ssse3_doneLinear:
    addq $72, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
.Lspot_ssse3_retLinear:
    retq

.p2align 4
.Lspot_ssse3_coreLinear:
    pushq %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $40, %rsp
    movq %r9, %rbp
    movq %rcx, %r14
    movd %xmm0, %r13d

    movdqu 0(%rdi), %xmm0
    movdqu 4(%rdi), %xmm1
    movdqu 8(%rdi), %xmm2
    movdqu 0(%rsi), %xmm3
    movdqu 4(%rsi), %xmm4
    movdqu 8(%rsi), %xmm5
    movdqu 0(%rdx), %xmm6
    movdqu 4(%rdx), %xmm7
    movdqu 8(%rdx), %xmm8
    psrld $24, %xmm0
    psrld $24, %xmm1
    psrld $24, %xmm2
    psrld $24, %xmm3
    psrld $24, %xmm4
    psrld $24, %xmm5
    psrld $24, %xmm6
    psrld $24, %xmm7
    psrld $24, %xmm8
    cvtdq2ps %xmm0, %xmm0
    cvtdq2ps %xmm1, %xmm1
    cvtdq2ps %xmm2, %xmm2
    cvtdq2ps %xmm3, %xmm3
    cvtdq2ps %xmm4, %xmm4
    cvtdq2ps %xmm5, %xmm5
    cvtdq2ps %xmm6, %xmm6
    cvtdq2ps %xmm7, %xmm7
    cvtdq2ps %xmm8, %xmm8
    movss 36(%rbp), %xmm11
    shufps $0, %xmm11, %xmm11
    mulps %xmm11, %xmm0
    mulps %xmm11, %xmm1
    mulps %xmm11, %xmm2
    mulps %xmm11, %xmm3
    mulps %xmm11, %xmm4
    mulps %xmm11, %xmm5
    mulps %xmm11, %xmm6
    mulps %xmm11, %xmm7
    mulps %xmm11, %xmm8
    movaps %xmm2, %xmm9
    addps %xmm8, %xmm9
    movaps %xmm5, %xmm11
    addps %xmm5, %xmm11
    addps %xmm11, %xmm9
    movaps %xmm0, %xmm10
    addps %xmm6, %xmm10
    movaps %xmm3, %xmm11
    addps %xmm3, %xmm11
    addps %xmm11, %xmm10
    subps %xmm10, %xmm9
    movaps %xmm6, %xmm10
    addps %xmm8, %xmm10
    movaps %xmm7, %xmm11
    addps %xmm7, %xmm11
    addps %xmm11, %xmm10
    movaps %xmm0, %xmm11
    addps %xmm2, %xmm11
    movaps %xmm1, %xmm0
    addps %xmm1, %xmm0
    addps %xmm0, %xmm11
    subps %xmm11, %xmm10
    movss 0(%rbp), %xmm0
    shufps $0, %xmm0, %xmm0
    divps %xmm0, %xmm9
    movss 4(%rbp), %xmm0
    shufps $0, %xmm0, %xmm0
    divps %xmm0, %xmm10
    pxor %xmm0, %xmm0
    subps %xmm9, %xmm0
    movaps %xmm0, %xmm9
    pxor %xmm0, %xmm0
    subps %xmm10, %xmm0
    movaps %xmm0, %xmm10
    movaps %xmm9, %xmm11
    mulps %xmm9, %xmm11
    movaps %xmm10, %xmm0
    mulps %xmm10, %xmm0
    addps %xmm0, %xmm11
    movss .Lspot_one(%rip), %xmm0
    shufps $0, %xmm0, %xmm0
    addps %xmm0, %xmm11
    sqrtps %xmm11, %xmm11
    movss .Lspot_one(%rip), %xmm0
    shufps $0, %xmm0, %xmm0
    divps %xmm11, %xmm0
    movaps %xmm0, %xmm12
    mulps %xmm0, %xmm9
    mulps %xmm0, %xmm10
    movdqu 4(%rsi), %xmm13
    psrld $24, %xmm13
    cvtdq2ps %xmm13, %xmm13
    movss 36(%rbp), %xmm0
    shufps $0, %xmm0, %xmm0
    mulps %xmm0, %xmm13
    movss 40(%rbp), %xmm11
    shufps $0, %xmm11, %xmm11
    movss 48(%rbp), %xmm0
    shufps $0, %xmm0, %xmm0
    movdqa .Lspot_idx4(%rip), %xmm8
    cvtdq2ps %xmm8, %xmm8
    mulps %xmm0, %xmm8
    addps %xmm8, %xmm11
    movss 12(%rbp), %xmm14
    shufps $0, %xmm14, %xmm14
    subps %xmm11, %xmm14
    movss 16(%rbp), %xmm15
    shufps $0, %xmm15, %xmm15
    movss 44(%rbp), %xmm0
    shufps $0, %xmm0, %xmm0
    subps %xmm0, %xmm15
    movss 20(%rbp), %xmm0
    shufps $0, %xmm0, %xmm0
    subps %xmm13, %xmm0
    movaps %xmm0, %xmm13
    movaps %xmm14, %xmm0
    mulps %xmm14, %xmm0
    movaps %xmm15, %xmm1
    mulps %xmm15, %xmm1
    addps %xmm1, %xmm0
    movaps %xmm13, %xmm1
    mulps %xmm13, %xmm1
    addps %xmm1, %xmm0
    sqrtps %xmm0, %xmm0
    pxor %xmm6, %xmm6
    cmpps $4, %xmm0, %xmm6
    movss .Lspot_one(%rip), %xmm7
    shufps $0, %xmm7, %xmm7
    divps %xmm0, %xmm7
    mulps %xmm7, %xmm14
    mulps %xmm7, %xmm15
    mulps %xmm7, %xmm13
    andps %xmm6, %xmm14
    andps %xmm6, %xmm15
    andps %xmm6, %xmm13
    pxor %xmm0, %xmm0
    movaps %xmm14, %xmm6
    subps %xmm6, %xmm0
    movss 52(%rbp), %xmm1
    shufps $0, %xmm1, %xmm1
    mulps %xmm1, %xmm0
    movaps %xmm15, %xmm1
    pxor %xmm7, %xmm7
    subps %xmm15, %xmm7
    movss 56(%rbp), %xmm2
    shufps $0, %xmm2, %xmm2
    mulps %xmm2, %xmm7
    addps %xmm7, %xmm0
    pxor %xmm7, %xmm7
    subps %xmm13, %xmm7
    movss 60(%rbp), %xmm2
    shufps $0, %xmm2, %xmm2
    mulps %xmm2, %xmm7
    addps %xmm7, %xmm0
    pxor %xmm7, %xmm7
    maxps %xmm7, %xmm0
    movss .Lspot_one(%rip), %xmm7
    shufps $0, %xmm7, %xmm7
    minps %xmm7, %xmm0
    movss 64(%rbp), %xmm7
    shufps $0, %xmm7, %xmm7
    movaps %xmm7, %xmm5
    cmpps $2, %xmm0, %xmm7
    cmpps $3, %xmm5, %xmm5
    orps %xmm5, %xmm7
    andps %xmm7, %xmm0
    movups %xmm0, 16(%rsp)
    movaps %xmm14, %xmm7
    movaps %xmm15, %xmm1
    movaps %xmm13, %xmm2
    movss .Lspot_one(%rip), %xmm0
    shufps $0, %xmm0, %xmm0
    addps %xmm0, %xmm2
    movaps %xmm7, %xmm11
    mulps %xmm7, %xmm11
    movaps %xmm1, %xmm0
    mulps %xmm1, %xmm0
    addps %xmm0, %xmm11
    movaps %xmm2, %xmm0
    mulps %xmm2, %xmm0
    addps %xmm0, %xmm11
    sqrtps %xmm11, %xmm11
    pxor %xmm8, %xmm8
    cmpps $4, %xmm11, %xmm8
    movss .Lspot_one(%rip), %xmm0
    shufps $0, %xmm0, %xmm0
    divps %xmm11, %xmm0
    mulps %xmm0, %xmm7
    mulps %xmm0, %xmm1
    mulps %xmm0, %xmm2
    andps %xmm8, %xmm7
    andps %xmm8, %xmm1
    andps %xmm8, %xmm2
    movaps %xmm7, %xmm11
    mulps %xmm9, %xmm11
    movaps %xmm1, %xmm0
    mulps %xmm10, %xmm0
    addps %xmm0, %xmm11
    movaps %xmm2, %xmm0
    mulps %xmm12, %xmm0
    addps %xmm0, %xmm11
    pxor %xmm0, %xmm0
    maxps %xmm0, %xmm11
    movups %xmm11, 0(%rsp)
    leaq .Lspot_l2s_data(%rip), %r15
    movss 0(%rsp), %xmm0
    movd %r13d, %xmm1
    CALL(powf)
    mulss 8(%rbp), %xmm0
    mulss 16(%rsp), %xmm0
    maxss .Lspot_zero(%rip), %xmm0
    minss .Lspot_one(%rip), %xmm0
    movaps %xmm0, %xmm1
    movaps %xmm0, %xmm2
    mulss 24(%rbp), %xmm0
    mulss 28(%rbp), %xmm1
    mulss 32(%rbp), %xmm2
    maxss .Lspot_zero(%rip), %xmm0
    maxss .Lspot_zero(%rip), %xmm1
    maxss .Lspot_zero(%rip), %xmm2
    minss .Lspot_255(%rip), %xmm0
    minss .Lspot_255(%rip), %xmm1
    minss .Lspot_255(%rip), %xmm2
    addss .Lspot_half(%rip), %xmm0
    addss .Lspot_half(%rip), %xmm1
    addss .Lspot_half(%rip), %xmm2
    cvttss2si %xmm0, %eax
    cvttss2si %xmm1, %ecx
    cvttss2si %xmm2, %edx
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
    movss 4(%rsp), %xmm0
    movd %r13d, %xmm1
    CALL(powf)
    mulss 8(%rbp), %xmm0
    mulss 20(%rsp), %xmm0
    maxss .Lspot_zero(%rip), %xmm0
    minss .Lspot_one(%rip), %xmm0
    movaps %xmm0, %xmm1
    movaps %xmm0, %xmm2
    mulss 24(%rbp), %xmm0
    mulss 28(%rbp), %xmm1
    mulss 32(%rbp), %xmm2
    maxss .Lspot_zero(%rip), %xmm0
    maxss .Lspot_zero(%rip), %xmm1
    maxss .Lspot_zero(%rip), %xmm2
    minss .Lspot_255(%rip), %xmm0
    minss .Lspot_255(%rip), %xmm1
    minss .Lspot_255(%rip), %xmm2
    addss .Lspot_half(%rip), %xmm0
    addss .Lspot_half(%rip), %xmm1
    addss .Lspot_half(%rip), %xmm2
    cvttss2si %xmm0, %eax
    cvttss2si %xmm1, %ecx
    cvttss2si %xmm2, %edx
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
    movss 8(%rsp), %xmm0
    movd %r13d, %xmm1
    CALL(powf)
    mulss 8(%rbp), %xmm0
    mulss 24(%rsp), %xmm0
    maxss .Lspot_zero(%rip), %xmm0
    minss .Lspot_one(%rip), %xmm0
    movaps %xmm0, %xmm1
    movaps %xmm0, %xmm2
    mulss 24(%rbp), %xmm0
    mulss 28(%rbp), %xmm1
    mulss 32(%rbp), %xmm2
    maxss .Lspot_zero(%rip), %xmm0
    maxss .Lspot_zero(%rip), %xmm1
    maxss .Lspot_zero(%rip), %xmm2
    minss .Lspot_255(%rip), %xmm0
    minss .Lspot_255(%rip), %xmm1
    minss .Lspot_255(%rip), %xmm2
    addss .Lspot_half(%rip), %xmm0
    addss .Lspot_half(%rip), %xmm1
    addss .Lspot_half(%rip), %xmm2
    cvttss2si %xmm0, %eax
    cvttss2si %xmm1, %ecx
    cvttss2si %xmm2, %edx
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
    movss 12(%rsp), %xmm0
    movd %r13d, %xmm1
    CALL(powf)
    mulss 8(%rbp), %xmm0
    mulss 28(%rsp), %xmm0
    maxss .Lspot_zero(%rip), %xmm0
    minss .Lspot_one(%rip), %xmm0
    movaps %xmm0, %xmm1
    movaps %xmm0, %xmm2
    mulss 24(%rbp), %xmm0
    mulss 28(%rbp), %xmm1
    mulss 32(%rbp), %xmm2
    maxss .Lspot_zero(%rip), %xmm0
    maxss .Lspot_zero(%rip), %xmm1
    maxss .Lspot_zero(%rip), %xmm2
    minss .Lspot_255(%rip), %xmm0
    minss .Lspot_255(%rip), %xmm1
    minss .Lspot_255(%rip), %xmm2
    addss .Lspot_half(%rip), %xmm0
    addss .Lspot_half(%rip), %xmm1
    addss .Lspot_half(%rip), %xmm2
    cvttss2si %xmm0, %eax
    cvttss2si %xmm1, %ecx
    cvttss2si %xmm2, %edx
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
    movd %r13d, %xmm0
    addq $40, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbp
    retq
