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
	.file	"ksvgConvolveApplyInteriorSse2I386.cpp"
	.section	.rodata.cst4,"aM",@progbits,4
	.p2align	2, 0x0                          # -- Begin function ksvgConvolveApplyInteriorSse2I386
.LCPI0_0:
	.long	0x437f0000                      # float 255
	.section	.rodata.cst16,"aM",@progbits,16
	.p2align	4, 0x0
.LCPI0_1:
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
.LCPI0_2:
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
.LCPI0_3:
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
.LCPI0_4:
	.zero	16
	.text
	.globl	SYM(ksvgConvolveApplyInteriorSse2)
	.p2align	4, 0x90
TYPE(SYM(ksvgConvolveApplyInteriorSse2), @function)
SYM(ksvgConvolveApplyInteriorSse2):      # @ksvgConvolveApplyInteriorSse2
	.cfi_startproc
# %bb.0:
	pushl	%ebp
	.cfi_def_cfa_offset 8
	pushl	%ebx
	.cfi_def_cfa_offset 12
	pushl	%edi
	.cfi_def_cfa_offset 16
	pushl	%esi
	.cfi_def_cfa_offset 20
	subl	$92, %esp
	.cfi_def_cfa_offset 112
	.cfi_offset %esi, -20
	.cfi_offset %edi, -16
	.cfi_offset %ebx, -12
	.cfi_offset %ebp, -8
	movl	140(%esp), %ecx
	movl	132(%esp), %esi
	movl	120(%esp), %edx
	movl	124(%esp), %eax
	subl	%esi, %edx
	leal	(%edx,%ecx), %ebp
	incl	%ebp
	subl	136(%esp), %eax
	leal	1(%eax), %edi
	testl	%edi, %edi
	jle	.LBB0_27
# %bb.1:
	incl	%edx
	cmpl	$4, %edx
	jge	.LBB0_2
.LBB0_27:
	andl	$-4, %ebp
	movl	%ebp, %eax
	addl	$92, %esp
	.cfi_def_cfa_offset 20
	popl	%esi
	.cfi_def_cfa_offset 16
	popl	%edi
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_def_cfa_offset 4
	retl
.LBB0_2:
	.cfi_def_cfa_offset 112
	movl	156(%esp), %edx
	movl	144(%esp), %edi
	movss	152(%esp), %xmm0                # xmm0 = mem[0],zero,zero,zero
	addl	%edi, %eax
	incl	%eax
	movl	%eax, 32(%esp)                  # 4-byte Spill
	movss	148(%esp), %xmm1                # xmm1 = mem[0],zero,zero,zero
	shufps	$0, %xmm1, %xmm1                # xmm1 = xmm1[0,0,0,0]
	movaps	%xmm1, 48(%esp)                 # 16-byte Spill
	mulss	.LCPI0_0, %xmm0
	shufps	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movaps	%xmm0, 64(%esp)                 # 16-byte Spill
	leal	4(%ecx), %eax
	movl	%eax, 28(%esp)                  # 4-byte Spill
	movaps	.LCPI0_1, %xmm2                 # xmm2 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	leal	(,%esi,4), %eax
	movl	%eax, 24(%esp)                  # 4-byte Spill
	movl	120(%esp), %eax
	leal	(,%eax,4), %ebx
	movl	%edi, %eax
	movl	112(%esp), %edi
	movl	%ebp, 16(%esp)                  # 4-byte Spill
	jmp	.LBB0_3
	.p2align	4, 0x90
.LBB0_26:                               #   in Loop: Header=BB0_3 Depth=1
	movl	36(%esp), %eax                  # 4-byte Reload
	incl	%eax
	movl	12(%esp), %edi                  # 4-byte Reload
	addl	%ebx, %edi
	cmpl	32(%esp), %eax                  # 4-byte Folded Reload
	jge	.LBB0_27
.LBB0_3:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_4 Depth 2
                                        #       Child Loop BB0_9 Depth 3
                                        #         Child Loop BB0_10 Depth 4
                                        #         Child Loop BB0_12 Depth 4
                                        #       Child Loop BB0_18 Depth 3
                                        #         Child Loop BB0_19 Depth 4
	movl	%edi, 12(%esp)                  # 4-byte Spill
	movl	%eax, 36(%esp)                  # 4-byte Spill
	imull	120(%esp), %eax
	movl	116(%esp), %edi
	leal	(%edi,%eax,4), %eax
	movl	%eax, 40(%esp)                  # 4-byte Spill
	movl	12(%esp), %eax                  # 4-byte Reload
	movl	%eax, 8(%esp)                   # 4-byte Spill
	movl	28(%esp), %eax                  # 4-byte Reload
	movl	%ecx, %edi
	jmp	.LBB0_4
	.p2align	4, 0x90
.LBB0_25:                               #   in Loop: Header=BB0_4 Depth=2
	divps	48(%esp), %xmm3                 # 16-byte Folded Reload
	movaps	64(%esp), %xmm0                 # 16-byte Reload
	addps	%xmm0, %xmm3
	movaps	%xmm0, %xmm5
	movaps	.LCPI0_2, %xmm0                 # xmm0 = [5.0E-1,5.0E-1,5.0E-1,5.0E-1]
	addps	%xmm0, %xmm3
	cvttps2dq	%xmm3, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	cmpltps	%xmm0, %xmm3
	movaps	.LCPI0_3, %xmm4                 # xmm4 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0]
	andps	%xmm4, %xmm3
	subps	%xmm3, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm2, %xmm4
	pcmpgtd	%xmm0, %xmm4
	pand	%xmm4, %xmm0
	pandn	%xmm2, %xmm4
	por	%xmm0, %xmm4
	movdqa	%xmm4, %xmm3
	pxor	%xmm0, %xmm0
	pcmpgtd	%xmm0, %xmm3
	pand	%xmm4, %xmm3
	divps	48(%esp), %xmm7                 # 16-byte Folded Reload
	addps	%xmm5, %xmm7
	addps	.LCPI0_2, %xmm7
	cvttps2dq	%xmm7, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	cmpltps	%xmm0, %xmm7
	andps	.LCPI0_3, %xmm7
	subps	%xmm7, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm2, %xmm4
	pcmpgtd	%xmm0, %xmm4
	pand	%xmm4, %xmm0
	pandn	%xmm2, %xmm4
	por	%xmm0, %xmm4
	movdqa	%xmm4, %xmm5
	xorps	%xmm7, %xmm7
	pcmpgtd	%xmm7, %xmm5
	pand	%xmm4, %xmm5
	divps	48(%esp), %xmm6                 # 16-byte Folded Reload
	addps	64(%esp), %xmm6                 # 16-byte Folded Reload
	addps	.LCPI0_2, %xmm6
	cvttps2dq	%xmm6, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	cmpltps	%xmm0, %xmm6
	andps	.LCPI0_3, %xmm6
	subps	%xmm6, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm2, %xmm4
	pcmpgtd	%xmm0, %xmm4
	pand	%xmm4, %xmm0
	pandn	%xmm2, %xmm4
	por	%xmm0, %xmm4
	movdqa	%xmm4, %xmm0
	pcmpgtd	%xmm7, %xmm0
	pand	%xmm4, %xmm0
	pslld	$24, %xmm1
	por	%xmm0, %xmm1
	pslld	$16, %xmm3
	pslld	$8, %xmm5
	por	%xmm3, %xmm5
	por	%xmm1, %xmm5
	movl	40(%esp), %eax                  # 4-byte Reload
	movdqu	%xmm5, (%eax,%edi,4)
	movl	44(%esp), %edi                  # 4-byte Reload
	leal	4(%edi), %eax
	addl	$16, 8(%esp)                    # 4-byte Folded Spill
	cmpl	%ebp, %eax
	jg	.LBB0_26
.LBB0_4:                                #   Parent Loop BB0_3 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB0_9 Depth 3
                                        #         Child Loop BB0_10 Depth 4
                                        #         Child Loop BB0_12 Depth 4
                                        #       Child Loop BB0_18 Depth 3
                                        #         Child Loop BB0_19 Depth 4
	movl	%eax, 44(%esp)                  # 4-byte Spill
	cmpl	$0, 136(%esp)
	jle	.LBB0_5
# %bb.6:                                #   in Loop: Header=BB0_4 Depth=2
	testl	%esi, %esi
	jle	.LBB0_5
# %bb.7:                                #   in Loop: Header=BB0_4 Depth=2
	movl	%edi, 20(%esp)                  # 4-byte Spill
	testl	%edx, %edx
	je	.LBB0_17
# %bb.8:                                #   in Loop: Header=BB0_4 Depth=2
	xorl	%ebp, %ebp
	xorps	%xmm1, %xmm1
	xorps	%xmm3, %xmm3
	movl	8(%esp), %eax                   # 4-byte Reload
	movl	128(%esp), %edx
	xorps	%xmm7, %xmm7
	xorps	%xmm6, %xmm6
	jmp	.LBB0_9
	.p2align	4, 0x90
.LBB0_15:                               #   in Loop: Header=BB0_9 Depth=3
	incl	%ebp
	addl	24(%esp), %edx                  # 4-byte Folded Reload
	addl	%ebx, %eax
	cmpl	136(%esp), %ebp
	je	.LBB0_16
.LBB0_9:                                #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB0_10 Depth 4
                                        #         Child Loop BB0_12 Depth 4
	xorl	%edi, %edi
	cmpl	144(%esp), %ebp
	jne	.LBB0_10
# %bb.11:                               #   in Loop: Header=BB0_9 Depth=3
	movaps	%xmm1, %xmm0
	jmp	.LBB0_12
	.p2align	4, 0x90
.LBB0_10:                               #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        #       Parent Loop BB0_9 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	movups	(%eax,%edi,4), %xmm5
	movss	(%edx,%edi,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	shufps	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movaps	%xmm5, %xmm4
	andps	%xmm2, %xmm4
	cvtdq2ps	%xmm4, %xmm4
	mulps	%xmm0, %xmm4
	addps	%xmm4, %xmm6
	movaps	%xmm5, %xmm4
	psrld	$8, %xmm4
	pand	%xmm2, %xmm4
	cvtdq2ps	%xmm4, %xmm4
	mulps	%xmm0, %xmm4
	addps	%xmm4, %xmm7
	psrld	$16, %xmm5
	pand	%xmm2, %xmm5
	cvtdq2ps	%xmm5, %xmm4
	mulps	%xmm0, %xmm4
	addps	%xmm4, %xmm3
	incl	%edi
	cmpl	%edi, %esi
	jne	.LBB0_10
	jmp	.LBB0_15
	.p2align	4, 0x90
.LBB0_14:                               #   in Loop: Header=BB0_12 Depth=4
	movss	(%edx,%edi,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	shufps	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movaps	%xmm4, %xmm5
	andps	%xmm2, %xmm5
	cvtdq2ps	%xmm5, %xmm5
	mulps	%xmm0, %xmm5
	addps	%xmm5, %xmm6
	movaps	%xmm4, %xmm5
	psrld	$8, %xmm5
	pand	%xmm2, %xmm5
	cvtdq2ps	%xmm5, %xmm5
	mulps	%xmm0, %xmm5
	addps	%xmm5, %xmm7
	psrld	$16, %xmm4
	pand	%xmm2, %xmm4
	cvtdq2ps	%xmm4, %xmm4
	mulps	%xmm0, %xmm4
	addps	%xmm4, %xmm3
	incl	%edi
	movaps	%xmm1, %xmm0
	cmpl	%edi, %esi
	je	.LBB0_15
.LBB0_12:                               #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        #       Parent Loop BB0_9 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	movups	(%eax,%edi,4), %xmm4
	movaps	%xmm4, %xmm1
	cmpl	%edi, %ecx
	je	.LBB0_14
# %bb.13:                               #   in Loop: Header=BB0_12 Depth=4
	movaps	%xmm0, %xmm1
	jmp	.LBB0_14
	.p2align	4, 0x90
.LBB0_5:                                #   in Loop: Header=BB0_4 Depth=2
	xorps	%xmm6, %xmm6
	xorps	%xmm1, %xmm1
	xorps	%xmm7, %xmm7
	xorps	%xmm3, %xmm3
	xorps	%xmm5, %xmm5
	testl	%edx, %edx
	jne	.LBB0_25
	jmp	.LBB0_24
	.p2align	4, 0x90
.LBB0_16:                               #   in Loop: Header=BB0_4 Depth=2
	psrld	$24, %xmm1
	xorps	%xmm5, %xmm5
	jmp	.LBB0_22
.LBB0_17:                               #   in Loop: Header=BB0_4 Depth=2
	xorl	%eax, %eax
	xorps	%xmm5, %xmm5
	movl	8(%esp), %edx                   # 4-byte Reload
	movl	128(%esp), %ebp
	xorps	%xmm3, %xmm3
	xorps	%xmm7, %xmm7
	xorps	%xmm6, %xmm6
	.p2align	4, 0x90
.LBB0_18:                               #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB0_19 Depth 4
	xorl	%edi, %edi
	.p2align	4, 0x90
.LBB0_19:                               #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        #       Parent Loop BB0_18 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	movups	(%edx,%edi,4), %xmm0
	movss	(%ebp,%edi,4), %xmm4            # xmm4 = mem[0],zero,zero,zero
	shufps	$0, %xmm4, %xmm4                # xmm4 = xmm4[0,0,0,0]
	movaps	%xmm0, %xmm1
	andps	%xmm2, %xmm1
	cvtdq2ps	%xmm1, %xmm1
	mulps	%xmm4, %xmm1
	addps	%xmm1, %xmm6
	movaps	%xmm0, %xmm1
	psrld	$8, %xmm1
	pand	%xmm2, %xmm1
	cvtdq2ps	%xmm1, %xmm1
	mulps	%xmm4, %xmm1
	addps	%xmm1, %xmm7
	movaps	%xmm0, %xmm1
	psrld	$16, %xmm1
	pand	%xmm2, %xmm1
	cvtdq2ps	%xmm1, %xmm1
	mulps	%xmm4, %xmm1
	addps	%xmm1, %xmm3
	psrld	$24, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	mulps	%xmm4, %xmm0
	addps	%xmm0, %xmm5
	incl	%edi
	cmpl	%edi, %esi
	jne	.LBB0_19
# %bb.20:                               #   in Loop: Header=BB0_18 Depth=3
	incl	%eax
	addl	24(%esp), %ebp                  # 4-byte Folded Reload
	addl	%ebx, %edx
	cmpl	136(%esp), %eax
	jne	.LBB0_18
# %bb.21:                               #   in Loop: Header=BB0_4 Depth=2
	xorps	%xmm1, %xmm1
.LBB0_22:                               #   in Loop: Header=BB0_4 Depth=2
	movl	16(%esp), %ebp                  # 4-byte Reload
	movl	156(%esp), %edx
	movl	20(%esp), %edi                  # 4-byte Reload
	testl	%edx, %edx
	jne	.LBB0_25
.LBB0_24:                               #   in Loop: Header=BB0_4 Depth=2
	divps	48(%esp), %xmm5                 # 16-byte Folded Reload
	addps	64(%esp), %xmm5                 # 16-byte Folded Reload
	addps	.LCPI0_2, %xmm5
	cvttps2dq	%xmm5, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	cmpltps	%xmm0, %xmm5
	andps	.LCPI0_3, %xmm5
	subps	%xmm5, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm2, %xmm4
	pcmpgtd	%xmm0, %xmm4
	pand	%xmm4, %xmm0
	pandn	%xmm2, %xmm4
	por	%xmm0, %xmm4
	movdqa	%xmm4, %xmm1
	pcmpgtd	.LCPI0_4, %xmm1
	pand	%xmm4, %xmm1
	jmp	.LBB0_25
.Lfunc_end0:
//// SIZE(SYM(ksvgConvolveApplyInteriorSse2))
	.cfi_endproc
                                        # -- End function
	.ident	"clang version 17.0.0 (https://github.com/swiftlang/llvm-project.git 10999b6d034fe318f3d56c83bddb6572593a8bb0)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
