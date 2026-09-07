#ifdef __APPLE__
#define SYM(x) _##x
#define TYPE(x,y)
#define SIZE(x)
#else
#define SYM(x) x
#define TYPE(x,y) .type x,y
#define SIZE(x) .size x,.-x
#endif
#ifdef __APPLE__
#define CFI_START
#define CFI_DEF_CFA_OFFSET(x)
#define CFI_OFFSET(reg, offset)
#define CFI_END
#else
#define CFI_START .cfi_startproc
#define CFI_DEF_CFA_OFFSET(x) .cfi_def_cfa_offset x
#define CFI_OFFSET(reg, offset) .cfi_offset reg, offset
#define CFI_END .cfi_endproc
#endif
	.text
	.file	"dm_sse2.cpp"
#if defined(__APPLE__)
	.section __TEXT,__const
#else
	.section	.rodata.cst16,"aM",@progbits,16
#endif
	.p2align	4, 0x0                          # -- Begin function ksvgDisplacementMapApplySse2
.LCPI0_0:
	.long	0                               # 0x0
	.long	1                               # 0x1
	.long	2                               # 0x2
	.long	3                               # 0x3
.LCPI0_1:
	.long	0x437f0000                      # float 255
	.long	0x437f0000                      # float 255
	.long	0x437f0000                      # float 255
	.long	0x437f0000                      # float 255
.LCPI0_2:
	.long	0xbf000000                      # float -0.5
	.long	0xbf000000                      # float -0.5
	.long	0xbf000000                      # float -0.5
	.long	0xbf000000                      # float -0.5
.LCPI0_3:
	.long	4                               # 0x4
	.long	4                               # 0x4
	.long	4                               # 0x4
	.long	4                               # 0x4
.LCPI0_6:
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
.LCPI0_7:
	.long	0x437f0000                      # float 255
	.long	0x437f0000                      # float 255
	.zero	4
	.zero	4
.LCPI0_8:
	.long	0xbf000000                      # float -0.5
	.long	0xbf000000                      # float -0.5
	.zero	4
	.zero	4
.LCPI0_9:
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
#if defined(__APPLE__)
	.section __TEXT,__const
#else
	.section	.rodata.cst4,"aM",@progbits,4
#endif
	.p2align	2, 0x0
.LCPI0_4:
	.long	0x437f0000                      # float 255
.LCPI0_5:
	.long	0xbf000000                      # float -0.5
	.text
	.globl	SYM(ksvgDisplacementMapApplySse2)
	.p2align	4, 0x90
	TYPE(SYM(ksvgDisplacementMapApplySse2), @function)
SYM(ksvgDisplacementMapApplySse2):       # @ksvgDisplacementMapApplySse2
	CFI_START
# %bb.0:
	pushq	%rbp
	CFI_DEF_CFA_OFFSET(16)
	pushq	%r15
	CFI_DEF_CFA_OFFSET(24)
	pushq	%r14
	CFI_DEF_CFA_OFFSET(32)
	pushq	%r13
	CFI_DEF_CFA_OFFSET(40)
	pushq	%r12
	CFI_DEF_CFA_OFFSET(48)
	pushq	%rbx
	CFI_DEF_CFA_OFFSET(56)
	subq	$56, %rsp
	CFI_DEF_CFA_OFFSET(112)
	CFI_OFFSET(%rbx, -56)
	CFI_OFFSET(%r12, -48)
	CFI_OFFSET(%r13, -40)
	CFI_OFFSET(%r14, -32)
	CFI_OFFSET(%r15, -24)
	CFI_OFFSET(%rbp, -16)
                                        # kill: def $r8d killed $r8d def $r8
                                        # kill: def $ecx killed $ecx def $rcx
	movq	%rdx, -120(%rsp)                # 8-byte Spill
	movq	%rsi, -128(%rsp)                # 8-byte Spill
	movl	112(%rsp), %eax
	cmpq	$3, %rax
	ja	.LBB0_746
# %bb.1:
	movaps	%xmm0, %xmm12
	leaq	.LJTI0_0(%rip), %rdx
	movslq	(%rdx,%rax,4), %rax
	addq	%rdx, %rax
	movaps	%xmm0, -32(%rsp)                # 16-byte Spill
	jmpq	*%rax
.LBB0_2:
	cmpl	$3, %r9d
	ja	.LBB0_746
# %bb.3:
	movl	%r9d, %eax
	leaq	.LJTI0_4(%rip), %rdx
	movslq	(%rdx,%rax,4), %rax
	addq	%rdx, %rax
	jmpq	*%rax
.LBB0_4:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.5:
	leal	-1(%rcx), %esi
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_6
# %bb.20:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.21:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movss	.LCPI0_4(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	movss	.LCPI0_5(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_22
.LBB0_374:
	cmpl	$3, %r9d
	ja	.LBB0_746
# %bb.375:
	movl	%r9d, %eax
	leaq	.LJTI0_2(%rip), %rdx
	movslq	(%rdx,%rax,4), %rax
	addq	%rdx, %rax
	jmpq	*%rax
.LBB0_376:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.377:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	leal	-1(%rcx), %r14d
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_378
# %bb.392:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.393:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movq	.LCPI0_9(%rip), %xmm1           # xmm1 = [255,0,0,0,255,0,0,0,0,0,0,0,0,0,0,0]
	movaps	.LCPI0_7(%rip), %xmm2           # xmm2 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm3           # xmm3 = [-5.0E-1,-5.0E-1,u,u]
	movl	$1, %eax
	movd	%eax, %xmm4
	movl	$2, %eax
	movd	%eax, %xmm5
	movq	-120(%rsp), %rsi                # 8-byte Reload
	jmp	.LBB0_394
.LBB0_560:
	cmpl	$3, %r9d
	ja	.LBB0_746
# %bb.561:
	movl	%r9d, %eax
	leaq	.LJTI0_1(%rip), %rdx
	movslq	(%rdx,%rax,4), %rax
	addq	%rdx, %rax
	jmpq	*%rax
.LBB0_562:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.563:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	leal	-1(%rcx), %r14d
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_564
# %bb.578:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.579:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movaps	.LCPI0_7(%rip), %xmm1           # xmm1 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm2           # xmm2 = [-5.0E-1,-5.0E-1,u,u]
	movl	$1, %eax
	movd	%eax, %xmm3
	movl	$2, %eax
	movd	%eax, %xmm4
	movq	-120(%rsp), %rsi                # 8-byte Reload
	jmp	.LBB0_580
.LBB0_188:
	cmpl	$3, %r9d
	ja	.LBB0_746
# %bb.189:
	movl	%r9d, %eax
	leaq	.LJTI0_3(%rip), %rdx
	movslq	(%rdx,%rax,4), %rax
	addq	%rdx, %rax
	jmpq	*%rax
.LBB0_190:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.191:
	leal	-1(%rcx), %edx
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_192
# %bb.206:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.207:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %eax
	xorl	%r15d, %r15d
	movss	.LCPI0_4(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	movss	.LCPI0_5(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_208
.LBB0_420:                              #   in Loop: Header=BB0_394 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r11)
.LBB0_421:                              #   in Loop: Header=BB0_394 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_394:                              # =>This Inner Loop Header: Depth=1
	movd	%ebx, %xmm6
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-8(%rax,%r11), %eax
	movd	%eax, %xmm0
	shrl	$16, %eax
	movd	%eax, %xmm7
	punpckldq	%xmm7, %xmm0            # xmm0 = xmm0[0],xmm7[0],xmm0[1],xmm7[1]
	pand	%xmm1, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm7
	paddd	%xmm6, %xmm7
	pshufd	$85, %xmm7, %xmm0               # xmm0 = xmm7[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_396
# %bb.395:                              #   in Loop: Header=BB0_394 Depth=1
	movl	%r14d, %r12d
.LBB0_396:                              #   in Loop: Header=BB0_394 Depth=1
	pshufd	$80, %xmm7, %xmm0               # xmm0 = xmm7[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_397
# %bb.398:                              #   in Loop: Header=BB0_394 Depth=1
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_399
.LBB0_400:                              #   in Loop: Header=BB0_394 Depth=1
	testb	$1, %r15b
	jne	.LBB0_402
.LBB0_401:                              #   in Loop: Header=BB0_394 Depth=1
	movl	%edx, %ebp
.LBB0_402:                              #   in Loop: Header=BB0_394 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -8(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_421
# %bb.403:                              #   in Loop: Header=BB0_394 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-4(%rax,%r11), %eax
	movd	%eax, %xmm0
	shrl	$16, %eax
	movd	%eax, %xmm7
	punpckldq	%xmm7, %xmm0            # xmm0 = xmm0[0],xmm7[0],xmm0[1],xmm7[1]
	pand	%xmm1, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm4, %xmm7
	punpcklqdq	%xmm6, %xmm7            # xmm7 = xmm7[0],xmm6[0]
	shufps	$226, %xmm6, %xmm7              # xmm7 = xmm7[2,0],xmm6[2,3]
	paddd	%xmm0, %xmm7
	pshufd	$85, %xmm7, %xmm0               # xmm0 = xmm7[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_405
# %bb.404:                              #   in Loop: Header=BB0_394 Depth=1
	movl	%r14d, %r12d
.LBB0_405:                              #   in Loop: Header=BB0_394 Depth=1
	pshufd	$80, %xmm7, %xmm0               # xmm0 = xmm7[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_406
# %bb.407:                              #   in Loop: Header=BB0_394 Depth=1
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_408
.LBB0_409:                              #   in Loop: Header=BB0_394 Depth=1
	testb	$1, %r15b
	jne	.LBB0_411
.LBB0_410:                              #   in Loop: Header=BB0_394 Depth=1
	movl	%edx, %ebp
.LBB0_411:                              #   in Loop: Header=BB0_394 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -4(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_421
# %bb.412:                              #   in Loop: Header=BB0_394 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r11), %eax
	movd	%eax, %xmm0
	shrl	$16, %eax
	movd	%eax, %xmm7
	punpckldq	%xmm7, %xmm0            # xmm0 = xmm0[0],xmm7[0],xmm0[1],xmm7[1]
	pand	%xmm1, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm5, %xmm7
	punpcklqdq	%xmm6, %xmm7            # xmm7 = xmm7[0],xmm6[0]
	shufps	$226, %xmm6, %xmm7              # xmm7 = xmm7[2,0],xmm6[2,3]
	paddd	%xmm0, %xmm7
	pshufd	$85, %xmm7, %xmm0               # xmm0 = xmm7[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_414
# %bb.413:                              #   in Loop: Header=BB0_394 Depth=1
	movl	%r14d, %r12d
.LBB0_414:                              #   in Loop: Header=BB0_394 Depth=1
	pshufd	$80, %xmm7, %xmm0               # xmm0 = xmm7[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_415
# %bb.416:                              #   in Loop: Header=BB0_394 Depth=1
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_417
.LBB0_418:                              #   in Loop: Header=BB0_394 Depth=1
	testb	$1, %r15b
	jne	.LBB0_420
	jmp	.LBB0_419
.LBB0_397:                              #   in Loop: Header=BB0_394 Depth=1
	movl	%r12d, %eax
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_400
.LBB0_399:                              #   in Loop: Header=BB0_394 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_401
	jmp	.LBB0_402
.LBB0_406:                              #   in Loop: Header=BB0_394 Depth=1
	movl	%r12d, %eax
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_409
.LBB0_408:                              #   in Loop: Header=BB0_394 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_410
	jmp	.LBB0_411
.LBB0_415:                              #   in Loop: Header=BB0_394 Depth=1
	movl	%r12d, %eax
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_418
.LBB0_417:                              #   in Loop: Header=BB0_394 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	jne	.LBB0_420
.LBB0_419:                              #   in Loop: Header=BB0_394 Depth=1
	movl	%edx, %ebp
	jmp	.LBB0_420
.LBB0_606:                              #   in Loop: Header=BB0_580 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r11)
.LBB0_607:                              #   in Loop: Header=BB0_580 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_580:                              # =>This Inner Loop Header: Depth=1
	movd	%ebx, %xmm5
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-8(%rax,%r11), %eax
	movl	%eax, %edx
	shrl	$16, %edx
	movzbl	%dl, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm6, %xmm0            # xmm0 = xmm0[0],xmm6[0],xmm0[1],xmm6[1]
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm6
	paddd	%xmm5, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_582
# %bb.581:                              #   in Loop: Header=BB0_580 Depth=1
	movl	%r14d, %r12d
.LBB0_582:                              #   in Loop: Header=BB0_580 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_583
# %bb.584:                              #   in Loop: Header=BB0_580 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_585
.LBB0_586:                              #   in Loop: Header=BB0_580 Depth=1
	testb	$1, %r15b
	jne	.LBB0_588
.LBB0_587:                              #   in Loop: Header=BB0_580 Depth=1
	movl	%edx, %ebp
.LBB0_588:                              #   in Loop: Header=BB0_580 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -8(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_607
# %bb.589:                              #   in Loop: Header=BB0_580 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-4(%rax,%r11), %eax
	movl	%eax, %edx
	shrl	$16, %edx
	movzbl	%dl, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm6, %xmm0            # xmm0 = xmm0[0],xmm6[0],xmm0[1],xmm6[1]
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm3, %xmm6
	punpcklqdq	%xmm5, %xmm6            # xmm6 = xmm6[0],xmm5[0]
	shufps	$226, %xmm5, %xmm6              # xmm6 = xmm6[2,0],xmm5[2,3]
	paddd	%xmm0, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_591
# %bb.590:                              #   in Loop: Header=BB0_580 Depth=1
	movl	%r14d, %r12d
.LBB0_591:                              #   in Loop: Header=BB0_580 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_592
# %bb.593:                              #   in Loop: Header=BB0_580 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_594
.LBB0_595:                              #   in Loop: Header=BB0_580 Depth=1
	testb	$1, %r15b
	jne	.LBB0_597
.LBB0_596:                              #   in Loop: Header=BB0_580 Depth=1
	movl	%edx, %ebp
.LBB0_597:                              #   in Loop: Header=BB0_580 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -4(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_607
# %bb.598:                              #   in Loop: Header=BB0_580 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r11), %eax
	movl	%eax, %edx
	shrl	$16, %edx
	movzbl	%dl, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm6, %xmm0            # xmm0 = xmm0[0],xmm6[0],xmm0[1],xmm6[1]
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm4, %xmm6
	punpcklqdq	%xmm5, %xmm6            # xmm6 = xmm6[0],xmm5[0]
	shufps	$226, %xmm5, %xmm6              # xmm6 = xmm6[2,0],xmm5[2,3]
	paddd	%xmm0, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_600
# %bb.599:                              #   in Loop: Header=BB0_580 Depth=1
	movl	%r14d, %r12d
.LBB0_600:                              #   in Loop: Header=BB0_580 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_601
# %bb.602:                              #   in Loop: Header=BB0_580 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_603
.LBB0_604:                              #   in Loop: Header=BB0_580 Depth=1
	testb	$1, %r15b
	jne	.LBB0_606
	jmp	.LBB0_605
.LBB0_583:                              #   in Loop: Header=BB0_580 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_586
.LBB0_585:                              #   in Loop: Header=BB0_580 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_587
	jmp	.LBB0_588
.LBB0_592:                              #   in Loop: Header=BB0_580 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_595
.LBB0_594:                              #   in Loop: Header=BB0_580 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_596
	jmp	.LBB0_597
.LBB0_601:                              #   in Loop: Header=BB0_580 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_604
.LBB0_603:                              #   in Loop: Header=BB0_580 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	jne	.LBB0_606
.LBB0_605:                              #   in Loop: Header=BB0_580 Depth=1
	movl	%edx, %ebp
	jmp	.LBB0_606
.LBB0_48:                               #   in Loop: Header=BB0_22 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-120(%rsp), %rdx                # 8-byte Reload
	movl	%eax, (%rdx,%r11)
.LBB0_49:                               #   in Loop: Header=BB0_22 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_22:                               # =>This Inner Loop Header: Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movzbl	-6(%rax,%r11), %eax
	xorps	%xmm3, %xmm3
	cvtsi2ss	%eax, %xmm3
	divss	%xmm1, %xmm3
	addss	%xmm2, %xmm3
	mulss	%xmm12, %xmm3
	cvttss2si	%xmm3, %r14d
	movl	%r14d, %edx
	cmpl	%esi, %r14d
	jge	.LBB0_23
# %bb.24:                               #   in Loop: Header=BB0_22 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	jns	.LBB0_25
.LBB0_26:                               #   in Loop: Header=BB0_22 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jge	.LBB0_27
.LBB0_28:                               #   in Loop: Header=BB0_22 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_30
.LBB0_29:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %ebp
.LBB0_30:                               #   in Loop: Header=BB0_22 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-120(%rsp), %rdx                # 8-byte Reload
	movl	%eax, -8(%rdx,%r11)
	cmpl	$1, %ecx
	je	.LBB0_49
# %bb.31:                               #   in Loop: Header=BB0_22 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movzbl	-2(%rax,%r11), %eax
	xorps	%xmm3, %xmm3
	cvtsi2ss	%eax, %xmm3
	divss	%xmm1, %xmm3
	addss	%xmm2, %xmm3
	mulss	%xmm12, %xmm3
	cvttss2si	%xmm3, %r14d
	leal	1(%r14), %edx
	cmpl	%esi, %edx
	jge	.LBB0_32
# %bb.33:                               #   in Loop: Header=BB0_22 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jge	.LBB0_34
.LBB0_35:                               #   in Loop: Header=BB0_22 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jge	.LBB0_36
.LBB0_37:                               #   in Loop: Header=BB0_22 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_39
.LBB0_38:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %ebp
.LBB0_39:                               #   in Loop: Header=BB0_22 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-120(%rsp), %rdx                # 8-byte Reload
	movl	%eax, -4(%rdx,%r11)
	cmpl	$2, %ecx
	je	.LBB0_49
# %bb.40:                               #   in Loop: Header=BB0_22 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movzbl	2(%rax,%r11), %eax
	xorps	%xmm3, %xmm3
	cvtsi2ss	%eax, %xmm3
	divss	%xmm1, %xmm3
	addss	%xmm2, %xmm3
	mulss	%xmm12, %xmm3
	cvttss2si	%xmm3, %r14d
	leal	2(%r14), %edx
	cmpl	%esi, %edx
	jge	.LBB0_41
# %bb.42:                               #   in Loop: Header=BB0_22 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jge	.LBB0_43
.LBB0_44:                               #   in Loop: Header=BB0_22 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jge	.LBB0_45
.LBB0_46:                               #   in Loop: Header=BB0_22 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_48
	jmp	.LBB0_47
.LBB0_23:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%esi, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	js	.LBB0_26
.LBB0_25:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jl	.LBB0_28
.LBB0_27:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%r9d, %eax
	testl	%r14d, %r14d
	jns	.LBB0_29
	jmp	.LBB0_30
.LBB0_32:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%esi, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jl	.LBB0_35
.LBB0_34:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jl	.LBB0_37
.LBB0_36:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%r9d, %eax
	testl	%r14d, %r14d
	jns	.LBB0_38
	jmp	.LBB0_39
.LBB0_41:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%esi, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jl	.LBB0_44
.LBB0_43:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jl	.LBB0_46
.LBB0_45:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%r9d, %eax
	testl	%r14d, %r14d
	js	.LBB0_48
.LBB0_47:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %ebp
	jmp	.LBB0_48
.LBB0_234:                              #   in Loop: Header=BB0_208 Depth=1
	imull	%ecx, %ebp
	addl	%r14d, %ebp
	movslq	%ebp, %rsi
	movl	(%rdi,%rsi,4), %esi
	movq	-120(%rsp), %r11                # 8-byte Reload
	movl	%esi, (%r11,%rax)
.LBB0_235:                              #   in Loop: Header=BB0_208 Depth=1
	incq	%r15
	addq	%r10, %rax
	cmpq	%r15, %r8
	je	.LBB0_746
.LBB0_208:                              # =>This Inner Loop Header: Depth=1
	movq	-128(%rsp), %rsi                # 8-byte Reload
	movl	-8(%rsi,%rax), %ebx
	movl	%ebx, %esi
	shrl	$16, %esi
	movzbl	%sil, %esi
	xorps	%xmm0, %xmm0
	cvtsi2ss	%esi, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r11d
	movl	%r11d, %esi
	cmpl	%edx, %r11d
	jl	.LBB0_210
# %bb.209:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%edx, %esi
.LBB0_210:                              #   in Loop: Header=BB0_208 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r14d
	testl	%r11d, %r11d
	js	.LBB0_212
# %bb.211:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%esi, %r14d
.LBB0_212:                              #   in Loop: Header=BB0_208 Depth=1
	movzbl	%bh, %esi
	xorps	%xmm0, %xmm0
	cvtsi2ss	%esi, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r11d
	addl	%r15d, %r11d
	movl	%r11d, %esi
	cmpl	%r9d, %r11d
	jl	.LBB0_214
# %bb.213:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%r9d, %esi
.LBB0_214:                              #   in Loop: Header=BB0_208 Depth=1
	testl	%r11d, %r11d
	js	.LBB0_216
# %bb.215:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%esi, %ebp
.LBB0_216:                              #   in Loop: Header=BB0_208 Depth=1
	imull	%ecx, %ebp
	addl	%r14d, %ebp
	movslq	%ebp, %rsi
	movl	(%rdi,%rsi,4), %esi
	movq	-120(%rsp), %r11                # 8-byte Reload
	movl	%esi, -8(%r11,%rax)
	cmpl	$1, %ecx
	je	.LBB0_235
# %bb.217:                              #   in Loop: Header=BB0_208 Depth=1
	movq	-128(%rsp), %rsi                # 8-byte Reload
	movl	-4(%rsi,%rax), %esi
	movl	%esi, %r12d
	shrl	$16, %esi
	movzbl	%sil, %esi
	xorps	%xmm0, %xmm0
	cvtsi2ss	%esi, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r11d
	leal	1(%r11), %ebx
	cmpl	%edx, %ebx
	jl	.LBB0_219
# %bb.218:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%edx, %ebx
.LBB0_219:                              #   in Loop: Header=BB0_208 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r14d
	cmpl	$-1, %r11d
	jl	.LBB0_221
# %bb.220:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%ebx, %r14d
.LBB0_221:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%r12d, %ebx
	movzbl	%bh, %esi
	xorps	%xmm0, %xmm0
	cvtsi2ss	%esi, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r11d
	addl	%r15d, %r11d
	movl	%r11d, %esi
	cmpl	%r9d, %r11d
	jl	.LBB0_223
# %bb.222:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%r9d, %esi
.LBB0_223:                              #   in Loop: Header=BB0_208 Depth=1
	testl	%r11d, %r11d
	js	.LBB0_225
# %bb.224:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%esi, %ebp
.LBB0_225:                              #   in Loop: Header=BB0_208 Depth=1
	imull	%ecx, %ebp
	addl	%r14d, %ebp
	movslq	%ebp, %rsi
	movl	(%rdi,%rsi,4), %esi
	movq	-120(%rsp), %r11                # 8-byte Reload
	movl	%esi, -4(%r11,%rax)
	cmpl	$2, %ecx
	je	.LBB0_235
# %bb.226:                              #   in Loop: Header=BB0_208 Depth=1
	movq	-128(%rsp), %rsi                # 8-byte Reload
	movl	(%rsi,%rax), %esi
	movl	%esi, %r12d
	shrl	$16, %esi
	movzbl	%sil, %esi
	xorps	%xmm0, %xmm0
	cvtsi2ss	%esi, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r11d
	leal	2(%r11), %ebx
	cmpl	%edx, %ebx
	jl	.LBB0_228
# %bb.227:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%edx, %ebx
.LBB0_228:                              #   in Loop: Header=BB0_208 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r14d
	cmpl	$-2, %r11d
	jl	.LBB0_230
# %bb.229:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%ebx, %r14d
.LBB0_230:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%r12d, %ebx
	movzbl	%bh, %esi
	xorps	%xmm0, %xmm0
	cvtsi2ss	%esi, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r11d
	addl	%r15d, %r11d
	movl	%r11d, %esi
	cmpl	%r9d, %r11d
	jl	.LBB0_232
# %bb.231:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%r9d, %esi
.LBB0_232:                              #   in Loop: Header=BB0_208 Depth=1
	testl	%r11d, %r11d
	js	.LBB0_234
# %bb.233:                              #   in Loop: Header=BB0_208 Depth=1
	movl	%esi, %ebp
	jmp	.LBB0_234
.LBB0_468:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.469:
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_470
# %bb.484:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.485:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movss	.LCPI0_4(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	movss	.LCPI0_5(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	movq	-120(%rsp), %rsi                # 8-byte Reload
	jmp	.LBB0_486
.LBB0_512:                              #   in Loop: Header=BB0_486 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rdx
	movl	(%rdi,%rdx,4), %edx
	movl	%edx, (%rsi,%r11)
.LBB0_513:                              #   in Loop: Header=BB0_486 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_486:                              # =>This Inner Loop Header: Depth=1
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movzbl	-8(%rdx,%r11), %edx
	xorps	%xmm0, %xmm0
	cvtsi2ss	%edx, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r14d
	movl	%r14d, %edx
	cmpl	%eax, %r14d
	jge	.LBB0_487
# %bb.488:                              #   in Loop: Header=BB0_486 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	jns	.LBB0_489
.LBB0_490:                              #   in Loop: Header=BB0_486 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jge	.LBB0_491
.LBB0_492:                              #   in Loop: Header=BB0_486 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_494
.LBB0_493:                              #   in Loop: Header=BB0_486 Depth=1
	movl	%edx, %ebp
.LBB0_494:                              #   in Loop: Header=BB0_486 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rdx
	movl	(%rdi,%rdx,4), %edx
	movl	%edx, -8(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_513
# %bb.495:                              #   in Loop: Header=BB0_486 Depth=1
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movzbl	-4(%rdx,%r11), %edx
	xorps	%xmm0, %xmm0
	cvtsi2ss	%edx, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r14d
	leal	1(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_496
# %bb.497:                              #   in Loop: Header=BB0_486 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jge	.LBB0_498
.LBB0_499:                              #   in Loop: Header=BB0_486 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jge	.LBB0_500
.LBB0_501:                              #   in Loop: Header=BB0_486 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_503
.LBB0_502:                              #   in Loop: Header=BB0_486 Depth=1
	movl	%edx, %ebp
.LBB0_503:                              #   in Loop: Header=BB0_486 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rdx
	movl	(%rdi,%rdx,4), %edx
	movl	%edx, -4(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_513
# %bb.504:                              #   in Loop: Header=BB0_486 Depth=1
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movzbl	(%rdx,%r11), %edx
	xorps	%xmm0, %xmm0
	cvtsi2ss	%edx, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r14d
	leal	2(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_505
# %bb.506:                              #   in Loop: Header=BB0_486 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jge	.LBB0_507
.LBB0_508:                              #   in Loop: Header=BB0_486 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jge	.LBB0_509
.LBB0_510:                              #   in Loop: Header=BB0_486 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_512
	jmp	.LBB0_511
.LBB0_487:                              #   in Loop: Header=BB0_486 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	js	.LBB0_490
.LBB0_489:                              #   in Loop: Header=BB0_486 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jl	.LBB0_492
.LBB0_491:                              #   in Loop: Header=BB0_486 Depth=1
	movl	%r9d, %edx
	testl	%r14d, %r14d
	jns	.LBB0_493
	jmp	.LBB0_494
.LBB0_496:                              #   in Loop: Header=BB0_486 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jl	.LBB0_499
.LBB0_498:                              #   in Loop: Header=BB0_486 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jl	.LBB0_501
.LBB0_500:                              #   in Loop: Header=BB0_486 Depth=1
	movl	%r9d, %edx
	testl	%r14d, %r14d
	jns	.LBB0_502
	jmp	.LBB0_503
.LBB0_505:                              #   in Loop: Header=BB0_486 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jl	.LBB0_508
.LBB0_507:                              #   in Loop: Header=BB0_486 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jl	.LBB0_510
.LBB0_509:                              #   in Loop: Header=BB0_486 Depth=1
	movl	%r9d, %edx
	testl	%r14d, %r14d
	js	.LBB0_512
.LBB0_511:                              #   in Loop: Header=BB0_486 Depth=1
	movl	%edx, %ebp
	jmp	.LBB0_512
.LBB0_514:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.515:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	leal	-1(%rcx), %r14d
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_516
# %bb.530:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.531:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movaps	.LCPI0_7(%rip), %xmm1           # xmm1 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm2           # xmm2 = [-5.0E-1,-5.0E-1,u,u]
	movl	$1, %eax
	movd	%eax, %xmm3
	movl	$2, %eax
	movd	%eax, %xmm4
	movq	-120(%rsp), %rsi                # 8-byte Reload
	jmp	.LBB0_532
.LBB0_558:                              #   in Loop: Header=BB0_532 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r11)
.LBB0_559:                              #   in Loop: Header=BB0_532 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_532:                              # =>This Inner Loop Header: Depth=1
	movd	%ebx, %xmm5
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-8(%rax,%r11), %eax
	movzbl	%al, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm0, %xmm6            # xmm6 = xmm6[0],xmm0[0],xmm6[1],xmm0[1]
	cvtdq2ps	%xmm6, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm6
	paddd	%xmm5, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_534
# %bb.533:                              #   in Loop: Header=BB0_532 Depth=1
	movl	%r14d, %r12d
.LBB0_534:                              #   in Loop: Header=BB0_532 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_535
# %bb.536:                              #   in Loop: Header=BB0_532 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_537
.LBB0_538:                              #   in Loop: Header=BB0_532 Depth=1
	testb	$1, %r15b
	jne	.LBB0_540
.LBB0_539:                              #   in Loop: Header=BB0_532 Depth=1
	movl	%edx, %ebp
.LBB0_540:                              #   in Loop: Header=BB0_532 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -8(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_559
# %bb.541:                              #   in Loop: Header=BB0_532 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-4(%rax,%r11), %eax
	movzbl	%al, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm0, %xmm6            # xmm6 = xmm6[0],xmm0[0],xmm6[1],xmm0[1]
	cvtdq2ps	%xmm6, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm3, %xmm6
	punpcklqdq	%xmm5, %xmm6            # xmm6 = xmm6[0],xmm5[0]
	shufps	$226, %xmm5, %xmm6              # xmm6 = xmm6[2,0],xmm5[2,3]
	paddd	%xmm0, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_543
# %bb.542:                              #   in Loop: Header=BB0_532 Depth=1
	movl	%r14d, %r12d
.LBB0_543:                              #   in Loop: Header=BB0_532 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_544
# %bb.545:                              #   in Loop: Header=BB0_532 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_546
.LBB0_547:                              #   in Loop: Header=BB0_532 Depth=1
	testb	$1, %r15b
	jne	.LBB0_549
.LBB0_548:                              #   in Loop: Header=BB0_532 Depth=1
	movl	%edx, %ebp
.LBB0_549:                              #   in Loop: Header=BB0_532 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -4(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_559
# %bb.550:                              #   in Loop: Header=BB0_532 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r11), %eax
	movzbl	%al, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm0, %xmm6            # xmm6 = xmm6[0],xmm0[0],xmm6[1],xmm0[1]
	cvtdq2ps	%xmm6, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm4, %xmm6
	punpcklqdq	%xmm5, %xmm6            # xmm6 = xmm6[0],xmm5[0]
	shufps	$226, %xmm5, %xmm6              # xmm6 = xmm6[2,0],xmm5[2,3]
	paddd	%xmm0, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_552
# %bb.551:                              #   in Loop: Header=BB0_532 Depth=1
	movl	%r14d, %r12d
.LBB0_552:                              #   in Loop: Header=BB0_532 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_553
# %bb.554:                              #   in Loop: Header=BB0_532 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_555
.LBB0_556:                              #   in Loop: Header=BB0_532 Depth=1
	testb	$1, %r15b
	jne	.LBB0_558
	jmp	.LBB0_557
.LBB0_535:                              #   in Loop: Header=BB0_532 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_538
.LBB0_537:                              #   in Loop: Header=BB0_532 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_539
	jmp	.LBB0_540
.LBB0_544:                              #   in Loop: Header=BB0_532 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_547
.LBB0_546:                              #   in Loop: Header=BB0_532 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_548
	jmp	.LBB0_549
.LBB0_553:                              #   in Loop: Header=BB0_532 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_556
.LBB0_555:                              #   in Loop: Header=BB0_532 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	jne	.LBB0_558
.LBB0_557:                              #   in Loop: Header=BB0_532 Depth=1
	movl	%edx, %ebp
	jmp	.LBB0_558
.LBB0_654:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.655:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	leal	-1(%rcx), %r14d
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_656
# %bb.670:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.671:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movaps	.LCPI0_7(%rip), %xmm1           # xmm1 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm2           # xmm2 = [-5.0E-1,-5.0E-1,u,u]
	movl	$1, %eax
	movd	%eax, %xmm3
	movl	$2, %eax
	movd	%eax, %xmm4
	movq	-120(%rsp), %rsi                # 8-byte Reload
	jmp	.LBB0_672
.LBB0_698:                              #   in Loop: Header=BB0_672 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r11)
.LBB0_699:                              #   in Loop: Header=BB0_672 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_672:                              # =>This Inner Loop Header: Depth=1
	movd	%ebx, %xmm5
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-8(%rax,%r11), %eax
	movzbl	%al, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm6, %xmm0            # xmm0 = xmm0[0],xmm6[0],xmm0[1],xmm6[1]
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm6
	paddd	%xmm5, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_674
# %bb.673:                              #   in Loop: Header=BB0_672 Depth=1
	movl	%r14d, %r12d
.LBB0_674:                              #   in Loop: Header=BB0_672 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_675
# %bb.676:                              #   in Loop: Header=BB0_672 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_677
.LBB0_678:                              #   in Loop: Header=BB0_672 Depth=1
	testb	$1, %r15b
	jne	.LBB0_680
.LBB0_679:                              #   in Loop: Header=BB0_672 Depth=1
	movl	%edx, %ebp
.LBB0_680:                              #   in Loop: Header=BB0_672 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -8(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_699
# %bb.681:                              #   in Loop: Header=BB0_672 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-4(%rax,%r11), %eax
	movzbl	%al, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm6, %xmm0            # xmm0 = xmm0[0],xmm6[0],xmm0[1],xmm6[1]
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm3, %xmm6
	punpcklqdq	%xmm5, %xmm6            # xmm6 = xmm6[0],xmm5[0]
	shufps	$226, %xmm5, %xmm6              # xmm6 = xmm6[2,0],xmm5[2,3]
	paddd	%xmm0, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_683
# %bb.682:                              #   in Loop: Header=BB0_672 Depth=1
	movl	%r14d, %r12d
.LBB0_683:                              #   in Loop: Header=BB0_672 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_684
# %bb.685:                              #   in Loop: Header=BB0_672 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_686
.LBB0_687:                              #   in Loop: Header=BB0_672 Depth=1
	testb	$1, %r15b
	jne	.LBB0_689
.LBB0_688:                              #   in Loop: Header=BB0_672 Depth=1
	movl	%edx, %ebp
.LBB0_689:                              #   in Loop: Header=BB0_672 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -4(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_699
# %bb.690:                              #   in Loop: Header=BB0_672 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r11), %eax
	movzbl	%al, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm6, %xmm0            # xmm0 = xmm0[0],xmm6[0],xmm0[1],xmm6[1]
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm4, %xmm6
	punpcklqdq	%xmm5, %xmm6            # xmm6 = xmm6[0],xmm5[0]
	shufps	$226, %xmm5, %xmm6              # xmm6 = xmm6[2,0],xmm5[2,3]
	paddd	%xmm0, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_692
# %bb.691:                              #   in Loop: Header=BB0_672 Depth=1
	movl	%r14d, %r12d
.LBB0_692:                              #   in Loop: Header=BB0_672 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_693
# %bb.694:                              #   in Loop: Header=BB0_672 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_695
.LBB0_696:                              #   in Loop: Header=BB0_672 Depth=1
	testb	$1, %r15b
	jne	.LBB0_698
	jmp	.LBB0_697
.LBB0_675:                              #   in Loop: Header=BB0_672 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_678
.LBB0_677:                              #   in Loop: Header=BB0_672 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_679
	jmp	.LBB0_680
.LBB0_684:                              #   in Loop: Header=BB0_672 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_687
.LBB0_686:                              #   in Loop: Header=BB0_672 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_688
	jmp	.LBB0_689
.LBB0_693:                              #   in Loop: Header=BB0_672 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_696
.LBB0_695:                              #   in Loop: Header=BB0_672 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	jne	.LBB0_698
.LBB0_697:                              #   in Loop: Header=BB0_672 Depth=1
	movl	%edx, %ebp
	jmp	.LBB0_698
.LBB0_96:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.97:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	leal	-1(%rcx), %r14d
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_98
# %bb.112:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.113:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movq	.LCPI0_9(%rip), %xmm1           # xmm1 = [255,0,0,0,255,0,0,0,0,0,0,0,0,0,0,0]
	movaps	.LCPI0_7(%rip), %xmm2           # xmm2 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm3           # xmm3 = [-5.0E-1,-5.0E-1,u,u]
	movl	$1, %eax
	movd	%eax, %xmm4
	movl	$2, %eax
	movd	%eax, %xmm5
	movq	-120(%rsp), %rsi                # 8-byte Reload
	jmp	.LBB0_114
.LBB0_140:                              #   in Loop: Header=BB0_114 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r11)
.LBB0_141:                              #   in Loop: Header=BB0_114 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_114:                              # =>This Inner Loop Header: Depth=1
	movd	%ebx, %xmm6
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-8(%rax,%r11), %eax
	movd	%eax, %xmm0
	shrl	$16, %eax
	movd	%eax, %xmm7
	punpckldq	%xmm0, %xmm7            # xmm7 = xmm7[0],xmm0[0],xmm7[1],xmm0[1]
	pand	%xmm1, %xmm7
	cvtdq2ps	%xmm7, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm7
	paddd	%xmm6, %xmm7
	pshufd	$85, %xmm7, %xmm0               # xmm0 = xmm7[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_116
# %bb.115:                              #   in Loop: Header=BB0_114 Depth=1
	movl	%r14d, %r12d
.LBB0_116:                              #   in Loop: Header=BB0_114 Depth=1
	pshufd	$80, %xmm7, %xmm0               # xmm0 = xmm7[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_117
# %bb.118:                              #   in Loop: Header=BB0_114 Depth=1
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_119
.LBB0_120:                              #   in Loop: Header=BB0_114 Depth=1
	testb	$1, %r15b
	jne	.LBB0_122
.LBB0_121:                              #   in Loop: Header=BB0_114 Depth=1
	movl	%edx, %ebp
.LBB0_122:                              #   in Loop: Header=BB0_114 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -8(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_141
# %bb.123:                              #   in Loop: Header=BB0_114 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-4(%rax,%r11), %eax
	movd	%eax, %xmm0
	shrl	$16, %eax
	movd	%eax, %xmm7
	punpckldq	%xmm0, %xmm7            # xmm7 = xmm7[0],xmm0[0],xmm7[1],xmm0[1]
	pand	%xmm1, %xmm7
	cvtdq2ps	%xmm7, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm4, %xmm7
	punpcklqdq	%xmm6, %xmm7            # xmm7 = xmm7[0],xmm6[0]
	shufps	$226, %xmm6, %xmm7              # xmm7 = xmm7[2,0],xmm6[2,3]
	paddd	%xmm0, %xmm7
	pshufd	$85, %xmm7, %xmm0               # xmm0 = xmm7[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_125
# %bb.124:                              #   in Loop: Header=BB0_114 Depth=1
	movl	%r14d, %r12d
.LBB0_125:                              #   in Loop: Header=BB0_114 Depth=1
	pshufd	$80, %xmm7, %xmm0               # xmm0 = xmm7[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_126
# %bb.127:                              #   in Loop: Header=BB0_114 Depth=1
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_128
.LBB0_129:                              #   in Loop: Header=BB0_114 Depth=1
	testb	$1, %r15b
	jne	.LBB0_131
.LBB0_130:                              #   in Loop: Header=BB0_114 Depth=1
	movl	%edx, %ebp
.LBB0_131:                              #   in Loop: Header=BB0_114 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -4(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_141
# %bb.132:                              #   in Loop: Header=BB0_114 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r11), %eax
	movd	%eax, %xmm0
	shrl	$16, %eax
	movd	%eax, %xmm7
	punpckldq	%xmm0, %xmm7            # xmm7 = xmm7[0],xmm0[0],xmm7[1],xmm0[1]
	pand	%xmm1, %xmm7
	cvtdq2ps	%xmm7, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm5, %xmm7
	punpcklqdq	%xmm6, %xmm7            # xmm7 = xmm7[0],xmm6[0]
	shufps	$226, %xmm6, %xmm7              # xmm7 = xmm7[2,0],xmm6[2,3]
	paddd	%xmm0, %xmm7
	pshufd	$85, %xmm7, %xmm0               # xmm0 = xmm7[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_134
# %bb.133:                              #   in Loop: Header=BB0_114 Depth=1
	movl	%r14d, %r12d
.LBB0_134:                              #   in Loop: Header=BB0_114 Depth=1
	pshufd	$80, %xmm7, %xmm0               # xmm0 = xmm7[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_135
# %bb.136:                              #   in Loop: Header=BB0_114 Depth=1
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_137
.LBB0_138:                              #   in Loop: Header=BB0_114 Depth=1
	testb	$1, %r15b
	jne	.LBB0_140
	jmp	.LBB0_139
.LBB0_117:                              #   in Loop: Header=BB0_114 Depth=1
	movl	%r12d, %eax
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_120
.LBB0_119:                              #   in Loop: Header=BB0_114 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_121
	jmp	.LBB0_122
.LBB0_126:                              #   in Loop: Header=BB0_114 Depth=1
	movl	%r12d, %eax
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_129
.LBB0_128:                              #   in Loop: Header=BB0_114 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_130
	jmp	.LBB0_131
.LBB0_135:                              #   in Loop: Header=BB0_114 Depth=1
	movl	%r12d, %eax
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_138
.LBB0_137:                              #   in Loop: Header=BB0_114 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	jne	.LBB0_140
.LBB0_139:                              #   in Loop: Header=BB0_114 Depth=1
	movl	%edx, %ebp
	jmp	.LBB0_140
.LBB0_422:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.423:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	leal	-1(%rcx), %r14d
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_424
# %bb.438:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.439:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movq	.LCPI0_9(%rip), %xmm1           # xmm1 = [255,0,0,0,255,0,0,0,0,0,0,0,0,0,0,0]
	movaps	.LCPI0_7(%rip), %xmm2           # xmm2 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm3           # xmm3 = [-5.0E-1,-5.0E-1,u,u]
	movl	$1, %eax
	movd	%eax, %xmm4
	movl	$2, %eax
	movd	%eax, %xmm5
	movq	-120(%rsp), %rsi                # 8-byte Reload
	jmp	.LBB0_440
.LBB0_466:                              #   in Loop: Header=BB0_440 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r11)
.LBB0_467:                              #   in Loop: Header=BB0_440 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_440:                              # =>This Inner Loop Header: Depth=1
	movd	%ebx, %xmm6
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-8(%rax,%r11), %eax
	movd	%eax, %xmm0
	shrl	$8, %eax
	movd	%eax, %xmm7
	punpckldq	%xmm7, %xmm0            # xmm0 = xmm0[0],xmm7[0],xmm0[1],xmm7[1]
	pand	%xmm1, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm7
	paddd	%xmm6, %xmm7
	pshufd	$85, %xmm7, %xmm0               # xmm0 = xmm7[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_442
# %bb.441:                              #   in Loop: Header=BB0_440 Depth=1
	movl	%r14d, %r12d
.LBB0_442:                              #   in Loop: Header=BB0_440 Depth=1
	pshufd	$80, %xmm7, %xmm0               # xmm0 = xmm7[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_443
# %bb.444:                              #   in Loop: Header=BB0_440 Depth=1
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_445
.LBB0_446:                              #   in Loop: Header=BB0_440 Depth=1
	testb	$1, %r15b
	jne	.LBB0_448
.LBB0_447:                              #   in Loop: Header=BB0_440 Depth=1
	movl	%edx, %ebp
.LBB0_448:                              #   in Loop: Header=BB0_440 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -8(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_467
# %bb.449:                              #   in Loop: Header=BB0_440 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-4(%rax,%r11), %eax
	movd	%eax, %xmm0
	shrl	$8, %eax
	movd	%eax, %xmm7
	punpckldq	%xmm7, %xmm0            # xmm0 = xmm0[0],xmm7[0],xmm0[1],xmm7[1]
	pand	%xmm1, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm4, %xmm7
	punpcklqdq	%xmm6, %xmm7            # xmm7 = xmm7[0],xmm6[0]
	shufps	$226, %xmm6, %xmm7              # xmm7 = xmm7[2,0],xmm6[2,3]
	paddd	%xmm0, %xmm7
	pshufd	$85, %xmm7, %xmm0               # xmm0 = xmm7[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_451
# %bb.450:                              #   in Loop: Header=BB0_440 Depth=1
	movl	%r14d, %r12d
.LBB0_451:                              #   in Loop: Header=BB0_440 Depth=1
	pshufd	$80, %xmm7, %xmm0               # xmm0 = xmm7[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_452
# %bb.453:                              #   in Loop: Header=BB0_440 Depth=1
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_454
.LBB0_455:                              #   in Loop: Header=BB0_440 Depth=1
	testb	$1, %r15b
	jne	.LBB0_457
.LBB0_456:                              #   in Loop: Header=BB0_440 Depth=1
	movl	%edx, %ebp
.LBB0_457:                              #   in Loop: Header=BB0_440 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -4(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_467
# %bb.458:                              #   in Loop: Header=BB0_440 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r11), %eax
	movd	%eax, %xmm0
	shrl	$8, %eax
	movd	%eax, %xmm7
	punpckldq	%xmm7, %xmm0            # xmm0 = xmm0[0],xmm7[0],xmm0[1],xmm7[1]
	pand	%xmm1, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm5, %xmm7
	punpcklqdq	%xmm6, %xmm7            # xmm7 = xmm7[0],xmm6[0]
	shufps	$226, %xmm6, %xmm7              # xmm7 = xmm7[2,0],xmm6[2,3]
	paddd	%xmm0, %xmm7
	pshufd	$85, %xmm7, %xmm0               # xmm0 = xmm7[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_460
# %bb.459:                              #   in Loop: Header=BB0_440 Depth=1
	movl	%r14d, %r12d
.LBB0_460:                              #   in Loop: Header=BB0_440 Depth=1
	pshufd	$80, %xmm7, %xmm0               # xmm0 = xmm7[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_461
# %bb.462:                              #   in Loop: Header=BB0_440 Depth=1
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_463
.LBB0_464:                              #   in Loop: Header=BB0_440 Depth=1
	testb	$1, %r15b
	jne	.LBB0_466
	jmp	.LBB0_465
.LBB0_443:                              #   in Loop: Header=BB0_440 Depth=1
	movl	%r12d, %eax
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_446
.LBB0_445:                              #   in Loop: Header=BB0_440 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_447
	jmp	.LBB0_448
.LBB0_452:                              #   in Loop: Header=BB0_440 Depth=1
	movl	%r12d, %eax
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_455
.LBB0_454:                              #   in Loop: Header=BB0_440 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_456
	jmp	.LBB0_457
.LBB0_461:                              #   in Loop: Header=BB0_440 Depth=1
	movl	%r12d, %eax
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_464
.LBB0_463:                              #   in Loop: Header=BB0_440 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	jne	.LBB0_466
.LBB0_465:                              #   in Loop: Header=BB0_440 Depth=1
	movl	%edx, %ebp
	jmp	.LBB0_466
.LBB0_282:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.283:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	leal	-1(%rcx), %r14d
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_284
# %bb.298:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.299:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movq	.LCPI0_9(%rip), %xmm1           # xmm1 = [255,0,0,0,255,0,0,0,0,0,0,0,0,0,0,0]
	movaps	.LCPI0_7(%rip), %xmm2           # xmm2 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm3           # xmm3 = [-5.0E-1,-5.0E-1,u,u]
	movl	$1, %eax
	movd	%eax, %xmm4
	movl	$2, %eax
	movd	%eax, %xmm5
	movq	-120(%rsp), %rsi                # 8-byte Reload
	jmp	.LBB0_300
.LBB0_326:                              #   in Loop: Header=BB0_300 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r11)
.LBB0_327:                              #   in Loop: Header=BB0_300 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_300:                              # =>This Inner Loop Header: Depth=1
	movd	%ebx, %xmm6
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-8(%rax,%r11), %eax
	movd	%eax, %xmm0
	shrl	$8, %eax
	movd	%eax, %xmm7
	punpckldq	%xmm0, %xmm7            # xmm7 = xmm7[0],xmm0[0],xmm7[1],xmm0[1]
	pand	%xmm1, %xmm7
	cvtdq2ps	%xmm7, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm7
	paddd	%xmm6, %xmm7
	pshufd	$85, %xmm7, %xmm0               # xmm0 = xmm7[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_302
# %bb.301:                              #   in Loop: Header=BB0_300 Depth=1
	movl	%r14d, %r12d
.LBB0_302:                              #   in Loop: Header=BB0_300 Depth=1
	pshufd	$80, %xmm7, %xmm0               # xmm0 = xmm7[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_303
# %bb.304:                              #   in Loop: Header=BB0_300 Depth=1
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_305
.LBB0_306:                              #   in Loop: Header=BB0_300 Depth=1
	testb	$1, %r15b
	jne	.LBB0_308
.LBB0_307:                              #   in Loop: Header=BB0_300 Depth=1
	movl	%edx, %ebp
.LBB0_308:                              #   in Loop: Header=BB0_300 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -8(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_327
# %bb.309:                              #   in Loop: Header=BB0_300 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-4(%rax,%r11), %eax
	movd	%eax, %xmm0
	shrl	$8, %eax
	movd	%eax, %xmm7
	punpckldq	%xmm0, %xmm7            # xmm7 = xmm7[0],xmm0[0],xmm7[1],xmm0[1]
	pand	%xmm1, %xmm7
	cvtdq2ps	%xmm7, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm4, %xmm7
	punpcklqdq	%xmm6, %xmm7            # xmm7 = xmm7[0],xmm6[0]
	shufps	$226, %xmm6, %xmm7              # xmm7 = xmm7[2,0],xmm6[2,3]
	paddd	%xmm0, %xmm7
	pshufd	$85, %xmm7, %xmm0               # xmm0 = xmm7[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_311
# %bb.310:                              #   in Loop: Header=BB0_300 Depth=1
	movl	%r14d, %r12d
.LBB0_311:                              #   in Loop: Header=BB0_300 Depth=1
	pshufd	$80, %xmm7, %xmm0               # xmm0 = xmm7[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_312
# %bb.313:                              #   in Loop: Header=BB0_300 Depth=1
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_314
.LBB0_315:                              #   in Loop: Header=BB0_300 Depth=1
	testb	$1, %r15b
	jne	.LBB0_317
.LBB0_316:                              #   in Loop: Header=BB0_300 Depth=1
	movl	%edx, %ebp
.LBB0_317:                              #   in Loop: Header=BB0_300 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -4(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_327
# %bb.318:                              #   in Loop: Header=BB0_300 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r11), %eax
	movd	%eax, %xmm0
	shrl	$8, %eax
	movd	%eax, %xmm7
	punpckldq	%xmm0, %xmm7            # xmm7 = xmm7[0],xmm0[0],xmm7[1],xmm0[1]
	pand	%xmm1, %xmm7
	cvtdq2ps	%xmm7, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm5, %xmm7
	punpcklqdq	%xmm6, %xmm7            # xmm7 = xmm7[0],xmm6[0]
	shufps	$226, %xmm6, %xmm7              # xmm7 = xmm7[2,0],xmm6[2,3]
	paddd	%xmm0, %xmm7
	pshufd	$85, %xmm7, %xmm0               # xmm0 = xmm7[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_320
# %bb.319:                              #   in Loop: Header=BB0_300 Depth=1
	movl	%r14d, %r12d
.LBB0_320:                              #   in Loop: Header=BB0_300 Depth=1
	pshufd	$80, %xmm7, %xmm0               # xmm0 = xmm7[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_321
# %bb.322:                              #   in Loop: Header=BB0_300 Depth=1
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_323
.LBB0_324:                              #   in Loop: Header=BB0_300 Depth=1
	testb	$1, %r15b
	jne	.LBB0_326
	jmp	.LBB0_325
.LBB0_303:                              #   in Loop: Header=BB0_300 Depth=1
	movl	%r12d, %eax
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_306
.LBB0_305:                              #   in Loop: Header=BB0_300 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_307
	jmp	.LBB0_308
.LBB0_312:                              #   in Loop: Header=BB0_300 Depth=1
	movl	%r12d, %eax
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_315
.LBB0_314:                              #   in Loop: Header=BB0_300 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_316
	jmp	.LBB0_317
.LBB0_321:                              #   in Loop: Header=BB0_300 Depth=1
	movl	%r12d, %eax
	movd	%xmm7, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_324
.LBB0_323:                              #   in Loop: Header=BB0_300 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	jne	.LBB0_326
.LBB0_325:                              #   in Loop: Header=BB0_300 Depth=1
	movl	%edx, %ebp
	jmp	.LBB0_326
.LBB0_700:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.701:
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_702
# %bb.716:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.717:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movss	.LCPI0_4(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	movss	.LCPI0_5(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	movq	-120(%rsp), %rsi                # 8-byte Reload
	jmp	.LBB0_718
.LBB0_744:                              #   in Loop: Header=BB0_718 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rdx
	movl	(%rdi,%rdx,4), %edx
	movl	%edx, (%rsi,%r11)
.LBB0_745:                              #   in Loop: Header=BB0_718 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_718:                              # =>This Inner Loop Header: Depth=1
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movzbl	-5(%rdx,%r11), %edx
	xorps	%xmm0, %xmm0
	cvtsi2ss	%edx, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r14d
	movl	%r14d, %edx
	cmpl	%eax, %r14d
	jge	.LBB0_719
# %bb.720:                              #   in Loop: Header=BB0_718 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	jns	.LBB0_721
.LBB0_722:                              #   in Loop: Header=BB0_718 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jge	.LBB0_723
.LBB0_724:                              #   in Loop: Header=BB0_718 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_726
.LBB0_725:                              #   in Loop: Header=BB0_718 Depth=1
	movl	%edx, %ebp
.LBB0_726:                              #   in Loop: Header=BB0_718 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rdx
	movl	(%rdi,%rdx,4), %edx
	movl	%edx, -8(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_745
# %bb.727:                              #   in Loop: Header=BB0_718 Depth=1
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movzbl	-1(%rdx,%r11), %edx
	xorps	%xmm0, %xmm0
	cvtsi2ss	%edx, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r14d
	leal	1(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_728
# %bb.729:                              #   in Loop: Header=BB0_718 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jge	.LBB0_730
.LBB0_731:                              #   in Loop: Header=BB0_718 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jge	.LBB0_732
.LBB0_733:                              #   in Loop: Header=BB0_718 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_735
.LBB0_734:                              #   in Loop: Header=BB0_718 Depth=1
	movl	%edx, %ebp
.LBB0_735:                              #   in Loop: Header=BB0_718 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rdx
	movl	(%rdi,%rdx,4), %edx
	movl	%edx, -4(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_745
# %bb.736:                              #   in Loop: Header=BB0_718 Depth=1
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movzbl	3(%rdx,%r11), %edx
	xorps	%xmm0, %xmm0
	cvtsi2ss	%edx, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r14d
	leal	2(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_737
# %bb.738:                              #   in Loop: Header=BB0_718 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jge	.LBB0_739
.LBB0_740:                              #   in Loop: Header=BB0_718 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jge	.LBB0_741
.LBB0_742:                              #   in Loop: Header=BB0_718 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_744
	jmp	.LBB0_743
.LBB0_719:                              #   in Loop: Header=BB0_718 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	js	.LBB0_722
.LBB0_721:                              #   in Loop: Header=BB0_718 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jl	.LBB0_724
.LBB0_723:                              #   in Loop: Header=BB0_718 Depth=1
	movl	%r9d, %edx
	testl	%r14d, %r14d
	jns	.LBB0_725
	jmp	.LBB0_726
.LBB0_728:                              #   in Loop: Header=BB0_718 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jl	.LBB0_731
.LBB0_730:                              #   in Loop: Header=BB0_718 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jl	.LBB0_733
.LBB0_732:                              #   in Loop: Header=BB0_718 Depth=1
	movl	%r9d, %edx
	testl	%r14d, %r14d
	jns	.LBB0_734
	jmp	.LBB0_735
.LBB0_737:                              #   in Loop: Header=BB0_718 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jl	.LBB0_740
.LBB0_739:                              #   in Loop: Header=BB0_718 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jl	.LBB0_742
.LBB0_741:                              #   in Loop: Header=BB0_718 Depth=1
	movl	%r9d, %edx
	testl	%r14d, %r14d
	js	.LBB0_744
.LBB0_743:                              #   in Loop: Header=BB0_718 Depth=1
	movl	%edx, %ebp
	jmp	.LBB0_744
.LBB0_142:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.143:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	leal	-1(%rcx), %r14d
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_144
# %bb.158:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.159:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movaps	.LCPI0_7(%rip), %xmm1           # xmm1 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm2           # xmm2 = [-5.0E-1,-5.0E-1,u,u]
	movl	$1, %eax
	movd	%eax, %xmm3
	movl	$2, %eax
	movd	%eax, %xmm4
	movq	-120(%rsp), %rsi                # 8-byte Reload
	jmp	.LBB0_160
.LBB0_186:                              #   in Loop: Header=BB0_160 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r11)
.LBB0_187:                              #   in Loop: Header=BB0_160 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_160:                              # =>This Inner Loop Header: Depth=1
	movd	%ebx, %xmm5
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-8(%rax,%r11), %eax
	movl	%eax, %edx
	shrl	$24, %edx
	shrl	$16, %eax
	movzbl	%al, %eax
	movd	%edx, %xmm0
	movd	%eax, %xmm6
	punpckldq	%xmm0, %xmm6            # xmm6 = xmm6[0],xmm0[0],xmm6[1],xmm0[1]
	cvtdq2ps	%xmm6, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm6
	paddd	%xmm5, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_162
# %bb.161:                              #   in Loop: Header=BB0_160 Depth=1
	movl	%r14d, %r12d
.LBB0_162:                              #   in Loop: Header=BB0_160 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_163
# %bb.164:                              #   in Loop: Header=BB0_160 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_165
.LBB0_166:                              #   in Loop: Header=BB0_160 Depth=1
	testb	$1, %r15b
	jne	.LBB0_168
.LBB0_167:                              #   in Loop: Header=BB0_160 Depth=1
	movl	%edx, %ebp
.LBB0_168:                              #   in Loop: Header=BB0_160 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -8(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_187
# %bb.169:                              #   in Loop: Header=BB0_160 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-4(%rax,%r11), %eax
	movl	%eax, %edx
	shrl	$24, %edx
	shrl	$16, %eax
	movzbl	%al, %eax
	movd	%edx, %xmm0
	movd	%eax, %xmm6
	punpckldq	%xmm0, %xmm6            # xmm6 = xmm6[0],xmm0[0],xmm6[1],xmm0[1]
	cvtdq2ps	%xmm6, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm3, %xmm6
	punpcklqdq	%xmm5, %xmm6            # xmm6 = xmm6[0],xmm5[0]
	shufps	$226, %xmm5, %xmm6              # xmm6 = xmm6[2,0],xmm5[2,3]
	paddd	%xmm0, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_171
# %bb.170:                              #   in Loop: Header=BB0_160 Depth=1
	movl	%r14d, %r12d
.LBB0_171:                              #   in Loop: Header=BB0_160 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_172
# %bb.173:                              #   in Loop: Header=BB0_160 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_174
.LBB0_175:                              #   in Loop: Header=BB0_160 Depth=1
	testb	$1, %r15b
	jne	.LBB0_177
.LBB0_176:                              #   in Loop: Header=BB0_160 Depth=1
	movl	%edx, %ebp
.LBB0_177:                              #   in Loop: Header=BB0_160 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -4(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_187
# %bb.178:                              #   in Loop: Header=BB0_160 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r11), %eax
	movl	%eax, %edx
	shrl	$24, %edx
	shrl	$16, %eax
	movzbl	%al, %eax
	movd	%edx, %xmm0
	movd	%eax, %xmm6
	punpckldq	%xmm0, %xmm6            # xmm6 = xmm6[0],xmm0[0],xmm6[1],xmm0[1]
	cvtdq2ps	%xmm6, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm4, %xmm6
	punpcklqdq	%xmm5, %xmm6            # xmm6 = xmm6[0],xmm5[0]
	shufps	$226, %xmm5, %xmm6              # xmm6 = xmm6[2,0],xmm5[2,3]
	paddd	%xmm0, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_180
# %bb.179:                              #   in Loop: Header=BB0_160 Depth=1
	movl	%r14d, %r12d
.LBB0_180:                              #   in Loop: Header=BB0_160 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_181
# %bb.182:                              #   in Loop: Header=BB0_160 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_183
.LBB0_184:                              #   in Loop: Header=BB0_160 Depth=1
	testb	$1, %r15b
	jne	.LBB0_186
	jmp	.LBB0_185
.LBB0_163:                              #   in Loop: Header=BB0_160 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_166
.LBB0_165:                              #   in Loop: Header=BB0_160 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_167
	jmp	.LBB0_168
.LBB0_172:                              #   in Loop: Header=BB0_160 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_175
.LBB0_174:                              #   in Loop: Header=BB0_160 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_176
	jmp	.LBB0_177
.LBB0_181:                              #   in Loop: Header=BB0_160 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_184
.LBB0_183:                              #   in Loop: Header=BB0_160 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	jne	.LBB0_186
.LBB0_185:                              #   in Loop: Header=BB0_160 Depth=1
	movl	%edx, %ebp
	jmp	.LBB0_186
.LBB0_608:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.609:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	leal	-1(%rcx), %r14d
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_610
# %bb.624:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.625:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movaps	.LCPI0_7(%rip), %xmm1           # xmm1 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm2           # xmm2 = [-5.0E-1,-5.0E-1,u,u]
	movl	$1, %eax
	movd	%eax, %xmm3
	movl	$2, %eax
	movd	%eax, %xmm4
	movq	-120(%rsp), %rsi                # 8-byte Reload
	jmp	.LBB0_626
.LBB0_652:                              #   in Loop: Header=BB0_626 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r11)
.LBB0_653:                              #   in Loop: Header=BB0_626 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_626:                              # =>This Inner Loop Header: Depth=1
	movd	%ebx, %xmm5
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-8(%rax,%r11), %eax
	movzbl	%ah, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm6, %xmm0            # xmm0 = xmm0[0],xmm6[0],xmm0[1],xmm6[1]
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm6
	paddd	%xmm5, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_628
# %bb.627:                              #   in Loop: Header=BB0_626 Depth=1
	movl	%r14d, %r12d
.LBB0_628:                              #   in Loop: Header=BB0_626 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_629
# %bb.630:                              #   in Loop: Header=BB0_626 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_631
.LBB0_632:                              #   in Loop: Header=BB0_626 Depth=1
	testb	$1, %r15b
	jne	.LBB0_634
.LBB0_633:                              #   in Loop: Header=BB0_626 Depth=1
	movl	%edx, %ebp
.LBB0_634:                              #   in Loop: Header=BB0_626 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -8(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_653
# %bb.635:                              #   in Loop: Header=BB0_626 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-4(%rax,%r11), %eax
	movzbl	%ah, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm6, %xmm0            # xmm0 = xmm0[0],xmm6[0],xmm0[1],xmm6[1]
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm3, %xmm6
	punpcklqdq	%xmm5, %xmm6            # xmm6 = xmm6[0],xmm5[0]
	shufps	$226, %xmm5, %xmm6              # xmm6 = xmm6[2,0],xmm5[2,3]
	paddd	%xmm0, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_637
# %bb.636:                              #   in Loop: Header=BB0_626 Depth=1
	movl	%r14d, %r12d
.LBB0_637:                              #   in Loop: Header=BB0_626 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_638
# %bb.639:                              #   in Loop: Header=BB0_626 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_640
.LBB0_641:                              #   in Loop: Header=BB0_626 Depth=1
	testb	$1, %r15b
	jne	.LBB0_643
.LBB0_642:                              #   in Loop: Header=BB0_626 Depth=1
	movl	%edx, %ebp
.LBB0_643:                              #   in Loop: Header=BB0_626 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -4(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_653
# %bb.644:                              #   in Loop: Header=BB0_626 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r11), %eax
	movzbl	%ah, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm6, %xmm0            # xmm0 = xmm0[0],xmm6[0],xmm0[1],xmm6[1]
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm4, %xmm6
	punpcklqdq	%xmm5, %xmm6            # xmm6 = xmm6[0],xmm5[0]
	shufps	$226, %xmm5, %xmm6              # xmm6 = xmm6[2,0],xmm5[2,3]
	paddd	%xmm0, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_646
# %bb.645:                              #   in Loop: Header=BB0_626 Depth=1
	movl	%r14d, %r12d
.LBB0_646:                              #   in Loop: Header=BB0_626 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_647
# %bb.648:                              #   in Loop: Header=BB0_626 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_649
.LBB0_650:                              #   in Loop: Header=BB0_626 Depth=1
	testb	$1, %r15b
	jne	.LBB0_652
	jmp	.LBB0_651
.LBB0_629:                              #   in Loop: Header=BB0_626 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_632
.LBB0_631:                              #   in Loop: Header=BB0_626 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_633
	jmp	.LBB0_634
.LBB0_638:                              #   in Loop: Header=BB0_626 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_641
.LBB0_640:                              #   in Loop: Header=BB0_626 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_642
	jmp	.LBB0_643
.LBB0_647:                              #   in Loop: Header=BB0_626 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_650
.LBB0_649:                              #   in Loop: Header=BB0_626 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	jne	.LBB0_652
.LBB0_651:                              #   in Loop: Header=BB0_626 Depth=1
	movl	%edx, %ebp
	jmp	.LBB0_652
.LBB0_328:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.329:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	leal	-1(%rcx), %r14d
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_330
# %bb.344:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.345:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movaps	.LCPI0_7(%rip), %xmm1           # xmm1 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm2           # xmm2 = [-5.0E-1,-5.0E-1,u,u]
	movl	$1, %eax
	movd	%eax, %xmm3
	movl	$2, %eax
	movd	%eax, %xmm4
	movq	-120(%rsp), %rsi                # 8-byte Reload
	jmp	.LBB0_346
.LBB0_372:                              #   in Loop: Header=BB0_346 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r11)
.LBB0_373:                              #   in Loop: Header=BB0_346 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_346:                              # =>This Inner Loop Header: Depth=1
	movd	%ebx, %xmm5
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-8(%rax,%r11), %eax
	movzbl	%ah, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm0, %xmm6            # xmm6 = xmm6[0],xmm0[0],xmm6[1],xmm0[1]
	cvtdq2ps	%xmm6, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm6
	paddd	%xmm5, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_348
# %bb.347:                              #   in Loop: Header=BB0_346 Depth=1
	movl	%r14d, %r12d
.LBB0_348:                              #   in Loop: Header=BB0_346 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_349
# %bb.350:                              #   in Loop: Header=BB0_346 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_351
.LBB0_352:                              #   in Loop: Header=BB0_346 Depth=1
	testb	$1, %r15b
	jne	.LBB0_354
.LBB0_353:                              #   in Loop: Header=BB0_346 Depth=1
	movl	%edx, %ebp
.LBB0_354:                              #   in Loop: Header=BB0_346 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -8(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_373
# %bb.355:                              #   in Loop: Header=BB0_346 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	-4(%rax,%r11), %eax
	movzbl	%ah, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm0, %xmm6            # xmm6 = xmm6[0],xmm0[0],xmm6[1],xmm0[1]
	cvtdq2ps	%xmm6, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm3, %xmm6
	punpcklqdq	%xmm5, %xmm6            # xmm6 = xmm6[0],xmm5[0]
	shufps	$226, %xmm5, %xmm6              # xmm6 = xmm6[2,0],xmm5[2,3]
	paddd	%xmm0, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_357
# %bb.356:                              #   in Loop: Header=BB0_346 Depth=1
	movl	%r14d, %r12d
.LBB0_357:                              #   in Loop: Header=BB0_346 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_358
# %bb.359:                              #   in Loop: Header=BB0_346 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_360
.LBB0_361:                              #   in Loop: Header=BB0_346 Depth=1
	testb	$1, %r15b
	jne	.LBB0_363
.LBB0_362:                              #   in Loop: Header=BB0_346 Depth=1
	movl	%edx, %ebp
.LBB0_363:                              #   in Loop: Header=BB0_346 Depth=1
	imull	%ecx, %ebp
	addl	%eax, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, -4(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_373
# %bb.364:                              #   in Loop: Header=BB0_346 Depth=1
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r11), %eax
	movzbl	%ah, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm6
	punpckldq	%xmm0, %xmm6            # xmm6 = xmm6[0],xmm0[0],xmm6[1],xmm0[1]
	cvtdq2ps	%xmm6, %xmm0
	divps	%xmm1, %xmm0
	addps	%xmm2, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm4, %xmm6
	punpcklqdq	%xmm5, %xmm6            # xmm6 = xmm6[0],xmm5[0]
	shufps	$226, %xmm5, %xmm6              # xmm6 = xmm6[2,0],xmm5[2,3]
	paddd	%xmm0, %xmm6
	pshufd	$85, %xmm6, %xmm0               # xmm0 = xmm6[1,1,1,1]
	movd	%xmm0, %r12d
	cmpl	%r14d, %r12d
	jl	.LBB0_366
# %bb.365:                              #   in Loop: Header=BB0_346 Depth=1
	movl	%r14d, %r12d
.LBB0_366:                              #   in Loop: Header=BB0_346 Depth=1
	pshufd	$80, %xmm6, %xmm0               # xmm0 = xmm6[0,0,1,1]
	movmskpd	%xmm0, %r15d
	xorl	%ebp, %ebp
	movl	$0, %eax
	testb	$2, %r15b
	je	.LBB0_367
# %bb.368:                              #   in Loop: Header=BB0_346 Depth=1
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jge	.LBB0_369
.LBB0_370:                              #   in Loop: Header=BB0_346 Depth=1
	testb	$1, %r15b
	jne	.LBB0_372
	jmp	.LBB0_371
.LBB0_349:                              #   in Loop: Header=BB0_346 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_352
.LBB0_351:                              #   in Loop: Header=BB0_346 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_353
	jmp	.LBB0_354
.LBB0_358:                              #   in Loop: Header=BB0_346 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_361
.LBB0_360:                              #   in Loop: Header=BB0_346 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	je	.LBB0_362
	jmp	.LBB0_363
.LBB0_367:                              #   in Loop: Header=BB0_346 Depth=1
	movl	%r12d, %eax
	movd	%xmm6, %edx
	cmpl	%r9d, %edx
	jl	.LBB0_370
.LBB0_369:                              #   in Loop: Header=BB0_346 Depth=1
	movl	%r9d, %edx
	testb	$1, %r15b
	jne	.LBB0_372
.LBB0_371:                              #   in Loop: Header=BB0_346 Depth=1
	movl	%edx, %ebp
	jmp	.LBB0_372
.LBB0_50:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.51:
	leal	-1(%rcx), %r11d
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_52
# %bb.66:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.67:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %eax
	xorl	%r15d, %r15d
	movss	.LCPI0_4(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	movss	.LCPI0_5(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_68
.LBB0_94:                               #   in Loop: Header=BB0_68 Depth=1
	imull	%ecx, %ebp
	addl	%r14d, %ebp
	movslq	%ebp, %rdx
	movl	(%rdi,%rdx,4), %edx
	movq	-120(%rsp), %rsi                # 8-byte Reload
	movl	%edx, (%rsi,%rax)
.LBB0_95:                               #   in Loop: Header=BB0_68 Depth=1
	incq	%r15
	addq	%r10, %rax
	cmpq	%r15, %r8
	je	.LBB0_746
.LBB0_68:                               # =>This Inner Loop Header: Depth=1
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movl	-8(%rdx,%rax), %ebx
	movzbl	%bh, %edx
	xorps	%xmm3, %xmm3
	cvtsi2ss	%edx, %xmm3
	divss	%xmm1, %xmm3
	addss	%xmm2, %xmm3
	mulss	%xmm12, %xmm3
	cvttss2si	%xmm3, %edx
	movl	%edx, %esi
	cmpl	%r11d, %edx
	jl	.LBB0_70
# %bb.69:                               #   in Loop: Header=BB0_68 Depth=1
	movl	%r11d, %esi
.LBB0_70:                               #   in Loop: Header=BB0_68 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r14d
	testl	%edx, %edx
	js	.LBB0_72
# %bb.71:                               #   in Loop: Header=BB0_68 Depth=1
	movl	%esi, %r14d
.LBB0_72:                               #   in Loop: Header=BB0_68 Depth=1
	shrl	$16, %ebx
	movzbl	%bl, %edx
	xorps	%xmm3, %xmm3
	cvtsi2ss	%edx, %xmm3
	divss	%xmm1, %xmm3
	addss	%xmm2, %xmm3
	mulss	%xmm12, %xmm3
	cvttss2si	%xmm3, %edx
	addl	%r15d, %edx
	movl	%edx, %esi
	cmpl	%r9d, %edx
	jl	.LBB0_74
# %bb.73:                               #   in Loop: Header=BB0_68 Depth=1
	movl	%r9d, %esi
.LBB0_74:                               #   in Loop: Header=BB0_68 Depth=1
	testl	%edx, %edx
	js	.LBB0_76
# %bb.75:                               #   in Loop: Header=BB0_68 Depth=1
	movl	%esi, %ebp
.LBB0_76:                               #   in Loop: Header=BB0_68 Depth=1
	imull	%ecx, %ebp
	addl	%r14d, %ebp
	movslq	%ebp, %rdx
	movl	(%rdi,%rdx,4), %edx
	movq	-120(%rsp), %rsi                # 8-byte Reload
	movl	%edx, -8(%rsi,%rax)
	cmpl	$1, %ecx
	je	.LBB0_95
# %bb.77:                               #   in Loop: Header=BB0_68 Depth=1
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movl	-4(%rdx,%rax), %ebx
	movzbl	%bh, %edx
	xorps	%xmm3, %xmm3
	cvtsi2ss	%edx, %xmm3
	divss	%xmm1, %xmm3
	addss	%xmm2, %xmm3
	mulss	%xmm12, %xmm3
	cvttss2si	%xmm3, %edx
	leal	1(%rdx), %r12d
	cmpl	%r11d, %r12d
	jl	.LBB0_79
# %bb.78:                               #   in Loop: Header=BB0_68 Depth=1
	movl	%r11d, %r12d
.LBB0_79:                               #   in Loop: Header=BB0_68 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r14d
	cmpl	$-1, %edx
	jl	.LBB0_81
# %bb.80:                               #   in Loop: Header=BB0_68 Depth=1
	movl	%r12d, %r14d
.LBB0_81:                               #   in Loop: Header=BB0_68 Depth=1
	shrl	$16, %ebx
	movzbl	%bl, %edx
	xorps	%xmm3, %xmm3
	cvtsi2ss	%edx, %xmm3
	divss	%xmm1, %xmm3
	addss	%xmm2, %xmm3
	mulss	%xmm12, %xmm3
	cvttss2si	%xmm3, %edx
	addl	%r15d, %edx
	movl	%edx, %esi
	cmpl	%r9d, %edx
	jl	.LBB0_83
# %bb.82:                               #   in Loop: Header=BB0_68 Depth=1
	movl	%r9d, %esi
.LBB0_83:                               #   in Loop: Header=BB0_68 Depth=1
	testl	%edx, %edx
	js	.LBB0_85
# %bb.84:                               #   in Loop: Header=BB0_68 Depth=1
	movl	%esi, %ebp
.LBB0_85:                               #   in Loop: Header=BB0_68 Depth=1
	imull	%ecx, %ebp
	addl	%r14d, %ebp
	movslq	%ebp, %rdx
	movl	(%rdi,%rdx,4), %edx
	movq	-120(%rsp), %rsi                # 8-byte Reload
	movl	%edx, -4(%rsi,%rax)
	cmpl	$2, %ecx
	je	.LBB0_95
# %bb.86:                               #   in Loop: Header=BB0_68 Depth=1
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movl	(%rdx,%rax), %ebx
	movzbl	%bh, %edx
	xorps	%xmm3, %xmm3
	cvtsi2ss	%edx, %xmm3
	divss	%xmm1, %xmm3
	addss	%xmm2, %xmm3
	mulss	%xmm12, %xmm3
	cvttss2si	%xmm3, %edx
	leal	2(%rdx), %r12d
	cmpl	%r11d, %r12d
	jl	.LBB0_88
# %bb.87:                               #   in Loop: Header=BB0_68 Depth=1
	movl	%r11d, %r12d
.LBB0_88:                               #   in Loop: Header=BB0_68 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r14d
	cmpl	$-2, %edx
	jl	.LBB0_90
# %bb.89:                               #   in Loop: Header=BB0_68 Depth=1
	movl	%r12d, %r14d
.LBB0_90:                               #   in Loop: Header=BB0_68 Depth=1
	shrl	$16, %ebx
	movzbl	%bl, %edx
	xorps	%xmm3, %xmm3
	cvtsi2ss	%edx, %xmm3
	divss	%xmm1, %xmm3
	addss	%xmm2, %xmm3
	mulss	%xmm12, %xmm3
	cvttss2si	%xmm3, %edx
	addl	%r15d, %edx
	movl	%edx, %esi
	cmpl	%r9d, %edx
	jl	.LBB0_92
# %bb.91:                               #   in Loop: Header=BB0_68 Depth=1
	movl	%r9d, %esi
.LBB0_92:                               #   in Loop: Header=BB0_68 Depth=1
	testl	%edx, %edx
	js	.LBB0_94
# %bb.93:                               #   in Loop: Header=BB0_68 Depth=1
	movl	%esi, %ebp
	jmp	.LBB0_94
.LBB0_236:
	testl	%r8d, %r8d
	jle	.LBB0_746
# %bb.237:
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$4, %ecx
	jge	.LBB0_238
# %bb.252:
	testl	%ecx, %ecx
	jle	.LBB0_746
# %bb.253:
	movl	%ecx, %r10d
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$8, %r11d
	xorl	%ebx, %ebx
	movss	.LCPI0_4(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	movss	.LCPI0_5(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	movq	-120(%rsp), %rsi                # 8-byte Reload
	jmp	.LBB0_254
.LBB0_280:                              #   in Loop: Header=BB0_254 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rdx
	movl	(%rdi,%rdx,4), %edx
	movl	%edx, (%rsi,%r11)
.LBB0_281:                              #   in Loop: Header=BB0_254 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_746
.LBB0_254:                              # =>This Inner Loop Header: Depth=1
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movzbl	-7(%rdx,%r11), %edx
	xorps	%xmm0, %xmm0
	cvtsi2ss	%edx, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r14d
	movl	%r14d, %edx
	cmpl	%eax, %r14d
	jge	.LBB0_255
# %bb.256:                              #   in Loop: Header=BB0_254 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	jns	.LBB0_257
.LBB0_258:                              #   in Loop: Header=BB0_254 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jge	.LBB0_259
.LBB0_260:                              #   in Loop: Header=BB0_254 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_262
.LBB0_261:                              #   in Loop: Header=BB0_254 Depth=1
	movl	%edx, %ebp
.LBB0_262:                              #   in Loop: Header=BB0_254 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rdx
	movl	(%rdi,%rdx,4), %edx
	movl	%edx, -8(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_281
# %bb.263:                              #   in Loop: Header=BB0_254 Depth=1
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movzbl	-3(%rdx,%r11), %edx
	xorps	%xmm0, %xmm0
	cvtsi2ss	%edx, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r14d
	leal	1(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_264
# %bb.265:                              #   in Loop: Header=BB0_254 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jge	.LBB0_266
.LBB0_267:                              #   in Loop: Header=BB0_254 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jge	.LBB0_268
.LBB0_269:                              #   in Loop: Header=BB0_254 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_271
.LBB0_270:                              #   in Loop: Header=BB0_254 Depth=1
	movl	%edx, %ebp
.LBB0_271:                              #   in Loop: Header=BB0_254 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rdx
	movl	(%rdi,%rdx,4), %edx
	movl	%edx, -4(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_281
# %bb.272:                              #   in Loop: Header=BB0_254 Depth=1
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movzbl	1(%rdx,%r11), %edx
	xorps	%xmm0, %xmm0
	cvtsi2ss	%edx, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	mulss	%xmm12, %xmm0
	cvttss2si	%xmm0, %r14d
	leal	2(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_273
# %bb.274:                              #   in Loop: Header=BB0_254 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jge	.LBB0_275
.LBB0_276:                              #   in Loop: Header=BB0_254 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jge	.LBB0_277
.LBB0_278:                              #   in Loop: Header=BB0_254 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_280
	jmp	.LBB0_279
.LBB0_255:                              #   in Loop: Header=BB0_254 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	js	.LBB0_258
.LBB0_257:                              #   in Loop: Header=BB0_254 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jl	.LBB0_260
.LBB0_259:                              #   in Loop: Header=BB0_254 Depth=1
	movl	%r9d, %edx
	testl	%r14d, %r14d
	jns	.LBB0_261
	jmp	.LBB0_262
.LBB0_264:                              #   in Loop: Header=BB0_254 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jl	.LBB0_267
.LBB0_266:                              #   in Loop: Header=BB0_254 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jl	.LBB0_269
.LBB0_268:                              #   in Loop: Header=BB0_254 Depth=1
	movl	%r9d, %edx
	testl	%r14d, %r14d
	jns	.LBB0_270
	jmp	.LBB0_271
.LBB0_273:                              #   in Loop: Header=BB0_254 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jl	.LBB0_276
.LBB0_275:                              #   in Loop: Header=BB0_254 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %edx
	cmpl	%r9d, %r14d
	jl	.LBB0_278
.LBB0_277:                              #   in Loop: Header=BB0_254 Depth=1
	movl	%r9d, %edx
	testl	%r14d, %r14d
	js	.LBB0_280
.LBB0_279:                              #   in Loop: Header=BB0_254 Depth=1
	movl	%edx, %ebp
	jmp	.LBB0_280
.LBB0_470:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	movaps	%xmm12, -96(%rsp)               # 16-byte Spill
	movd	%eax, %xmm0
	pshufd	$0, %xmm0, %xmm2                # xmm2 = xmm0[0,0,0,0]
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm7                # xmm7 = xmm0[0,0,0,0]
	movl	%ecx, %r10d
	movl	%r8d, %edx
	movq	%rdx, -64(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rdx
	movq	%rdx, -80(%rsp)                 # 8-byte Spill
	movl	$16, %ebx
	xorl	%r14d, %r14d
	pxor	%xmm9, %xmm9
	movdqa	%xmm0, -112(%rsp)               # 16-byte Spill
	pshufd	$245, %xmm0, %xmm10             # xmm10 = xmm0[1,1,3,3]
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	-112(%rsp), %xmm8               # 16-byte Reload
	movdqa	.LCPI0_3(%rip), %xmm11          # xmm11 = [4,4,4,4]
	jmp	.LBB0_471
	.p2align	4, 0x90
.LBB0_483:                              #   in Loop: Header=BB0_471 Depth=1
	incq	%r14
	movq	-80(%rsp), %rdx                 # 8-byte Reload
	addq	%rdx, %r12
	addq	%rdx, %r15
	movq	-48(%rsp), %rbx                 # 8-byte Reload
	addq	%rdx, %rbx
	cmpq	-64(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_471:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_472 Depth 2
                                        #     Child Loop BB0_474 Depth 2
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm14               # xmm14 = xmm0[0,0,0,0]
	movq	%rbx, -48(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm15          # xmm15 = [0,1,2,3]
	movaps	.LCPI0_2(%rip), %xmm1           # xmm1 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movaps	-96(%rsp), %xmm4                # 16-byte Reload
	.p2align	4, 0x90
.LBB0_472:                              #   Parent Loop BB0_471 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movups	(%r15,%rbp,4), %xmm0
	andps	.LCPI0_6(%rip), %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	.LCPI0_1(%rip), %xmm0
	addps	%xmm1, %xmm0
	mulps	%xmm4, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm0, %xmm12
	paddd	%xmm15, %xmm12
	paddd	%xmm14, %xmm0
	movdqa	%xmm12, %xmm5
	pcmpgtd	%xmm9, %xmm5
	movdqa	%xmm0, %xmm6
	pcmpgtd	%xmm9, %xmm6
	pand	%xmm0, %xmm6
	pand	%xmm12, %xmm5
	movdqa	%xmm5, %xmm0
	pcmpgtd	%xmm2, %xmm0
	movdqa	%xmm2, %xmm12
	pand	%xmm0, %xmm12
	movdqa	%xmm6, %xmm13
	pcmpgtd	%xmm7, %xmm13
	movdqa	%xmm7, %xmm3
	pandn	%xmm5, %xmm0
	pand	%xmm13, %xmm3
	pandn	%xmm6, %xmm13
	por	%xmm3, %xmm13
	por	%xmm12, %xmm0
	pshufd	$245, %xmm13, %xmm3             # xmm3 = xmm13[1,1,3,3]
	pmuludq	%xmm8, %xmm13
	pmuludq	%xmm10, %xmm3
	pshufd	$232, %xmm13, %xmm5             # xmm5 = xmm13[0,2,2,3]
	pshufd	$232, %xmm3, %xmm3              # xmm3 = xmm3[0,2,2,3]
	punpckldq	%xmm3, %xmm5            # xmm5 = xmm5[0],xmm3[0],xmm5[1],xmm3[1]
	paddd	%xmm0, %xmm5
	movq	%rbx, %r13
	movd	%xmm5, %edx
	pshufd	$85, %xmm5, %xmm0               # xmm0 = xmm5[1,1,1,1]
	pshufd	$238, %xmm5, %xmm3              # xmm3 = xmm5[2,3,2,3]
	movd	%xmm0, %esi
	movd	%xmm3, %r11d
	pshufd	$255, %xmm5, %xmm0              # xmm0 = xmm5[3,3,3,3]
	movd	%xmm0, %ebx
	movss	(%rdi,%rbx,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%r11,4), %xmm3            # xmm3 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm5            # xmm5 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm6            # xmm6 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm3                    # xmm3 = xmm3[0],xmm0[0],xmm3[1],xmm0[1]
	unpcklps	%xmm6, %xmm5                    # xmm5 = xmm5[0],xmm6[0],xmm5[1],xmm6[1]
	movlhps	%xmm3, %xmm5                    # xmm5 = xmm5[0],xmm3[0]
	paddd	%xmm11, %xmm15
	movups	%xmm5, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	leaq	16(%r13), %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_472
# %bb.473:                              #   in Loop: Header=BB0_471 Depth=1
	cmpl	%ecx, %ebp
	movaps	-32(%rsp), %xmm3                # 16-byte Reload
	movss	.LCPI0_4(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	movss	.LCPI0_5(%rip), %xmm4           # xmm4 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jl	.LBB0_474
	jmp	.LBB0_483
	.p2align	4, 0x90
.LBB0_482:                              #   in Loop: Header=BB0_474 Depth=2
	imull	%ecx, %ebx
	addl	%r11d, %ebx
	movslq	%ebx, %rdx
	movl	(%rdi,%rdx,4), %edx
	movl	%edx, (%rsi,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_483
.LBB0_474:                              #   Parent Loop BB0_471 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movzbl	(%rdx,%r13), %edx
	xorps	%xmm0, %xmm0
	cvtsi2ss	%edx, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm4, %xmm0
	mulss	%xmm3, %xmm0
	cvttss2si	%xmm0, %r8d
	leal	(%r8,%rbp), %edx
	movl	%edx, %esi
	cmpl	%eax, %edx
	jge	.LBB0_475
# %bb.476:                              #   in Loop: Header=BB0_474 Depth=2
	xorl	%ebx, %ebx
	movl	$0, %r11d
	testl	%edx, %edx
	jns	.LBB0_477
.LBB0_478:                              #   in Loop: Header=BB0_474 Depth=2
	addl	%r14d, %r8d
	movl	%r8d, %edx
	cmpl	%r9d, %r8d
	jge	.LBB0_479
.LBB0_480:                              #   in Loop: Header=BB0_474 Depth=2
	testl	%r8d, %r8d
	movq	-120(%rsp), %rsi                # 8-byte Reload
	js	.LBB0_482
	jmp	.LBB0_481
	.p2align	4, 0x90
.LBB0_475:                              #   in Loop: Header=BB0_474 Depth=2
	movl	%eax, %esi
	xorl	%ebx, %ebx
	movl	$0, %r11d
	testl	%edx, %edx
	js	.LBB0_478
.LBB0_477:                              #   in Loop: Header=BB0_474 Depth=2
	movl	%esi, %r11d
	addl	%r14d, %r8d
	movl	%r8d, %edx
	cmpl	%r9d, %r8d
	jl	.LBB0_480
.LBB0_479:                              #   in Loop: Header=BB0_474 Depth=2
	movl	%r9d, %edx
	testl	%r8d, %r8d
	movq	-120(%rsp), %rsi                # 8-byte Reload
	js	.LBB0_482
.LBB0_481:                              #   in Loop: Header=BB0_474 Depth=2
	movl	%edx, %ebx
	jmp	.LBB0_482
.LBB0_516:
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm7                # xmm7 = xmm0[0,0,0,0]
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm10               # xmm10 = xmm0[0,0,0,0]
	movl	%ecx, %r10d
	movl	%r8d, %eax
	movq	%rax, -80(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rax
	movq	%rax, -112(%rsp)                # 8-byte Spill
	movl	$16, %ebx
	xorl	%edx, %edx
	movdqa	%xmm0, -96(%rsp)                # 16-byte Spill
	pshufd	$245, %xmm0, %xmm0              # xmm0 = xmm0[1,1,3,3]
	movdqa	%xmm0, -16(%rsp)                # 16-byte Spill
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	-96(%rsp), %xmm5                # 16-byte Reload
	movaps	.LCPI0_1(%rip), %xmm6           # xmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	movaps	.LCPI0_2(%rip), %xmm8           # xmm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	pxor	%xmm9, %xmm9
	movdqa	-16(%rsp), %xmm13               # 16-byte Reload
	jmp	.LBB0_517
	.p2align	4, 0x90
.LBB0_529:                              #   in Loop: Header=BB0_517 Depth=1
	movq	-32(%rsp), %rdx                 # 8-byte Reload
	incq	%rdx
	movq	-112(%rsp), %rax                # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	movq	-48(%rsp), %rbx                 # 8-byte Reload
	addq	%rax, %rbx
	cmpq	-80(%rsp), %rdx                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_517:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_518 Depth 2
                                        #     Child Loop BB0_520 Depth 2
	movq	%rdx, -32(%rsp)                 # 8-byte Spill
	movd	%edx, %xmm0
	movdqa	%xmm0, -64(%rsp)                # 16-byte Spill
	pshufd	$0, %xmm0, %xmm14               # xmm14 = xmm0[0,0,0,0]
	movq	%rbx, -48(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm15          # xmm15 = [0,1,2,3]
	.p2align	4, 0x90
.LBB0_518:                              #   Parent Loop BB0_517 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm4
	movdqa	%xmm4, %xmm0
	psrld	$24, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm6, %xmm0
	addps	%xmm8, %xmm0
	pand	.LCPI0_6(%rip), %xmm4
	cvtdq2ps	%xmm4, %xmm4
	divps	%xmm6, %xmm4
	mulps	%xmm12, %xmm0
	addps	%xmm8, %xmm4
	mulps	%xmm12, %xmm4
	cvttps2dq	%xmm4, %xmm4
	cvttps2dq	%xmm0, %xmm11
	paddd	%xmm14, %xmm4
	paddd	%xmm15, %xmm11
	movdqa	%xmm11, %xmm0
	pcmpgtd	%xmm9, %xmm0
	movaps	%xmm12, %xmm3
	movdqa	%xmm4, %xmm12
	pcmpgtd	%xmm9, %xmm12
	pand	%xmm4, %xmm12
	pand	%xmm11, %xmm0
	movdqa	%xmm0, %xmm11
	pcmpgtd	%xmm7, %xmm11
	movdqa	%xmm7, %xmm1
	pand	%xmm11, %xmm1
	movdqa	%xmm12, %xmm4
	pcmpgtd	%xmm10, %xmm4
	movdqa	%xmm10, %xmm2
	pandn	%xmm0, %xmm11
	pand	%xmm4, %xmm2
	pandn	%xmm12, %xmm4
	movaps	%xmm3, %xmm12
	por	%xmm2, %xmm4
	por	%xmm1, %xmm11
	pshufd	$245, %xmm4, %xmm0              # xmm0 = xmm4[1,1,3,3]
	pmuludq	%xmm5, %xmm4
	pmuludq	%xmm13, %xmm0
	pshufd	$232, %xmm4, %xmm1              # xmm1 = xmm4[0,2,2,3]
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	punpckldq	%xmm0, %xmm1            # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	paddd	%xmm11, %xmm1
	movq	%rbx, %r13
	movd	%xmm1, %eax
	pshufd	$85, %xmm1, %xmm0               # xmm0 = xmm1[1,1,1,1]
	pshufd	$238, %xmm1, %xmm2              # xmm2 = xmm1[2,3,2,3]
	movd	%xmm0, %edx
	movd	%xmm2, %esi
	pshufd	$255, %xmm1, %xmm0              # xmm0 = xmm1[3,3,3,3]
	movd	%xmm0, %r11d
	movss	(%rdi,%r11,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm1            # xmm1 = mem[0],zero,zero,zero
	movss	(%rdi,%rax,4), %xmm2            # xmm2 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm4            # xmm4 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm1                    # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	unpcklps	%xmm4, %xmm2                    # xmm2 = xmm2[0],xmm4[0],xmm2[1],xmm4[1]
	unpcklpd	%xmm1, %xmm2                    # xmm2 = xmm2[0],xmm1[0]
	paddd	.LCPI0_3(%rip), %xmm15
	movupd	%xmm2, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	addq	$16, %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_518
# %bb.519:                              #   in Loop: Header=BB0_517 Depth=1
	cmpl	%ecx, %ebp
	movq	-120(%rsp), %rsi                # 8-byte Reload
	movaps	.LCPI0_7(%rip), %xmm2           # xmm2 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm3           # xmm3 = [-5.0E-1,-5.0E-1,u,u]
	movdqa	-64(%rsp), %xmm4                # 16-byte Reload
	jl	.LBB0_520
	jmp	.LBB0_529
	.p2align	4, 0x90
.LBB0_528:                              #   in Loop: Header=BB0_520 Depth=2
	imull	%ecx, %r8d
	addl	%ebx, %r8d
	movslq	%r8d, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_529
.LBB0_520:                              #   Parent Loop BB0_517 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r13), %eax
	movzbl	%al, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm1
	punpckldq	%xmm0, %xmm1            # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	cvtdq2ps	%xmm1, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movd	%ebp, %xmm14
	punpcklqdq	%xmm4, %xmm14           # xmm14 = xmm14[0],xmm4[0]
	shufps	$226, %xmm4, %xmm14             # xmm14 = xmm14[2,0],xmm4[2,3]
	paddd	%xmm0, %xmm14
	pshufd	$85, %xmm14, %xmm0              # xmm0 = xmm14[1,1,1,1]
	movd	%xmm0, %eax
	cmpl	%r14d, %eax
	jl	.LBB0_522
# %bb.521:                              #   in Loop: Header=BB0_520 Depth=2
	movl	%r14d, %eax
.LBB0_522:                              #   in Loop: Header=BB0_520 Depth=2
	pshufd	$80, %xmm14, %xmm0              # xmm0 = xmm14[0,0,1,1]
	movmskpd	%xmm0, %r11d
	xorl	%r8d, %r8d
	movl	$0, %ebx
	testb	$2, %r11b
	je	.LBB0_523
# %bb.524:                              #   in Loop: Header=BB0_520 Depth=2
	movd	%xmm14, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_525
.LBB0_526:                              #   in Loop: Header=BB0_520 Depth=2
	testb	$1, %r11b
	jne	.LBB0_528
	jmp	.LBB0_527
	.p2align	4, 0x90
.LBB0_523:                              #   in Loop: Header=BB0_520 Depth=2
	movl	%eax, %ebx
	movd	%xmm14, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_526
.LBB0_525:                              #   in Loop: Header=BB0_520 Depth=2
	movl	%r9d, %eax
	testb	$1, %r11b
	jne	.LBB0_528
.LBB0_527:                              #   in Loop: Header=BB0_520 Depth=2
	movl	%eax, %r8d
	jmp	.LBB0_528
.LBB0_656:
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm5                # xmm5 = xmm0[0,0,0,0]
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm10               # xmm10 = xmm0[0,0,0,0]
	movl	%ecx, %r10d
	movl	%r8d, %eax
	movq	%rax, -80(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rax
	movq	%rax, -112(%rsp)                # 8-byte Spill
	movl	$16, %ebx
	xorl	%edx, %edx
	movdqa	%xmm0, -96(%rsp)                # 16-byte Spill
	pshufd	$245, %xmm0, %xmm0              # xmm0 = xmm0[1,1,3,3]
	movdqa	%xmm0, -16(%rsp)                # 16-byte Spill
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	-96(%rsp), %xmm6                # 16-byte Reload
	movaps	.LCPI0_1(%rip), %xmm8           # xmm8 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	movaps	.LCPI0_2(%rip), %xmm9           # xmm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	pxor	%xmm7, %xmm7
	movdqa	-16(%rsp), %xmm13               # 16-byte Reload
	jmp	.LBB0_657
	.p2align	4, 0x90
.LBB0_669:                              #   in Loop: Header=BB0_657 Depth=1
	movq	-32(%rsp), %rdx                 # 8-byte Reload
	incq	%rdx
	movq	-112(%rsp), %rax                # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	movq	-48(%rsp), %rbx                 # 8-byte Reload
	addq	%rax, %rbx
	cmpq	-80(%rsp), %rdx                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_657:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_658 Depth 2
                                        #     Child Loop BB0_660 Depth 2
	movq	%rdx, -32(%rsp)                 # 8-byte Spill
	movd	%edx, %xmm0
	movdqa	%xmm0, -64(%rsp)                # 16-byte Spill
	pshufd	$0, %xmm0, %xmm14               # xmm14 = xmm0[0,0,0,0]
	movq	%rbx, -48(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm15          # xmm15 = [0,1,2,3]
	.p2align	4, 0x90
.LBB0_658:                              #   Parent Loop BB0_657 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm0
	movdqa	%xmm0, %xmm4
	psrld	$24, %xmm4
	pand	.LCPI0_6(%rip), %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm8, %xmm0
	addps	%xmm9, %xmm0
	cvtdq2ps	%xmm4, %xmm4
	divps	%xmm8, %xmm4
	mulps	%xmm12, %xmm0
	addps	%xmm9, %xmm4
	mulps	%xmm12, %xmm4
	cvttps2dq	%xmm4, %xmm4
	cvttps2dq	%xmm0, %xmm11
	paddd	%xmm14, %xmm4
	paddd	%xmm15, %xmm11
	movdqa	%xmm11, %xmm0
	pcmpgtd	%xmm7, %xmm0
	movaps	%xmm12, %xmm3
	movdqa	%xmm4, %xmm12
	pcmpgtd	%xmm7, %xmm12
	pand	%xmm4, %xmm12
	pand	%xmm11, %xmm0
	movdqa	%xmm0, %xmm11
	pcmpgtd	%xmm5, %xmm11
	movdqa	%xmm5, %xmm1
	pand	%xmm11, %xmm1
	movdqa	%xmm12, %xmm4
	pcmpgtd	%xmm10, %xmm4
	movdqa	%xmm10, %xmm2
	pandn	%xmm0, %xmm11
	pand	%xmm4, %xmm2
	pandn	%xmm12, %xmm4
	movaps	%xmm3, %xmm12
	por	%xmm2, %xmm4
	por	%xmm1, %xmm11
	pshufd	$245, %xmm4, %xmm0              # xmm0 = xmm4[1,1,3,3]
	pmuludq	%xmm6, %xmm4
	pmuludq	%xmm13, %xmm0
	pshufd	$232, %xmm4, %xmm1              # xmm1 = xmm4[0,2,2,3]
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	punpckldq	%xmm0, %xmm1            # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	paddd	%xmm11, %xmm1
	movq	%rbx, %r13
	movd	%xmm1, %eax
	pshufd	$85, %xmm1, %xmm0               # xmm0 = xmm1[1,1,1,1]
	pshufd	$238, %xmm1, %xmm2              # xmm2 = xmm1[2,3,2,3]
	movd	%xmm0, %edx
	movd	%xmm2, %esi
	pshufd	$255, %xmm1, %xmm0              # xmm0 = xmm1[3,3,3,3]
	movd	%xmm0, %r11d
	movss	(%rdi,%r11,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm1            # xmm1 = mem[0],zero,zero,zero
	movss	(%rdi,%rax,4), %xmm2            # xmm2 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm4            # xmm4 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm1                    # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	unpcklps	%xmm4, %xmm2                    # xmm2 = xmm2[0],xmm4[0],xmm2[1],xmm4[1]
	unpcklpd	%xmm1, %xmm2                    # xmm2 = xmm2[0],xmm1[0]
	paddd	.LCPI0_3(%rip), %xmm15
	movupd	%xmm2, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	addq	$16, %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_658
# %bb.659:                              #   in Loop: Header=BB0_657 Depth=1
	cmpl	%ecx, %ebp
	movq	-120(%rsp), %rsi                # 8-byte Reload
	movaps	.LCPI0_7(%rip), %xmm2           # xmm2 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm3           # xmm3 = [-5.0E-1,-5.0E-1,u,u]
	movdqa	-64(%rsp), %xmm4                # 16-byte Reload
	jl	.LBB0_660
	jmp	.LBB0_669
	.p2align	4, 0x90
.LBB0_668:                              #   in Loop: Header=BB0_660 Depth=2
	imull	%ecx, %r8d
	addl	%ebx, %r8d
	movslq	%r8d, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_669
.LBB0_660:                              #   Parent Loop BB0_657 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r13), %eax
	movzbl	%al, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm1
	punpckldq	%xmm1, %xmm0            # xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1]
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movd	%ebp, %xmm14
	punpcklqdq	%xmm4, %xmm14           # xmm14 = xmm14[0],xmm4[0]
	shufps	$226, %xmm4, %xmm14             # xmm14 = xmm14[2,0],xmm4[2,3]
	paddd	%xmm0, %xmm14
	pshufd	$85, %xmm14, %xmm0              # xmm0 = xmm14[1,1,1,1]
	movd	%xmm0, %eax
	cmpl	%r14d, %eax
	jl	.LBB0_662
# %bb.661:                              #   in Loop: Header=BB0_660 Depth=2
	movl	%r14d, %eax
.LBB0_662:                              #   in Loop: Header=BB0_660 Depth=2
	pshufd	$80, %xmm14, %xmm0              # xmm0 = xmm14[0,0,1,1]
	movmskpd	%xmm0, %r11d
	xorl	%r8d, %r8d
	movl	$0, %ebx
	testb	$2, %r11b
	je	.LBB0_663
# %bb.664:                              #   in Loop: Header=BB0_660 Depth=2
	movd	%xmm14, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_665
.LBB0_666:                              #   in Loop: Header=BB0_660 Depth=2
	testb	$1, %r11b
	jne	.LBB0_668
	jmp	.LBB0_667
	.p2align	4, 0x90
.LBB0_663:                              #   in Loop: Header=BB0_660 Depth=2
	movl	%eax, %ebx
	movd	%xmm14, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_666
.LBB0_665:                              #   in Loop: Header=BB0_660 Depth=2
	movl	%r9d, %eax
	testb	$1, %r11b
	jne	.LBB0_668
.LBB0_667:                              #   in Loop: Header=BB0_660 Depth=2
	movl	%eax, %r8d
	jmp	.LBB0_668
.LBB0_378:
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movdqa	%xmm0, 32(%rsp)                 # 16-byte Spill
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movdqa	%xmm0, 16(%rsp)                 # 16-byte Spill
	movl	%ecx, %r10d
	movl	%r8d, %eax
	movq	%rax, -96(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rax
	movq	%rax, -16(%rsp)                 # 8-byte Spill
	movl	$16, %ebx
	xorl	%edx, %edx
	movdqa	%xmm0, -112(%rsp)               # 16-byte Spill
	pshufd	$245, %xmm0, %xmm0              # xmm0 = xmm0[1,1,3,3]
	movdqa	%xmm0, (%rsp)                   # 16-byte Spill
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	.LCPI0_6(%rip), %xmm7           # xmm7 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	movaps	.LCPI0_1(%rip), %xmm8           # xmm8 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	movaps	.LCPI0_2(%rip), %xmm9           # xmm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	pxor	%xmm14, %xmm14
	movdqa	(%rsp), %xmm10                  # 16-byte Reload
	movdqa	16(%rsp), %xmm15                # 16-byte Reload
	jmp	.LBB0_379
	.p2align	4, 0x90
.LBB0_391:                              #   in Loop: Header=BB0_379 Depth=1
	movq	-64(%rsp), %rdx                 # 8-byte Reload
	incq	%rdx
	movq	-16(%rsp), %rax                 # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	movq	-32(%rsp), %rbx                 # 8-byte Reload
	addq	%rax, %rbx
	cmpq	-96(%rsp), %rdx                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_379:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_380 Depth 2
                                        #     Child Loop BB0_382 Depth 2
	movq	%rdx, -64(%rsp)                 # 8-byte Spill
	movd	%edx, %xmm0
	movdqa	%xmm0, -80(%rsp)                # 16-byte Spill
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movdqa	%xmm0, -48(%rsp)                # 16-byte Spill
	movq	%rbx, -32(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm4           # xmm4 = [0,1,2,3]
	movdqa	-112(%rsp), %xmm6               # 16-byte Reload
	movdqa	32(%rsp), %xmm3                 # 16-byte Reload
	.p2align	4, 0x90
.LBB0_380:                              #   Parent Loop BB0_379 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm11
	movdqa	%xmm11, %xmm0
	psrld	$16, %xmm0
	pand	%xmm7, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm8, %xmm0
	addps	%xmm9, %xmm0
	pand	%xmm7, %xmm11
	cvtdq2ps	%xmm11, %xmm11
	divps	%xmm8, %xmm11
	mulps	%xmm12, %xmm0
	addps	%xmm9, %xmm11
	mulps	%xmm12, %xmm11
	cvttps2dq	%xmm11, %xmm11
	movaps	%xmm12, %xmm5
	cvttps2dq	%xmm0, %xmm12
	paddd	-48(%rsp), %xmm11               # 16-byte Folded Reload
	paddd	%xmm4, %xmm12
	movdqa	%xmm12, %xmm0
	pcmpgtd	%xmm14, %xmm0
	movdqa	%xmm11, %xmm13
	pcmpgtd	%xmm14, %xmm13
	pand	%xmm11, %xmm13
	pand	%xmm12, %xmm0
	movdqa	%xmm0, %xmm12
	pcmpgtd	%xmm3, %xmm12
	movdqa	%xmm3, %xmm1
	pand	%xmm12, %xmm1
	movdqa	%xmm13, %xmm11
	pcmpgtd	%xmm15, %xmm11
	movdqa	%xmm15, %xmm2
	pandn	%xmm0, %xmm12
	pand	%xmm11, %xmm2
	pandn	%xmm13, %xmm11
	por	%xmm2, %xmm11
	por	%xmm1, %xmm12
	pshufd	$245, %xmm11, %xmm0             # xmm0 = xmm11[1,1,3,3]
	pmuludq	%xmm6, %xmm11
	pmuludq	%xmm10, %xmm0
	pshufd	$232, %xmm11, %xmm1             # xmm1 = xmm11[0,2,2,3]
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	punpckldq	%xmm0, %xmm1            # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	paddd	%xmm12, %xmm1
	movaps	%xmm5, %xmm12
	movq	%rbx, %r13
	movd	%xmm1, %eax
	pshufd	$85, %xmm1, %xmm0               # xmm0 = xmm1[1,1,1,1]
	pshufd	$238, %xmm1, %xmm2              # xmm2 = xmm1[2,3,2,3]
	movd	%xmm0, %edx
	movd	%xmm2, %esi
	pshufd	$255, %xmm1, %xmm0              # xmm0 = xmm1[3,3,3,3]
	movd	%xmm0, %r11d
	movss	(%rdi,%r11,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm1            # xmm1 = mem[0],zero,zero,zero
	movss	(%rdi,%rax,4), %xmm2            # xmm2 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm11           # xmm11 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm1                    # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	unpcklps	%xmm11, %xmm2                   # xmm2 = xmm2[0],xmm11[0],xmm2[1],xmm11[1]
	unpcklpd	%xmm1, %xmm2                    # xmm2 = xmm2[0],xmm1[0]
	paddd	.LCPI0_3(%rip), %xmm4
	movupd	%xmm2, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	addq	$16, %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_380
# %bb.381:                              #   in Loop: Header=BB0_379 Depth=1
	cmpl	%ecx, %ebp
	movq	-120(%rsp), %rdx                # 8-byte Reload
	movq	.LCPI0_9(%rip), %xmm2           # xmm2 = [255,0,0,0,255,0,0,0,0,0,0,0,0,0,0,0]
	movaps	.LCPI0_7(%rip), %xmm3           # xmm3 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm5           # xmm5 = [-5.0E-1,-5.0E-1,u,u]
	movdqa	-80(%rsp), %xmm6                # 16-byte Reload
	jl	.LBB0_382
	jmp	.LBB0_391
	.p2align	4, 0x90
.LBB0_390:                              #   in Loop: Header=BB0_382 Depth=2
	imull	%ecx, %r8d
	addl	%ebx, %r8d
	movslq	%r8d, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rdx,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_391
.LBB0_382:                              #   Parent Loop BB0_379 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r13), %eax
	movd	%eax, %xmm0
	shrl	$16, %eax
	movd	%eax, %xmm1
	punpckldq	%xmm1, %xmm0            # xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1]
	pand	%xmm2, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm3, %xmm0
	addps	%xmm5, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movd	%ebp, %xmm4
	punpcklqdq	%xmm6, %xmm4            # xmm4 = xmm4[0],xmm6[0]
	shufps	$226, %xmm6, %xmm4              # xmm4 = xmm4[2,0],xmm6[2,3]
	paddd	%xmm0, %xmm4
	pshufd	$85, %xmm4, %xmm0               # xmm0 = xmm4[1,1,1,1]
	movd	%xmm0, %eax
	cmpl	%r14d, %eax
	jl	.LBB0_384
# %bb.383:                              #   in Loop: Header=BB0_382 Depth=2
	movl	%r14d, %eax
.LBB0_384:                              #   in Loop: Header=BB0_382 Depth=2
	pshufd	$80, %xmm4, %xmm0               # xmm0 = xmm4[0,0,1,1]
	movmskpd	%xmm0, %r11d
	xorl	%r8d, %r8d
	movl	$0, %ebx
	testb	$2, %r11b
	je	.LBB0_385
# %bb.386:                              #   in Loop: Header=BB0_382 Depth=2
	movd	%xmm4, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_387
.LBB0_388:                              #   in Loop: Header=BB0_382 Depth=2
	testb	$1, %r11b
	jne	.LBB0_390
	jmp	.LBB0_389
	.p2align	4, 0x90
.LBB0_385:                              #   in Loop: Header=BB0_382 Depth=2
	movl	%eax, %ebx
	movd	%xmm4, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_388
.LBB0_387:                              #   in Loop: Header=BB0_382 Depth=2
	movl	%r9d, %eax
	testb	$1, %r11b
	jne	.LBB0_390
.LBB0_389:                              #   in Loop: Header=BB0_382 Depth=2
	movl	%eax, %r8d
	jmp	.LBB0_390
.LBB0_98:
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movdqa	%xmm0, 32(%rsp)                 # 16-byte Spill
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movdqa	%xmm0, 16(%rsp)                 # 16-byte Spill
	movl	%ecx, %r10d
	movl	%r8d, %eax
	movq	%rax, -96(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rax
	movq	%rax, -16(%rsp)                 # 8-byte Spill
	movl	$16, %ebx
	xorl	%edx, %edx
	movdqa	%xmm0, -112(%rsp)               # 16-byte Spill
	pshufd	$245, %xmm0, %xmm0              # xmm0 = xmm0[1,1,3,3]
	movdqa	%xmm0, (%rsp)                   # 16-byte Spill
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	.LCPI0_6(%rip), %xmm7           # xmm7 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	movaps	.LCPI0_1(%rip), %xmm8           # xmm8 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	movaps	.LCPI0_2(%rip), %xmm9           # xmm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	pxor	%xmm14, %xmm14
	movdqa	(%rsp), %xmm10                  # 16-byte Reload
	movdqa	16(%rsp), %xmm15                # 16-byte Reload
	jmp	.LBB0_99
	.p2align	4, 0x90
.LBB0_111:                              #   in Loop: Header=BB0_99 Depth=1
	movq	-64(%rsp), %rdx                 # 8-byte Reload
	incq	%rdx
	movq	-16(%rsp), %rax                 # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	movq	-32(%rsp), %rbx                 # 8-byte Reload
	addq	%rax, %rbx
	cmpq	-96(%rsp), %rdx                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_99:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_100 Depth 2
                                        #     Child Loop BB0_102 Depth 2
	movq	%rdx, -64(%rsp)                 # 8-byte Spill
	movd	%edx, %xmm0
	movdqa	%xmm0, -80(%rsp)                # 16-byte Spill
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movdqa	%xmm0, -48(%rsp)                # 16-byte Spill
	movq	%rbx, -32(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm4           # xmm4 = [0,1,2,3]
	movdqa	-112(%rsp), %xmm6               # 16-byte Reload
	movdqa	32(%rsp), %xmm3                 # 16-byte Reload
	.p2align	4, 0x90
.LBB0_100:                              #   Parent Loop BB0_99 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm0
	movdqa	%xmm0, %xmm11
	psrld	$16, %xmm11
	pand	%xmm7, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm8, %xmm0
	addps	%xmm9, %xmm0
	pand	%xmm7, %xmm11
	cvtdq2ps	%xmm11, %xmm11
	divps	%xmm8, %xmm11
	mulps	%xmm12, %xmm0
	addps	%xmm9, %xmm11
	mulps	%xmm12, %xmm11
	cvttps2dq	%xmm11, %xmm11
	movaps	%xmm12, %xmm5
	cvttps2dq	%xmm0, %xmm12
	paddd	-48(%rsp), %xmm11               # 16-byte Folded Reload
	paddd	%xmm4, %xmm12
	movdqa	%xmm12, %xmm0
	pcmpgtd	%xmm14, %xmm0
	movdqa	%xmm11, %xmm13
	pcmpgtd	%xmm14, %xmm13
	pand	%xmm11, %xmm13
	pand	%xmm12, %xmm0
	movdqa	%xmm0, %xmm12
	pcmpgtd	%xmm3, %xmm12
	movdqa	%xmm3, %xmm1
	pand	%xmm12, %xmm1
	movdqa	%xmm13, %xmm11
	pcmpgtd	%xmm15, %xmm11
	movdqa	%xmm15, %xmm2
	pandn	%xmm0, %xmm12
	pand	%xmm11, %xmm2
	pandn	%xmm13, %xmm11
	por	%xmm2, %xmm11
	por	%xmm1, %xmm12
	pshufd	$245, %xmm11, %xmm0             # xmm0 = xmm11[1,1,3,3]
	pmuludq	%xmm6, %xmm11
	pmuludq	%xmm10, %xmm0
	pshufd	$232, %xmm11, %xmm1             # xmm1 = xmm11[0,2,2,3]
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	punpckldq	%xmm0, %xmm1            # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	paddd	%xmm12, %xmm1
	movaps	%xmm5, %xmm12
	movq	%rbx, %r13
	movd	%xmm1, %eax
	pshufd	$85, %xmm1, %xmm0               # xmm0 = xmm1[1,1,1,1]
	pshufd	$238, %xmm1, %xmm2              # xmm2 = xmm1[2,3,2,3]
	movd	%xmm0, %edx
	movd	%xmm2, %esi
	pshufd	$255, %xmm1, %xmm0              # xmm0 = xmm1[3,3,3,3]
	movd	%xmm0, %r11d
	movss	(%rdi,%r11,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm1            # xmm1 = mem[0],zero,zero,zero
	movss	(%rdi,%rax,4), %xmm2            # xmm2 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm11           # xmm11 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm1                    # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	unpcklps	%xmm11, %xmm2                   # xmm2 = xmm2[0],xmm11[0],xmm2[1],xmm11[1]
	unpcklpd	%xmm1, %xmm2                    # xmm2 = xmm2[0],xmm1[0]
	paddd	.LCPI0_3(%rip), %xmm4
	movupd	%xmm2, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	addq	$16, %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_100
# %bb.101:                              #   in Loop: Header=BB0_99 Depth=1
	cmpl	%ecx, %ebp
	movq	-120(%rsp), %rdx                # 8-byte Reload
	movq	.LCPI0_9(%rip), %xmm2           # xmm2 = [255,0,0,0,255,0,0,0,0,0,0,0,0,0,0,0]
	movaps	.LCPI0_7(%rip), %xmm3           # xmm3 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm5           # xmm5 = [-5.0E-1,-5.0E-1,u,u]
	movdqa	-80(%rsp), %xmm6                # 16-byte Reload
	jl	.LBB0_102
	jmp	.LBB0_111
	.p2align	4, 0x90
.LBB0_110:                              #   in Loop: Header=BB0_102 Depth=2
	imull	%ecx, %r8d
	addl	%ebx, %r8d
	movslq	%r8d, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rdx,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_111
.LBB0_102:                              #   Parent Loop BB0_99 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r13), %eax
	movd	%eax, %xmm0
	shrl	$16, %eax
	movd	%eax, %xmm1
	punpckldq	%xmm0, %xmm1            # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	pand	%xmm2, %xmm1
	cvtdq2ps	%xmm1, %xmm0
	divps	%xmm3, %xmm0
	addps	%xmm5, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movd	%ebp, %xmm4
	punpcklqdq	%xmm6, %xmm4            # xmm4 = xmm4[0],xmm6[0]
	shufps	$226, %xmm6, %xmm4              # xmm4 = xmm4[2,0],xmm6[2,3]
	paddd	%xmm0, %xmm4
	pshufd	$85, %xmm4, %xmm0               # xmm0 = xmm4[1,1,1,1]
	movd	%xmm0, %eax
	cmpl	%r14d, %eax
	jl	.LBB0_104
# %bb.103:                              #   in Loop: Header=BB0_102 Depth=2
	movl	%r14d, %eax
.LBB0_104:                              #   in Loop: Header=BB0_102 Depth=2
	pshufd	$80, %xmm4, %xmm0               # xmm0 = xmm4[0,0,1,1]
	movmskpd	%xmm0, %r11d
	xorl	%r8d, %r8d
	movl	$0, %ebx
	testb	$2, %r11b
	je	.LBB0_105
# %bb.106:                              #   in Loop: Header=BB0_102 Depth=2
	movd	%xmm4, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_107
.LBB0_108:                              #   in Loop: Header=BB0_102 Depth=2
	testb	$1, %r11b
	jne	.LBB0_110
	jmp	.LBB0_109
	.p2align	4, 0x90
.LBB0_105:                              #   in Loop: Header=BB0_102 Depth=2
	movl	%eax, %ebx
	movd	%xmm4, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_108
.LBB0_107:                              #   in Loop: Header=BB0_102 Depth=2
	movl	%r9d, %eax
	testb	$1, %r11b
	jne	.LBB0_110
.LBB0_109:                              #   in Loop: Header=BB0_102 Depth=2
	movl	%eax, %r8d
	jmp	.LBB0_110
.LBB0_424:
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movdqa	%xmm0, 32(%rsp)                 # 16-byte Spill
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movdqa	%xmm0, 16(%rsp)                 # 16-byte Spill
	movl	%ecx, %r10d
	movl	%r8d, %eax
	movq	%rax, -96(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rax
	movq	%rax, -16(%rsp)                 # 8-byte Spill
	movl	$16, %ebx
	xorl	%edx, %edx
	movdqa	%xmm0, -112(%rsp)               # 16-byte Spill
	pshufd	$245, %xmm0, %xmm0              # xmm0 = xmm0[1,1,3,3]
	movdqa	%xmm0, (%rsp)                   # 16-byte Spill
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	.LCPI0_6(%rip), %xmm7           # xmm7 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	movaps	.LCPI0_1(%rip), %xmm8           # xmm8 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	movaps	.LCPI0_2(%rip), %xmm9           # xmm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	pxor	%xmm14, %xmm14
	movdqa	(%rsp), %xmm10                  # 16-byte Reload
	movdqa	16(%rsp), %xmm15                # 16-byte Reload
	jmp	.LBB0_425
	.p2align	4, 0x90
.LBB0_437:                              #   in Loop: Header=BB0_425 Depth=1
	movq	-64(%rsp), %rdx                 # 8-byte Reload
	incq	%rdx
	movq	-16(%rsp), %rax                 # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	movq	-32(%rsp), %rbx                 # 8-byte Reload
	addq	%rax, %rbx
	cmpq	-96(%rsp), %rdx                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_425:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_426 Depth 2
                                        #     Child Loop BB0_428 Depth 2
	movq	%rdx, -64(%rsp)                 # 8-byte Spill
	movd	%edx, %xmm0
	movdqa	%xmm0, -80(%rsp)                # 16-byte Spill
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movdqa	%xmm0, -48(%rsp)                # 16-byte Spill
	movq	%rbx, -32(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm4           # xmm4 = [0,1,2,3]
	movdqa	-112(%rsp), %xmm6               # 16-byte Reload
	movdqa	32(%rsp), %xmm3                 # 16-byte Reload
	.p2align	4, 0x90
.LBB0_426:                              #   Parent Loop BB0_425 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm11
	movdqa	%xmm11, %xmm0
	psrld	$8, %xmm0
	pand	%xmm7, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm8, %xmm0
	addps	%xmm9, %xmm0
	pand	%xmm7, %xmm11
	cvtdq2ps	%xmm11, %xmm11
	divps	%xmm8, %xmm11
	mulps	%xmm12, %xmm0
	addps	%xmm9, %xmm11
	mulps	%xmm12, %xmm11
	cvttps2dq	%xmm11, %xmm11
	movaps	%xmm12, %xmm5
	cvttps2dq	%xmm0, %xmm12
	paddd	-48(%rsp), %xmm11               # 16-byte Folded Reload
	paddd	%xmm4, %xmm12
	movdqa	%xmm12, %xmm0
	pcmpgtd	%xmm14, %xmm0
	movdqa	%xmm11, %xmm13
	pcmpgtd	%xmm14, %xmm13
	pand	%xmm11, %xmm13
	pand	%xmm12, %xmm0
	movdqa	%xmm0, %xmm12
	pcmpgtd	%xmm3, %xmm12
	movdqa	%xmm3, %xmm1
	pand	%xmm12, %xmm1
	movdqa	%xmm13, %xmm11
	pcmpgtd	%xmm15, %xmm11
	movdqa	%xmm15, %xmm2
	pandn	%xmm0, %xmm12
	pand	%xmm11, %xmm2
	pandn	%xmm13, %xmm11
	por	%xmm2, %xmm11
	por	%xmm1, %xmm12
	pshufd	$245, %xmm11, %xmm0             # xmm0 = xmm11[1,1,3,3]
	pmuludq	%xmm6, %xmm11
	pmuludq	%xmm10, %xmm0
	pshufd	$232, %xmm11, %xmm1             # xmm1 = xmm11[0,2,2,3]
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	punpckldq	%xmm0, %xmm1            # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	paddd	%xmm12, %xmm1
	movaps	%xmm5, %xmm12
	movq	%rbx, %r13
	movd	%xmm1, %eax
	pshufd	$85, %xmm1, %xmm0               # xmm0 = xmm1[1,1,1,1]
	pshufd	$238, %xmm1, %xmm2              # xmm2 = xmm1[2,3,2,3]
	movd	%xmm0, %edx
	movd	%xmm2, %esi
	pshufd	$255, %xmm1, %xmm0              # xmm0 = xmm1[3,3,3,3]
	movd	%xmm0, %r11d
	movss	(%rdi,%r11,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm1            # xmm1 = mem[0],zero,zero,zero
	movss	(%rdi,%rax,4), %xmm2            # xmm2 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm11           # xmm11 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm1                    # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	unpcklps	%xmm11, %xmm2                   # xmm2 = xmm2[0],xmm11[0],xmm2[1],xmm11[1]
	unpcklpd	%xmm1, %xmm2                    # xmm2 = xmm2[0],xmm1[0]
	paddd	.LCPI0_3(%rip), %xmm4
	movupd	%xmm2, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	addq	$16, %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_426
# %bb.427:                              #   in Loop: Header=BB0_425 Depth=1
	cmpl	%ecx, %ebp
	movq	-120(%rsp), %rdx                # 8-byte Reload
	movq	.LCPI0_9(%rip), %xmm2           # xmm2 = [255,0,0,0,255,0,0,0,0,0,0,0,0,0,0,0]
	movaps	.LCPI0_7(%rip), %xmm3           # xmm3 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm5           # xmm5 = [-5.0E-1,-5.0E-1,u,u]
	movdqa	-80(%rsp), %xmm6                # 16-byte Reload
	jl	.LBB0_428
	jmp	.LBB0_437
	.p2align	4, 0x90
.LBB0_436:                              #   in Loop: Header=BB0_428 Depth=2
	imull	%ecx, %r8d
	addl	%ebx, %r8d
	movslq	%r8d, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rdx,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_437
.LBB0_428:                              #   Parent Loop BB0_425 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r13), %eax
	movd	%eax, %xmm0
	shrl	$8, %eax
	movd	%eax, %xmm1
	punpckldq	%xmm1, %xmm0            # xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1]
	pand	%xmm2, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm3, %xmm0
	addps	%xmm5, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movd	%ebp, %xmm4
	punpcklqdq	%xmm6, %xmm4            # xmm4 = xmm4[0],xmm6[0]
	shufps	$226, %xmm6, %xmm4              # xmm4 = xmm4[2,0],xmm6[2,3]
	paddd	%xmm0, %xmm4
	pshufd	$85, %xmm4, %xmm0               # xmm0 = xmm4[1,1,1,1]
	movd	%xmm0, %eax
	cmpl	%r14d, %eax
	jl	.LBB0_430
# %bb.429:                              #   in Loop: Header=BB0_428 Depth=2
	movl	%r14d, %eax
.LBB0_430:                              #   in Loop: Header=BB0_428 Depth=2
	pshufd	$80, %xmm4, %xmm0               # xmm0 = xmm4[0,0,1,1]
	movmskpd	%xmm0, %r11d
	xorl	%r8d, %r8d
	movl	$0, %ebx
	testb	$2, %r11b
	je	.LBB0_431
# %bb.432:                              #   in Loop: Header=BB0_428 Depth=2
	movd	%xmm4, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_433
.LBB0_434:                              #   in Loop: Header=BB0_428 Depth=2
	testb	$1, %r11b
	jne	.LBB0_436
	jmp	.LBB0_435
	.p2align	4, 0x90
.LBB0_431:                              #   in Loop: Header=BB0_428 Depth=2
	movl	%eax, %ebx
	movd	%xmm4, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_434
.LBB0_433:                              #   in Loop: Header=BB0_428 Depth=2
	movl	%r9d, %eax
	testb	$1, %r11b
	jne	.LBB0_436
.LBB0_435:                              #   in Loop: Header=BB0_428 Depth=2
	movl	%eax, %r8d
	jmp	.LBB0_436
.LBB0_284:
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movdqa	%xmm0, 32(%rsp)                 # 16-byte Spill
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movdqa	%xmm0, 16(%rsp)                 # 16-byte Spill
	movl	%ecx, %r10d
	movl	%r8d, %eax
	movq	%rax, -96(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rax
	movq	%rax, -16(%rsp)                 # 8-byte Spill
	movl	$16, %ebx
	xorl	%edx, %edx
	movdqa	%xmm0, -112(%rsp)               # 16-byte Spill
	pshufd	$245, %xmm0, %xmm0              # xmm0 = xmm0[1,1,3,3]
	movdqa	%xmm0, (%rsp)                   # 16-byte Spill
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	.LCPI0_6(%rip), %xmm7           # xmm7 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	movaps	.LCPI0_1(%rip), %xmm8           # xmm8 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	movaps	.LCPI0_2(%rip), %xmm9           # xmm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	pxor	%xmm14, %xmm14
	movdqa	(%rsp), %xmm10                  # 16-byte Reload
	movdqa	16(%rsp), %xmm15                # 16-byte Reload
	jmp	.LBB0_285
	.p2align	4, 0x90
.LBB0_297:                              #   in Loop: Header=BB0_285 Depth=1
	movq	-64(%rsp), %rdx                 # 8-byte Reload
	incq	%rdx
	movq	-16(%rsp), %rax                 # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	movq	-32(%rsp), %rbx                 # 8-byte Reload
	addq	%rax, %rbx
	cmpq	-96(%rsp), %rdx                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_285:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_286 Depth 2
                                        #     Child Loop BB0_288 Depth 2
	movq	%rdx, -64(%rsp)                 # 8-byte Spill
	movd	%edx, %xmm0
	movdqa	%xmm0, -80(%rsp)                # 16-byte Spill
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movdqa	%xmm0, -48(%rsp)                # 16-byte Spill
	movq	%rbx, -32(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm4           # xmm4 = [0,1,2,3]
	movdqa	-112(%rsp), %xmm6               # 16-byte Reload
	movdqa	32(%rsp), %xmm3                 # 16-byte Reload
	.p2align	4, 0x90
.LBB0_286:                              #   Parent Loop BB0_285 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm0
	movdqa	%xmm0, %xmm11
	psrld	$8, %xmm11
	pand	%xmm7, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm8, %xmm0
	addps	%xmm9, %xmm0
	pand	%xmm7, %xmm11
	cvtdq2ps	%xmm11, %xmm11
	divps	%xmm8, %xmm11
	mulps	%xmm12, %xmm0
	addps	%xmm9, %xmm11
	mulps	%xmm12, %xmm11
	cvttps2dq	%xmm11, %xmm11
	movaps	%xmm12, %xmm5
	cvttps2dq	%xmm0, %xmm12
	paddd	-48(%rsp), %xmm11               # 16-byte Folded Reload
	paddd	%xmm4, %xmm12
	movdqa	%xmm12, %xmm0
	pcmpgtd	%xmm14, %xmm0
	movdqa	%xmm11, %xmm13
	pcmpgtd	%xmm14, %xmm13
	pand	%xmm11, %xmm13
	pand	%xmm12, %xmm0
	movdqa	%xmm0, %xmm12
	pcmpgtd	%xmm3, %xmm12
	movdqa	%xmm3, %xmm1
	pand	%xmm12, %xmm1
	movdqa	%xmm13, %xmm11
	pcmpgtd	%xmm15, %xmm11
	movdqa	%xmm15, %xmm2
	pandn	%xmm0, %xmm12
	pand	%xmm11, %xmm2
	pandn	%xmm13, %xmm11
	por	%xmm2, %xmm11
	por	%xmm1, %xmm12
	pshufd	$245, %xmm11, %xmm0             # xmm0 = xmm11[1,1,3,3]
	pmuludq	%xmm6, %xmm11
	pmuludq	%xmm10, %xmm0
	pshufd	$232, %xmm11, %xmm1             # xmm1 = xmm11[0,2,2,3]
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	punpckldq	%xmm0, %xmm1            # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	paddd	%xmm12, %xmm1
	movaps	%xmm5, %xmm12
	movq	%rbx, %r13
	movd	%xmm1, %eax
	pshufd	$85, %xmm1, %xmm0               # xmm0 = xmm1[1,1,1,1]
	pshufd	$238, %xmm1, %xmm2              # xmm2 = xmm1[2,3,2,3]
	movd	%xmm0, %edx
	movd	%xmm2, %esi
	pshufd	$255, %xmm1, %xmm0              # xmm0 = xmm1[3,3,3,3]
	movd	%xmm0, %r11d
	movss	(%rdi,%r11,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm1            # xmm1 = mem[0],zero,zero,zero
	movss	(%rdi,%rax,4), %xmm2            # xmm2 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm11           # xmm11 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm1                    # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	unpcklps	%xmm11, %xmm2                   # xmm2 = xmm2[0],xmm11[0],xmm2[1],xmm11[1]
	unpcklpd	%xmm1, %xmm2                    # xmm2 = xmm2[0],xmm1[0]
	paddd	.LCPI0_3(%rip), %xmm4
	movupd	%xmm2, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	addq	$16, %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_286
# %bb.287:                              #   in Loop: Header=BB0_285 Depth=1
	cmpl	%ecx, %ebp
	movq	-120(%rsp), %rdx                # 8-byte Reload
	movq	.LCPI0_9(%rip), %xmm2           # xmm2 = [255,0,0,0,255,0,0,0,0,0,0,0,0,0,0,0]
	movaps	.LCPI0_7(%rip), %xmm3           # xmm3 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm5           # xmm5 = [-5.0E-1,-5.0E-1,u,u]
	movdqa	-80(%rsp), %xmm6                # 16-byte Reload
	jl	.LBB0_288
	jmp	.LBB0_297
	.p2align	4, 0x90
.LBB0_296:                              #   in Loop: Header=BB0_288 Depth=2
	imull	%ecx, %r8d
	addl	%ebx, %r8d
	movslq	%r8d, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rdx,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_297
.LBB0_288:                              #   Parent Loop BB0_285 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r13), %eax
	movd	%eax, %xmm0
	shrl	$8, %eax
	movd	%eax, %xmm1
	punpckldq	%xmm0, %xmm1            # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	pand	%xmm2, %xmm1
	cvtdq2ps	%xmm1, %xmm0
	divps	%xmm3, %xmm0
	addps	%xmm5, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movd	%ebp, %xmm4
	punpcklqdq	%xmm6, %xmm4            # xmm4 = xmm4[0],xmm6[0]
	shufps	$226, %xmm6, %xmm4              # xmm4 = xmm4[2,0],xmm6[2,3]
	paddd	%xmm0, %xmm4
	pshufd	$85, %xmm4, %xmm0               # xmm0 = xmm4[1,1,1,1]
	movd	%xmm0, %eax
	cmpl	%r14d, %eax
	jl	.LBB0_290
# %bb.289:                              #   in Loop: Header=BB0_288 Depth=2
	movl	%r14d, %eax
.LBB0_290:                              #   in Loop: Header=BB0_288 Depth=2
	pshufd	$80, %xmm4, %xmm0               # xmm0 = xmm4[0,0,1,1]
	movmskpd	%xmm0, %r11d
	xorl	%r8d, %r8d
	movl	$0, %ebx
	testb	$2, %r11b
	je	.LBB0_291
# %bb.292:                              #   in Loop: Header=BB0_288 Depth=2
	movd	%xmm4, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_293
.LBB0_294:                              #   in Loop: Header=BB0_288 Depth=2
	testb	$1, %r11b
	jne	.LBB0_296
	jmp	.LBB0_295
	.p2align	4, 0x90
.LBB0_291:                              #   in Loop: Header=BB0_288 Depth=2
	movl	%eax, %ebx
	movd	%xmm4, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_294
.LBB0_293:                              #   in Loop: Header=BB0_288 Depth=2
	movl	%r9d, %eax
	testb	$1, %r11b
	jne	.LBB0_296
.LBB0_295:                              #   in Loop: Header=BB0_288 Depth=2
	movl	%eax, %r8d
	jmp	.LBB0_296
.LBB0_702:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	movaps	%xmm12, -96(%rsp)               # 16-byte Spill
	movd	%eax, %xmm0
	pshufd	$0, %xmm0, %xmm2                # xmm2 = xmm0[0,0,0,0]
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm6                # xmm6 = xmm0[0,0,0,0]
	movl	%ecx, %r10d
	movl	%r8d, %edx
	movq	%rdx, -64(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rdx
	movq	%rdx, -80(%rsp)                 # 8-byte Spill
	movl	$16, %ebx
	xorl	%r14d, %r14d
	pxor	%xmm8, %xmm8
	movdqa	%xmm0, -112(%rsp)               # 16-byte Spill
	pshufd	$245, %xmm0, %xmm9              # xmm9 = xmm0[1,1,3,3]
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movaps	.LCPI0_2(%rip), %xmm10          # xmm10 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movdqa	-112(%rsp), %xmm7               # 16-byte Reload
	jmp	.LBB0_703
	.p2align	4, 0x90
.LBB0_715:                              #   in Loop: Header=BB0_703 Depth=1
	incq	%r14
	movq	-80(%rsp), %rdx                 # 8-byte Reload
	addq	%rdx, %r12
	addq	%rdx, %r15
	movq	-48(%rsp), %rbx                 # 8-byte Reload
	addq	%rdx, %rbx
	cmpq	-64(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_703:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_704 Depth 2
                                        #     Child Loop BB0_706 Depth 2
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm13               # xmm13 = xmm0[0,0,0,0]
	movq	%rbx, -48(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm14          # xmm14 = [0,1,2,3]
	movdqa	.LCPI0_3(%rip), %xmm1           # xmm1 = [4,4,4,4]
	movaps	-96(%rsp), %xmm4                # 16-byte Reload
	.p2align	4, 0x90
.LBB0_704:                              #   Parent Loop BB0_703 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm0
	psrld	$24, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	.LCPI0_1(%rip), %xmm0
	addps	%xmm10, %xmm0
	mulps	%xmm4, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm0, %xmm5
	paddd	%xmm14, %xmm5
	paddd	%xmm13, %xmm0
	movdqa	%xmm5, %xmm15
	pcmpgtd	%xmm8, %xmm15
	movdqa	%xmm0, %xmm12
	pcmpgtd	%xmm8, %xmm12
	pand	%xmm0, %xmm12
	pand	%xmm5, %xmm15
	movdqa	%xmm15, %xmm0
	pcmpgtd	%xmm2, %xmm0
	movdqa	%xmm2, %xmm5
	pand	%xmm0, %xmm5
	movdqa	%xmm12, %xmm11
	pcmpgtd	%xmm6, %xmm11
	movdqa	%xmm6, %xmm3
	pandn	%xmm15, %xmm0
	pand	%xmm11, %xmm3
	pandn	%xmm12, %xmm11
	por	%xmm3, %xmm11
	por	%xmm5, %xmm0
	pshufd	$245, %xmm11, %xmm3             # xmm3 = xmm11[1,1,3,3]
	pmuludq	%xmm7, %xmm11
	pmuludq	%xmm9, %xmm3
	pshufd	$232, %xmm11, %xmm5             # xmm5 = xmm11[0,2,2,3]
	pshufd	$232, %xmm3, %xmm3              # xmm3 = xmm3[0,2,2,3]
	punpckldq	%xmm3, %xmm5            # xmm5 = xmm5[0],xmm3[0],xmm5[1],xmm3[1]
	paddd	%xmm0, %xmm5
	movq	%rbx, %r13
	movd	%xmm5, %edx
	pshufd	$85, %xmm5, %xmm0               # xmm0 = xmm5[1,1,1,1]
	pshufd	$238, %xmm5, %xmm3              # xmm3 = xmm5[2,3,2,3]
	movd	%xmm0, %esi
	movd	%xmm3, %r11d
	pshufd	$255, %xmm5, %xmm0              # xmm0 = xmm5[3,3,3,3]
	movd	%xmm0, %ebx
	movss	(%rdi,%rbx,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%r11,4), %xmm3            # xmm3 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm5            # xmm5 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm11           # xmm11 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm3                    # xmm3 = xmm3[0],xmm0[0],xmm3[1],xmm0[1]
	unpcklps	%xmm11, %xmm5                   # xmm5 = xmm5[0],xmm11[0],xmm5[1],xmm11[1]
	movlhps	%xmm3, %xmm5                    # xmm5 = xmm5[0],xmm3[0]
	paddd	%xmm1, %xmm14
	movups	%xmm5, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	leaq	16(%r13), %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_704
# %bb.705:                              #   in Loop: Header=BB0_703 Depth=1
	cmpl	%ecx, %ebp
	movaps	-32(%rsp), %xmm3                # 16-byte Reload
	movss	.LCPI0_4(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	movss	.LCPI0_5(%rip), %xmm4           # xmm4 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jl	.LBB0_706
	jmp	.LBB0_715
	.p2align	4, 0x90
.LBB0_714:                              #   in Loop: Header=BB0_706 Depth=2
	imull	%ecx, %ebx
	addl	%r11d, %ebx
	movslq	%ebx, %rdx
	movl	(%rdi,%rdx,4), %edx
	movl	%edx, (%rsi,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_715
.LBB0_706:                              #   Parent Loop BB0_703 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movzbl	3(%rdx,%r13), %edx
	xorps	%xmm0, %xmm0
	cvtsi2ss	%edx, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm4, %xmm0
	mulss	%xmm3, %xmm0
	cvttss2si	%xmm0, %r8d
	leal	(%r8,%rbp), %edx
	movl	%edx, %esi
	cmpl	%eax, %edx
	jge	.LBB0_707
# %bb.708:                              #   in Loop: Header=BB0_706 Depth=2
	xorl	%ebx, %ebx
	movl	$0, %r11d
	testl	%edx, %edx
	jns	.LBB0_709
.LBB0_710:                              #   in Loop: Header=BB0_706 Depth=2
	addl	%r14d, %r8d
	movl	%r8d, %edx
	cmpl	%r9d, %r8d
	jge	.LBB0_711
.LBB0_712:                              #   in Loop: Header=BB0_706 Depth=2
	testl	%r8d, %r8d
	movq	-120(%rsp), %rsi                # 8-byte Reload
	js	.LBB0_714
	jmp	.LBB0_713
	.p2align	4, 0x90
.LBB0_707:                              #   in Loop: Header=BB0_706 Depth=2
	movl	%eax, %esi
	xorl	%ebx, %ebx
	movl	$0, %r11d
	testl	%edx, %edx
	js	.LBB0_710
.LBB0_709:                              #   in Loop: Header=BB0_706 Depth=2
	movl	%esi, %r11d
	addl	%r14d, %r8d
	movl	%r8d, %edx
	cmpl	%r9d, %r8d
	jl	.LBB0_712
.LBB0_711:                              #   in Loop: Header=BB0_706 Depth=2
	movl	%r9d, %edx
	testl	%r8d, %r8d
	movq	-120(%rsp), %rsi                # 8-byte Reload
	js	.LBB0_714
.LBB0_713:                              #   in Loop: Header=BB0_706 Depth=2
	movl	%edx, %ebx
	jmp	.LBB0_714
.LBB0_564:
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm5                # xmm5 = xmm0[0,0,0,0]
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm10               # xmm10 = xmm0[0,0,0,0]
	movl	%ecx, %r10d
	movl	%r8d, %eax
	movq	%rax, -80(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rax
	movq	%rax, -112(%rsp)                # 8-byte Spill
	movl	$16, %ebx
	xorl	%edx, %edx
	movdqa	%xmm0, -96(%rsp)                # 16-byte Spill
	pshufd	$245, %xmm0, %xmm0              # xmm0 = xmm0[1,1,3,3]
	movdqa	%xmm0, -16(%rsp)                # 16-byte Spill
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	-96(%rsp), %xmm6                # 16-byte Reload
	movaps	.LCPI0_1(%rip), %xmm8           # xmm8 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	movaps	.LCPI0_2(%rip), %xmm9           # xmm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	pxor	%xmm7, %xmm7
	movdqa	-16(%rsp), %xmm13               # 16-byte Reload
	jmp	.LBB0_565
	.p2align	4, 0x90
.LBB0_577:                              #   in Loop: Header=BB0_565 Depth=1
	movq	-32(%rsp), %rdx                 # 8-byte Reload
	incq	%rdx
	movq	-112(%rsp), %rax                # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	movq	-48(%rsp), %rbx                 # 8-byte Reload
	addq	%rax, %rbx
	cmpq	-80(%rsp), %rdx                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_565:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_566 Depth 2
                                        #     Child Loop BB0_568 Depth 2
	movq	%rdx, -32(%rsp)                 # 8-byte Spill
	movd	%edx, %xmm0
	movdqa	%xmm0, -64(%rsp)                # 16-byte Spill
	pshufd	$0, %xmm0, %xmm14               # xmm14 = xmm0[0,0,0,0]
	movq	%rbx, -48(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm15          # xmm15 = [0,1,2,3]
	.p2align	4, 0x90
.LBB0_566:                              #   Parent Loop BB0_565 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm4
	movdqa	%xmm4, %xmm0
	psrld	$16, %xmm0
	pand	.LCPI0_6(%rip), %xmm0
	psrld	$24, %xmm4
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm8, %xmm0
	addps	%xmm9, %xmm0
	cvtdq2ps	%xmm4, %xmm4
	divps	%xmm8, %xmm4
	mulps	%xmm12, %xmm0
	addps	%xmm9, %xmm4
	mulps	%xmm12, %xmm4
	cvttps2dq	%xmm4, %xmm4
	cvttps2dq	%xmm0, %xmm11
	paddd	%xmm14, %xmm4
	paddd	%xmm15, %xmm11
	movdqa	%xmm11, %xmm0
	pcmpgtd	%xmm7, %xmm0
	movaps	%xmm12, %xmm3
	movdqa	%xmm4, %xmm12
	pcmpgtd	%xmm7, %xmm12
	pand	%xmm4, %xmm12
	pand	%xmm11, %xmm0
	movdqa	%xmm0, %xmm11
	pcmpgtd	%xmm5, %xmm11
	movdqa	%xmm5, %xmm1
	pand	%xmm11, %xmm1
	movdqa	%xmm12, %xmm4
	pcmpgtd	%xmm10, %xmm4
	movdqa	%xmm10, %xmm2
	pandn	%xmm0, %xmm11
	pand	%xmm4, %xmm2
	pandn	%xmm12, %xmm4
	movaps	%xmm3, %xmm12
	por	%xmm2, %xmm4
	por	%xmm1, %xmm11
	pshufd	$245, %xmm4, %xmm0              # xmm0 = xmm4[1,1,3,3]
	pmuludq	%xmm6, %xmm4
	pmuludq	%xmm13, %xmm0
	pshufd	$232, %xmm4, %xmm1              # xmm1 = xmm4[0,2,2,3]
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	punpckldq	%xmm0, %xmm1            # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	paddd	%xmm11, %xmm1
	movq	%rbx, %r13
	movd	%xmm1, %eax
	pshufd	$85, %xmm1, %xmm0               # xmm0 = xmm1[1,1,1,1]
	pshufd	$238, %xmm1, %xmm2              # xmm2 = xmm1[2,3,2,3]
	movd	%xmm0, %edx
	movd	%xmm2, %esi
	pshufd	$255, %xmm1, %xmm0              # xmm0 = xmm1[3,3,3,3]
	movd	%xmm0, %r11d
	movss	(%rdi,%r11,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm1            # xmm1 = mem[0],zero,zero,zero
	movss	(%rdi,%rax,4), %xmm2            # xmm2 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm4            # xmm4 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm1                    # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	unpcklps	%xmm4, %xmm2                    # xmm2 = xmm2[0],xmm4[0],xmm2[1],xmm4[1]
	unpcklpd	%xmm1, %xmm2                    # xmm2 = xmm2[0],xmm1[0]
	paddd	.LCPI0_3(%rip), %xmm15
	movupd	%xmm2, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	addq	$16, %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_566
# %bb.567:                              #   in Loop: Header=BB0_565 Depth=1
	cmpl	%ecx, %ebp
	movq	-120(%rsp), %rsi                # 8-byte Reload
	movaps	.LCPI0_7(%rip), %xmm2           # xmm2 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm3           # xmm3 = [-5.0E-1,-5.0E-1,u,u]
	movdqa	-64(%rsp), %xmm4                # 16-byte Reload
	jl	.LBB0_568
	jmp	.LBB0_577
	.p2align	4, 0x90
.LBB0_576:                              #   in Loop: Header=BB0_568 Depth=2
	imull	%ecx, %r8d
	addl	%ebx, %r8d
	movslq	%r8d, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_577
.LBB0_568:                              #   Parent Loop BB0_565 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r13), %eax
	movl	%eax, %edx
	shrl	$16, %edx
	movzbl	%dl, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm1
	punpckldq	%xmm1, %xmm0            # xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1]
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movd	%ebp, %xmm14
	punpcklqdq	%xmm4, %xmm14           # xmm14 = xmm14[0],xmm4[0]
	shufps	$226, %xmm4, %xmm14             # xmm14 = xmm14[2,0],xmm4[2,3]
	paddd	%xmm0, %xmm14
	pshufd	$85, %xmm14, %xmm0              # xmm0 = xmm14[1,1,1,1]
	movd	%xmm0, %eax
	cmpl	%r14d, %eax
	jl	.LBB0_570
# %bb.569:                              #   in Loop: Header=BB0_568 Depth=2
	movl	%r14d, %eax
.LBB0_570:                              #   in Loop: Header=BB0_568 Depth=2
	pshufd	$80, %xmm14, %xmm0              # xmm0 = xmm14[0,0,1,1]
	movmskpd	%xmm0, %r11d
	xorl	%r8d, %r8d
	movl	$0, %ebx
	testb	$2, %r11b
	je	.LBB0_571
# %bb.572:                              #   in Loop: Header=BB0_568 Depth=2
	movd	%xmm14, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_573
.LBB0_574:                              #   in Loop: Header=BB0_568 Depth=2
	testb	$1, %r11b
	jne	.LBB0_576
	jmp	.LBB0_575
	.p2align	4, 0x90
.LBB0_571:                              #   in Loop: Header=BB0_568 Depth=2
	movl	%eax, %ebx
	movd	%xmm14, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_574
.LBB0_573:                              #   in Loop: Header=BB0_568 Depth=2
	movl	%r9d, %eax
	testb	$1, %r11b
	jne	.LBB0_576
.LBB0_575:                              #   in Loop: Header=BB0_568 Depth=2
	movl	%eax, %r8d
	jmp	.LBB0_576
.LBB0_144:
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm7                # xmm7 = xmm0[0,0,0,0]
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm10               # xmm10 = xmm0[0,0,0,0]
	movl	%ecx, %r10d
	movl	%r8d, %eax
	movq	%rax, -80(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rax
	movq	%rax, -112(%rsp)                # 8-byte Spill
	movl	$16, %ebx
	xorl	%edx, %edx
	movdqa	%xmm0, -96(%rsp)                # 16-byte Spill
	pshufd	$245, %xmm0, %xmm0              # xmm0 = xmm0[1,1,3,3]
	movdqa	%xmm0, -16(%rsp)                # 16-byte Spill
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	-96(%rsp), %xmm5                # 16-byte Reload
	movaps	.LCPI0_1(%rip), %xmm6           # xmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	movaps	.LCPI0_2(%rip), %xmm8           # xmm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	pxor	%xmm9, %xmm9
	movdqa	-16(%rsp), %xmm13               # 16-byte Reload
	jmp	.LBB0_145
	.p2align	4, 0x90
.LBB0_157:                              #   in Loop: Header=BB0_145 Depth=1
	movq	-32(%rsp), %rdx                 # 8-byte Reload
	incq	%rdx
	movq	-112(%rsp), %rax                # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	movq	-48(%rsp), %rbx                 # 8-byte Reload
	addq	%rax, %rbx
	cmpq	-80(%rsp), %rdx                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_145:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_146 Depth 2
                                        #     Child Loop BB0_148 Depth 2
	movq	%rdx, -32(%rsp)                 # 8-byte Spill
	movd	%edx, %xmm0
	movdqa	%xmm0, -64(%rsp)                # 16-byte Spill
	pshufd	$0, %xmm0, %xmm14               # xmm14 = xmm0[0,0,0,0]
	movq	%rbx, -48(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm15          # xmm15 = [0,1,2,3]
	.p2align	4, 0x90
.LBB0_146:                              #   Parent Loop BB0_145 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm0
	movdqa	%xmm0, %xmm4
	psrld	$24, %xmm4
	psrld	$16, %xmm0
	pand	.LCPI0_6(%rip), %xmm0
	cvtdq2ps	%xmm4, %xmm4
	divps	%xmm6, %xmm4
	addps	%xmm8, %xmm4
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm6, %xmm0
	mulps	%xmm12, %xmm4
	addps	%xmm8, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	cvttps2dq	%xmm4, %xmm11
	paddd	%xmm14, %xmm0
	paddd	%xmm15, %xmm11
	movdqa	%xmm11, %xmm4
	pcmpgtd	%xmm9, %xmm4
	movaps	%xmm12, %xmm3
	movdqa	%xmm0, %xmm12
	pcmpgtd	%xmm9, %xmm12
	pand	%xmm0, %xmm12
	pand	%xmm11, %xmm4
	movdqa	%xmm4, %xmm11
	pcmpgtd	%xmm7, %xmm11
	movdqa	%xmm7, %xmm1
	pand	%xmm11, %xmm1
	movdqa	%xmm12, %xmm0
	pcmpgtd	%xmm10, %xmm0
	movdqa	%xmm10, %xmm2
	pandn	%xmm4, %xmm11
	pand	%xmm0, %xmm2
	pandn	%xmm12, %xmm0
	movaps	%xmm3, %xmm12
	por	%xmm2, %xmm0
	por	%xmm1, %xmm11
	pshufd	$245, %xmm0, %xmm1              # xmm1 = xmm0[1,1,3,3]
	pmuludq	%xmm5, %xmm0
	pmuludq	%xmm13, %xmm1
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	pshufd	$232, %xmm1, %xmm1              # xmm1 = xmm1[0,2,2,3]
	punpckldq	%xmm1, %xmm0            # xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1]
	paddd	%xmm11, %xmm0
	movq	%rbx, %r13
	movd	%xmm0, %eax
	pshufd	$85, %xmm0, %xmm1               # xmm1 = xmm0[1,1,1,1]
	pshufd	$238, %xmm0, %xmm2              # xmm2 = xmm0[2,3,2,3]
	movd	%xmm1, %edx
	movd	%xmm2, %esi
	pshufd	$255, %xmm0, %xmm0              # xmm0 = xmm0[3,3,3,3]
	movd	%xmm0, %r11d
	movss	(%rdi,%r11,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm1            # xmm1 = mem[0],zero,zero,zero
	movss	(%rdi,%rax,4), %xmm2            # xmm2 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm4            # xmm4 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm1                    # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	unpcklps	%xmm4, %xmm2                    # xmm2 = xmm2[0],xmm4[0],xmm2[1],xmm4[1]
	unpcklpd	%xmm1, %xmm2                    # xmm2 = xmm2[0],xmm1[0]
	paddd	.LCPI0_3(%rip), %xmm15
	movupd	%xmm2, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	addq	$16, %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_146
# %bb.147:                              #   in Loop: Header=BB0_145 Depth=1
	cmpl	%ecx, %ebp
	movq	-120(%rsp), %rsi                # 8-byte Reload
	movaps	.LCPI0_7(%rip), %xmm2           # xmm2 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm3           # xmm3 = [-5.0E-1,-5.0E-1,u,u]
	movdqa	-64(%rsp), %xmm4                # 16-byte Reload
	jl	.LBB0_148
	jmp	.LBB0_157
	.p2align	4, 0x90
.LBB0_156:                              #   in Loop: Header=BB0_148 Depth=2
	imull	%ecx, %r8d
	addl	%ebx, %r8d
	movslq	%r8d, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_157
.LBB0_148:                              #   Parent Loop BB0_145 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r13), %eax
	movl	%eax, %edx
	shrl	$24, %edx
	shrl	$16, %eax
	movzbl	%al, %eax
	movd	%edx, %xmm0
	movd	%eax, %xmm1
	punpckldq	%xmm0, %xmm1            # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	cvtdq2ps	%xmm1, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movd	%ebp, %xmm14
	punpcklqdq	%xmm4, %xmm14           # xmm14 = xmm14[0],xmm4[0]
	shufps	$226, %xmm4, %xmm14             # xmm14 = xmm14[2,0],xmm4[2,3]
	paddd	%xmm0, %xmm14
	pshufd	$85, %xmm14, %xmm0              # xmm0 = xmm14[1,1,1,1]
	movd	%xmm0, %eax
	cmpl	%r14d, %eax
	jl	.LBB0_150
# %bb.149:                              #   in Loop: Header=BB0_148 Depth=2
	movl	%r14d, %eax
.LBB0_150:                              #   in Loop: Header=BB0_148 Depth=2
	pshufd	$80, %xmm14, %xmm0              # xmm0 = xmm14[0,0,1,1]
	movmskpd	%xmm0, %r11d
	xorl	%r8d, %r8d
	movl	$0, %ebx
	testb	$2, %r11b
	je	.LBB0_151
# %bb.152:                              #   in Loop: Header=BB0_148 Depth=2
	movd	%xmm14, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_153
.LBB0_154:                              #   in Loop: Header=BB0_148 Depth=2
	testb	$1, %r11b
	jne	.LBB0_156
	jmp	.LBB0_155
	.p2align	4, 0x90
.LBB0_151:                              #   in Loop: Header=BB0_148 Depth=2
	movl	%eax, %ebx
	movd	%xmm14, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_154
.LBB0_153:                              #   in Loop: Header=BB0_148 Depth=2
	movl	%r9d, %eax
	testb	$1, %r11b
	jne	.LBB0_156
.LBB0_155:                              #   in Loop: Header=BB0_148 Depth=2
	movl	%eax, %r8d
	jmp	.LBB0_156
.LBB0_610:
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm5                # xmm5 = xmm0[0,0,0,0]
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm10               # xmm10 = xmm0[0,0,0,0]
	movl	%ecx, %r10d
	movl	%r8d, %eax
	movq	%rax, -80(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rax
	movq	%rax, -112(%rsp)                # 8-byte Spill
	movl	$16, %ebx
	xorl	%edx, %edx
	movdqa	%xmm0, -96(%rsp)                # 16-byte Spill
	pshufd	$245, %xmm0, %xmm0              # xmm0 = xmm0[1,1,3,3]
	movdqa	%xmm0, -16(%rsp)                # 16-byte Spill
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	-96(%rsp), %xmm6                # 16-byte Reload
	movaps	.LCPI0_1(%rip), %xmm8           # xmm8 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	movaps	.LCPI0_2(%rip), %xmm9           # xmm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	pxor	%xmm7, %xmm7
	movdqa	-16(%rsp), %xmm13               # 16-byte Reload
	jmp	.LBB0_611
	.p2align	4, 0x90
.LBB0_623:                              #   in Loop: Header=BB0_611 Depth=1
	movq	-32(%rsp), %rdx                 # 8-byte Reload
	incq	%rdx
	movq	-112(%rsp), %rax                # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	movq	-48(%rsp), %rbx                 # 8-byte Reload
	addq	%rax, %rbx
	cmpq	-80(%rsp), %rdx                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_611:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_612 Depth 2
                                        #     Child Loop BB0_614 Depth 2
	movq	%rdx, -32(%rsp)                 # 8-byte Spill
	movd	%edx, %xmm0
	movdqa	%xmm0, -64(%rsp)                # 16-byte Spill
	pshufd	$0, %xmm0, %xmm14               # xmm14 = xmm0[0,0,0,0]
	movq	%rbx, -48(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm15          # xmm15 = [0,1,2,3]
	.p2align	4, 0x90
.LBB0_612:                              #   Parent Loop BB0_611 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm4
	movdqa	%xmm4, %xmm0
	psrld	$8, %xmm0
	pand	.LCPI0_6(%rip), %xmm0
	psrld	$24, %xmm4
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm8, %xmm0
	addps	%xmm9, %xmm0
	cvtdq2ps	%xmm4, %xmm4
	divps	%xmm8, %xmm4
	mulps	%xmm12, %xmm0
	addps	%xmm9, %xmm4
	mulps	%xmm12, %xmm4
	cvttps2dq	%xmm4, %xmm4
	cvttps2dq	%xmm0, %xmm11
	paddd	%xmm14, %xmm4
	paddd	%xmm15, %xmm11
	movdqa	%xmm11, %xmm0
	pcmpgtd	%xmm7, %xmm0
	movaps	%xmm12, %xmm3
	movdqa	%xmm4, %xmm12
	pcmpgtd	%xmm7, %xmm12
	pand	%xmm4, %xmm12
	pand	%xmm11, %xmm0
	movdqa	%xmm0, %xmm11
	pcmpgtd	%xmm5, %xmm11
	movdqa	%xmm5, %xmm1
	pand	%xmm11, %xmm1
	movdqa	%xmm12, %xmm4
	pcmpgtd	%xmm10, %xmm4
	movdqa	%xmm10, %xmm2
	pandn	%xmm0, %xmm11
	pand	%xmm4, %xmm2
	pandn	%xmm12, %xmm4
	movaps	%xmm3, %xmm12
	por	%xmm2, %xmm4
	por	%xmm1, %xmm11
	pshufd	$245, %xmm4, %xmm0              # xmm0 = xmm4[1,1,3,3]
	pmuludq	%xmm6, %xmm4
	pmuludq	%xmm13, %xmm0
	pshufd	$232, %xmm4, %xmm1              # xmm1 = xmm4[0,2,2,3]
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	punpckldq	%xmm0, %xmm1            # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	paddd	%xmm11, %xmm1
	movq	%rbx, %r13
	movd	%xmm1, %eax
	pshufd	$85, %xmm1, %xmm0               # xmm0 = xmm1[1,1,1,1]
	pshufd	$238, %xmm1, %xmm2              # xmm2 = xmm1[2,3,2,3]
	movd	%xmm0, %edx
	movd	%xmm2, %esi
	pshufd	$255, %xmm1, %xmm0              # xmm0 = xmm1[3,3,3,3]
	movd	%xmm0, %r11d
	movss	(%rdi,%r11,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm1            # xmm1 = mem[0],zero,zero,zero
	movss	(%rdi,%rax,4), %xmm2            # xmm2 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm4            # xmm4 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm1                    # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	unpcklps	%xmm4, %xmm2                    # xmm2 = xmm2[0],xmm4[0],xmm2[1],xmm4[1]
	unpcklpd	%xmm1, %xmm2                    # xmm2 = xmm2[0],xmm1[0]
	paddd	.LCPI0_3(%rip), %xmm15
	movupd	%xmm2, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	addq	$16, %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_612
# %bb.613:                              #   in Loop: Header=BB0_611 Depth=1
	cmpl	%ecx, %ebp
	movq	-120(%rsp), %rsi                # 8-byte Reload
	movaps	.LCPI0_7(%rip), %xmm2           # xmm2 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm3           # xmm3 = [-5.0E-1,-5.0E-1,u,u]
	movdqa	-64(%rsp), %xmm4                # 16-byte Reload
	jl	.LBB0_614
	jmp	.LBB0_623
	.p2align	4, 0x90
.LBB0_622:                              #   in Loop: Header=BB0_614 Depth=2
	imull	%ecx, %r8d
	addl	%ebx, %r8d
	movslq	%r8d, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_623
.LBB0_614:                              #   Parent Loop BB0_611 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r13), %eax
	movzbl	%ah, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm1
	punpckldq	%xmm1, %xmm0            # xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1]
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movd	%ebp, %xmm14
	punpcklqdq	%xmm4, %xmm14           # xmm14 = xmm14[0],xmm4[0]
	shufps	$226, %xmm4, %xmm14             # xmm14 = xmm14[2,0],xmm4[2,3]
	paddd	%xmm0, %xmm14
	pshufd	$85, %xmm14, %xmm0              # xmm0 = xmm14[1,1,1,1]
	movd	%xmm0, %eax
	cmpl	%r14d, %eax
	jl	.LBB0_616
# %bb.615:                              #   in Loop: Header=BB0_614 Depth=2
	movl	%r14d, %eax
.LBB0_616:                              #   in Loop: Header=BB0_614 Depth=2
	pshufd	$80, %xmm14, %xmm0              # xmm0 = xmm14[0,0,1,1]
	movmskpd	%xmm0, %r11d
	xorl	%r8d, %r8d
	movl	$0, %ebx
	testb	$2, %r11b
	je	.LBB0_617
# %bb.618:                              #   in Loop: Header=BB0_614 Depth=2
	movd	%xmm14, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_619
.LBB0_620:                              #   in Loop: Header=BB0_614 Depth=2
	testb	$1, %r11b
	jne	.LBB0_622
	jmp	.LBB0_621
	.p2align	4, 0x90
.LBB0_617:                              #   in Loop: Header=BB0_614 Depth=2
	movl	%eax, %ebx
	movd	%xmm14, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_620
.LBB0_619:                              #   in Loop: Header=BB0_614 Depth=2
	movl	%r9d, %eax
	testb	$1, %r11b
	jne	.LBB0_622
.LBB0_621:                              #   in Loop: Header=BB0_614 Depth=2
	movl	%eax, %r8d
	jmp	.LBB0_622
.LBB0_330:
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm7                # xmm7 = xmm0[0,0,0,0]
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm10               # xmm10 = xmm0[0,0,0,0]
	movl	%ecx, %r10d
	movl	%r8d, %eax
	movq	%rax, -80(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rax
	movq	%rax, -112(%rsp)                # 8-byte Spill
	movl	$16, %ebx
	xorl	%edx, %edx
	movdqa	%xmm0, -96(%rsp)                # 16-byte Spill
	pshufd	$245, %xmm0, %xmm0              # xmm0 = xmm0[1,1,3,3]
	movdqa	%xmm0, -16(%rsp)                # 16-byte Spill
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	-96(%rsp), %xmm5                # 16-byte Reload
	movaps	.LCPI0_1(%rip), %xmm6           # xmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	movaps	.LCPI0_2(%rip), %xmm8           # xmm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	pxor	%xmm9, %xmm9
	movdqa	-16(%rsp), %xmm13               # 16-byte Reload
	jmp	.LBB0_331
	.p2align	4, 0x90
.LBB0_343:                              #   in Loop: Header=BB0_331 Depth=1
	movq	-32(%rsp), %rdx                 # 8-byte Reload
	incq	%rdx
	movq	-112(%rsp), %rax                # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	movq	-48(%rsp), %rbx                 # 8-byte Reload
	addq	%rax, %rbx
	cmpq	-80(%rsp), %rdx                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_331:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_332 Depth 2
                                        #     Child Loop BB0_334 Depth 2
	movq	%rdx, -32(%rsp)                 # 8-byte Spill
	movd	%edx, %xmm0
	movdqa	%xmm0, -64(%rsp)                # 16-byte Spill
	pshufd	$0, %xmm0, %xmm14               # xmm14 = xmm0[0,0,0,0]
	movq	%rbx, -48(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm15          # xmm15 = [0,1,2,3]
	.p2align	4, 0x90
.LBB0_332:                              #   Parent Loop BB0_331 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm0
	movdqa	%xmm0, %xmm4
	psrld	$24, %xmm4
	psrld	$8, %xmm0
	pand	.LCPI0_6(%rip), %xmm0
	cvtdq2ps	%xmm4, %xmm4
	divps	%xmm6, %xmm4
	addps	%xmm8, %xmm4
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm6, %xmm0
	mulps	%xmm12, %xmm4
	addps	%xmm8, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	cvttps2dq	%xmm4, %xmm11
	paddd	%xmm14, %xmm0
	paddd	%xmm15, %xmm11
	movdqa	%xmm11, %xmm4
	pcmpgtd	%xmm9, %xmm4
	movaps	%xmm12, %xmm3
	movdqa	%xmm0, %xmm12
	pcmpgtd	%xmm9, %xmm12
	pand	%xmm0, %xmm12
	pand	%xmm11, %xmm4
	movdqa	%xmm4, %xmm11
	pcmpgtd	%xmm7, %xmm11
	movdqa	%xmm7, %xmm1
	pand	%xmm11, %xmm1
	movdqa	%xmm12, %xmm0
	pcmpgtd	%xmm10, %xmm0
	movdqa	%xmm10, %xmm2
	pandn	%xmm4, %xmm11
	pand	%xmm0, %xmm2
	pandn	%xmm12, %xmm0
	movaps	%xmm3, %xmm12
	por	%xmm2, %xmm0
	por	%xmm1, %xmm11
	pshufd	$245, %xmm0, %xmm1              # xmm1 = xmm0[1,1,3,3]
	pmuludq	%xmm5, %xmm0
	pmuludq	%xmm13, %xmm1
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	pshufd	$232, %xmm1, %xmm1              # xmm1 = xmm1[0,2,2,3]
	punpckldq	%xmm1, %xmm0            # xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1]
	paddd	%xmm11, %xmm0
	movq	%rbx, %r13
	movd	%xmm0, %eax
	pshufd	$85, %xmm0, %xmm1               # xmm1 = xmm0[1,1,1,1]
	pshufd	$238, %xmm0, %xmm2              # xmm2 = xmm0[2,3,2,3]
	movd	%xmm1, %edx
	movd	%xmm2, %esi
	pshufd	$255, %xmm0, %xmm0              # xmm0 = xmm0[3,3,3,3]
	movd	%xmm0, %r11d
	movss	(%rdi,%r11,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm1            # xmm1 = mem[0],zero,zero,zero
	movss	(%rdi,%rax,4), %xmm2            # xmm2 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm4            # xmm4 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm1                    # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	unpcklps	%xmm4, %xmm2                    # xmm2 = xmm2[0],xmm4[0],xmm2[1],xmm4[1]
	unpcklpd	%xmm1, %xmm2                    # xmm2 = xmm2[0],xmm1[0]
	paddd	.LCPI0_3(%rip), %xmm15
	movupd	%xmm2, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	addq	$16, %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_332
# %bb.333:                              #   in Loop: Header=BB0_331 Depth=1
	cmpl	%ecx, %ebp
	movq	-120(%rsp), %rsi                # 8-byte Reload
	movaps	.LCPI0_7(%rip), %xmm2           # xmm2 = [2.55E+2,2.55E+2,u,u]
	movaps	.LCPI0_8(%rip), %xmm3           # xmm3 = [-5.0E-1,-5.0E-1,u,u]
	movdqa	-64(%rsp), %xmm4                # 16-byte Reload
	jl	.LBB0_334
	jmp	.LBB0_343
	.p2align	4, 0x90
.LBB0_342:                              #   in Loop: Header=BB0_334 Depth=2
	imull	%ecx, %r8d
	addl	%ebx, %r8d
	movslq	%r8d, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_343
.LBB0_334:                              #   Parent Loop BB0_331 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r13), %eax
	movzbl	%ah, %edx
	shrl	$24, %eax
	movd	%eax, %xmm0
	movd	%edx, %xmm1
	punpckldq	%xmm0, %xmm1            # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
	cvtdq2ps	%xmm1, %xmm0
	divps	%xmm2, %xmm0
	addps	%xmm3, %xmm0
	mulps	%xmm12, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movd	%ebp, %xmm14
	punpcklqdq	%xmm4, %xmm14           # xmm14 = xmm14[0],xmm4[0]
	shufps	$226, %xmm4, %xmm14             # xmm14 = xmm14[2,0],xmm4[2,3]
	paddd	%xmm0, %xmm14
	pshufd	$85, %xmm14, %xmm0              # xmm0 = xmm14[1,1,1,1]
	movd	%xmm0, %eax
	cmpl	%r14d, %eax
	jl	.LBB0_336
# %bb.335:                              #   in Loop: Header=BB0_334 Depth=2
	movl	%r14d, %eax
.LBB0_336:                              #   in Loop: Header=BB0_334 Depth=2
	pshufd	$80, %xmm14, %xmm0              # xmm0 = xmm14[0,0,1,1]
	movmskpd	%xmm0, %r11d
	xorl	%r8d, %r8d
	movl	$0, %ebx
	testb	$2, %r11b
	je	.LBB0_337
# %bb.338:                              #   in Loop: Header=BB0_334 Depth=2
	movd	%xmm14, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_339
.LBB0_340:                              #   in Loop: Header=BB0_334 Depth=2
	testb	$1, %r11b
	jne	.LBB0_342
	jmp	.LBB0_341
	.p2align	4, 0x90
.LBB0_337:                              #   in Loop: Header=BB0_334 Depth=2
	movl	%eax, %ebx
	movd	%xmm14, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_340
.LBB0_339:                              #   in Loop: Header=BB0_334 Depth=2
	movl	%r9d, %eax
	testb	$1, %r11b
	jne	.LBB0_342
.LBB0_341:                              #   in Loop: Header=BB0_334 Depth=2
	movl	%eax, %r8d
	jmp	.LBB0_342
.LBB0_6:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	movaps	%xmm12, -96(%rsp)               # 16-byte Spill
	movd	%esi, %xmm2
	pshufd	$0, %xmm2, %xmm2                # xmm2 = xmm2[0,0,0,0]
	movd	%r9d, %xmm3
	pshufd	$0, %xmm3, %xmm8                # xmm8 = xmm3[0,0,0,0]
	movl	%ecx, %r10d
	movl	%r8d, %eax
	movq	%rax, -64(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm4
	pshufd	$0, %xmm4, %xmm0                # xmm0 = xmm4[0,0,0,0]
	leaq	(,%r10,4), %rax
	movq	%rax, -80(%rsp)                 # 8-byte Spill
	movl	$16, %ebx
	xorl	%r14d, %r14d
	pxor	%xmm9, %xmm9
	movdqa	%xmm0, -112(%rsp)               # 16-byte Spill
	pshufd	$245, %xmm0, %xmm10             # xmm10 = xmm0[1,1,3,3]
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	.LCPI0_3(%rip), %xmm11          # xmm11 = [4,4,4,4]
	jmp	.LBB0_7
	.p2align	4, 0x90
.LBB0_19:                               #   in Loop: Header=BB0_7 Depth=1
	incq	%r14
	movq	-80(%rsp), %rax                 # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	movq	-48(%rsp), %rbx                 # 8-byte Reload
	addq	%rax, %rbx
	cmpq	-64(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_7:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_8 Depth 2
                                        #     Child Loop BB0_10 Depth 2
	movd	%r14d, %xmm14
	pshufd	$0, %xmm14, %xmm14              # xmm14 = xmm14[0,0,0,0]
	movq	%rbx, -48(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm15          # xmm15 = [0,1,2,3]
	movaps	.LCPI0_2(%rip), %xmm1           # xmm1 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movaps	-96(%rsp), %xmm4                # 16-byte Reload
	movdqa	-112(%rsp), %xmm0               # 16-byte Reload
	.p2align	4, 0x90
.LBB0_8:                                #   Parent Loop BB0_7 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm5
	psrld	$16, %xmm5
	pand	.LCPI0_6(%rip), %xmm5
	cvtdq2ps	%xmm5, %xmm5
	divps	.LCPI0_1(%rip), %xmm5
	addps	%xmm1, %xmm5
	mulps	%xmm4, %xmm5
	cvttps2dq	%xmm5, %xmm5
	movdqa	%xmm5, %xmm13
	paddd	%xmm15, %xmm13
	paddd	%xmm14, %xmm5
	movdqa	%xmm13, %xmm12
	pcmpgtd	%xmm9, %xmm12
	movdqa	%xmm5, %xmm7
	pcmpgtd	%xmm9, %xmm7
	pand	%xmm5, %xmm7
	pand	%xmm13, %xmm12
	movdqa	%xmm12, %xmm5
	pcmpgtd	%xmm2, %xmm5
	movdqa	%xmm2, %xmm13
	pand	%xmm5, %xmm13
	movdqa	%xmm7, %xmm6
	pcmpgtd	%xmm8, %xmm6
	movdqa	%xmm8, %xmm3
	pandn	%xmm12, %xmm5
	pand	%xmm6, %xmm3
	pandn	%xmm7, %xmm6
	por	%xmm3, %xmm6
	por	%xmm13, %xmm5
	pshufd	$245, %xmm6, %xmm3              # xmm3 = xmm6[1,1,3,3]
	pmuludq	%xmm0, %xmm6
	pmuludq	%xmm10, %xmm3
	pshufd	$232, %xmm6, %xmm6              # xmm6 = xmm6[0,2,2,3]
	pshufd	$232, %xmm3, %xmm3              # xmm3 = xmm3[0,2,2,3]
	punpckldq	%xmm3, %xmm6            # xmm6 = xmm6[0],xmm3[0],xmm6[1],xmm3[1]
	paddd	%xmm5, %xmm6
	movq	%rbx, %r13
	movd	%xmm6, %eax
	pshufd	$85, %xmm6, %xmm3               # xmm3 = xmm6[1,1,1,1]
	pshufd	$238, %xmm6, %xmm5              # xmm5 = xmm6[2,3,2,3]
	movd	%xmm3, %edx
	movd	%xmm5, %r11d
	pshufd	$255, %xmm6, %xmm3              # xmm3 = xmm6[3,3,3,3]
	movd	%xmm3, %ebx
	movss	(%rdi,%rbx,4), %xmm3            # xmm3 = mem[0],zero,zero,zero
	movss	(%rdi,%r11,4), %xmm5            # xmm5 = mem[0],zero,zero,zero
	movss	(%rdi,%rax,4), %xmm6            # xmm6 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm7            # xmm7 = mem[0],zero,zero,zero
	unpcklps	%xmm3, %xmm5                    # xmm5 = xmm5[0],xmm3[0],xmm5[1],xmm3[1]
	unpcklps	%xmm7, %xmm6                    # xmm6 = xmm6[0],xmm7[0],xmm6[1],xmm7[1]
	movlhps	%xmm5, %xmm6                    # xmm6 = xmm6[0],xmm5[0]
	paddd	%xmm11, %xmm15
	movups	%xmm6, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	leaq	16(%r13), %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_8
# %bb.9:                                #   in Loop: Header=BB0_7 Depth=1
	cmpl	%ecx, %ebp
	movaps	-32(%rsp), %xmm0                # 16-byte Reload
	movss	.LCPI0_4(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	movss	.LCPI0_5(%rip), %xmm4           # xmm4 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jl	.LBB0_10
	jmp	.LBB0_19
	.p2align	4, 0x90
.LBB0_18:                               #   in Loop: Header=BB0_10 Depth=2
	imull	%ecx, %ebx
	addl	%r11d, %ebx
	movslq	%ebx, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-120(%rsp), %rdx                # 8-byte Reload
	movl	%eax, (%rdx,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_19
.LBB0_10:                               #   Parent Loop BB0_7 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rax                # 8-byte Reload
	movzbl	2(%rax,%r13), %eax
	xorps	%xmm3, %xmm3
	cvtsi2ss	%eax, %xmm3
	divss	%xmm1, %xmm3
	addss	%xmm4, %xmm3
	mulss	%xmm0, %xmm3
	cvttss2si	%xmm3, %r8d
	leal	(%r8,%rbp), %edx
	movl	%edx, %eax
	cmpl	%esi, %edx
	jge	.LBB0_11
# %bb.12:                               #   in Loop: Header=BB0_10 Depth=2
	xorl	%ebx, %ebx
	movl	$0, %r11d
	testl	%edx, %edx
	jns	.LBB0_13
.LBB0_14:                               #   in Loop: Header=BB0_10 Depth=2
	addl	%r14d, %r8d
	movl	%r8d, %eax
	cmpl	%r9d, %r8d
	jge	.LBB0_15
.LBB0_16:                               #   in Loop: Header=BB0_10 Depth=2
	testl	%r8d, %r8d
	js	.LBB0_18
	jmp	.LBB0_17
	.p2align	4, 0x90
.LBB0_11:                               #   in Loop: Header=BB0_10 Depth=2
	movl	%esi, %eax
	xorl	%ebx, %ebx
	movl	$0, %r11d
	testl	%edx, %edx
	js	.LBB0_14
.LBB0_13:                               #   in Loop: Header=BB0_10 Depth=2
	movl	%eax, %r11d
	addl	%r14d, %r8d
	movl	%r8d, %eax
	cmpl	%r9d, %r8d
	jl	.LBB0_16
.LBB0_15:                               #   in Loop: Header=BB0_10 Depth=2
	movl	%r9d, %eax
	testl	%r8d, %r8d
	js	.LBB0_18
.LBB0_17:                               #   in Loop: Header=BB0_10 Depth=2
	movl	%eax, %ebx
	jmp	.LBB0_18
.LBB0_192:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	movaps	%xmm12, (%rsp)                  # 16-byte Spill
	movd	%edx, %xmm0
	pshufd	$0, %xmm0, %xmm13               # xmm13 = xmm0[0,0,0,0]
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm4                # xmm4 = xmm0[0,0,0,0]
	movl	%ecx, %r10d
	movl	%r8d, %eax
	movq	%rax, -80(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rax
	movq	%rax, -112(%rsp)                # 8-byte Spill
	movl	$16, %ebx
	xorl	%r14d, %r14d
	movdqa	%xmm0, -96(%rsp)                # 16-byte Spill
	pshufd	$245, %xmm0, %xmm0              # xmm0 = xmm0[1,1,3,3]
	movdqa	%xmm0, -16(%rsp)                # 16-byte Spill
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	-96(%rsp), %xmm6                # 16-byte Reload
	movdqa	.LCPI0_6(%rip), %xmm7           # xmm7 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	movaps	.LCPI0_1(%rip), %xmm8           # xmm8 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	movaps	.LCPI0_2(%rip), %xmm9           # xmm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	pxor	%xmm10, %xmm10
	movaps	(%rsp), %xmm14                  # 16-byte Reload
	jmp	.LBB0_193
	.p2align	4, 0x90
.LBB0_205:                              #   in Loop: Header=BB0_193 Depth=1
	incq	%r14
	movq	-112(%rsp), %rax                # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	movq	-64(%rsp), %rbx                 # 8-byte Reload
	addq	%rax, %rbx
	cmpq	-80(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_193:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_194 Depth 2
                                        #     Child Loop BB0_196 Depth 2
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movdqa	%xmm0, -48(%rsp)                # 16-byte Spill
	movq	%rbx, -64(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm15          # xmm15 = [0,1,2,3]
	movdqa	-16(%rsp), %xmm1                # 16-byte Reload
	.p2align	4, 0x90
.LBB0_194:                              #   Parent Loop BB0_193 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm5
	movdqa	%xmm5, %xmm0
	psrld	$8, %xmm5
	psrld	$16, %xmm0
	pand	%xmm7, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	%xmm8, %xmm0
	addps	%xmm9, %xmm0
	pand	%xmm7, %xmm5
	cvtdq2ps	%xmm5, %xmm5
	divps	%xmm8, %xmm5
	mulps	%xmm14, %xmm0
	addps	%xmm9, %xmm5
	mulps	%xmm14, %xmm5
	cvttps2dq	%xmm5, %xmm5
	cvttps2dq	%xmm0, %xmm11
	paddd	-48(%rsp), %xmm5                # 16-byte Folded Reload
	paddd	%xmm15, %xmm11
	movdqa	%xmm11, %xmm0
	pcmpgtd	%xmm10, %xmm0
	movdqa	%xmm5, %xmm12
	pcmpgtd	%xmm10, %xmm12
	pand	%xmm5, %xmm12
	pand	%xmm11, %xmm0
	movdqa	%xmm0, %xmm11
	pcmpgtd	%xmm13, %xmm11
	movdqa	%xmm13, %xmm2
	pand	%xmm11, %xmm2
	movdqa	%xmm12, %xmm5
	pcmpgtd	%xmm4, %xmm5
	movdqa	%xmm4, %xmm3
	pandn	%xmm0, %xmm11
	pand	%xmm5, %xmm3
	pandn	%xmm12, %xmm5
	por	%xmm3, %xmm5
	por	%xmm2, %xmm11
	pshufd	$245, %xmm5, %xmm0              # xmm0 = xmm5[1,1,3,3]
	pmuludq	%xmm6, %xmm5
	pmuludq	%xmm1, %xmm0
	pshufd	$232, %xmm5, %xmm2              # xmm2 = xmm5[0,2,2,3]
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	punpckldq	%xmm0, %xmm2            # xmm2 = xmm2[0],xmm0[0],xmm2[1],xmm0[1]
	paddd	%xmm11, %xmm2
	movq	%rbx, %r13
	movd	%xmm2, %eax
	pshufd	$85, %xmm2, %xmm0               # xmm0 = xmm2[1,1,1,1]
	pshufd	$238, %xmm2, %xmm3              # xmm3 = xmm2[2,3,2,3]
	movd	%xmm0, %esi
	movd	%xmm3, %r11d
	pshufd	$255, %xmm2, %xmm0              # xmm0 = xmm2[3,3,3,3]
	movd	%xmm0, %ebx
	movss	(%rdi,%rbx,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%r11,4), %xmm2            # xmm2 = mem[0],zero,zero,zero
	movss	(%rdi,%rax,4), %xmm3            # xmm3 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm5            # xmm5 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm2                    # xmm2 = xmm2[0],xmm0[0],xmm2[1],xmm0[1]
	unpcklps	%xmm5, %xmm3                    # xmm3 = xmm3[0],xmm5[0],xmm3[1],xmm5[1]
	movlhps	%xmm2, %xmm3                    # xmm3 = xmm3[0],xmm2[0]
	paddd	.LCPI0_3(%rip), %xmm15
	movups	%xmm3, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	leaq	16(%r13), %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_194
# %bb.195:                              #   in Loop: Header=BB0_193 Depth=1
	cmpl	%ecx, %ebp
	movaps	-32(%rsp), %xmm2                # 16-byte Reload
	movss	.LCPI0_4(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	movss	.LCPI0_5(%rip), %xmm3           # xmm3 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jl	.LBB0_196
	jmp	.LBB0_205
	.p2align	4, 0x90
.LBB0_204:                              #   in Loop: Header=BB0_196 Depth=2
	imull	%ecx, %r8d
	addl	%ebx, %r8d
	movslq	%r8d, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-120(%rsp), %rsi                # 8-byte Reload
	movl	%eax, (%rsi,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_205
.LBB0_196:                              #   Parent Loop BB0_193 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r13), %eax
	movl	%eax, %esi
	shrl	$16, %esi
	movzbl	%sil, %esi
	xorps	%xmm0, %xmm0
	cvtsi2ss	%esi, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm3, %xmm0
	mulss	%xmm2, %xmm0
	cvttss2si	%xmm0, %r11d
	addl	%ebp, %r11d
	movl	%r11d, %esi
	cmpl	%edx, %r11d
	jl	.LBB0_198
# %bb.197:                              #   in Loop: Header=BB0_196 Depth=2
	movl	%edx, %esi
.LBB0_198:                              #   in Loop: Header=BB0_196 Depth=2
	xorl	%r8d, %r8d
	movl	$0, %ebx
	testl	%r11d, %r11d
	js	.LBB0_200
# %bb.199:                              #   in Loop: Header=BB0_196 Depth=2
	movl	%esi, %ebx
.LBB0_200:                              #   in Loop: Header=BB0_196 Depth=2
	movzbl	%ah, %eax
	xorps	%xmm0, %xmm0
	cvtsi2ss	%eax, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm3, %xmm0
	mulss	%xmm2, %xmm0
	cvttss2si	%xmm0, %eax
	addl	%r14d, %eax
	movl	%eax, %esi
	cmpl	%r9d, %eax
	jl	.LBB0_202
# %bb.201:                              #   in Loop: Header=BB0_196 Depth=2
	movl	%r9d, %esi
.LBB0_202:                              #   in Loop: Header=BB0_196 Depth=2
	testl	%eax, %eax
	js	.LBB0_204
# %bb.203:                              #   in Loop: Header=BB0_196 Depth=2
	movl	%esi, %r8d
	jmp	.LBB0_204
.LBB0_52:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	movaps	%xmm12, (%rsp)                  # 16-byte Spill
	movd	%r11d, %xmm2
	pshufd	$0, %xmm2, %xmm6                # xmm6 = xmm2[0,0,0,0]
	movd	%r9d, %xmm3
	pshufd	$0, %xmm3, %xmm7                # xmm7 = xmm3[0,0,0,0]
	movl	%ecx, %r10d
	movl	%r8d, %eax
	movq	%rax, -80(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm4
	pshufd	$0, %xmm4, %xmm0                # xmm0 = xmm4[0,0,0,0]
	leaq	(,%r10,4), %rax
	movq	%rax, -112(%rsp)                # 8-byte Spill
	movl	$16, %ebx
	xorl	%r14d, %r14d
	movdqa	%xmm0, -96(%rsp)                # 16-byte Spill
	pshufd	$245, %xmm0, %xmm0              # xmm0 = xmm0[1,1,3,3]
	movdqa	%xmm0, -16(%rsp)                # 16-byte Spill
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	.LCPI0_6(%rip), %xmm4           # xmm4 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	movaps	.LCPI0_1(%rip), %xmm8           # xmm8 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	movaps	.LCPI0_2(%rip), %xmm9           # xmm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	pxor	%xmm10, %xmm10
	jmp	.LBB0_53
	.p2align	4, 0x90
.LBB0_65:                               #   in Loop: Header=BB0_53 Depth=1
	incq	%r14
	movq	-112(%rsp), %rax                # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	movq	-64(%rsp), %rbx                 # 8-byte Reload
	addq	%rax, %rbx
	cmpq	-80(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_53:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_54 Depth 2
                                        #     Child Loop BB0_56 Depth 2
	movd	%r14d, %xmm14
	pshufd	$0, %xmm14, %xmm0               # xmm0 = xmm14[0,0,0,0]
	movdqa	%xmm0, -48(%rsp)                # 16-byte Spill
	movq	%rbx, -64(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm15          # xmm15 = [0,1,2,3]
	movdqa	-96(%rsp), %xmm0                # 16-byte Reload
	movdqa	-16(%rsp), %xmm1                # 16-byte Reload
	movaps	(%rsp), %xmm14                  # 16-byte Reload
	.p2align	4, 0x90
.LBB0_54:                               #   Parent Loop BB0_53 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm11
	movdqa	%xmm11, %xmm5
	psrld	$16, %xmm11
	psrld	$8, %xmm5
	pand	%xmm4, %xmm5
	cvtdq2ps	%xmm5, %xmm5
	divps	%xmm8, %xmm5
	addps	%xmm9, %xmm5
	pand	%xmm4, %xmm11
	cvtdq2ps	%xmm11, %xmm11
	divps	%xmm8, %xmm11
	mulps	%xmm14, %xmm5
	addps	%xmm9, %xmm11
	mulps	%xmm14, %xmm11
	cvttps2dq	%xmm11, %xmm11
	cvttps2dq	%xmm5, %xmm12
	paddd	-48(%rsp), %xmm11               # 16-byte Folded Reload
	paddd	%xmm15, %xmm12
	movdqa	%xmm12, %xmm5
	pcmpgtd	%xmm10, %xmm5
	movdqa	%xmm11, %xmm13
	pcmpgtd	%xmm10, %xmm13
	pand	%xmm11, %xmm13
	pand	%xmm12, %xmm5
	movdqa	%xmm5, %xmm12
	pcmpgtd	%xmm6, %xmm12
	movdqa	%xmm6, %xmm2
	pand	%xmm12, %xmm2
	movdqa	%xmm13, %xmm11
	pcmpgtd	%xmm7, %xmm11
	movdqa	%xmm7, %xmm3
	pandn	%xmm5, %xmm12
	pand	%xmm11, %xmm3
	pandn	%xmm13, %xmm11
	por	%xmm3, %xmm11
	por	%xmm2, %xmm12
	pshufd	$245, %xmm11, %xmm2             # xmm2 = xmm11[1,1,3,3]
	pmuludq	%xmm0, %xmm11
	pmuludq	%xmm1, %xmm2
	pshufd	$232, %xmm11, %xmm3             # xmm3 = xmm11[0,2,2,3]
	pshufd	$232, %xmm2, %xmm2              # xmm2 = xmm2[0,2,2,3]
	punpckldq	%xmm2, %xmm3            # xmm3 = xmm3[0],xmm2[0],xmm3[1],xmm2[1]
	paddd	%xmm12, %xmm3
	movq	%rbx, %r13
	movd	%xmm3, %eax
	pshufd	$85, %xmm3, %xmm2               # xmm2 = xmm3[1,1,1,1]
	pshufd	$238, %xmm3, %xmm5              # xmm5 = xmm3[2,3,2,3]
	movd	%xmm2, %edx
	movd	%xmm5, %esi
	pshufd	$255, %xmm3, %xmm2              # xmm2 = xmm3[3,3,3,3]
	movd	%xmm2, %ebx
	movss	(%rdi,%rbx,4), %xmm2            # xmm2 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm3            # xmm3 = mem[0],zero,zero,zero
	movss	(%rdi,%rax,4), %xmm5            # xmm5 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm11           # xmm11 = mem[0],zero,zero,zero
	unpcklps	%xmm2, %xmm3                    # xmm3 = xmm3[0],xmm2[0],xmm3[1],xmm2[1]
	unpcklps	%xmm11, %xmm5                   # xmm5 = xmm5[0],xmm11[0],xmm5[1],xmm11[1]
	movlhps	%xmm3, %xmm5                    # xmm5 = xmm5[0],xmm3[0]
	paddd	.LCPI0_3(%rip), %xmm15
	movups	%xmm5, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	leaq	16(%r13), %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_54
# %bb.55:                               #   in Loop: Header=BB0_53 Depth=1
	cmpl	%ecx, %ebp
	movaps	-32(%rsp), %xmm3                # 16-byte Reload
	movss	.LCPI0_4(%rip), %xmm0           # xmm0 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	movss	.LCPI0_5(%rip), %xmm1           # xmm1 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jl	.LBB0_56
	jmp	.LBB0_65
	.p2align	4, 0x90
.LBB0_64:                               #   in Loop: Header=BB0_56 Depth=2
	imull	%ecx, %r8d
	addl	%ebx, %r8d
	movslq	%r8d, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rsi,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_65
.LBB0_56:                               #   Parent Loop BB0_53 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rax                # 8-byte Reload
	movl	(%rax,%r13), %eax
	movzbl	%ah, %edx
	xorps	%xmm2, %xmm2
	cvtsi2ss	%edx, %xmm2
	divss	%xmm0, %xmm2
	addss	%xmm1, %xmm2
	mulss	%xmm3, %xmm2
	cvttss2si	%xmm2, %edx
	addl	%ebp, %edx
	movl	%edx, %esi
	cmpl	%r11d, %edx
	jl	.LBB0_58
# %bb.57:                               #   in Loop: Header=BB0_56 Depth=2
	movl	%r11d, %esi
.LBB0_58:                               #   in Loop: Header=BB0_56 Depth=2
	xorl	%r8d, %r8d
	movl	$0, %ebx
	testl	%edx, %edx
	js	.LBB0_60
# %bb.59:                               #   in Loop: Header=BB0_56 Depth=2
	movl	%esi, %ebx
.LBB0_60:                               #   in Loop: Header=BB0_56 Depth=2
	shrl	$16, %eax
	movzbl	%al, %eax
	xorps	%xmm2, %xmm2
	cvtsi2ss	%eax, %xmm2
	divss	%xmm0, %xmm2
	addss	%xmm1, %xmm2
	mulss	%xmm3, %xmm2
	cvttss2si	%xmm2, %eax
	addl	%r14d, %eax
	movl	%eax, %edx
	cmpl	%r9d, %eax
	jl	.LBB0_62
# %bb.61:                               #   in Loop: Header=BB0_56 Depth=2
	movl	%r9d, %edx
.LBB0_62:                               #   in Loop: Header=BB0_56 Depth=2
	testl	%eax, %eax
	movq	-120(%rsp), %rsi                # 8-byte Reload
	js	.LBB0_64
# %bb.63:                               #   in Loop: Header=BB0_56 Depth=2
	movl	%edx, %r8d
	jmp	.LBB0_64
.LBB0_238:
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	movaps	%xmm12, -96(%rsp)               # 16-byte Spill
	movd	%eax, %xmm0
	pshufd	$0, %xmm0, %xmm2                # xmm2 = xmm0[0,0,0,0]
	movd	%r9d, %xmm0
	pshufd	$0, %xmm0, %xmm7                # xmm7 = xmm0[0,0,0,0]
	movl	%ecx, %r10d
	movl	%r8d, %edx
	movq	%rdx, -64(%rsp)                 # 8-byte Spill
	movd	%ecx, %xmm0
	pshufd	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	leaq	(,%r10,4), %rdx
	movq	%rdx, -80(%rsp)                 # 8-byte Spill
	movl	$16, %ebx
	xorl	%r14d, %r14d
	pxor	%xmm9, %xmm9
	movdqa	%xmm0, -112(%rsp)               # 16-byte Spill
	pshufd	$245, %xmm0, %xmm10             # xmm10 = xmm0[1,1,3,3]
	movq	-128(%rsp), %r15                # 8-byte Reload
	movq	-120(%rsp), %r12                # 8-byte Reload
	movdqa	-112(%rsp), %xmm8               # 16-byte Reload
	movdqa	.LCPI0_3(%rip), %xmm11          # xmm11 = [4,4,4,4]
	jmp	.LBB0_239
	.p2align	4, 0x90
.LBB0_251:                              #   in Loop: Header=BB0_239 Depth=1
	incq	%r14
	movq	-80(%rsp), %rdx                 # 8-byte Reload
	addq	%rdx, %r12
	addq	%rdx, %r15
	movq	-48(%rsp), %rbx                 # 8-byte Reload
	addq	%rdx, %rbx
	cmpq	-64(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_746
.LBB0_239:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_240 Depth 2
                                        #     Child Loop BB0_242 Depth 2
	movd	%r14d, %xmm0
	pshufd	$0, %xmm0, %xmm14               # xmm14 = xmm0[0,0,0,0]
	movq	%rbx, -48(%rsp)                 # 8-byte Spill
	xorl	%ebp, %ebp
	movdqa	.LCPI0_0(%rip), %xmm15          # xmm15 = [0,1,2,3]
	movaps	.LCPI0_2(%rip), %xmm1           # xmm1 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movaps	-96(%rsp), %xmm4                # 16-byte Reload
	.p2align	4, 0x90
.LBB0_240:                              #   Parent Loop BB0_239 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %r8
	movdqu	(%r15,%rbp,4), %xmm0
	psrld	$8, %xmm0
	pand	.LCPI0_6(%rip), %xmm0
	cvtdq2ps	%xmm0, %xmm0
	divps	.LCPI0_1(%rip), %xmm0
	addps	%xmm1, %xmm0
	mulps	%xmm4, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm0, %xmm12
	paddd	%xmm15, %xmm12
	paddd	%xmm14, %xmm0
	movdqa	%xmm12, %xmm5
	pcmpgtd	%xmm9, %xmm5
	movdqa	%xmm0, %xmm6
	pcmpgtd	%xmm9, %xmm6
	pand	%xmm0, %xmm6
	pand	%xmm12, %xmm5
	movdqa	%xmm5, %xmm0
	pcmpgtd	%xmm2, %xmm0
	movdqa	%xmm2, %xmm12
	pand	%xmm0, %xmm12
	movdqa	%xmm6, %xmm13
	pcmpgtd	%xmm7, %xmm13
	movdqa	%xmm7, %xmm3
	pandn	%xmm5, %xmm0
	pand	%xmm13, %xmm3
	pandn	%xmm6, %xmm13
	por	%xmm3, %xmm13
	por	%xmm12, %xmm0
	pshufd	$245, %xmm13, %xmm3             # xmm3 = xmm13[1,1,3,3]
	pmuludq	%xmm8, %xmm13
	pmuludq	%xmm10, %xmm3
	pshufd	$232, %xmm13, %xmm5             # xmm5 = xmm13[0,2,2,3]
	pshufd	$232, %xmm3, %xmm3              # xmm3 = xmm3[0,2,2,3]
	punpckldq	%xmm3, %xmm5            # xmm5 = xmm5[0],xmm3[0],xmm5[1],xmm3[1]
	paddd	%xmm0, %xmm5
	movq	%rbx, %r13
	movd	%xmm5, %edx
	pshufd	$85, %xmm5, %xmm0               # xmm0 = xmm5[1,1,1,1]
	pshufd	$238, %xmm5, %xmm3              # xmm3 = xmm5[2,3,2,3]
	movd	%xmm0, %esi
	movd	%xmm3, %r11d
	pshufd	$255, %xmm5, %xmm0              # xmm0 = xmm5[3,3,3,3]
	movd	%xmm0, %ebx
	movss	(%rdi,%rbx,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	(%rdi,%r11,4), %xmm3            # xmm3 = mem[0],zero,zero,zero
	movss	(%rdi,%rdx,4), %xmm5            # xmm5 = mem[0],zero,zero,zero
	movss	(%rdi,%rsi,4), %xmm6            # xmm6 = mem[0],zero,zero,zero
	unpcklps	%xmm0, %xmm3                    # xmm3 = xmm3[0],xmm0[0],xmm3[1],xmm0[1]
	unpcklps	%xmm6, %xmm5                    # xmm5 = xmm5[0],xmm6[0],xmm5[1],xmm6[1]
	movlhps	%xmm3, %xmm5                    # xmm5 = xmm5[0],xmm3[0]
	paddd	%xmm11, %xmm15
	movups	%xmm5, (%r12,%rbp,4)
	addq	$4, %rbp
	addq	$8, %r8
	leaq	16(%r13), %rbx
	cmpq	%r10, %r8
	jbe	.LBB0_240
# %bb.241:                              #   in Loop: Header=BB0_239 Depth=1
	cmpl	%ecx, %ebp
	movaps	-32(%rsp), %xmm3                # 16-byte Reload
	movss	.LCPI0_4(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	movss	.LCPI0_5(%rip), %xmm4           # xmm4 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jl	.LBB0_242
	jmp	.LBB0_251
	.p2align	4, 0x90
.LBB0_250:                              #   in Loop: Header=BB0_242 Depth=2
	imull	%ecx, %ebx
	addl	%r11d, %ebx
	movslq	%ebx, %rdx
	movl	(%rdi,%rdx,4), %edx
	movl	%edx, (%rsi,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_251
.LBB0_242:                              #   Parent Loop BB0_239 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-128(%rsp), %rdx                # 8-byte Reload
	movzbl	1(%rdx,%r13), %edx
	xorps	%xmm0, %xmm0
	cvtsi2ss	%edx, %xmm0
	divss	%xmm1, %xmm0
	addss	%xmm4, %xmm0
	mulss	%xmm3, %xmm0
	cvttss2si	%xmm0, %r8d
	leal	(%r8,%rbp), %edx
	movl	%edx, %esi
	cmpl	%eax, %edx
	jge	.LBB0_243
# %bb.244:                              #   in Loop: Header=BB0_242 Depth=2
	xorl	%ebx, %ebx
	movl	$0, %r11d
	testl	%edx, %edx
	jns	.LBB0_245
.LBB0_246:                              #   in Loop: Header=BB0_242 Depth=2
	addl	%r14d, %r8d
	movl	%r8d, %edx
	cmpl	%r9d, %r8d
	jge	.LBB0_247
.LBB0_248:                              #   in Loop: Header=BB0_242 Depth=2
	testl	%r8d, %r8d
	movq	-120(%rsp), %rsi                # 8-byte Reload
	js	.LBB0_250
	jmp	.LBB0_249
	.p2align	4, 0x90
.LBB0_243:                              #   in Loop: Header=BB0_242 Depth=2
	movl	%eax, %esi
	xorl	%ebx, %ebx
	movl	$0, %r11d
	testl	%edx, %edx
	js	.LBB0_246
.LBB0_245:                              #   in Loop: Header=BB0_242 Depth=2
	movl	%esi, %r11d
	addl	%r14d, %r8d
	movl	%r8d, %edx
	cmpl	%r9d, %r8d
	jl	.LBB0_248
.LBB0_247:                              #   in Loop: Header=BB0_242 Depth=2
	movl	%r9d, %edx
	testl	%r8d, %r8d
	movq	-120(%rsp), %rsi                # 8-byte Reload
	js	.LBB0_250
.LBB0_249:                              #   in Loop: Header=BB0_242 Depth=2
	movl	%edx, %ebx
	jmp	.LBB0_250
.LBB0_746:
	addq	$56, %rsp
	CFI_DEF_CFA_OFFSET(56)
	popq	%rbx
	CFI_DEF_CFA_OFFSET(48)
	popq	%r12
	CFI_DEF_CFA_OFFSET(40)
	popq	%r13
	CFI_DEF_CFA_OFFSET(32)
	popq	%r14
	CFI_DEF_CFA_OFFSET(24)
	popq	%r15
	CFI_DEF_CFA_OFFSET(16)
	popq	%rbp
	CFI_DEF_CFA_OFFSET(8)
	retq
.Lfunc_end0:
// SIZE(SYM(ksvgDisplacementMapApplySse2))
	CFI_END
#if defined(__APPLE__)
	.section __TEXT,__const
#else
	.section	.rodata,"a",@progbits
#endif
	.p2align	2, 0x0
.LJTI0_0:
	.long	.LBB0_2-.LJTI0_0
	.long	.LBB0_188-.LJTI0_0
	.long	.LBB0_374-.LJTI0_0
	.long	.LBB0_560-.LJTI0_0
.LJTI0_1:
	.long	.LBB0_562-.LJTI0_1
	.long	.LBB0_608-.LJTI0_1
	.long	.LBB0_654-.LJTI0_1
	.long	.LBB0_700-.LJTI0_1
.LJTI0_2:
	.long	.LBB0_376-.LJTI0_2
	.long	.LBB0_422-.LJTI0_2
	.long	.LBB0_468-.LJTI0_2
	.long	.LBB0_514-.LJTI0_2
.LJTI0_3:
	.long	.LBB0_190-.LJTI0_3
	.long	.LBB0_236-.LJTI0_3
	.long	.LBB0_282-.LJTI0_3
	.long	.LBB0_328-.LJTI0_3
.LJTI0_4:
	.long	.LBB0_4-.LJTI0_4
	.long	.LBB0_50-.LJTI0_4
	.long	.LBB0_96-.LJTI0_4
	.long	.LBB0_142-.LJTI0_4
                                        # -- End function
	.ident	"clang version 17.0.0 (https://github.com/swiftlang/llvm-project.git 10999b6d034fe318f3d56c83bddb6572593a8bb0)"
#if !defined(__APPLE__)
	.section	".note.GNU-stack","",@progbits
#endif
	.addrsig
