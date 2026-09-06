/* x86-64 AVX2 distant-light diffuse kernel. SysV/Android ABI.
 * Same signature as SSE2, count must be a positive multiple of 8.
 */
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
.p2align 5
.globl SYM(ksvgLightingDistantDiffuseAvx2)
TYPE(SYM(ksvgLightingDistantDiffuseAvx2),@function)
SYM(ksvgLightingDistantDiffuseAvx2):
    vbroadcastss %xmm0, %ymm6
    vbroadcastss %xmm1, %ymm7
    vbroadcastss %xmm2, %ymm8
    vbroadcastss %xmm3, %ymm9
    vbroadcastss %xmm4, %ymm10
    vbroadcastss %xmm5, %ymm11
    vbroadcastss .Ltwo(%rip), %ymm12
    vxorps %ymm13, %ymm13, %ymm13
    vbroadcastss .Lone(%rip), %ymm14
    mov %rcx, %r9
    test %r9d, %r9d
    jz .Ldone
.p2align 5
.Lloop:
    vmovups 0(%rdi), %ymm0
    vmovups 4(%rdi), %ymm1
    vmovups 8(%rdi), %ymm2
    vmovups 0(%rsi), %ymm3
    vmovups 4(%rsi), %ymm4
    vmovups 8(%rsi), %ymm5
    vmulps %ymm12,%ymm3,%ymm3
    vaddps %ymm0,%ymm3,%ymm3
    vmulps %ymm12,%ymm5,%ymm5
    vaddps %ymm2,%ymm5,%ymm5
    vmulps %ymm12,%ymm1,%ymm1
    vaddps %ymm0,%ymm1,%ymm1
    vaddps %ymm2,%ymm1,%ymm1
    vmovups 0(%rdx), %ymm15
    vaddps %ymm15,%ymm3,%ymm3
    vmovups 4(%rdx), %ymm0
    vmulps %ymm12,%ymm0,%ymm0
    vaddps %ymm15,%ymm0,%ymm0
    vmovups 8(%rdx), %ymm2
    vaddps %ymm2,%ymm5,%ymm5
    vaddps %ymm2,%ymm0,%ymm0
    vsubps %ymm3,%ymm5,%ymm5
    vdivps %ymm6,%ymm5,%ymm5
    vsubps %ymm1,%ymm0,%ymm0
    vdivps %ymm7,%ymm0,%ymm0
    vxorps %ymm3,%ymm3,%ymm3
    vsubps %ymm5,%ymm3,%ymm3
    vxorps %ymm1,%ymm1,%ymm1
    vsubps %ymm0,%ymm1,%ymm1
    vmulps %ymm3,%ymm3,%ymm5
    vmulps %ymm1,%ymm1,%ymm15
    vaddps %ymm15,%ymm5,%ymm5
    vaddps %ymm14,%ymm5,%ymm5
    vsqrtps %ymm5,%ymm5
    vdivps %ymm5,%ymm3,%ymm0
    vdivps %ymm5,%ymm1,%ymm2
    vdivps %ymm5,%ymm14,%ymm15
    vmulps %ymm9,%ymm0,%ymm0
    vmulps %ymm10,%ymm2,%ymm2
    vmulps %ymm11,%ymm15,%ymm15
    vaddps %ymm2,%ymm0,%ymm0
    vaddps %ymm15,%ymm0,%ymm0
    vmaxps %ymm13,%ymm0,%ymm0
    vmulps %ymm8,%ymm0,%ymm0
    vminps %ymm14,%ymm0,%ymm0
    vmovups %ymm0,(%r8)
    add $32,%rdi
    add $32,%rsi
    add $32,%rdx
    add $32,%r8
    sub $8,%r9
    jne .Lloop
    vzeroupper
.Ldone:
    ret
SIZE(SYM(ksvgLightingDistantDiffuseAvx2))
#ifdef __APPLE__
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 5
.Lone: .float 1.0
.Ltwo: .float 2.0
