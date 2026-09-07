/*
 * x86-64 SSSE3 implementation of UnLinearize — version A (baseline).
 *
 * void ksvgUnlinearizeApplySsse3vA(
 *     jint* src, jint* dst, jint width, jint height, const jbyte* table);
 *
 * SysV x86-64 ABI:
 *   rdi = src, rsi = dst, edx = width, ecx = height, r8 = 256-byte LUT
 *
 * Processes 4 ARGB8888 pixels (16 bytes) per iteration.
 * LUT layout: 16 rows x 16 bytes. High nibble selects the row and low nibble
 * selects within the row via SSSE3 PSHUFB.
 *
 * This is the originally committed kernel, kept verbatim (modulo the renamed
 * symbol) as the structural-overhead reference for the A/B/C comparison:
 * it relies on xmm8-xmm15 (callee-saved in the SysV ABI) without saving them.
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
.globl SYM(ksvgUnlinearizeApplySsse3vA)
TYPE(SYM(ksvgUnlinearizeApplySsse3vA), @function)
SYM(ksvgUnlinearizeApplySsse3vA):
    movl    %edx, %eax
    imull   %ecx, %eax
    movl    %eax, %r9d
    shrl    $2, %r9d                 /* blocks = total / 4 */
    andl    $3, %eax
    movl    %eax, %r10d              /* tail = total % 4 */

    movdqa  .L_nibble_mask(%rip), %xmm15

    testl   %r9d, %r9d
    jz      .L_tail

.p2align 5
.L_loop:
    /* Source bytes: xmm1. Low/high nibbles: xmm0/xmm2. */
    movdqu  (%rdi), %xmm1
    movdqa  %xmm1, %xmm0
    pand    %xmm15, %xmm0
    movdqa  %xmm1, %xmm2
    psrlw   $4, %xmm2
    pand    %xmm15, %xmm2

    pxor    %xmm3, %xmm3              /* accumulated RGB result */
    pxor    %xmm14, %xmm14            /* row id = 0 */

    /* Rows 0..7. Table rows live in xmm4..xmm11. */
    movdqu   0(%r8), %xmm4
    movdqu  16(%r8), %xmm5
    movdqu  32(%r8), %xmm6
    movdqu  48(%r8), %xmm7
    movdqu  64(%r8), %xmm8
    movdqu  80(%r8), %xmm9
    movdqu  96(%r8), %xmm10
    movdqu 112(%r8), %xmm11

    /* row 0 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm4
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm4
    por     %xmm4, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 1 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm5
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 2 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm6
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm6
    por     %xmm6, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 3 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm7
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm7
    por     %xmm7, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 4 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm8
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm8
    por     %xmm8, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 5 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm9
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm9
    por     %xmm9, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 6 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm10
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm10
    por     %xmm10, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 7 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm11
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm11
    por     %xmm11, %xmm3

    /* Rows 8..15. */
    movdqu 128(%r8), %xmm4
    movdqu 144(%r8), %xmm5
    movdqu 160(%r8), %xmm6
    movdqu 176(%r8), %xmm7
    movdqu 192(%r8), %xmm8
    movdqu 208(%r8), %xmm9
    movdqu 224(%r8), %xmm10
    movdqu 240(%r8), %xmm11
    paddb   .L_one_vec(%rip), %xmm14  /* row id = 8 */

    /* row 8 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm4
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm4
    por     %xmm4, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 9 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm5
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 10 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm6
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm6
    por     %xmm6, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 11 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm7
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm7
    por     %xmm7, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 12 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm8
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm8
    por     %xmm8, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 13 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm9
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm9
    por     %xmm9, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 14 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm10
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm10
    por     %xmm10, %xmm3
    paddb   .L_one_vec(%rip), %xmm14

    /* row 15 */
    movdqa  %xmm0, %xmm12
    pshufb  %xmm12, %xmm11
    movdqa  %xmm2, %xmm13
    pcmpeqb %xmm14, %xmm13
    pand    %xmm13, %xmm11
    por     %xmm11, %xmm3

    /* Preserve A and replace only RGB. */
    pand    .L_rgb_mask(%rip), %xmm3
    pand    .L_alpha_mask(%rip), %xmm1
    por     %xmm1, %xmm3
    movdqu  %xmm3, (%rsi)

    addq    $16, %rdi
    addq    $16, %rsi
    decl    %r9d
    jnz     .L_loop

.L_tail:
    testl   %r10d, %r10d
    jz      .L_done

.L_tail_loop:
    movl    (%rdi), %eax
    movl    %eax, %edx
    andl    $0xff000000, %edx          /* alpha */

    movl    %eax, %ecx
    andl    $0xff, %ecx
    movzbl  (%r8,%rcx), %ecx            /* B */
    movl    %ecx, %r11d

    shrl    $8, %eax
    andl    $0xff, %eax
    movzbl  (%r8,%rax), %eax             /* G */
    shll    $8, %eax
    orl     %eax, %r11d

    movl    (%rdi), %eax
    shrl    $16, %eax
    andl    $0xff, %eax
    movzbl  (%r8,%rax), %eax             /* R */
    shll    $16, %eax
    orl     %eax, %r11d

    orl     %edx, %r11d
    movl    %r11d, (%rsi)
    addq    $4, %rdi
    addq    $4, %rsi
    decl    %r10d
    jnz     .L_tail_loop

.L_done:
    ret

#ifdef __APPLE__
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 4
.L_nibble_mask:
    .byte 0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f
    .byte 0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f
.L_one_vec:
    .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.L_rgb_mask:
    .byte 0xff,0xff,0xff,0x00, 0xff,0xff,0xff,0x00
    .byte 0xff,0xff,0xff,0x00, 0xff,0xff,0xff,0x00
.L_alpha_mask:
    .byte 0x00,0x00,0x00,0xff, 0x00,0x00,0x00,0xff
    .byte 0x00,0x00,0x00,0xff, 0x00,0x00,0x00,0xff

.text
//// SIZE(SYM(ksvgUnlinearizeApplySsse3vA))
