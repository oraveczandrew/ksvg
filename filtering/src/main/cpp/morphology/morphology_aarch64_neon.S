/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * AArch64 / AdvSIMD implementation of the interior morphology kernels.
 *
 * Row:
 *   x0 = src
 *   x1 = dst
 *   w2 = width
 *   w3 = radiusX
 *   w4 = radiusY
 *   w5 = erode (0 = dilate, non-zero = erode)
 *   w6 = y
 *   w7 = xStart
 *   [sp] = xEnd
 *   [sp+8] = scratch
 */

.text
.align 2

/* -------------------------------------------------------------------------
 * Row kernel: ksvgMorphologyApplyRowNeon64
 * ------------------------------------------------------------------------- */
.global ksvgMorphologyApplyRowNeon64
.type ksvgMorphologyApplyRowNeon64, %function

ksvgMorphologyApplyRowNeon64:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]

    /* Arguments from stack. */
    ldr     w8, [sp, #48]               // w8 = xEnd
    ldr     x19, [sp, #56]              // x19 = scratch base

    /* width=w2, radiusX=w3, radiusY=w4, erode=w5, y=w6, xStart=w7 */
    mov     w20, w5                     // w20 = erode

    /* colLo = xStart - radiusX */
    sub     w9, w7, w3

    /* colCount = (xEnd + radiusX) - colLo */
    add     w10, w8, w3
    sub     w10, w10, w9                // w10 = colCount

    /* vertical groupCount / tail */
    lsr     w11, w10, #2                // w11 = groupCount
    and     w12, w10, #3                // w12 = tailCols

    /* rowCount = 2*radiusY + 1 */
    add     w13, w4, w4
    add     w13, w13, #1                // w13 = rowCount

    /* source group cursor: x14 = &src[y-radiusY][colLo] */
    sub     w14, w6, w4                 // top = y - radiusY
    sxtw    x14, w14
    sxtw    x15, w2                     // width
    mul     x14, x14, x15
    sxtw    x15, w9                     // colLo
    add     x14, x14, x15
    lsl     x14, x14, #2
    add     x14, x0, x14                // x14 = source group cursor

    sxtw    x15, w2
    lsl     x15, x15, #2                // x15 = row stride in bytes

    cbz     w20, .L_row_dilate_vert

/* -------------------- vertical erosion -------------------- */
.L_row_erode_vert:
    mov     x16, x19                    // x16 = scratch cursor
.L_row_e_v_g:
    cbz     w11, .L_row_e_v_t
    movi    v0.16b, #0xff
    mov     x17, x14
    mov     w18, w13                    // w18 = rowCount
.L_row_e_v_g_r:
    ldr     q1, [x17]
    umin    v0.16b, v0.16b, v1.16b
    add     x17, x17, x15
    subs    w18, w18, #1
    bne     .L_row_e_v_g_r
    str     q0, [x16], #16
    add     x14, x14, #16
    subs    w11, w11, #1
    bne     .L_row_e_v_g
.L_row_e_v_t:
    cbz     w12, .L_row_horiz_e
.L_row_e_v_t_c:
    movi    v0.16b, #0xff
    mov     x17, x14
    mov     w18, w13
.L_row_e_v_t_r:
    ldr     w21, [x17]
    dup     v1.4s, w21
    umin    v0.16b, v0.16b, v1.16b
    add     x17, x17, x15
    subs    w18, w18, #1
    bne     .L_row_e_v_t_r
    st1     {v0.s}[0], [x16], #4
    add     x14, x14, #4
    subs    w12, w12, #1
    bne     .L_row_e_v_t_c
    b       .L_row_horiz_e

/* -------------------- vertical dilation -------------------- */
.L_row_dilate_vert:
    mov     x16, x19
.L_row_d_v_g:
    cbz     w11, .L_row_d_v_t
    movi    v0.16b, #0
    mov     x17, x14
    mov     w18, w13
.L_row_d_v_g_r:
    ldr     q1, [x17]
    umax    v0.16b, v0.16b, v1.16b
    add     x17, x17, x15
    subs    w18, w18, #1
    bne     .L_row_d_v_g_r
    str     q0, [x16], #16
    add     x14, x14, #16
    subs    w11, w11, #1
    bne     .L_row_d_v_g
.L_row_d_v_t:
    cbz     w12, .L_row_horiz_d
.L_row_d_v_t_c:
    movi    v0.16b, #0
    mov     x17, x14
    mov     w18, w13
.L_row_d_v_t_r:
    ldr     w21, [x17]
    dup     v1.4s, w21
    umax    v0.16b, v0.16b, v1.16b
    add     x17, x17, x15
    subs    w18, w18, #1
    bne     .L_row_d_v_t_r
    st1     {v0.s}[0], [x16], #4
    add     x14, x14, #4
    subs    w12, w12, #1
    bne     .L_row_d_v_t_c

/* -------------------- horizontal stage -------------------- */
.L_row_horiz_d:
    /* outputCount = xEnd - xStart */
    ldr     w8, [sp, #48]
    sub     w10, w8, w7                 // w10 = outputCount
    cbz     w10, .L_done

    /* dst cursor = &dst[y][xStart] */
    sxtw    x8, w6                      // y
    sxtw    x9, w2                      // width
    mul     x8, x8, x9
    sxtw    x9, w7                      // xStart
    add     x8, x8, x9
    lsl     x8, x8, #2
    add     x16, x1, x8                 // x16 = dst cursor

    /* L = 2*radiusX + 1 */
    add     w11, w3, w3
    add     w11, w11, #1                // w11 = L
    lsr     w12, w11, #2                // w12 = vectorCount (L / 4)
    and     w13, w11, #3                // w13 = tailCount (L % 4)

    mov     x17, x19                    // x17 = window scratch cursor
.L_row_h_d_px:
    movi    v0.16b, #0
    mov     x18, x17
    mov     w21, w12                    // w21 = vectorCount
    cbz     w21, .L_row_h_d_t
.L_row_h_d_v:
    ldr     q1, [x18], #16
    umax    v0.16b, v0.16b, v1.16b
    subs    w21, w21, #1
    bne     .L_row_h_d_v
.L_row_h_d_t:
    cbz     w13, .L_row_h_d_p
    tbz     w13, #1, .L_row_h_d_t1
    ld1     {v1.8b}, [x18], #8
    umax    v0.16b, v0.16b, v1.16b
    tbz     w13, #0, .L_row_h_d_p
.L_row_h_d_t1:
    ldr     w21, [x18]
    dup     v1.4s, w21
    umax    v0.16b, v0.16b, v1.16b
.L_row_h_d_p:
    ext     v1.16b, v0.16b, v0.16b, #8
    umax    v0.16b, v0.16b, v1.16b
    ext     v1.16b, v0.16b, v0.16b, #4
    umax    v0.16b, v0.16b, v1.16b
    str     s0, [x16], #4
    add     x17, x17, #4
    subs    w10, w10, #1
    bne     .L_row_h_d_px
    b       .L_done

.L_row_horiz_e:
    ldr     w8, [sp, #48]
    sub     w10, w8, w7
    cbz     w10, .L_done

    sxtw    x8, w6
    sxtw    x9, w2
    mul     x8, x8, x9
    sxtw    x9, w7
    add     x8, x8, x9
    lsl     x8, x8, #2
    add     x16, x1, x8

    add     w11, w3, w3
    add     w11, w11, #1
    lsr     w12, w11, #2
    and     w13, w11, #3

    mov     x17, x19
.L_row_h_e_px:
    movi    v0.16b, #0xff
    mov     x18, x17
    mov     w21, w12
    cbz     w21, .L_row_h_e_t
.L_row_h_e_v:
    ldr     q1, [x18], #16
    umin    v0.16b, v0.16b, v1.16b
    subs    w21, w21, #1
    bne     .L_row_h_e_v
.L_row_h_e_t:
    cbz     w13, .L_row_h_e_p
    tbz     w13, #1, .L_row_h_e_t1
    movi    v1.16b, #0xff
    ld1     {v1.d}[0], [x18], #8
    umin    v0.16b, v0.16b, v1.16b
    tbz     w13, #0, .L_row_h_e_p
.L_row_h_e_t1:
    ldr     w21, [x18]
    dup     v1.4s, w21
    umin    v0.16b, v0.16b, v1.16b
.L_row_h_e_p:
    ext     v1.16b, v0.16b, v0.16b, #8
    umin    v0.16b, v0.16b, v1.16b
    ext     v1.16b, v0.16b, v0.16b, #4
    umin    v0.16b, v0.16b, v1.16b
    str     s0, [x16], #4
    add     x17, x17, #4
    subs    w10, w10, #1
    bne     .L_row_h_e_px

.L_done:
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

.size ksvgMorphologyApplyRowNeon64, .-ksvgMorphologyApplyRowNeon64
