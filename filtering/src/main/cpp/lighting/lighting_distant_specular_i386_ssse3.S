/*
 * Distant-light specular SSSE3 kernel for i386.
 */

#include "asm_macros.S"
#include "lighting_i386_ssse3_macros.S"

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
    ALPHA_EXTRACT 0, -84
    ALPHA_EXTRACT 4, -88
    ALPHA_EXTRACT 8, -92
    movl -36(%ebp),%eax
    ALPHA_EXTRACT 0, -96
    ALPHA_EXTRACT 8, -100
    movl -40(%ebp),%eax
    ALPHA_EXTRACT 0, -104
    ALPHA_EXTRACT 4, -108
    ALPHA_EXTRACT 8, -112

    movl -16(%ebp),%eax
    movss 36(%eax),%xmm7 # ss
    TO_FLOAT -84; TO_FLOAT -88; TO_FLOAT -92
    TO_FLOAT -96; TO_FLOAT -100
    TO_FLOAT -104; TO_FLOAT -108; TO_FLOAT -112

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
    CHAN_TO_INT 24, %eax, %eax, .Ldss_half
    movl -16(%ebp),%edx
    CHAN_TO_INT 28, %edx, %ecx, .Ldss_half
    CHAN_TO_INT 32, %edx, %edx, .Ldss_half

    cmpl $0,-4(%ebp) # useLinear
    je .Ldss_out
    L2S_GATHER %esi
.Ldss_out:
    PACK_MAX_ALPHA

    addl $4,-32(%ebp); addl $4,-36(%ebp); addl $4,-40(%ebp); addl $4,-8(%ebp)
    decl -12(%ebp)
    jmp .Ldss_loop_Ssse3

.Ldss_done_Ssse3:
    addl $384,%esp; popl %edi; popl %esi; popl %ebx; popl %ebp; ret
SIZE(SYM(ksvgLightingDistantSpecularRowSsse3))
SIZE(SYM(ksvgLightingDistantSpecularRowSsse3Linear))
