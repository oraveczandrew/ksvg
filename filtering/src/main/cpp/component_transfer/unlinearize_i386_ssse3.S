/* i386 SSSE3 sRGB unlinearize.
 * Exact 8-bit result using 16-segment integer approximation + correction.
 * V31: PIC/no-text-rel local constants, fused base term; fixed tail table argument offset.
 */
#include "asm_macros.S"


.text
.p2align 5
.globl SYM(ksvgUnlinearizeApplySsse3ApproxV31)
TYPE(SYM(ksvgUnlinearizeApplySsse3ApproxV31), @function)
SYM(ksvgUnlinearizeApplySsse3ApproxV31):
    pushl   %ebp
    pushl   %ebx
    pushl   %esi
    pushl   %edi

    # EIP-relative base for local constants; no R_386_32 relocations.
    call    1f
1:  popl    %ebp

    movl    20(%esp), %esi
    movl    24(%esp), %edi
    movl    28(%esp), %eax
    imull   32(%esp), %eax
    movl    %eax, %ebx
    shrl    $2, %ebx
    andl    $3, %eax
    movl    %eax, %ecx

    pxor    %xmm7, %xmm7
    testl   %ebx, %ebx
    jz      .L_tail

.p2align 5
.L_loop:
    movdqu  (%esi), %xmm0

    # hi = x >> 4, lo = x & 15
    movdqa  %xmm0, %xmm1
    psrlw   $4, %xmm1
    pand    (.L_nibble_mask-1b)(%ebp), %xmm1
    movdqa  %xmm0, %xmm2
    pand    (.L_nibble_mask-1b)(%ebp), %xmm2

    # base[hi], slope[hi]
    movdqa  (.L_base_lut-1b)(%ebp), %xmm3
    pshufb  %xmm1, %xmm3
    movdqa  (.L_slope_lut-1b)(%ebp), %xmm4
    pshufb  %xmm1, %xmm4

    # (slope * lo + base * 32 + 16) >> 5
    # Interleave [slope, base] with [lo, 32].
    movdqa  %xmm4, %xmm5
    punpcklbw %xmm3, %xmm5
    movdqa  %xmm2, %xmm6
    punpcklbw (.L_const32-1b)(%ebp), %xmm6
    pmaddubsw %xmm6, %xmm5

    movdqa  %xmm4, %xmm6
    punpckhbw %xmm3, %xmm6
    movdqa  %xmm2, %xmm4
    punpckhbw (.L_const32-1b)(%ebp), %xmm4
    pmaddubsw %xmm4, %xmm6

    paddw   (.L_rounding-1b)(%ebp), %xmm5
    psrlw   $5, %xmm5
    paddw   (.L_rounding-1b)(%ebp), %xmm6
    psrlw   $5, %xmm6
    packuswb %xmm6, %xmm5

    # approximation is reference + correction, where correction is 0/1
    # correction bitsets: low segments h=0..7, high segments h=8..15
    movdqa  %xmm1, %xmm7
    pcmpgtb (.L_hi7-1b)(%ebp), %xmm7          # 0xff when hi >= 8

    movdqa  (.L_corr_lo-1b)(%ebp), %xmm4
    pshufb  %xmm2, %xmm4
    movdqa  (.L_corr_xor-1b)(%ebp), %xmm6
    pshufb  %xmm2, %xmm6
    pand    %xmm7, %xmm6
    pxor    %xmm6, %xmm4           # selected corr bitset

    movdqa  (.L_onehot_hi-1b)(%ebp), %xmm6
    pshufb  %xmm1, %xmm6
    pand    %xmm6, %xmm4
    pminub  (.L_one_byte-1b)(%ebp), %xmm4
    psubb   %xmm4, %xmm5

    # Exact reference for x < 16.
    pxor    %xmm7, %xmm7
    movdqa  (.L_exact_low16-1b)(%ebp), %xmm3
    pshufb  %xmm2, %xmm3
    pcmpeqb %xmm7, %xmm1
    pand    %xmm1, %xmm3
    pandn   %xmm5, %xmm1
    por     %xmm3, %xmm1

    # preserve alpha
    pand    (.L_alpha_mask-1b)(%ebp), %xmm0
    pand    (.L_rgb_mask-1b)(%ebp), %xmm1
    por     %xmm0, %xmm1
    movdqu  %xmm1, (%edi)

    addl    $16, %esi
    addl    $16, %edi
    decl    %ebx
    jnz     .L_loop

.L_tail:
    testl   %ecx, %ecx
    jz      .L_done
.L_tail_loop:
    movl    (%esi), %eax
    movl    %eax, %edx
    andl    $0xff000000, %edx
    movl    %eax, %ebx
    andl    $0xff, %ebx
    movzbl  (.L_unlinearize_lut-1b)(%ebp,%ebx,1), %ebx
    movl    %ebx, %eax
    movl    (%esi), %ebx
    shrl    $8, %ebx
    andl    $0xff, %ebx
    movzbl  (.L_unlinearize_lut-1b)(%ebp,%ebx,1), %ebx
    shll    $8, %ebx
    orl     %ebx, %eax
    movl    (%esi), %ebx
    shrl    $16, %ebx
    andl    $0xff, %ebx
    movzbl  (.L_unlinearize_lut-1b)(%ebp,%ebx,1), %ebx
    shll    $16, %ebx
    orl     %ebx, %eax
    orl     %edx, %eax
    movl    %eax, (%edi)
    addl    $4, %esi
    addl    $4, %edi
    decl    %ecx
    jnz     .L_tail_loop
.L_done:
    popl    %edi
    popl    %esi
    popl    %ebx
    popl    %ebp
    ret
SIZE(SYM(ksvgUnlinearizeApplySsse3ApproxV31))

.p2align 4
.L_unlinearize_lut:
    .byte 0, 13, 22, 28, 34, 38, 42, 46, 50, 53, 56, 59, 61, 64, 66, 69
    .byte 71, 73, 75, 77, 79, 81, 83, 85, 86, 88, 90, 92, 93, 95, 96, 98
    .byte 99, 101, 102, 104, 105, 106, 108, 109, 110, 112, 113, 114, 115, 117, 118, 119
    .byte 120, 121, 122, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136
    .byte 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 148, 149, 150, 151
    .byte 152, 153, 154, 155, 155, 156, 157, 158, 159, 159, 160, 161, 162, 163, 163, 164
    .byte 165, 166, 167, 167, 168, 169, 170, 170, 171, 172, 173, 173, 174, 175, 175, 176
    .byte 177, 178, 178, 179, 180, 180, 181, 182, 182, 183, 184, 185, 185, 186, 187, 187
    .byte 188, 189, 189, 190, 190, 191, 192, 192, 193, 194, 194, 195, 196, 196, 197, 197
    .byte 198, 199, 199, 200, 200, 201, 202, 202, 203, 203, 204, 205, 205, 206, 206, 207
    .byte 208, 208, 209, 209, 210, 210, 211, 212, 212, 213, 213, 214, 214, 215, 215, 216
    .byte 216, 217, 218, 218, 219, 219, 220, 220, 221, 221, 222, 222, 223, 223, 224, 224
    .byte 225, 226, 226, 227, 227, 228, 228, 229, 229, 230, 230, 231, 231, 232, 232, 233
    .byte 233, 234, 234, 235, 235, 236, 236, 237, 237, 238, 238, 238, 239, 239, 240, 240
    .byte 241, 241, 242, 242, 243, 243, 244, 244, 245, 245, 246, 246, 246, 247, 247, 248
    .byte 248, 249, 249, 250, 250, 251, 251, 251, 252, 252, 253, 253, 254, 254, 255, 255

.text
.p2align 4
.L_exact_low16:
    .byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69
.L_base_lut:
    .byte 0,72,100,121,137,152,165,177,188,198,208,217,225,234,241,249
.L_slope_lut:
    .byte 0,58,41,31,31,27,24,22,20,19,16,15,16,13,15,13
.L_const32:
    .rept 16
    .byte 32
    .endr
.L_nibble_mask:
    .rept 16
    .byte 15
    .endr
.L_hi7:
    .rept 16
    .byte 7
    .endr
.L_one_byte:
    .rept 16
    .byte 1
    .endr
.L_onehot_hi:
    .byte 1,2,4,8,16,32,64,128,1,2,4,8,16,32,64,128
.L_corr_lo:
    .byte 14,10,14,0,0,0,0,0,130,32,0,0,18,18,114,50
.L_corr_xor:
    .byte 166,14,174,4,161,4,0,128,130,160,0,0,82,18,50,50
.L_alpha_mask:
    .long 0xff000000,0xff000000,0xff000000,0xff000000
.L_rgb_mask:
    .long 0x00ffffff,0x00ffffff,0x00ffffff,0x00ffffff
.L_rounding:
    .short 16,16,16,16,16,16,16,16
