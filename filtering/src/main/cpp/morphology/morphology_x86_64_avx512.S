/*
 * x86-64 / AVX-512BW implementation of morphology kernels.
 * ABI: SysV x86-64 / x86_64 Android.
 * Row:   rdi=src,rsi=dst,edx=width,ecx=radiusX,r8d=radiusY,r9d=erode,[rsp+8]=y,[rsp+16]=xStart,[rsp+24]=xEnd,[rsp+32]=scratch
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
.p2align 6

/* Row kernel: same two-stage algorithm as AVX2, 64 bytes = 16 pixels. */
.globl SYM(ksvgMorphologyApplyRowAvx512)
TYPE(SYM(ksvgMorphologyApplyRowAvx512), @function)
SYM(ksvgMorphologyApplyRowAvx512):
    push %rbx; push %rbp; push %r12; push %r13; push %r14; push %r15
    mov 56(%rsp),%r15d          # y
    mov 64(%rsp),%ebx           # xStart
    mov 80(%rsp),%r10           # scratch
    mov %r9d,%ebp               # erode
    mov %edx,%r13d              # width
    mov %ecx,%r14d              # radiusX
    mov %ecx,%r12d              # saved radiusX
    lea 1(%r8d,%r8d),%r9d       # rowCount
    mov %ebx,%r11d; sub %r14d,%r11d # colLo
    mov %r15d,%edx; sub %r8d,%edx
    movslq %edx,%rdx; movslq %r13d,%rax; imul %rax,%rdx
    movslq %r11d,%rax; add %rax,%rdx; lea (%rdi,%rdx,4),%r11
    mov 72(%rsp),%ecx; sub %ebx,%ecx
    lea (%rcx,%r14,2),%rax; mov %eax,%ecx
    mov %ecx,%edx; and $15,%edx; mov %edx,%r8d; shr $4,%ecx
    mov %rsi,%rdi
    movslq %r13d,%r14; shl $2,%r14
    test %ebp,%ebp; jne .Lrv_e
    mov %r10,%rsi
.Lrv_dg:
    test %ecx,%ecx; jz .Lrv_dt
    vpxorq %zmm0,%zmm0,%zmm0
    mov %r11,%rax; mov %r9d,%edx
.Lrv_dr:
    vmovdqu32 (%rax),%zmm1; vpmaxub %zmm1,%zmm0,%zmm0
    add %r14,%rax; dec %edx; jnz .Lrv_dr
    vmovdqu32 %zmm0,(%rsi); add $64,%rsi; add $64,%r11; dec %ecx; jmp .Lrv_dg
.Lrv_dt:
    test %r8d,%r8d; jz .Lrv_dh
.Lrv_dtc:
    vpxorq %zmm0,%zmm0,%zmm0; mov %r11,%rax; mov %r9d,%ecx
.Lrv_dtr:
    mov (%rax),%edx; vmovd %edx,%xmm1; vpbroadcastd %xmm1,%zmm1
    vpmaxub %zmm1,%zmm0,%zmm0; add %r14,%rax; dec %ecx; jnz .Lrv_dtr
    vmovd %xmm0,%edx; mov %edx,(%rsi); add $4,%rsi; add $4,%r11; dec %r8d; jnz .Lrv_dtc
    jmp .Lrv_dh
.Lrv_e:
    mov %r10,%rsi
.Lrv_eg:
    test %ecx,%ecx; jz .Lrv_et
    mov $-1,%eax; kmovd %eax,%k1; vpmovm2d %k1,%zmm0
    mov %r11,%rax; mov %r9d,%edx
.Lrv_er:
    vmovdqu32 (%rax),%zmm1; vpminub %zmm1,%zmm0,%zmm0
    add %r14,%rax; dec %edx; jnz .Lrv_er
    vmovdqu32 %zmm0,(%rsi); add $64,%rsi; add $64,%r11; dec %ecx; jmp .Lrv_eg
.Lrv_et:
    test %r8d,%r8d; jz .Lrv_eh
.Lrv_etc:
    mov $-1,%eax; kmovd %eax,%k1; vpmovm2d %k1,%zmm0; mov %r11,%rax; mov %r9d,%ecx
.Lrv_etr:
    mov (%rax),%edx; vmovd %edx,%xmm1; vpbroadcastd %xmm1,%zmm1
    vpminub %zmm1,%zmm0,%zmm0; add %r14,%rax; dec %ecx; jnz .Lrv_etr
    vmovd %xmm0,%edx; mov %edx,(%rsi); add $4,%rsi; add $4,%r11; dec %r8d; jnz .Lrv_etc

.Lrv_eh:
    lea 1(%r12d,%r12d),%eax; mov %eax,%ecx; shr $4,%ecx; and $15,%eax; mov %eax,%r9d
    mov 72(%rsp),%r12d; sub %ebx,%r12d
    mov 56(%rsp),%r15d; movslq %r15d,%rax; movslq %r13d,%rdx; imul %rdx,%rax; movslq %ebx,%rdx; add %rdx,%rax; lea (%rdi,%rax,4),%rdi
    mov %r10,%r11
.Lrv_ehp:
    mov $-1,%eax; kmovd %eax,%k1; vpmovm2d %k1,%zmm0; mov %r11,%rdx; mov %ecx,%eax; mov %r9d,%r8d
.Lrv_ehv:
    test %eax,%eax; jz .Lrv_eht
    vmovdqu32 (%rdx),%zmm1; vpminub %zmm1,%zmm0,%zmm0; add $64,%rdx; dec %eax; jnz .Lrv_ehv
.Lrv_eht:
    test %r8d,%r8d; jz .Lrv_ehpck
.Lrv_ehtl:
    mov (%rdx),%eax; vmovd %eax,%xmm1; vpbroadcastd %xmm1,%zmm1; vpminub %zmm1,%zmm0,%zmm0
    add $4,%rdx; dec %r8d; jnz .Lrv_ehtl
.Lrv_ehpck:
    vextracti64x4 $1,%zmm0,%ymm1; vpminub %ymm1,%ymm0,%ymm0
    vextracti128 $1,%ymm0,%xmm1; vpminub %xmm1,%xmm0,%xmm0
    vpsrldq $8,%xmm0,%xmm1; vpminub %xmm1,%xmm0,%xmm0
    vpsrldq $4,%xmm0,%xmm1; vpminub %xmm1,%xmm0,%xmm0
    vmovd %xmm0,%eax; mov %eax,(%rdi); add $4,%rdi; add $4,%r11; dec %r12d; jnz .Lrv_ehp
    jmp .Lrv_done

.Lrv_dh:
    lea 1(%r12d,%r12d),%eax; mov %eax,%ecx; shr $4,%ecx; and $15,%eax; mov %eax,%r9d
    mov 72(%rsp),%r12d; sub %ebx,%r12d
    mov 56(%rsp),%r15d; movslq %r15d,%rax; movslq %r13d,%rdx; imul %rdx,%rax; movslq %ebx,%rdx; add %rdx,%rax; lea (%rdi,%rax,4),%rdi
    mov %r10,%r11
.Lrv_dhp:
    vpxorq %zmm0,%zmm0,%zmm0; mov %r11,%rdx; mov %ecx,%eax; mov %r9d,%r8d
.Lrv_dhv:
    test %eax,%eax; jz .Lrv_dht
    vmovdqu32 (%rdx),%zmm1; vpmaxub %zmm1,%zmm0,%zmm0; add $64,%rdx; dec %eax; jnz .Lrv_dhv
.Lrv_dht:
    test %r8d,%r8d; jz .Lrv_dhpck
.Lrv_dhtl:
    mov (%rdx),%eax; vmovd %eax,%xmm1; vpbroadcastd %xmm1,%zmm1; vpmaxub %zmm1,%zmm0,%zmm0
    add $4,%rdx; dec %r8d; jnz .Lrv_dhtl
.Lrv_dhpck:
    vextracti64x4 $1,%zmm0,%ymm1; vpmaxub %ymm1,%ymm0,%ymm0
    vextracti128 $1,%ymm0,%xmm1; vpmaxub %xmm1,%xmm0,%xmm0
    vpsrldq $8,%xmm0,%xmm1; vpmaxub %xmm1,%xmm0,%xmm0
    vpsrldq $4,%xmm0,%xmm1; vpmaxub %xmm1,%xmm0,%xmm0
    vmovd %xmm0,%eax; mov %eax,(%rdi); add $4,%rdi; add $4,%r11; dec %r12d; jnz .Lrv_dhp
.Lrv_done:
    vzeroupper
    pop %r15; pop %r14; pop %r13; pop %r12; pop %rbp; pop %rbx; ret
//// SIZE(SYM(ksvgMorphologyApplyRowAvx512))
