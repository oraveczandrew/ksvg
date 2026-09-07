/*
 * x86-64 SSSE3 UnLinearize experiment vE: "4-bit binary decision-tree cascade".
 *
 *   void ksvgUnlinearizeApplySsse3vE(
 *       jint* src, jint* dst, jint width, jint height, const jbyte* table);
 *
 * SysV x86-64 ABI: rdi = src, rsi = dst, edx = width, ecx = height, r8 = LUT.
 *
 * The 16-row compare-and-select cascade (vB) resolves every row with a
 * PCMPEQB per row (16), then masks (pand) and accumulates (por + paddb row-id
 * advance): ~15-deep serial accumulate chain per 4-pixel vector. vE replaces
 * that with an exact 4-bit BINARY DECISION TREE over the high nibble (the row
 * index), so there are NO PCMPEQB and NO PADDB in the loop:
 *
 *   leaves    C[r] = PSHUFB(row r, lo)          (16 per vector, row = 16r(%r8)
 *                                                loaded like vB -- memory path
 *                                                deliberately untouched)
 *   masks     m_k = PSHUFB(precomputed 16-byte table of 0xFF/0x00, hi)
 *                                                0xFF where hi has bit k   (k0..3)
 *   level 0   for each row pair (2p, 2p+1):  blend(C[2p], C[2p+1], m0)   (8 nodes)
 *   level 1   4 blends by m1   level 2  2 blends by m2   level 3  1 blend by m3
 *
 * blend(a, b, m) = (a & ~m) | (b & m): ~m_k is hoisted once per level into
 * xmm6 by `pxor .L_vE_ones` (all-0xFF), then each node is
 * pand(a,&~m) + pand(b,&m) + por -- still 3 ops per node, log-depth (4 levels)
 * instead of a 16-row serial accumulate. Per-lane exactness: row number's bit k
 * == byte's high-nibble bit k, so a lane's byte is selected by exactly one path
 * of the tree. No PCMPEQB and no PADDB anywhere in the loop.
 *
 * Register map (xmm8..xmm15 = tree slots, callee-saved, saved in prologue):
 *   xmm0..3 = m0..m3, xmm4 = lo, xmm5 = alpha, xmm6 = ~m_k (per level),
 *   xmm7 = scratch
 *
 * The question this experiment answers: does replacing the 16-way select with
 * a 4-bit decision tree reduce the PCMPEQB/PAND/POR work (and the dependency
 * depth) enough to matter, with the LUT load path held identical to vB?
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
.globl SYM(ksvgUnlinearizeApplySsse3vE)
TYPE(SYM(ksvgUnlinearizeApplySsse3vE), @function)
SYM(ksvgUnlinearizeApplySsse3vE):

    movl    %edx, %eax
    imull   %ecx, %eax
    movl    %eax, %r9d
    shrl    $4, %r9d
    andl    $15, %eax
    movl    %eax, %r10d

    testl   %r9d, %r9d
    jz      .L_vE_tail

    /* prologue: save callee-saved xmm8..xmm15 */
    subq    $128, %rsp
    movdqu  %xmm8,   0(%rsp)
    movdqu  %xmm9,  16(%rsp)
    movdqu  %xmm10, 32(%rsp)
    movdqu  %xmm11, 48(%rsp)
    movdqu  %xmm12, 64(%rsp)
    movdqu  %xmm13, 80(%rsp)
    movdqu  %xmm14, 96(%rsp)
    movdqu  %xmm15,112(%rsp)

.p2align 5
.L_vE_block:
    /* ---- vector 0 (pixels 0..3) ---- */
    movdqu  0(%rdi), %xmm7
    movdqa  %xmm7, %xmm4
    pand    .L_vE_nibble(%rip), %xmm4
    movdqa  %xmm7, %xmm6
    psrlw   $4, %xmm6
    pand    .L_vE_nibble(%rip), %xmm6
    movdqa  %xmm7, %xmm5
    pand    .L_vE_alpha(%rip), %xmm5
    movdqa  .L_vE_m0(%rip), %xmm0
    pshufb  %xmm6, %xmm0
    movdqa  .L_vE_m1(%rip), %xmm1
    pshufb  %xmm6, %xmm1
    movdqa  .L_vE_m2(%rip), %xmm2
    pshufb  %xmm6, %xmm2
    movdqa  .L_vE_m3(%rip), %xmm3
    pshufb  %xmm6, %xmm3
    movdqa  %xmm0, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    movdqu  0(%r8), %xmm8
    pshufb  %xmm4, %xmm8
    pand    %xmm6, %xmm8
    movdqu  16(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm8
    movdqu  32(%r8), %xmm9
    pshufb  %xmm4, %xmm9
    pand    %xmm6, %xmm9
    movdqu  48(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm9
    movdqu  64(%r8), %xmm10
    pshufb  %xmm4, %xmm10
    pand    %xmm6, %xmm10
    movdqu  80(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm10
    movdqu  96(%r8), %xmm11
    pshufb  %xmm4, %xmm11
    pand    %xmm6, %xmm11
    movdqu  112(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm11
    movdqu  128(%r8), %xmm12
    pshufb  %xmm4, %xmm12
    pand    %xmm6, %xmm12
    movdqu  144(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm12
    movdqu  160(%r8), %xmm13
    pshufb  %xmm4, %xmm13
    pand    %xmm6, %xmm13
    movdqu  176(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm13
    movdqu  192(%r8), %xmm14
    pshufb  %xmm4, %xmm14
    pand    %xmm6, %xmm14
    movdqu  208(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm14
    movdqu  224(%r8), %xmm15
    pshufb  %xmm4, %xmm15
    pand    %xmm6, %xmm15
    movdqu  240(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm15
    movdqa  %xmm1, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    pand    %xmm6, %xmm8
    pand    %xmm1, %xmm9
    por     %xmm9, %xmm8
    pand    %xmm6, %xmm10
    pand    %xmm1, %xmm11
    por     %xmm11, %xmm10
    pand    %xmm6, %xmm12
    pand    %xmm1, %xmm13
    por     %xmm13, %xmm12
    pand    %xmm6, %xmm14
    pand    %xmm1, %xmm15
    por     %xmm15, %xmm14
    movdqa  %xmm2, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    pand    %xmm6, %xmm8
    pand    %xmm2, %xmm10
    por     %xmm10, %xmm8
    pand    %xmm6, %xmm12
    pand    %xmm2, %xmm14
    por     %xmm14, %xmm12
    movdqa  %xmm3, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    pand    %xmm6, %xmm8
    pand    %xmm3, %xmm12
    por     %xmm12, %xmm8
    pand    .L_vE_rgb(%rip), %xmm8
    por     %xmm5, %xmm8
    movdqu  %xmm8, 0(%rsi)


    /* ---- vector 1 (pixels 4..7) ---- */
    movdqu  16(%rdi), %xmm7
    movdqa  %xmm7, %xmm4
    pand    .L_vE_nibble(%rip), %xmm4
    movdqa  %xmm7, %xmm6
    psrlw   $4, %xmm6
    pand    .L_vE_nibble(%rip), %xmm6
    movdqa  %xmm7, %xmm5
    pand    .L_vE_alpha(%rip), %xmm5
    movdqa  .L_vE_m0(%rip), %xmm0
    pshufb  %xmm6, %xmm0
    movdqa  .L_vE_m1(%rip), %xmm1
    pshufb  %xmm6, %xmm1
    movdqa  .L_vE_m2(%rip), %xmm2
    pshufb  %xmm6, %xmm2
    movdqa  .L_vE_m3(%rip), %xmm3
    pshufb  %xmm6, %xmm3
    movdqa  %xmm0, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    movdqu  0(%r8), %xmm8
    pshufb  %xmm4, %xmm8
    pand    %xmm6, %xmm8
    movdqu  16(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm8
    movdqu  32(%r8), %xmm9
    pshufb  %xmm4, %xmm9
    pand    %xmm6, %xmm9
    movdqu  48(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm9
    movdqu  64(%r8), %xmm10
    pshufb  %xmm4, %xmm10
    pand    %xmm6, %xmm10
    movdqu  80(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm10
    movdqu  96(%r8), %xmm11
    pshufb  %xmm4, %xmm11
    pand    %xmm6, %xmm11
    movdqu  112(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm11
    movdqu  128(%r8), %xmm12
    pshufb  %xmm4, %xmm12
    pand    %xmm6, %xmm12
    movdqu  144(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm12
    movdqu  160(%r8), %xmm13
    pshufb  %xmm4, %xmm13
    pand    %xmm6, %xmm13
    movdqu  176(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm13
    movdqu  192(%r8), %xmm14
    pshufb  %xmm4, %xmm14
    pand    %xmm6, %xmm14
    movdqu  208(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm14
    movdqu  224(%r8), %xmm15
    pshufb  %xmm4, %xmm15
    pand    %xmm6, %xmm15
    movdqu  240(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm15
    movdqa  %xmm1, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    pand    %xmm6, %xmm8
    pand    %xmm1, %xmm9
    por     %xmm9, %xmm8
    pand    %xmm6, %xmm10
    pand    %xmm1, %xmm11
    por     %xmm11, %xmm10
    pand    %xmm6, %xmm12
    pand    %xmm1, %xmm13
    por     %xmm13, %xmm12
    pand    %xmm6, %xmm14
    pand    %xmm1, %xmm15
    por     %xmm15, %xmm14
    movdqa  %xmm2, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    pand    %xmm6, %xmm8
    pand    %xmm2, %xmm10
    por     %xmm10, %xmm8
    pand    %xmm6, %xmm12
    pand    %xmm2, %xmm14
    por     %xmm14, %xmm12
    movdqa  %xmm3, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    pand    %xmm6, %xmm8
    pand    %xmm3, %xmm12
    por     %xmm12, %xmm8
    pand    .L_vE_rgb(%rip), %xmm8
    por     %xmm5, %xmm8
    movdqu  %xmm8, 16(%rsi)


    /* ---- vector 2 (pixels 8..11) ---- */
    movdqu  32(%rdi), %xmm7
    movdqa  %xmm7, %xmm4
    pand    .L_vE_nibble(%rip), %xmm4
    movdqa  %xmm7, %xmm6
    psrlw   $4, %xmm6
    pand    .L_vE_nibble(%rip), %xmm6
    movdqa  %xmm7, %xmm5
    pand    .L_vE_alpha(%rip), %xmm5
    movdqa  .L_vE_m0(%rip), %xmm0
    pshufb  %xmm6, %xmm0
    movdqa  .L_vE_m1(%rip), %xmm1
    pshufb  %xmm6, %xmm1
    movdqa  .L_vE_m2(%rip), %xmm2
    pshufb  %xmm6, %xmm2
    movdqa  .L_vE_m3(%rip), %xmm3
    pshufb  %xmm6, %xmm3
    movdqa  %xmm0, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    movdqu  0(%r8), %xmm8
    pshufb  %xmm4, %xmm8
    pand    %xmm6, %xmm8
    movdqu  16(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm8
    movdqu  32(%r8), %xmm9
    pshufb  %xmm4, %xmm9
    pand    %xmm6, %xmm9
    movdqu  48(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm9
    movdqu  64(%r8), %xmm10
    pshufb  %xmm4, %xmm10
    pand    %xmm6, %xmm10
    movdqu  80(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm10
    movdqu  96(%r8), %xmm11
    pshufb  %xmm4, %xmm11
    pand    %xmm6, %xmm11
    movdqu  112(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm11
    movdqu  128(%r8), %xmm12
    pshufb  %xmm4, %xmm12
    pand    %xmm6, %xmm12
    movdqu  144(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm12
    movdqu  160(%r8), %xmm13
    pshufb  %xmm4, %xmm13
    pand    %xmm6, %xmm13
    movdqu  176(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm13
    movdqu  192(%r8), %xmm14
    pshufb  %xmm4, %xmm14
    pand    %xmm6, %xmm14
    movdqu  208(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm14
    movdqu  224(%r8), %xmm15
    pshufb  %xmm4, %xmm15
    pand    %xmm6, %xmm15
    movdqu  240(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm15
    movdqa  %xmm1, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    pand    %xmm6, %xmm8
    pand    %xmm1, %xmm9
    por     %xmm9, %xmm8
    pand    %xmm6, %xmm10
    pand    %xmm1, %xmm11
    por     %xmm11, %xmm10
    pand    %xmm6, %xmm12
    pand    %xmm1, %xmm13
    por     %xmm13, %xmm12
    pand    %xmm6, %xmm14
    pand    %xmm1, %xmm15
    por     %xmm15, %xmm14
    movdqa  %xmm2, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    pand    %xmm6, %xmm8
    pand    %xmm2, %xmm10
    por     %xmm10, %xmm8
    pand    %xmm6, %xmm12
    pand    %xmm2, %xmm14
    por     %xmm14, %xmm12
    movdqa  %xmm3, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    pand    %xmm6, %xmm8
    pand    %xmm3, %xmm12
    por     %xmm12, %xmm8
    pand    .L_vE_rgb(%rip), %xmm8
    por     %xmm5, %xmm8
    movdqu  %xmm8, 32(%rsi)


    /* ---- vector 3 (pixels 12..15) ---- */
    movdqu  48(%rdi), %xmm7
    movdqa  %xmm7, %xmm4
    pand    .L_vE_nibble(%rip), %xmm4
    movdqa  %xmm7, %xmm6
    psrlw   $4, %xmm6
    pand    .L_vE_nibble(%rip), %xmm6
    movdqa  %xmm7, %xmm5
    pand    .L_vE_alpha(%rip), %xmm5
    movdqa  .L_vE_m0(%rip), %xmm0
    pshufb  %xmm6, %xmm0
    movdqa  .L_vE_m1(%rip), %xmm1
    pshufb  %xmm6, %xmm1
    movdqa  .L_vE_m2(%rip), %xmm2
    pshufb  %xmm6, %xmm2
    movdqa  .L_vE_m3(%rip), %xmm3
    pshufb  %xmm6, %xmm3
    movdqa  %xmm0, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    movdqu  0(%r8), %xmm8
    pshufb  %xmm4, %xmm8
    pand    %xmm6, %xmm8
    movdqu  16(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm8
    movdqu  32(%r8), %xmm9
    pshufb  %xmm4, %xmm9
    pand    %xmm6, %xmm9
    movdqu  48(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm9
    movdqu  64(%r8), %xmm10
    pshufb  %xmm4, %xmm10
    pand    %xmm6, %xmm10
    movdqu  80(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm10
    movdqu  96(%r8), %xmm11
    pshufb  %xmm4, %xmm11
    pand    %xmm6, %xmm11
    movdqu  112(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm11
    movdqu  128(%r8), %xmm12
    pshufb  %xmm4, %xmm12
    pand    %xmm6, %xmm12
    movdqu  144(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm12
    movdqu  160(%r8), %xmm13
    pshufb  %xmm4, %xmm13
    pand    %xmm6, %xmm13
    movdqu  176(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm13
    movdqu  192(%r8), %xmm14
    pshufb  %xmm4, %xmm14
    pand    %xmm6, %xmm14
    movdqu  208(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm14
    movdqu  224(%r8), %xmm15
    pshufb  %xmm4, %xmm15
    pand    %xmm6, %xmm15
    movdqu  240(%r8), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm0, %xmm7
    por     %xmm7, %xmm15
    movdqa  %xmm1, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    pand    %xmm6, %xmm8
    pand    %xmm1, %xmm9
    por     %xmm9, %xmm8
    pand    %xmm6, %xmm10
    pand    %xmm1, %xmm11
    por     %xmm11, %xmm10
    pand    %xmm6, %xmm12
    pand    %xmm1, %xmm13
    por     %xmm13, %xmm12
    pand    %xmm6, %xmm14
    pand    %xmm1, %xmm15
    por     %xmm15, %xmm14
    movdqa  %xmm2, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    pand    %xmm6, %xmm8
    pand    %xmm2, %xmm10
    por     %xmm10, %xmm8
    pand    %xmm6, %xmm12
    pand    %xmm2, %xmm14
    por     %xmm14, %xmm12
    movdqa  %xmm3, %xmm6
    pxor    .L_vE_ones(%rip), %xmm6
    pand    %xmm6, %xmm8
    pand    %xmm3, %xmm12
    por     %xmm12, %xmm8
    pand    .L_vE_rgb(%rip), %xmm8
    por     %xmm5, %xmm8
    movdqu  %xmm8, 48(%rsi)


    addq    $64, %rdi
    addq    $64, %rsi
    decl    %r9d
    jnz     .L_vE_block

    /* epilogue: restore callee-saved xmm8..xmm15 */
    movdqu   0(%rsp), %xmm8
    movdqu  16(%rsp), %xmm9
    movdqu  32(%rsp), %xmm10
    movdqu  48(%rsp), %xmm11
    movdqu  64(%rsp), %xmm12
    movdqu  80(%rsp), %xmm13
    movdqu  96(%rsp), %xmm14
    movdqu 112(%rsp), %xmm15
    addq    $128, %rsp

.L_vE_tail:
    testl   %r10d, %r10d
    jz      .L_vE_done

.L_vE_tail_loop:
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
    jnz     .L_vE_tail_loop

.L_vE_done:
    ret

#ifdef __APPLE__
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 4
.L_vE_nibble:
    .byte 0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f
    .byte 0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f
.L_vE_rgb:
    .byte 0xff,0xff,0xff,0x00, 0xff,0xff,0xff,0x00
    .byte 0xff,0xff,0xff,0x00, 0xff,0xff,0xff,0x00
.L_vE_alpha:
    .byte 0x00,0x00,0x00,0xff, 0x00,0x00,0x00,0xff
    .byte 0x00,0x00,0x00,0xff, 0x00,0x00,0x00,0xff
.L_vE_ones:
    .byte 0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
.L_vE_m0:
    .byte 0x00,0xff,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0xff
.L_vE_m1:
    .byte 0x00,0x00,0xff,0xff,0x00,0x00,0xff,0xff,0x00,0x00,0xff,0xff,0x00,0x00,0xff,0xff
.L_vE_m2:
    .byte 0x00,0x00,0x00,0x00,0xff,0xff,0xff,0xff,0x00,0x00,0x00,0x00,0xff,0xff,0xff,0xff
.L_vE_m3:
    .byte 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff

.text
//// SIZE(SYM(ksvgUnlinearizeApplySsse3vE))
