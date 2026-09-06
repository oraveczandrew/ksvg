/* x86-64 AVX-512F distant-light diffuse kernel. SysV/Android ABI.
 * Same signature as SSE2, count must be a positive multiple of 16.
 */
.text
.p2align 6
.globl ksvgLightingDistantDiffuseAvx512
.type ksvgLightingDistantDiffuseAvx512,@function
ksvgLightingDistantDiffuseAvx512:
    vbroadcastss %xmm0,%zmm6
    vbroadcastss %xmm1,%zmm7
    vbroadcastss %xmm2,%zmm8
    vbroadcastss %xmm3,%zmm9
    vbroadcastss %xmm4,%zmm10
    vbroadcastss %xmm5,%zmm11
    vbroadcastss .Ltwo(%rip),%zmm12
    vxorps %zmm13,%zmm13,%zmm13
    vbroadcastss .Lone(%rip),%zmm14
    mov %rcx,%r9
    test %r9d,%r9d
    jz .Ldone
.p2align 6
.Lloop:
    vmovups 0(%rdi),%zmm0
    vmovups 4(%rdi),%zmm1
    vmovups 8(%rdi),%zmm2
    vmovups 0(%rsi),%zmm3
    vmovups 4(%rsi),%zmm4
    vmovups 8(%rsi),%zmm5
    vmulps %zmm12,%zmm3,%zmm3
    vaddps %zmm0,%zmm3,%zmm3
    vmulps %zmm12,%zmm5,%zmm5
    vaddps %zmm2,%zmm5,%zmm5
    vmulps %zmm12,%zmm1,%zmm1
    vaddps %zmm0,%zmm1,%zmm1
    vaddps %zmm2,%zmm1,%zmm1
    vmovups 0(%rdx),%zmm15
    vaddps %zmm15,%zmm3,%zmm3
    vmovups 4(%rdx),%zmm0
    vmulps %zmm12,%zmm0,%zmm0
    vaddps %zmm15,%zmm0,%zmm0
    vmovups 8(%rdx),%zmm2
    vaddps %zmm2,%zmm5,%zmm5
    vaddps %zmm2,%zmm0,%zmm0
    vsubps %zmm3,%zmm5,%zmm5
    vdivps %zmm6,%zmm5,%zmm5
    vsubps %zmm1,%zmm0,%zmm0
    vdivps %zmm7,%zmm0,%zmm0
    vxorps %zmm3,%zmm3,%zmm3
    vsubps %zmm5,%zmm3,%zmm3
    vxorps %zmm1,%zmm1,%zmm1
    vsubps %zmm0,%zmm1,%zmm1
    vmulps %zmm3,%zmm3,%zmm5
    vmulps %zmm1,%zmm1,%zmm15
    vaddps %zmm15,%zmm5,%zmm5
    vaddps %zmm14,%zmm5,%zmm5
    vsqrtps %zmm5,%zmm5
    vdivps %zmm5,%zmm3,%zmm0
    vdivps %zmm5,%zmm1,%zmm2
    vdivps %zmm5,%zmm14,%zmm15
    vmulps %zmm9,%zmm0,%zmm0
    vmulps %zmm10,%zmm2,%zmm2
    vmulps %zmm11,%zmm15,%zmm15
    vaddps %zmm2,%zmm0,%zmm0
    vaddps %zmm15,%zmm0,%zmm0
    vmaxps %zmm13,%zmm0,%zmm0
    vmulps %zmm8,%zmm0,%zmm0
    vminps %zmm14,%zmm0,%zmm0
    vmovups %zmm0,(%r8)
    add $64,%rdi
    add $64,%rsi
    add $64,%rdx
    add $64,%r8
    sub $16,%r9
    jne .Lloop
.Ldone:
    ret
.size ksvgLightingDistantDiffuseAvx512,.-ksvgLightingDistantDiffuseAvx512
.section .rodata
.p2align 6
.Lone: .float 1.0
.Ltwo: .float 2.0
