#ifdef __APPLE__
#define SYM(x) _##x
#define TYPE(x,y)
#define SIZE(x)
#else
#define SYM(x) x
#define TYPE(x,y) .type x,y
#define SIZE(x) .size x,.-x
#endif

.text
.globl SYM(ksvgConvolveApplyInteriorAvx512)
TYPE(SYM(ksvgConvolveApplyInteriorAvx512), @function)
.p2align 4
SYM(ksvgConvolveApplyInteriorAvx512):
    cmpl $0, 32(%rsp)
    je .Lavx512_false

    pushq %rbp
    pushq %r15
    pushq %r14
    pushq %r13
    pushq %r12
    pushq %rbx
    subq $48, %rsp

    movq %rdi, %r13
    movq %rsi, %r12
    movq %r8,  %r15
    movl %r9d, %ebx
    movl 104(%rsp), %ebp
    movl 112(%rsp), %r10d
    movl 120(%rsp), %r11d
    movss %xmm0, 24(%rsp)
    movss %xmm1, 28(%rsp)
    movslq %edx, %r14

    movl %edx, %eax
    subl %ebx, %eax
    incl %eax
    andl $-16, %eax
    addl %r10d, %eax
    movl %eax, %r9d

    leaq (,%r14,4), %r14
    movq %rbx, %rax
    shlq $2, %rax
    movq %r14, %r8
    subq %rax, %r8

    movslq %r10d, %rax
    shlq $2, %rax
    movq %rax, 0(%rsp)

    movl %ecx, %eax
    subl %ebp, %eax
    incl %eax
    movslq %eax, %rax
    imulq %r14, %rax
    addq %r12, %rax
    movq %rax, 8(%rsp)

    movslq %r11d, %rax
    imulq %r14, %rax
    addq %rax, %r13

    vbroadcastss 24(%rsp), %zmm0      # divisor
    movss 28(%rsp), %xmm1
    mulss .Lavx512_255f(%rip), %xmm1
    vbroadcastss %xmm1, %zmm1        # bias255
    vbroadcastss .Lavx512_half(%rip), %zmm2
    vpbroadcastd .Lavx512_255i(%rip), %zmm3
    vpxor %xmm4, %xmm4, %xmm4        # zero

.Lavx512_t_y:
    movq 0(%rsp), %rax
    leaq (%r13,%rax), %rdi
    movq %r12, %rsi
    movl 112(%rsp), %r10d
.Lavx512_t_x:
    cmpl %r9d, %r10d
    jge .Lavx512_t_next_y

    vxorps %zmm5, %zmm5, %zmm5       # B
    vxorps %zmm6, %zmm6, %zmm6       # G
    vxorps %zmm7, %zmm7, %zmm7       # R

    movq %rsi, %rdx
    movq %r15, %rcx
    xorl %eax, %eax
.Lavx512_t_ky:
    leaq (%rdx,%rbx,4), %r11
.Lavx512_t_kx:
    vmovdqu32 (%rdx), %zmm8
    vbroadcastss (%rcx), %zmm9

    vpandd %zmm3, %zmm8, %zmm10
    vcvtdq2ps %zmm10, %zmm10
    vmulps %zmm9, %zmm10, %zmm10
    vaddps %zmm10, %zmm5, %zmm5

    vpsrld $8, %zmm8, %zmm10
    vpandd %zmm3, %zmm10, %zmm10
    vcvtdq2ps %zmm10, %zmm10
    vmulps %zmm9, %zmm10, %zmm10
    vaddps %zmm10, %zmm6, %zmm6

    vpsrld $16, %zmm8, %zmm10
    vpandd %zmm3, %zmm10, %zmm10
    vcvtdq2ps %zmm10, %zmm10
    vmulps %zmm9, %zmm10, %zmm10
    vaddps %zmm10, %zmm7, %zmm7

    addq $4, %rdx
    addq $4, %rcx
    cmpq %r11, %rdx
    jb .Lavx512_t_kx
    addq %r8, %rdx
    incl %eax
    cmpl %ebp, %eax
    jb .Lavx512_t_ky

    # B round/clamp -> zmm5
    vdivps %zmm0, %zmm5, %zmm5
    vaddps %zmm1, %zmm5, %zmm5
    vaddps %zmm2, %zmm5, %zmm5
    vrndscaleps $1, %zmm5, %zmm5
    vcvttps2dq %zmm5, %zmm5
    vpmaxsd %zmm4, %zmm5, %zmm5
    vpminsd %zmm3, %zmm5, %zmm5

    # G
    vdivps %zmm0, %zmm6, %zmm6
    vaddps %zmm1, %zmm6, %zmm6
    vaddps %zmm2, %zmm6, %zmm6
    vrndscaleps $1, %zmm6, %zmm6
    vcvttps2dq %zmm6, %zmm6
    vpmaxsd %zmm4, %zmm6, %zmm6
    vpminsd %zmm3, %zmm6, %zmm6

    # R
    vdivps %zmm0, %zmm7, %zmm7
    vaddps %zmm1, %zmm7, %zmm7
    vaddps %zmm2, %zmm7, %zmm7
    vrndscaleps $1, %zmm7, %zmm7
    vcvttps2dq %zmm7, %zmm7
    vpmaxsd %zmm4, %zmm7, %zmm7
    vpminsd %zmm3, %zmm7, %zmm7

    # preserve alpha from center source vector
    movslq %r10d, %rax
    shlq $2, %rax
    vmovdqu32 (%r12,%rax), %zmm10
    vpsrld $24, %zmm10, %zmm10

    vpslld $16, %zmm7, %zmm7
    vpslld $8, %zmm6, %zmm6
    vpord %zmm6, %zmm5, %zmm5
    vpord %zmm7, %zmm5, %zmm5
    vpslld $24, %zmm10, %zmm10
    vpord %zmm10, %zmm5, %zmm5
    vmovdqu32 %zmm5, (%rdi)

    addq $64, %rsi
    addq $64, %rdi
    addl $16, %r10d
    jmp .Lavx512_t_x
.Lavx512_t_next_y:
    addq %r14, %r12
    addq %r14, %r13
    cmpq 8(%rsp), %r12
    jb .Lavx512_t_y
    movl %r9d, %eax
    addq $48, %rsp
    popq %rbx
    popq %r12
    popq %r13
    popq %r14
    popq %r15
    popq %rbp
    vzeroupper
    retq

.Lavx512_false:
    pushq %rbp
    pushq %r15
    pushq %r14
    pushq %r13
    pushq %r12
    pushq %rbx
    subq $48, %rsp

    movq %rdi, %r13
    movq %rsi, %r12
    movq %r8, %r15
    movl %r9d, %ebx
    movl 104(%rsp), %ebp
    movl 112(%rsp), %r10d
    movl 120(%rsp), %r11d
    movss %xmm0, 24(%rsp)
    movss %xmm1, 28(%rsp)
    movslq %edx, %r14

    movl %edx, %eax
    subl %ebx, %eax
    incl %eax
    andl $-16, %eax
    addl %r10d, %eax
    movl %eax, %r9d

    leaq (,%r14,4), %r14
    movq %rbx, %rax
    shlq $2, %rax
    movq %r14, %r8
    subq %rax, %r8

    movslq %r10d, %rax
    shlq $2, %rax
    movq %rax, 0(%rsp)

    movl %ecx, %eax
    subl %ebp, %eax
    incl %eax
    movslq %eax, %rax
    imulq %r14, %rax
    addq %r12, %rax
    movq %rax, 8(%rsp)

    movslq %r11d, %rax
    imulq %r14, %rax
    addq %rax, %r13

    vbroadcastss 24(%rsp), %zmm0
    movss 28(%rsp), %xmm1
    mulss .Lavx512_255f(%rip), %xmm1
    vbroadcastss %xmm1, %zmm1
    vbroadcastss .Lavx512_half(%rip), %zmm2
    vpbroadcastd .Lavx512_255i(%rip), %zmm3
    vpxor %xmm4, %xmm4, %xmm4

.Lavx512_f_y:
    movq 0(%rsp), %rax
    leaq (%r13,%rax), %rdi
    movq %r12, %rsi
    movl 112(%rsp), %r10d
.Lavx512_f_x:
    cmpl %r9d, %r10d
    jge .Lavx512_f_next_y
    vxorps %zmm5, %zmm5, %zmm5
    vxorps %zmm6, %zmm6, %zmm6
    vxorps %zmm7, %zmm7, %zmm7
    vxorps %zmm10, %zmm10, %zmm10
    movq %rsi, %rdx
    movq %r15, %rcx
    xorl %eax, %eax
.Lavx512_f_ky:
    leaq (%rdx,%rbx,4), %r11
.Lavx512_f_kx:
    vmovdqu32 (%rdx), %zmm8
    vbroadcastss (%rcx), %zmm9
    vpandd %zmm3, %zmm8, %zmm11
    vcvtdq2ps %zmm11, %zmm11
    vmulps %zmm9, %zmm11, %zmm11
    vaddps %zmm11, %zmm5, %zmm5
    vpsrld $8, %zmm8, %zmm11
    vpandd %zmm3, %zmm11, %zmm11
    vcvtdq2ps %zmm11, %zmm11
    vmulps %zmm9, %zmm11, %zmm11
    vaddps %zmm11, %zmm6, %zmm6
    vpsrld $16, %zmm8, %zmm11
    vpandd %zmm3, %zmm11, %zmm11
    vcvtdq2ps %zmm11, %zmm11
    vmulps %zmm9, %zmm11, %zmm11
    vaddps %zmm11, %zmm7, %zmm7
    vpsrld $24, %zmm8, %zmm11
    vcvtdq2ps %zmm11, %zmm11
    vmulps %zmm9, %zmm11, %zmm11
    vaddps %zmm11, %zmm10, %zmm10
    addq $4, %rdx
    addq $4, %rcx
    cmpq %r11, %rdx
    jb .Lavx512_f_kx
    addq %r8, %rdx
    incl %eax
    cmpl %ebp, %eax
    jb .Lavx512_f_ky

    vdivps %zmm0, %zmm5, %zmm5
    vaddps %zmm1, %zmm5, %zmm5
    vaddps %zmm2, %zmm5, %zmm5
    vrndscaleps $1, %zmm5, %zmm5
    vcvttps2dq %zmm5, %zmm5
    vpmaxsd %zmm4, %zmm5, %zmm5
    vpminsd %zmm3, %zmm5, %zmm5
    vdivps %zmm0, %zmm6, %zmm6
    vaddps %zmm1, %zmm6, %zmm6
    vaddps %zmm2, %zmm6, %zmm6
    vrndscaleps $1, %zmm6, %zmm6
    vcvttps2dq %zmm6, %zmm6
    vpmaxsd %zmm4, %zmm6, %zmm6
    vpminsd %zmm3, %zmm6, %zmm6
    vdivps %zmm0, %zmm7, %zmm7
    vaddps %zmm1, %zmm7, %zmm7
    vaddps %zmm2, %zmm7, %zmm7
    vrndscaleps $1, %zmm7, %zmm7
    vcvttps2dq %zmm7, %zmm7
    vpmaxsd %zmm4, %zmm7, %zmm7
    vpminsd %zmm3, %zmm7, %zmm7
    vdivps %zmm0, %zmm10, %zmm10
    vaddps %zmm1, %zmm10, %zmm10
    vaddps %zmm2, %zmm10, %zmm10
    vrndscaleps $1, %zmm10, %zmm10
    vcvttps2dq %zmm10, %zmm10
    vpmaxsd %zmm4, %zmm10, %zmm10
    vpminsd %zmm3, %zmm10, %zmm10

    vpslld $24, %zmm10, %zmm10
    vpslld $16, %zmm7, %zmm7
    vpord %zmm10, %zmm7, %zmm7
    vpslld $8, %zmm6, %zmm6
    vpord %zmm6, %zmm5, %zmm5
    vpord %zmm5, %zmm7, %zmm7
    vmovdqu32 %zmm7, (%rdi)
    addq $64, %rsi
    addq $64, %rdi
    addl $16, %r10d
    jmp .Lavx512_f_x
.Lavx512_f_next_y:
    addq %r14, %r12
    addq %r14, %r13
    cmpq 8(%rsp), %r12
    jb .Lavx512_f_y
    movl %r9d, %eax
    addq $48, %rsp
    popq %rbx
    popq %r12
    popq %r13
    popq %r14
    popq %r15
    popq %rbp
    vzeroupper
    retq


//// SIZE(SYM(ksvgConvolveApplyInteriorAvx512))

#if defined(__APPLE__)
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 4
.Lavx512_255f: .long 0x437f0000
.Lavx512_half: .long 0x3f000000
.Lavx512_255i: .long 255
