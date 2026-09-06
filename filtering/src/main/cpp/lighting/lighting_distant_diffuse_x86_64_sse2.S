/* x86-64 SSE2 distant-light diffuse kernel. SysV/Android ABI.
 * void ksvgLightingDistantDiffuseSse2(const float* ht,const float* hm,const float* hb,
 *   int count,float invDx,float invDy,float k,float lx,float ly,float lz,float* out);
 * count must be a positive multiple of 4; rows point at x-1.
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
.p2align 4
.globl SYM(ksvgLightingDistantDiffuseSse2)
TYPE(SYM(ksvgLightingDistantDiffuseSse2),@function)
SYM(ksvgLightingDistantDiffuseSse2):
    pshufd  $0, %xmm0, %xmm6        # invDx
    pshufd  $0, %xmm1, %xmm7        # invDy
    pshufd  $0, %xmm2, %xmm8        # k
    pshufd  $0, %xmm3, %xmm9        # lx
    pshufd  $0, %xmm4, %xmm10       # ly
    pshufd  $0, %xmm5, %xmm11       # lz
    movaps  .Ltwo(%rip), %xmm12
    movaps  .Lzero(%rip), %xmm13
    movaps  .Lone(%rip), %xmm14
    mov     %rcx, %r9
    test    %r9d, %r9d
    jz      .Ldone
.p2align 4
.Lloop:
    movups  0(%rdi), %xmm0         # lT
    movups  4(%rdi), %xmm1         # mT
    movups  8(%rdi), %xmm2         # rT
    movups  0(%rsi), %xmm3         # lM
    movups  4(%rsi), %xmm4         # mM
    movups  8(%rsi), %xmm5         # rM

    # sumL partial = lT + 2*lM
    mulps   %xmm12, %xmm3
    addps   %xmm0, %xmm3
    # sumR partial = rT + 2*rM
    mulps   %xmm12, %xmm5
    addps   %xmm2, %xmm5
    # sumT = lT + 2*mT + rT
    mulps   %xmm12, %xmm1
    addps   %xmm0, %xmm1
    addps   %xmm2, %xmm1

    # bottom: lB/mB/rB
    movups  0(%rdx), %xmm15
    addps   %xmm15, %xmm3          # sumL
    movups  4(%rdx), %xmm0         # mB (lT dead)
    mulps   %xmm12, %xmm0
    addps   %xmm15, %xmm0          # sumB
    movups  8(%rdx), %xmm2         # rB (rT dead)
    addps   %xmm2, %xmm5           # sumR
    addps   %xmm2, %xmm0           # sumB

    # dzdx / dzdy
    subps   %xmm3, %xmm5
    divps   %xmm6, %xmm5
    subps   %xmm1, %xmm0
    divps   %xmm7, %xmm0

    # nx=-dzdx, ny=-dzdy, normalize
    movaps  %xmm13, %xmm3
    subps   %xmm5, %xmm3           # nx
    movaps  %xmm13, %xmm1
    subps   %xmm0, %xmm1           # ny
    movaps  %xmm3, %xmm5
    mulps   %xmm3, %xmm5
    movaps  %xmm1, %xmm15
    mulps   %xmm1, %xmm15
    addps   %xmm15, %xmm5
    addps   %xmm14, %xmm5
    sqrtps  %xmm5, %xmm5            # nLen
    movaps  %xmm3, %xmm0
    divps   %xmm5, %xmm0            # nx
    movaps  %xmm1, %xmm2
    divps   %xmm5, %xmm2            # ny
    movaps  %xmm14, %xmm15
    divps   %xmm5, %xmm15           # nz

    # dot and clamp [0,1]
    mulps   %xmm9, %xmm0
    mulps   %xmm10, %xmm2
    mulps   %xmm11, %xmm15
    addps   %xmm2, %xmm0
    addps   %xmm15, %xmm0
    maxps   %xmm13, %xmm0
    mulps   %xmm8, %xmm0
    minps   %xmm14, %xmm0
    movups  %xmm0, (%r8)

    add     $16, %rdi
    add     $16, %rsi
    add     $16, %rdx
    add     $16, %r8
    sub     $4, %r9
    jne     .Lloop
.Ldone:
    ret
SIZE(SYM(ksvgLightingDistantDiffuseSse2))
#ifdef __APPLE__
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 4
.Lzero: .float 0.0,0.0,0.0,0.0
.Lone:  .float 1.0,1.0,1.0,1.0
.Ltwo:  .float 2.0,2.0,2.0,2.0
