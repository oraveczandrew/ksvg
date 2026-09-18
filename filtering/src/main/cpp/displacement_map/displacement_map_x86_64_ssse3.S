/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "asm_macros.S"

.text
.intel_syntax noprefix

/*
 * void ksvgDisplacementMapApplySsse3(
 *     const jint* src, const jint* map, jint* dst, jint width, jint height,
 *     jfloat scale, jint xChannel, jint yChannel);
 *
 * x86-64 System V ABI:
 *   rdi = src, rsi = map, rdx = dst, ecx = width, r8d = height
 *   xmm0 = scale, r9d = xChannel
 *   stack: yChannel ([rsp+8] at entry)
 */
.globl SYM(ksvgDisplacementMapApplySsse3)
TYPE(SYM(ksvgDisplacementMapApplySsse3), @function)
SYM(ksvgDisplacementMapApplySsse3):
    cmp     r9d, 3
    ja      .Lbad
    mov     eax, DWORD PTR [rsp+8]
    cmp     eax, 3
    ja      .Lbad
    lea     eax, [rax+r9*4]
    lea     r10, [rip+.Ldm_jt]
    movsxd  rax, DWORD PTR [r10+rax*4]
    add     rax, r10
    jmp     rax

.Lbad:
    ret

/*
 * Four map pixels are decoded with PSHUFB. The masks extract the selected
 * RGBA byte from each dword and zero the remaining bytes, yielding four
 * dword channel values for CVTDQ2PS.
 */
.macro KERNEL LABEL, XMASK, YMASK, XSHIFT, YSHIFT
.p2align 4
\LABEL:
    test    ecx, ecx
    jle     .Ldone_\@
    test    r8d, r8d
    jle     .Ldone_\@

    movaps  xmm7, xmm0
    shufps  xmm7, xmm7, 0
    xor     r10d, r10d

.Lrow_\@:
    xor     r11d, r11d

.Lvec_\@:
    lea     eax, [r11d+4]
    cmp     eax, ecx
    jg      .Ltail_\@

    movdqu  xmm0, XMMWORD PTR [rsi]

    /* dx = (int)(scale * ((xChannel / 255.0f) - 0.5f)). */
    movdqa  xmm1, xmm0
    pshufb  xmm1, XMMWORD PTR [rip+\XMASK]
    cvtdq2ps xmm1, xmm1
    divps   xmm1, XMMWORD PTR [rip+.Ldm_255v]
    subps   xmm1, XMMWORD PTR [rip+.Ldm_halfv]
    mulps   xmm1, xmm7
    cvttps2dq xmm1, xmm1

    /* dy = (int)(scale * ((yChannel / 255.0f) - 0.5f)). */
    movdqa  xmm2, xmm0
    pshufb  xmm2, XMMWORD PTR [rip+\YMASK]
    cvtdq2ps xmm2, xmm2
    divps   xmm2, XMMWORD PTR [rip+.Ldm_255v]
    subps   xmm2, XMMWORD PTR [rip+.Ldm_halfv]
    mulps   xmm2, xmm7
    cvttps2dq xmm2, xmm2

    /* sx = clamp(x + dx, 0, width - 1). */
    movd    xmm4, r11d
    pshufd  xmm4, xmm4, 0
    paddd   xmm4, XMMWORD PTR [rip+.Ldm_inc4]
    paddd   xmm4, xmm1

    movd    xmm3, ecx
    pshufd  xmm3, xmm3, 0
    psubd   xmm3, XMMWORD PTR [rip+.Ldm_one4]

    movdqa  xmm5, xmm4
    pcmpgtd xmm5, xmm3
    pand    xmm3, xmm5
    pandn   xmm5, xmm4
    por     xmm3, xmm5

    pxor    xmm5, xmm5
    pcmpgtd xmm5, xmm3
    pandn   xmm5, xmm3
    movdqa  xmm6, xmm5

    /* sy = clamp(y + dy, 0, height - 1). */
    movd    xmm5, r10d
    pshufd  xmm5, xmm5, 0
    paddd   xmm5, xmm2

    movd    xmm3, r8d
    pshufd  xmm3, xmm3, 0
    psubd   xmm3, XMMWORD PTR [rip+.Ldm_one4]

    movdqa  xmm4, xmm5
    pcmpgtd xmm4, xmm3
    pand    xmm3, xmm4
    pandn   xmm4, xmm5
    por     xmm3, xmm4

    pxor    xmm4, xmm4
    pcmpgtd xmm4, xmm3
    pandn   xmm4, xmm3

    /* Four scalar source gathers. SSSE3 has no integer gather instruction. */
    movd    eax, xmm4
    movd    r9d, xmm6
    imul    eax, ecx
    add     eax, r9d
    mov     eax, DWORD PTR [rdi+rax*4]
    mov     DWORD PTR [rdx], eax

    pshufd  xmm0, xmm4, 1
    pshufd  xmm1, xmm6, 1
    movd    eax, xmm0
    movd    r9d, xmm1
    imul    eax, ecx
    add     eax, r9d
    mov     eax, DWORD PTR [rdi+rax*4]
    mov     DWORD PTR [rdx+4], eax

    pshufd  xmm0, xmm4, 2
    pshufd  xmm1, xmm6, 2
    movd    eax, xmm0
    movd    r9d, xmm1
    imul    eax, ecx
    add     eax, r9d
    mov     eax, DWORD PTR [rdi+rax*4]
    mov     DWORD PTR [rdx+8], eax

    pshufd  xmm0, xmm4, 3
    pshufd  xmm1, xmm6, 3
    movd    eax, xmm0
    movd    r9d, xmm1
    imul    eax, ecx
    add     eax, r9d
    mov     eax, DWORD PTR [rdi+rax*4]
    mov     DWORD PTR [rdx+12], eax

    add     r11d, 4
    add     rsi, 16
    add     rdx, 16
    jmp     .Lvec_\@

.Ltail_\@:
    cmp     r11d, ecx
    jge     .Lnextrow_\@

.Ltail_pixel_\@:
    mov     eax, DWORD PTR [rsi]

    /* dx */
    mov     r9d, eax
    shr     r9d, \XSHIFT
    and     r9d, 255
    cvtsi2ss xmm0, r9d
    divss   xmm0, DWORD PTR [rip+.Ldm_255s]
    subss   xmm0, DWORD PTR [rip+.Ldm_halfs]
    mulss   xmm0, xmm7
    cvttss2si r9d, xmm0

    /* dy */
    mov     eax, DWORD PTR [rsi]
    shr     eax, \YSHIFT
    and     eax, 255
    cvtsi2ss xmm0, eax
    divss   xmm0, DWORD PTR [rip+.Ldm_255s]
    subss   xmm0, DWORD PTR [rip+.Ldm_halfs]
    mulss   xmm0, xmm7
    cvttss2si eax, xmm0

    /* sx = clamp(x + dx, 0, width - 1). */
    add     r9d, r11d
    test    r9d, r9d
    jns     .Lsx_nonneg_\@
    xor     r9d, r9d
.Lsx_nonneg_\@:
    cmp     r9d, ecx
    jl      .Lsx_ok_\@
    lea     r9d, [ecx-1]
.Lsx_ok_\@:

    /* sy = clamp(y + dy, 0, height - 1). */
    add     eax, r10d
    test    eax, eax
    jns     .Lsy_nonneg_\@
    xor     eax, eax
.Lsy_nonneg_\@:
    cmp     eax, r8d
    jl      .Lsy_ok_\@
    lea     eax, [r8d-1]
.Lsy_ok_\@:

    imul    eax, ecx
    add     eax, r9d
    mov     eax, DWORD PTR [rdi+rax*4]
    mov     DWORD PTR [rdx], eax

    inc     r11d
    add     rsi, 4
    add     rdx, 4
    cmp     r11d, ecx
    jl      .Ltail_pixel_\@

.Lnextrow_\@:
    inc     r10d
    cmp     r10d, r8d
    jl      .Lrow_\@

.Ldone_\@:
    ret
.endm

.macro KENTRY LABEL, XMASK, YMASK, XSHIFT, YSHIFT
    .long  \LABEL-.Ldm_jt
.endm

    // ARGB_8888 channel layout (little-endian byte order): 0=R(byte 2, shift 16),
    // 1=G(byte 1, shift 8), 2=B(byte 0, shift 0), 3=A(byte 3, shift 24).
    // Row = xChannel, column = yChannel (index = y + 4*x).
    KERNEL .Ldm_k00, .Ldm_mask_c2, .Ldm_mask_c2, 16, 16
    KERNEL .Ldm_k01, .Ldm_mask_c2, .Ldm_mask_c1, 16, 8
    KERNEL .Ldm_k02, .Ldm_mask_c2, .Ldm_mask_c0, 16, 0
    KERNEL .Ldm_k03, .Ldm_mask_c2, .Ldm_mask_c3, 16, 24
    KERNEL .Ldm_k04, .Ldm_mask_c1, .Ldm_mask_c2, 8, 16
    KERNEL .Ldm_k05, .Ldm_mask_c1, .Ldm_mask_c1, 8, 8
    KERNEL .Ldm_k06, .Ldm_mask_c1, .Ldm_mask_c0, 8, 0
    KERNEL .Ldm_k07, .Ldm_mask_c1, .Ldm_mask_c3, 8, 24
    KERNEL .Ldm_k08, .Ldm_mask_c0, .Ldm_mask_c2, 0, 16
    KERNEL .Ldm_k09, .Ldm_mask_c0, .Ldm_mask_c1, 0, 8
    KERNEL .Ldm_k10, .Ldm_mask_c0, .Ldm_mask_c0, 0, 0
    KERNEL .Ldm_k11, .Ldm_mask_c0, .Ldm_mask_c3, 0, 24
    KERNEL .Ldm_k12, .Ldm_mask_c3, .Ldm_mask_c2, 24, 16
    KERNEL .Ldm_k13, .Ldm_mask_c3, .Ldm_mask_c1, 24, 8
    KERNEL .Ldm_k14, .Ldm_mask_c3, .Ldm_mask_c0, 24, 0
    KERNEL .Ldm_k15, .Ldm_mask_c3, .Ldm_mask_c3, 24, 24

.p2align 2
.Ldm_jt:
.long .Ldm_k00-.Ldm_jt, .Ldm_k01-.Ldm_jt, .Ldm_k02-.Ldm_jt, .Ldm_k03-.Ldm_jt
.long .Ldm_k04-.Ldm_jt, .Ldm_k05-.Ldm_jt, .Ldm_k06-.Ldm_jt, .Ldm_k07-.Ldm_jt
.long .Ldm_k08-.Ldm_jt, .Ldm_k09-.Ldm_jt, .Ldm_k10-.Ldm_jt, .Ldm_k11-.Ldm_jt
.long .Ldm_k12-.Ldm_jt, .Ldm_k13-.Ldm_jt, .Ldm_k14-.Ldm_jt, .Ldm_k15-.Ldm_jt

.p2align 4
.Ldm_mask_c0:
.byte 0, 0x80, 0x80, 0x80, 4, 0x80, 0x80, 0x80, 8, 0x80, 0x80, 0x80, 12, 0x80, 0x80, 0x80
.Ldm_mask_c1:
.byte 1, 0x80, 0x80, 0x80, 5, 0x80, 0x80, 0x80, 9, 0x80, 0x80, 0x80, 13, 0x80, 0x80, 0x80
.Ldm_mask_c2:
.byte 2, 0x80, 0x80, 0x80, 6, 0x80, 0x80, 0x80, 10, 0x80, 0x80, 0x80, 14, 0x80, 0x80, 0x80
.Ldm_mask_c3:
.byte 3, 0x80, 0x80, 0x80, 7, 0x80, 0x80, 0x80, 11, 0x80, 0x80, 0x80, 15, 0x80, 0x80, 0x80
.Ldm_inc4:
.long 0, 1, 2, 3
.Ldm_one4:
.long 1, 1, 1, 1
.Ldm_255v:
.float 255.0, 255.0, 255.0, 255.0
.Ldm_halfv:
.float 0.5, 0.5, 0.5, 0.5
.Ldm_255s:
.float 255.0
.Ldm_halfs:
.float 0.5
