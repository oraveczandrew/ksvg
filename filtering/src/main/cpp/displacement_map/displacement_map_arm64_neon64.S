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
.align 2

/*
 * void ksvgDisplacementMapApplyNeon64(
 *     const int32_t* src, const int32_t* map, int32_t* dst,
 *     int width, int height, float scale, int xChannel, int yChannel);
 *
 * AArch64 ABI:
 *   x0 = src, x1 = map, x2 = dst
 *   w3 = width, w4 = height
 *   s0 = scale
 *   w5 = xChannel, w6 = yChannel
 *
 * The dispatcher is cold; the 16 specialized kernels make the channel shifts
 * compile-time constants, matching the C++ template specialization.
 */

.global SYM(ksvgDisplacementMapApplyNeon64)
TYPE(SYM(ksvgDisplacementMapApplyNeon64), %function)
    SYM(ksvgDisplacementMapApplyNeon64):
    and     w7, w5, #3
    lsl     w7, w7, #2
    and     w6, w6, #3
    orr     w7, w7, w6
    /* 32-bit PC-relative offsets keep the table PIC-safe (a shared lib may
    not     carry R_AARCH64_ABS64). Slot byte offset = (xc&3)<<2 | (yc&3). */
    adr     x8, .Ldispatch
    ldr     w9, [x8, w7, uxtw #2]
    add     x8, x8, w9, sxtw
    br      x8
   // SIZE(SYM(ksvgDisplacementMapApplyNeon64))

.macro DEFINE_KERNEL name, xshift, yshift
    .global SYM(\name)
    TYPE(SYM(\name), %function)
    SYM(\name):
    cbz     w3, .Lret_\name
    cbz     w4, .Lret_\name
    /* Constants / invariants. */
    dup     v0.4s, v0.s[0]  // scale
    fmov    v1.4s, #0.5
    ldr     q2, .Lfloat255
    movi    v3.4s, #255
    ldr     q4, .Lincrements
    movi    v5.4s, #4

    sub     w21, w3, #1
    sub     w22, w4, #1
    dup     v17.4s, w21  // width - 1
    dup     v18.4s, w22  // height - 1
    movi    v19.4s, #0

    and     w20, w3, #~3  // largest multiple of 4
    mov     w11, w4  // rows remaining
    mov     w12, wzr  // y
    mov     x9, x1  // current map row pointer
    mov     x10, x2  // current dst row pointer

.Lrow_\name:
    mov     w13, wzr  // x
    dup     v6.4s, w12  // y, y, y, y
    dup     v7.4s, w13  // x, x, x, x
    add     v7.4s, v7.4s, v4.4s  // x..x+3

.Lvec_\name:
    cmp     w13, w20
    b.ge    .Ltail_\name

    ld1     {v8.4s}, [x9], #16

    .if \xshift == 0
    mov     v9.16b, v8.16b
    and     v9.16b, v9.16b, v3.16b
    .else
    ushr    v9.4s, v8.4s, #\xshift
    and     v9.16b, v9.16b, v3.16b
    .endif
    .if \yshift == 0
    mov     v10.16b, v8.16b
    and     v10.16b, v10.16b, v3.16b
    .else
    ushr    v10.4s, v8.4s, #\yshift
    and     v10.16b, v10.16b, v3.16b
    .endif

    ucvtf   v11.4s, v9.4s
    ucvtf   v12.4s, v10.4s
    fdiv    v11.4s, v11.4s, v2.4s
    fdiv    v12.4s, v12.4s, v2.4s

    fsub    v13.4s, v11.4s, v1.4s
    fmul    v13.4s, v13.4s, v0.4s
    fcvtzs  v13.4s, v13.4s

    fsub    v14.4s, v12.4s, v1.4s
    fmul    v14.4s, v14.4s, v0.4s
    fcvtzs  v14.4s, v14.4s

    add     v15.4s, v7.4s, v13.4s
    smin    v15.4s, v15.4s, v17.4s
    smax    v15.4s, v15.4s, v19.4s

    add     v16.4s, v6.4s, v14.4s
    smin    v16.4s, v16.4s, v18.4s
    smax    v16.4s, v16.4s, v19.4s

    /* Lane 0: compute sy * width + sx, scalar gather, scalar store. */
    umov    w14, v15.s[0]
    umov    w15, v16.s[0]
    madd    w16, w15, w3, w14
    ldr     w17, [x0, w16, uxtw #2]
    str     w17, [x10], #4

    /* Lane 1. */
    umov    w14, v15.s[1]
    umov    w15, v16.s[1]
    madd    w16, w15, w3, w14
    ldr     w17, [x0, w16, uxtw #2]
    str     w17, [x10], #4

    /* Lane 2. */
    umov    w14, v15.s[2]
    umov    w15, v16.s[2]
    madd    w16, w15, w3, w14
    ldr     w17, [x0, w16, uxtw #2]
    str     w17, [x10], #4

    /* Lane 3. */
    umov    w14, v15.s[3]
    umov    w15, v16.s[3]
    madd    w16, w15, w3, w14
    ldr     w17, [x0, w16, uxtw #2]
    str     w17, [x10], #4

    add     w13, w13, #4
    add     v7.4s, v7.4s, v5.4s
    b       .Lvec_\name

.Ltail_\name:
    cmp     w13, w3
    b.ge    .Lrow_done_\name

.Lscalar_\name:
    ldr     w8, [x9], #4

    lsr     w14, w8, #\xshift
    and     w14, w14, #255
    ucvtf   s14, w14
    fdiv    s14, s14, s2
    fsub    s14, s14, s1
    fmul    s14, s14, s0
    fcvtzs  w14, s14
    add     w14, w14, w13
    cmp     w14, wzr
    csel    w14, wzr, w14, lt
    cmp     w14, w3
    csel    w14, w21, w14, ge

    lsr     w15, w8, #\yshift
    and     w15, w15, #255
    ucvtf   s15, w15
    fdiv    s15, s15, s2
    fsub    s15, s15, s1
    fmul    s15, s15, s0
    fcvtzs  w15, s15
    add     w15, w15, w12
    cmp     w15, wzr
    csel    w15, wzr, w15, lt
    cmp     w15, w4
    csel    w15, w22, w15, ge

    madd    w16, w15, w3, w14
    ldr     w17, [x0, w16, uxtw #2]
    str     w17, [x10], #4

    add     w13, w13, #1
    cmp     w13, w3
    b.lt    .Lscalar_\name

.Lrow_done_\name:
    subs    w11, w11, #1
    add     w12, w12, #1
    b.ne    .Lrow_\name

    ret

.Lret_\name:
    ret
   // SIZE(SYM(\name))
.endm

    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_RR, 16, 16
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_RG, 16, 8
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_RB, 16, 0
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_RA, 16, 24

    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_GR, 8, 16
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_GG, 8, 8
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_GB, 8, 0
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_GA, 8, 24

    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_BR, 0, 16
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_BG, 0, 8
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_BB, 0, 0
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_BA, 0, 24

    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_AR, 24, 16
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_AG, 24, 8
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_AB, 24, 0
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon64_AA, 24, 24

.align 2
.Ldispatch:
.word SYM(ksvgDisplacementMapApplyNeon64_RR) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_RG) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_RB) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_RA) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_GR) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_GG) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_GB) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_GA) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_BR) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_BG) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_BB) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_BA) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_AR) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_AG) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_AB) - .Ldispatch
.word SYM(ksvgDisplacementMapApplyNeon64_AA) - .Ldispatch

.align 2
.Lfloat255:
.word 0x437f0000, 0x437f0000, 0x437f0000, 0x437f0000

.align 2
.Lincrements:
.word 0, 1, 2, 3
GNU_STACK
