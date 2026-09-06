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

.syntax unified
.thumb
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
 */

.global ksvgMorphologyApplyPixelNeon32
.type ksvgMorphologyApplyPixelNeon32, %function

ksvgMorphologyApplyPixelNeon32:
    push    {r4-r11, lr}
    @ Load stack args (r4-r11, lr = 9 registers = 36 bytes)
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

    @ pixelCount = 2*radiusX + 1
    add     r11, r6, r3                 @ right
    sub     r11, r11, r9
    add     r11, r11, #1                @ r11 = pixelCount

    @ vectorCount = pixelCount / 4
    lsr     r12, r11, #2                @ r12 = vectorCount

    @ src_cursor_base = src + (top * width + left) * 4
    mul     r7, r8, r2
    add     r7, r7, r9
    add     r0, r0, r7, lsl #2          @ r0 = current row start in src

    @ dst_ptr = dst + (y * width + x) * 4
    ldr     r7, [sp, #48]               @ y
    mul     r7, r7, r2
    add     r7, r7, r6
    add     r1, r1, r7, lsl #2          @ r1 = dst pointer

    @ stride = width * 4
    mov     lr, r2, lsl #2              @ lr = row stride

    @ Branch once: do not maintain both min and max accumulators.
    tst     r5, #255
    bne     .L_erode

/* ---------------------------------------------------------------------
 * Dilation.
 * --------------------------------------------------------------------- */
.L_dilate:
    vmov.i8 q0, #0

.L_dilate_row:
    mov     r7, r0                      @ r7 = current pixel cursor in row
    cmp     r12, #0
    beq     .L_dilate_tail              @ pixelCount < 4: no vector work
    mov     r8, r12                     @ vector loop counter
    vmov.i8 q1, #0
    vmov.i8 q2, #0
    vmov.i8 q3, #0

.L_dilate_vec:
    @ 4-way unroll into four independent max chains (q0, q1, q2, q3)
    cmp     r8, #4
    blo     .L_dilate_resid
    vld1.8  {q8, q9}, [r7]!
    vld1.8  {q10, q11}, [r7]!
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
    @ Tail is 1 or 3 pixels (tst bit 1 of pixelCount)
    tst     r11, #2
    beq     .L_dilate_next_row
    ldr     r8, [r7], #4
    vdup.32 q8, r8
    vmax.u8 q0, q0, q8
    ldr     r8, [r7], #4
    vdup.32 q8, r8
    vmax.u8 q0, q0, q8

.L_dilate_next_row:
    add     r0, r0, lr
    subs    r10, r10, #1
    bne     .L_dilate_row

    b       .L_reduce_max

/* ---------------------------------------------------------------------
 * Erosion.
 * --------------------------------------------------------------------- */
.L_erode:
    vmov.i8 q0, #255

.L_erode_row:
    mov     r7, r0
    cmp     r12, #0
    beq     .L_erode_tail
    mov     r8, r12
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
    tst     r11, #2
    beq     .L_erode_next_row
    ldr     r8, [r7], #4
    vdup.32 q8, r8
    vmin.u8 q0, q0, q8
    ldr     r8, [r7], #4
    vdup.32 q8, r8
    vmin.u8 q0, q0, q8

.L_erode_next_row:
    add     r0, r0, lr
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
    str     r0, [r1]
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
 */
.global ksvgMorphologyApplyRowNeon32
.type ksvgMorphologyApplyRowNeon32, %function

ksvgMorphologyApplyRowNeon32:
    push    {r4-r11, lr}
    @ sp+36: radiusY, sp+40: erode, sp+44: y, sp+48: xStart, sp+52: xEnd, sp+56: scratch

    @ Constant geometry
    ldr     r4, [sp, #36]               @ r4 = radiusY
    add     r4, r4, r4
    add     r4, r4, #1                  @ r4 = rowCount (STABLE)

    ldr     r5, [sp, #44]               @ r5 = y
    ldr     r6, [sp, #48]               @ r6 = xStart (STABLE)
    sub     r7, r6, r3                  @ r7 = colLo

    mov     r8, r2, lsl #2              @ r8 = row stride (STABLE)

    lsr     r9, r4, #1                  @ r9 = radiusY (temp)
    sub     r9, r5, r9                  @ r9 = top
    mul     r10, r9, r2
    add     r10, r10, r7
    add     r10, r0, r10, lsl #2        @ r10 = src start base (STABLE)

    mul     r11, r5, r2
    add     r11, r1, r11, lsl #2        @ r11 = dst row base (STABLE)

    ldr     r5, [sp, #52]               @ r5 = xEnd
    add     r5, r5, r3                  @ r5 = colHi
    sub     r5, r5, r7                  @ r5 = colCount

    lsr     r9, r5, #2                  @ r9 = fullGroups
    and     r7, r5, #3                  @ r7 = tailCols

    @ Check erode
    ldr     r12, [sp, #40]              @ erode
    tst     r12, #255
    bne     .L_row_erode

/* ---------------------------------------------------------------------
 * Dilation (Row).
 * --------------------------------------------------------------------- */
.L_row_dv:
    ldr     r0, [sp, #56]               @ r0 = scratch cursor
    mov     r1, r10                     @ r1 = moving src base

    cmp     r9, #0
    beq     .L_row_dv_tail

.L_row_dv_group_loop:
    vmov.i8 q0, #0
    vmov.i8 q1, #0
    mov     r5, r1                      @ r5 = group row cursor
    lsr     r2, r4, #1                  @ r2 = row pairs
    cmp     r2, #0
    beq     .L_row_dv_group_rows_single
.L_row_dv_group_rows_pairs:
    vld1.8  {q2}, [r5], r8
    vld1.8  {q3}, [r5], r8
    vmax.u8 q0, q0, q2
    vmax.u8 q1, q1, q3
    subs    r2, r2, #1
    bne     .L_row_dv_group_rows_pairs
.L_row_dv_group_rows_single:
    tst     r4, #1
    beq     .L_row_dv_group_rows_done
    vld1.8  {q2}, [r5]
    vmax.u8 q0, q0, q2
.L_row_dv_group_rows_done:
    vmax.u8 q0, q0, q1
    vst1.8  {q0}, [r0]!
    add     r1, r1, #16
    subs    r9, r9, #1
    bne     .L_row_dv_group_loop

.L_row_dv_tail:
    cmp     r7, #0
    beq     .L_row_dh
.L_row_dv_tail_col:
    mov     r5, r1
    vmov.i8 q0, #0
    mov     r2, r4
.L_row_dv_tail_rows:
    ldr     r12, [r5]
    vdup.32 q2, r12
    vmax.u8 q0, q0, q2
    add     r5, r5, r8
    subs    r2, r2, #1
    bne     .L_row_dv_tail_rows
    vst1.32 {d0[0]}, [r0]!
    add     r1, r1, #4
    subs    r7, r7, #1
    bne     .L_row_dv_tail_col

.L_row_dh:
    ldr     r0, [sp, #56]               @ scratch base
    mov     r1, r6                      @ current x
    add     r12, r11, r1, lsl #2        @ dst cursor
    ldr     r10, [sp, #52]              @ xEnd

.L_row_dh_loop:
    sub     r7, r1, r6                  @ rel index
    add     r7, r0, r7, lsl #2          @ window base in scratch

    add     r2, r3, r3
    add     r2, r2, #1                  @ L
    lsr     r8, r2, #2                  @ vecCount

    vmov.i8 q0, #0
    vmov.i8 q1, #0
    cmp     r8, #0
    beq     .L_row_dh_tail

.L_row_dh_vec_loop:
    cmp     r8, #2
    blo     .L_row_dh_vec_resid
    vld1.8  {q2, q3}, [r7]!
    vmax.u8 q0, q0, q2
    vmax.u8 q1, q1, q3
    sub     r8, r8, #2
    cmp     r8, #2
    bhs     .L_row_dh_vec_loop
    cmp     r8, #0
    beq     .L_row_dh_combine

.L_row_dh_vec_resid:
    vld1.8  {q2}, [r7]!
    vmax.u8 q0, q0, q2

.L_row_dh_combine:
    vmax.u8 q0, q0, q1

.L_row_dh_tail:
    ldr     r8, [r7], #4
    vdup.32 q2, r8
    vmax.u8 q0, q0, q2
    tst     r2, #2
    beq     .L_row_dh_pack
    ldr     r8, [r7], #4
    vdup.32 q2, r8
    vmax.u8 q0, q0, q2
    ldr     r8, [r7], #4
    vdup.32 q2, r8
    vmax.u8 q0, q0, q2

.L_row_dh_pack:
    vext.8  q1, q0, q0, #8
    vmax.u8 q0, q0, q1
    vext.8  q1, q0, q0, #4
    vmax.u8 q0, q0, q1
    vmov.32 r8, d0[0]
    str     r8, [r12], #4
    add     r1, r1, #1
    cmp     r1, r10
    blo     .L_row_dh_loop
    pop     {r4-r11, pc}

/* ---------------------------------------------------------------------
 * Erosion (Row).
 * --------------------------------------------------------------------- */
.L_row_erode:
.L_row_ev:
    ldr     r0, [sp, #56]
    mov     r1, r10

    cmp     r9, #0
    beq     .L_row_ev_tail

.L_row_ev_group_loop:
    vmov.i8 q0, #255
    vmov.i8 q1, #255
    mov     r5, r1
    lsr     r2, r4, #1
    cmp     r2, #0
    beq     .L_row_ev_group_rows_single
.L_row_ev_group_rows_pairs:
    vld1.8  {q2}, [r5], r8
    vld1.8  {q3}, [r5], r8
    vmin.u8 q0, q0, q2
    vmin.u8 q1, q1, q3
    subs    r2, r2, #1
    bne     .L_row_ev_group_rows_pairs
.L_row_ev_group_rows_single:
    tst     r4, #1
    beq     .L_row_ev_group_rows_done
    vld1.8  {q2}, [r5]
    vmin.u8 q0, q0, q2
.L_row_ev_group_rows_done:
    vmin.u8 q0, q0, q1
    vst1.8  {q0}, [r0]!
    add     r1, r1, #16
    subs    r9, r9, #1
    bne     .L_row_ev_group_loop

.L_row_ev_tail:
    cmp     r7, #0
    beq     .L_row_eh
.L_row_ev_tail_col:
    mov     r5, r1
    vmov.i8 q0, #255
    mov     r2, r4
.L_row_ev_tail_rows:
    ldr     r12, [r5]
    vdup.32 q2, r12
    vmin.u8 q0, q0, q2
    add     r5, r5, r8
    subs    r2, r2, #1
    bne     .L_row_ev_tail_rows
    vst1.32 {d0[0]}, [r0]!
    add     r1, r1, #4
    subs    r7, r7, #1
    bne     .L_row_ev_tail_col

.L_row_eh:
    ldr     r0, [sp, #56]
    mov     r1, r6
    add     r12, r11, r1, lsl #2
    ldr     r10, [sp, #52]

.L_row_eh_loop:
    sub     r7, r1, r6
    add     r7, r0, r7, lsl #2

    add     r2, r3, r3
    add     r2, r2, #1
    lsr     r8, r2, #2

    vmov.i8 q0, #255
    vmov.i8 q1, #255
    cmp     r8, #0
    beq     .L_row_eh_tail

.L_row_eh_vec_loop:
    cmp     r8, #2
    blo     .L_row_eh_vec_resid
    vld1.8  {q2, q3}, [r7]!
    vmin.u8 q0, q0, q2
    vmin.u8 q1, q1, q3
    sub     r8, r8, #2
    cmp     r8, #2
    bhs     .L_row_eh_vec_loop
    cmp     r8, #0
    beq     .L_row_eh_combine

.L_row_eh_vec_resid:
    vld1.8  {q2}, [r7]!
    vmin.u8 q0, q0, q2

.L_row_eh_combine:
    vmin.u8 q0, q0, q1

.L_row_eh_tail:
    ldr     r8, [r7], #4
    vdup.32 q2, r8
    vmin.u8 q0, q0, q2
    tst     r2, #2
    beq     .L_row_eh_pack
    ldr     r8, [r7], #4
    vdup.32 q2, r8
    vmin.u8 q0, q0, q2
    ldr     r8, [r7], #4
    vdup.32 q2, r8
    vmin.u8 q0, q0, q2

.L_row_eh_pack:
    vext.8  q1, q0, q0, #8
    vmin.u8 q0, q0, q1
    vext.8  q1, q0, q0, #4
    vmin.u8 q0, q0, q1
    vmov.32 r8, d0[0]
    str     r8, [r12], #4
    add     r1, r1, #1
    cmp     r1, r10
    blo     .L_row_eh_loop
    pop     {r4-r11, pc}

.size ksvgMorphologyApplyRowNeon32, .-ksvgMorphologyApplyRowNeon32
