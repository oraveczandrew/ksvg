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
	.file	"ksvgConvolveApplyInteriorAvx2I386.cpp"
	.p2align	2, 0x0                          # -- Begin function ksvgConvolveApplyInteriorAvx2I386
.LCPI0_0:
	.long	0x437f0000                      # float 255
.LCPI0_1:
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
.LCPI0_4:
	.long	0x3f000000                      # float 0.5
	.p2align	5, 0x0
.LCPI0_2:
	.byte	1                               # 0x1
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	5                               # 0x5
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	9                               # 0x9
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	13                              # 0xd
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	17                              # 0x11
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	21                              # 0x15
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	25                              # 0x19
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	29                              # 0x1d
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
.LCPI0_3:
	.byte	2                               # 0x2
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	6                               # 0x6
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	10                              # 0xa
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	14                              # 0xe
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	18                              # 0x12
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	22                              # 0x16
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	26                              # 0x1a
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	30                              # 0x1e
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
.LCPI0_5:
	.zero	32
	.text
	.globl	SYM(ksvgConvolveApplyInteriorAvx2)
	.p2align	4, 0x90
TYPE(SYM(ksvgConvolveApplyInteriorAvx2), @function)
SYM(ksvgConvolveApplyInteriorAvx2):      # @ksvgConvolveApplyInteriorAvx2I386
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
	subl	$236, %esp
	.cfi_def_cfa_offset 256
	.cfi_offset %esi, -20
	.cfi_offset %edi, -16
	.cfi_offset %ebx, -12
	.cfi_offset %ebp, -8
	call	1f
1:	popl	%eax
	leal	.LCPI0_0-1b(%eax), %eax
	movd	(%eax), %xmm0
	vmovd	%xmm0, 104(%esp)
	movd	4(%eax), %xmm0
	vmovd	%xmm0, 96(%esp)
	movd	8(%eax), %xmm0
	vmovd	%xmm0, 100(%esp)
	leal	.LCPI0_2-.LCPI0_0(%eax), %eax
	vmovdqu	(%eax), %ymm0
	vmovdqu	%ymm0, (%esp)
	vmovdqu	32(%eax), %ymm0
	vmovdqu	%ymm0, 32(%esp)
	vmovdqu	64(%eax), %ymm0
	vmovdqu	%ymm0, 64(%esp)
	movl	284(%esp), %ecx
	movl	276(%esp), %esi
	movl	264(%esp), %edx
	movl	268(%esp), %eax
	subl	%esi, %edx
	leal	(%edx,%ecx), %ebp
	incl	%ebp
	subl	280(%esp), %eax
	leal	1(%eax), %edi
	testl	%edi, %edi
	jle	.LBB0_23
# %bb.1:
	incl	%edx
	cmpl	$8, %edx
	jge	.LBB0_2
.LBB0_23:
	andl	$-8, %ebp
	movl	%ebp, %eax
	addl	$236, %esp
	.cfi_def_cfa_offset 20
	popl	%esi
	.cfi_def_cfa_offset 16
	popl	%edi
	.cfi_def_cfa_offset 12
	popl	%ebx
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_def_cfa_offset 4
	vzeroupper
	retl
.LBB0_2:
	.cfi_def_cfa_offset 256
	movl	300(%esp), %edx
	movl	288(%esp), %edi
	vmovss	296(%esp), %xmm0                # xmm0 = mem[0],zero,zero,zero
	addl	%edi, %eax
	incl	%eax
	movl	%eax, 144(%esp)                 # 4-byte Spill
	vmulss	104(%esp), %xmm0, %xmm0
	vbroadcastss	%xmm0, %ymm0
	vmovups	%ymm0, 192(%esp)                # 32-byte Spill
	leal	8(%ecx), %eax
	movl	%eax, 140(%esp)                 # 4-byte Spill
	vbroadcastss	96(%esp), %ymm2         # ymm2 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	leal	(,%esi,4), %eax
	movl	%eax, 136(%esp)                 # 4-byte Spill
	movl	264(%esp), %eax
	leal	(,%eax,4), %ebx
	movl	%edi, %eax
	movl	256(%esp), %edi
	movl	%ebp, 128(%esp)                 # 4-byte Spill
	vmovups	%ymm2, 160(%esp)                # 32-byte Spill
	jmp	.LBB0_3
	.p2align	4, 0x90
.LBB0_22:                               #   in Loop: Header=BB0_3 Depth=1
	movl	148(%esp), %eax                 # 4-byte Reload
	incl	%eax
	movl	124(%esp), %edi                 # 4-byte Reload
	addl	%ebx, %edi
	cmpl	144(%esp), %eax                 # 4-byte Folded Reload
	jge	.LBB0_23
.LBB0_3:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_4 Depth 2
                                        #       Child Loop BB0_9 Depth 3
                                        #         Child Loop BB0_11 Depth 4
                                        #         Child Loop BB0_14 Depth 4
                                        #       Child Loop BB0_25 Depth 3
                                        #         Child Loop BB0_26 Depth 4
	movl	%edi, 124(%esp)                 # 4-byte Spill
	movl	%eax, 148(%esp)                 # 4-byte Spill
	imull	264(%esp), %eax
	movl	260(%esp), %edi
	leal	(%edi,%eax,4), %eax
	movl	%eax, 152(%esp)                 # 4-byte Spill
	movl	124(%esp), %eax                 # 4-byte Reload
	movl	%eax, 120(%esp)                 # 4-byte Spill
	movl	140(%esp), %eax                 # 4-byte Reload
	movl	%ecx, 132(%esp)                 # 4-byte Spill
	jmp	.LBB0_4
	.p2align	4, 0x90
.LBB0_21:                               #   in Loop: Header=BB0_4 Depth=2
	vbroadcastss	292(%esp), %ymm4
	vdivps	%ymm4, %ymm5, %ymm3
	vmovups	192(%esp), %ymm5                # 32-byte Reload
	vaddps	%ymm3, %ymm5, %ymm3
	vbroadcastss	100(%esp), %ymm6        # ymm6 = [5.0E-1,5.0E-1,5.0E-1,5.0E-1,5.0E-1,5.0E-1,5.0E-1,5.0E-1]
	vaddps	%ymm6, %ymm3, %ymm3
	vroundps	$1, %ymm3, %ymm3
	vcvttps2dq	%ymm3, %ymm3
	vdivps	%ymm4, %ymm0, %ymm0
	vxorps	%xmm4, %xmm4, %xmm4
	vpmaxsd	%ymm4, %ymm3, %ymm3
	vpminsd	%ymm2, %ymm3, %ymm3
	vpslld	$24, %ymm1, %ymm1
	vpslld	$16, %ymm3, %ymm3
	vpor	%ymm3, %ymm1, %ymm1
	vaddps	%ymm0, %ymm5, %ymm0
	vaddps	%ymm6, %ymm0, %ymm0
	vroundps	$1, %ymm0, %ymm0
	vcvttps2dq	%ymm0, %ymm0
	vbroadcastss	292(%esp), %ymm3
	vdivps	%ymm3, %ymm7, %ymm3
	vpmaxsd	%ymm4, %ymm0, %ymm0
	vpminsd	%ymm2, %ymm0, %ymm0
	vaddps	%ymm3, %ymm5, %ymm3
	vaddps	%ymm6, %ymm3, %ymm3
	vroundps	$1, %ymm3, %ymm3
	vcvttps2dq	%ymm3, %ymm3
	vpmaxsd	%ymm4, %ymm3, %ymm3
	vpminsd	%ymm2, %ymm3, %ymm3
	vpslld	$8, %ymm0, %ymm0
	vpor	%ymm0, %ymm3, %ymm0
	vpor	%ymm0, %ymm1, %ymm0
	movl	152(%esp), %eax                 # 4-byte Reload
	movl	132(%esp), %edi                 # 4-byte Reload
	vmovdqu	%ymm0, (%eax,%edi,4)
	movl	156(%esp), %edi                 # 4-byte Reload
	leal	8(%edi), %eax
	addl	$32, 120(%esp)                  # 4-byte Folded Spill
	movl	%edi, 132(%esp)                 # 4-byte Spill
	cmpl	%ebp, %eax
	jg	.LBB0_22
.LBB0_4:                                #   Parent Loop BB0_3 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB0_9 Depth 3
                                        #         Child Loop BB0_11 Depth 4
                                        #         Child Loop BB0_14 Depth 4
                                        #       Child Loop BB0_25 Depth 3
                                        #         Child Loop BB0_26 Depth 4
	movl	%eax, 156(%esp)                 # 4-byte Spill
	cmpl	$0, 280(%esp)
	jle	.LBB0_5
# %bb.6:                                #   in Loop: Header=BB0_4 Depth=2
	testl	%esi, %esi
	jle	.LBB0_5
# %bb.7:                                #   in Loop: Header=BB0_4 Depth=2
	testl	%edx, %edx
	je	.LBB0_24
# %bb.8:                                #   in Loop: Header=BB0_4 Depth=2
	xorl	%ebp, %ebp
	vxorps	%xmm3, %xmm3, %xmm3
	vxorps	%xmm5, %xmm5, %xmm5
	movl	120(%esp), %eax                 # 4-byte Reload
	movl	272(%esp), %edx
	vxorps	%xmm0, %xmm0, %xmm0
	vxorps	%xmm7, %xmm7, %xmm7
	jmp	.LBB0_9
	.p2align	4, 0x90
.LBB0_17:                               #   in Loop: Header=BB0_9 Depth=3
	incl	%ebp
	addl	136(%esp), %edx                 # 4-byte Folded Reload
	addl	%ebx, %eax
	cmpl	280(%esp), %ebp
	je	.LBB0_18
.LBB0_9:                                #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB0_11 Depth 4
                                        #         Child Loop BB0_14 Depth 4
	xorl	%edi, %edi
	cmpl	288(%esp), %ebp
	jne	.LBB0_10
# %bb.13:                               #   in Loop: Header=BB0_9 Depth=3
	vmovaps	%ymm3, %ymm1
	jmp	.LBB0_14
	.p2align	4, 0x90
.LBB0_16:                               #   in Loop: Header=BB0_14 Depth=4
	vbroadcastss	(%edx,%edi,4), %ymm1
	vandps	%ymm6, %ymm2, %ymm4
	vcvtdq2ps	%ymm4, %ymm4
	vmulps	%ymm4, %ymm1, %ymm4
	vaddps	%ymm4, %ymm7, %ymm7
	vpshufb	(%esp), %ymm6, %ymm4            # ymm4 = ymm6[1],zero,zero,zero,ymm6[5],zero,zero,zero,ymm6[9],zero,zero,zero,ymm6[13],zero,zero,zero,ymm6[17],zero,zero,zero,ymm6[21],zero,zero,zero,ymm6[25],zero,zero,zero,ymm6[29],zero,zero,zero
	vcvtdq2ps	%ymm4, %ymm4
	vmulps	%ymm4, %ymm1, %ymm4
	vaddps	%ymm4, %ymm0, %ymm0
	vpshufb	32(%esp), %ymm6, %ymm4          # ymm4 = ymm6[2],zero,zero,zero,ymm6[6],zero,zero,zero,ymm6[10],zero,zero,zero,ymm6[14],zero,zero,zero,ymm6[18],zero,zero,zero,ymm6[22],zero,zero,zero,ymm6[26],zero,zero,zero,ymm6[30],zero,zero,zero
	vcvtdq2ps	%ymm4, %ymm4
	vmulps	%ymm4, %ymm1, %ymm1
	vaddps	%ymm1, %ymm5, %ymm5
	incl	%edi
	vmovaps	%ymm3, %ymm1
	cmpl	%edi, %esi
	je	.LBB0_17
.LBB0_14:                               #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        #       Parent Loop BB0_9 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	vmovups	(%eax,%edi,4), %ymm6
	vmovaps	%ymm6, %ymm3
	cmpl	%edi, %ecx
	je	.LBB0_16
# %bb.15:                               #   in Loop: Header=BB0_14 Depth=4
	vmovaps	%ymm1, %ymm3
	jmp	.LBB0_16
	.p2align	4, 0x90
.LBB0_10:                               #   in Loop: Header=BB0_9 Depth=3
	vmovdqa	32(%esp), %ymm2                 # ymm2 = [2,128,128,128,6,128,128,128,10,128,128,128,14,128,128,128,18,128,128,128,22,128,128,128,26,128,128,128,30,128,128,128]
	.p2align	4, 0x90
.LBB0_11:                               #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        #       Parent Loop BB0_9 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	vmovups	(%eax,%edi,4), %ymm1
	vbroadcastss	(%edx,%edi,4), %ymm6
	vandps	160(%esp), %ymm1, %ymm4         # 32-byte Folded Reload
	vcvtdq2ps	%ymm4, %ymm4
	vmulps	%ymm4, %ymm6, %ymm4
	vaddps	%ymm4, %ymm7, %ymm7
	vpshufb	(%esp), %ymm1, %ymm4            # ymm4 = ymm1[1],zero,zero,zero,ymm1[5],zero,zero,zero,ymm1[9],zero,zero,zero,ymm1[13],zero,zero,zero,ymm1[17],zero,zero,zero,ymm1[21],zero,zero,zero,ymm1[25],zero,zero,zero,ymm1[29],zero,zero,zero
	vcvtdq2ps	%ymm4, %ymm4
	vmulps	%ymm4, %ymm6, %ymm4
	vaddps	%ymm4, %ymm0, %ymm0
	vpshufb	%ymm2, %ymm1, %ymm1
	vcvtdq2ps	%ymm1, %ymm1
	vmulps	%ymm1, %ymm6, %ymm1
	vaddps	%ymm1, %ymm5, %ymm5
	incl	%edi
	cmpl	%edi, %esi
	jne	.LBB0_11
# %bb.12:                               #   in Loop: Header=BB0_9 Depth=3
	vmovups	160(%esp), %ymm2                # 32-byte Reload
	jmp	.LBB0_17
	.p2align	4, 0x90
.LBB0_5:                                #   in Loop: Header=BB0_4 Depth=2
	vxorps	%xmm7, %xmm7, %xmm7
	vxorps	%xmm1, %xmm1, %xmm1
	vxorps	%xmm0, %xmm0, %xmm0
	vxorps	%xmm5, %xmm5, %xmm5
	vxorps	%xmm6, %xmm6, %xmm6
	testl	%edx, %edx
	jne	.LBB0_21
	jmp	.LBB0_20
	.p2align	4, 0x90
.LBB0_18:                               #   in Loop: Header=BB0_4 Depth=2
	vpsrld	$24, %ymm3, %ymm1
	vxorps	%xmm6, %xmm6, %xmm6
	movl	128(%esp), %ebp                 # 4-byte Reload
	movl	300(%esp), %edx
	testl	%edx, %edx
	jne	.LBB0_21
	jmp	.LBB0_20
.LBB0_24:                               #   in Loop: Header=BB0_4 Depth=2
	xorl	%eax, %eax
	vxorps	%xmm6, %xmm6, %xmm6
	movl	120(%esp), %edx                 # 4-byte Reload
	movl	272(%esp), %ebp
	vxorps	%xmm5, %xmm5, %xmm5
	vxorps	%xmm0, %xmm0, %xmm0
	vxorps	%xmm7, %xmm7, %xmm7
	.p2align	4, 0x90
.LBB0_25:                               #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB0_26 Depth 4
	xorl	%edi, %edi
	vmovups	160(%esp), %ymm2                # 32-byte Reload
	.p2align	4, 0x90
.LBB0_26:                               #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        #       Parent Loop BB0_25 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	vmovups	(%edx,%edi,4), %ymm1
	vbroadcastss	(%ebp,%edi,4), %ymm3
	vandps	%ymm1, %ymm2, %ymm4
	vcvtdq2ps	%ymm4, %ymm4
	vmulps	%ymm4, %ymm3, %ymm4
	vaddps	%ymm4, %ymm7, %ymm7
	vpshufb	(%esp), %ymm1, %ymm4            # ymm4 = ymm1[1],zero,zero,zero,ymm1[5],zero,zero,zero,ymm1[9],zero,zero,zero,ymm1[13],zero,zero,zero,ymm1[17],zero,zero,zero,ymm1[21],zero,zero,zero,ymm1[25],zero,zero,zero,ymm1[29],zero,zero,zero
	vcvtdq2ps	%ymm4, %ymm4
	vmulps	%ymm4, %ymm3, %ymm4
	vaddps	%ymm4, %ymm0, %ymm0
	vpshufb	32(%esp), %ymm1, %ymm4          # ymm4 = ymm1[2],zero,zero,zero,ymm1[6],zero,zero,zero,ymm1[10],zero,zero,zero,ymm1[14],zero,zero,zero,ymm1[18],zero,zero,zero,ymm1[22],zero,zero,zero,ymm1[26],zero,zero,zero,ymm1[30],zero,zero,zero
	vcvtdq2ps	%ymm4, %ymm4
	vmulps	%ymm4, %ymm3, %ymm4
	vaddps	%ymm4, %ymm5, %ymm5
	vpsrld	$24, %ymm1, %ymm1
	vcvtdq2ps	%ymm1, %ymm1
	vmulps	%ymm1, %ymm3, %ymm1
	vaddps	%ymm1, %ymm6, %ymm6
	incl	%edi
	cmpl	%edi, %esi
	jne	.LBB0_26
# %bb.27:                               #   in Loop: Header=BB0_25 Depth=3
	incl	%eax
	addl	136(%esp), %ebp                 # 4-byte Folded Reload
	addl	%ebx, %edx
	cmpl	280(%esp), %eax
	jne	.LBB0_25
# %bb.28:                               #   in Loop: Header=BB0_4 Depth=2
	vxorps	%xmm1, %xmm1, %xmm1
	movl	128(%esp), %ebp                 # 4-byte Reload
	movl	300(%esp), %edx
	vmovups	160(%esp), %ymm2                # 32-byte Reload
	testl	%edx, %edx
	jne	.LBB0_21
	.p2align	4, 0x90
.LBB0_20:                               #   in Loop: Header=BB0_4 Depth=2
	vbroadcastss	292(%esp), %ymm1
	vdivps	%ymm1, %ymm6, %ymm1
	vaddps	192(%esp), %ymm1, %ymm1         # 32-byte Folded Reload
	vbroadcastss	100(%esp), %ymm3        # ymm3 = [5.0E-1,5.0E-1,5.0E-1,5.0E-1,5.0E-1,5.0E-1,5.0E-1,5.0E-1]
	vaddps	%ymm3, %ymm1, %ymm1
	vroundps	$1, %ymm1, %ymm1
	vcvttps2dq	%ymm1, %ymm1
	vpmaxsd	64(%esp), %ymm1, %ymm1
	vpminsd	%ymm2, %ymm1, %ymm1
	jmp	.LBB0_21
.Lfunc_end0:
//// SIZE(SYM(ksvgConvolveApplyInteriorAvx2))
	.cfi_endproc
                                        # -- End function
	.ident	"clang version 17.0.0 (https://github.com/swiftlang/llvm-project.git 10999b6d034fe318f3d56c83bddb6572593a8bb0)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
