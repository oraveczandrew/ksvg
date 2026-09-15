#include "asm_macros.S"
RODATA
.p2align 4
.Lsp_zero: .long 0
.Lsp_one:  .long 0x3f800000
.Lsp_half: .long 0x3f000000
.Lsp_255:  .long 0x437f0000
.text
.macro L2S reg
 movl -24(%ebp),%ecx
 movzbl (%ecx,\reg),%ecx
 movl %ecx,\reg
.endm
.macro CLAMP reg
 cmpl $0,\reg; jge 1f; xorl \reg,\reg; jmp 2f
1: cmpl $255,\reg; jle 2f; movl $255,\reg
2:
.endm

.globl SYM(ksvgLightingSpotSpecularRowAvx2)
TYPE(SYM(ksvgLightingSpotSpecularRowAvx2), @function)
SYM(ksvgLightingSpotSpecularRowAvx2):
    xorl %eax,%eax
    jmp .Lsp_entry_Avx2
.globl SYM(ksvgLightingSpotSpecularRowAvx2Linear)
TYPE(SYM(ksvgLightingSpotSpecularRowAvx2Linear), @function)
SYM(ksvgLightingSpotSpecularRowAvx2Linear):
    movl $1,%eax
.Lsp_entry_Avx2:
    pushl %ebp
    movl %esp,%ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    subl $176,%esp
    LOAD_GOT(sp_avx)
    movl %eax,-4(%ebp)
    movl ksvg_linear_to_srgb_lut@GOT(%ebx), %eax; movl %eax,-24(%ebp)
    movl 8(%ebp), %eax; movl %eax,-32(%ebp)
    movl 12(%ebp), %eax; movl %eax,-36(%ebp)
    movl 16(%ebp), %eax; movl %eax,-40(%ebp)
    movl 20(%ebp), %eax; movl %eax,-8(%ebp)
    movl 24(%ebp), %eax; movl %eax,-12(%ebp)
    movl 28(%ebp), %eax; movl %eax,-16(%ebp)
    movl 32(%ebp), %eax; movl %eax,-20(%ebp)
.Lsp_loop_Avx2:
    cmpl $0,-12(%ebp); jle .Lsp_done_Avx2
movl -32(%ebp),%eax
movl 0(%eax),%eax
shrl $24,%eax
movl %eax,-84(%ebp)
movl -32(%ebp),%eax
movl 4(%eax),%eax
shrl $24,%eax
movl %eax,-88(%ebp)
movl -32(%ebp),%eax
movl 8(%eax),%eax
shrl $24,%eax
movl %eax,-92(%ebp)
movl -36(%ebp),%eax
movl 0(%eax),%eax
shrl $24,%eax
movl %eax,-96(%ebp)
movl -36(%ebp),%eax
movl 8(%eax),%eax
shrl $24,%eax
movl %eax,-100(%ebp)
movl -40(%ebp),%eax
movl 0(%eax),%eax
shrl $24,%eax
movl %eax,-104(%ebp)
movl -40(%ebp),%eax
movl 4(%eax),%eax
shrl $24,%eax
movl %eax,-108(%ebp)
movl -40(%ebp),%eax
movl 8(%eax),%eax
shrl $24,%eax
movl %eax,-112(%ebp)
movd -84(%ebp),%xmm0
cvtdq2ps %xmm0,%xmm0
movl -16(%ebp),%eax
mulss 36(%eax),%xmm0
movss %xmm0,-84(%ebp)
movd -88(%ebp),%xmm0
cvtdq2ps %xmm0,%xmm0
movl -16(%ebp),%eax
mulss 36(%eax),%xmm0
movss %xmm0,-88(%ebp)
movd -92(%ebp),%xmm0
cvtdq2ps %xmm0,%xmm0
movl -16(%ebp),%eax
mulss 36(%eax),%xmm0
movss %xmm0,-92(%ebp)
movd -96(%ebp),%xmm0
cvtdq2ps %xmm0,%xmm0
movl -16(%ebp),%eax
mulss 36(%eax),%xmm0
movss %xmm0,-96(%ebp)
movd -100(%ebp),%xmm0
cvtdq2ps %xmm0,%xmm0
movl -16(%ebp),%eax
mulss 36(%eax),%xmm0
movss %xmm0,-100(%ebp)
movd -104(%ebp),%xmm0
cvtdq2ps %xmm0,%xmm0
movl -16(%ebp),%eax
mulss 36(%eax),%xmm0
movss %xmm0,-104(%ebp)
movd -108(%ebp),%xmm0
cvtdq2ps %xmm0,%xmm0
movl -16(%ebp),%eax
mulss 36(%eax),%xmm0
movss %xmm0,-108(%ebp)
movd -112(%ebp),%xmm0
cvtdq2ps %xmm0,%xmm0
movl -16(%ebp),%eax
mulss 36(%eax),%xmm0
movss %xmm0,-112(%ebp)
movss -92(%ebp),%xmm0
addss -100(%ebp),%xmm0
addss -100(%ebp),%xmm0
addss -112(%ebp),%xmm0
movss -84(%ebp),%xmm1
addss -96(%ebp),%xmm1
addss -96(%ebp),%xmm1
addss -104(%ebp),%xmm1
subss %xmm1,%xmm0
movl -16(%ebp),%eax
divss 0(%eax),%xmm0
movss %xmm0,-116(%ebp)
movss -104(%ebp),%xmm0
addss -108(%ebp),%xmm0
addss -108(%ebp),%xmm0
addss -112(%ebp),%xmm0
movss -84(%ebp),%xmm1
addss -88(%ebp),%xmm1
addss -88(%ebp),%xmm1
addss -92(%ebp),%xmm1
subss %xmm1,%xmm0
movl -16(%ebp),%eax
divss 4(%eax),%xmm0
movss %xmm0,-120(%ebp)
movss -116(%ebp),%xmm0
xorps %xmm1,%xmm1
subss %xmm0,%xmm1
movss -120(%ebp),%xmm0
xorps %xmm2,%xmm2
subss %xmm0,%xmm2
movaps %xmm1,%xmm3
mulss %xmm1,%xmm3
movaps %xmm2,%xmm0
mulss %xmm2,%xmm0
addss %xmm0,%xmm3
addss .Lsp_one@GOTOFF(%ebx),%xmm3
sqrtss %xmm3,%xmm3
movss .Lsp_one@GOTOFF(%ebx),%xmm0
divss %xmm3,%xmm0
mulss %xmm0,%xmm1
mulss %xmm0,%xmm2
movss %xmm1,-124(%ebp)
movss %xmm2,-128(%ebp)
movss %xmm0,-132(%ebp)
movl -16(%ebp),%eax
movl -36(%ebp),%ecx
movl 4(%ecx),%ecx
shrl $24,%ecx
movd %ecx,%xmm0
cvtdq2ps %xmm0,%xmm0
mulss 36(%eax),%xmm0
movss %xmm0,-136(%ebp)
movl -16(%ebp),%eax
	movss 40(%eax),%xmm0
	movss %xmm0,-140(%ebp)
movl -16(%ebp),%eax
movss 12(%eax),%xmm0
subss -140(%ebp),%xmm0
movss %xmm0,-144(%ebp)
movss 16(%eax),%xmm0
subss 44(%eax),%xmm0
movss %xmm0,-148(%ebp)
movss 20(%eax),%xmm0
subss -136(%ebp),%xmm0
movss %xmm0,-152(%ebp)
movss -144(%ebp),%xmm0
mulss %xmm0,%xmm0
movss -148(%ebp),%xmm1
mulss %xmm1,%xmm1
addss %xmm1,%xmm0
movss -152(%ebp),%xmm1
mulss %xmm1,%xmm1
addss %xmm1,%xmm0
sqrtss %xmm0,%xmm0
movss .Lsp_zero@GOTOFF(%ebx),%xmm1
ucomiss %xmm1,%xmm0
je .Lsp_zeroL_0
movss .Lsp_one@GOTOFF(%ebx),%xmm1
divss %xmm0,%xmm1
movss -144(%ebp),%xmm0
    mulss %xmm1,%xmm0
    movss %xmm0,-144(%ebp)
movss -148(%ebp),%xmm0
    mulss %xmm1,%xmm0
    movss %xmm0,-148(%ebp)
movss -152(%ebp),%xmm0
    mulss %xmm1,%xmm0
    movss %xmm0,-152(%ebp)
jmp .Lsp_afterL_0
.Lsp_zeroL_0:
movl $0,-144(%ebp)
movl $0,-148(%ebp)
movl $0,-152(%ebp)
.Lsp_afterL_0:
movss -144(%ebp),%xmm0
xorps %xmm1,%xmm1
subss %xmm0,%xmm1
movl -16(%ebp),%eax
mulss 52(%eax),%xmm1
movss -148(%ebp),%xmm0
xorps %xmm2,%xmm2
subss %xmm0,%xmm2
mulss 56(%eax),%xmm2
addss %xmm2,%xmm1
movss -152(%ebp),%xmm0
xorps %xmm2,%xmm2
subss %xmm0,%xmm2
mulss 60(%eax),%xmm2
addss %xmm2,%xmm1
xorps %xmm0,%xmm0
maxss %xmm0,%xmm1
movss %xmm1,-156(%ebp)
movss 64(%eax),%xmm2
ucomiss %xmm2,%xmm2
jp .Lsp_noCut_0
ucomiss %xmm2,%xmm1
jb .Lsp_cut0_0
.Lsp_noCut_0:
jmp .Lsp_cutDone_0
.Lsp_cut0_0:
movl $0,-156(%ebp)
.Lsp_cutDone_0:
movss -144(%ebp),%xmm0
movss -148(%ebp),%xmm1
movss -152(%ebp),%xmm2
addss .Lsp_one@GOTOFF(%ebx),%xmm2
movaps %xmm0,%xmm3
mulss %xmm0,%xmm3
movaps %xmm1,%xmm4
mulss %xmm1,%xmm4
addss %xmm4,%xmm3
movaps %xmm2,%xmm4
mulss %xmm2,%xmm4
addss %xmm4,%xmm3
sqrtss %xmm3,%xmm3
movss .Lsp_one@GOTOFF(%ebx),%xmm4
divss %xmm3,%xmm4
mulss %xmm4,%xmm0
mulss %xmm4,%xmm1
mulss %xmm4,%xmm2
movss -124(%ebp),%xmm3
mulss %xmm0,%xmm3
movss -128(%ebp),%xmm4
mulss %xmm1,%xmm4
addss %xmm4,%xmm3
movss -132(%ebp),%xmm4
mulss %xmm2,%xmm4
addss %xmm4,%xmm3
xorps %xmm4,%xmm4
maxss %xmm4,%xmm3
movss %xmm3,-160(%ebp)
pushl -20(%ebp)
	pushl -160(%ebp)
	calll powf@PLT
	addl $8,%esp
	fstps -160(%ebp)
	movss -160(%ebp),%xmm0
	movl -16(%ebp),%eax
	mulss 8(%eax),%xmm0
	mulss -156(%ebp),%xmm0
xorps %xmm1,%xmm1
maxss %xmm1,%xmm0
movss .Lsp_one@GOTOFF(%ebx),%xmm1
minss %xmm1,%xmm0
movss %xmm0,-164(%ebp)
movl -16(%ebp),%eax
movss 24(%eax),%xmm0
mulss -164(%ebp),%xmm0
addss .Lsp_half@GOTOFF(%ebx),%xmm0; cvttss2si %xmm0,%eax
movl %eax,%ecx
movl -16(%ebp),%edx
movss 28(%edx),%xmm0
mulss -164(%ebp),%xmm0
addss .Lsp_half@GOTOFF(%ebx),%xmm0; cvttss2si %xmm0,%edx
movl -16(%ebp),%eax
movss 32(%eax),%xmm0
mulss -164(%ebp),%xmm0
addss .Lsp_half@GOTOFF(%ebx),%xmm0; cvttss2si %xmm0,%esi
    # Store channel integers before optional L2S.
    movl %ecx,-168(%ebp)
    movl %edx,-172(%ebp)
    movl %esi,-176(%ebp)
    cmpl $0,-4(%ebp)
    je .Lsp_nolinear_0
    movl -168(%ebp),%eax; CLAMP %eax; movl %eax,-168(%ebp); L2S %eax; movl %eax,-168(%ebp)
    movl -172(%ebp),%eax; CLAMP %eax; movl %eax,-172(%ebp); L2S %eax; movl %eax,-172(%ebp)
    movl -176(%ebp),%eax; CLAMP %eax; movl %eax,-176(%ebp); L2S %eax; movl %eax,-176(%ebp)
    jmp .Lsp_out_0
.Lsp_nolinear_0:
    movl -168(%ebp),%eax; CLAMP %eax; movl %eax,-168(%ebp)
    movl -172(%ebp),%eax; CLAMP %eax; movl %eax,-172(%ebp)
    movl -176(%ebp),%eax; CLAMP %eax; movl %eax,-176(%ebp)
.Lsp_out_0:
    movl -168(%ebp),%eax
    movl -172(%ebp),%ecx
    movl -176(%ebp),%edx
    movl %eax,%esi
    cmpl %ecx,%esi; cmovl %ecx,%esi
    cmpl %edx,%esi; cmovl %edx,%esi
    shll $16,%eax
    shll $8,%ecx
    shll $24,%esi
    orl %ecx,%eax; orl %edx,%eax; orl %esi,%eax
    movl -8(%ebp),%ecx
    movl %eax,0(%ecx)

    addl $4,-32(%ebp); addl $4,-36(%ebp); addl $4,-40(%ebp); addl $4,-8(%ebp)
    movl -16(%ebp),%eax; movss 40(%eax),%xmm0; addss 48(%eax),%xmm0; movss %xmm0,40(%eax)
    decl -12(%ebp)
    jmp .Lsp_loop_Avx2
.Lsp_done_Avx2:
    addl $176,%esp
    popl %edi; popl %esi; popl %ebx; popl %ebp
    ret
SIZE(SYM(ksvgLightingSpotSpecularRowAvx2))
SIZE(SYM(ksvgLightingSpotSpecularRowAvx2Linear))
