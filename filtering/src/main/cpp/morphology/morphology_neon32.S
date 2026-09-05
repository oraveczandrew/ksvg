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

.text
.fpu neon
.align 2

/*
 * ARM32 / AdvSIMD implementation of the interior morphology pixel.
 *
 * C++ ABI:
 *   void ksvgMorphologyApplyPixelNeon32(
 *       const jint *src, jint *dst,
 *       jint width, jint radiusX, jint radiusY,
 *       jboolean erode, jint x, jint y);
 *
 * ARM32 AAPCS arguments:
 *   r0 = src
 *   r1 = dst
 *   r2 = width
 *   r3 = radiusX
 *   [sp, #0] = radiusY
 *   [sp, #4] = erode
 *   [sp, #8] = x
 *   [sp, #12] = y
 */

.global ksvgMorphologyApplyPixelNeon32
.type ksvgMorphologyApplyPixelNeon32, %function

ksvgMorphologyApplyPixelNeon32:
    push    {r4-r11, lr}
    @ Arguments from stack (sp moved 9*4 = 36 bytes)
    ldr     r4, [sp, #36]               @ r4 = radiusY
    ldr     r5, [sp, #40]               @ r5 = erode
    ldr     r6, [sp, #44]               @ r6 = x
    ldr     r7, [sp, #48]               @ r7 = y

    @ top = y - radiusY, left = x - radiusX
    sub     r8, r7, r4                  @ r8 = top
    sub     r9, r6, r3                  @ r9 = left

    @ rowCount = 2*radiusY + 1
    add     r10, r4, r4
    add     r10, r10, #1                @ r10 = rowCount

    @ right = x + radiusX, pixelCount = 2*radiusX + 1
    add     r11, r6, r3                 @ r11 = right
    sub     r12, r11, r9
    add     r12, r12, #1                @ r12 = pixelCount

    @ vectorCount = pixelCount / 4
    lsr     r14, r12, #2                @ r14 = vectorCount

    @ r4 = pointer to src[top][left]
    mul     r7, r8, r2
    add     r7, r7, r9
    add     r4, r0, r7, lsl #2          @ r4 = current row in src (src cursor)

    @ r5 = pointer to dst[y][x]
    ldr     r7, [sp, #48]               @ y
    mul     r7, r7, r2
    add     r7, r7, r6
    add     r5, r1, r7, lsl #2          @ r5 = dst pointer

    @ lr = row stride in bytes
    mov     lr, r2, lsl #2

    @ Branch once: do not maintain both min and max accumulators.
    ldr     r7, [sp, #40]               @ erode
    tst     r7, #255
    bne     .L_erode

/* ---------------------------------------------------------------------
 * Dilation.
 * --------------------------------------------------------------------- */
.L_dilate:
    vmov.i8 q0, #0

.L_dilate_row:
    mov     r7, r4                      @ r7 = current pixel cursor in row
    cmp     r14, #0
    beq     .L_dilate_tail              @ pixelCount < 4: no vector work
    mov     r8, r14                     @ vector loop counter
    vmov.i8 q1, #0
    vmov.i8 q2, #0
    vmov.i8 q3, #0

.L_dilate_vec:
    @ 4-way unroll into four independent max chains (q0, q1, q2, q3)
    cmp     r8, #4
    blo     .L_dilate_resid
    vld1.8  {q8, q9}, [r7]!             @ load 32 bytes (8 pixels)
    vld1.8  {q10, q11}, [r7]!           @ load 32 bytes (8 pixels)
    vmax.u8 q0, q0, q8
    vmax.u8 q1, q1, q9
    vmax.u8 q2, q2, q10
    vmax.u8 q3, q3, q11
    sub     r8, r8, #4
    cmp     r8, #4
    bhs     .L_dilate_vec
    cmp     r8, #0
    beq     .L_dilate_combine

.L_dilate_resid:
    cmp     r8, #2
    blo     .L_dilate_resid1
    vld1.8  {q8, q9}, [r7]!
    vmax.u8 q0, q0, q8
    vmax.u8 q1, q1, q9
    sub     r8, r8, #2
    cmp     r8, #0
    beq     .L_dilate_combine

.L_dilate_resid1:
    vld1.8  {q8}, [r7]!
    vmax.u8 q0, q0, q8

.L_dilate_combine:
    vmax.u8 q0, q0, q1
    vmax.u8 q2, q2, q3
    vmax.u8 q0, q0, q2

.L_dilate_tail:
    @ First tail pixel always exists (L is odd)
    ldr     r8, [r7], #4
    vdup.32 q8, r8
    vmax.u8 q0, q0, q8
    @ Tail is 1 or 3 pixels
    tst     r12, #2
    beq     .L_dilate_next_row
    ldr     r8, [r7], #4
    vdup.32 q8, r8
    vmax.u8 q0, q0, q8
    ldr     r8, [r7], #4
    vdup.32 q8, r8
    vmax.u8 q0, q0, q8

.L_dilate_next_row:
    add     r4, r4, lr
    subs    r10, r10, #1
    bne     .L_dilate_row

    b       .L_reduce_max

/* ---------------------------------------------------------------------
 * Erosion.
 * --------------------------------------------------------------------- */
.L_erode:
    vmov.i8 q0, #255

.L_erode_row:
    mov     r7, r4
    cmp     r14, #0
    beq     .L_erode_tail
    mov     r8, r14
    vmov.i8 q1, #255
    vmov.i8 q2, #255
    vmov.i8 q3, #255

.L_erode_vec:
    cmp     r8, #4
    blo     .L_erode_resid
    vld1.8  {q8, q9}, [r7]!
    vld1.8  {q10, q11}, [r7]!
    vmin.u8 q0, q0, q8
    vmin.u8 q1, q1, q9
    vmin.u8 q2, q2, q10
    vmin.u8 q3, q3, q11
    sub     r8, r8, #4
    cmp     r8, #4
    bhs     .L_erode_vec
    cmp     r8, #0
    beq     .L_erode_combine

.L_erode_resid:
    cmp     r8, #2
    blo     .L_erode_resid1
    vld1.8  {q8, q9}, [r7]!
    vmin.u8 q0, q0, q8
    vmin.u8 q1, q1, q9
    sub     r8, r8, #2
    cmp     r8, #0
    beq     .L_erode_combine

.L_erode_resid1:
    vld1.8  {q8}, [r7]!
    vmin.u8 q0, q0, q8

.L_erode_combine:
    vmin.u8 q0, q0, q1
    vmin.u8 q2, q2, q3
    vmin.u8 q0, q0, q2

.L_erode_tail:
    ldr     r8, [r7], #4
    vdup.32 q8, r8
    vmin.u8 q0, q0, q8
    tst     r12, #2
    beq     .L_erode_next_row
    ldr     r8, [r7], #4
    vdup.32 q8, r8
    vmin.u8 q0, q0, q8
    ldr     r8, [r7], #4
    vdup.32 q8, r8
    vmin.u8 q0, q0, q8

.L_erode_next_row:
    add     r4, r4, lr
    subs    r10, r10, #1
    bne     .L_erode_row

    b       .L_reduce_min

/* ---------------------------------------------------------------------
 * Horizontal reduction and packing.
 * --------------------------------------------------------------------- */
.L_reduce_min:
    vext.8  q1, q0, q0, #8
    vmin.u8 q0, q0, q1
    vext.8  q1, q0, q0, #4
    vmin.u8 q0, q0, q1
    b       .L_pack

.L_reduce_max:
    vext.8  q1, q0, q0, #8
    vmax.u8 q0, q0, q1
    vext.8  q1, q0, q0, #4
    vmax.u8 q0, q0, q1

.L_pack:
    vmov.32 r0, d0[0]
    str     r0, [r5]
    pop     {r4-r11, pc}

.size ksvgMorphologyApplyPixelNeon32, .-ksvgMorphologyApplyPixelNeon32

/* ---------------------------------------------------------------------
 * Row kernel: ksvgMorphologyApplyRowNeon32
 *
 * ABI:
 *   r0 = src
 *   r1 = dst
 *   r2 = width
 *   r3 = radiusX
 *   [sp, #0]  = radiusY
 *   [sp, #4]  = erode
 *   [sp, #8]  = y
 *   [sp, #12] = xStart
 *   [sp, #16] = xEnd
 *   [sp, #20] = scratch
 * --------------------------------------------------------------------- */
.global ksvgMorphologyApplyRowNeon32
.type ksvgMorphologyApplyRowNeon32, %function

ksvgMorphologyApplyRowNeon32:
    push    {r4-r11, lr}
    @ Load stack arguments (sp moved 9*4 = 36 bytes)
    ldr     r4, [sp, #36]               @ r4 = radiusY
    ldr     r5, [sp, #40]               @ r5 = erode
    ldr     r6, [sp, #44]               @ r6 = y
    ldr     r7, [sp, #48]               @ r7 = xStart
    ldr     r10, [sp, #52]              @ r10 = xEnd
    ldr     r11, [sp, #56]              @ r11 = scratch

    @ top = y - radiusY, colLo = xStart - radiusX
    sub     r8, r6, r4                  @ r8 = top
    sub     r9, r7, r3                  @ r9 = colLo

    @ r12 = src[top][colLo]
    mul     r12, r8, r2
    add     r12, r12, r9
    add     r12, r0, r12, lsl #2        @ r12 = initial group base in src

    @ lr = dst[y][0]
    mul     r8, r6, r2
    add     lr, r1, r8, lsl #2          @ lr = dst pointer for the row

    @ r8 = row stride in bytes
    mov     r8, r2, lsl #2

    @ rowCount = 2*radiusY + 1
    add     r4, r4, r4
    add     r4, r4, #1                  @ r4 = rowCount

    @ colCount = (xEnd + radiusX) - colLo
    add     r2, r10, r3                 @ r2 = colHi
    sub     r2, r2, r9                  @ r2 = colCount
    lsr     r6, r2, #2                  @ r6 = fullGroups
    and     r9, r2, #3                  @ r9 = tailCols

    tst     r5, #255
    bne     .L_row_erode

/* ---------------------------------------------------------------------
 * Dilation (Row).
 * --------------------------------------------------------------------- */
    mov     r0, r11                     @ r0 = scratch cursor
    mov     r5, r12                     @ r5 = current group base in src

.L_row_dv_groups:
    cmp     r6, #0
    beq     .L_row_dv_tail
    vmov.i8 q0, #0
    vmov.i8 q1, #0
    mov     r7, r5
    mov     r2, r4                      @ r2 = rowCounter
    lsr     r11, r2, #1                 @ r11 = row pairs

    cmp     r11, #0
    beq     .L_row_dv_resid_row
.L_row_dv_pairs:
    vld1.8  {q2}, [r7]
    add     r7, r7, r8
    vld1.8  {q3}, [r7]
    add     r7, r7, r8
    vmax.u8 q0, q0, q2
    vmax.u8 q1, q1, q3
    subs    r11, r11, #1
    bne     .L_row_dv_pairs

.L_row_dv_resid_row:
    tst     r2, #1
    beq     .L_row_dv_combine
    vld1.8  {q2}, [r7]
    vmax.u8 q0, q0, q2

.L_row_dv_combine:
    vmax.u8 q0, q0, q1
    vst1.8  {q0}, [r0]!
    add     r5, r5, #16
    subs    r6, r6, #1
    bne     .L_row_dv_groups

.L_row_dv_tail:
    cmp     r9, #0
    beq     .L_row_dh
.L_row_dv_tail_col:
    mov     r7, r5
    mov     r2, r4
    vmov.i8 q0, #0
.L_row_dv_tail_rows:
    ldr     r11, [r7]
    vdup.32 q2, r11
    vmax.u8 q0, q0, q2
    add     r7, r7, r8
    subs    r2, r2, #1
    bne     .L_row_dv_tail_rows
    vst1.32 {d0[0]}, [r0]!
    add     r5, r5, #4
    subs    r9, r9, #1
    bne     .L_row_dv_tail_col

.L_row_dh:
    @ Reload scratch base and xStart
    ldr     r11, [sp, #56]
    ldr     r7, [sp, #48]               @ r7 = xStart
    add     r12, lr, r7, lsl #2         @ r12 = &dst[y][xStart]

.L_row_dh_px:
    @ window base in scratch: (x - radiusX - colLo) * 4
    ldr     r7, [sp, #48]               @ x
    sub     r8, r7, r3                  @ x - radiusX
    ldr     r12, [sp, #48]              @ xStart
    sub     r12, r12, r3                @ colLo = xStart - radiusX
    sub     r8, r8, r12                 @ relative column in scratch
    add     r14, r11, r8, lsl #2        @ r14 = window base in scratch

    @ L = 2*radiusX + 1
    add     r12, r3, r3
    add     r12, r12, #1                @ r12 = L
    lsr     r8, r12, #2                 @ r8 = vecCount

    vmov.i8 q0, #0
    vmov.i8 q1, #0
    vmov.i8 q2, #0
    vmov.i8 q3, #0
    cmp     r8, #0
    beq     .L_row_dh_tail
    cmp     r8, #4
    blo     .L_row_dh_resid

.L_row_dh_vec4:
    vld1.8  {q8, q9}, [r14]!
    vld1.8  {q10, q11}, [r14]!
    vmax.u8 q0, q0, q8
    vmax.u8 q1, q1, q9
    vmax.u8 q2, q2, q10
    vmax.u8 q3, q3, q11
    sub     r8, r8, #4
    cmp     r8, #4
    bhs     .L_row_dh_vec4
    cmp     r8, #0
    beq     .L_row_dh_combine

.L_row_dh_resid:
    cmp     r8, #2
    blo     .L_row_dh_resid1
    vld1.8  {q8, q9}, [r14]!
    vmax.u8 q0, q0, q8
    vmax.u8 q1, q1, q9
    sub     r8, r8, #2
    cmp     r8, #0
    beq     .L_row_dh_combine

.L_row_dh_resid1:
    vld1.8  {q8}, [r14]!
    vmax.u8 q0, q0, q8

.L_row_dh_combine:
    vmax.u8 q0, q0, q1
    vmax.u8 q2, q2, q3
    vmax.u8 q0, q0, q2

.L_row_dh_tail:
    ldr     r8, [r14], #4
    vdup.32 q8, r8
    vmax.u8 q0, q0, q8
    tst     r12, #2
    beq     .L_row_dh_pack
    ldr     r8, [r14], #4
    vdup.32 q8, r8
    vmax.u8 q0, q0, q8
    ldr     r8, [r14], #4
    vdup.32 q8, r8
    vmax.u8 q0, q0, q8

.L_row_dh_pack:
    vext.8  q1, q0, q0, #8
    vmax.u8 q0, q0, q1
    vext.8  q1, q0, q0, #4
    vmax.u8 q0, q0, q1
    vmov.32 r0, d0[0]
    str     r0, [r12], #4
    ldr     r7, [sp, #48]
    add     r7, r7, #1
    str     r7, [sp, #48]
    cmp     r7, r10
    blo     .L_row_dh_px
    pop     {r4-r11, pc}

/* ---------------------------------------------------------------------
 * Erosion (Row).
 * --------------------------------------------------------------------- */
.L_row_erode:
    mov     r0, r11
    mov     r5, r12
    mov     r8, r2, lsl #2              @ row stride

.L_row_ev_groups:
    cmp     r6, #0
    beq     .L_row_ev_tail
    vmov.i8 q0, #255
    vmov.i8 q1, #255
    mov     r7, r5
    mov     r2, r4
    lsr     r11, r2, #1

    cmp     r11, #0
    beq     .L_row_ev_resid_row
.L_row_ev_pairs:
    vld1.8  {q2}, [r7]
    add     r7, r7, r8
    vld1.8  {q3}, [r7]
    add     r7, r7, r8
    vmin.u8 q0, q0, q2
    vmin.u8 q1, q1, q3
    subs    r11, r11, #1
    bne     .L_row_ev_pairs

.L_row_ev_resid_row:
    tst     r2, #1
    beq     .L_row_ev_combine
    vld1.8  {q2}, [r7]
    vmin.u8 q0, q0, q2

.L_row_ev_combine:
    vmin.u8 q0, q0, q1
    vst1.8  {q0}, [r0]!
    add     r5, r5, #16
    subs    r6, r6, #1
    bne     .L_row_ev_groups

.L_row_ev_tail:
    cmp     r9, #0
    beq     .L_row_eh
.L_row_ev_tail_col:
    mov     r7, r5
    mov     r2, r4
    vmov.i8 q0, #255
.L_row_ev_tail_rows:
    ldr     r11, [r7]
    vdup.32 q2, r11
    vmin.u8 q0, q0, q2
    add     r7, r7, r8
    subs    r2, r2, #1
    bne     .L_row_ev_tail_rows
    vst1.32 {d0[0]}, [r0]!
    add     r5, r5, #4
    subs    r9, r9, #1
    bne     .L_row_ev_tail_col

.L_row_eh:
    ldr     r11, [sp, #56]
    ldr     r7, [sp, #48]
    add     r12, lr, r7, lsl #2

.L_row_eh_px:
    ldr     r7, [sp, #48]
    sub     r8, r7, r3
    ldr     r12, [sp, #48]
    sub     r12, r12, r3
    sub     r8, r8, r12
    add     r14, r11, r8, lsl #2

    add     r12, r3, r3
    add     r12, r12, #1
    lsr     r8, r12, #2

    vmov.i8 q0, #255
    vmov.i8 q1, #255
    vmov.i8 q2, #255
    vmov.i8 q3, #255
    cmp     r8, #0
    beq     .L_row_eh_tail
    cmp     r8, #4
    blo     .L_row_eh_resid

.L_row_eh_vec4:
    vld1.8  {q8, q9}, [r14]!
    vld1.8  {q10, q11}, [r14]!
    vmin.u8 q0, q0, q8
    vmin.u8 q1, q1, q9
    vmin.u8 q2, q2, q10
    vmin.u8 q3, q3, q11
    sub     r8, r8, #4
    cmp     r8, #4
    bhs     .L_row_eh_vec4
    cmp     r8, #0
    beq     .L_row_eh_combine

.L_row_eh_resid:
    cmp     r8, #2
    blo     .L_row_eh_resid1
    vld1.8  {q8, q9}, [r14]!
    vmin.u8 q0, q0, q8
    vmin.u8 q1, q1, q9
    sub     r8, r8, #2
    cmp     r8, #0
    beq     .L_row_eh_combine

.L_row_eh_resid1:
    vld1.8  {q8}, [r14]!
    vmin.u8 q0, q0, q8

.L_row_eh_combine:
    vmin.u8 q0, q0, q1
    vmin.u8 q2, q2, q3
    vmin.u8 q0, q0, q2

.L_row_eh_tail:
    ldr     r8, [r14], #4
    vdup.32 q8, r8
    vmin.u8 q0, q0, q8
    tst     r12, #2
    beq     .L_row_eh_pack
    ldr     r8, [r14], #4
    vdup.32 q8, r8
    vmin.u8 q0, q0, q8
    ldr     r8, [r14], #4
    vdup.32 q8, r8
    vmin.u8 q0, q0, q8

.L_row_eh_pack:
    vext.8  q1, q0, q0, #8
    vmin.u8 q0, q0, q1
    vext.8  q1, q0, q0, #4
    vmin.u8 q0, q0, q1
    vmov.32 r0, d0[0]
    str     r0, [r12], #4
    ldr     r7, [sp, #48]
    add     r7, r7, #1
    str     r7, [sp, #48]
    cmp     r7, r10
    blo     .L_row_eh_px
    pop     {r4-r11, pc}

.size ksvgMorphologyApplyRowNeon32, .-ksvgMorphologyApplyRowNeon32
