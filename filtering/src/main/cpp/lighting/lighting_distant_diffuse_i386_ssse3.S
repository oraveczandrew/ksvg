/*
 * Distant-light diffuse SSSE3 kernel for i386.
 */

#include "asm_macros.S"
#include "lighting_i386_ssse3_macros.S"

	.text
POINT_LIT4
	.p2align 2
.Ldd_zero:  .long 0
.Ldd_one:   .long 0x3f800000
.Ldd_half:  .long 0x3f000000

.globl SYM(ksvgLightingDistantDiffuseRowSsse3)
TYPE(SYM(ksvgLightingDistantDiffuseRowSsse3), @function)
SYM(ksvgLightingDistantDiffuseRowSsse3):
    xorl %eax,%eax
    jmp .Ldd_entry_Ssse3
.globl SYM(ksvgLightingDistantDiffuseRowSsse3Linear)
TYPE(SYM(ksvgLightingDistantDiffuseRowSsse3Linear), @function)
SYM(ksvgLightingDistantDiffuseRowSsse3Linear):
    movl $1,%eax
.Ldd_entry_Ssse3:
    pushl %ebp
    movl %esp,%ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    subl $256,%esp
    LOAD_GOT(dd)
    movl %eax,-4(%ebp) # useLinear
    movl 8(%ebp), %eax; movl %eax,-32(%ebp) # srcT
    movl 12(%ebp), %eax; movl %eax,-36(%ebp) # srcM
    movl 16(%ebp), %eax; movl %eax,-40(%ebp) # srcB
    movl 20(%ebp), %eax; movl %eax,-8(%ebp)  # dst
    movl 24(%ebp), %eax; movl %eax,-12(%ebp) # count
    movl 28(%ebp), %eax; movl %eax,-16(%ebp) # params
    movl ksvg_linear_to_srgb_lut@GOT(%ebx), %eax; movl %eax,-24(%ebp)

.Ldd_loop_Ssse3:
    cmpl $0,-12(%ebp); jle .Ldd_done_Ssse3

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
    subss %xmm1,%xmm0; movl -16(%ebp),%eax; divss 0(%eax),%xmm0; # dzdx

    # dzdy
    movss -104(%ebp),%xmm1; addss -108(%ebp),%xmm1; addss -108(%ebp),%xmm1; addss -112(%ebp),%xmm1
    movss -84(%ebp),%xmm2; addss -88(%ebp),%xmm2; addss -88(%ebp),%xmm2; addss -92(%ebp),%xmm2
    subss %xmm2,%xmm1; divss 4(%eax),%xmm1; # dzdy

    # Normal N = normalize(-dzdx, -dzdy, 1)
    xorps %xmm2,%xmm2; subss %xmm0,%xmm2 # nx
    xorps %xmm3,%xmm3; subss %xmm1,%xmm3 # ny
    movaps %xmm2,%xmm4; mulss %xmm2,%xmm4; movaps %xmm3,%xmm5; mulss %xmm3,%xmm5; addss %xmm5,%xmm4
    addss .Ldd_one@GOTOFF(%ebx),%xmm4; sqrtss %xmm4,%xmm4; movss .Ldd_one@GOTOFF(%ebx),%xmm0; divss %xmm4,%xmm0 # invLen
    mulss %xmm0,%xmm2; mulss %xmm0,%xmm3; # nx, ny

    # intensity = k * max(0, N . L)
    # L = (lx, ly, lz) normalized.
    movl -16(%ebp),%eax
    mulss 12(%eax),%xmm2 # nx*lx
    mulss 16(%eax),%xmm3; addss %xmm3,%xmm2
    mulss 20(%eax),%xmm0; addss %xmm0,%xmm2 # nz=invLen, + nz*lz
    xorps %xmm0,%xmm0; maxss %xmm0,%xmm2; mulss 8(%eax),%xmm2; minss .Ldd_one@GOTOFF(%ebx),%xmm2
    movaps %xmm2,%xmm0

    # R,G,B
    CHAN_TO_INT 24, %eax, %eax, .Ldd_half
    movl -16(%ebp),%edx
    CHAN_TO_INT 28, %edx, %ecx, .Ldd_half
    CHAN_TO_INT 32, %edx, %edx, .Ldd_half

    cmpl $0,-4(%ebp) # useLinear
    je .Ldd_out
    L2S_GATHER %esi
.Ldd_out:
    PACK_FORCE_ALPHA

    addl $4,-32(%ebp); addl $4,-36(%ebp); addl $4,-40(%ebp); addl $4,-8(%ebp)
    decl -12(%ebp)
    jmp .Ldd_loop_Ssse3

.Ldd_done_Ssse3:
    addl $256,%esp; popl %edi; popl %esi; popl %ebx; popl %ebp; ret
SIZE(SYM(ksvgLightingDistantDiffuseRowSsse3))
SIZE(SYM(ksvgLightingDistantDiffuseRowSsse3Linear))
