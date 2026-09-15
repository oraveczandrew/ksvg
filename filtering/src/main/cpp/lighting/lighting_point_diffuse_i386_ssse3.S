/*
 * Point-light diffuse SSSE3 kernel for i386.
 *
 * void ksvgLightingPointDiffuseRowSsse3(
 *   const jint* srcT, const jint* srcM, const jint* srcB,
 *   jint* dst, jint count, const PointLightingParams* params)
 */

#include "asm_macros.S"

	.text
POINT_LIT4
	.p2align 2
.Lpd_zero:  .long 0
.Lpd_one:   .long 0x3f800000
.Lpd_half:  .long 0x3f000000

.globl SYM(ksvgLightingPointDiffuseRowSsse3)
TYPE(SYM(ksvgLightingPointDiffuseRowSsse3), @function)
SYM(ksvgLightingPointDiffuseRowSsse3):
    xorl %eax,%eax
    jmp .Lpd_entry_Ssse3
.globl SYM(ksvgLightingPointDiffuseRowSsse3Linear)
TYPE(SYM(ksvgLightingPointDiffuseRowSsse3Linear), @function)
SYM(ksvgLightingPointDiffuseRowSsse3Linear):
    movl $1,%eax
.Lpd_entry_Ssse3:
    pushl %ebp
    movl %esp,%ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    subl $256,%esp
    LOAD_GOT(pd)
    movl %eax,-4(%ebp) # useLinear
    movl 8(%ebp), %eax; movl %eax,-32(%ebp) # srcT
    movl 12(%ebp), %eax; movl %eax,-36(%ebp) # srcM
    movl 16(%ebp), %eax; movl %eax,-40(%ebp) # srcB
    movl 20(%ebp), %eax; movl %eax,-8(%ebp)  # dst
    movl 24(%ebp), %eax; movl %eax,-12(%ebp) # count
    movl 28(%ebp), %eax; movl %eax,-16(%ebp) # params
    movl ksvg_linear_to_srgb_lut@GOT(%ebx), %eax; movl %eax,-24(%ebp)

.Lpd_loop_Ssse3:
    cmpl $0,-12(%ebp); jle .Lpd_done_Ssse3

    movl -32(%ebp),%eax
    movl 0(%eax),%ecx; shrl $24,%ecx; movl %ecx,-84(%ebp) # tl
    movl 4(%eax),%ecx; shrl $24,%ecx; movl %ecx,-88(%ebp) # tm
    movl 8(%eax),%ecx; shrl $24,%ecx; movl %ecx,-92(%ebp) # tr

    movl -36(%ebp),%eax
    movl 0(%eax),%ecx; shrl $24,%ecx; movl %ecx,-96(%ebp) # ml
    movl 4(%eax),%ecx; shrl $24,%ecx; movl %ecx,-136(%ebp) # mm (surfaceZ)
    movl 8(%eax),%ecx; shrl $24,%ecx; movl %ecx,-100(%ebp) # mr

    movl -40(%ebp),%eax
    movl 0(%eax),%ecx; shrl $24,%ecx; movl %ecx,-104(%ebp) # bl
    movl 4(%eax),%ecx; shrl $24,%ecx; movl %ecx,-108(%ebp) # bm
    movl 8(%eax),%ecx; shrl $24,%ecx; movl %ecx,-112(%ebp) # br

    movl -16(%ebp),%eax
    movss 36(%eax),%xmm7 # ss

    .macro PD_TO_FLOAT stack_off
    movd \stack_off(%ebp),%xmm0
    cvtdq2ps %xmm0,%xmm0
    mulss %xmm7,%xmm0
    movss %xmm0,\stack_off(%ebp)
    .endm

    PD_TO_FLOAT -84; PD_TO_FLOAT -88; PD_TO_FLOAT -92
    PD_TO_FLOAT -96; PD_TO_FLOAT -136; PD_TO_FLOAT -100
    PD_TO_FLOAT -104; PD_TO_FLOAT -108; PD_TO_FLOAT -112

    # dzdx = (tr + 2*mr + br) - (tl + 2*ml + bl)
    movss -92(%ebp),%xmm0
    addss -100(%ebp),%xmm0; addss -100(%ebp),%xmm0; addss -112(%ebp),%xmm0
    movss -84(%ebp),%xmm1
    addss -96(%ebp),%xmm1; addss -96(%ebp),%xmm1; addss -104(%ebp),%xmm1
    subss %xmm1,%xmm0
    movl -16(%ebp),%eax
    divss 0(%eax),%xmm0
    movss %xmm0,-116(%ebp)

    # dzdy = (bl + 2*bm + br) - (tl + 2*tm + tr)
    movss -104(%ebp),%xmm0
    addss -108(%ebp),%xmm0; addss -108(%ebp),%xmm0; addss -112(%ebp),%xmm0
    movss -84(%ebp),%xmm1
    addss -88(%ebp),%xmm1; addss -88(%ebp),%xmm1; addss -92(%ebp),%xmm1
    subss %xmm1,%xmm0
    divss 4(%eax),%xmm0
    movss %xmm0,-120(%ebp)

    # Normal N = normalize(-dzdx, -dzdy, 1)
    movss -116(%ebp),%xmm0
    xorps %xmm1,%xmm1; subss %xmm0,%xmm1 # nx
    movss -120(%ebp),%xmm0
    xorps %xmm2,%xmm2; subss %xmm0,%xmm2 # ny
    movaps %xmm1,%xmm3; mulss %xmm1,%xmm3
    movaps %xmm2,%xmm0; mulss %xmm2,%xmm0
    addss %xmm0,%xmm3
    addss .Lpd_one@GOTOFF(%ebx),%xmm3
    sqrtss %xmm3,%xmm3
    movss .Lpd_one@GOTOFF(%ebx),%xmm0; divss %xmm3,%xmm0
    mulss %xmm0,%xmm1; mulss %xmm0,%xmm2
    movss %xmm1,-124(%ebp); movss %xmm2,-128(%ebp); movss %xmm0,-132(%ebp) # nz

    # Point light L = normalize(lx - ux, ly - uy, lz - surfaceZ)
    movl -16(%ebp),%eax
    movss 40(%eax),%xmm0 # ux
    movss 44(%eax),%xmm1 # uy
    movss -136(%ebp),%xmm2 # surfaceZ
    movss 12(%eax),%xmm3; subss %xmm0,%xmm3 # lx_raw
    movss 16(%eax),%xmm4; subss %xmm1,%xmm4 # ly_raw
    movss 20(%eax),%xmm5; subss %xmm2,%xmm5 # lz_raw
    movaps %xmm3,%xmm6; mulss %xmm3,%xmm6
    movaps %xmm4,%xmm0; mulss %xmm4,%xmm0; addss %xmm0,%xmm6
    movaps %xmm5,%xmm0; mulss %xmm5,%xmm0; addss %xmm0,%xmm6
    sqrtss %xmm6,%xmm6
    movss .Lpd_zero@GOTOFF(%ebx),%xmm0
    ucomiss %xmm0,%xmm6
    je .Lpd_l_zero
    movss .Lpd_one@GOTOFF(%ebx),%xmm0; divss %xmm6,%xmm0
    mulss %xmm0,%xmm3; mulss %xmm0,%xmm4; mulss %xmm0,%xmm5
    jmp .Lpd_l_done
.Lpd_l_zero:
    xorps %xmm3,%xmm3; xorps %xmm4,%xmm4; xorps %xmm5,%xmm5
.Lpd_l_done:

    # intensity = k * max(0, N . L)
    mulss -124(%ebp),%xmm3
    mulss -128(%ebp),%xmm4; addss %xmm4,%xmm3
    mulss -132(%ebp),%xmm5; addss %xmm5,%xmm3
    xorps %xmm0,%xmm0; maxss %xmm0,%xmm3
    mulss 8(%eax),%xmm3 # k * dot
    minss .Lpd_one@GOTOFF(%ebx),%xmm3
    movaps %xmm3,%xmm0

    # R,G,B
    movss 24(%eax),%xmm1; mulss %xmm0,%xmm1; addss .Lpd_half@GOTOFF(%ebx),%xmm1; cvttss2si %xmm1,%eax
    movl -16(%ebp),%edx
    movss 28(%edx),%xmm1; mulss %xmm0,%xmm1; addss .Lpd_half@GOTOFF(%ebx),%xmm1; cvttss2si %xmm1,%ecx
    movss 32(%edx),%xmm1; mulss %xmm0,%xmm1; addss .Lpd_half@GOTOFF(%ebx),%xmm1; cvttss2si %xmm1,%edx

    cmpl $0,-4(%ebp) # useLinear
    je .Lpd_out
    movl -24(%ebp),%esi # lut
    movzbl (%esi,%eax),%eax
    movzbl (%esi,%ecx),%ecx
    movzbl (%esi,%edx),%edx
.Lpd_out:
    shll $16,%eax; shll $8,%ecx; orl %ecx,%eax; orl %edx,%eax
    orl $-16777216, %eax
    movl -8(%ebp),%ecx; movl %eax,(%ecx)

    addl $4,-32(%ebp); addl $4,-36(%ebp); addl $4,-40(%ebp); addl $4,-8(%ebp)
    movl -16(%ebp),%eax
    movss 40(%eax),%xmm0; addss 48(%eax),%xmm0; movss %xmm0,40(%eax)
    decl -12(%ebp)
    jmp .Lpd_loop_Ssse3

.Lpd_done_Ssse3:
    addl $256,%esp; popl %edi; popl %esi; popl %ebx; popl %ebp; ret

SIZE(SYM(ksvgLightingPointDiffuseRowSsse3))
SIZE(SYM(ksvgLightingPointDiffuseRowSsse3Linear))
