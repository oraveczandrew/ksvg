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
 * AArch64 / AdvSIMD implementation of the interior morphology pixel.
 *
 * C++ ABI:
 *   void ksvgMorphologyApplyPixelNeon64(
 *       const jint *src, jint *dst,
 *       jint width, jint radiusX, jint radiusY,
 *       jboolean erode, jint x, jint y);
 *
 * AArch64 arguments:
 *   x0 = src
 *   x1 = dst
 *   w2 = width
 *   w3 = radiusX
 *   w4 = radiusY
 *   w5 = erode (0 = dilate, non-zero = erode)
 *   w6 = x
 *   w7 = y
 *
 * Preconditions (same as applyVectorPixel in morphology.cpp):
 *   - the complete kernel is inside the image
 *   - radiusX/radiusY >= 0
 *   - x/y are valid output coordinates
 *
 * Pixel representation is the native jint ARGB_8888 layout used by the
 * existing C++ code. On little-endian AArch64 the bytes are:
 *
 *   B G R A | B G R A | ...
 *
 * Every 16-byte load therefore contains four complete pixels, and every
 * byte lane always represents the same color channel across all loads.
 */

.text
.align 2
.global ksvgMorphologyApplyPixelNeon64
.type ksvgMorphologyApplyPixelNeon64, %function

ksvgMorphologyApplyPixelNeon64:
    /* -------------------------------------------------------------
     * Geometry.
     * ------------------------------------------------------------- */
    sub     w8, w7, w4                  // top = y - radiusY
    sub     w9, w6, w3                  // left = x - radiusX

    add     w10, w4, w4
    add     w10, w10, #1                // rowCount = 2*radiusY + 1

    add     w11, w6, w3                 // right = x + radiusX
    sub     w12, w11, w9
    add     w12, w12, #1                // pixelCount = 2*radiusX + 1

    lsr     w13, w12, #2                // vectorCount = pixelCount / 4

    /*
     * x15 = pointer to src[top][left]
     * x16 = pointer to dst[y][x]
     * x17 = row stride in bytes
     */
    sxtw    x8, w8
    sxtw    x11, w2
    mul     x8, x8, x11
    sxtw    x11, w9
    add     x8, x8, x11
    lsl     x8, x8, #2
    add     x15, x0, x8

    sxtw    x8, w7
    sxtw    x11, w2
    mul     x8, x8, x11
    sxtw    x11, w6
    add     x8, x8, x11
    lsl     x8, x8, #2
    add     x16, x1, x8

    sxtw    x17, w2
    lsl     x17, x17, #2               // row stride in bytes

    /* No tail counter at all: pixelCount is always odd (2*radiusX + 1), so
     * the tail after the 4-pixel vector loop is either 1 or 3 pixels. The
     * straight-line tail below tests bit 1 of w12 and unrolls accordingly,
     * which also removes the possibility of a counter/cursor register clash
     * (x14 is the per-row pixel cursor and stays out of the tail math). */

    /* Branch once: do not maintain both min and max accumulators. */
    cbnz    w5, .L_erode

/* ---------------------------------------------------------------------
 * Dilation: byte-wise maximum over the complete kernel.
 *
 * The vector loop consumes pixelCount & ~3 pixels; the tail is always
 * 1 or 3 pixels because pixelCount = 2*radiusX + 1 is odd.
 * --------------------------------------------------------------------- */
.L_dilate:
    movi    v0.16b, #0

.L_dilate_row:
    mov     x14, x15
    cbz     w13, .L_dilate_tail        // pixelCount < 4: no vector work
    mov     w8, w13                    // vector loop counter
    movi    v1.16b, #0
    movi    v6.16b, #0
    movi    v7.16b, #0

.L_dilate_vec:
    /* 4-way unroll into four independent max chains (v0,v1,v6,v7). */
    cmp     w8, #4
    b.lo    .L_dilate_resid
    ld1     {v2.16b}, [x14], #16
    ld1     {v3.16b}, [x14], #16
    ld1     {v4.16b}, [x14], #16
    ld1     {v5.16b}, [x14], #16
    umax    v0.16b, v0.16b, v2.16b
    umax    v1.16b, v1.16b, v3.16b
    umax    v6.16b, v6.16b, v4.16b
    umax    v7.16b, v7.16b, v5.16b
    sub     w8, w8, #4
    cmp     w8, #4
    b.hs    .L_dilate_vec
    cbz     w8, .L_dilate_combine

.L_dilate_resid:
    /* w8 in 1..3 vector groups: up to two chains. */
    cmp     w8, #2
    b.lo    .L_dilate_resid1
    ld1     {v2.16b}, [x14], #16
    ld1     {v3.16b}, [x14], #16
    umax    v0.16b, v0.16b, v2.16b
    umax    v1.16b, v1.16b, v3.16b
    sub     w8, w8, #2
    cbz     w8, .L_dilate_combine

.L_dilate_resid1:
    ld1     {v2.16b}, [x14], #16
    umax    v0.16b, v0.16b, v2.16b

.L_dilate_combine:
    umax    v0.16b, v0.16b, v1.16b
    umax    v6.16b, v6.16b, v7.16b
    umax    v0.16b, v0.16b, v6.16b

.L_dilate_tail:
    /* First tail pixel always exists (tail is 1 or 3). */
    ldr     w8, [x14], #4
    dup     v2.4s, w8
    umax    v0.16b, v0.16b, v2.16b
    /* The remaining two tail pixels exist only when pixelCount % 4 == 3,
     * i.e. when bit 1 of the odd pixelCount is set. */
    tbz     w12, #1, .L_dilate_next_row
    ldr     w8, [x14], #4
    dup     v2.4s, w8
    umax    v0.16b, v0.16b, v2.16b
    ldr     w8, [x14], #4
    dup     v2.4s, w8
    umax    v0.16b, v0.16b, v2.16b

.L_dilate_next_row:
    add     x15, x15, x17
    subs    w10, w10, #1
    b.ne    .L_dilate_row

    b       .L_reduce_max

/* ---------------------------------------------------------------------
 * Erosion: byte-wise minimum over the complete kernel.
 * --------------------------------------------------------------------- */
.L_erode:
    movi    v0.16b, #255

.L_erode_row:
    mov     x14, x15
    cbz     w13, .L_erode_tail         // pixelCount < 4: no vector work
    mov     w8, w13                    // vector loop counter
    movi    v1.16b, #255
    movi    v6.16b, #255
    movi    v7.16b, #255

.L_erode_vec:
    /* 4-way unroll into four independent min chains (v0,v1,v6,v7). */
    cmp     w8, #4
    b.lo    .L_erode_resid
    ld1     {v2.16b}, [x14], #16
    ld1     {v3.16b}, [x14], #16
    ld1     {v4.16b}, [x14], #16
    ld1     {v5.16b}, [x14], #16
    umin    v0.16b, v0.16b, v2.16b
    umin    v1.16b, v1.16b, v3.16b
    umin    v6.16b, v6.16b, v4.16b
    umin    v7.16b, v7.16b, v5.16b
    sub     w8, w8, #4
    cmp     w8, #4
    b.hs    .L_erode_vec
    cbz     w8, .L_erode_combine

.L_erode_resid:
    /* w8 in 1..3 vector groups: up to two chains. */
    cmp     w8, #2
    b.lo    .L_erode_resid1
    ld1     {v2.16b}, [x14], #16
    ld1     {v3.16b}, [x14], #16
    umin    v0.16b, v0.16b, v2.16b
    umin    v1.16b, v1.16b, v3.16b
    sub     w8, w8, #2
    cbz     w8, .L_erode_combine

.L_erode_resid1:
    ld1     {v2.16b}, [x14], #16
    umin    v0.16b, v0.16b, v2.16b

.L_erode_combine:
    umin    v0.16b, v0.16b, v1.16b
    umin    v6.16b, v6.16b, v7.16b
    umin    v0.16b, v0.16b, v6.16b

.L_erode_tail:
    /* First tail pixel always exists (tail is 1 or 3). */
    ldr     w8, [x14], #4
    dup     v2.4s, w8
    umin    v0.16b, v0.16b, v2.16b
    /* The remaining two tail pixels exist only when pixelCount % 4 == 3,
     * i.e. when bit 1 of the odd pixelCount is set. */
    tbz     w12, #1, .L_erode_next_row
    ldr     w8, [x14], #4
    dup     v2.4s, w8
    umin    v0.16b, v0.16b, v2.16b
    ldr     w8, [x14], #4
    dup     v2.4s, w8
    umin    v0.16b, v0.16b, v2.16b

.L_erode_next_row:
    add     x15, x15, x17
    subs    w10, w10, #1
    b.ne    .L_erode_row

    b       .L_reduce_min

/* ---------------------------------------------------------------------
 * Horizontal reduction of the four byte lanes belonging to each channel.
 *
 * Before reduction:
 *   lane  0,  4,  8, 12 = B
 *   lane  1,  5,  9, 13 = G
 *   lane  2,  6, 10, 14 = R
 *   lane  3,  7, 11, 15 = A
 *
 * First compare bytes 0..7 against 8..15, then compare the resulting
 * bytes 0..3 against 4..7. The low four bytes are the four channel
 * results in B,G,R,A order.
 * --------------------------------------------------------------------- */
.L_reduce_min:
    ext     v1.16b, v0.16b, v0.16b, #8
    umin    v0.16b, v0.16b, v1.16b
    ext     v1.16b, v0.16b, v0.16b, #4
    umin    v0.16b, v0.16b, v1.16b
    b       .L_pack

.L_reduce_max:
    ext     v1.16b, v0.16b, v0.16b, #8
    umax    v0.16b, v0.16b, v1.16b
    ext     v1.16b, v0.16b, v0.16b, #4
    umax    v0.16b, v0.16b, v1.16b

/* ---------------------------------------------------------------------
 * Pack B,G,R,A into the jint value expected by the C++ implementation.
 * --------------------------------------------------------------------- */
.L_pack:
    umov    w8,  v0.b[0]               // B
    umov    w9,  v0.b[1]               // G
    umov    w10, v0.b[2]               // R
    umov    w11, v0.b[3]               // A

    orr     w8, w8, w9, lsl #8
    orr     w8, w8, w10, lsl #16
    orr     w8, w8, w11, lsl #24
    str     w8, [x16]
    ret

.size ksvgMorphologyApplyPixelNeon64, .-ksvgMorphologyApplyPixelNeon64

/* ---------------------------------------------------------------------
 * Row kernel: ksvgMorphologyApplyRowNeon64
 *
 * Computes an entire horizontal run of fully-interior output pixels in one
 * call instead of one pixel per call, so the overlapping horizontal windows
 * stop re-reading the same source bytes. For output row y it:
 *
 *   1. vertically reduces each column of the spanned range [xStart-radiusX,
 *      xEnd-1+radiusX] over the 2*radiusY+1 rows into a caller-provided
 *      scratch buffer (one jint per column; 16-byte loads fold 4 columns by
 *      byte-lane min/max, so the result is exactly the per-channel min/max of
 *      the ARGB jints), then
 *   2. reduces each output pixel's 2*radiusX+1-wide window from that now-L1
 *      scratch row with the same two-accumulator 4-way-unrolled fold used by
 *      the per-pixel kernel.
 *
 * A source byte is loaded once per output row instead of 2*radiusX+1 times
 * per output pixel; the horizontal fold re-reads only the small scratch row.
 * scratch must be at least (xEnd - xStart) + 2*radiusX jints.
 *
 * AArch64 ABI (10 arguments; x0-x7 plus two stack words):
 *   x0 = src
 *   x1 = dst
 *   w2 = width
 *   w3 = radiusX
 *   w4 = radiusY
 *   w5 = erode (0 = dilate, non-zero = erode)
 *   w6 = y
 *   w7 = xStart
 *   [sp, #0] = xEnd     (one-past-last output column)
 *   [sp, #8] = scratch  (jint* holding the reduced column row)
 *
 * Register map (all caller-saved; v8-v15 are deliberately avoided):
 *   x10 = scratch base, x15 = src window base, x16 = dst pixel pointer,
 *   x17 = row stride in bytes, w12 = colLo, w13 = xEnd,
 *   w4 = rowCount (2*radiusY+1), w8 = group counter, w9 = tail column count.
 * --------------------------------------------------------------------- */
.text
.align 2
.global ksvgMorphologyApplyRowNeon64
.type ksvgMorphologyApplyRowNeon64, %function

ksvgMorphologyApplyRowNeon64:
    ldr     w13, [sp]                  // xEnd
    ldr     x10, [sp, #8]              // scratch base

    sub     w11, w6, w4                // top = y - radiusY
    sub     w12, w7, w3                // colLo = xStart - radiusX

    /* x15 = src[top][colLo], x16 = dst[y][0], x17 = row stride in bytes */
    sxtw    x8, w11
    sxtw    x9, w2
    mul     x8, x8, x9
    sxtw    x9, w12
    add     x8, x8, x9
    lsl     x8, x8, #2
    add     x15, x0, x8

    sxtw    x8, w6
    sxtw    x9, w2
    mul     x8, x8, x9
    lsl     x16, x8, #2
    add     x16, x1, x16

    sxtw    x17, w2
    lsl     x17, x17, #2

    add     w4, w4, w4
    add     w4, w4, #1                 // rowCount = 2*radiusY + 1

    add     w11, w13, w3               // colHi = xEnd + radiusX
    sub     w11, w11, w12              // colCount = colHi - colLo
    lsr     w8, w11, #2                // fullGroups = colCount / 4
    and     w9, w11, #3                // tailCols = colCount % 4

    cbnz    w5, .L_row_erode

/* ---------------------------------------------------------------------
 * Dilation.
 * --------------------------------------------------------------------- */
    mov     x0, x10                    // scratch cursor
    mov     x14, x15                   // current group base in src

.L_row_dv_groups:
    /* Fold one 4-column group over all rows into two independent chains. */
    cbz     w8, .L_row_dv_tail
    movi    v0.16b, #0
    movi    v1.16b, #0
    mov     x11, x14
    mov     w2, w4                     // w2 = rowCounter
    lsr     w6, w2, #1                 // w6 = row pairs
    cbz     w6, .L_row_dv_resid_row

.L_row_dv_pairs:
    ld1     {v2.16b}, [x11], x17
    ld1     {v3.16b}, [x11], x17
    umax    v0.16b, v0.16b, v2.16b
    umax    v1.16b, v1.16b, v3.16b
    subs    w6, w6, #1
    b.ne    .L_row_dv_pairs

.L_row_dv_resid_row:
    tbz     w2, #0, .L_row_dv_combine
    ld1     {v2.16b}, [x11]
    umax    v0.16b, v0.16b, v2.16b
    tbz     w2, #0, .L_row_dv_combine
    ld1     {v2.16b}, [x11]
    umax    v0.16b, v0.16b, v2.16b
.L_row_dv_combine:
    umax    v0.16b, v0.16b, v1.16b
    st1     {v0.16b}, [x0], #16
    add     x14, x14, #16
    sub     w8, w8, #1
    b.ne    .L_row_dv_groups

.L_row_dv_tail:
    /* The 0..3 unaligned tail columns: one scalar-dup fold per column. */
    cbz     w9, .L_row_dh
.L_row_dv_tail_col:
    mov     x11, x14
    mov     w2, w4
    movi    v0.16b, #0
.L_row_dv_tail_rows:
    ldr     w8, [x11]
    dup     v2.4s, w8
    umax    v0.16b, v0.16b, v2.16b
    add     x11, x11, x17
    sub     w2, w2, #1
    cbnz    w2, .L_row_dv_tail_rows
    st1     {v0.s}[0], [x0], #4
    add     x14, x14, #4
    sub     w9, w9, #1
    b.ne    .L_row_dv_tail_col

    /* ---------------------------------------------------------------
     * Horizontal reduction of the scratch column row (dilation).
     * --------------------------------------------------------------- */
.L_row_dh:
    sxtw    x8, w7
    lsl     x8, x8, #2
    add     x16, x16, x8               // x16 = &dst[y][xStart]

.L_row_dh_px:
    sub     w11, w7, w3
    sub     w11, w11, w12              // relStart = x - radiusX - colLo
    sxtw    x11, w11
    lsl     x14, x11, #2
    add     x14, x14, x10              // window base in scratch

    add     w11, w3, w3
    add     w11, w11, #1               // L = 2*radiusX + 1
    lsr     w8, w11, #2                // vecCount = L / 4

    movi    v0.16b, #0
    movi    v1.16b, #0
    movi    v6.16b, #0
    movi    v7.16b, #0
    cbz     w8, .L_row_dh_tail
    cmp     w8, #4
    b.lo    .L_row_dh_resid

.L_row_dh_vec4:
    ld1     {v2.16b}, [x14], #16
    ld1     {v3.16b}, [x14], #16
    ld1     {v4.16b}, [x14], #16
    ld1     {v5.16b}, [x14], #16
    umax    v0.16b, v0.16b, v2.16b
    umax    v1.16b, v1.16b, v3.16b
    umax    v6.16b, v6.16b, v4.16b
    umax    v7.16b, v7.16b, v5.16b
    sub     w8, w8, #4
    cmp     w8, #4
    b.hs    .L_row_dh_vec4
    cbz     w8, .L_row_dh_combine

.L_row_dh_resid:
    cmp     w8, #2
    b.lo    .L_row_dh_resid1
    ld1     {v2.16b}, [x14], #16
    ld1     {v3.16b}, [x14], #16
    umax    v0.16b, v0.16b, v2.16b
    umax    v1.16b, v1.16b, v3.16b
    sub     w8, w8, #2
    cbz     w8, .L_row_dh_combine

.L_row_dh_resid1:
    ld1     {v2.16b}, [x14], #16
    umax    v0.16b, v0.16b, v2.16b

.L_row_dh_combine:
    umax    v0.16b, v0.16b, v1.16b
    umax    v6.16b, v6.16b, v7.16b
    umax    v0.16b, v0.16b, v6.16b

.L_row_dh_tail:
    /* First tail pixel always exists (L is odd: tail is 1 or 3). */
    ldr     w8, [x14], #4
    dup     v2.4s, w8
    umax    v0.16b, v0.16b, v2.16b
    tbz     w11, #1, .L_row_dh_pack
    ldr     w8, [x14], #4
    dup     v2.4s, w8
    umax    v0.16b, v0.16b, v2.16b
    ldr     w8, [x14], #4
    dup     v2.4s, w8
    umax    v0.16b, v0.16b, v2.16b

.L_row_dh_pack:
    umov    w8,  v0.b[0]               // B
    umov    w9,  v0.b[1]               // G
    umov    w2,  v0.b[2]               // R
    umov    w0,  v0.b[3]               // A
    orr     w8, w8, w9, lsl #8
    orr     w8, w8, w2, lsl #16
    orr     w8, w8, w0, lsl #24
    str     w8, [x16], #4
    add     w7, w7, #1
    cmp     w7, w13
    b.lo    .L_row_dh_px
    ret

/* ---------------------------------------------------------------------
 * Erosion.
 * --------------------------------------------------------------------- */
.L_row_erode:
    mov     x0, x10                    // scratch cursor
    mov     x14, x15                   // current group base in src

.L_row_ev_groups:
    cbz     w8, .L_row_ev_tail
    movi    v0.16b, #255
    movi    v1.16b, #255
    mov     x11, x14
    mov     w2, w4                     // w2 = rowCounter
    lsr     w6, w2, #1                 // w6 = row pairs
    cbz     w6, .L_row_ev_resid_row

.L_row_ev_pairs:
    ld1     {v2.16b}, [x11], x17
    ld1     {v3.16b}, [x11], x17
    umin    v0.16b, v0.16b, v2.16b
    umin    v1.16b, v1.16b, v3.16b
    subs    w6, w6, #1
    b.ne    .L_row_ev_pairs

.L_row_ev_resid_row:
    tbz     w2, #0, .L_row_ev_combine
    ld1     {v2.16b}, [x11]
    umin    v0.16b, v0.16b, v2.16b
    tbz     w2, #0, .L_row_ev_combine
    ld1     {v2.16b}, [x11]
    umin    v0.16b, v0.16b, v2.16b
.L_row_ev_combine:
    umin    v0.16b, v0.16b, v1.16b
    st1     {v0.16b}, [x0], #16
    add     x14, x14, #16
    sub     w8, w8, #1
    b.ne    .L_row_ev_groups

.L_row_ev_tail:
    cbz     w9, .L_row_eh
.L_row_ev_tail_col:
    mov     x11, x14
    mov     w2, w4
    movi    v0.16b, #255
.L_row_ev_tail_rows:
    ldr     w8, [x11]
    dup     v2.4s, w8
    umin    v0.16b, v0.16b, v2.16b
    add     x11, x11, x17
    sub     w2, w2, #1
    cbnz    w2, .L_row_ev_tail_rows
    st1     {v0.s}[0], [x0], #4
    add     x14, x14, #4
    sub     w9, w9, #1
    b.ne    .L_row_ev_tail_col

    /* Horizontal reduction of the scratch column row (erosion). */
.L_row_eh:
    sxtw    x8, w7
    lsl     x8, x8, #2
    add     x16, x16, x8               // x16 = &dst[y][xStart]

.L_row_eh_px:
    sub     w11, w7, w3
    sub     w11, w11, w12              // relStart = x - radiusX - colLo
    sxtw    x11, w11
    lsl     x14, x11, #2
    add     x14, x14, x10              // window base in scratch

    add     w11, w3, w3
    add     w11, w11, #1               // L = 2*radiusX + 1
    lsr     w8, w11, #2                // vecCount = L / 4

    movi    v0.16b, #255
    movi    v1.16b, #255
    movi    v6.16b, #255
    movi    v7.16b, #255
    cbz     w8, .L_row_eh_tail
    cmp     w8, #4
    b.lo    .L_row_eh_resid

.L_row_eh_vec4:
    ld1     {v2.16b}, [x14], #16
    ld1     {v3.16b}, [x14], #16
    ld1     {v4.16b}, [x14], #16
    ld1     {v5.16b}, [x14], #16
    umin    v0.16b, v0.16b, v2.16b
    umin    v1.16b, v1.16b, v3.16b
    umin    v6.16b, v6.16b, v4.16b
    umin    v7.16b, v7.16b, v5.16b
    sub     w8, w8, #4
    cmp     w8, #4
    b.hs    .L_row_eh_vec4
    cbz     w8, .L_row_eh_combine

.L_row_eh_resid:
    cmp     w8, #2
    b.lo    .L_row_eh_resid1
    ld1     {v2.16b}, [x14], #16
    ld1     {v3.16b}, [x14], #16
    umin    v0.16b, v0.16b, v2.16b
    umin    v1.16b, v1.16b, v3.16b
    sub     w8, w8, #2
    cbz     w8, .L_row_eh_combine

.L_row_eh_resid1:
    ld1     {v2.16b}, [x14], #16
    umin    v0.16b, v0.16b, v2.16b

.L_row_eh_combine:
    umin    v0.16b, v0.16b, v1.16b
    umin    v6.16b, v6.16b, v7.16b
    umin    v0.16b, v0.16b, v6.16b

.L_row_eh_tail:
    ldr     w8, [x14], #4
    dup     v2.4s, w8
    umin    v0.16b, v0.16b, v2.16b
    tbz     w11, #1, .L_row_eh_pack
    ldr     w8, [x14], #4
    dup     v2.4s, w8
    umin    v0.16b, v0.16b, v2.16b
    ldr     w8, [x14], #4
    dup     v2.4s, w8
    umin    v0.16b, v0.16b, v2.16b

.L_row_eh_pack:
    umov    w8,  v0.b[0]               // B
    umov    w9,  v0.b[1]               // G
    umov    w2,  v0.b[2]               // R
    umov    w0,  v0.b[3]               // A
    orr     w8, w8, w9, lsl #8
    orr     w8, w8, w2, lsl #16
    orr     w8, w8, w0, lsl #24
    str     w8, [x16], #4
    add     w7, w7, #1
    cmp     w7, w13
    b.lo    .L_row_eh_px
    ret

.size ksvgMorphologyApplyRowNeon64, .-ksvgMorphologyApplyRowNeon64
