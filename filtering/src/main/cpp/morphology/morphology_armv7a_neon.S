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

.syntax unified
.thumb
.text
.fpu neon
.align 2

/*
 * Row kernel: ksvgMorphologyApplyRowNeon32
 *
 * void ksvgMorphologyApplyRowNeon32(
 *     const jint* src, jint* dst, jint width, jint radiusX, jint radiusY,
 *     jboolean erode, jint y, jint xStart, jint xEnd, jint* scratch);
 *
 * ARMv7a ABI:
 *   r0 = src, r1 = dst, r2 = width, r3 = radiusX
 *   stack: radiusY ([sp, #36]), erode ([sp, #40]), y ([sp, #44])
 *   stack: xStart ([sp, #48]), xEnd ([sp, #52]), scratch ([sp, #56])
 */
.global ksvgMorphologyApplyRowNeon32
.type ksvgMorphologyApplyRowNeon32, %function

ksvgMorphologyApplyRowNeon32:
    push    {r4-r11, lr}
    //       sp+36: radiusY, sp+40: erode, sp+44: y, sp+48: xStart, sp+52: xEnd, sp+56: scratch

    //       Constant geometry
    ldr     r4, [sp, #36] // r4 = radiusY
    add     r4, r4, r4
    add     r4, r4, #1 // r4 = rowCount (STABLE)

    ldr     r5, [sp, #44] // r5 = y
    ldr     r6, [sp, #48] // r6 = xStart (STABLE)
    sub     r7, r6, r3 // r7 = colLo

    mov     r8, r2, lsl #2 // r8 = row stride (STABLE)

    lsr     r9, r4, #1 // r9 = radiusY (temp)
    sub     r9, r5, r9 // r9 = top
    mul     r10, r9, r2
    add     r10, r10, r7
    add     r10, r0, r10, lsl #2 // r10 = src start base (STABLE)

    mul     r11, r5, r2
    add     r11, r1, r11, lsl #2 // r11 = dst row base (STABLE)

    ldr     r5, [sp, #52] // r5 = xEnd
    add     r5, r5, r3 // r5 = colHi
    sub     r5, r5, r7 // r5 = colCount

    lsr     r9, r5, #2 // r9 = fullGroups
    and     r7, r5, #3 // r7 = tailCols

    //       Check erode
    ldr     r12, [sp, #40] // erode
    tst     r12, #255
    bne     .L_row_erode

/* ---------------------------------------------------------------------
* Dilation (Row).
* --------------------------------------------------------------------- */
.L_row_dv:
    ldr     r0, [sp, #56] // r0 = scratch cursor
    mov     r1, r10 // r1 = moving src base

    cmp     r9, #0
    beq     .L_row_dv_tail

.L_row_dv_group_loop:
    vmov.i8 q0, #0
    vmov.i8 q1, #0
    mov     r5, r1 // r5 = group row cursor
    lsr     r2, r4, #1 // r2 = row pairs
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
    ldr     r0, [sp, #56] // scratch base
    mov     r1, r6 // current x
    add     r12, r11, r1, lsl #2 // dst cursor
    ldr     r10, [sp, #52] // xEnd

.L_row_dh_loop:
    sub     r7, r1, r6 // rel index
    add     r7, r0, r7, lsl #2 // window base in scratch

    add     r2, r3, r3
    add     r2, r2, #1 // L
    lsr     r8, r2, #2 // vecCount

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
