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

.L_dilate_vec:
    ld1     {v2.16b}, [x14], #16
    umax    v0.16b, v0.16b, v2.16b
    subs    w8, w8, #1
    b.ne    .L_dilate_vec

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

.L_erode_vec:
    ld1     {v2.16b}, [x14], #16
    umin    v0.16b, v0.16b, v2.16b
    subs    w8, w8, #1
    b.ne    .L_erode_vec

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
