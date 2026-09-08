/*
 * x86-64 SSSE3 linear -> sRGB (u8), exact corrected integer approximation.
 *
 * Fast path for four ARGB pixels at a time.
 *
 * V12 vs V10:
 *   - Aggressive register management: Eliminates all reloads of the input
 *     pixels within the loop by keeping raw input, hi/lo nibbles, and alpha
 *     in registers (xmm0, xmm1, xmm2, xmm8).
 *   - Uses all 16 XMM registers to hold constants (xmm9-xmm15) and state.
 *
 * void ksvgUnlinearizeApplySsse3(
 *     jint* src, jint* dst, jint width, jint height, const jbyte* table);
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

    movl    %edx, %eax
    imull   %ecx, %eax
    movl    %eax, %r9d
    shrl    $2, %r9d
    andl    $3, %eax
    movl    %eax, %r10d

    testl   %r9d, %r9d
    jz      .L_tail

    /* Hoist constants */
    movdqa  .L_nibble_mask(%rip), %xmm15
    movdqa  .L_alpha_mask(%rip), %xmm14
    movdqa  .L_rgb_mask(%rip), %xmm13
    movdqa  .L_rounding(%rip), %xmm12
    movdqa  .L_group_mask(%rip), %xmm11
    movdqa  .L_one_byte(%rip), %xmm10
    movdqa  .L_low3_mask(%rip), %xmm9
    pxor    %xmm14, %xmm14             /* Temporarily use xmm14 for zero during calculation if needed */

.p2align 5
.L_loop:
    movdqu  (%rdi), %xmm0              /* raw input (4 ARGB pixels) */

    /* Save alpha */
    movdqa  %xmm0, %xmm8
    pand    .L_alpha_mask(%rip), %xmm8 /* Use memory load for alpha mask to free xmm14 for zero */
    pxor    %xmm7, %xmm7               /* zero */

    /* hi/lo */
    movdqa  %xmm0, %xmm1
    psrlw   $4, %xmm1
    pand    %xmm15, %xmm1              /* hi */
    movdqa  %xmm0, %xmm2
    pand    %xmm15, %xmm2              /* lo */

    /* base/slope */
    movdqa  .L_base_lut(%rip), %xmm3
    pshufb  %xmm1, %xmm3
    movdqa  .L_slope_lut(%rip), %xmm4
    pshufb  %xmm1, %xmm4

    /* multiply s*lo */
    movdqa  %xmm4, %xmm5
    punpcklbw %xmm7, %xmm5
    movdqa  %xmm2, %xmm6
    punpcklbw %xmm7, %xmm6
    pmaddubsw %xmm6, %xmm5             /* A_low: s*lo */

    movdqa  %xmm4, %xmm6
    punpckhbw %xmm7, %xmm6
    movdqa  %xmm2, %xmm4               /* reuse xmm4 for lo_high */
    punpckhbw %xmm7, %xmm4
    pmaddubsw %xmm4, %xmm6             /* A_high: s*lo */

    /* Round and shift */
    paddw   %xmm12, %xmm5
    psrlw   $5, %xmm5
    paddw   %xmm12, %xmm6
    psrlw   $5, %xmm6

    packuswb %xmm6, %xmm5
    paddb   %xmm3, %xmm5              /* y0 */

    /* Correction bitset */
    movdqa  %xmm0, %xmm3               /* use raw input */
    psrlw   $3, %xmm3
    pand    %xmm11, %xmm3              /* group = x >> 3 */

    movdqa  %xmm3, %xmm4
    psubb   .L_group16(%rip), %xmm4
    movdqa  .L_correction_hi(%rip), %xmm6
    pshufb  %xmm4, %xmm6

    movdqa  %xmm3, %xmm4
    psrlw   $4, %xmm4
    pand    %xmm10, %xmm4
    psllw   $7, %xmm4
    por     %xmm3, %xmm4
    movdqa  .L_correction_lo(%rip), %xmm3
    pshufb  %xmm4, %xmm3
    por     %xmm6, %xmm3               /* bitset */

    /* onehot = 1 << (lo & 7) */
    movdqa  %xmm2, %xmm4
    pand    %xmm9, %xmm4
    movdqa  .L_onehot_lut(%rip), %xmm6
    pshufb  %xmm4, %xmm6
    pand    %xmm6, %xmm3
    pminub  %xmm10, %xmm3
    psubb   %xmm3, %xmm5              /* y_corr */

    /* Exact low-16 */
    movdqa  .L_exact_low16(%rip), %xmm3
    pshufb  %xmm2, %xmm3

    /* hi == 0 mask */
    pcmpeqb %xmm7, %xmm1

    pand    %xmm1, %xmm3
    pandn   %xmm5, %xmm1
    por     %xmm3, %xmm1

    /* Restore alpha */
    pand    %xmm13, %xmm1
    por     %xmm8, %xmm1

    movdqu  %xmm1, (%rsi)

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
    andl    $0xff000000, %edx
    movl    %eax, %ecx
    andl    $0xff, %ecx
    movzbl  (%r8,%rcx), %ecx
    movl    %ecx, %r11d
    shrl    $8, %eax
    andl    $0xff, %eax
    movzbl  (%r8,%rax), %eax
    shll    $8, %eax
    orl     %eax, %r11d
    movl    (%rdi), %eax
    shrl    $16, %eax
    andl    $0xff, %eax
    movzbl  (%r8,%rax), %eax
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

SIZE(SYM(ksvgUnlinearizeApplySsse3ApproxV12))

#ifdef __APPLE__
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 4
.L_exact_low16:
    .byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69
.L_base_lut:
    .byte 0,72,100,121,137,152,165,177,188,198,208,217,225,233,241,248
.L_slope_lut:
    .byte 0,58,41,31,31,27,24,22,20,19,16,15,16,16,15,16
.L_nibble_mask:
    .byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
.L_group_mask:
    .byte 31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
.L_low3_mask:
    .byte 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
.L_one_byte:
    .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.L_group16:
    .byte 16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16
.L_onehot_lut:
    .byte 1,2,4,8,16,32,64,128,1,2,4,8,16,32,64,128
.L_correction_lo:
    .byte 0,0,7,241,5,0,7,0,0,240,0,194,0,64,0,1
.L_correction_hi:
    .byte 16,0,0,0,42,0,1,0,0,0,0,168,0,80,128,170
.L_alpha_mask:
    .long 0xff000000, 0xff000000, 0xff000000, 0xff000000
.L_rgb_mask:
    .long 0x00ffffff, 0x00ffffff, 0x00ffffff, 0x00ffffff
.L_rounding:
    .short 16,16,16,16,16,16,16,16
