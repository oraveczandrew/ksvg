/*
 * x86-64 SSSE3 implementation of UnLinearize.
 *
 * void ksvgUnlinearizeApplySsse3(
 *     jint* src, jint* dst, jint width, jint height, const jbyte* table);
 *
 * SysV x86-64 ABI:
 *   rdi = src, rsi = dst, edx = width, ecx = height, r8 = 256-byte LUT
 *
 * 16 ARGB8888 pixels (64 bytes) per iteration, statically unrolled over four
 * 4-pixel vectors. LUT layout: 16 rows x 16 bytes; the high nibble selects the
 * row, the low nibble the entry within the row via SSSE3 PSHUFB - a pure byte
 * permutation, bit-exact with the scalar reference.
 *
 * This is the layout chosen by the A/B/C structural-overhead study (the
 * benchmarked SSSE3 tables and the per-pixel hot-loop op counts are in
 * KERNEL_REVIEW.md, section "UnLinearize SSSE3 A/C"):
 *  - No stack frame: every LUT row is loaded directly from the table pointer
 *    (%r8). No 328-byte stack cache, no stack -> XMM reloads.
 *  - Alpha never touches memory: it is split into its own register up front
 *    (movdqa + pand) and only re-combined with a final pand/por at the store.
 *  - True static unrolling over the four input vectors - every vector is
 *    loaded exactly once (movdqu 0/16/32/48(%rdi)) and processed inline; there
 *    is no runtime index dispatch (no cmp/jcc between vectors).
 *  - Only volatile xmm0..xmm7 (SysV caller-saved) are used. No callee-saved
 *    xmm8..xmm15 is read or written, so the function needs no prologue/epilogue
 *    save/restore and stays ABI-correct.
 *  - The row-id counter is kept as a broadcast byte vector (xmm7) and advanced
 *    with a single paddb per row; the mask is computed into a scratch register
 *    (xmm6) so the hi-nibble vector (xmm2) is never clobbered.
 *
 * Per-vector register map:
 *   xmm0 = pixel vector (loaded once)  -> becomes lo-baseline copy scratch
 *   xmm1 = lo nibbles                  (v & 0x0F)
 *   xmm2 = hi nibbles                  ((v >> 4) & 0x0F)
 *   xmm3 = RGB accumulator
 *   xmm4 = alpha (pixel & alpha_mask), kept across the 16-row lookup
 *   xmm5 = LUT row (from table + 16*i)
 *   xmm6 = row-select mask  (hi == rowid)
 *   xmm7 = row-id broadcast (0..15), +1 per row
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
.globl SYM(ksvgUnlinearizeApplySsse3)
TYPE(SYM(ksvgUnlinearizeApplySsse3), @function)
SYM(ksvgUnlinearizeApplySsse3):

    /* total = width * height; blocks16 = total / 16; tail = total % 16 */
    movl    %edx, %eax
    imull   %ecx, %eax
    movl    %eax, %r9d
    shrl    $4, %r9d
    andl    $15, %eax
    movl    %eax, %r10d

    /* xmm7 = row-id broadcast, starts at 0 */
    xorps   %xmm7, %xmm7

    testl   %r9d, %r9d
    jz      .L_tail

.p2align 5
.L_loop:

    /* ================= Vector 0 (pixels 0..3) ================= */
    movdqu    (%rdi), %xmm0
    movdqa    %xmm0, %xmm1
    pand    .L_nibble_mask(%rip), %xmm1     /* lo */
    movdqa    %xmm0, %xmm2
    psrlw   $4, %xmm2
    pand    .L_nibble_mask(%rip), %xmm2     /* hi */
    movdqa    %xmm0, %xmm4
    pand    .L_alpha_mask(%rip), %xmm4      /* alpha */
    xorps   %xmm3, %xmm3                    /* acc = 0 */
    xorps   %xmm7, %xmm7                    /* rowid = 0 */

    /* row 0 */
    movdqu   0(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 1 */
    movdqu  16(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 2 */
    movdqu  32(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 3 */
    movdqu  48(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 4 */
    movdqu  64(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 5 */
    movdqu  80(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 6 */
    movdqu  96(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 7 */
    movdqu 112(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 8 */
    movdqu 128(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 9 */
    movdqu 144(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 10 */
    movdqu 160(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 11 */
    movdqu 176(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 12 */
    movdqu 192(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 13 */
    movdqu 208(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 14 */
    movdqu 224(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 15 */
    movdqu 240(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3

    /* restore alpha: RGB result | original alpha */
    pand    .L_rgb_mask(%rip), %xmm3
    por     %xmm4, %xmm3
    movdqu  %xmm3, (%rsi)

    /* ================= Vector 1 (pixels 4..7) ================= */
    movdqu  16(%rdi), %xmm0
    movdqa  %xmm0, %xmm1
    pand    .L_nibble_mask(%rip), %xmm1     /* lo */
    movdqa  %xmm0, %xmm2
    psrlw   $4, %xmm2
    pand    .L_nibble_mask(%rip), %xmm2     /* hi */
    movdqa  %xmm0, %xmm4
    pand    .L_alpha_mask(%rip), %xmm4      /* alpha */
    xorps   %xmm3, %xmm3                    /* acc = 0 */
    xorps   %xmm7, %xmm7                    /* rowid = 0 */

    /* row 0 */
    movdqu   0(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 1 */
    movdqu  16(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 2 */
    movdqu  32(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 3 */
    movdqu  48(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 4 */
    movdqu  64(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 5 */
    movdqu  80(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 6 */
    movdqu  96(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 7 */
    movdqu 112(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 8 */
    movdqu 128(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 9 */
    movdqu 144(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 10 */
    movdqu 160(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 11 */
    movdqu 176(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 12 */
    movdqu 192(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 13 */
    movdqu 208(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 14 */
    movdqu 224(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 15 */
    movdqu 240(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3

    /* restore alpha */
    pand    .L_rgb_mask(%rip), %xmm3
    por     %xmm4, %xmm3
    movdqu  %xmm3, 16(%rsi)

    /* ================= Vector 2 (pixels 8..11) ================= */
    movdqu  32(%rdi), %xmm0
    movdqa  %xmm0, %xmm1
    pand    .L_nibble_mask(%rip), %xmm1     /* lo */
    movdqa  %xmm0, %xmm2
    psrlw   $4, %xmm2
    pand    .L_nibble_mask(%rip), %xmm2     /* hi */
    movdqa  %xmm0, %xmm4
    pand    .L_alpha_mask(%rip), %xmm4      /* alpha */
    xorps   %xmm3, %xmm3                    /* acc = 0 */
    xorps   %xmm7, %xmm7                    /* rowid = 0 */

    /* row 0 */
    movdqu   0(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 1 */
    movdqu  16(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 2 */
    movdqu  32(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 3 */
    movdqu  48(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 4 */
    movdqu  64(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 5 */
    movdqu  80(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 6 */
    movdqu  96(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 7 */
    movdqu 112(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 8 */
    movdqu 128(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 9 */
    movdqu 144(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 10 */
    movdqu 160(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 11 */
    movdqu 176(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 12 */
    movdqu 192(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 13 */
    movdqu 208(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 14 */
    movdqu 224(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 15 */
    movdqu 240(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3

    /* restore alpha */
    pand    .L_rgb_mask(%rip), %xmm3
    por     %xmm4, %xmm3
    movdqu  %xmm3, 32(%rsi)

    /* ================= Vector 3 (pixels 12..15) ================= */
    movdqu  48(%rdi), %xmm0
    movdqa  %xmm0, %xmm1
    pand    .L_nibble_mask(%rip), %xmm1     /* lo */
    movdqa  %xmm0, %xmm2
    psrlw   $4, %xmm2
    pand    .L_nibble_mask(%rip), %xmm2     /* hi */
    movdqa  %xmm0, %xmm4
    pand    .L_alpha_mask(%rip), %xmm4      /* alpha */
    xorps   %xmm3, %xmm3                    /* acc = 0 */
    xorps   %xmm7, %xmm7                    /* rowid = 0 */

    /* row 0 */
    movdqu   0(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 1 */
    movdqu  16(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 2 */
    movdqu  32(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 3 */
    movdqu  48(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 4 */
    movdqu  64(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 5 */
    movdqu  80(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 6 */
    movdqu  96(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 7 */
    movdqu 112(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 8 */
    movdqu 128(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 9 */
    movdqu 144(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 10 */
    movdqu 160(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 11 */
    movdqu 176(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 12 */
    movdqu 192(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 13 */
    movdqu 208(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 14 */
    movdqu 224(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_one_vec(%rip), %xmm7
    /* row 15 */
    movdqu 240(%r8), %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3

    /* restore alpha */
    pand    .L_rgb_mask(%rip), %xmm3
    por     %xmm4, %xmm3
    movdqu  %xmm3, 48(%rsi)

    addq    $64, %rdi
    addq    $64, %rsi
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
//// SIZE(SYM(ksvgUnlinearizeApplySsse3))