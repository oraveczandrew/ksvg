/*
 * Distant-light specular SSSE3 kernel for i386.
 */

#include "asm_macros.S"

	.text
POINT_LIT4
	.p2align 2
.Ldss_zero:  .long 0
.Ldss_one:   .long 0x3f800000
.Ldss_half:  .long 0x3f000000

.globl SYM(ksvgLightingDistantSpecularRowSsse3)
TYPE(SYM(ksvgLightingDistantSpecularRowSsse3), @function)
SYM(ksvgLightingDistantSpecularRowSsse3):
    xorl %eax,%eax
    jmp .Ldss_entry_Ssse3
.globl SYM(ksvgLightingDistantSpecularRowSsse3Linear)
TYPE(SYM(ksvgLightingDistantSpecularRowSsse3Linear), @function)
SYM(ksvgLightingDistantSpecularRowSsse3Linear):
    movl $1,%eax
.Ldss_entry_Ssse3:
    pushl %ebp
    movl %esp,%ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    subl $384,%esp
    LOAD_GOT(dss)
    movl %eax,-4(%ebp) # useLinear
    movl 8(%ebp), %eax; movl %eax,-32(%ebp) # srcT
    movl 12(%ebp), %eax; movl %eax,-36(%ebp) # srcM
    movl 16(%ebp), %eax; movl %eax,-40(%ebp) # srcB
    movl 20(%ebp), %eax; movl %eax,-8(%ebp)  # dst
    movl 24(%ebp), %eax; movl %eax,-12(%ebp) # count
    movl 28(%ebp), %eax; movl %eax,-16(%ebp) # params
    movl 32(%ebp), %eax; movl %eax,-20(%ebp) # exponent
    movl ksvg_linear_to_srgb_lut@GOT(%ebx), %eax; movl %eax,-24(%ebp)

    # Distant light L = (lx, ly, lz) normalized.
    # params[0], [1] are az, el in deg.
    # Already pre-calculated by lighting.cpp? No, PointLightingParams doesn't have it.
    # Wait, DistantLightingParams has it.
    # But wait! lighting.cpp passes PointLightingParams for ALL light types in some paths?
    # NO! let's check distant diffuse entry point.

    # Actually, for Distant light, the caller passes LX, LY, LZ normalized in params.
    # For Distant Specular, the layout is (invDx, invDy, k, lx, ly, lz, lr, lg, lb, ss).
    # invDx=0, invDy=4, k=8, lx=12, ly=16, lz=20, lr=24, lg=28, lb=32, ss=36.

    # Pre-calculate Half vector H = normalize(L + (0,0,1))
    movl -16(%ebp), %eax
    movss 12(%eax), %xmm3 # lx
    movss 16(%eax), %xmm4 # ly
    movss 20(%eax), %xmm5; addss .Ldss_one@GOTOFF(%ebx), %xmm5 # lz + 1
    movaps %xmm3,%xmm6; mulss %xmm3,%xmm6; movaps %xmm4,%xmm0; mulss %xmm4,%xmm0; addss %xmm0,%xmm6; movaps %xmm5,%xmm0; mulss %xmm5,%xmm0; addss %xmm0,%xmm6
    sqrtss %xmm6,%xmm6; movss .Ldss_one@GOTOFF(%ebx), %xmm0; divss %xmm6, %xmm0
    mulss %xmm0,%xmm3; mulss %xmm0,%xmm4; mulss %xmm0,%xmm5
    movss %xmm3,-140(%ebp); movss %xmm4,-144(%ebp); movss %xmm5,-148(%ebp) # H

.Ldss_loop_Ssse3:
    cmpl $0,-12(%ebp); jle .Ldss_done_Ssse3

    movl -32(%ebp),%eax
    movl 0(%eax),%ecx; shrl $24,%ecx; movl %ecx,-84(%ebp) # tl
    movl 4(%eax),%ecx; shrl $24,%ecx; movl %ecx,-88(%ebp) # tm
    movl 8(%eax),%ecx; shrl $24,%ecx; movl %ecx,-92(%ebp) # tr
    movl -36(%ebp),%eax
    movl 0(%eax),%ecx; shrl $24,%ecx; movl %ecx,-96(%ebp) # ml
    movl 8(%eax),%ecx; shrl $24,%ecx; movl %ecx,-100(%ebp) # mr
    movl -40(%ebp),%eax
    movl 0(%eax),%ecx; shrl $24,%ecx; movl %ecx,-104(%ebp) # bl
    movl 4(%eax),%ecx; shrl $24,%ecx; movl %ecx,-108(%ebp) # bm
    movl 8(%eax),%ecx; shrl $24,%ecx; movl %ecx,-112(%ebp) # br

    movl -16(%ebp),%eax
    movss 36(%eax),%xmm7 # ss
    .macro DSS_TO_FLOAT stack_off
    movd \stack_off(%ebp),%xmm0; cvtdq2ps %xmm0,%xmm0; mulss %xmm7,%xmm0; movss %xmm0,\stack_off(%ebp)
    .endm
    DSS_TO_FLOAT -84; DSS_TO_FLOAT -88; DSS_TO_FLOAT -92
    DSS_TO_FLOAT -96; DSS_TO_FLOAT -100
    DSS_TO_FLOAT -104; DSS_TO_FLOAT -108; DSS_TO_FLOAT -112

    # dzdx
    movss -92(%ebp),%xmm0; addss -100(%ebp),%xmm0; addss -100(%ebp),%xmm0; addss -112(%ebp),%xmm0
    movss -84(%ebp),%xmm1; addss -96(%ebp),%xmm1; addss -96(%ebp),%xmm1; addss -104(%ebp),%xmm1
    subss %xmm1,%xmm0; movl -16(%ebp),%eax; divss 0(%eax),%xmm0; movss %xmm0,-116(%ebp)

    # dzdy
    movss -104(%ebp),%xmm0; addss -108(%ebp),%xmm0; addss -108(%ebp),%xmm0; addss -112(%ebp),%xmm0
    movss -84(%ebp),%xmm1; addss -88(%ebp),%xmm1; addss -88(%ebp),%xmm1; addss -92(%ebp),%xmm1
    subss %xmm1,%xmm0; divss 4(%eax),%xmm0; movss %xmm0,-120(%ebp)

    # Normal N
    movss -116(%ebp),%xmm0; xorps %xmm1,%xmm1; subss %xmm0,%xmm1 # nx
    movss -120(%ebp),%xmm0; xorps %xmm2,%xmm2; subss %xmm0,%xmm2 # ny
    movaps %xmm1,%xmm3; mulss %xmm1,%xmm3; movaps %xmm2,%xmm0; mulss %xmm2,%xmm0; addss %xmm0,%xmm3
    addss .Ldss_one@GOTOFF(%ebx),%xmm3; sqrtss %xmm3,%xmm3; movss .Ldss_one@GOTOFF(%ebx),%xmm0; divss %xmm3,%xmm0
    mulss %xmm0,%xmm1; mulss %xmm0,%xmm2; # nx, ny

    # ndoth = max(0, N . H)
    mulss -140(%ebp),%xmm1; mulss -144(%ebp),%xmm2; addss %xmm2,%xmm1; mulss -148(%ebp),%xmm0; addss %xmm0,%xmm1
    xorps %xmm0,%xmm0; maxss %xmm0,%xmm1

    # p = powf(ndoth, exponent)
    pushl -20(%ebp); subl $4,%esp; movss %xmm1,(%esp); calll powf@PLT; addl $8,%esp
    fstps -160(%ebp); movss -160(%ebp),%xmm0

    # intensity = k * p
    movl -16(%ebp),%eax; mulss 8(%eax),%xmm0
    xorps %xmm1,%xmm1; maxss %xmm1,%xmm0; minss .Ldss_one@GOTOFF(%ebx),%xmm0

    # R,G,B
    movss 24(%eax),%xmm1; mulss %xmm0,%xmm1; addss .Ldss_half@GOTOFF(%ebx),%xmm1; cvttss2si %xmm1,%eax
    movl -16(%ebp),%edx
    movss 28(%edx),%xmm1; mulss %xmm0,%xmm1; addss .Ldss_half@GOTOFF(%ebx),%xmm1; cvttss2si %xmm1,%ecx
    movss 32(%edx),%xmm1; mulss %xmm0,%xmm1; addss .Ldss_half@GOTOFF(%ebx),%xmm1; cvttss2si %xmm1,%edx

    cmpl $0,-4(%ebp) # useLinear
    je .Ldss_out
    movl -24(%ebp),%esi # lut
    movzbl (%esi,%eax),%eax; movzbl (%esi,%ecx),%ecx; movzbl (%esi,%edx),%edx
.Ldss_out:
    shll $16,%eax; shll $8,%ecx; orl %ecx,%eax; orl %edx,%eax
    movl %eax,%esi; cmpl %ecx,%esi; cmovl %ecx,%esi; cmpl %edx,%esi; cmovl %edx,%esi
    shll $24,%esi; orl %esi,%eax
    movl -8(%ebp),%ecx; movl %eax,(%ecx)

    addl $4,-32(%ebp); addl $4,-36(%ebp); addl $4,-40(%ebp); addl $4,-8(%ebp)
    decl -12(%ebp)
    jmp .Ldss_loop_Ssse3

.Ldss_done_Ssse3:
    addl $384,%esp; popl %edi; popl %esi; popl %ebx; popl %ebp; ret
SIZE(SYM(ksvgLightingDistantSpecularRowSsse3))
SIZE(SYM(ksvgLightingDistantSpecularRowSsse3Linear))
