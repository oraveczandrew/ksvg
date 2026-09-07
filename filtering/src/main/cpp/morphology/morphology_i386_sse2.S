/* Copyright 2026 András Oravecz. Apache-2.0. */
/* x86-32 / SSE2, cdecl ABI. Interior-only morphology. */
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
.code32
.p2align 4

/* Row(src,dst,width,rx,ry,erode,y,xStart,xEnd,scratch) */
.globl SYM(ksvgMorphologyApplyRowSse2)
TYPE(SYM(ksvgMorphologyApplyRowSse2),@function)
SYM(ksvgMorphologyApplyRowSse2):
    push %ebp; mov %esp,%ebp
    push %ebx; push %esi; push %edi
    sub $48,%esp
    # locals: -4 srcCursor, -8 dstCursor, -12 scratch, -16 stride,
    # -20 rowCount, -24 colLo, -28 colCount, -32 groups, -36 tail,
    # -40 outCount, -44 L, -48 tmp
    mov 8(%ebp),%eax; mov %eax,-4(%ebp)
    mov 12(%ebp),%eax; mov %eax,-8(%ebp)
    mov 44(%ebp),%eax; mov %eax,-12(%ebp)
    mov 16(%ebp),%eax; shl $2,%eax; mov %eax,-16(%ebp)
    mov 24(%ebp),%eax; lea 1(%eax,%eax),%eax; mov %eax,-20(%ebp)
    mov 36(%ebp),%eax; sub 20(%ebp),%eax; mov %eax,-24(%ebp)
    mov 40(%ebp),%eax; sub 36(%ebp),%eax; mov %eax,-40(%ebp)
    mov -40(%ebp),%eax; mov 20(%ebp),%edx; lea (%eax,%edx,2),%eax; mov %eax,-28(%ebp)
    mov -28(%ebp),%eax; mov %eax,%edx; shr $2,%eax; and $3,%edx; mov %eax,-32(%ebp); mov %edx,-36(%ebp)
    mov 20(%ebp),%eax; lea 1(%eax,%eax),%eax; mov %eax,-44(%ebp)

    mov 32(%ebp),%eax; sub 24(%ebp),%eax; imul 16(%ebp),%eax; add -24(%ebp),%eax
    mov 8(%ebp),%edx; lea (%edx,%eax,4),%edx; mov %edx,-4(%ebp)
    cmpl $0,28(%ebp); jne .Lrs32_evert

.Lrs32_dvert:
    mov -12(%ebp),%edi; mov -32(%ebp),%esi
.Lrs32_dg:
    test %esi,%esi; jz .Lrs32_dt
    pxor %xmm0,%xmm0; mov -4(%ebp),%eax; mov -20(%ebp),%ecx
.Lrs32_dr:
    movdqu (%eax),%xmm1; pmaxub %xmm1,%xmm0; add -16(%ebp),%eax; dec %ecx; jnz .Lrs32_dr
    movdqu %xmm0,(%edi); add $16,%edi; addl $16,-4(%ebp); dec %esi; jmp .Lrs32_dg
.Lrs32_dt:
    mov -36(%ebp),%esi; test %esi,%esi; jz .Lrs32_hmax
.Lrs32_dtc:
    pxor %xmm0,%xmm0; mov -4(%ebp),%eax; mov -20(%ebp),%ecx
.Lrs32_dtr:
    mov (%eax),%edx; movd %edx,%xmm1; pshufd $0,%xmm1,%xmm1; pmaxub %xmm1,%xmm0
    add -16(%ebp),%eax; dec %ecx; jnz .Lrs32_dtr
    movd %xmm0,(%edi); add $4,%edi; addl $4,-4(%ebp); dec %esi; jnz .Lrs32_dtc
    jmp .Lrs32_hmax

.Lrs32_evert:
    mov -12(%ebp),%edi; mov -32(%ebp),%esi
.Lrs32_eg:
    test %esi,%esi; jz .Lrs32_et
    pcmpeqb %xmm0,%xmm0; mov -4(%ebp),%eax; mov -20(%ebp),%ecx
.Lrs32_er:
    movdqu (%eax),%xmm1; pminub %xmm1,%xmm0; add -16(%ebp),%eax; dec %ecx; jnz .Lrs32_er
    movdqu %xmm0,(%edi); add $16,%edi; addl $16,-4(%ebp); dec %esi; jmp .Lrs32_eg
.Lrs32_et:
    mov -36(%ebp),%esi; test %esi,%esi; jz .Lrs32_hmin
.Lrs32_etc:
    pcmpeqb %xmm0,%xmm0; mov -4(%ebp),%eax; mov -20(%ebp),%ecx
.Lrs32_etr:
    mov (%eax),%edx; movd %edx,%xmm1; pshufd $0,%xmm1,%xmm1; pminub %xmm1,%xmm0
    add -16(%ebp),%eax; dec %ecx; jnz .Lrs32_etr
    movd %xmm0,(%edi); add $4,%edi; addl $4,-4(%ebp); dec %esi; jnz .Lrs32_etc

.Lrs32_hmax:
    mov -40(%ebp),%ecx; mov 12(%ebp),%eax; mov 32(%ebp),%edx; imul 16(%ebp),%edx; add 36(%ebp),%edx; lea (%eax,%edx,4),%eax; mov %eax,-8(%ebp)
    mov -12(%ebp),%edi
.Lrs32_hmax_px:
    pxor %xmm0,%xmm0; mov %edi,%eax; mov -44(%ebp),%edx; shr $2,%edx
.Lrs32_hmax_vec:
    test %edx,%edx; jz .Lrs32_hmax_tail
    movdqu (%eax),%xmm1; pmaxub %xmm1,%xmm0; add $16,%eax; dec %edx; jnz .Lrs32_hmax_vec
.Lrs32_hmax_tail:
    mov -44(%ebp),%edx; and $3,%edx
.Lrs32_hmax_t:
    test %edx,%edx; jz .Lrs32_hmax_red
    mov (%eax),%ebx; movd %ebx,%xmm1; pshufd $0,%xmm1,%xmm1; pmaxub %xmm1,%xmm0; add $4,%eax; dec %edx; jmp .Lrs32_hmax_t
.Lrs32_hmax_red:
    movdqa %xmm0,%xmm1; psrldq $8,%xmm1; pmaxub %xmm1,%xmm0; movdqa %xmm0,%xmm1; psrldq $4,%xmm1; pmaxub %xmm1,%xmm0
    movd %xmm0,%eax; mov -8(%ebp),%edx; mov %eax,(%edx); add $4,%edx; mov %edx,-8(%ebp); add $4,%edi; dec %ecx; jnz .Lrs32_hmax_px
    jmp .Lrs32_done

.Lrs32_hmin:
    mov -40(%ebp),%ecx; mov 12(%ebp),%eax; mov 32(%ebp),%edx; imul 16(%ebp),%edx; add 36(%ebp),%edx; lea (%eax,%edx,4),%eax; mov %eax,-8(%ebp)
    mov -12(%ebp),%edi
.Lrs32_hmin_px:
    pcmpeqb %xmm0,%xmm0; mov %edi,%eax; mov -44(%ebp),%edx; shr $2,%edx
.Lrs32_hmin_vec:
    test %edx,%edx; jz .Lrs32_hmin_tail
    movdqu (%eax),%xmm1; pminub %xmm1,%xmm0; add $16,%eax; dec %edx; jnz .Lrs32_hmin_vec
.Lrs32_hmin_tail:
    mov -44(%ebp),%edx; and $3,%edx
.Lrs32_hmin_t:
    test %edx,%edx; jz .Lrs32_hmin_red
    mov (%eax),%ebx; movd %ebx,%xmm1; pshufd $0,%xmm1,%xmm1; pminub %xmm1,%xmm0; add $4,%eax; dec %edx; jmp .Lrs32_hmin_t
.Lrs32_hmin_red:
    movdqa %xmm0,%xmm1; psrldq $8,%xmm1; pminub %xmm1,%xmm0; movdqa %xmm0,%xmm1; psrldq $4,%xmm1; pminub %xmm1,%xmm0
    movd %xmm0,%eax; mov -8(%ebp),%edx; mov %eax,(%edx); add $4,%edx; mov %edx,-8(%ebp); add $4,%edi; dec %ecx; jnz .Lrs32_hmin_px
.Lrs32_done:
    add $48,%esp; pop %edi; pop %esi; pop %ebx; pop %ebp; ret
//// SIZE(SYM(ksvgMorphologyApplyRowSse2))
