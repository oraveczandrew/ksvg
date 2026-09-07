/*
 * x86-64 SSSE3 UnLinearize experiment vD: "block-hoisted resident-row cascade".
 *
 *   void ksvgUnlinearizeApplySsse3vD(
 *       jint* src, jint* dst, jint width, jint height, const jbyte* table);
 *
 * SysV x86-64 ABI: rdi = src, rsi = dst, edx = width, ecx = height, r8 = LUT.
 *
 * Difference vs the production 16-px unroll (vB):
 *   - vB re-loads all 16 LUT rows from (%r8) for EVERY 4-pixel vector
 *     (64 loads / 16 px). vD hoists the rows into registers once per 16-px
 *     block, in TWO passes of 8 rows (xmm8..xmm15, callee-saved, saved /
 *     restored in the prologue): 16 loads / 16 px. The per-row cascade is
 *     otherwise identical to vB (PSHUFB by lo-nibble + PCMPEQB hi-match on
 *     the row-id, PAND, POR).
 *   - Pass A covers row-ids 0..7 (values 0x00..0x7F), pass B row-ids 8..15.
 *     A lane whose high nibble is h is written by exactly one row (h); the
 *     other seven rows mask it to zero, so POR of the two partials is exact.
 *   - The pass-A partial for each vector is parked on the stack (64 bytes)
 *     and OR-ed with the pass-B result before the rgb/alpha re-combine.
 *   - The tail (total %% 16) uses the same scalar path as production.
 *
 * This experiment isolates the LUT load-port cost: if vD moves materially
 * past vB the residue is structural (loads); if it stays ~equal the cost is
 * the compare-and-select ALU itself.
 *
 * Per 4-pixel vector, pass = 8 rows x (movdqa row-copy + pshufb + movdqa hi +
 * pcmpeqb + pand + por) + 7 row-id advances + setup. All 16 xmm registers
 * used: xmm8..15 rows, xmm0 px, xmm1 lo, xmm2 hi, xmm3 acc, xmm4 alpha,
 * xmm5 row copy, xmm6 hi-mask, xmm7 row-id.
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
.globl SYM(ksvgUnlinearizeApplySsse3vD)
TYPE(SYM(ksvgUnlinearizeApplySsse3vD), @function)
SYM(ksvgUnlinearizeApplySsse3vD):

    movl    %edx, %eax
    imull   %ecx, %eax
    movl    %eax, %r9d
    shrl    $4, %r9d
    andl    $15, %eax
    movl    %eax, %r10d

    testl   %r9d, %r9d
    jz      .L_vd_tail

    /* prologue: save callee-saved xmm8..xmm15 */
    subq    $192, %rsp
    movdqu  %xmm8,   0(%rsp)
    movdqu  %xmm9,  16(%rsp)
    movdqu  %xmm10, 32(%rsp)
    movdqu  %xmm11, 48(%rsp)
    movdqu  %xmm12, 64(%rsp)
    movdqu  %xmm13, 80(%rsp)
    movdqu  %xmm14, 96(%rsp)
    movdqu  %xmm15,112(%rsp)

.p2align 5
.L_vd_block:

    /* ------- Pass A: rows 0..7 resident in xmm8..xmm15 ------- */
    movdqu   0(%r8), %xmm8
    movdqu  16(%r8), %xmm9
    movdqu  32(%r8), %xmm10
    movdqu  48(%r8), %xmm11
    movdqu  64(%r8), %xmm12
    movdqu  80(%r8), %xmm13
    movdqu  96(%r8), %xmm14
    movdqu 112(%r8), %xmm15
    /* ---- pass A, vector 0 (rows 0..7) ---- */
    movdqu  0(%rdi), %xmm0
    movdqa  %xmm0, %xmm1
    pand    .L_vd_nibble(%rip), %xmm1
    movdqa  %xmm0, %xmm2
    psrlw   $4, %xmm2
    pand    .L_vd_nibble(%rip), %xmm2
    movdqa  %xmm0, %xmm4
    pand    .L_vd_alpha(%rip), %xmm4
    xorps   %xmm3, %xmm3
    xorps   %xmm7, %xmm7
    movdqa  %xmm8, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm9, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm10, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm11, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm12, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm13, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm14, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm15, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    movdqu  %xmm3, 128(%rsp)

    /* ---- pass A, vector 1 (rows 0..7) ---- */
    movdqu  16(%rdi), %xmm0
    movdqa  %xmm0, %xmm1
    pand    .L_vd_nibble(%rip), %xmm1
    movdqa  %xmm0, %xmm2
    psrlw   $4, %xmm2
    pand    .L_vd_nibble(%rip), %xmm2
    movdqa  %xmm0, %xmm4
    pand    .L_vd_alpha(%rip), %xmm4
    xorps   %xmm3, %xmm3
    xorps   %xmm7, %xmm7
    movdqa  %xmm8, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm9, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm10, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm11, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm12, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm13, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm14, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm15, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    movdqu  %xmm3, 144(%rsp)

    /* ---- pass A, vector 2 (rows 0..7) ---- */
    movdqu  32(%rdi), %xmm0
    movdqa  %xmm0, %xmm1
    pand    .L_vd_nibble(%rip), %xmm1
    movdqa  %xmm0, %xmm2
    psrlw   $4, %xmm2
    pand    .L_vd_nibble(%rip), %xmm2
    movdqa  %xmm0, %xmm4
    pand    .L_vd_alpha(%rip), %xmm4
    xorps   %xmm3, %xmm3
    xorps   %xmm7, %xmm7
    movdqa  %xmm8, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm9, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm10, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm11, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm12, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm13, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm14, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm15, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    movdqu  %xmm3, 160(%rsp)

    /* ---- pass A, vector 3 (rows 0..7) ---- */
    movdqu  48(%rdi), %xmm0
    movdqa  %xmm0, %xmm1
    pand    .L_vd_nibble(%rip), %xmm1
    movdqa  %xmm0, %xmm2
    psrlw   $4, %xmm2
    pand    .L_vd_nibble(%rip), %xmm2
    movdqa  %xmm0, %xmm4
    pand    .L_vd_alpha(%rip), %xmm4
    xorps   %xmm3, %xmm3
    xorps   %xmm7, %xmm7
    movdqa  %xmm8, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm9, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm10, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm11, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm12, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm13, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm14, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm15, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    movdqu  %xmm3, 176(%rsp)

    /* ------- Pass B: rows 8..15 resident ------- */
    movdqu 128(%r8), %xmm8
    movdqu 144(%r8), %xmm9
    movdqu 160(%r8), %xmm10
    movdqu 176(%r8), %xmm11
    movdqu 192(%r8), %xmm12
    movdqu 208(%r8), %xmm13
    movdqu 224(%r8), %xmm14
    movdqu 240(%r8), %xmm15

    /* ---- pass B, vector 0 (rows 8..15) ---- */
    movdqu  0(%rdi), %xmm0
    movdqa  %xmm0, %xmm1
    pand    .L_vd_nibble(%rip), %xmm1
    movdqa  %xmm0, %xmm2
    psrlw   $4, %xmm2
    pand    .L_vd_nibble(%rip), %xmm2
    movdqa  %xmm0, %xmm4
    pand    .L_vd_alpha(%rip), %xmm4
    xorps   %xmm3, %xmm3
    movdqa  .L_vd_row8(%rip), %xmm7
    movdqa  %xmm8, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm9, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm10, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm11, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm12, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm13, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm14, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm15, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    movdqu  128(%rsp), %xmm1
    por     %xmm3, %xmm1
    pand    .L_vd_rgb(%rip), %xmm1
    por     %xmm4, %xmm1
    movdqu  %xmm1, 0(%rsi)

    /* ---- pass B, vector 1 (rows 8..15) ---- */
    movdqu  16(%rdi), %xmm0
    movdqa  %xmm0, %xmm1
    pand    .L_vd_nibble(%rip), %xmm1
    movdqa  %xmm0, %xmm2
    psrlw   $4, %xmm2
    pand    .L_vd_nibble(%rip), %xmm2
    movdqa  %xmm0, %xmm4
    pand    .L_vd_alpha(%rip), %xmm4
    xorps   %xmm3, %xmm3
    movdqa  .L_vd_row8(%rip), %xmm7
    movdqa  %xmm8, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm9, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm10, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm11, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm12, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm13, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm14, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm15, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    movdqu  144(%rsp), %xmm1
    por     %xmm3, %xmm1
    pand    .L_vd_rgb(%rip), %xmm1
    por     %xmm4, %xmm1
    movdqu  %xmm1, 16(%rsi)

    /* ---- pass B, vector 2 (rows 8..15) ---- */
    movdqu  32(%rdi), %xmm0
    movdqa  %xmm0, %xmm1
    pand    .L_vd_nibble(%rip), %xmm1
    movdqa  %xmm0, %xmm2
    psrlw   $4, %xmm2
    pand    .L_vd_nibble(%rip), %xmm2
    movdqa  %xmm0, %xmm4
    pand    .L_vd_alpha(%rip), %xmm4
    xorps   %xmm3, %xmm3
    movdqa  .L_vd_row8(%rip), %xmm7
    movdqa  %xmm8, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm9, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm10, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm11, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm12, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm13, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm14, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm15, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    movdqu  160(%rsp), %xmm1
    por     %xmm3, %xmm1
    pand    .L_vd_rgb(%rip), %xmm1
    por     %xmm4, %xmm1
    movdqu  %xmm1, 32(%rsi)

    /* ---- pass B, vector 3 (rows 8..15) ---- */
    movdqu  48(%rdi), %xmm0
    movdqa  %xmm0, %xmm1
    pand    .L_vd_nibble(%rip), %xmm1
    movdqa  %xmm0, %xmm2
    psrlw   $4, %xmm2
    pand    .L_vd_nibble(%rip), %xmm2
    movdqa  %xmm0, %xmm4
    pand    .L_vd_alpha(%rip), %xmm4
    xorps   %xmm3, %xmm3
    movdqa  .L_vd_row8(%rip), %xmm7
    movdqa  %xmm8, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm9, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm10, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm11, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm12, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm13, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm14, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    paddb   .L_vd_one(%rip), %xmm7
    movdqa  %xmm15, %xmm5
    pshufb  %xmm1, %xmm5
    movdqa  %xmm2, %xmm6
    pcmpeqb %xmm7, %xmm6
    pand    %xmm6, %xmm5
    por     %xmm5, %xmm3
    movdqu  176(%rsp), %xmm1
    por     %xmm3, %xmm1
    pand    .L_vd_rgb(%rip), %xmm1
    por     %xmm4, %xmm1
    movdqu  %xmm1, 48(%rsi)


    addq    $64, %rdi
    addq    $64, %rsi
    decl    %r9d
    jnz     .L_vd_block

    /* epilogue: restore callee-saved xmm8..xmm15 */
    movdqu   0(%rsp), %xmm8
    movdqu  16(%rsp), %xmm9
    movdqu  32(%rsp), %xmm10
    movdqu  48(%rsp), %xmm11
    movdqu  64(%rsp), %xmm12
    movdqu  80(%rsp), %xmm13
    movdqu  96(%rsp), %xmm14
    movdqu 112(%rsp), %xmm15
    addq    $192, %rsp

.L_vd_tail:
    testl   %r10d, %r10d
    jz      .L_vd_done

.L_vd_tail_loop:
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
    jnz     .L_vd_tail_loop

.L_vd_done:
    ret

#ifdef __APPLE__
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 4
.L_vd_nibble:
    .byte 0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f
    .byte 0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f,0x0f
.L_vd_one:
    .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.L_vd_row8:
    .byte 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
.L_vd_rgb:
    .byte 0xff,0xff,0xff,0x00, 0xff,0xff,0xff,0x00
    .byte 0xff,0xff,0xff,0x00, 0xff,0xff,0xff,0x00
.L_vd_alpha:
    .byte 0x00,0x00,0x00,0xff, 0x00,0x00,0x00,0xff
    .byte 0x00,0x00,0x00,0xff, 0x00,0x00,0x00,0xff

.text
//// SIZE(SYM(ksvgUnlinearizeApplySsse3vD))
