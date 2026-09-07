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
	.file	"dm_avx2.cpp"
#if defined(__APPLE__)
	.section __TEXT,__const
#else
	.section	.rodata.cst32,"aM",@progbits,32
#endif
	.p2align	5, 0x0                          # -- Begin function ksvgDisplacementMapApplyAvx2
.LCPI0_0:
	.long	0                               # 0x0
	.long	1                               # 0x1
	.long	2                               # 0x2
	.long	3                               # 0x3
	.long	4                               # 0x4
	.long	5                               # 0x5
	.long	6                               # 0x6
	.long	7                               # 0x7
.LCPI0_4:
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
.LCPI0_5:
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
.LCPI0_6:
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
#if defined(__APPLE__)
	.section __TEXT,__const
#else
	.section	.rodata.cst4,"aM",@progbits,4
#endif
	.p2align	2, 0x0
.LCPI0_1:
	.long	0x437f0000                      # float 255
.LCPI0_2:
	.long	0xbf000000                      # float -0.5
.LCPI0_3:
	.long	8                               # 0x8
.LCPI0_7:
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
.LCPI0_11:
	.byte	255                             # 0xff
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
.LCPI0_12:
	.byte	8                               # 0x8
	.byte	16                              # 0x10
	.byte	0                               # 0x0
	.byte	0                               # 0x0
.LCPI0_13:
	.byte	16                              # 0x10
	.byte	8                               # 0x8
	.byte	0                               # 0x0
	.byte	0                               # 0x0
#if defined(__APPLE__)
	.section __TEXT,__const
#else
	.section	.rodata.cst16,"aM",@progbits,16
#endif
	.p2align	4, 0x0
.LCPI0_8:
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
.LCPI0_9:
	.long	8                               # 0x8
	.long	16                              # 0x10
	.zero	4
	.zero	4
.LCPI0_10:
	.long	16                              # 0x10
	.long	8                               # 0x8
	.zero	4
	.zero	4
#if defined(__APPLE__)
	.section __TEXT,__const
#else
	.section	.rodata.cst8,"aM",@progbits,8
#endif
.LCPI0_14:
	.byte	0                               # 0x0
	.byte	1                               # 0x1
	.byte	2                               # 0x2
	.byte	3                               # 0x3
	.byte	4                               # 0x4
	.byte	5                               # 0x5
	.byte	6                               # 0x6
	.byte	7                               # 0x7
	.text
	.globl	SYM(ksvgDisplacementMapApplyAvx2)
	.p2align	4, 0x90
	TYPE(SYM(ksvgDisplacementMapApplyAvx2), @function)
SYM(ksvgDisplacementMapApplyAvx2):       # @ksvgDisplacementMapApplyAvx2
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
	CFI_OFFSET(%rbx, -56)
	CFI_OFFSET(%r12, -48)
	CFI_OFFSET(%r13, -40)
	CFI_OFFSET(%r14, -32)
	CFI_OFFSET(%r15, -24)
	CFI_OFFSET(%rbp, -16)
                                        # kill: def $r8d killed $r8d def $r8
                                        # kill: def $ecx killed $ecx def $rcx
	movq	%rcx, -72(%rsp)                 # 8-byte Spill
	movq	%rdx, -56(%rsp)                 # 8-byte Spill
	movq	%rsi, -64(%rsp)                 # 8-byte Spill
	movl	56(%rsp), %eax
	cmpq	$3, %rax
	ja	.LBB0_1322
# %bb.1:
	vmovaps	%xmm0, %xmm5
	leaq	.LJTI0_0(%rip), %rcx
	movslq	(%rcx,%rax,4), %rax
	addq	%rcx, %rax
	vmovaps	%xmm0, -24(%rsp)                # 16-byte Spill
	jmpq	*%rax
.LBB0_2:
	cmpl	$3, %r9d
	ja	.LBB0_1322
# %bb.3:
	movl	%r9d, %eax
	leaq	.LJTI0_4(%rip), %rcx
	movslq	(%rcx,%rax,4), %rax
	addq	%rcx, %rax
	jmpq	*%rax
.LBB0_4:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.5:
	movq	-72(%rsp), %rax                 # 8-byte Reload
	leal	-1(%rax), %edx
	leal	-1(%r8), %r9d
	cmpl	$8, %eax
	jge	.LBB0_6
# %bb.20:
	testl	%eax, %eax
	jle	.LBB0_1322
# %bb.21:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_22
.LBB0_662:
	cmpl	$3, %r9d
	ja	.LBB0_1322
# %bb.663:
	movl	%r9d, %eax
	leaq	.LJTI0_2(%rip), %rcx
	movslq	(%rcx,%rax,4), %rax
	addq	%rcx, %rax
	jmpq	*%rax
.LBB0_664:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.665:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_666
# %bb.680:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.681:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm5, %xmm0
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vpmovzxbd	.LCPI0_11(%rip), %xmm1  # xmm1 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm2   # xmm2 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm3   # xmm3 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movl	$1, %ebp
	movl	$2, %r14d
	movl	$3, %r15d
	jmp	.LBB0_682
.LBB0_992:
	cmpl	$3, %r9d
	ja	.LBB0_1322
# %bb.993:
	movl	%r9d, %eax
	leaq	.LJTI0_1(%rip), %rcx
	movslq	(%rcx,%rax,4), %rax
	addq	%rcx, %rax
	jmpq	*%rax
.LBB0_994:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.995:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_996
# %bb.1010:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.1011:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm5, %xmm0
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vbroadcastss	.LCPI0_1(%rip), %xmm1   # xmm1 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm2   # xmm2 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movl	$1, %ebp
	movl	$2, %r14d
	movl	$3, %r15d
	jmp	.LBB0_1012
.LBB0_332:
	cmpl	$3, %r9d
	ja	.LBB0_1322
# %bb.333:
	movl	%r9d, %eax
	leaq	.LJTI0_3(%rip), %rcx
	movslq	(%rcx,%rax,4), %rax
	addq	%rcx, %rax
	jmpq	*%rax
.LBB0_334:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.335:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_336
# %bb.350:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.351:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm5, %xmm0
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vpmovsxbd	.LCPI0_12(%rip), %xmm1  # xmm1 = [8,16,0,0]
	vpmovzxbd	.LCPI0_11(%rip), %xmm2  # xmm2 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm3   # xmm3 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm4   # xmm4 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movl	$1, %ebp
	movl	$2, %r14d
	movl	$3, %r15d
	jmp	.LBB0_352
.LBB0_828:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.829:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_830
# %bb.844:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.845:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	jmp	.LBB0_846
.LBB0_910:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.911:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_912
# %bb.926:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.927:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm5, %xmm0
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vbroadcastss	.LCPI0_1(%rip), %xmm1   # xmm1 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm2   # xmm2 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movl	$1, %ebp
	movl	$2, %r14d
	movl	$3, %r15d
	jmp	.LBB0_928
.LBB0_1158:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.1159:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_1160
# %bb.1174:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.1175:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm5, %xmm0
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vbroadcastss	.LCPI0_1(%rip), %xmm1   # xmm1 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm2   # xmm2 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movl	$1, %ebp
	movl	$2, %r14d
	movl	$3, %r15d
	jmp	.LBB0_1176
.LBB0_168:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.169:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_170
# %bb.184:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.185:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm5, %xmm0
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vpmovzxbd	.LCPI0_11(%rip), %xmm1  # xmm1 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm2   # xmm2 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm3   # xmm3 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movl	$1, %ebp
	movl	$2, %r14d
	movl	$3, %r15d
	jmp	.LBB0_186
.LBB0_746:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.747:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_748
# %bb.762:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.763:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm5, %xmm0
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vpmovzxbd	.LCPI0_11(%rip), %xmm1  # xmm1 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm2   # xmm2 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm3   # xmm3 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movl	$1, %ebp
	movl	$2, %r14d
	movl	$3, %r15d
	jmp	.LBB0_764
.LBB0_498:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.499:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_500
# %bb.514:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.515:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm5, %xmm0
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vpmovzxbd	.LCPI0_11(%rip), %xmm1  # xmm1 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm2   # xmm2 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm3   # xmm3 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movl	$1, %ebp
	movl	$2, %r14d
	movl	$3, %r15d
	jmp	.LBB0_516
.LBB0_1240:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.1241:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_1242
# %bb.1256:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.1257:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	jmp	.LBB0_1258
.LBB0_250:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.251:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_252
# %bb.266:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.267:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm5, %xmm0
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vbroadcastss	.LCPI0_1(%rip), %xmm1   # xmm1 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm2   # xmm2 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movl	$1, %ebp
	movl	$2, %r14d
	movl	$3, %r15d
	jmp	.LBB0_268
.LBB0_1076:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.1077:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_1078
# %bb.1092:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.1093:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm5, %xmm0
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vbroadcastss	.LCPI0_1(%rip), %xmm1   # xmm1 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm2   # xmm2 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movl	$1, %ebp
	movl	$2, %r14d
	movl	$3, %r15d
	jmp	.LBB0_1094
.LBB0_580:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.581:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_582
# %bb.596:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.597:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm5, %xmm0
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vbroadcastss	.LCPI0_1(%rip), %xmm1   # xmm1 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm2   # xmm2 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movl	$1, %ebp
	movl	$2, %r14d
	movl	$3, %r15d
	jmp	.LBB0_598
.LBB0_86:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.87:
	movq	-72(%rsp), %rax                 # 8-byte Reload
	leal	-1(%rax), %esi
	leal	-1(%r8), %r9d
	cmpl	$8, %eax
	jge	.LBB0_88
# %bb.102:
	testl	%eax, %eax
	jle	.LBB0_1322
# %bb.103:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm5, %xmm0
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%r15d, %r15d
	vpmovsxbd	.LCPI0_13(%rip), %xmm1  # xmm1 = [16,8,0,0]
	vpmovzxbd	.LCPI0_11(%rip), %xmm2  # xmm2 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm3   # xmm3 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm4   # xmm4 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	movl	$1, %ebp
	movl	$2, %r14d
	movl	$3, %ebx
	jmp	.LBB0_104
.LBB0_416:
	testl	%r8d, %r8d
	jle	.LBB0_1322
# %bb.417:
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	leal	-1(%rcx), %eax
	leal	-1(%r8), %r9d
	cmpl	$8, %ecx
	jge	.LBB0_418
# %bb.432:
	testl	%ecx, %ecx
	jle	.LBB0_1322
# %bb.433:
	movl	-72(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	shlq	$2, %r10
	movl	$24, %r11d
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	jmp	.LBB0_434
.LBB0_830:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -40(%rsp)                 # 8-byte Spill
	leaq	(,%r10,4), %rcx
	movq	%rcx, -48(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vbroadcastss	.LCPI0_1(%rip), %ymm6   # ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm7   # ymm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vbroadcastss	.LCPI0_7(%rip), %ymm8   # ymm8 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %ymm10  # ymm10 = [8,8,8,8,8,8,8,8]
	vmovss	.LCPI0_1(%rip), %xmm11          # xmm11 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm12          # xmm12 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_831
	.p2align	4, 0x90
.LBB0_843:                              #   in Loop: Header=BB0_831 Depth=1
	incq	%r14
	movq	-48(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-40(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_831:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_832 Depth 2
                                        #     Child Loop BB0_834 Depth 2
	vmovd	%r14d, %xmm0
	vpbroadcastd	%xmm0, %ymm13
	movq	%rbx, %rdx
	xorl	%ebp, %ebp
	vpmovsxbd	.LCPI0_14(%rip), %ymm14 # ymm14 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_832:                              #   Parent Loop BB0_831 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %rcx
	vandps	(%r15,%rbp,4), %ymm8, %ymm0
	vcvtdq2ps	%ymm0, %ymm0
	vdivps	%ymm6, %ymm0, %ymm0
	movq	%rdx, %r13
	vaddps	%ymm7, %ymm0, %ymm0
	vmulps	%ymm0, %ymm1, %ymm0
	vcvttps2dq	%ymm0, %ymm0
	vpaddd	%ymm0, %ymm14, %ymm15
	vpmaxsd	%ymm9, %ymm15, %ymm15
	vpaddd	%ymm0, %ymm13, %ymm0
	vpmaxsd	%ymm9, %ymm0, %ymm0
	vpminsd	%ymm2, %ymm15, %ymm15
	vpminsd	%ymm3, %ymm0, %ymm0
	vpmulld	%ymm4, %ymm0, %ymm0
	vxorps	%xmm5, %xmm5, %xmm5
	vpaddd	%ymm0, %ymm15, %ymm0
	vpcmpeqd	%ymm15, %ymm15, %ymm15
	vpgatherdd	%ymm15, (%rdi,%ymm0,4), %ymm5
	vpaddd	%ymm10, %ymm14, %ymm14
	vmovdqu	%ymm5, (%r12,%rbp,4)
	addq	$8, %rbp
	addq	$16, %rcx
	addq	$32, %rdx
	cmpq	%r10, %rcx
	jbe	.LBB0_832
# %bb.833:                              #   in Loop: Header=BB0_831 Depth=1
	cmpl	-72(%rsp), %ebp                 # 4-byte Folded Reload
	vmovaps	-24(%rsp), %xmm5                # 16-byte Reload
	jl	.LBB0_834
	jmp	.LBB0_843
	.p2align	4, 0x90
.LBB0_842:                              #   in Loop: Header=BB0_834 Depth=2
	imull	-72(%rsp), %r11d                # 4-byte Folded Reload
	addl	%edx, %r11d
	movslq	%r11d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_843
.LBB0_834:                              #   Parent Loop BB0_831 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	(%rcx,%r13), %ecx
	vcvtsi2ss	%ecx, %xmm1, %xmm0
	vdivss	%xmm11, %xmm0, %xmm0
	vaddss	%xmm0, %xmm12, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r8d
	leal	(%r8,%rbp), %esi
	movl	%esi, %ecx
	cmpl	%eax, %esi
	jge	.LBB0_835
# %bb.836:                              #   in Loop: Header=BB0_834 Depth=2
	xorl	%r11d, %r11d
	movl	$0, %edx
	testl	%esi, %esi
	jns	.LBB0_837
.LBB0_838:                              #   in Loop: Header=BB0_834 Depth=2
	addl	%r14d, %r8d
	movl	%r8d, %ecx
	cmpl	%r9d, %r8d
	jge	.LBB0_839
.LBB0_840:                              #   in Loop: Header=BB0_834 Depth=2
	testl	%r8d, %r8d
	js	.LBB0_842
	jmp	.LBB0_841
	.p2align	4, 0x90
.LBB0_835:                              #   in Loop: Header=BB0_834 Depth=2
	movl	%eax, %ecx
	xorl	%r11d, %r11d
	movl	$0, %edx
	testl	%esi, %esi
	js	.LBB0_838
.LBB0_837:                              #   in Loop: Header=BB0_834 Depth=2
	movl	%ecx, %edx
	addl	%r14d, %r8d
	movl	%r8d, %ecx
	cmpl	%r9d, %r8d
	jl	.LBB0_840
.LBB0_839:                              #   in Loop: Header=BB0_834 Depth=2
	movl	%r9d, %ecx
	testl	%r8d, %r8d
	js	.LBB0_842
.LBB0_841:                              #   in Loop: Header=BB0_834 Depth=2
	movl	%ecx, %r11d
	jmp	.LBB0_842
.LBB0_912:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -24(%rsp)                 # 8-byte Spill
	vbroadcastss	%xmm5, %xmm0
	leaq	(,%r10,4), %rcx
	movq	%rcx, -40(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vbroadcastss	.LCPI0_1(%rip), %ymm6   # ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm7   # ymm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vbroadcastss	.LCPI0_7(%rip), %ymm8   # ymm8 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %ymm10  # ymm10 = [8,8,8,8,8,8,8,8]
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_913
	.p2align	4, 0x90
.LBB0_925:                              #   in Loop: Header=BB0_913 Depth=1
	incq	%r14
	movq	-40(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-24(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_913:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_914 Depth 2
                                        #     Child Loop BB0_916 Depth 2
	vmovd	%r14d, %xmm13
	vpbroadcastd	%xmm13, %ymm14
	movq	%rbx, %r13
	xorl	%r8d, %r8d
	vpmovsxbd	.LCPI0_14(%rip), %ymm15 # ymm15 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_914:                              #   Parent Loop BB0_913 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%r8, %rbp
	vmovups	(%r15,%r8,4), %ymm5
	vandps	%ymm5, %ymm8, %ymm11
	vcvtdq2ps	%ymm11, %ymm11
	vdivps	%ymm6, %ymm11, %ymm11
	vpsrld	$24, %ymm5, %ymm5
	vcvtdq2ps	%ymm5, %ymm5
	vdivps	%ymm6, %ymm5, %ymm5
	movq	%r13, %r11
	vaddps	%ymm7, %ymm5, %ymm5
	vaddps	%ymm7, %ymm11, %ymm11
	vmulps	%ymm5, %ymm1, %ymm5
	vmulps	%ymm1, %ymm11, %ymm11
	vcvttps2dq	%ymm11, %ymm11
	vpaddd	%ymm14, %ymm11, %ymm11
	vcvttps2dq	%ymm5, %ymm5
	vpaddd	%ymm5, %ymm15, %ymm5
	vpmaxsd	%ymm9, %ymm5, %ymm5
	vpmaxsd	%ymm9, %ymm11, %ymm11
	vpminsd	%ymm2, %ymm5, %ymm5
	vpminsd	%ymm3, %ymm11, %ymm11
	vpmulld	%ymm4, %ymm11, %ymm11
	vpcmpeqd	%ymm12, %ymm12, %ymm12
	vpaddd	%ymm5, %ymm11, %ymm5
	vpxor	%xmm11, %xmm11, %xmm11
	vpgatherdd	%ymm12, (%rdi,%ymm5,4), %ymm11
	vpaddd	%ymm10, %ymm15, %ymm15
	vmovdqu	%ymm11, (%r12,%r8,4)
	addq	$8, %r8
	addq	$16, %rbp
	addq	$32, %r13
	cmpq	%r10, %rbp
	jbe	.LBB0_914
# %bb.915:                              #   in Loop: Header=BB0_913 Depth=1
	cmpl	-72(%rsp), %r8d                 # 4-byte Folded Reload
	vbroadcastss	.LCPI0_1(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm15  # xmm15 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	jl	.LBB0_916
	jmp	.LBB0_925
	.p2align	4, 0x90
.LBB0_924:                              #   in Loop: Header=BB0_916 Depth=2
	imull	-72(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%edx, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	incq	%r8
	addq	$4, %r11
	cmpq	%r10, %r8
	jae	.LBB0_925
.LBB0_916:                              #   Parent Loop BB0_913 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm12, %xmm5, %xmm5
	vaddps	%xmm5, %xmm15, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r8d, %xmm13, %xmm11
	vpaddd	%xmm5, %xmm11, %xmm14
	vpextrd	$1, %xmm14, %esi
	cmpl	%eax, %esi
	jl	.LBB0_918
# %bb.917:                              #   in Loop: Header=BB0_916 Depth=2
	movl	%eax, %esi
.LBB0_918:                              #   in Loop: Header=BB0_916 Depth=2
	vpmovsxdq	%xmm14, %xmm5
	vmovmskpd	%xmm5, %r13d
	xorl	%ebp, %ebp
	movl	$0, %edx
	testb	$2, %r13b
	je	.LBB0_919
# %bb.920:                              #   in Loop: Header=BB0_916 Depth=2
	vmovd	%xmm14, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_921
.LBB0_922:                              #   in Loop: Header=BB0_916 Depth=2
	testb	$1, %r13b
	jne	.LBB0_924
	jmp	.LBB0_923
	.p2align	4, 0x90
.LBB0_919:                              #   in Loop: Header=BB0_916 Depth=2
	movl	%esi, %edx
	vmovd	%xmm14, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_922
.LBB0_921:                              #   in Loop: Header=BB0_916 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r13b
	jne	.LBB0_924
.LBB0_923:                              #   in Loop: Header=BB0_916 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_924
.LBB0_1160:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -24(%rsp)                 # 8-byte Spill
	vbroadcastss	%xmm5, %xmm0
	leaq	(,%r10,4), %rcx
	movq	%rcx, -40(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vbroadcastss	.LCPI0_1(%rip), %ymm6   # ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm7   # ymm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpbroadcastd	.LCPI0_7(%rip), %ymm8   # ymm8 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %ymm10  # ymm10 = [8,8,8,8,8,8,8,8]
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_1161
	.p2align	4, 0x90
.LBB0_1173:                             #   in Loop: Header=BB0_1161 Depth=1
	incq	%r14
	movq	-40(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-24(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_1161:                             # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_1162 Depth 2
                                        #     Child Loop BB0_1164 Depth 2
	vmovd	%r14d, %xmm13
	vpbroadcastd	%xmm13, %ymm14
	movq	%rbx, %r13
	xorl	%r8d, %r8d
	vpmovsxbd	.LCPI0_14(%rip), %ymm15 # ymm15 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_1162:                             #   Parent Loop BB0_1161 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%r8, %rbp
	vmovdqu	(%r15,%r8,4), %ymm5
	vpsrld	$24, %ymm5, %ymm11
	vcvtdq2ps	%ymm11, %ymm11
	vdivps	%ymm6, %ymm11, %ymm11
	vpand	%ymm5, %ymm8, %ymm5
	vcvtdq2ps	%ymm5, %ymm5
	vdivps	%ymm6, %ymm5, %ymm5
	movq	%r13, %r11
	vaddps	%ymm7, %ymm5, %ymm5
	vaddps	%ymm7, %ymm11, %ymm11
	vmulps	%ymm5, %ymm1, %ymm5
	vmulps	%ymm1, %ymm11, %ymm11
	vcvttps2dq	%ymm11, %ymm11
	vpaddd	%ymm14, %ymm11, %ymm11
	vcvttps2dq	%ymm5, %ymm5
	vpaddd	%ymm5, %ymm15, %ymm5
	vpmaxsd	%ymm9, %ymm5, %ymm5
	vpmaxsd	%ymm9, %ymm11, %ymm11
	vpminsd	%ymm2, %ymm5, %ymm5
	vpminsd	%ymm3, %ymm11, %ymm11
	vpmulld	%ymm4, %ymm11, %ymm11
	vpcmpeqd	%ymm12, %ymm12, %ymm12
	vpaddd	%ymm5, %ymm11, %ymm5
	vpxor	%xmm11, %xmm11, %xmm11
	vpgatherdd	%ymm12, (%rdi,%ymm5,4), %ymm11
	vpaddd	%ymm10, %ymm15, %ymm15
	vmovdqu	%ymm11, (%r12,%r8,4)
	addq	$8, %r8
	addq	$16, %rbp
	addq	$32, %r13
	cmpq	%r10, %rbp
	jbe	.LBB0_1162
# %bb.1163:                             #   in Loop: Header=BB0_1161 Depth=1
	cmpl	-72(%rsp), %r8d                 # 4-byte Folded Reload
	vbroadcastss	.LCPI0_1(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm15  # xmm15 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	jl	.LBB0_1164
	jmp	.LBB0_1173
	.p2align	4, 0x90
.LBB0_1172:                             #   in Loop: Header=BB0_1164 Depth=2
	imull	-72(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%edx, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	incq	%r8
	addq	$4, %r11
	cmpq	%r10, %r8
	jae	.LBB0_1173
.LBB0_1164:                             #   Parent Loop BB0_1161 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm5
	vpinsrd	$1, %edx, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm12, %xmm5, %xmm5
	vaddps	%xmm5, %xmm15, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r8d, %xmm13, %xmm11
	vpaddd	%xmm5, %xmm11, %xmm14
	vpextrd	$1, %xmm14, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1166
# %bb.1165:                             #   in Loop: Header=BB0_1164 Depth=2
	movl	%eax, %esi
.LBB0_1166:                             #   in Loop: Header=BB0_1164 Depth=2
	vpmovsxdq	%xmm14, %xmm5
	vmovmskpd	%xmm5, %r13d
	xorl	%ebp, %ebp
	movl	$0, %edx
	testb	$2, %r13b
	je	.LBB0_1167
# %bb.1168:                             #   in Loop: Header=BB0_1164 Depth=2
	vmovd	%xmm14, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1169
.LBB0_1170:                             #   in Loop: Header=BB0_1164 Depth=2
	testb	$1, %r13b
	jne	.LBB0_1172
	jmp	.LBB0_1171
	.p2align	4, 0x90
.LBB0_1167:                             #   in Loop: Header=BB0_1164 Depth=2
	movl	%esi, %edx
	vmovd	%xmm14, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1170
.LBB0_1169:                             #   in Loop: Header=BB0_1164 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r13b
	jne	.LBB0_1172
.LBB0_1171:                             #   in Loop: Header=BB0_1164 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_1172
.LBB0_666:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -24(%rsp)                 # 8-byte Spill
	vbroadcastss	%xmm5, %xmm0
	vmovaps	%xmm0, -40(%rsp)                # 16-byte Spill
	leaq	(,%r10,4), %rcx
	movq	%rcx, -48(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vmovdqa	.LCPI0_6(%rip), %ymm6           # ymm6 = [2,128,128,128,6,128,128,128,10,128,128,128,14,128,128,128,18,128,128,128,22,128,128,128,26,128,128,128,30,128,128,128]
	vbroadcastss	.LCPI0_7(%rip), %ymm7   # ymm7 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_1(%rip), %ymm8   # ymm8 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm9   # ymm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm10, %xmm10, %xmm10
	vpbroadcastd	.LCPI0_3(%rip), %ymm11  # ymm11 = [8,8,8,8,8,8,8,8]
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_667
	.p2align	4, 0x90
.LBB0_679:                              #   in Loop: Header=BB0_667 Depth=1
	incq	%r14
	movq	-48(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-24(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_667:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_668 Depth 2
                                        #     Child Loop BB0_670 Depth 2
	vmovd	%r14d, %xmm15
	vpbroadcastd	%xmm15, %ymm5
	movq	%rbx, %r13
	xorl	%r8d, %r8d
	vpmovsxbd	.LCPI0_14(%rip), %ymm12 # ymm12 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_668:                              #   Parent Loop BB0_667 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%r8, %rbp
	vmovups	(%r15,%r8,4), %ymm13
	vandps	%ymm7, %ymm13, %ymm14
	vcvtdq2ps	%ymm14, %ymm14
	vdivps	%ymm8, %ymm14, %ymm14
	vpshufb	%ymm6, %ymm13, %ymm13
	vcvtdq2ps	%ymm13, %ymm13
	vdivps	%ymm8, %ymm13, %ymm13
	movq	%r13, %r11
	vaddps	%ymm9, %ymm13, %ymm13
	vaddps	%ymm9, %ymm14, %ymm14
	vmulps	%ymm1, %ymm13, %ymm13
	vmulps	%ymm1, %ymm14, %ymm14
	vcvttps2dq	%ymm14, %ymm14
	vpaddd	%ymm5, %ymm14, %ymm14
	vcvttps2dq	%ymm13, %ymm13
	vpaddd	%ymm12, %ymm13, %ymm13
	vpmaxsd	%ymm10, %ymm13, %ymm13
	vpmaxsd	%ymm10, %ymm14, %ymm14
	vpminsd	%ymm2, %ymm13, %ymm13
	vpminsd	%ymm3, %ymm14, %ymm14
	vpmulld	%ymm4, %ymm14, %ymm14
	vxorps	%xmm0, %xmm0, %xmm0
	vpaddd	%ymm13, %ymm14, %ymm13
	vpcmpeqd	%ymm14, %ymm14, %ymm14
	vpgatherdd	%ymm14, (%rdi,%ymm13,4), %ymm0
	vpaddd	%ymm11, %ymm12, %ymm12
	vmovdqu	%ymm0, (%r12,%r8,4)
	addq	$8, %r8
	addq	$16, %rbp
	addq	$32, %r13
	cmpq	%r10, %rbp
	jbe	.LBB0_668
# %bb.669:                              #   in Loop: Header=BB0_667 Depth=1
	cmpl	-72(%rsp), %r8d                 # 4-byte Folded Reload
	vmovaps	-40(%rsp), %xmm12               # 16-byte Reload
	vpmovzxbd	.LCPI0_11(%rip), %xmm13 # xmm13 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm14  # xmm14 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	jl	.LBB0_670
	jmp	.LBB0_679
	.p2align	4, 0x90
.LBB0_678:                              #   in Loop: Header=BB0_670 Depth=2
	imull	-72(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%edx, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	incq	%r8
	addq	$4, %r11
	cmpq	%r10, %r8
	jae	.LBB0_679
.LBB0_670:                              #   Parent Loop BB0_667 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm0
	shrl	$16, %ecx
	vpinsrd	$1, %ecx, %xmm0, %xmm0
	vpand	%xmm0, %xmm13, %xmm0
	vcvtdq2ps	%xmm0, %xmm0
	vdivps	%xmm14, %xmm0, %xmm0
	vbroadcastss	.LCPI0_2(%rip), %xmm5   # xmm5 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vaddps	%xmm5, %xmm0, %xmm0
	vmulps	%xmm0, %xmm12, %xmm0
	vcvttps2dq	%xmm0, %xmm0
	vpinsrd	$1, %r8d, %xmm15, %xmm5
	vpaddd	%xmm0, %xmm5, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_672
# %bb.671:                              #   in Loop: Header=BB0_670 Depth=2
	movl	%eax, %esi
.LBB0_672:                              #   in Loop: Header=BB0_670 Depth=2
	vpmovsxdq	%xmm5, %xmm0
	vmovmskpd	%xmm0, %r13d
	xorl	%ebp, %ebp
	movl	$0, %edx
	testb	$2, %r13b
	je	.LBB0_673
# %bb.674:                              #   in Loop: Header=BB0_670 Depth=2
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_675
.LBB0_676:                              #   in Loop: Header=BB0_670 Depth=2
	testb	$1, %r13b
	jne	.LBB0_678
	jmp	.LBB0_677
	.p2align	4, 0x90
.LBB0_673:                              #   in Loop: Header=BB0_670 Depth=2
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_676
.LBB0_675:                              #   in Loop: Header=BB0_670 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r13b
	jne	.LBB0_678
.LBB0_677:                              #   in Loop: Header=BB0_670 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_678
.LBB0_170:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -24(%rsp)                 # 8-byte Spill
	vbroadcastss	%xmm5, %xmm0
	vmovaps	%xmm0, -40(%rsp)                # 16-byte Spill
	leaq	(,%r10,4), %rcx
	movq	%rcx, -48(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vpbroadcastd	.LCPI0_7(%rip), %ymm5   # ymm5 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_1(%rip), %ymm6   # ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm8   # ymm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vmovdqa	.LCPI0_6(%rip), %ymm9           # ymm9 = [2,128,128,128,6,128,128,128,10,128,128,128,14,128,128,128,18,128,128,128,22,128,128,128,26,128,128,128,30,128,128,128]
	vpxor	%xmm10, %xmm10, %xmm10
	vpbroadcastd	.LCPI0_3(%rip), %ymm11  # ymm11 = [8,8,8,8,8,8,8,8]
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_171
	.p2align	4, 0x90
.LBB0_183:                              #   in Loop: Header=BB0_171 Depth=1
	incq	%r14
	movq	-48(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-24(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_171:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_172 Depth 2
                                        #     Child Loop BB0_174 Depth 2
	vmovd	%r14d, %xmm15
	vpbroadcastd	%xmm15, %ymm7
	movq	%rbx, %r13
	xorl	%r8d, %r8d
	vpmovsxbd	.LCPI0_14(%rip), %ymm12 # ymm12 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_172:                              #   Parent Loop BB0_171 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%r8, %rbp
	vmovdqu	(%r15,%r8,4), %ymm13
	vpshufb	%ymm9, %ymm13, %ymm14
	vcvtdq2ps	%ymm14, %ymm14
	vdivps	%ymm6, %ymm14, %ymm14
	vpand	%ymm5, %ymm13, %ymm13
	vcvtdq2ps	%ymm13, %ymm13
	vdivps	%ymm6, %ymm13, %ymm13
	movq	%r13, %r11
	vaddps	%ymm8, %ymm13, %ymm13
	vaddps	%ymm8, %ymm14, %ymm14
	vmulps	%ymm1, %ymm13, %ymm13
	vmulps	%ymm1, %ymm14, %ymm14
	vcvttps2dq	%ymm14, %ymm14
	vpaddd	%ymm7, %ymm14, %ymm14
	vcvttps2dq	%ymm13, %ymm13
	vpaddd	%ymm12, %ymm13, %ymm13
	vpmaxsd	%ymm10, %ymm13, %ymm13
	vpmaxsd	%ymm10, %ymm14, %ymm14
	vpminsd	%ymm2, %ymm13, %ymm13
	vpminsd	%ymm3, %ymm14, %ymm14
	vpmulld	%ymm4, %ymm14, %ymm14
	vxorps	%xmm0, %xmm0, %xmm0
	vpaddd	%ymm13, %ymm14, %ymm13
	vpcmpeqd	%ymm14, %ymm14, %ymm14
	vpgatherdd	%ymm14, (%rdi,%ymm13,4), %ymm0
	vpaddd	%ymm11, %ymm12, %ymm12
	vmovdqu	%ymm0, (%r12,%r8,4)
	addq	$8, %r8
	addq	$16, %rbp
	addq	$32, %r13
	cmpq	%r10, %rbp
	jbe	.LBB0_172
# %bb.173:                              #   in Loop: Header=BB0_171 Depth=1
	cmpl	-72(%rsp), %r8d                 # 4-byte Folded Reload
	vmovaps	-40(%rsp), %xmm12               # 16-byte Reload
	vpmovzxbd	.LCPI0_11(%rip), %xmm13 # xmm13 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm14  # xmm14 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	jl	.LBB0_174
	jmp	.LBB0_183
	.p2align	4, 0x90
.LBB0_182:                              #   in Loop: Header=BB0_174 Depth=2
	imull	-72(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%edx, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	incq	%r8
	addq	$4, %r11
	cmpq	%r10, %r8
	jae	.LBB0_183
.LBB0_174:                              #   Parent Loop BB0_171 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	vmovd	%edx, %xmm0
	vpinsrd	$1, %ecx, %xmm0, %xmm0
	vpand	%xmm0, %xmm13, %xmm0
	vcvtdq2ps	%xmm0, %xmm0
	vdivps	%xmm14, %xmm0, %xmm0
	vbroadcastss	.LCPI0_2(%rip), %xmm7   # xmm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vaddps	%xmm7, %xmm0, %xmm0
	vmulps	%xmm0, %xmm12, %xmm0
	vcvttps2dq	%xmm0, %xmm0
	vpinsrd	$1, %r8d, %xmm15, %xmm7
	vpaddd	%xmm0, %xmm7, %xmm7
	vpextrd	$1, %xmm7, %esi
	cmpl	%eax, %esi
	jl	.LBB0_176
# %bb.175:                              #   in Loop: Header=BB0_174 Depth=2
	movl	%eax, %esi
.LBB0_176:                              #   in Loop: Header=BB0_174 Depth=2
	vpmovsxdq	%xmm7, %xmm0
	vmovmskpd	%xmm0, %r13d
	xorl	%ebp, %ebp
	movl	$0, %edx
	testb	$2, %r13b
	je	.LBB0_177
# %bb.178:                              #   in Loop: Header=BB0_174 Depth=2
	vmovd	%xmm7, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_179
.LBB0_180:                              #   in Loop: Header=BB0_174 Depth=2
	testb	$1, %r13b
	jne	.LBB0_182
	jmp	.LBB0_181
	.p2align	4, 0x90
.LBB0_177:                              #   in Loop: Header=BB0_174 Depth=2
	movl	%esi, %edx
	vmovd	%xmm7, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_180
.LBB0_179:                              #   in Loop: Header=BB0_174 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r13b
	jne	.LBB0_182
.LBB0_181:                              #   in Loop: Header=BB0_174 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_182
.LBB0_748:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -24(%rsp)                 # 8-byte Spill
	vbroadcastss	%xmm5, %xmm0
	vmovaps	%xmm0, -40(%rsp)                # 16-byte Spill
	leaq	(,%r10,4), %rcx
	movq	%rcx, -48(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vpbroadcastd	.LCPI0_3(%rip), %ymm6   # ymm6 = [8,8,8,8,8,8,8,8]
	vmovdqa	.LCPI0_5(%rip), %ymm7           # ymm7 = [1,128,128,128,5,128,128,128,9,128,128,128,13,128,128,128,17,128,128,128,21,128,128,128,25,128,128,128,29,128,128,128]
	vbroadcastss	.LCPI0_7(%rip), %ymm8   # ymm8 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_1(%rip), %ymm9   # ymm9 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm10  # ymm10 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm11, %xmm11, %xmm11
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_749
	.p2align	4, 0x90
.LBB0_761:                              #   in Loop: Header=BB0_749 Depth=1
	incq	%r14
	movq	-48(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-24(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_749:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_750 Depth 2
                                        #     Child Loop BB0_752 Depth 2
	vmovd	%r14d, %xmm15
	vpbroadcastd	%xmm15, %ymm5
	movq	%rbx, %r13
	xorl	%r8d, %r8d
	vpmovsxbd	.LCPI0_14(%rip), %ymm12 # ymm12 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_750:                              #   Parent Loop BB0_749 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%r8, %rbp
	vmovups	(%r15,%r8,4), %ymm13
	vandps	%ymm13, %ymm8, %ymm14
	vcvtdq2ps	%ymm14, %ymm14
	vdivps	%ymm9, %ymm14, %ymm14
	vpshufb	%ymm7, %ymm13, %ymm13
	vcvtdq2ps	%ymm13, %ymm13
	vdivps	%ymm9, %ymm13, %ymm13
	movq	%r13, %r11
	vaddps	%ymm10, %ymm13, %ymm13
	vaddps	%ymm10, %ymm14, %ymm14
	vmulps	%ymm1, %ymm13, %ymm13
	vmulps	%ymm1, %ymm14, %ymm14
	vcvttps2dq	%ymm14, %ymm14
	vpaddd	%ymm5, %ymm14, %ymm14
	vcvttps2dq	%ymm13, %ymm13
	vpaddd	%ymm12, %ymm13, %ymm13
	vpmaxsd	%ymm11, %ymm13, %ymm13
	vpmaxsd	%ymm11, %ymm14, %ymm14
	vpminsd	%ymm2, %ymm13, %ymm13
	vpminsd	%ymm3, %ymm14, %ymm14
	vpmulld	%ymm4, %ymm14, %ymm14
	vpcmpeqd	%ymm0, %ymm0, %ymm0
	vpaddd	%ymm13, %ymm14, %ymm13
	vpxor	%xmm14, %xmm14, %xmm14
	vpgatherdd	%ymm0, (%rdi,%ymm13,4), %ymm14
	vpaddd	%ymm6, %ymm12, %ymm12
	vmovdqu	%ymm14, (%r12,%r8,4)
	addq	$8, %r8
	addq	$16, %rbp
	addq	$32, %r13
	cmpq	%r10, %rbp
	jbe	.LBB0_750
# %bb.751:                              #   in Loop: Header=BB0_749 Depth=1
	cmpl	-72(%rsp), %r8d                 # 4-byte Folded Reload
	vmovaps	-40(%rsp), %xmm12               # 16-byte Reload
	vpmovzxbd	.LCPI0_11(%rip), %xmm13 # xmm13 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm14  # xmm14 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	jl	.LBB0_752
	jmp	.LBB0_761
	.p2align	4, 0x90
.LBB0_760:                              #   in Loop: Header=BB0_752 Depth=2
	imull	-72(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%edx, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	incq	%r8
	addq	$4, %r11
	cmpq	%r10, %r8
	jae	.LBB0_761
.LBB0_752:                              #   Parent Loop BB0_749 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm0
	shrl	$8, %ecx
	vpinsrd	$1, %ecx, %xmm0, %xmm0
	vpand	%xmm0, %xmm13, %xmm0
	vcvtdq2ps	%xmm0, %xmm0
	vdivps	%xmm14, %xmm0, %xmm0
	vbroadcastss	.LCPI0_2(%rip), %xmm5   # xmm5 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vaddps	%xmm5, %xmm0, %xmm0
	vmulps	%xmm0, %xmm12, %xmm0
	vcvttps2dq	%xmm0, %xmm0
	vpinsrd	$1, %r8d, %xmm15, %xmm5
	vpaddd	%xmm0, %xmm5, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_754
# %bb.753:                              #   in Loop: Header=BB0_752 Depth=2
	movl	%eax, %esi
.LBB0_754:                              #   in Loop: Header=BB0_752 Depth=2
	vpmovsxdq	%xmm5, %xmm0
	vmovmskpd	%xmm0, %r13d
	xorl	%ebp, %ebp
	movl	$0, %edx
	testb	$2, %r13b
	je	.LBB0_755
# %bb.756:                              #   in Loop: Header=BB0_752 Depth=2
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_757
.LBB0_758:                              #   in Loop: Header=BB0_752 Depth=2
	testb	$1, %r13b
	jne	.LBB0_760
	jmp	.LBB0_759
	.p2align	4, 0x90
.LBB0_755:                              #   in Loop: Header=BB0_752 Depth=2
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_758
.LBB0_757:                              #   in Loop: Header=BB0_752 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r13b
	jne	.LBB0_760
.LBB0_759:                              #   in Loop: Header=BB0_752 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_760
.LBB0_500:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -24(%rsp)                 # 8-byte Spill
	vbroadcastss	%xmm5, %xmm0
	vmovaps	%xmm0, -40(%rsp)                # 16-byte Spill
	leaq	(,%r10,4), %rcx
	movq	%rcx, -48(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vpbroadcastd	.LCPI0_3(%rip), %ymm5   # ymm5 = [8,8,8,8,8,8,8,8]
	vpbroadcastd	.LCPI0_7(%rip), %ymm6   # ymm6 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_1(%rip), %ymm7   # ymm7 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm8   # ymm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vmovdqa	.LCPI0_5(%rip), %ymm10          # ymm10 = [1,128,128,128,5,128,128,128,9,128,128,128,13,128,128,128,17,128,128,128,21,128,128,128,25,128,128,128,29,128,128,128]
	vpxor	%xmm11, %xmm11, %xmm11
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_501
	.p2align	4, 0x90
.LBB0_513:                              #   in Loop: Header=BB0_501 Depth=1
	incq	%r14
	movq	-48(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-24(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_501:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_502 Depth 2
                                        #     Child Loop BB0_504 Depth 2
	vmovd	%r14d, %xmm15
	vpbroadcastd	%xmm15, %ymm9
	movq	%rbx, %r13
	xorl	%r8d, %r8d
	vpmovsxbd	.LCPI0_14(%rip), %ymm12 # ymm12 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_502:                              #   Parent Loop BB0_501 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%r8, %rbp
	vmovdqu	(%r15,%r8,4), %ymm13
	vpshufb	%ymm10, %ymm13, %ymm14
	vcvtdq2ps	%ymm14, %ymm14
	vdivps	%ymm7, %ymm14, %ymm14
	vpand	%ymm6, %ymm13, %ymm13
	vcvtdq2ps	%ymm13, %ymm13
	vdivps	%ymm7, %ymm13, %ymm13
	movq	%r13, %r11
	vaddps	%ymm8, %ymm13, %ymm13
	vaddps	%ymm8, %ymm14, %ymm14
	vmulps	%ymm1, %ymm13, %ymm13
	vmulps	%ymm1, %ymm14, %ymm14
	vcvttps2dq	%ymm14, %ymm14
	vpaddd	%ymm9, %ymm14, %ymm14
	vcvttps2dq	%ymm13, %ymm13
	vpaddd	%ymm12, %ymm13, %ymm13
	vpmaxsd	%ymm11, %ymm13, %ymm13
	vpmaxsd	%ymm11, %ymm14, %ymm14
	vpminsd	%ymm2, %ymm13, %ymm13
	vpminsd	%ymm3, %ymm14, %ymm14
	vpmulld	%ymm4, %ymm14, %ymm14
	vxorps	%xmm0, %xmm0, %xmm0
	vpaddd	%ymm13, %ymm14, %ymm13
	vpcmpeqd	%ymm14, %ymm14, %ymm14
	vpgatherdd	%ymm14, (%rdi,%ymm13,4), %ymm0
	vpaddd	%ymm5, %ymm12, %ymm12
	vmovdqu	%ymm0, (%r12,%r8,4)
	addq	$8, %r8
	addq	$16, %rbp
	addq	$32, %r13
	cmpq	%r10, %rbp
	jbe	.LBB0_502
# %bb.503:                              #   in Loop: Header=BB0_501 Depth=1
	cmpl	-72(%rsp), %r8d                 # 4-byte Folded Reload
	vmovaps	-40(%rsp), %xmm12               # 16-byte Reload
	vpmovzxbd	.LCPI0_11(%rip), %xmm13 # xmm13 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm14  # xmm14 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	jl	.LBB0_504
	jmp	.LBB0_513
	.p2align	4, 0x90
.LBB0_512:                              #   in Loop: Header=BB0_504 Depth=2
	imull	-72(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%edx, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	incq	%r8
	addq	$4, %r11
	cmpq	%r10, %r8
	jae	.LBB0_513
.LBB0_504:                              #   Parent Loop BB0_501 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$8, %edx
	vmovd	%edx, %xmm0
	vpinsrd	$1, %ecx, %xmm0, %xmm0
	vpand	%xmm0, %xmm13, %xmm0
	vcvtdq2ps	%xmm0, %xmm0
	vdivps	%xmm14, %xmm0, %xmm0
	vbroadcastss	.LCPI0_2(%rip), %xmm9   # xmm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vaddps	%xmm0, %xmm9, %xmm0
	vmulps	%xmm0, %xmm12, %xmm0
	vcvttps2dq	%xmm0, %xmm0
	vpinsrd	$1, %r8d, %xmm15, %xmm9
	vpaddd	%xmm0, %xmm9, %xmm9
	vpextrd	$1, %xmm9, %esi
	cmpl	%eax, %esi
	jl	.LBB0_506
# %bb.505:                              #   in Loop: Header=BB0_504 Depth=2
	movl	%eax, %esi
.LBB0_506:                              #   in Loop: Header=BB0_504 Depth=2
	vpmovsxdq	%xmm9, %xmm0
	vmovmskpd	%xmm0, %r13d
	xorl	%ebp, %ebp
	movl	$0, %edx
	testb	$2, %r13b
	je	.LBB0_507
# %bb.508:                              #   in Loop: Header=BB0_504 Depth=2
	vmovd	%xmm9, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_509
.LBB0_510:                              #   in Loop: Header=BB0_504 Depth=2
	testb	$1, %r13b
	jne	.LBB0_512
	jmp	.LBB0_511
	.p2align	4, 0x90
.LBB0_507:                              #   in Loop: Header=BB0_504 Depth=2
	movl	%esi, %edx
	vmovd	%xmm9, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_510
.LBB0_509:                              #   in Loop: Header=BB0_504 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r13b
	jne	.LBB0_512
.LBB0_511:                              #   in Loop: Header=BB0_504 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_512
.LBB0_1242:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -40(%rsp)                 # 8-byte Spill
	leaq	(,%r10,4), %rcx
	movq	%rcx, -48(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vbroadcastss	.LCPI0_1(%rip), %ymm5   # ymm5 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm6   # ymm6 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpmovsxbd	.LCPI0_14(%rip), %ymm7  # ymm7 = [0,1,2,3,4,5,6,7]
	vpxor	%xmm8, %xmm8, %xmm8
	vpbroadcastd	.LCPI0_3(%rip), %ymm9   # ymm9 = [8,8,8,8,8,8,8,8]
	vmovss	.LCPI0_1(%rip), %xmm10          # xmm10 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm11          # xmm11 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_1243
	.p2align	4, 0x90
.LBB0_1255:                             #   in Loop: Header=BB0_1243 Depth=1
	incq	%r14
	movq	-48(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-40(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_1243:                             # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_1244 Depth 2
                                        #     Child Loop BB0_1246 Depth 2
	vmovd	%r14d, %xmm0
	vpbroadcastd	%xmm0, %ymm12
	movq	%rbx, %rdx
	xorl	%ebp, %ebp
	vmovdqa	%ymm7, %ymm13
	.p2align	4, 0x90
.LBB0_1244:                             #   Parent Loop BB0_1243 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %rcx
	vmovdqu	(%r15,%rbp,4), %ymm0
	vpsrld	$24, %ymm0, %ymm0
	vcvtdq2ps	%ymm0, %ymm0
	vdivps	%ymm5, %ymm0, %ymm0
	movq	%rdx, %r13
	vaddps	%ymm6, %ymm0, %ymm0
	vmulps	%ymm0, %ymm1, %ymm0
	vcvttps2dq	%ymm0, %ymm0
	vpaddd	%ymm0, %ymm13, %ymm14
	vpmaxsd	%ymm8, %ymm14, %ymm14
	vpaddd	%ymm0, %ymm12, %ymm0
	vpmaxsd	%ymm8, %ymm0, %ymm0
	vpminsd	%ymm2, %ymm14, %ymm14
	vpminsd	%ymm3, %ymm0, %ymm0
	vpmulld	%ymm4, %ymm0, %ymm0
	vpxor	%xmm15, %xmm15, %xmm15
	vpaddd	%ymm0, %ymm14, %ymm0
	vpcmpeqd	%ymm14, %ymm14, %ymm14
	vpgatherdd	%ymm14, (%rdi,%ymm0,4), %ymm15
	vpaddd	%ymm9, %ymm13, %ymm13
	vmovdqu	%ymm15, (%r12,%rbp,4)
	addq	$8, %rbp
	addq	$16, %rcx
	addq	$32, %rdx
	cmpq	%r10, %rcx
	jbe	.LBB0_1244
# %bb.1245:                             #   in Loop: Header=BB0_1243 Depth=1
	cmpl	-72(%rsp), %ebp                 # 4-byte Folded Reload
	vmovaps	-24(%rsp), %xmm12               # 16-byte Reload
	jl	.LBB0_1246
	jmp	.LBB0_1255
	.p2align	4, 0x90
.LBB0_1254:                             #   in Loop: Header=BB0_1246 Depth=2
	imull	-72(%rsp), %r11d                # 4-byte Folded Reload
	addl	%edx, %r11d
	movslq	%r11d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_1255
.LBB0_1246:                             #   Parent Loop BB0_1243 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	3(%rcx,%r13), %ecx
	vcvtsi2ss	%ecx, %xmm1, %xmm0
	vdivss	%xmm10, %xmm0, %xmm0
	vaddss	%xmm0, %xmm11, %xmm0
	vmulss	%xmm0, %xmm12, %xmm0
	vcvttss2si	%xmm0, %r8d
	leal	(%r8,%rbp), %esi
	movl	%esi, %ecx
	cmpl	%eax, %esi
	jge	.LBB0_1247
# %bb.1248:                             #   in Loop: Header=BB0_1246 Depth=2
	xorl	%r11d, %r11d
	movl	$0, %edx
	testl	%esi, %esi
	jns	.LBB0_1249
.LBB0_1250:                             #   in Loop: Header=BB0_1246 Depth=2
	addl	%r14d, %r8d
	movl	%r8d, %ecx
	cmpl	%r9d, %r8d
	jge	.LBB0_1251
.LBB0_1252:                             #   in Loop: Header=BB0_1246 Depth=2
	testl	%r8d, %r8d
	js	.LBB0_1254
	jmp	.LBB0_1253
	.p2align	4, 0x90
.LBB0_1247:                             #   in Loop: Header=BB0_1246 Depth=2
	movl	%eax, %ecx
	xorl	%r11d, %r11d
	movl	$0, %edx
	testl	%esi, %esi
	js	.LBB0_1250
.LBB0_1249:                             #   in Loop: Header=BB0_1246 Depth=2
	movl	%ecx, %edx
	addl	%r14d, %r8d
	movl	%r8d, %ecx
	cmpl	%r9d, %r8d
	jl	.LBB0_1252
.LBB0_1251:                             #   in Loop: Header=BB0_1246 Depth=2
	movl	%r9d, %ecx
	testl	%r8d, %r8d
	js	.LBB0_1254
.LBB0_1253:                             #   in Loop: Header=BB0_1246 Depth=2
	movl	%ecx, %r11d
	jmp	.LBB0_1254
.LBB0_996:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -24(%rsp)                 # 8-byte Spill
	vbroadcastss	%xmm5, %xmm0
	leaq	(,%r10,4), %rcx
	movq	%rcx, -40(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vbroadcastss	.LCPI0_1(%rip), %ymm6   # ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm7   # ymm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vmovdqa	.LCPI0_6(%rip), %ymm8           # ymm8 = [2,128,128,128,6,128,128,128,10,128,128,128,14,128,128,128,18,128,128,128,22,128,128,128,26,128,128,128,30,128,128,128]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %ymm10  # ymm10 = [8,8,8,8,8,8,8,8]
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_997
	.p2align	4, 0x90
.LBB0_1009:                             #   in Loop: Header=BB0_997 Depth=1
	incq	%r14
	movq	-40(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-24(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_997:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_998 Depth 2
                                        #     Child Loop BB0_1000 Depth 2
	vmovd	%r14d, %xmm13
	vpbroadcastd	%xmm13, %ymm14
	movq	%rbx, %r13
	xorl	%r8d, %r8d
	vpmovsxbd	.LCPI0_14(%rip), %ymm15 # ymm15 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_998:                              #   Parent Loop BB0_997 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%r8, %rbp
	vmovdqu	(%r15,%r8,4), %ymm5
	vpsrld	$24, %ymm5, %ymm11
	vcvtdq2ps	%ymm11, %ymm11
	vdivps	%ymm6, %ymm11, %ymm11
	vpshufb	%ymm8, %ymm5, %ymm5
	vcvtdq2ps	%ymm5, %ymm5
	vdivps	%ymm6, %ymm5, %ymm5
	movq	%r13, %r11
	vaddps	%ymm7, %ymm5, %ymm5
	vaddps	%ymm7, %ymm11, %ymm11
	vmulps	%ymm5, %ymm1, %ymm5
	vmulps	%ymm1, %ymm11, %ymm11
	vcvttps2dq	%ymm11, %ymm11
	vpaddd	%ymm14, %ymm11, %ymm11
	vcvttps2dq	%ymm5, %ymm5
	vpaddd	%ymm5, %ymm15, %ymm5
	vpmaxsd	%ymm9, %ymm5, %ymm5
	vpmaxsd	%ymm9, %ymm11, %ymm11
	vpminsd	%ymm2, %ymm5, %ymm5
	vpminsd	%ymm3, %ymm11, %ymm11
	vpmulld	%ymm4, %ymm11, %ymm11
	vpcmpeqd	%ymm12, %ymm12, %ymm12
	vpaddd	%ymm5, %ymm11, %ymm5
	vpxor	%xmm11, %xmm11, %xmm11
	vpgatherdd	%ymm12, (%rdi,%ymm5,4), %ymm11
	vpaddd	%ymm10, %ymm15, %ymm15
	vmovdqu	%ymm11, (%r12,%r8,4)
	addq	$8, %r8
	addq	$16, %rbp
	addq	$32, %r13
	cmpq	%r10, %rbp
	jbe	.LBB0_998
# %bb.999:                              #   in Loop: Header=BB0_997 Depth=1
	cmpl	-72(%rsp), %r8d                 # 4-byte Folded Reload
	vbroadcastss	.LCPI0_1(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm15  # xmm15 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	jl	.LBB0_1000
	jmp	.LBB0_1009
	.p2align	4, 0x90
.LBB0_1008:                             #   in Loop: Header=BB0_1000 Depth=2
	imull	-72(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%edx, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	incq	%r8
	addq	$4, %r11
	cmpq	%r10, %r8
	jae	.LBB0_1009
.LBB0_1000:                             #   Parent Loop BB0_997 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	movzbl	%dl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm5
	vpinsrd	$1, %edx, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm12, %xmm5, %xmm5
	vaddps	%xmm5, %xmm15, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r8d, %xmm13, %xmm11
	vpaddd	%xmm5, %xmm11, %xmm14
	vpextrd	$1, %xmm14, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1002
# %bb.1001:                             #   in Loop: Header=BB0_1000 Depth=2
	movl	%eax, %esi
.LBB0_1002:                             #   in Loop: Header=BB0_1000 Depth=2
	vpmovsxdq	%xmm14, %xmm5
	vmovmskpd	%xmm5, %r13d
	xorl	%ebp, %ebp
	movl	$0, %edx
	testb	$2, %r13b
	je	.LBB0_1003
# %bb.1004:                             #   in Loop: Header=BB0_1000 Depth=2
	vmovd	%xmm14, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1005
.LBB0_1006:                             #   in Loop: Header=BB0_1000 Depth=2
	testb	$1, %r13b
	jne	.LBB0_1008
	jmp	.LBB0_1007
	.p2align	4, 0x90
.LBB0_1003:                             #   in Loop: Header=BB0_1000 Depth=2
	movl	%esi, %edx
	vmovd	%xmm14, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1006
.LBB0_1005:                             #   in Loop: Header=BB0_1000 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r13b
	jne	.LBB0_1008
.LBB0_1007:                             #   in Loop: Header=BB0_1000 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_1008
.LBB0_252:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -24(%rsp)                 # 8-byte Spill
	vbroadcastss	%xmm5, %xmm0
	leaq	(,%r10,4), %rcx
	movq	%rcx, -40(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vbroadcastss	.LCPI0_1(%rip), %ymm6   # ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm7   # ymm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vmovdqa	.LCPI0_6(%rip), %ymm8           # ymm8 = [2,128,128,128,6,128,128,128,10,128,128,128,14,128,128,128,18,128,128,128,22,128,128,128,26,128,128,128,30,128,128,128]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %ymm10  # ymm10 = [8,8,8,8,8,8,8,8]
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_253
	.p2align	4, 0x90
.LBB0_265:                              #   in Loop: Header=BB0_253 Depth=1
	incq	%r14
	movq	-40(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-24(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_253:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_254 Depth 2
                                        #     Child Loop BB0_256 Depth 2
	vmovd	%r14d, %xmm13
	vpbroadcastd	%xmm13, %ymm14
	movq	%rbx, %r13
	xorl	%r8d, %r8d
	vpmovsxbd	.LCPI0_14(%rip), %ymm15 # ymm15 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_254:                              #   Parent Loop BB0_253 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%r8, %rbp
	vmovdqu	(%r15,%r8,4), %ymm5
	vpshufb	%ymm8, %ymm5, %ymm11
	vcvtdq2ps	%ymm11, %ymm11
	vdivps	%ymm6, %ymm11, %ymm11
	vpsrld	$24, %ymm5, %ymm5
	vcvtdq2ps	%ymm5, %ymm5
	vdivps	%ymm6, %ymm5, %ymm5
	movq	%r13, %r11
	vaddps	%ymm7, %ymm5, %ymm5
	vaddps	%ymm7, %ymm11, %ymm11
	vmulps	%ymm5, %ymm1, %ymm5
	vmulps	%ymm1, %ymm11, %ymm11
	vcvttps2dq	%ymm11, %ymm11
	vpaddd	%ymm14, %ymm11, %ymm11
	vcvttps2dq	%ymm5, %ymm5
	vpaddd	%ymm5, %ymm15, %ymm5
	vpmaxsd	%ymm9, %ymm5, %ymm5
	vpmaxsd	%ymm9, %ymm11, %ymm11
	vpminsd	%ymm2, %ymm5, %ymm5
	vpminsd	%ymm3, %ymm11, %ymm11
	vpmulld	%ymm4, %ymm11, %ymm11
	vpxor	%xmm12, %xmm12, %xmm12
	vpaddd	%ymm5, %ymm11, %ymm5
	vpcmpeqd	%ymm11, %ymm11, %ymm11
	vpgatherdd	%ymm11, (%rdi,%ymm5,4), %ymm12
	vpaddd	%ymm10, %ymm15, %ymm15
	vmovdqu	%ymm12, (%r12,%r8,4)
	addq	$8, %r8
	addq	$16, %rbp
	addq	$32, %r13
	cmpq	%r10, %rbp
	jbe	.LBB0_254
# %bb.255:                              #   in Loop: Header=BB0_253 Depth=1
	cmpl	-72(%rsp), %r8d                 # 4-byte Folded Reload
	vbroadcastss	.LCPI0_1(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm15  # xmm15 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	jl	.LBB0_256
	jmp	.LBB0_265
	.p2align	4, 0x90
.LBB0_264:                              #   in Loop: Header=BB0_256 Depth=2
	imull	-72(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%edx, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	incq	%r8
	addq	$4, %r11
	cmpq	%r10, %r8
	jae	.LBB0_265
.LBB0_256:                              #   Parent Loop BB0_253 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$24, %edx
	shrl	$16, %ecx
	movzbl	%cl, %ecx
	vmovd	%ecx, %xmm5
	vpinsrd	$1, %edx, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm12, %xmm5, %xmm5
	vaddps	%xmm5, %xmm15, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r8d, %xmm13, %xmm11
	vpaddd	%xmm5, %xmm11, %xmm14
	vpextrd	$1, %xmm14, %esi
	cmpl	%eax, %esi
	jl	.LBB0_258
# %bb.257:                              #   in Loop: Header=BB0_256 Depth=2
	movl	%eax, %esi
.LBB0_258:                              #   in Loop: Header=BB0_256 Depth=2
	vpmovsxdq	%xmm14, %xmm5
	vmovmskpd	%xmm5, %r13d
	xorl	%ebp, %ebp
	movl	$0, %edx
	testb	$2, %r13b
	je	.LBB0_259
# %bb.260:                              #   in Loop: Header=BB0_256 Depth=2
	vmovd	%xmm14, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_261
.LBB0_262:                              #   in Loop: Header=BB0_256 Depth=2
	testb	$1, %r13b
	jne	.LBB0_264
	jmp	.LBB0_263
	.p2align	4, 0x90
.LBB0_259:                              #   in Loop: Header=BB0_256 Depth=2
	movl	%esi, %edx
	vmovd	%xmm14, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_262
.LBB0_261:                              #   in Loop: Header=BB0_256 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r13b
	jne	.LBB0_264
.LBB0_263:                              #   in Loop: Header=BB0_256 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_264
.LBB0_1078:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -24(%rsp)                 # 8-byte Spill
	vbroadcastss	%xmm5, %xmm0
	leaq	(,%r10,4), %rcx
	movq	%rcx, -40(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vpbroadcastd	.LCPI0_3(%rip), %ymm6   # ymm6 = [8,8,8,8,8,8,8,8]
	vbroadcastss	.LCPI0_1(%rip), %ymm7   # ymm7 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vmovdqa	.LCPI0_5(%rip), %ymm8           # ymm8 = [1,128,128,128,5,128,128,128,9,128,128,128,13,128,128,128,17,128,128,128,21,128,128,128,25,128,128,128,29,128,128,128]
	vbroadcastss	.LCPI0_2(%rip), %ymm9   # ymm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm10, %xmm10, %xmm10
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_1079
	.p2align	4, 0x90
.LBB0_1091:                             #   in Loop: Header=BB0_1079 Depth=1
	incq	%r14
	movq	-40(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-24(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_1079:                             # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_1080 Depth 2
                                        #     Child Loop BB0_1082 Depth 2
	vmovd	%r14d, %xmm13
	vpbroadcastd	%xmm13, %ymm14
	movq	%rbx, %r13
	xorl	%r8d, %r8d
	vpmovsxbd	.LCPI0_14(%rip), %ymm15 # ymm15 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_1080:                             #   Parent Loop BB0_1079 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%r8, %rbp
	vmovdqu	(%r15,%r8,4), %ymm5
	vpsrld	$24, %ymm5, %ymm11
	vcvtdq2ps	%ymm11, %ymm11
	vdivps	%ymm7, %ymm11, %ymm11
	vpshufb	%ymm8, %ymm5, %ymm5
	vcvtdq2ps	%ymm5, %ymm5
	vdivps	%ymm7, %ymm5, %ymm5
	movq	%r13, %r11
	vaddps	%ymm5, %ymm9, %ymm5
	vaddps	%ymm9, %ymm11, %ymm11
	vmulps	%ymm5, %ymm1, %ymm5
	vmulps	%ymm1, %ymm11, %ymm11
	vcvttps2dq	%ymm11, %ymm11
	vpaddd	%ymm14, %ymm11, %ymm11
	vcvttps2dq	%ymm5, %ymm5
	vpaddd	%ymm5, %ymm15, %ymm5
	vpmaxsd	%ymm10, %ymm5, %ymm5
	vpmaxsd	%ymm10, %ymm11, %ymm11
	vpminsd	%ymm2, %ymm5, %ymm5
	vpminsd	%ymm3, %ymm11, %ymm11
	vpmulld	%ymm4, %ymm11, %ymm11
	vpxor	%xmm12, %xmm12, %xmm12
	vpaddd	%ymm5, %ymm11, %ymm5
	vpcmpeqd	%ymm11, %ymm11, %ymm11
	vpgatherdd	%ymm11, (%rdi,%ymm5,4), %ymm12
	vpaddd	%ymm6, %ymm15, %ymm15
	vmovdqu	%ymm12, (%r12,%r8,4)
	addq	$8, %r8
	addq	$16, %rbp
	addq	$32, %r13
	cmpq	%r10, %rbp
	jbe	.LBB0_1080
# %bb.1081:                             #   in Loop: Header=BB0_1079 Depth=1
	cmpl	-72(%rsp), %r8d                 # 4-byte Folded Reload
	vbroadcastss	.LCPI0_1(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm15  # xmm15 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	jl	.LBB0_1082
	jmp	.LBB0_1091
	.p2align	4, 0x90
.LBB0_1090:                             #   in Loop: Header=BB0_1082 Depth=2
	imull	-72(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%edx, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	incq	%r8
	addq	$4, %r11
	cmpq	%r10, %r8
	jae	.LBB0_1091
.LBB0_1082:                             #   Parent Loop BB0_1079 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm5
	vpinsrd	$1, %edx, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm12, %xmm5, %xmm5
	vaddps	%xmm5, %xmm15, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r8d, %xmm13, %xmm11
	vpaddd	%xmm5, %xmm11, %xmm14
	vpextrd	$1, %xmm14, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1084
# %bb.1083:                             #   in Loop: Header=BB0_1082 Depth=2
	movl	%eax, %esi
.LBB0_1084:                             #   in Loop: Header=BB0_1082 Depth=2
	vpmovsxdq	%xmm14, %xmm5
	vmovmskpd	%xmm5, %r13d
	xorl	%ebp, %ebp
	movl	$0, %edx
	testb	$2, %r13b
	je	.LBB0_1085
# %bb.1086:                             #   in Loop: Header=BB0_1082 Depth=2
	vmovd	%xmm14, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1087
.LBB0_1088:                             #   in Loop: Header=BB0_1082 Depth=2
	testb	$1, %r13b
	jne	.LBB0_1090
	jmp	.LBB0_1089
	.p2align	4, 0x90
.LBB0_1085:                             #   in Loop: Header=BB0_1082 Depth=2
	movl	%esi, %edx
	vmovd	%xmm14, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1088
.LBB0_1087:                             #   in Loop: Header=BB0_1082 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r13b
	jne	.LBB0_1090
.LBB0_1089:                             #   in Loop: Header=BB0_1082 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_1090
.LBB0_582:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -24(%rsp)                 # 8-byte Spill
	vbroadcastss	%xmm5, %xmm0
	leaq	(,%r10,4), %rcx
	movq	%rcx, -40(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vpbroadcastd	.LCPI0_3(%rip), %ymm6   # ymm6 = [8,8,8,8,8,8,8,8]
	vbroadcastss	.LCPI0_1(%rip), %ymm7   # ymm7 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm8   # ymm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vmovdqa	.LCPI0_5(%rip), %ymm9           # ymm9 = [1,128,128,128,5,128,128,128,9,128,128,128,13,128,128,128,17,128,128,128,21,128,128,128,25,128,128,128,29,128,128,128]
	vpxor	%xmm10, %xmm10, %xmm10
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_583
	.p2align	4, 0x90
.LBB0_595:                              #   in Loop: Header=BB0_583 Depth=1
	incq	%r14
	movq	-40(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-24(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_583:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_584 Depth 2
                                        #     Child Loop BB0_586 Depth 2
	vmovd	%r14d, %xmm13
	vpbroadcastd	%xmm13, %ymm14
	movq	%rbx, %r13
	xorl	%r8d, %r8d
	vpmovsxbd	.LCPI0_14(%rip), %ymm15 # ymm15 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_584:                              #   Parent Loop BB0_583 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%r8, %rbp
	vmovdqu	(%r15,%r8,4), %ymm5
	vpshufb	%ymm9, %ymm5, %ymm11
	vcvtdq2ps	%ymm11, %ymm11
	vdivps	%ymm7, %ymm11, %ymm11
	vpsrld	$24, %ymm5, %ymm5
	vcvtdq2ps	%ymm5, %ymm5
	vdivps	%ymm7, %ymm5, %ymm5
	movq	%r13, %r11
	vaddps	%ymm5, %ymm8, %ymm5
	vaddps	%ymm8, %ymm11, %ymm11
	vmulps	%ymm5, %ymm1, %ymm5
	vmulps	%ymm1, %ymm11, %ymm11
	vcvttps2dq	%ymm11, %ymm11
	vpaddd	%ymm14, %ymm11, %ymm11
	vcvttps2dq	%ymm5, %ymm5
	vpaddd	%ymm5, %ymm15, %ymm5
	vpmaxsd	%ymm10, %ymm5, %ymm5
	vpmaxsd	%ymm10, %ymm11, %ymm11
	vpminsd	%ymm2, %ymm5, %ymm5
	vpminsd	%ymm3, %ymm11, %ymm11
	vpmulld	%ymm4, %ymm11, %ymm11
	vpxor	%xmm12, %xmm12, %xmm12
	vpaddd	%ymm5, %ymm11, %ymm5
	vpcmpeqd	%ymm11, %ymm11, %ymm11
	vpgatherdd	%ymm11, (%rdi,%ymm5,4), %ymm12
	vpaddd	%ymm6, %ymm15, %ymm15
	vmovdqu	%ymm12, (%r12,%r8,4)
	addq	$8, %r8
	addq	$16, %rbp
	addq	$32, %r13
	cmpq	%r10, %rbp
	jbe	.LBB0_584
# %bb.585:                              #   in Loop: Header=BB0_583 Depth=1
	cmpl	-72(%rsp), %r8d                 # 4-byte Folded Reload
	vbroadcastss	.LCPI0_1(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm15  # xmm15 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	jl	.LBB0_586
	jmp	.LBB0_595
	.p2align	4, 0x90
.LBB0_594:                              #   in Loop: Header=BB0_586 Depth=2
	imull	-72(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%edx, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	incq	%r8
	addq	$4, %r11
	cmpq	%r10, %r8
	jae	.LBB0_595
.LBB0_586:                              #   Parent Loop BB0_583 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm12, %xmm5, %xmm5
	vaddps	%xmm5, %xmm15, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r8d, %xmm13, %xmm11
	vpaddd	%xmm5, %xmm11, %xmm14
	vpextrd	$1, %xmm14, %esi
	cmpl	%eax, %esi
	jl	.LBB0_588
# %bb.587:                              #   in Loop: Header=BB0_586 Depth=2
	movl	%eax, %esi
.LBB0_588:                              #   in Loop: Header=BB0_586 Depth=2
	vpmovsxdq	%xmm14, %xmm5
	vmovmskpd	%xmm5, %r13d
	xorl	%ebp, %ebp
	movl	$0, %edx
	testb	$2, %r13b
	je	.LBB0_589
# %bb.590:                              #   in Loop: Header=BB0_586 Depth=2
	vmovd	%xmm14, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_591
.LBB0_592:                              #   in Loop: Header=BB0_586 Depth=2
	testb	$1, %r13b
	jne	.LBB0_594
	jmp	.LBB0_593
	.p2align	4, 0x90
.LBB0_589:                              #   in Loop: Header=BB0_586 Depth=2
	movl	%esi, %edx
	vmovd	%xmm14, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_592
.LBB0_591:                              #   in Loop: Header=BB0_586 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r13b
	jne	.LBB0_594
.LBB0_593:                              #   in Loop: Header=BB0_586 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_594
.LBB0_6:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%edx, %xmm2
	vpbroadcastd	%xmm2, %ymm2
	vmovd	%r9d, %xmm3
	vpbroadcastd	%xmm3, %ymm3
	vmovd	%eax, %xmm4
	vpbroadcastd	%xmm4, %ymm4
	movl	%eax, %r10d
	movl	%r8d, %eax
	movq	%rax, -40(%rsp)                 # 8-byte Spill
	leaq	(,%r10,4), %rax
	movq	%rax, -48(%rsp)                 # 8-byte Spill
	movl	$32, %ecx
	xorl	%r14d, %r14d
	vbroadcastss	.LCPI0_1(%rip), %ymm6   # ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm7   # ymm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vmovdqa	.LCPI0_6(%rip), %ymm8           # ymm8 = [2,128,128,128,6,128,128,128,10,128,128,128,14,128,128,128,18,128,128,128,22,128,128,128,26,128,128,128,30,128,128,128]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %ymm10  # ymm10 = [8,8,8,8,8,8,8,8]
	vmovss	.LCPI0_1(%rip), %xmm0           # xmm0 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm12          # xmm12 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_7
	.p2align	4, 0x90
.LBB0_19:                               #   in Loop: Header=BB0_7 Depth=1
	incq	%r14
	movq	-48(%rsp), %rax                 # 8-byte Reload
	addq	%rax, %r12
	addq	%rax, %r15
	addq	%rax, %rcx
	cmpq	-40(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_7:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_8 Depth 2
                                        #     Child Loop BB0_10 Depth 2
	vmovd	%r14d, %xmm13
	vpbroadcastd	%xmm13, %ymm13
	movq	%rcx, %r8
	xorl	%ebp, %ebp
	vpmovsxbd	.LCPI0_14(%rip), %ymm14 # ymm14 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_8:                                #   Parent Loop BB0_7 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %rax
	vmovdqu	(%r15,%rbp,4), %ymm15
	vpshufb	%ymm8, %ymm15, %ymm15
	vcvtdq2ps	%ymm15, %ymm15
	vdivps	%ymm6, %ymm15, %ymm15
	movq	%r8, %r13
	vaddps	%ymm7, %ymm15, %ymm15
	vmulps	%ymm1, %ymm15, %ymm15
	vcvttps2dq	%ymm15, %ymm15
	vpaddd	%ymm14, %ymm15, %ymm5
	vpmaxsd	%ymm9, %ymm5, %ymm5
	vpaddd	%ymm13, %ymm15, %ymm15
	vpmaxsd	%ymm9, %ymm15, %ymm15
	vpminsd	%ymm2, %ymm5, %ymm5
	vpminsd	%ymm3, %ymm15, %ymm15
	vpmulld	%ymm4, %ymm15, %ymm15
	vpxor	%xmm11, %xmm11, %xmm11
	vpaddd	%ymm5, %ymm15, %ymm5
	vpcmpeqd	%ymm15, %ymm15, %ymm15
	vpgatherdd	%ymm15, (%rdi,%ymm5,4), %ymm11
	vpaddd	%ymm10, %ymm14, %ymm14
	vmovdqu	%ymm11, (%r12,%rbp,4)
	addq	$8, %rbp
	addq	$16, %rax
	addq	$32, %r8
	cmpq	%r10, %rax
	jbe	.LBB0_8
# %bb.9:                                #   in Loop: Header=BB0_7 Depth=1
	cmpl	-72(%rsp), %ebp                 # 4-byte Folded Reload
	vmovaps	-24(%rsp), %xmm11               # 16-byte Reload
	jl	.LBB0_10
	jmp	.LBB0_19
	.p2align	4, 0x90
.LBB0_18:                               #   in Loop: Header=BB0_10 Depth=2
	imull	-72(%rsp), %r11d                # 4-byte Folded Reload
	addl	%ebx, %r11d
	movslq	%r11d, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-56(%rsp), %rsi                 # 8-byte Reload
	movl	%eax, (%rsi,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_19
.LBB0_10:                               #   Parent Loop BB0_7 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rax                 # 8-byte Reload
	movzbl	2(%rax,%r13), %eax
	vcvtsi2ss	%eax, %xmm1, %xmm5
	vdivss	%xmm0, %xmm5, %xmm5
	vaddss	%xmm5, %xmm12, %xmm5
	vmulss	%xmm5, %xmm11, %xmm5
	vcvttss2si	%xmm5, %r8d
	leal	(%r8,%rbp), %esi
	movl	%esi, %eax
	cmpl	%edx, %esi
	jge	.LBB0_11
# %bb.12:                               #   in Loop: Header=BB0_10 Depth=2
	xorl	%r11d, %r11d
	movl	$0, %ebx
	testl	%esi, %esi
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
	movl	%edx, %eax
	xorl	%r11d, %r11d
	movl	$0, %ebx
	testl	%esi, %esi
	js	.LBB0_14
.LBB0_13:                               #   in Loop: Header=BB0_10 Depth=2
	movl	%eax, %ebx
	addl	%r14d, %r8d
	movl	%r8d, %eax
	cmpl	%r9d, %r8d
	jl	.LBB0_16
.LBB0_15:                               #   in Loop: Header=BB0_10 Depth=2
	movl	%r9d, %eax
	testl	%r8d, %r8d
	js	.LBB0_18
.LBB0_17:                               #   in Loop: Header=BB0_10 Depth=2
	movl	%eax, %r11d
	jmp	.LBB0_18
.LBB0_336:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -24(%rsp)                 # 8-byte Spill
	vbroadcastss	%xmm5, %xmm0
	vmovaps	%xmm0, -40(%rsp)                # 16-byte Spill
	leaq	(,%r10,4), %rcx
	movq	%rcx, -48(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vpbroadcastd	.LCPI0_3(%rip), %ymm6   # ymm6 = [8,8,8,8,8,8,8,8]
	vmovdqa	.LCPI0_6(%rip), %ymm7           # ymm7 = [2,128,128,128,6,128,128,128,10,128,128,128,14,128,128,128,18,128,128,128,22,128,128,128,26,128,128,128,30,128,128,128]
	vbroadcastss	.LCPI0_1(%rip), %ymm8   # ymm8 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm9   # ymm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vmovdqa	.LCPI0_5(%rip), %ymm10          # ymm10 = [1,128,128,128,5,128,128,128,9,128,128,128,13,128,128,128,17,128,128,128,21,128,128,128,25,128,128,128,29,128,128,128]
	vpxor	%xmm11, %xmm11, %xmm11
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_337
	.p2align	4, 0x90
.LBB0_349:                              #   in Loop: Header=BB0_337 Depth=1
	incq	%r14
	movq	-48(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-24(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_337:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_338 Depth 2
                                        #     Child Loop BB0_340 Depth 2
	vmovd	%r14d, %xmm5
	vpbroadcastd	%xmm5, %ymm12
	movq	%rbx, %r13
	xorl	%r8d, %r8d
	vpmovsxbd	.LCPI0_14(%rip), %ymm13 # ymm13 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_338:                              #   Parent Loop BB0_337 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%r8, %rbp
	vmovdqu	(%r15,%r8,4), %ymm14
	vpshufb	%ymm10, %ymm14, %ymm15
	vcvtdq2ps	%ymm15, %ymm15
	vdivps	%ymm8, %ymm15, %ymm15
	vpshufb	%ymm7, %ymm14, %ymm14
	vcvtdq2ps	%ymm14, %ymm14
	vdivps	%ymm8, %ymm14, %ymm14
	movq	%r13, %r11
	vaddps	%ymm9, %ymm14, %ymm14
	vaddps	%ymm9, %ymm15, %ymm15
	vmulps	%ymm1, %ymm14, %ymm14
	vmulps	%ymm1, %ymm15, %ymm15
	vcvttps2dq	%ymm15, %ymm15
	vpaddd	%ymm12, %ymm15, %ymm15
	vcvttps2dq	%ymm14, %ymm14
	vpaddd	%ymm13, %ymm14, %ymm14
	vpmaxsd	%ymm11, %ymm14, %ymm14
	vpmaxsd	%ymm11, %ymm15, %ymm15
	vpminsd	%ymm2, %ymm14, %ymm14
	vpminsd	%ymm3, %ymm15, %ymm15
	vpmulld	%ymm4, %ymm15, %ymm15
	vpcmpeqd	%ymm0, %ymm0, %ymm0
	vpaddd	%ymm14, %ymm15, %ymm14
	vpxor	%xmm15, %xmm15, %xmm15
	vpgatherdd	%ymm0, (%rdi,%ymm14,4), %ymm15
	vpaddd	%ymm6, %ymm13, %ymm13
	vmovdqu	%ymm15, (%r12,%r8,4)
	addq	$8, %r8
	addq	$16, %rbp
	addq	$32, %r13
	cmpq	%r10, %rbp
	jbe	.LBB0_338
# %bb.339:                              #   in Loop: Header=BB0_337 Depth=1
	cmpl	-72(%rsp), %r8d                 # 4-byte Folded Reload
	vmovaps	-40(%rsp), %xmm13               # 16-byte Reload
	vpmovsxbd	.LCPI0_12(%rip), %xmm14 # xmm14 = [8,16,0,0]
	vpmovzxbd	.LCPI0_11(%rip), %xmm15 # xmm15 = [255,255,0,0]
	jl	.LBB0_340
	jmp	.LBB0_349
	.p2align	4, 0x90
.LBB0_348:                              #   in Loop: Header=BB0_340 Depth=2
	imull	-72(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%edx, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	incq	%r8
	addq	$4, %r11
	cmpq	%r10, %r8
	jae	.LBB0_349
.LBB0_340:                              #   Parent Loop BB0_337 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	vpbroadcastd	(%rcx,%r11), %xmm0
	vpsrlvd	%xmm14, %xmm0, %xmm0
	vpand	%xmm0, %xmm15, %xmm0
	vcvtdq2ps	%xmm0, %xmm0
	vbroadcastss	.LCPI0_1(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vdivps	%xmm12, %xmm0, %xmm0
	vbroadcastss	.LCPI0_2(%rip), %xmm12  # xmm12 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vaddps	%xmm0, %xmm12, %xmm0
	vmulps	%xmm0, %xmm13, %xmm0
	vcvttps2dq	%xmm0, %xmm0
	vpinsrd	$1, %r8d, %xmm5, %xmm12
	vpaddd	%xmm0, %xmm12, %xmm12
	vpextrd	$1, %xmm12, %esi
	cmpl	%eax, %esi
	jl	.LBB0_342
# %bb.341:                              #   in Loop: Header=BB0_340 Depth=2
	movl	%eax, %esi
.LBB0_342:                              #   in Loop: Header=BB0_340 Depth=2
	vpmovsxdq	%xmm12, %xmm0
	vmovmskpd	%xmm0, %r13d
	xorl	%ebp, %ebp
	movl	$0, %edx
	testb	$2, %r13b
	je	.LBB0_343
# %bb.344:                              #   in Loop: Header=BB0_340 Depth=2
	vmovd	%xmm12, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_345
.LBB0_346:                              #   in Loop: Header=BB0_340 Depth=2
	testb	$1, %r13b
	jne	.LBB0_348
	jmp	.LBB0_347
	.p2align	4, 0x90
.LBB0_343:                              #   in Loop: Header=BB0_340 Depth=2
	movl	%esi, %edx
	vmovd	%xmm12, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_346
.LBB0_345:                              #   in Loop: Header=BB0_340 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r13b
	jne	.LBB0_348
.LBB0_347:                              #   in Loop: Header=BB0_340 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_348
.LBB0_88:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%esi, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%eax, %r10d
	movl	%r8d, %eax
	movq	%rax, -24(%rsp)                 # 8-byte Spill
	vbroadcastss	%xmm5, %xmm0
	vmovaps	%xmm0, -40(%rsp)                # 16-byte Spill
	leaq	(,%r10,4), %rax
	movq	%rax, -48(%rsp)                 # 8-byte Spill
	movl	$32, %eax
	xorl	%r14d, %r14d
	vpbroadcastd	.LCPI0_3(%rip), %ymm6   # ymm6 = [8,8,8,8,8,8,8,8]
	vmovdqa	.LCPI0_5(%rip), %ymm7           # ymm7 = [1,128,128,128,5,128,128,128,9,128,128,128,13,128,128,128,17,128,128,128,21,128,128,128,25,128,128,128,29,128,128,128]
	vbroadcastss	.LCPI0_1(%rip), %ymm8   # ymm8 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %ymm9   # ymm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vmovdqa	.LCPI0_6(%rip), %ymm10          # ymm10 = [2,128,128,128,6,128,128,128,10,128,128,128,14,128,128,128,18,128,128,128,22,128,128,128,26,128,128,128,30,128,128,128]
	vpxor	%xmm11, %xmm11, %xmm11
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_89
	.p2align	4, 0x90
.LBB0_101:                              #   in Loop: Header=BB0_89 Depth=1
	incq	%r14
	movq	-48(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rax
	cmpq	-24(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_89:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_90 Depth 2
                                        #     Child Loop BB0_92 Depth 2
	vmovd	%r14d, %xmm5
	vpbroadcastd	%xmm5, %ymm12
	movq	%rax, %r13
	xorl	%r8d, %r8d
	vpmovsxbd	.LCPI0_14(%rip), %ymm13 # ymm13 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_90:                               #   Parent Loop BB0_89 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%r8, %rbp
	vmovdqu	(%r15,%r8,4), %ymm14
	vpshufb	%ymm10, %ymm14, %ymm15
	vcvtdq2ps	%ymm15, %ymm15
	vdivps	%ymm8, %ymm15, %ymm15
	vpshufb	%ymm7, %ymm14, %ymm14
	vcvtdq2ps	%ymm14, %ymm14
	vdivps	%ymm8, %ymm14, %ymm14
	movq	%r13, %r11
	vaddps	%ymm9, %ymm14, %ymm14
	vaddps	%ymm9, %ymm15, %ymm15
	vmulps	%ymm1, %ymm14, %ymm14
	vmulps	%ymm1, %ymm15, %ymm15
	vcvttps2dq	%ymm15, %ymm15
	vpaddd	%ymm12, %ymm15, %ymm15
	vcvttps2dq	%ymm14, %ymm14
	vpaddd	%ymm13, %ymm14, %ymm14
	vpmaxsd	%ymm11, %ymm14, %ymm14
	vpmaxsd	%ymm11, %ymm15, %ymm15
	vpminsd	%ymm2, %ymm14, %ymm14
	vpminsd	%ymm3, %ymm15, %ymm15
	vpmulld	%ymm4, %ymm15, %ymm15
	vxorps	%xmm0, %xmm0, %xmm0
	vpaddd	%ymm14, %ymm15, %ymm14
	vpcmpeqd	%ymm15, %ymm15, %ymm15
	vpgatherdd	%ymm15, (%rdi,%ymm14,4), %ymm0
	vpaddd	%ymm6, %ymm13, %ymm13
	vmovdqu	%ymm0, (%r12,%r8,4)
	addq	$8, %r8
	addq	$16, %rbp
	addq	$32, %r13
	cmpq	%r10, %rbp
	jbe	.LBB0_90
# %bb.91:                               #   in Loop: Header=BB0_89 Depth=1
	cmpl	-72(%rsp), %r8d                 # 4-byte Folded Reload
	vmovaps	-40(%rsp), %xmm13               # 16-byte Reload
	vpmovsxbd	.LCPI0_13(%rip), %xmm14 # xmm14 = [16,8,0,0]
	vpmovzxbd	.LCPI0_11(%rip), %xmm15 # xmm15 = [255,255,0,0]
	jl	.LBB0_92
	jmp	.LBB0_101
	.p2align	4, 0x90
.LBB0_100:                              #   in Loop: Header=BB0_92 Depth=2
	imull	-72(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%edx, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	incq	%r8
	addq	$4, %r11
	cmpq	%r10, %r8
	jae	.LBB0_101
.LBB0_92:                               #   Parent Loop BB0_89 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	vpbroadcastd	(%rcx,%r11), %xmm0
	vpsrlvd	%xmm14, %xmm0, %xmm0
	vpand	%xmm0, %xmm15, %xmm0
	vcvtdq2ps	%xmm0, %xmm0
	vbroadcastss	.LCPI0_1(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vdivps	%xmm12, %xmm0, %xmm0
	vbroadcastss	.LCPI0_2(%rip), %xmm12  # xmm12 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vaddps	%xmm0, %xmm12, %xmm0
	vmulps	%xmm0, %xmm13, %xmm0
	vcvttps2dq	%xmm0, %xmm0
	vpinsrd	$1, %r8d, %xmm5, %xmm12
	vpaddd	%xmm0, %xmm12, %xmm12
	vpextrd	$1, %xmm12, %ebx
	cmpl	%esi, %ebx
	jl	.LBB0_94
# %bb.93:                               #   in Loop: Header=BB0_92 Depth=2
	movl	%esi, %ebx
.LBB0_94:                               #   in Loop: Header=BB0_92 Depth=2
	vpmovsxdq	%xmm12, %xmm0
	vmovmskpd	%xmm0, %r13d
	xorl	%ebp, %ebp
	movl	$0, %edx
	testb	$2, %r13b
	je	.LBB0_95
# %bb.96:                               #   in Loop: Header=BB0_92 Depth=2
	vmovd	%xmm12, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_97
.LBB0_98:                               #   in Loop: Header=BB0_92 Depth=2
	testb	$1, %r13b
	jne	.LBB0_100
	jmp	.LBB0_99
	.p2align	4, 0x90
.LBB0_95:                               #   in Loop: Header=BB0_92 Depth=2
	movl	%ebx, %edx
	vmovd	%xmm12, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_98
.LBB0_97:                               #   in Loop: Header=BB0_92 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r13b
	jne	.LBB0_100
.LBB0_99:                               #   in Loop: Header=BB0_92 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_100
.LBB0_418:
	vbroadcastss	%xmm5, %ymm1
	vmovd	%eax, %xmm0
	vpbroadcastd	%xmm0, %ymm2
	vmovd	%r9d, %xmm0
	vpbroadcastd	%xmm0, %ymm3
	vmovd	%ecx, %xmm0
	vpbroadcastd	%xmm0, %ymm4
	movl	%ecx, %r10d
	movl	%r8d, %ecx
	movq	%rcx, -40(%rsp)                 # 8-byte Spill
	leaq	(,%r10,4), %rcx
	movq	%rcx, -48(%rsp)                 # 8-byte Spill
	movl	$32, %ebx
	xorl	%r14d, %r14d
	vpbroadcastd	.LCPI0_3(%rip), %ymm6   # ymm6 = [8,8,8,8,8,8,8,8]
	vbroadcastss	.LCPI0_1(%rip), %ymm7   # ymm7 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vmovdqa	.LCPI0_5(%rip), %ymm8           # ymm8 = [1,128,128,128,5,128,128,128,9,128,128,128,13,128,128,128,17,128,128,128,21,128,128,128,25,128,128,128,29,128,128,128]
	vbroadcastss	.LCPI0_2(%rip), %ymm9   # ymm9 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm10, %xmm10, %xmm10
	vmovss	.LCPI0_1(%rip), %xmm11          # xmm11 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm12          # xmm12 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	movq	-64(%rsp), %r15                 # 8-byte Reload
	movq	-56(%rsp), %r12                 # 8-byte Reload
	jmp	.LBB0_419
	.p2align	4, 0x90
.LBB0_431:                              #   in Loop: Header=BB0_419 Depth=1
	incq	%r14
	movq	-48(%rsp), %rcx                 # 8-byte Reload
	addq	%rcx, %r12
	addq	%rcx, %r15
	addq	%rcx, %rbx
	cmpq	-40(%rsp), %r14                 # 8-byte Folded Reload
	je	.LBB0_1322
.LBB0_419:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_420 Depth 2
                                        #     Child Loop BB0_422 Depth 2
	vmovd	%r14d, %xmm0
	vpbroadcastd	%xmm0, %ymm13
	movq	%rbx, %rdx
	xorl	%ebp, %ebp
	vpmovsxbd	.LCPI0_14(%rip), %ymm14 # ymm14 = [0,1,2,3,4,5,6,7]
	.p2align	4, 0x90
.LBB0_420:                              #   Parent Loop BB0_419 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	%rbp, %rcx
	vmovdqu	(%r15,%rbp,4), %ymm0
	vpshufb	%ymm8, %ymm0, %ymm0
	vcvtdq2ps	%ymm0, %ymm0
	vdivps	%ymm7, %ymm0, %ymm0
	movq	%rdx, %r13
	vaddps	%ymm0, %ymm9, %ymm0
	vmulps	%ymm0, %ymm1, %ymm0
	vcvttps2dq	%ymm0, %ymm0
	vpaddd	%ymm0, %ymm14, %ymm15
	vpmaxsd	%ymm10, %ymm15, %ymm15
	vpaddd	%ymm0, %ymm13, %ymm0
	vpmaxsd	%ymm10, %ymm0, %ymm0
	vpminsd	%ymm2, %ymm15, %ymm15
	vpminsd	%ymm3, %ymm0, %ymm0
	vpmulld	%ymm4, %ymm0, %ymm0
	vxorps	%xmm5, %xmm5, %xmm5
	vpaddd	%ymm0, %ymm15, %ymm0
	vpcmpeqd	%ymm15, %ymm15, %ymm15
	vpgatherdd	%ymm15, (%rdi,%ymm0,4), %ymm5
	vpaddd	%ymm6, %ymm14, %ymm14
	vmovdqu	%ymm5, (%r12,%rbp,4)
	addq	$8, %rbp
	addq	$16, %rcx
	addq	$32, %rdx
	cmpq	%r10, %rcx
	jbe	.LBB0_420
# %bb.421:                              #   in Loop: Header=BB0_419 Depth=1
	cmpl	-72(%rsp), %ebp                 # 4-byte Folded Reload
	vmovaps	-24(%rsp), %xmm5                # 16-byte Reload
	jl	.LBB0_422
	jmp	.LBB0_431
	.p2align	4, 0x90
.LBB0_430:                              #   in Loop: Header=BB0_422 Depth=2
	imull	-72(%rsp), %r11d                # 4-byte Folded Reload
	addl	%edx, %r11d
	movslq	%r11d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r13)
	incq	%rbp
	addq	$4, %r13
	cmpq	%r10, %rbp
	jae	.LBB0_431
.LBB0_422:                              #   Parent Loop BB0_419 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	1(%rcx,%r13), %ecx
	vcvtsi2ss	%ecx, %xmm1, %xmm0
	vdivss	%xmm11, %xmm0, %xmm0
	vaddss	%xmm0, %xmm12, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r8d
	leal	(%r8,%rbp), %esi
	movl	%esi, %ecx
	cmpl	%eax, %esi
	jge	.LBB0_423
# %bb.424:                              #   in Loop: Header=BB0_422 Depth=2
	xorl	%r11d, %r11d
	movl	$0, %edx
	testl	%esi, %esi
	jns	.LBB0_425
.LBB0_426:                              #   in Loop: Header=BB0_422 Depth=2
	addl	%r14d, %r8d
	movl	%r8d, %ecx
	cmpl	%r9d, %r8d
	jge	.LBB0_427
.LBB0_428:                              #   in Loop: Header=BB0_422 Depth=2
	testl	%r8d, %r8d
	js	.LBB0_430
	jmp	.LBB0_429
	.p2align	4, 0x90
.LBB0_423:                              #   in Loop: Header=BB0_422 Depth=2
	movl	%eax, %ecx
	xorl	%r11d, %r11d
	movl	$0, %edx
	testl	%esi, %esi
	js	.LBB0_426
.LBB0_425:                              #   in Loop: Header=BB0_422 Depth=2
	movl	%ecx, %edx
	addl	%r14d, %r8d
	movl	%r8d, %ecx
	cmpl	%r9d, %r8d
	jl	.LBB0_428
.LBB0_427:                              #   in Loop: Header=BB0_422 Depth=2
	movl	%r9d, %ecx
	testl	%r8d, %r8d
	js	.LBB0_430
.LBB0_429:                              #   in Loop: Header=BB0_422 Depth=2
	movl	%ecx, %r11d
	jmp	.LBB0_430
.LBB0_908:                              #   in Loop: Header=BB0_846 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_909:                              #   in Loop: Header=BB0_846 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_846:                              # =>This Inner Loop Header: Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-24(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	movl	%r14d, %ecx
	cmpl	%eax, %r14d
	jge	.LBB0_847
# %bb.848:                              #   in Loop: Header=BB0_846 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	jns	.LBB0_849
.LBB0_850:                              #   in Loop: Header=BB0_846 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_851
.LBB0_852:                              #   in Loop: Header=BB0_846 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_854
.LBB0_853:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%ecx, %ebp
.LBB0_854:                              #   in Loop: Header=BB0_846 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_909
# %bb.855:                              #   in Loop: Header=BB0_846 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-20(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	1(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_856
# %bb.857:                              #   in Loop: Header=BB0_846 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jge	.LBB0_858
.LBB0_859:                              #   in Loop: Header=BB0_846 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_860
.LBB0_861:                              #   in Loop: Header=BB0_846 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_863
.LBB0_862:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%ecx, %ebp
.LBB0_863:                              #   in Loop: Header=BB0_846 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_909
# %bb.864:                              #   in Loop: Header=BB0_846 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-16(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	2(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_865
# %bb.866:                              #   in Loop: Header=BB0_846 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jge	.LBB0_867
.LBB0_868:                              #   in Loop: Header=BB0_846 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_869
.LBB0_870:                              #   in Loop: Header=BB0_846 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_872
.LBB0_871:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%ecx, %ebp
.LBB0_872:                              #   in Loop: Header=BB0_846 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_909
# %bb.873:                              #   in Loop: Header=BB0_846 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-12(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	3(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_874
# %bb.875:                              #   in Loop: Header=BB0_846 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-3, %r14d
	jge	.LBB0_876
.LBB0_877:                              #   in Loop: Header=BB0_846 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_878
.LBB0_879:                              #   in Loop: Header=BB0_846 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_881
.LBB0_880:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%ecx, %ebp
.LBB0_881:                              #   in Loop: Header=BB0_846 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_909
# %bb.882:                              #   in Loop: Header=BB0_846 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-8(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	4(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_883
# %bb.884:                              #   in Loop: Header=BB0_846 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-4, %r14d
	jge	.LBB0_885
.LBB0_886:                              #   in Loop: Header=BB0_846 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_887
.LBB0_888:                              #   in Loop: Header=BB0_846 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_890
.LBB0_889:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%ecx, %ebp
.LBB0_890:                              #   in Loop: Header=BB0_846 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_909
# %bb.891:                              #   in Loop: Header=BB0_846 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-4(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm1, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	5(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_892
# %bb.893:                              #   in Loop: Header=BB0_846 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-5, %r14d
	jge	.LBB0_894
.LBB0_895:                              #   in Loop: Header=BB0_846 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_896
.LBB0_897:                              #   in Loop: Header=BB0_846 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_899
.LBB0_898:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%ecx, %ebp
.LBB0_899:                              #   in Loop: Header=BB0_846 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_909
# %bb.900:                              #   in Loop: Header=BB0_846 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm1, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	6(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_901
# %bb.902:                              #   in Loop: Header=BB0_846 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-6, %r14d
	jge	.LBB0_903
.LBB0_904:                              #   in Loop: Header=BB0_846 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_905
.LBB0_906:                              #   in Loop: Header=BB0_846 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_908
	jmp	.LBB0_907
.LBB0_847:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%eax, %ecx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	js	.LBB0_850
.LBB0_849:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%ecx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_852
.LBB0_851:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_853
	jmp	.LBB0_854
.LBB0_856:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jl	.LBB0_859
.LBB0_858:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_861
.LBB0_860:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_862
	jmp	.LBB0_863
.LBB0_865:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jl	.LBB0_868
.LBB0_867:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_870
.LBB0_869:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_871
	jmp	.LBB0_872
.LBB0_874:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-3, %r14d
	jl	.LBB0_877
.LBB0_876:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_879
.LBB0_878:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_880
	jmp	.LBB0_881
.LBB0_883:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-4, %r14d
	jl	.LBB0_886
.LBB0_885:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_888
.LBB0_887:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_889
	jmp	.LBB0_890
.LBB0_892:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-5, %r14d
	jl	.LBB0_895
.LBB0_894:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_897
.LBB0_896:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_898
	jmp	.LBB0_899
.LBB0_901:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-6, %r14d
	jl	.LBB0_904
.LBB0_903:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_906
.LBB0_905:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	js	.LBB0_908
.LBB0_907:                              #   in Loop: Header=BB0_846 Depth=1
	movl	%ecx, %ebp
	jmp	.LBB0_908
.LBB0_990:                              #   in Loop: Header=BB0_928 Depth=1
	imull	-72(%rsp), %r13d                # 4-byte Folded Reload
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_991:                              #   in Loop: Header=BB0_928 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_928:                              # =>This Inner Loop Header: Depth=1
	vmovd	%ebx, %xmm3
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-24(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpaddd	%xmm4, %xmm3, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_930
# %bb.929:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%eax, %esi
.LBB0_930:                              #   in Loop: Header=BB0_928 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_931
# %bb.932:                              #   in Loop: Header=BB0_928 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_933
.LBB0_934:                              #   in Loop: Header=BB0_928 Depth=1
	testb	$1, %r12b
	jne	.LBB0_936
.LBB0_935:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%ecx, %r13d
.LBB0_936:                              #   in Loop: Header=BB0_928 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_991
# %bb.937:                              #   in Loop: Header=BB0_928 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-20(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %ebp, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_939
# %bb.938:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%eax, %esi
.LBB0_939:                              #   in Loop: Header=BB0_928 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_940
# %bb.941:                              #   in Loop: Header=BB0_928 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_942
.LBB0_943:                              #   in Loop: Header=BB0_928 Depth=1
	testb	$1, %r12b
	jne	.LBB0_945
.LBB0_944:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%ecx, %r13d
.LBB0_945:                              #   in Loop: Header=BB0_928 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_991
# %bb.946:                              #   in Loop: Header=BB0_928 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-16(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %r14d, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_948
# %bb.947:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%eax, %esi
.LBB0_948:                              #   in Loop: Header=BB0_928 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_949
# %bb.950:                              #   in Loop: Header=BB0_928 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_951
.LBB0_952:                              #   in Loop: Header=BB0_928 Depth=1
	testb	$1, %r12b
	jne	.LBB0_954
.LBB0_953:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%ecx, %r13d
.LBB0_954:                              #   in Loop: Header=BB0_928 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_991
# %bb.955:                              #   in Loop: Header=BB0_928 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-12(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %r15d, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_957
# %bb.956:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%eax, %esi
.LBB0_957:                              #   in Loop: Header=BB0_928 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_958
# %bb.959:                              #   in Loop: Header=BB0_928 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_960
.LBB0_961:                              #   in Loop: Header=BB0_928 Depth=1
	testb	$1, %r12b
	jne	.LBB0_963
.LBB0_962:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%ecx, %r13d
.LBB0_963:                              #   in Loop: Header=BB0_928 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_991
# %bb.964:                              #   in Loop: Header=BB0_928 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-8(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$4, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_966
# %bb.965:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%eax, %esi
.LBB0_966:                              #   in Loop: Header=BB0_928 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_967
# %bb.968:                              #   in Loop: Header=BB0_928 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_969
.LBB0_970:                              #   in Loop: Header=BB0_928 Depth=1
	testb	$1, %r12b
	jne	.LBB0_972
.LBB0_971:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%ecx, %r13d
.LBB0_972:                              #   in Loop: Header=BB0_928 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_991
# %bb.973:                              #   in Loop: Header=BB0_928 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-4(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$5, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_975
# %bb.974:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%eax, %esi
.LBB0_975:                              #   in Loop: Header=BB0_928 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_976
# %bb.977:                              #   in Loop: Header=BB0_928 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_978
.LBB0_979:                              #   in Loop: Header=BB0_928 Depth=1
	testb	$1, %r12b
	jne	.LBB0_981
.LBB0_980:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%ecx, %r13d
.LBB0_981:                              #   in Loop: Header=BB0_928 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_991
# %bb.982:                              #   in Loop: Header=BB0_928 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$6, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm3
	vpaddd	%xmm4, %xmm3, %xmm3
	vpextrd	$1, %xmm3, %esi
	cmpl	%eax, %esi
	jl	.LBB0_984
# %bb.983:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%eax, %esi
.LBB0_984:                              #   in Loop: Header=BB0_928 Depth=1
	vpmovsxdq	%xmm3, %xmm4
	vmovmskpd	%xmm4, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_985
# %bb.986:                              #   in Loop: Header=BB0_928 Depth=1
	vmovd	%xmm3, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_987
.LBB0_988:                              #   in Loop: Header=BB0_928 Depth=1
	testb	$1, %r12b
	jne	.LBB0_990
	jmp	.LBB0_989
.LBB0_931:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_934
.LBB0_933:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_935
	jmp	.LBB0_936
.LBB0_940:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_943
.LBB0_942:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_944
	jmp	.LBB0_945
.LBB0_949:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_952
.LBB0_951:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_953
	jmp	.LBB0_954
.LBB0_958:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_961
.LBB0_960:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_962
	jmp	.LBB0_963
.LBB0_967:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_970
.LBB0_969:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_971
	jmp	.LBB0_972
.LBB0_976:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_979
.LBB0_978:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_980
	jmp	.LBB0_981
.LBB0_985:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%esi, %edx
	vmovd	%xmm3, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_988
.LBB0_987:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_990
.LBB0_989:                              #   in Loop: Header=BB0_928 Depth=1
	movl	%ecx, %r13d
	jmp	.LBB0_990
.LBB0_1238:                             #   in Loop: Header=BB0_1176 Depth=1
	imull	-72(%rsp), %r13d                # 4-byte Folded Reload
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_1239:                             #   in Loop: Header=BB0_1176 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_1176:                             # =>This Inner Loop Header: Depth=1
	vmovd	%ebx, %xmm3
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-24(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpaddd	%xmm4, %xmm3, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1178
# %bb.1177:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%eax, %esi
.LBB0_1178:                             #   in Loop: Header=BB0_1176 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1179
# %bb.1180:                             #   in Loop: Header=BB0_1176 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1181
.LBB0_1182:                             #   in Loop: Header=BB0_1176 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1184
.LBB0_1183:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%ecx, %r13d
.LBB0_1184:                             #   in Loop: Header=BB0_1176 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_1239
# %bb.1185:                             #   in Loop: Header=BB0_1176 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-20(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %ebp, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1187
# %bb.1186:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%eax, %esi
.LBB0_1187:                             #   in Loop: Header=BB0_1176 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1188
# %bb.1189:                             #   in Loop: Header=BB0_1176 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1190
.LBB0_1191:                             #   in Loop: Header=BB0_1176 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1193
.LBB0_1192:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%ecx, %r13d
.LBB0_1193:                             #   in Loop: Header=BB0_1176 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_1239
# %bb.1194:                             #   in Loop: Header=BB0_1176 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-16(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %r14d, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1196
# %bb.1195:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%eax, %esi
.LBB0_1196:                             #   in Loop: Header=BB0_1176 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1197
# %bb.1198:                             #   in Loop: Header=BB0_1176 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1199
.LBB0_1200:                             #   in Loop: Header=BB0_1176 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1202
.LBB0_1201:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%ecx, %r13d
.LBB0_1202:                             #   in Loop: Header=BB0_1176 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_1239
# %bb.1203:                             #   in Loop: Header=BB0_1176 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-12(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %r15d, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1205
# %bb.1204:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%eax, %esi
.LBB0_1205:                             #   in Loop: Header=BB0_1176 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1206
# %bb.1207:                             #   in Loop: Header=BB0_1176 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1208
.LBB0_1209:                             #   in Loop: Header=BB0_1176 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1211
.LBB0_1210:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%ecx, %r13d
.LBB0_1211:                             #   in Loop: Header=BB0_1176 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_1239
# %bb.1212:                             #   in Loop: Header=BB0_1176 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-8(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$4, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1214
# %bb.1213:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%eax, %esi
.LBB0_1214:                             #   in Loop: Header=BB0_1176 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1215
# %bb.1216:                             #   in Loop: Header=BB0_1176 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1217
.LBB0_1218:                             #   in Loop: Header=BB0_1176 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1220
.LBB0_1219:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%ecx, %r13d
.LBB0_1220:                             #   in Loop: Header=BB0_1176 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_1239
# %bb.1221:                             #   in Loop: Header=BB0_1176 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-4(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$5, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1223
# %bb.1222:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%eax, %esi
.LBB0_1223:                             #   in Loop: Header=BB0_1176 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1224
# %bb.1225:                             #   in Loop: Header=BB0_1176 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1226
.LBB0_1227:                             #   in Loop: Header=BB0_1176 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1229
.LBB0_1228:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%ecx, %r13d
.LBB0_1229:                             #   in Loop: Header=BB0_1176 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_1239
# %bb.1230:                             #   in Loop: Header=BB0_1176 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movzbl	%cl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$6, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm3
	vpaddd	%xmm4, %xmm3, %xmm3
	vpextrd	$1, %xmm3, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1232
# %bb.1231:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%eax, %esi
.LBB0_1232:                             #   in Loop: Header=BB0_1176 Depth=1
	vpmovsxdq	%xmm3, %xmm4
	vmovmskpd	%xmm4, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1233
# %bb.1234:                             #   in Loop: Header=BB0_1176 Depth=1
	vmovd	%xmm3, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1235
.LBB0_1236:                             #   in Loop: Header=BB0_1176 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1238
	jmp	.LBB0_1237
.LBB0_1179:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1182
.LBB0_1181:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1183
	jmp	.LBB0_1184
.LBB0_1188:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1191
.LBB0_1190:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1192
	jmp	.LBB0_1193
.LBB0_1197:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1200
.LBB0_1199:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1201
	jmp	.LBB0_1202
.LBB0_1206:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1209
.LBB0_1208:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1210
	jmp	.LBB0_1211
.LBB0_1215:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1218
.LBB0_1217:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1219
	jmp	.LBB0_1220
.LBB0_1224:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1227
.LBB0_1226:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1228
	jmp	.LBB0_1229
.LBB0_1233:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%esi, %edx
	vmovd	%xmm3, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1236
.LBB0_1235:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_1238
.LBB0_1237:                             #   in Loop: Header=BB0_1176 Depth=1
	movl	%ecx, %r13d
	jmp	.LBB0_1238
.LBB0_744:                              #   in Loop: Header=BB0_682 Depth=1
	imull	-72(%rsp), %r13d                # 4-byte Folded Reload
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_745:                              #   in Loop: Header=BB0_682 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_682:                              # =>This Inner Loop Header: Depth=1
	vmovd	%ebx, %xmm4
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-24(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$16, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpaddd	%xmm5, %xmm4, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_684
# %bb.683:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%eax, %esi
.LBB0_684:                              #   in Loop: Header=BB0_682 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_685
# %bb.686:                              #   in Loop: Header=BB0_682 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_687
.LBB0_688:                              #   in Loop: Header=BB0_682 Depth=1
	testb	$1, %r12b
	jne	.LBB0_690
.LBB0_689:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%ecx, %r13d
.LBB0_690:                              #   in Loop: Header=BB0_682 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_745
# %bb.691:                              #   in Loop: Header=BB0_682 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-20(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$16, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %ebp, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_693
# %bb.692:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%eax, %esi
.LBB0_693:                              #   in Loop: Header=BB0_682 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_694
# %bb.695:                              #   in Loop: Header=BB0_682 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_696
.LBB0_697:                              #   in Loop: Header=BB0_682 Depth=1
	testb	$1, %r12b
	jne	.LBB0_699
.LBB0_698:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%ecx, %r13d
.LBB0_699:                              #   in Loop: Header=BB0_682 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_745
# %bb.700:                              #   in Loop: Header=BB0_682 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-16(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$16, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r14d, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_702
# %bb.701:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%eax, %esi
.LBB0_702:                              #   in Loop: Header=BB0_682 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_703
# %bb.704:                              #   in Loop: Header=BB0_682 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_705
.LBB0_706:                              #   in Loop: Header=BB0_682 Depth=1
	testb	$1, %r12b
	jne	.LBB0_708
.LBB0_707:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%ecx, %r13d
.LBB0_708:                              #   in Loop: Header=BB0_682 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_745
# %bb.709:                              #   in Loop: Header=BB0_682 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-12(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$16, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r15d, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_711
# %bb.710:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%eax, %esi
.LBB0_711:                              #   in Loop: Header=BB0_682 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_712
# %bb.713:                              #   in Loop: Header=BB0_682 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_714
.LBB0_715:                              #   in Loop: Header=BB0_682 Depth=1
	testb	$1, %r12b
	jne	.LBB0_717
.LBB0_716:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%ecx, %r13d
.LBB0_717:                              #   in Loop: Header=BB0_682 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_745
# %bb.718:                              #   in Loop: Header=BB0_682 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-8(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$16, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	movl	$4, %ecx
	vpinsrd	$1, %ecx, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_720
# %bb.719:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%eax, %esi
.LBB0_720:                              #   in Loop: Header=BB0_682 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_721
# %bb.722:                              #   in Loop: Header=BB0_682 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_723
.LBB0_724:                              #   in Loop: Header=BB0_682 Depth=1
	testb	$1, %r12b
	jne	.LBB0_726
.LBB0_725:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%ecx, %r13d
.LBB0_726:                              #   in Loop: Header=BB0_682 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_745
# %bb.727:                              #   in Loop: Header=BB0_682 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-4(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$16, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	movl	$5, %ecx
	vpinsrd	$1, %ecx, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_729
# %bb.728:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%eax, %esi
.LBB0_729:                              #   in Loop: Header=BB0_682 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_730
# %bb.731:                              #   in Loop: Header=BB0_682 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_732
.LBB0_733:                              #   in Loop: Header=BB0_682 Depth=1
	testb	$1, %r12b
	jne	.LBB0_735
.LBB0_734:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%ecx, %r13d
.LBB0_735:                              #   in Loop: Header=BB0_682 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_745
# %bb.736:                              #   in Loop: Header=BB0_682 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$16, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	movl	$6, %ecx
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vpaddd	%xmm5, %xmm4, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_738
# %bb.737:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%eax, %esi
.LBB0_738:                              #   in Loop: Header=BB0_682 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_739
# %bb.740:                              #   in Loop: Header=BB0_682 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_741
.LBB0_742:                              #   in Loop: Header=BB0_682 Depth=1
	testb	$1, %r12b
	jne	.LBB0_744
	jmp	.LBB0_743
.LBB0_685:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_688
.LBB0_687:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_689
	jmp	.LBB0_690
.LBB0_694:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_697
.LBB0_696:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_698
	jmp	.LBB0_699
.LBB0_703:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_706
.LBB0_705:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_707
	jmp	.LBB0_708
.LBB0_712:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_715
.LBB0_714:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_716
	jmp	.LBB0_717
.LBB0_721:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_724
.LBB0_723:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_725
	jmp	.LBB0_726
.LBB0_730:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_733
.LBB0_732:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_734
	jmp	.LBB0_735
.LBB0_739:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_742
.LBB0_741:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_744
.LBB0_743:                              #   in Loop: Header=BB0_682 Depth=1
	movl	%ecx, %r13d
	jmp	.LBB0_744
.LBB0_248:                              #   in Loop: Header=BB0_186 Depth=1
	imull	-72(%rsp), %r13d                # 4-byte Folded Reload
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_249:                              #   in Loop: Header=BB0_186 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_186:                              # =>This Inner Loop Header: Depth=1
	vmovd	%ebx, %xmm4
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-24(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpaddd	%xmm5, %xmm4, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_188
# %bb.187:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%eax, %esi
.LBB0_188:                              #   in Loop: Header=BB0_186 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_189
# %bb.190:                              #   in Loop: Header=BB0_186 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_191
.LBB0_192:                              #   in Loop: Header=BB0_186 Depth=1
	testb	$1, %r12b
	jne	.LBB0_194
.LBB0_193:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%ecx, %r13d
.LBB0_194:                              #   in Loop: Header=BB0_186 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_249
# %bb.195:                              #   in Loop: Header=BB0_186 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-20(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %ebp, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_197
# %bb.196:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%eax, %esi
.LBB0_197:                              #   in Loop: Header=BB0_186 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_198
# %bb.199:                              #   in Loop: Header=BB0_186 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_200
.LBB0_201:                              #   in Loop: Header=BB0_186 Depth=1
	testb	$1, %r12b
	jne	.LBB0_203
.LBB0_202:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%ecx, %r13d
.LBB0_203:                              #   in Loop: Header=BB0_186 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_249
# %bb.204:                              #   in Loop: Header=BB0_186 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-16(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r14d, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_206
# %bb.205:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%eax, %esi
.LBB0_206:                              #   in Loop: Header=BB0_186 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_207
# %bb.208:                              #   in Loop: Header=BB0_186 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_209
.LBB0_210:                              #   in Loop: Header=BB0_186 Depth=1
	testb	$1, %r12b
	jne	.LBB0_212
.LBB0_211:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%ecx, %r13d
.LBB0_212:                              #   in Loop: Header=BB0_186 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_249
# %bb.213:                              #   in Loop: Header=BB0_186 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-12(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r15d, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_215
# %bb.214:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%eax, %esi
.LBB0_215:                              #   in Loop: Header=BB0_186 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_216
# %bb.217:                              #   in Loop: Header=BB0_186 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_218
.LBB0_219:                              #   in Loop: Header=BB0_186 Depth=1
	testb	$1, %r12b
	jne	.LBB0_221
.LBB0_220:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%ecx, %r13d
.LBB0_221:                              #   in Loop: Header=BB0_186 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_249
# %bb.222:                              #   in Loop: Header=BB0_186 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-8(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	movl	$4, %ecx
	vpinsrd	$1, %ecx, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_224
# %bb.223:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%eax, %esi
.LBB0_224:                              #   in Loop: Header=BB0_186 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_225
# %bb.226:                              #   in Loop: Header=BB0_186 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_227
.LBB0_228:                              #   in Loop: Header=BB0_186 Depth=1
	testb	$1, %r12b
	jne	.LBB0_230
.LBB0_229:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%ecx, %r13d
.LBB0_230:                              #   in Loop: Header=BB0_186 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_249
# %bb.231:                              #   in Loop: Header=BB0_186 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-4(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	movl	$5, %ecx
	vpinsrd	$1, %ecx, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_233
# %bb.232:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%eax, %esi
.LBB0_233:                              #   in Loop: Header=BB0_186 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_234
# %bb.235:                              #   in Loop: Header=BB0_186 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_236
.LBB0_237:                              #   in Loop: Header=BB0_186 Depth=1
	testb	$1, %r12b
	jne	.LBB0_239
.LBB0_238:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%ecx, %r13d
.LBB0_239:                              #   in Loop: Header=BB0_186 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_249
# %bb.240:                              #   in Loop: Header=BB0_186 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	movl	$6, %ecx
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vpaddd	%xmm5, %xmm4, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_242
# %bb.241:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%eax, %esi
.LBB0_242:                              #   in Loop: Header=BB0_186 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_243
# %bb.244:                              #   in Loop: Header=BB0_186 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_245
.LBB0_246:                              #   in Loop: Header=BB0_186 Depth=1
	testb	$1, %r12b
	jne	.LBB0_248
	jmp	.LBB0_247
.LBB0_189:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_192
.LBB0_191:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_193
	jmp	.LBB0_194
.LBB0_198:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_201
.LBB0_200:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_202
	jmp	.LBB0_203
.LBB0_207:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_210
.LBB0_209:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_211
	jmp	.LBB0_212
.LBB0_216:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_219
.LBB0_218:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_220
	jmp	.LBB0_221
.LBB0_225:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_228
.LBB0_227:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_229
	jmp	.LBB0_230
.LBB0_234:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_237
.LBB0_236:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_238
	jmp	.LBB0_239
.LBB0_243:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_246
.LBB0_245:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_248
.LBB0_247:                              #   in Loop: Header=BB0_186 Depth=1
	movl	%ecx, %r13d
	jmp	.LBB0_248
.LBB0_826:                              #   in Loop: Header=BB0_764 Depth=1
	imull	-72(%rsp), %r13d                # 4-byte Folded Reload
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_827:                              #   in Loop: Header=BB0_764 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_764:                              # =>This Inner Loop Header: Depth=1
	vmovd	%ebx, %xmm4
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-24(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$8, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpaddd	%xmm5, %xmm4, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_766
# %bb.765:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%eax, %esi
.LBB0_766:                              #   in Loop: Header=BB0_764 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_767
# %bb.768:                              #   in Loop: Header=BB0_764 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_769
.LBB0_770:                              #   in Loop: Header=BB0_764 Depth=1
	testb	$1, %r12b
	jne	.LBB0_772
.LBB0_771:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%ecx, %r13d
.LBB0_772:                              #   in Loop: Header=BB0_764 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_827
# %bb.773:                              #   in Loop: Header=BB0_764 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-20(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$8, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %ebp, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_775
# %bb.774:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%eax, %esi
.LBB0_775:                              #   in Loop: Header=BB0_764 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_776
# %bb.777:                              #   in Loop: Header=BB0_764 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_778
.LBB0_779:                              #   in Loop: Header=BB0_764 Depth=1
	testb	$1, %r12b
	jne	.LBB0_781
.LBB0_780:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%ecx, %r13d
.LBB0_781:                              #   in Loop: Header=BB0_764 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_827
# %bb.782:                              #   in Loop: Header=BB0_764 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-16(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$8, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r14d, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_784
# %bb.783:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%eax, %esi
.LBB0_784:                              #   in Loop: Header=BB0_764 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_785
# %bb.786:                              #   in Loop: Header=BB0_764 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_787
.LBB0_788:                              #   in Loop: Header=BB0_764 Depth=1
	testb	$1, %r12b
	jne	.LBB0_790
.LBB0_789:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%ecx, %r13d
.LBB0_790:                              #   in Loop: Header=BB0_764 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_827
# %bb.791:                              #   in Loop: Header=BB0_764 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-12(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$8, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r15d, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_793
# %bb.792:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%eax, %esi
.LBB0_793:                              #   in Loop: Header=BB0_764 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_794
# %bb.795:                              #   in Loop: Header=BB0_764 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_796
.LBB0_797:                              #   in Loop: Header=BB0_764 Depth=1
	testb	$1, %r12b
	jne	.LBB0_799
.LBB0_798:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%ecx, %r13d
.LBB0_799:                              #   in Loop: Header=BB0_764 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_827
# %bb.800:                              #   in Loop: Header=BB0_764 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-8(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$8, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	movl	$4, %ecx
	vpinsrd	$1, %ecx, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_802
# %bb.801:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%eax, %esi
.LBB0_802:                              #   in Loop: Header=BB0_764 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_803
# %bb.804:                              #   in Loop: Header=BB0_764 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_805
.LBB0_806:                              #   in Loop: Header=BB0_764 Depth=1
	testb	$1, %r12b
	jne	.LBB0_808
.LBB0_807:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%ecx, %r13d
.LBB0_808:                              #   in Loop: Header=BB0_764 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_827
# %bb.809:                              #   in Loop: Header=BB0_764 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-4(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$8, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	movl	$5, %ecx
	vpinsrd	$1, %ecx, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_811
# %bb.810:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%eax, %esi
.LBB0_811:                              #   in Loop: Header=BB0_764 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_812
# %bb.813:                              #   in Loop: Header=BB0_764 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_814
.LBB0_815:                              #   in Loop: Header=BB0_764 Depth=1
	testb	$1, %r12b
	jne	.LBB0_817
.LBB0_816:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%ecx, %r13d
.LBB0_817:                              #   in Loop: Header=BB0_764 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_827
# %bb.818:                              #   in Loop: Header=BB0_764 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	vmovd	%ecx, %xmm5
	shrl	$8, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	movl	$6, %ecx
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vpaddd	%xmm5, %xmm4, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_820
# %bb.819:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%eax, %esi
.LBB0_820:                              #   in Loop: Header=BB0_764 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_821
# %bb.822:                              #   in Loop: Header=BB0_764 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_823
.LBB0_824:                              #   in Loop: Header=BB0_764 Depth=1
	testb	$1, %r12b
	jne	.LBB0_826
	jmp	.LBB0_825
.LBB0_767:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_770
.LBB0_769:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_771
	jmp	.LBB0_772
.LBB0_776:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_779
.LBB0_778:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_780
	jmp	.LBB0_781
.LBB0_785:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_788
.LBB0_787:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_789
	jmp	.LBB0_790
.LBB0_794:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_797
.LBB0_796:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_798
	jmp	.LBB0_799
.LBB0_803:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_806
.LBB0_805:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_807
	jmp	.LBB0_808
.LBB0_812:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_815
.LBB0_814:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_816
	jmp	.LBB0_817
.LBB0_821:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_824
.LBB0_823:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_826
.LBB0_825:                              #   in Loop: Header=BB0_764 Depth=1
	movl	%ecx, %r13d
	jmp	.LBB0_826
.LBB0_578:                              #   in Loop: Header=BB0_516 Depth=1
	imull	-72(%rsp), %r13d                # 4-byte Folded Reload
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_579:                              #   in Loop: Header=BB0_516 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_516:                              # =>This Inner Loop Header: Depth=1
	vmovd	%ebx, %xmm4
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-24(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$8, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpaddd	%xmm5, %xmm4, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_518
# %bb.517:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%eax, %esi
.LBB0_518:                              #   in Loop: Header=BB0_516 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_519
# %bb.520:                              #   in Loop: Header=BB0_516 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_521
.LBB0_522:                              #   in Loop: Header=BB0_516 Depth=1
	testb	$1, %r12b
	jne	.LBB0_524
.LBB0_523:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%ecx, %r13d
.LBB0_524:                              #   in Loop: Header=BB0_516 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_579
# %bb.525:                              #   in Loop: Header=BB0_516 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-20(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$8, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %ebp, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_527
# %bb.526:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%eax, %esi
.LBB0_527:                              #   in Loop: Header=BB0_516 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_528
# %bb.529:                              #   in Loop: Header=BB0_516 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_530
.LBB0_531:                              #   in Loop: Header=BB0_516 Depth=1
	testb	$1, %r12b
	jne	.LBB0_533
.LBB0_532:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%ecx, %r13d
.LBB0_533:                              #   in Loop: Header=BB0_516 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_579
# %bb.534:                              #   in Loop: Header=BB0_516 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-16(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$8, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r14d, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_536
# %bb.535:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%eax, %esi
.LBB0_536:                              #   in Loop: Header=BB0_516 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_537
# %bb.538:                              #   in Loop: Header=BB0_516 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_539
.LBB0_540:                              #   in Loop: Header=BB0_516 Depth=1
	testb	$1, %r12b
	jne	.LBB0_542
.LBB0_541:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%ecx, %r13d
.LBB0_542:                              #   in Loop: Header=BB0_516 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_579
# %bb.543:                              #   in Loop: Header=BB0_516 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-12(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$8, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpinsrd	$1, %r15d, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_545
# %bb.544:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%eax, %esi
.LBB0_545:                              #   in Loop: Header=BB0_516 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_546
# %bb.547:                              #   in Loop: Header=BB0_516 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_548
.LBB0_549:                              #   in Loop: Header=BB0_516 Depth=1
	testb	$1, %r12b
	jne	.LBB0_551
.LBB0_550:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%ecx, %r13d
.LBB0_551:                              #   in Loop: Header=BB0_516 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_579
# %bb.552:                              #   in Loop: Header=BB0_516 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-8(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$8, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	movl	$4, %ecx
	vpinsrd	$1, %ecx, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_554
# %bb.553:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%eax, %esi
.LBB0_554:                              #   in Loop: Header=BB0_516 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_555
# %bb.556:                              #   in Loop: Header=BB0_516 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_557
.LBB0_558:                              #   in Loop: Header=BB0_516 Depth=1
	testb	$1, %r12b
	jne	.LBB0_560
.LBB0_559:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%ecx, %r13d
.LBB0_560:                              #   in Loop: Header=BB0_516 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_579
# %bb.561:                              #   in Loop: Header=BB0_516 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-4(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$8, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	movl	$5, %ecx
	vpinsrd	$1, %ecx, %xmm4, %xmm6
	vpaddd	%xmm5, %xmm6, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_563
# %bb.562:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%eax, %esi
.LBB0_563:                              #   in Loop: Header=BB0_516 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_564
# %bb.565:                              #   in Loop: Header=BB0_516 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_566
.LBB0_567:                              #   in Loop: Header=BB0_516 Depth=1
	testb	$1, %r12b
	jne	.LBB0_569
.LBB0_568:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%ecx, %r13d
.LBB0_569:                              #   in Loop: Header=BB0_516 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_579
# %bb.570:                              #   in Loop: Header=BB0_516 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$8, %edx
	vmovd	%edx, %xmm5
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpand	%xmm1, %xmm5, %xmm5
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm2, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm5
	vmulps	%xmm0, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	movl	$6, %ecx
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vpaddd	%xmm5, %xmm4, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_572
# %bb.571:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%eax, %esi
.LBB0_572:                              #   in Loop: Header=BB0_516 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_573
# %bb.574:                              #   in Loop: Header=BB0_516 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_575
.LBB0_576:                              #   in Loop: Header=BB0_516 Depth=1
	testb	$1, %r12b
	jne	.LBB0_578
	jmp	.LBB0_577
.LBB0_519:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_522
.LBB0_521:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_523
	jmp	.LBB0_524
.LBB0_528:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_531
.LBB0_530:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_532
	jmp	.LBB0_533
.LBB0_537:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_540
.LBB0_539:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_541
	jmp	.LBB0_542
.LBB0_546:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_549
.LBB0_548:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_550
	jmp	.LBB0_551
.LBB0_555:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_558
.LBB0_557:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_559
	jmp	.LBB0_560
.LBB0_564:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_567
.LBB0_566:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_568
	jmp	.LBB0_569
.LBB0_573:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_576
.LBB0_575:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_578
.LBB0_577:                              #   in Loop: Header=BB0_516 Depth=1
	movl	%ecx, %r13d
	jmp	.LBB0_578
.LBB0_1320:                             #   in Loop: Header=BB0_1258 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_1321:                             #   in Loop: Header=BB0_1258 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_1258:                             # =>This Inner Loop Header: Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-21(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	movl	%r14d, %ecx
	cmpl	%eax, %r14d
	jge	.LBB0_1259
# %bb.1260:                             #   in Loop: Header=BB0_1258 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	jns	.LBB0_1261
.LBB0_1262:                             #   in Loop: Header=BB0_1258 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_1263
.LBB0_1264:                             #   in Loop: Header=BB0_1258 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_1266
.LBB0_1265:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%ecx, %ebp
.LBB0_1266:                             #   in Loop: Header=BB0_1258 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_1321
# %bb.1267:                             #   in Loop: Header=BB0_1258 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-17(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	1(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_1268
# %bb.1269:                             #   in Loop: Header=BB0_1258 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jge	.LBB0_1270
.LBB0_1271:                             #   in Loop: Header=BB0_1258 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_1272
.LBB0_1273:                             #   in Loop: Header=BB0_1258 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_1275
.LBB0_1274:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%ecx, %ebp
.LBB0_1275:                             #   in Loop: Header=BB0_1258 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_1321
# %bb.1276:                             #   in Loop: Header=BB0_1258 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-13(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	2(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_1277
# %bb.1278:                             #   in Loop: Header=BB0_1258 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jge	.LBB0_1279
.LBB0_1280:                             #   in Loop: Header=BB0_1258 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_1281
.LBB0_1282:                             #   in Loop: Header=BB0_1258 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_1284
.LBB0_1283:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%ecx, %ebp
.LBB0_1284:                             #   in Loop: Header=BB0_1258 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_1321
# %bb.1285:                             #   in Loop: Header=BB0_1258 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-9(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	3(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_1286
# %bb.1287:                             #   in Loop: Header=BB0_1258 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-3, %r14d
	jge	.LBB0_1288
.LBB0_1289:                             #   in Loop: Header=BB0_1258 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_1290
.LBB0_1291:                             #   in Loop: Header=BB0_1258 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_1293
.LBB0_1292:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%ecx, %ebp
.LBB0_1293:                             #   in Loop: Header=BB0_1258 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_1321
# %bb.1294:                             #   in Loop: Header=BB0_1258 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-5(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	4(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_1295
# %bb.1296:                             #   in Loop: Header=BB0_1258 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-4, %r14d
	jge	.LBB0_1297
.LBB0_1298:                             #   in Loop: Header=BB0_1258 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_1299
.LBB0_1300:                             #   in Loop: Header=BB0_1258 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_1302
.LBB0_1301:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%ecx, %ebp
.LBB0_1302:                             #   in Loop: Header=BB0_1258 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_1321
# %bb.1303:                             #   in Loop: Header=BB0_1258 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-1(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm1, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	5(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_1304
# %bb.1305:                             #   in Loop: Header=BB0_1258 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-5, %r14d
	jge	.LBB0_1306
.LBB0_1307:                             #   in Loop: Header=BB0_1258 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_1308
.LBB0_1309:                             #   in Loop: Header=BB0_1258 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_1311
.LBB0_1310:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%ecx, %ebp
.LBB0_1311:                             #   in Loop: Header=BB0_1258 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_1321
# %bb.1312:                             #   in Loop: Header=BB0_1258 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	3(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm1, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	6(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_1313
# %bb.1314:                             #   in Loop: Header=BB0_1258 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-6, %r14d
	jge	.LBB0_1315
.LBB0_1316:                             #   in Loop: Header=BB0_1258 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_1317
.LBB0_1318:                             #   in Loop: Header=BB0_1258 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_1320
	jmp	.LBB0_1319
.LBB0_1259:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%eax, %ecx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	js	.LBB0_1262
.LBB0_1261:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%ecx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_1264
.LBB0_1263:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_1265
	jmp	.LBB0_1266
.LBB0_1268:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jl	.LBB0_1271
.LBB0_1270:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_1273
.LBB0_1272:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_1274
	jmp	.LBB0_1275
.LBB0_1277:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jl	.LBB0_1280
.LBB0_1279:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_1282
.LBB0_1281:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_1283
	jmp	.LBB0_1284
.LBB0_1286:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-3, %r14d
	jl	.LBB0_1289
.LBB0_1288:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_1291
.LBB0_1290:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_1292
	jmp	.LBB0_1293
.LBB0_1295:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-4, %r14d
	jl	.LBB0_1298
.LBB0_1297:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_1300
.LBB0_1299:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_1301
	jmp	.LBB0_1302
.LBB0_1304:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-5, %r14d
	jl	.LBB0_1307
.LBB0_1306:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_1309
.LBB0_1308:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_1310
	jmp	.LBB0_1311
.LBB0_1313:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-6, %r14d
	jl	.LBB0_1316
.LBB0_1315:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_1318
.LBB0_1317:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	js	.LBB0_1320
.LBB0_1319:                             #   in Loop: Header=BB0_1258 Depth=1
	movl	%ecx, %ebp
	jmp	.LBB0_1320
.LBB0_1074:                             #   in Loop: Header=BB0_1012 Depth=1
	imull	-72(%rsp), %r13d                # 4-byte Folded Reload
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_1075:                             #   in Loop: Header=BB0_1012 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_1012:                             # =>This Inner Loop Header: Depth=1
	vmovd	%ebx, %xmm3
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-24(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	movzbl	%dl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpaddd	%xmm4, %xmm3, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1014
# %bb.1013:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%eax, %esi
.LBB0_1014:                             #   in Loop: Header=BB0_1012 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1015
# %bb.1016:                             #   in Loop: Header=BB0_1012 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1017
.LBB0_1018:                             #   in Loop: Header=BB0_1012 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1020
.LBB0_1019:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%ecx, %r13d
.LBB0_1020:                             #   in Loop: Header=BB0_1012 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_1075
# %bb.1021:                             #   in Loop: Header=BB0_1012 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-20(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	movzbl	%dl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %ebp, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1023
# %bb.1022:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%eax, %esi
.LBB0_1023:                             #   in Loop: Header=BB0_1012 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1024
# %bb.1025:                             #   in Loop: Header=BB0_1012 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1026
.LBB0_1027:                             #   in Loop: Header=BB0_1012 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1029
.LBB0_1028:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%ecx, %r13d
.LBB0_1029:                             #   in Loop: Header=BB0_1012 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_1075
# %bb.1030:                             #   in Loop: Header=BB0_1012 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-16(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	movzbl	%dl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %r14d, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1032
# %bb.1031:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%eax, %esi
.LBB0_1032:                             #   in Loop: Header=BB0_1012 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1033
# %bb.1034:                             #   in Loop: Header=BB0_1012 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1035
.LBB0_1036:                             #   in Loop: Header=BB0_1012 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1038
.LBB0_1037:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%ecx, %r13d
.LBB0_1038:                             #   in Loop: Header=BB0_1012 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_1075
# %bb.1039:                             #   in Loop: Header=BB0_1012 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-12(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	movzbl	%dl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %r15d, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1041
# %bb.1040:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%eax, %esi
.LBB0_1041:                             #   in Loop: Header=BB0_1012 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1042
# %bb.1043:                             #   in Loop: Header=BB0_1012 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1044
.LBB0_1045:                             #   in Loop: Header=BB0_1012 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1047
.LBB0_1046:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%ecx, %r13d
.LBB0_1047:                             #   in Loop: Header=BB0_1012 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_1075
# %bb.1048:                             #   in Loop: Header=BB0_1012 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-8(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	movzbl	%dl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$4, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1050
# %bb.1049:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%eax, %esi
.LBB0_1050:                             #   in Loop: Header=BB0_1012 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1051
# %bb.1052:                             #   in Loop: Header=BB0_1012 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1053
.LBB0_1054:                             #   in Loop: Header=BB0_1012 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1056
.LBB0_1055:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%ecx, %r13d
.LBB0_1056:                             #   in Loop: Header=BB0_1012 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_1075
# %bb.1057:                             #   in Loop: Header=BB0_1012 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-4(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	movzbl	%dl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$5, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1059
# %bb.1058:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%eax, %esi
.LBB0_1059:                             #   in Loop: Header=BB0_1012 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1060
# %bb.1061:                             #   in Loop: Header=BB0_1012 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1062
.LBB0_1063:                             #   in Loop: Header=BB0_1012 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1065
.LBB0_1064:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%ecx, %r13d
.LBB0_1065:                             #   in Loop: Header=BB0_1012 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_1075
# %bb.1066:                             #   in Loop: Header=BB0_1012 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$16, %edx
	movzbl	%dl, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$6, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm3
	vpaddd	%xmm4, %xmm3, %xmm3
	vpextrd	$1, %xmm3, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1068
# %bb.1067:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%eax, %esi
.LBB0_1068:                             #   in Loop: Header=BB0_1012 Depth=1
	vpmovsxdq	%xmm3, %xmm4
	vmovmskpd	%xmm4, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1069
# %bb.1070:                             #   in Loop: Header=BB0_1012 Depth=1
	vmovd	%xmm3, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1071
.LBB0_1072:                             #   in Loop: Header=BB0_1012 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1074
	jmp	.LBB0_1073
.LBB0_1015:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1018
.LBB0_1017:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1019
	jmp	.LBB0_1020
.LBB0_1024:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1027
.LBB0_1026:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1028
	jmp	.LBB0_1029
.LBB0_1033:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1036
.LBB0_1035:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1037
	jmp	.LBB0_1038
.LBB0_1042:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1045
.LBB0_1044:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1046
	jmp	.LBB0_1047
.LBB0_1051:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1054
.LBB0_1053:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1055
	jmp	.LBB0_1056
.LBB0_1060:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1063
.LBB0_1062:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1064
	jmp	.LBB0_1065
.LBB0_1069:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%esi, %edx
	vmovd	%xmm3, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1072
.LBB0_1071:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_1074
.LBB0_1073:                             #   in Loop: Header=BB0_1012 Depth=1
	movl	%ecx, %r13d
	jmp	.LBB0_1074
.LBB0_1156:                             #   in Loop: Header=BB0_1094 Depth=1
	imull	-72(%rsp), %r13d                # 4-byte Folded Reload
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_1157:                             #   in Loop: Header=BB0_1094 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_1094:                             # =>This Inner Loop Header: Depth=1
	vmovd	%ebx, %xmm3
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-24(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpaddd	%xmm4, %xmm3, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1096
# %bb.1095:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%eax, %esi
.LBB0_1096:                             #   in Loop: Header=BB0_1094 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1097
# %bb.1098:                             #   in Loop: Header=BB0_1094 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1099
.LBB0_1100:                             #   in Loop: Header=BB0_1094 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1102
.LBB0_1101:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%ecx, %r13d
.LBB0_1102:                             #   in Loop: Header=BB0_1094 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_1157
# %bb.1103:                             #   in Loop: Header=BB0_1094 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-20(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %ebp, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1105
# %bb.1104:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%eax, %esi
.LBB0_1105:                             #   in Loop: Header=BB0_1094 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1106
# %bb.1107:                             #   in Loop: Header=BB0_1094 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1108
.LBB0_1109:                             #   in Loop: Header=BB0_1094 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1111
.LBB0_1110:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%ecx, %r13d
.LBB0_1111:                             #   in Loop: Header=BB0_1094 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_1157
# %bb.1112:                             #   in Loop: Header=BB0_1094 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-16(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %r14d, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1114
# %bb.1113:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%eax, %esi
.LBB0_1114:                             #   in Loop: Header=BB0_1094 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1115
# %bb.1116:                             #   in Loop: Header=BB0_1094 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1117
.LBB0_1118:                             #   in Loop: Header=BB0_1094 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1120
.LBB0_1119:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%ecx, %r13d
.LBB0_1120:                             #   in Loop: Header=BB0_1094 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_1157
# %bb.1121:                             #   in Loop: Header=BB0_1094 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-12(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %r15d, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1123
# %bb.1122:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%eax, %esi
.LBB0_1123:                             #   in Loop: Header=BB0_1094 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1124
# %bb.1125:                             #   in Loop: Header=BB0_1094 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1126
.LBB0_1127:                             #   in Loop: Header=BB0_1094 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1129
.LBB0_1128:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%ecx, %r13d
.LBB0_1129:                             #   in Loop: Header=BB0_1094 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_1157
# %bb.1130:                             #   in Loop: Header=BB0_1094 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-8(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$4, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1132
# %bb.1131:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%eax, %esi
.LBB0_1132:                             #   in Loop: Header=BB0_1094 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1133
# %bb.1134:                             #   in Loop: Header=BB0_1094 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1135
.LBB0_1136:                             #   in Loop: Header=BB0_1094 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1138
.LBB0_1137:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%ecx, %r13d
.LBB0_1138:                             #   in Loop: Header=BB0_1094 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_1157
# %bb.1139:                             #   in Loop: Header=BB0_1094 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-4(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$5, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1141
# %bb.1140:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%eax, %esi
.LBB0_1141:                             #   in Loop: Header=BB0_1094 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1142
# %bb.1143:                             #   in Loop: Header=BB0_1094 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1144
.LBB0_1145:                             #   in Loop: Header=BB0_1094 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1147
.LBB0_1146:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%ecx, %r13d
.LBB0_1147:                             #   in Loop: Header=BB0_1094 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_1157
# %bb.1148:                             #   in Loop: Header=BB0_1094 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$6, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm3
	vpaddd	%xmm4, %xmm3, %xmm3
	vpextrd	$1, %xmm3, %esi
	cmpl	%eax, %esi
	jl	.LBB0_1150
# %bb.1149:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%eax, %esi
.LBB0_1150:                             #   in Loop: Header=BB0_1094 Depth=1
	vpmovsxdq	%xmm3, %xmm4
	vmovmskpd	%xmm4, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_1151
# %bb.1152:                             #   in Loop: Header=BB0_1094 Depth=1
	vmovd	%xmm3, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_1153
.LBB0_1154:                             #   in Loop: Header=BB0_1094 Depth=1
	testb	$1, %r12b
	jne	.LBB0_1156
	jmp	.LBB0_1155
.LBB0_1097:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1100
.LBB0_1099:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1101
	jmp	.LBB0_1102
.LBB0_1106:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1109
.LBB0_1108:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1110
	jmp	.LBB0_1111
.LBB0_1115:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1118
.LBB0_1117:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1119
	jmp	.LBB0_1120
.LBB0_1124:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1127
.LBB0_1126:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1128
	jmp	.LBB0_1129
.LBB0_1133:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1136
.LBB0_1135:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1137
	jmp	.LBB0_1138
.LBB0_1142:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1145
.LBB0_1144:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_1146
	jmp	.LBB0_1147
.LBB0_1151:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%esi, %edx
	vmovd	%xmm3, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_1154
.LBB0_1153:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_1156
.LBB0_1155:                             #   in Loop: Header=BB0_1094 Depth=1
	movl	%ecx, %r13d
	jmp	.LBB0_1156
.LBB0_330:                              #   in Loop: Header=BB0_268 Depth=1
	imull	-72(%rsp), %r13d                # 4-byte Folded Reload
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_331:                              #   in Loop: Header=BB0_268 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_268:                              # =>This Inner Loop Header: Depth=1
	vmovd	%ebx, %xmm3
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-24(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$24, %edx
	shrl	$16, %ecx
	movzbl	%cl, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpaddd	%xmm4, %xmm3, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_270
# %bb.269:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%eax, %esi
.LBB0_270:                              #   in Loop: Header=BB0_268 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_271
# %bb.272:                              #   in Loop: Header=BB0_268 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_273
.LBB0_274:                              #   in Loop: Header=BB0_268 Depth=1
	testb	$1, %r12b
	jne	.LBB0_276
.LBB0_275:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%ecx, %r13d
.LBB0_276:                              #   in Loop: Header=BB0_268 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_331
# %bb.277:                              #   in Loop: Header=BB0_268 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-20(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$24, %edx
	shrl	$16, %ecx
	movzbl	%cl, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %ebp, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_279
# %bb.278:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%eax, %esi
.LBB0_279:                              #   in Loop: Header=BB0_268 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_280
# %bb.281:                              #   in Loop: Header=BB0_268 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_282
.LBB0_283:                              #   in Loop: Header=BB0_268 Depth=1
	testb	$1, %r12b
	jne	.LBB0_285
.LBB0_284:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%ecx, %r13d
.LBB0_285:                              #   in Loop: Header=BB0_268 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_331
# %bb.286:                              #   in Loop: Header=BB0_268 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-16(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$24, %edx
	shrl	$16, %ecx
	movzbl	%cl, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %r14d, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_288
# %bb.287:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%eax, %esi
.LBB0_288:                              #   in Loop: Header=BB0_268 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_289
# %bb.290:                              #   in Loop: Header=BB0_268 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_291
.LBB0_292:                              #   in Loop: Header=BB0_268 Depth=1
	testb	$1, %r12b
	jne	.LBB0_294
.LBB0_293:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%ecx, %r13d
.LBB0_294:                              #   in Loop: Header=BB0_268 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_331
# %bb.295:                              #   in Loop: Header=BB0_268 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-12(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$24, %edx
	shrl	$16, %ecx
	movzbl	%cl, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %r15d, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_297
# %bb.296:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%eax, %esi
.LBB0_297:                              #   in Loop: Header=BB0_268 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_298
# %bb.299:                              #   in Loop: Header=BB0_268 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_300
.LBB0_301:                              #   in Loop: Header=BB0_268 Depth=1
	testb	$1, %r12b
	jne	.LBB0_303
.LBB0_302:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%ecx, %r13d
.LBB0_303:                              #   in Loop: Header=BB0_268 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_331
# %bb.304:                              #   in Loop: Header=BB0_268 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-8(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$24, %edx
	shrl	$16, %ecx
	movzbl	%cl, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$4, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_306
# %bb.305:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%eax, %esi
.LBB0_306:                              #   in Loop: Header=BB0_268 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_307
# %bb.308:                              #   in Loop: Header=BB0_268 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_309
.LBB0_310:                              #   in Loop: Header=BB0_268 Depth=1
	testb	$1, %r12b
	jne	.LBB0_312
.LBB0_311:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%ecx, %r13d
.LBB0_312:                              #   in Loop: Header=BB0_268 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_331
# %bb.313:                              #   in Loop: Header=BB0_268 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-4(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$24, %edx
	shrl	$16, %ecx
	movzbl	%cl, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$5, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_315
# %bb.314:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%eax, %esi
.LBB0_315:                              #   in Loop: Header=BB0_268 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_316
# %bb.317:                              #   in Loop: Header=BB0_268 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_318
.LBB0_319:                              #   in Loop: Header=BB0_268 Depth=1
	testb	$1, %r12b
	jne	.LBB0_321
.LBB0_320:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%ecx, %r13d
.LBB0_321:                              #   in Loop: Header=BB0_268 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_331
# %bb.322:                              #   in Loop: Header=BB0_268 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movl	%ecx, %edx
	shrl	$24, %edx
	shrl	$16, %ecx
	movzbl	%cl, %ecx
	vmovd	%ecx, %xmm4
	vpinsrd	$1, %edx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$6, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm3
	vpaddd	%xmm4, %xmm3, %xmm3
	vpextrd	$1, %xmm3, %esi
	cmpl	%eax, %esi
	jl	.LBB0_324
# %bb.323:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%eax, %esi
.LBB0_324:                              #   in Loop: Header=BB0_268 Depth=1
	vpmovsxdq	%xmm3, %xmm4
	vmovmskpd	%xmm4, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_325
# %bb.326:                              #   in Loop: Header=BB0_268 Depth=1
	vmovd	%xmm3, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_327
.LBB0_328:                              #   in Loop: Header=BB0_268 Depth=1
	testb	$1, %r12b
	jne	.LBB0_330
	jmp	.LBB0_329
.LBB0_271:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_274
.LBB0_273:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_275
	jmp	.LBB0_276
.LBB0_280:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_283
.LBB0_282:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_284
	jmp	.LBB0_285
.LBB0_289:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_292
.LBB0_291:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_293
	jmp	.LBB0_294
.LBB0_298:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_301
.LBB0_300:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_302
	jmp	.LBB0_303
.LBB0_307:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_310
.LBB0_309:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_311
	jmp	.LBB0_312
.LBB0_316:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_319
.LBB0_318:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_320
	jmp	.LBB0_321
.LBB0_325:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%esi, %edx
	vmovd	%xmm3, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_328
.LBB0_327:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_330
.LBB0_329:                              #   in Loop: Header=BB0_268 Depth=1
	movl	%ecx, %r13d
	jmp	.LBB0_330
.LBB0_660:                              #   in Loop: Header=BB0_598 Depth=1
	imull	-72(%rsp), %r13d                # 4-byte Folded Reload
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_661:                              #   in Loop: Header=BB0_598 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_598:                              # =>This Inner Loop Header: Depth=1
	vmovd	%ebx, %xmm3
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-24(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpaddd	%xmm4, %xmm3, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_600
# %bb.599:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%eax, %esi
.LBB0_600:                              #   in Loop: Header=BB0_598 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_601
# %bb.602:                              #   in Loop: Header=BB0_598 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_603
.LBB0_604:                              #   in Loop: Header=BB0_598 Depth=1
	testb	$1, %r12b
	jne	.LBB0_606
.LBB0_605:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%ecx, %r13d
.LBB0_606:                              #   in Loop: Header=BB0_598 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_661
# %bb.607:                              #   in Loop: Header=BB0_598 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-20(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %ebp, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_609
# %bb.608:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%eax, %esi
.LBB0_609:                              #   in Loop: Header=BB0_598 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_610
# %bb.611:                              #   in Loop: Header=BB0_598 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_612
.LBB0_613:                              #   in Loop: Header=BB0_598 Depth=1
	testb	$1, %r12b
	jne	.LBB0_615
.LBB0_614:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%ecx, %r13d
.LBB0_615:                              #   in Loop: Header=BB0_598 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_661
# %bb.616:                              #   in Loop: Header=BB0_598 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-16(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %r14d, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_618
# %bb.617:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%eax, %esi
.LBB0_618:                              #   in Loop: Header=BB0_598 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_619
# %bb.620:                              #   in Loop: Header=BB0_598 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_621
.LBB0_622:                              #   in Loop: Header=BB0_598 Depth=1
	testb	$1, %r12b
	jne	.LBB0_624
.LBB0_623:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%ecx, %r13d
.LBB0_624:                              #   in Loop: Header=BB0_598 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_661
# %bb.625:                              #   in Loop: Header=BB0_598 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-12(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	vpinsrd	$1, %r15d, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_627
# %bb.626:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%eax, %esi
.LBB0_627:                              #   in Loop: Header=BB0_598 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_628
# %bb.629:                              #   in Loop: Header=BB0_598 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_630
.LBB0_631:                              #   in Loop: Header=BB0_598 Depth=1
	testb	$1, %r12b
	jne	.LBB0_633
.LBB0_632:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%ecx, %r13d
.LBB0_633:                              #   in Loop: Header=BB0_598 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_661
# %bb.634:                              #   in Loop: Header=BB0_598 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-8(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$4, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_636
# %bb.635:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%eax, %esi
.LBB0_636:                              #   in Loop: Header=BB0_598 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_637
# %bb.638:                              #   in Loop: Header=BB0_598 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_639
.LBB0_640:                              #   in Loop: Header=BB0_598 Depth=1
	testb	$1, %r12b
	jne	.LBB0_642
.LBB0_641:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%ecx, %r13d
.LBB0_642:                              #   in Loop: Header=BB0_598 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_661
# %bb.643:                              #   in Loop: Header=BB0_598 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	-4(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$5, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm5
	vpaddd	%xmm4, %xmm5, %xmm4
	vpextrd	$1, %xmm4, %esi
	cmpl	%eax, %esi
	jl	.LBB0_645
# %bb.644:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%eax, %esi
.LBB0_645:                              #   in Loop: Header=BB0_598 Depth=1
	vpmovsxdq	%xmm4, %xmm5
	vmovmskpd	%xmm5, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_646
# %bb.647:                              #   in Loop: Header=BB0_598 Depth=1
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_648
.LBB0_649:                              #   in Loop: Header=BB0_598 Depth=1
	testb	$1, %r12b
	jne	.LBB0_651
.LBB0_650:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%ecx, %r13d
.LBB0_651:                              #   in Loop: Header=BB0_598 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_661
# %bb.652:                              #   in Loop: Header=BB0_598 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movl	(%rcx,%r11), %ecx
	movzbl	%ch, %edx
	shrl	$24, %ecx
	vmovd	%edx, %xmm4
	vpinsrd	$1, %ecx, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm1, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm4
	vmulps	%xmm0, %xmm4, %xmm4
	vcvttps2dq	%xmm4, %xmm4
	movl	$6, %ecx
	vpinsrd	$1, %ecx, %xmm3, %xmm3
	vpaddd	%xmm4, %xmm3, %xmm3
	vpextrd	$1, %xmm3, %esi
	cmpl	%eax, %esi
	jl	.LBB0_654
# %bb.653:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%eax, %esi
.LBB0_654:                              #   in Loop: Header=BB0_598 Depth=1
	vpmovsxdq	%xmm3, %xmm4
	vmovmskpd	%xmm4, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_655
# %bb.656:                              #   in Loop: Header=BB0_598 Depth=1
	vmovd	%xmm3, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_657
.LBB0_658:                              #   in Loop: Header=BB0_598 Depth=1
	testb	$1, %r12b
	jne	.LBB0_660
	jmp	.LBB0_659
.LBB0_601:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_604
.LBB0_603:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_605
	jmp	.LBB0_606
.LBB0_610:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_613
.LBB0_612:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_614
	jmp	.LBB0_615
.LBB0_619:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_622
.LBB0_621:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_623
	jmp	.LBB0_624
.LBB0_628:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_631
.LBB0_630:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_632
	jmp	.LBB0_633
.LBB0_637:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_640
.LBB0_639:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_641
	jmp	.LBB0_642
.LBB0_646:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%esi, %edx
	vmovd	%xmm4, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_649
.LBB0_648:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_650
	jmp	.LBB0_651
.LBB0_655:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%esi, %edx
	vmovd	%xmm3, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_658
.LBB0_657:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_660
.LBB0_659:                              #   in Loop: Header=BB0_598 Depth=1
	movl	%ecx, %r13d
	jmp	.LBB0_660
.LBB0_84:                               #   in Loop: Header=BB0_22 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-56(%rsp), %rcx                 # 8-byte Reload
	movl	%eax, (%rcx,%r11)
	.p2align	4, 0x90
.LBB0_85:                               #   in Loop: Header=BB0_22 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_22:                               # =>This Inner Loop Header: Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	movzbl	-22(%rax,%r11), %eax
	vcvtsi2ss	%eax, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm5, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r14d
	movl	%r14d, %eax
	cmpl	%edx, %r14d
	jl	.LBB0_24
# %bb.23:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%edx, %eax
.LBB0_24:                               #   in Loop: Header=BB0_22 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	jns	.LBB0_25
# %bb.26:                               #   in Loop: Header=BB0_22 Depth=1
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
	movq	-56(%rsp), %rsi                 # 8-byte Reload
	movl	%eax, -24(%rsi,%r11)
	cmpl	$1, %ecx
	je	.LBB0_85
# %bb.31:                               #   in Loop: Header=BB0_22 Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	movzbl	-18(%rax,%r11), %eax
	vcvtsi2ss	%eax, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm5, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r14d
	leal	1(%r14), %eax
	cmpl	%edx, %eax
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
	movq	-56(%rsp), %rsi                 # 8-byte Reload
	movl	%eax, -20(%rsi,%r11)
	cmpl	$2, %ecx
	je	.LBB0_85
# %bb.40:                               #   in Loop: Header=BB0_22 Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	movzbl	-14(%rax,%r11), %eax
	vcvtsi2ss	%eax, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm5, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r14d
	leal	2(%r14), %eax
	cmpl	%edx, %eax
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
.LBB0_47:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %ebp
.LBB0_48:                               #   in Loop: Header=BB0_22 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-56(%rsp), %rsi                 # 8-byte Reload
	movl	%eax, -16(%rsi,%r11)
	cmpl	$3, %ecx
	je	.LBB0_85
# %bb.49:                               #   in Loop: Header=BB0_22 Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	movzbl	-10(%rax,%r11), %eax
	vcvtsi2ss	%eax, %xmm0, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm5, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r14d
	leal	3(%r14), %eax
	cmpl	%edx, %eax
	jge	.LBB0_50
# %bb.51:                               #   in Loop: Header=BB0_22 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-3, %r14d
	jge	.LBB0_52
.LBB0_53:                               #   in Loop: Header=BB0_22 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jge	.LBB0_54
.LBB0_55:                               #   in Loop: Header=BB0_22 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_57
.LBB0_56:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %ebp
.LBB0_57:                               #   in Loop: Header=BB0_22 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-56(%rsp), %rsi                 # 8-byte Reload
	movl	%eax, -12(%rsi,%r11)
	cmpl	$4, %ecx
	je	.LBB0_85
# %bb.58:                               #   in Loop: Header=BB0_22 Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	movzbl	-6(%rax,%r11), %eax
	vcvtsi2ss	%eax, %xmm0, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm5, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r14d
	leal	4(%r14), %eax
	cmpl	%edx, %eax
	jge	.LBB0_59
# %bb.60:                               #   in Loop: Header=BB0_22 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-4, %r14d
	jge	.LBB0_61
.LBB0_62:                               #   in Loop: Header=BB0_22 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jge	.LBB0_63
.LBB0_64:                               #   in Loop: Header=BB0_22 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_66
.LBB0_65:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %ebp
.LBB0_66:                               #   in Loop: Header=BB0_22 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-56(%rsp), %rsi                 # 8-byte Reload
	movl	%eax, -8(%rsi,%r11)
	cmpl	$5, %ecx
	je	.LBB0_85
# %bb.67:                               #   in Loop: Header=BB0_22 Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	movzbl	-2(%rax,%r11), %eax
	vcvtsi2ss	%eax, %xmm0, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm5, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r14d
	leal	5(%r14), %eax
	cmpl	%edx, %eax
	jge	.LBB0_68
# %bb.69:                               #   in Loop: Header=BB0_22 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-5, %r14d
	jge	.LBB0_70
.LBB0_71:                               #   in Loop: Header=BB0_22 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jge	.LBB0_72
.LBB0_73:                               #   in Loop: Header=BB0_22 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_75
.LBB0_74:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %ebp
.LBB0_75:                               #   in Loop: Header=BB0_22 Depth=1
	imull	%ecx, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-56(%rsp), %rsi                 # 8-byte Reload
	movl	%eax, -4(%rsi,%r11)
	cmpl	$6, %ecx
	je	.LBB0_85
# %bb.76:                               #   in Loop: Header=BB0_22 Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	movzbl	2(%rax,%r11), %eax
	vcvtsi2ss	%eax, %xmm0, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm5, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r14d
	leal	6(%r14), %eax
	cmpl	%edx, %eax
	jge	.LBB0_77
# %bb.78:                               #   in Loop: Header=BB0_22 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-6, %r14d
	jge	.LBB0_79
.LBB0_80:                               #   in Loop: Header=BB0_22 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jge	.LBB0_81
.LBB0_82:                               #   in Loop: Header=BB0_22 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_84
	jmp	.LBB0_83
.LBB0_25:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %r15d
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
	movl	%edx, %eax
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jl	.LBB0_35
.LBB0_34:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %r15d
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
	movl	%edx, %eax
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jl	.LBB0_44
.LBB0_43:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jl	.LBB0_46
.LBB0_45:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%r9d, %eax
	testl	%r14d, %r14d
	jns	.LBB0_47
	jmp	.LBB0_48
.LBB0_50:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%edx, %eax
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-3, %r14d
	jl	.LBB0_53
.LBB0_52:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jl	.LBB0_55
.LBB0_54:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%r9d, %eax
	testl	%r14d, %r14d
	jns	.LBB0_56
	jmp	.LBB0_57
.LBB0_59:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%edx, %eax
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-4, %r14d
	jl	.LBB0_62
.LBB0_61:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jl	.LBB0_64
.LBB0_63:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%r9d, %eax
	testl	%r14d, %r14d
	jns	.LBB0_65
	jmp	.LBB0_66
.LBB0_68:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%edx, %eax
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-5, %r14d
	jl	.LBB0_71
.LBB0_70:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jl	.LBB0_73
.LBB0_72:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%r9d, %eax
	testl	%r14d, %r14d
	jns	.LBB0_74
	jmp	.LBB0_75
.LBB0_77:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%edx, %eax
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-6, %r14d
	jl	.LBB0_80
.LBB0_79:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %eax
	cmpl	%r9d, %r14d
	jl	.LBB0_82
.LBB0_81:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%r9d, %eax
	testl	%r14d, %r14d
	js	.LBB0_84
.LBB0_83:                               #   in Loop: Header=BB0_22 Depth=1
	movl	%eax, %ebp
	jmp	.LBB0_84
.LBB0_414:                              #   in Loop: Header=BB0_352 Depth=1
	imull	-72(%rsp), %r13d                # 4-byte Folded Reload
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_415:                              #   in Loop: Header=BB0_352 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_352:                              # =>This Inner Loop Header: Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	vpbroadcastd	-24(%rcx,%r11), %xmm6
	vmovd	%ebx, %xmm5
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpaddd	%xmm6, %xmm5, %xmm6
	vpextrd	$1, %xmm6, %esi
	cmpl	%eax, %esi
	jl	.LBB0_354
# %bb.353:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%eax, %esi
.LBB0_354:                              #   in Loop: Header=BB0_352 Depth=1
	vpmovsxdq	%xmm6, %xmm7
	vmovmskpd	%xmm7, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_355
# %bb.356:                              #   in Loop: Header=BB0_352 Depth=1
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_357
.LBB0_358:                              #   in Loop: Header=BB0_352 Depth=1
	testb	$1, %r12b
	jne	.LBB0_360
.LBB0_359:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%ecx, %r13d
.LBB0_360:                              #   in Loop: Header=BB0_352 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_415
# %bb.361:                              #   in Loop: Header=BB0_352 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	vpbroadcastd	-20(%rcx,%r11), %xmm6
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpinsrd	$1, %ebp, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %esi
	cmpl	%eax, %esi
	jl	.LBB0_363
# %bb.362:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%eax, %esi
.LBB0_363:                              #   in Loop: Header=BB0_352 Depth=1
	vpmovsxdq	%xmm6, %xmm7
	vmovmskpd	%xmm7, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_364
# %bb.365:                              #   in Loop: Header=BB0_352 Depth=1
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_366
.LBB0_367:                              #   in Loop: Header=BB0_352 Depth=1
	testb	$1, %r12b
	jne	.LBB0_369
.LBB0_368:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%ecx, %r13d
.LBB0_369:                              #   in Loop: Header=BB0_352 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_415
# %bb.370:                              #   in Loop: Header=BB0_352 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	vpbroadcastd	-16(%rcx,%r11), %xmm6
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpinsrd	$1, %r14d, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %esi
	cmpl	%eax, %esi
	jl	.LBB0_372
# %bb.371:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%eax, %esi
.LBB0_372:                              #   in Loop: Header=BB0_352 Depth=1
	vpmovsxdq	%xmm6, %xmm7
	vmovmskpd	%xmm7, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_373
# %bb.374:                              #   in Loop: Header=BB0_352 Depth=1
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_375
.LBB0_376:                              #   in Loop: Header=BB0_352 Depth=1
	testb	$1, %r12b
	jne	.LBB0_378
.LBB0_377:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%ecx, %r13d
.LBB0_378:                              #   in Loop: Header=BB0_352 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_415
# %bb.379:                              #   in Loop: Header=BB0_352 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	vpbroadcastd	-12(%rcx,%r11), %xmm6
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpinsrd	$1, %r15d, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %esi
	cmpl	%eax, %esi
	jl	.LBB0_381
# %bb.380:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%eax, %esi
.LBB0_381:                              #   in Loop: Header=BB0_352 Depth=1
	vpmovsxdq	%xmm6, %xmm7
	vmovmskpd	%xmm7, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_382
# %bb.383:                              #   in Loop: Header=BB0_352 Depth=1
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_384
.LBB0_385:                              #   in Loop: Header=BB0_352 Depth=1
	testb	$1, %r12b
	jne	.LBB0_387
.LBB0_386:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%ecx, %r13d
.LBB0_387:                              #   in Loop: Header=BB0_352 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_415
# %bb.388:                              #   in Loop: Header=BB0_352 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	vpbroadcastd	-8(%rcx,%r11), %xmm6
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	movl	$4, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %esi
	cmpl	%eax, %esi
	jl	.LBB0_390
# %bb.389:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%eax, %esi
.LBB0_390:                              #   in Loop: Header=BB0_352 Depth=1
	vpmovsxdq	%xmm6, %xmm7
	vmovmskpd	%xmm7, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_391
# %bb.392:                              #   in Loop: Header=BB0_352 Depth=1
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_393
.LBB0_394:                              #   in Loop: Header=BB0_352 Depth=1
	testb	$1, %r12b
	jne	.LBB0_396
.LBB0_395:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%ecx, %r13d
.LBB0_396:                              #   in Loop: Header=BB0_352 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_415
# %bb.397:                              #   in Loop: Header=BB0_352 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	vpbroadcastd	-4(%rcx,%r11), %xmm6
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	movl	$5, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %esi
	cmpl	%eax, %esi
	jl	.LBB0_399
# %bb.398:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%eax, %esi
.LBB0_399:                              #   in Loop: Header=BB0_352 Depth=1
	vpmovsxdq	%xmm6, %xmm7
	vmovmskpd	%xmm7, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_400
# %bb.401:                              #   in Loop: Header=BB0_352 Depth=1
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_402
.LBB0_403:                              #   in Loop: Header=BB0_352 Depth=1
	testb	$1, %r12b
	jne	.LBB0_405
.LBB0_404:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%ecx, %r13d
.LBB0_405:                              #   in Loop: Header=BB0_352 Depth=1
	movq	-72(%rsp), %rsi                 # 8-byte Reload
	imull	%esi, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_415
# %bb.406:                              #   in Loop: Header=BB0_352 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	vpbroadcastd	(%rcx,%r11), %xmm6
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	movl	$6, %ecx
	vpinsrd	$1, %ecx, %xmm5, %xmm5
	vpaddd	%xmm6, %xmm5, %xmm5
	vpextrd	$1, %xmm5, %esi
	cmpl	%eax, %esi
	jl	.LBB0_408
# %bb.407:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%eax, %esi
.LBB0_408:                              #   in Loop: Header=BB0_352 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_409
# %bb.410:                              #   in Loop: Header=BB0_352 Depth=1
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_411
.LBB0_412:                              #   in Loop: Header=BB0_352 Depth=1
	testb	$1, %r12b
	jne	.LBB0_414
	jmp	.LBB0_413
.LBB0_355:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%esi, %edx
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_358
.LBB0_357:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_359
	jmp	.LBB0_360
.LBB0_364:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%esi, %edx
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_367
.LBB0_366:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_368
	jmp	.LBB0_369
.LBB0_373:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%esi, %edx
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_376
.LBB0_375:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_377
	jmp	.LBB0_378
.LBB0_382:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%esi, %edx
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_385
.LBB0_384:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_386
	jmp	.LBB0_387
.LBB0_391:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%esi, %edx
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_394
.LBB0_393:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_395
	jmp	.LBB0_396
.LBB0_400:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%esi, %edx
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_403
.LBB0_402:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	je	.LBB0_404
	jmp	.LBB0_405
.LBB0_409:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%esi, %edx
	vmovd	%xmm5, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_412
.LBB0_411:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_414
.LBB0_413:                              #   in Loop: Header=BB0_352 Depth=1
	movl	%ecx, %r13d
	jmp	.LBB0_414
.LBB0_166:                              #   in Loop: Header=BB0_104 Depth=1
	imull	-72(%rsp), %r13d                # 4-byte Folded Reload
	addl	%edx, %r13d
	movslq	%r13d, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-56(%rsp), %rcx                 # 8-byte Reload
	movl	%eax, (%rcx,%r11)
	.p2align	4, 0x90
.LBB0_167:                              #   in Loop: Header=BB0_104 Depth=1
	incq	%r15
	addq	%r10, %r11
	cmpq	%r15, %r8
	je	.LBB0_1322
.LBB0_104:                              # =>This Inner Loop Header: Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	vpbroadcastd	-24(%rax,%r11), %xmm6
	vmovd	%r15d, %xmm5
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpaddd	%xmm6, %xmm5, %xmm6
	vpextrd	$1, %xmm6, %eax
	cmpl	%esi, %eax
	jl	.LBB0_106
# %bb.105:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%esi, %eax
.LBB0_106:                              #   in Loop: Header=BB0_104 Depth=1
	vpmovsxdq	%xmm6, %xmm7
	vmovmskpd	%xmm7, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_107
# %bb.108:                              #   in Loop: Header=BB0_104 Depth=1
	vmovd	%xmm6, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_109
.LBB0_110:                              #   in Loop: Header=BB0_104 Depth=1
	testb	$1, %r12b
	jne	.LBB0_112
.LBB0_111:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %r13d
.LBB0_112:                              #   in Loop: Header=BB0_104 Depth=1
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	imull	%ecx, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%eax, -24(%rdx,%r11)
	cmpl	$1, %ecx
	je	.LBB0_167
# %bb.113:                              #   in Loop: Header=BB0_104 Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	vpbroadcastd	-20(%rax,%r11), %xmm6
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpinsrd	$1, %ebp, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %eax
	cmpl	%esi, %eax
	jl	.LBB0_115
# %bb.114:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%esi, %eax
.LBB0_115:                              #   in Loop: Header=BB0_104 Depth=1
	vpmovsxdq	%xmm6, %xmm7
	vmovmskpd	%xmm7, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_116
# %bb.117:                              #   in Loop: Header=BB0_104 Depth=1
	vmovd	%xmm6, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_118
.LBB0_119:                              #   in Loop: Header=BB0_104 Depth=1
	testb	$1, %r12b
	jne	.LBB0_121
.LBB0_120:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %r13d
.LBB0_121:                              #   in Loop: Header=BB0_104 Depth=1
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	imull	%ecx, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%eax, -20(%rdx,%r11)
	cmpl	$2, %ecx
	je	.LBB0_167
# %bb.122:                              #   in Loop: Header=BB0_104 Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	vpbroadcastd	-16(%rax,%r11), %xmm6
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpinsrd	$1, %r14d, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %eax
	cmpl	%esi, %eax
	jl	.LBB0_124
# %bb.123:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%esi, %eax
.LBB0_124:                              #   in Loop: Header=BB0_104 Depth=1
	vpmovsxdq	%xmm6, %xmm7
	vmovmskpd	%xmm7, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_125
# %bb.126:                              #   in Loop: Header=BB0_104 Depth=1
	vmovd	%xmm6, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_127
.LBB0_128:                              #   in Loop: Header=BB0_104 Depth=1
	testb	$1, %r12b
	jne	.LBB0_130
.LBB0_129:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %r13d
.LBB0_130:                              #   in Loop: Header=BB0_104 Depth=1
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	imull	%ecx, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%eax, -16(%rdx,%r11)
	cmpl	$3, %ecx
	je	.LBB0_167
# %bb.131:                              #   in Loop: Header=BB0_104 Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	vpbroadcastd	-12(%rax,%r11), %xmm6
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpinsrd	$1, %ebx, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %eax
	cmpl	%esi, %eax
	jl	.LBB0_133
# %bb.132:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%esi, %eax
.LBB0_133:                              #   in Loop: Header=BB0_104 Depth=1
	vpmovsxdq	%xmm6, %xmm7
	vmovmskpd	%xmm7, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_134
# %bb.135:                              #   in Loop: Header=BB0_104 Depth=1
	vmovd	%xmm6, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_136
.LBB0_137:                              #   in Loop: Header=BB0_104 Depth=1
	testb	$1, %r12b
	jne	.LBB0_139
.LBB0_138:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %r13d
.LBB0_139:                              #   in Loop: Header=BB0_104 Depth=1
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	imull	%ecx, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%eax, -12(%rdx,%r11)
	cmpl	$4, %ecx
	je	.LBB0_167
# %bb.140:                              #   in Loop: Header=BB0_104 Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	vpbroadcastd	-8(%rax,%r11), %xmm6
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	movl	$4, %eax
	vpinsrd	$1, %eax, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %eax
	cmpl	%esi, %eax
	jl	.LBB0_142
# %bb.141:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%esi, %eax
.LBB0_142:                              #   in Loop: Header=BB0_104 Depth=1
	vpmovsxdq	%xmm6, %xmm7
	vmovmskpd	%xmm7, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_143
# %bb.144:                              #   in Loop: Header=BB0_104 Depth=1
	vmovd	%xmm6, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_145
.LBB0_146:                              #   in Loop: Header=BB0_104 Depth=1
	testb	$1, %r12b
	jne	.LBB0_148
.LBB0_147:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %r13d
.LBB0_148:                              #   in Loop: Header=BB0_104 Depth=1
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	imull	%ecx, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%eax, -8(%rdx,%r11)
	cmpl	$5, %ecx
	je	.LBB0_167
# %bb.149:                              #   in Loop: Header=BB0_104 Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	vpbroadcastd	-4(%rax,%r11), %xmm6
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	movl	$5, %eax
	vpinsrd	$1, %eax, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %eax
	cmpl	%esi, %eax
	jl	.LBB0_151
# %bb.150:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%esi, %eax
.LBB0_151:                              #   in Loop: Header=BB0_104 Depth=1
	vpmovsxdq	%xmm6, %xmm7
	vmovmskpd	%xmm7, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_152
# %bb.153:                              #   in Loop: Header=BB0_104 Depth=1
	vmovd	%xmm6, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_154
.LBB0_155:                              #   in Loop: Header=BB0_104 Depth=1
	testb	$1, %r12b
	jne	.LBB0_157
.LBB0_156:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %r13d
.LBB0_157:                              #   in Loop: Header=BB0_104 Depth=1
	movq	-72(%rsp), %rcx                 # 8-byte Reload
	imull	%ecx, %r13d
	addl	%edx, %r13d
	movslq	%r13d, %rax
	movl	(%rdi,%rax,4), %eax
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%eax, -4(%rdx,%r11)
	cmpl	$6, %ecx
	je	.LBB0_167
# %bb.158:                              #   in Loop: Header=BB0_104 Depth=1
	movq	-64(%rsp), %rax                 # 8-byte Reload
	vpbroadcastd	(%rax,%r11), %xmm6
	vpsrlvd	%xmm1, %xmm6, %xmm6
	vpand	%xmm2, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm3, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	movl	$6, %eax
	vpinsrd	$1, %eax, %xmm5, %xmm5
	vpaddd	%xmm6, %xmm5, %xmm5
	vpextrd	$1, %xmm5, %eax
	cmpl	%esi, %eax
	jl	.LBB0_160
# %bb.159:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%esi, %eax
.LBB0_160:                              #   in Loop: Header=BB0_104 Depth=1
	vpmovsxdq	%xmm5, %xmm6
	vmovmskpd	%xmm6, %r12d
	xorl	%r13d, %r13d
	movl	$0, %edx
	testb	$2, %r12b
	je	.LBB0_161
# %bb.162:                              #   in Loop: Header=BB0_104 Depth=1
	vmovd	%xmm5, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_163
.LBB0_164:                              #   in Loop: Header=BB0_104 Depth=1
	testb	$1, %r12b
	jne	.LBB0_166
	jmp	.LBB0_165
.LBB0_107:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %edx
	vmovd	%xmm6, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_110
.LBB0_109:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%r9d, %eax
	testb	$1, %r12b
	je	.LBB0_111
	jmp	.LBB0_112
.LBB0_116:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %edx
	vmovd	%xmm6, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_119
.LBB0_118:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%r9d, %eax
	testb	$1, %r12b
	je	.LBB0_120
	jmp	.LBB0_121
.LBB0_125:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %edx
	vmovd	%xmm6, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_128
.LBB0_127:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%r9d, %eax
	testb	$1, %r12b
	je	.LBB0_129
	jmp	.LBB0_130
.LBB0_134:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %edx
	vmovd	%xmm6, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_137
.LBB0_136:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%r9d, %eax
	testb	$1, %r12b
	je	.LBB0_138
	jmp	.LBB0_139
.LBB0_143:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %edx
	vmovd	%xmm6, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_146
.LBB0_145:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%r9d, %eax
	testb	$1, %r12b
	je	.LBB0_147
	jmp	.LBB0_148
.LBB0_152:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %edx
	vmovd	%xmm6, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_155
.LBB0_154:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%r9d, %eax
	testb	$1, %r12b
	je	.LBB0_156
	jmp	.LBB0_157
.LBB0_161:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %edx
	vmovd	%xmm5, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_164
.LBB0_163:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%r9d, %eax
	testb	$1, %r12b
	jne	.LBB0_166
.LBB0_165:                              #   in Loop: Header=BB0_104 Depth=1
	movl	%eax, %r13d
	jmp	.LBB0_166
.LBB0_496:                              #   in Loop: Header=BB0_434 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, (%rdx,%r11)
	.p2align	4, 0x90
.LBB0_497:                              #   in Loop: Header=BB0_434 Depth=1
	incq	%rbx
	addq	%r10, %r11
	cmpq	%rbx, %r8
	je	.LBB0_1322
.LBB0_434:                              # =>This Inner Loop Header: Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-23(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	movl	%r14d, %ecx
	cmpl	%eax, %r14d
	jge	.LBB0_435
# %bb.436:                              #   in Loop: Header=BB0_434 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	jns	.LBB0_437
.LBB0_438:                              #   in Loop: Header=BB0_434 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_439
.LBB0_440:                              #   in Loop: Header=BB0_434 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_442
.LBB0_441:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%ecx, %ebp
.LBB0_442:                              #   in Loop: Header=BB0_434 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -24(%rdx,%r11)
	cmpl	$1, %esi
	je	.LBB0_497
# %bb.443:                              #   in Loop: Header=BB0_434 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-19(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	1(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_444
# %bb.445:                              #   in Loop: Header=BB0_434 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jge	.LBB0_446
.LBB0_447:                              #   in Loop: Header=BB0_434 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_448
.LBB0_449:                              #   in Loop: Header=BB0_434 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_451
.LBB0_450:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%ecx, %ebp
.LBB0_451:                              #   in Loop: Header=BB0_434 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -20(%rdx,%r11)
	cmpl	$2, %esi
	je	.LBB0_497
# %bb.452:                              #   in Loop: Header=BB0_434 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-15(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	2(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_453
# %bb.454:                              #   in Loop: Header=BB0_434 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jge	.LBB0_455
.LBB0_456:                              #   in Loop: Header=BB0_434 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_457
.LBB0_458:                              #   in Loop: Header=BB0_434 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_460
.LBB0_459:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%ecx, %ebp
.LBB0_460:                              #   in Loop: Header=BB0_434 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -16(%rdx,%r11)
	cmpl	$3, %esi
	je	.LBB0_497
# %bb.461:                              #   in Loop: Header=BB0_434 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-11(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	3(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_462
# %bb.463:                              #   in Loop: Header=BB0_434 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-3, %r14d
	jge	.LBB0_464
.LBB0_465:                              #   in Loop: Header=BB0_434 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_466
.LBB0_467:                              #   in Loop: Header=BB0_434 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_469
.LBB0_468:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%ecx, %ebp
.LBB0_469:                              #   in Loop: Header=BB0_434 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -12(%rdx,%r11)
	cmpl	$4, %esi
	je	.LBB0_497
# %bb.470:                              #   in Loop: Header=BB0_434 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-7(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm3, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	4(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_471
# %bb.472:                              #   in Loop: Header=BB0_434 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-4, %r14d
	jge	.LBB0_473
.LBB0_474:                              #   in Loop: Header=BB0_434 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_475
.LBB0_476:                              #   in Loop: Header=BB0_434 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_478
.LBB0_477:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%ecx, %ebp
.LBB0_478:                              #   in Loop: Header=BB0_434 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -8(%rdx,%r11)
	cmpl	$5, %esi
	je	.LBB0_497
# %bb.479:                              #   in Loop: Header=BB0_434 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	-3(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm1, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	5(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_480
# %bb.481:                              #   in Loop: Header=BB0_434 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-5, %r14d
	jge	.LBB0_482
.LBB0_483:                              #   in Loop: Header=BB0_434 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_484
.LBB0_485:                              #   in Loop: Header=BB0_434 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_487
.LBB0_486:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%ecx, %ebp
.LBB0_487:                              #   in Loop: Header=BB0_434 Depth=1
	imull	%esi, %ebp
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movq	-56(%rsp), %rdx                 # 8-byte Reload
	movl	%ecx, -4(%rdx,%r11)
	cmpl	$6, %esi
	je	.LBB0_497
# %bb.488:                              #   in Loop: Header=BB0_434 Depth=1
	movq	-64(%rsp), %rcx                 # 8-byte Reload
	movzbl	1(%rcx,%r11), %ecx
	vcvtsi2ss	%ecx, %xmm1, %xmm0
	vdivss	%xmm1, %xmm0, %xmm0
	vaddss	%xmm2, %xmm0, %xmm0
	vmulss	%xmm5, %xmm0, %xmm0
	vcvttss2si	%xmm0, %r14d
	leal	6(%r14), %edx
	cmpl	%eax, %edx
	jge	.LBB0_489
# %bb.490:                              #   in Loop: Header=BB0_434 Depth=1
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-6, %r14d
	jge	.LBB0_491
.LBB0_492:                              #   in Loop: Header=BB0_434 Depth=1
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jge	.LBB0_493
.LBB0_494:                              #   in Loop: Header=BB0_434 Depth=1
	testl	%r14d, %r14d
	js	.LBB0_496
	jmp	.LBB0_495
.LBB0_435:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%eax, %ecx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r14d, %r14d
	js	.LBB0_438
.LBB0_437:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%ecx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_440
.LBB0_439:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_441
	jmp	.LBB0_442
.LBB0_444:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-1, %r14d
	jl	.LBB0_447
.LBB0_446:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_449
.LBB0_448:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_450
	jmp	.LBB0_451
.LBB0_453:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-2, %r14d
	jl	.LBB0_456
.LBB0_455:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_458
.LBB0_457:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_459
	jmp	.LBB0_460
.LBB0_462:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-3, %r14d
	jl	.LBB0_465
.LBB0_464:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_467
.LBB0_466:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_468
	jmp	.LBB0_469
.LBB0_471:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-4, %r14d
	jl	.LBB0_474
.LBB0_473:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_476
.LBB0_475:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_477
	jmp	.LBB0_478
.LBB0_480:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-5, %r14d
	jl	.LBB0_483
.LBB0_482:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_485
.LBB0_484:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	jns	.LBB0_486
	jmp	.LBB0_487
.LBB0_489:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%eax, %edx
	xorl	%ebp, %ebp
	movl	$0, %r15d
	cmpl	$-6, %r14d
	jl	.LBB0_492
.LBB0_491:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%edx, %r15d
	addl	%ebx, %r14d
	movl	%r14d, %ecx
	cmpl	%r9d, %r14d
	jl	.LBB0_494
.LBB0_493:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%r9d, %ecx
	testl	%r14d, %r14d
	js	.LBB0_496
.LBB0_495:                              #   in Loop: Header=BB0_434 Depth=1
	movl	%ecx, %ebp
	jmp	.LBB0_496
.LBB0_1322:
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
	vzeroupper
	retq
.Lfunc_end0:
	SIZE(SYM(ksvgDisplacementMapApplyAvx2))
	CFI_END
#if defined(__APPLE__)
	.section __TEXT,__const
#else
	.section	.rodata,"a",@progbits
#endif
	.p2align	2, 0x0
.LJTI0_0:
	.long	.LBB0_2-.LJTI0_0
	.long	.LBB0_332-.LJTI0_0
	.long	.LBB0_662-.LJTI0_0
	.long	.LBB0_992-.LJTI0_0
.LJTI0_1:
	.long	.LBB0_994-.LJTI0_1
	.long	.LBB0_1076-.LJTI0_1
	.long	.LBB0_1158-.LJTI0_1
	.long	.LBB0_1240-.LJTI0_1
.LJTI0_2:
	.long	.LBB0_664-.LJTI0_2
	.long	.LBB0_746-.LJTI0_2
	.long	.LBB0_828-.LJTI0_2
	.long	.LBB0_910-.LJTI0_2
.LJTI0_3:
	.long	.LBB0_334-.LJTI0_3
	.long	.LBB0_416-.LJTI0_3
	.long	.LBB0_498-.LJTI0_3
	.long	.LBB0_580-.LJTI0_3
.LJTI0_4:
	.long	.LBB0_4-.LJTI0_4
	.long	.LBB0_86-.LJTI0_4
	.long	.LBB0_168-.LJTI0_4
	.long	.LBB0_250-.LJTI0_4
                                        # -- End function
	.ident	"clang version 17.0.0 (https://github.com/swiftlang/llvm-project.git 10999b6d034fe318f3d56c83bddb6572593a8bb0)"
#if !defined(__APPLE__)
	.section	".note.GNU-stack","",@progbits
#endif
	.addrsig
