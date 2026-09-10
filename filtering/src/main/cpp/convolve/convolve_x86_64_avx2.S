#include "asm_macros.S"


.text
.globl SYM(ksvgConvolveApplyInteriorAvx2)
TYPE(SYM(ksvgConvolveApplyInteriorAvx2), @function)
SYM(ksvgConvolveApplyInteriorAvx2):
    # preserveAlpha is the 10th integer argument: 48(%rsp)
    cmpl    $0, 32(%rsp)
    je      .Lbest_false
    jmp     .Lbest_true
//// SIZE(SYM(ksvgConvolveApplyInteriorAvx2))

#if defined(__APPLE__)
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 5
.Lbest_maskB:
    .byte 0,128,128,128, 4,128,128,128, 8,128,128,128, 12,128,128,128
    .byte 16,128,128,128, 20,128,128,128, 24,128,128,128, 28,128,128,128
.Lbest_maskG:
    .byte 1,128,128,128, 5,128,128,128, 9,128,128,128, 13,128,128,128
    .byte 17,128,128,128, 21,128,128,128, 25,128,128,128, 29,128,128,128
.Lbest_maskR:
    .byte 2,128,128,128, 6,128,128,128, 10,128,128,128, 14,128,128,128
    .byte 18,128,128,128, 22,128,128,128, 26,128,128,128, 30,128,128,128
.Lbest_255f:
    .long 0x437f0000
.Lbest_half:
    .long 0x3f000000
.Lbest_255i:
    .long 255

.text
.p2align 4
.Lbest_true:
    pushq   %rbp
    pushq   %r15
    pushq   %r14
    pushq   %r13
    pushq   %r12
    pushq   %rbx
    subq    $24, %rsp

    movq    %rdi, %r13              # dst base / current dst row
    movq    %rsi, %r12              # src base / current src row
    movq    %r8,  %r15              # kernel base
    movl    %r9d, %ebx              # orderX
    movl    80(%rsp), %ebp          # orderY
    movl    88(%rsp), %r10d         # targetX
    movl    96(%rsp), %r11d         # targetY
    movslq  %edx, %r14              # width -> stride bytes below

    # xHi = width - orderX + 1 + targetX
    movl    %edx, %eax
    subl    %ebx, %eax
    leal    1(%rax,%r10,1), %eax
    # fullEnd = targetX + ((xHi-targetX) & ~7)
    subl    %r10d, %eax
    andl    $-8, %eax
    addl    %r10d, %eax
    movl    %eax, %r9d              # r9d = fullEnd (returned)

    # stride bytes = width * 4
    leaq    (,%r14,4), %r14
    movq    %rbx, %rax
    shlq    $2, %rax
    movq    %r14, %r8
    subq    %rax, %r8                    # rowAdvance = stride - orderX*4

    # Save targetX*4 as a row-invariant local.
    movslq  %r10d, %rax
    shlq    $2, %rax
    movq    %rax, (%rsp)

    # Save end source row. Current source row starts at yLo-targetY=0,
    # so the number of output rows is height-orderY+1 (targetY cancels).
    movl    %ecx, %eax
    subl    %ebp, %eax
    incl    %eax
    movslq  %eax, %rax
    imulq   %r14, %rax
    addq    %r12, %rax
    movq    %rax, 8(%rsp)

    # yLo == targetY, so first source row is src + (yLo-targetY)*stride = src.
    # First destination row is dst + targetY*stride.
    movslq  %r11d, %rax
    imulq   %r14, %rax
    movq    %rax, 16(%rsp)
    addq    %rax, %r13

    # Constants.
    vbroadcastss .Lbest_half(%rip), %ymm11
    vpbroadcastd .Lbest_255i(%rip), %ymm7
    vpxor       %xmm8, %xmm8, %xmm8              # zero
    vbroadcastss %xmm0, %ymm9                    # divisor
    vmulss      .Lbest_255f(%rip), %xmm1, %xmm1
    vbroadcastss %xmm1, %ymm6                    # bias255
    vmovdqa     .Lbest_maskB(%rip), %ymm12
    vmovdqa     .Lbest_maskG(%rip), %ymm13
    vmovdqa     .Lbest_maskR(%rip), %ymm14

    # x starts at targetX; source block starts at current source row + targetX*4.
.Ltrue_y:
    movq    (%rsp), %rax
    movq    %r12, %rsi               # src block: x-targetX, so first block is row start
    leaq    (%r13,%rax), %r10       # dst block pointer
    movl    88(%rsp), %edi          # x = targetX

.Ltrue_x:
    cmpl    %r9d, %edi
    jge     .Ltrue_next_y

    # Accumulators: ymm0=B, ymm1=G, ymm2=R.
    vxorps  %xmm0, %xmm0, %xmm0
    vxorps  %xmm1, %xmm1, %xmm1
    vxorps  %xmm2, %xmm2, %xmm2
    vxorps  %xmm3, %xmm3, %xmm3          # unused alpha accumulator; keeps register map simple

    movq    %rsi, %rdx                    # tap source row
    movq    %r15, %rcx                    # tap kernel row
    xorl    %eax, %eax                    # ky = 0

.Ltrue_ky:
    xorl    %r11d, %r11d                  # kx = 0
.Ltrue_kx:
    vmovdqu  (%rdx), %ymm4               # 8 pixels
    vbroadcastss (%rcx), %ymm5

    vpand   %ymm7, %ymm4, %ymm15         # B
    vcvtdq2ps %ymm15, %ymm15
    vmulps  %ymm15, %ymm5, %ymm15
    vaddps  %ymm15, %ymm0, %ymm0

    vpshufb %ymm13, %ymm4, %ymm15         # G
    vcvtdq2ps %ymm15, %ymm15
    vmulps  %ymm15, %ymm5, %ymm15
    vaddps  %ymm15, %ymm1, %ymm1

    vpshufb %ymm14, %ymm4, %ymm15         # R
    vcvtdq2ps %ymm15, %ymm15
    vmulps  %ymm15, %ymm5, %ymm15
    vaddps  %ymm15, %ymm2, %ymm2

    addq    $4, %rdx
    addq    $4, %rcx
    incl    %r11d
    cmpl    %ebx, %r11d
    jne     .Ltrue_kx

    addq    %r8, %rdx                    # next source row
    incl    %eax
    cmpl    %ebp, %eax
    jne     .Ltrue_ky

    # Round + clamp R/G/B, exact order matching intrinsic implementation.
    vdivps  %ymm9, %ymm2, %ymm2
    vaddps  %ymm6, %ymm2, %ymm2
    vaddps  %ymm11, %ymm2, %ymm2
    vroundps $1, %ymm2, %ymm2
    vcvttps2dq %ymm2, %ymm2
    vpmaxsd %ymm8, %ymm2, %ymm2
    vpminsd %ymm7, %ymm2, %ymm2

    vdivps  %ymm9, %ymm1, %ymm1
    vaddps  %ymm6, %ymm1, %ymm1
    vaddps  %ymm11, %ymm1, %ymm1
    vroundps $1, %ymm1, %ymm1
    vcvttps2dq %ymm1, %ymm1
    vpmaxsd %ymm8, %ymm1, %ymm1
    vpminsd %ymm7, %ymm1, %ymm1

    vdivps  %ymm9, %ymm0, %ymm0
    vaddps  %ymm6, %ymm0, %ymm0
    vaddps  %ymm11, %ymm0, %ymm0
    vroundps $1, %ymm0, %ymm0
    vcvttps2dq %ymm0, %ymm0
    vpmaxsd %ymm8, %ymm0, %ymm0
    vpminsd %ymm7, %ymm0, %ymm0

    # Preserve alpha from center source pixel: srcRow + targetX*4 + current x*4.
    movslq  %edi, %rax
    shlq    $2, %rax
    addq    16(%rsp), %rax
    vmovdqu (%r12,%rax), %ymm3
    vpsrld  $24, %ymm3, %ymm3

    vpslld  $16, %ymm2, %ymm2
    vpslld  $8,  %ymm1, %ymm1
    vpor    %ymm1, %ymm0, %ymm0
    vpor    %ymm2, %ymm0, %ymm0
    vpslld  $24, %ymm3, %ymm3
    vpor    %ymm3, %ymm0, %ymm0
    vmovdqu %ymm0, (%r10)

    addq    $32, %rsi
    addq    $32, %r10
    addl    $8, %edi
    jmp     .Ltrue_x

.Ltrue_next_y:
    addq    %r14, %r12
    addq    %r14, %r13
    cmpq    8(%rsp), %r12
    jb      .Ltrue_y

    movl    %r9d, %eax                  # return tailX/fullEnd
    addq    $24, %rsp
    popq    %rbx
    popq    %r12
    popq    %r13
    popq    %r14
    popq    %r15
    popq    %rbp
    vzeroupper
    retq

.p2align 4
.Lbest_false:
    pushq   %rbp
    pushq   %r15
    pushq   %r14
    pushq   %r13
    pushq   %r12
    pushq   %rbx
    subq    $24, %rsp

    movq    %rdi, %r13
    movq    %rsi, %r12
    movq    %r8,  %r15
    movl    %r9d, %ebx
    movl    80(%rsp), %ebp
    movl    88(%rsp), %r10d
    movl    96(%rsp), %r11d
    movslq  %edx, %r14

    movl    %edx, %eax
    subl    %ebx, %eax
    leal    1(%rax,%r10,1), %eax
    subl    %r10d, %eax
    andl    $-8, %eax
    addl    %r10d, %eax
    movl    %eax, %r9d

    leaq    (,%r14,4), %r14
    movq    %rbx, %rax
    shlq    $2, %rax
    movq    %r14, %r8
    subq    %rax, %r8                    # rowAdvance = stride - orderX*4

    movslq  %r10d, %rax
    shlq    $2, %rax
    movq    %rax, (%rsp)

    movl    %ecx, %eax
    subl    %ebp, %eax
    incl    %eax
    movslq  %eax, %rax
    imulq   %r14, %rax
    addq    %r12, %rax
    movq    %rax, 8(%rsp)

    movslq  %r11d, %rax
    imulq   %r14, %rax
    movq    %rax, 16(%rsp)
    addq    %rax, %r13

    vbroadcastss .Lbest_half(%rip), %ymm11
    vpbroadcastd .Lbest_255i(%rip), %ymm7
    vpxor       %xmm8, %xmm8, %xmm8
    vbroadcastss %xmm0, %ymm9
    vmulss      .Lbest_255f(%rip), %xmm1, %xmm1
    vbroadcastss %xmm1, %ymm6
    vmovdqa     .Lbest_maskB(%rip), %ymm12
    vmovdqa     .Lbest_maskG(%rip), %ymm13
    vmovdqa     .Lbest_maskR(%rip), %ymm14

.Lfalse_y:
    movq    (%rsp), %rax
    movq    %r12, %rsi
    leaq    (%r13,%rax), %r10
    movl    88(%rsp), %edi

.Lfalse_x:
    cmpl    %r9d, %edi
    jge     .Lfalse_next_y

    vxorps  %xmm0, %xmm0, %xmm0           # B
    vxorps  %xmm1, %xmm1, %xmm1           # G
    vxorps  %xmm2, %xmm2, %xmm2           # R
    vxorps  %xmm3, %xmm3, %xmm3           # A

    movq    %rsi, %rdx
    movq    %r15, %rcx
    xorl    %eax, %eax

.Lfalse_ky:
    xorl    %r11d, %r11d
.Lfalse_kx:
    vmovdqu (%rdx), %ymm4
    vbroadcastss (%rcx), %ymm5

    vpand   %ymm7, %ymm4, %ymm15
    vcvtdq2ps %ymm15, %ymm15
    vmulps  %ymm15, %ymm5, %ymm15
    vaddps  %ymm15, %ymm0, %ymm0

    vpshufb %ymm13, %ymm4, %ymm15
    vcvtdq2ps %ymm15, %ymm15
    vmulps  %ymm15, %ymm5, %ymm15
    vaddps  %ymm15, %ymm1, %ymm1

    vpshufb %ymm14, %ymm4, %ymm15
    vcvtdq2ps %ymm15, %ymm15
    vmulps  %ymm15, %ymm5, %ymm15
    vaddps  %ymm15, %ymm2, %ymm2

    vpsrld  $24, %ymm4, %ymm15
    vcvtdq2ps %ymm15, %ymm15
    vmulps  %ymm15, %ymm5, %ymm15
    vaddps  %ymm15, %ymm3, %ymm3

    addq    $4, %rdx
    addq    $4, %rcx
    incl    %r11d
    cmpl    %ebx, %r11d
    jne     .Lfalse_kx

    addq    %r8, %rdx
    incl    %eax
    cmpl    %ebp, %eax
    jne     .Lfalse_ky

    # R
    vdivps  %ymm9, %ymm2, %ymm2
    vaddps  %ymm6, %ymm2, %ymm2
    vaddps  %ymm11, %ymm2, %ymm2
    vroundps $1, %ymm2, %ymm2
    vcvttps2dq %ymm2, %ymm2
    vpmaxsd %ymm8, %ymm2, %ymm2
    vpminsd %ymm7, %ymm2, %ymm2
    # G
    vdivps  %ymm9, %ymm1, %ymm1
    vaddps  %ymm6, %ymm1, %ymm1
    vaddps  %ymm11, %ymm1, %ymm1
    vroundps $1, %ymm1, %ymm1
    vcvttps2dq %ymm1, %ymm1
    vpmaxsd %ymm8, %ymm1, %ymm1
    vpminsd %ymm7, %ymm1, %ymm1
    # B
    vdivps  %ymm9, %ymm0, %ymm0
    vaddps  %ymm6, %ymm0, %ymm0
    vaddps  %ymm11, %ymm0, %ymm0
    vroundps $1, %ymm0, %ymm0
    vcvttps2dq %ymm0, %ymm0
    vpmaxsd %ymm8, %ymm0, %ymm0
    vpminsd %ymm7, %ymm0, %ymm0
    # A
    vdivps  %ymm9, %ymm3, %ymm3
    vaddps  %ymm6, %ymm3, %ymm3
    vaddps  %ymm11, %ymm3, %ymm3
    vroundps $1, %ymm3, %ymm3
    vcvttps2dq %ymm3, %ymm3
    vpmaxsd %ymm8, %ymm3, %ymm3
    vpminsd %ymm7, %ymm3, %ymm3

    vpslld  $24, %ymm3, %ymm3
    vpslld  $16, %ymm2, %ymm2
    vpor    %ymm3, %ymm2, %ymm2
    vpslld  $8,  %ymm1, %ymm1
    vpor    %ymm1, %ymm0, %ymm0
    vpor    %ymm0, %ymm2, %ymm0
    vmovdqu %ymm0, (%r10)

    addq    $32, %rsi
    addq    $32, %r10
    addl    $8, %edi
    jmp     .Lfalse_x

.Lfalse_next_y:
    addq    %r14, %r12
    addq    %r14, %r13
    cmpq    8(%rsp), %r12
    jb      .Lfalse_y

    movl    %r9d, %eax
    addq    $24, %rsp
    popq    %rbx
    popq    %r12
    popq    %r13
    popq    %r14
    popq    %r15
    popq    %rbp
    vzeroupper
    retq
