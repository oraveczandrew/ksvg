.text
.align 2
.global turbulence64Asm
.type turbulence64Asm, %function

// void turbulence64Asm(const Turbulence64AsmArgs* args)
// AArch64 / AAPCS64.
//
// Optimizations over the scalar baseline:
//   1. Branch hoisting: the fractal/turbulence fabs is done via a sign-bit
//      mask (BIC), so the flag is checked once per pixel pair, not per channel.
//   2. Two-pixel interleaving: the octave loop processes two adjacent pixels,
//      sharing Y geometry and halving loop overhead.
//   3. SIMD packing: the final pixel pack uses vector convert+saturate+shift
//      instead of four scalar clamp-and-pack sequences.

// ── Argument offsets ────────────────────────────────────────────────────────
.equ A_SELECTOR, 0
.equ A_GRADX, 8
.equ A_GRADY, 16
.equ A_PIXELS, 24
.equ A_WIDTH, 32
.equ A_CLIP_LEFT, 36
.equ A_CLIP_TOP, 40
.equ A_CLIP_RIGHT, 44
.equ A_CLIP_BOTTOM, 48
.equ A_PERIOD_X, 52
.equ A_PERIOD_Y, 56
.equ A_OCTAVES, 60
.equ A_FRACTAL, 64
.equ A_FREQ_X, 72
.equ A_FREQ_Y, 80
.equ A_INV_SCALE_X, 88
.equ A_INV_SCALE_Y, 96
.equ A_USER_LEFT, 104
.equ A_USER_TOP, 112
.equ A_UNIT_X, 120
.equ A_UNIT_Y, 128

// ── Stack frame ─────────────────────────────────────────────────────────────
// Callee-saved d8-d13 are saved (read geometry); d14/d15 also live across the
// whole octave loop as the P1 sum accumulators (v14/v15), so they must be
// saved/restored too (AAPCS64: d14/d15 are callee-saved).
.equ S_SAVE_D8,   0
.equ S_SAVE_D10, 16
.equ S_SAVE_D12, 32
.equ S_SAVE_D14, 48
.equ S_PIXELS,   64   // x: base pixel pointer (row-start recomputation)
.equ S_FX_BASE,  72   // double: P0 fx start for this row
.equ S_FX_STEP,  80   // double: fx advance per pixel (= invScaleX/unitX*freqX)
.equ S_CTLX_BASE,88   // double: P0 curtlx start (= 0 for clipLeft)
.equ S_PY0,      96   // double: py0 for this row
.equ S_CTLY,    104   // double: curtly for this row
.equ S_FX1,     112   // double: P1 fx (= fxBase + fxStep, updated per pixel pair)
.equ S_CTLX1,   120   // double: P1 curtlx (= freqX, updated per pixel pair)
.equ S_BY0,     128   // w: saved by0 (needed by P1 after P0's permutation)
.equ S_BY1,     132   // w: saved by1 (needed by P1 after P0's permutation)
.equ S_PACK_SCALE, 144 // q: [scale, scale]   pack vector (built once at entry)
.equ S_PACK_OFFSET,160 // q: [offset, offset] pack vector (built once at entry)
.equ S_PACK_HALF,  176 // q: [0.5, 0.5]       pack vector (built once at entry)
.equ S_SIZE,    192   // must be 16-byte aligned

// ── Register map (stable across the function unless noted) ──────────────────
// x0 = args pointer (preserved)
// x1 = fractal flag (read-only after mask setup)
// x2 = pixel output pointer (advances through the row)
// x3 = gradPackedX base
// x4 = gradPackedY base
// x5 = selector32 base
// x6 = y (clipTop row counter)
// x7 = octaves counter (reloaded per pixel pair)
// x8 = x column counter (clipLeft, advances per pixel pair)
// x9 = clipRight
// x10 = current stitch width  (doubles each octave, persists across octaves)
// x11 = current stitch height (doubles each octave, persists across octaves)
// x12-x15 = permutation indices (b00/b10/b01/b11) — reloaded per pixel
// x16-x18 = scratch
//
// v0 = P0 sums channels 0/1   v14 = P1 sums channels 0/1
// v1 = P0 sums channels 2/3   v15 = P1 sums channels 2/3
// v2-v6 = arithmetic temporaries (reused for both pixels)
// v7  = fabs sign mask: 0x8000000000000000 in BOTH 64-bit lanes for turbulence,
//       0 for fractal. BIC with v7 clears the sign bit (fabs) or is a no-op.
//       Set once at entry; never modified elsewhere.
// v30 = pack clamp ceiling [255,255,255,255]. NOT a set-once register: d30
// (its low 64 bits) is a geometry scratch double, so v30 is re-established
// (movi v30.4s,#255) at the top of every pack_pixel_pair.
//
// d8  = rx0       d9  = rx1       d10 = ry0
// d11 = ry1       d12 = sx        d13 = sy
// (callee-saved; reused for P1 after P0's lerp)
//
// d24 = fx0       d25 = fy (shared)   d26 = curtlx0   d27 = curtly (shared)
// d28 = ratio (invRatio, shared)
// (In the pack paths v24/v25/v26 are instead loaded from the frame slots
// S_PACK_SCALE/S_PACK_OFFSET/S_PACK_HALF — see entry.)
// d29 = scratch   d30 = scratch (NOTE: d30 ALIASES v30.d[0], the pack clamp
//      ceiling — see the pack_pixel_pair movi)   d31 = scratch
//
// v16-v23 = gradient loads (reused for P0 then P1)

.text
.align 2

turbulence64Asm:
    sub     sp, sp, #S_SIZE
    stp     d8, d9,  [sp, #S_SAVE_D8]
    stp     d10, d11,[sp, #S_SAVE_D10]
    stp     d12, d13,[sp, #S_SAVE_D12]
    stp     d14, d15,[sp, #S_SAVE_D14]

    ldr     x3, [x0, #A_GRADX]
    ldr     x4, [x0, #A_GRADY]
    ldr     x5, [x0, #A_SELECTOR]
    ldr     x2, [x0, #A_PIXELS]
    ldr     w1, [x0, #A_FRACTAL]
    str     x2, [sp, #S_PIXELS]

    // Pre-compute the fabs sign mask (branchless conditional fabs).
    // fractal (w1 != 0): mask = 0               → BIC leaves the value unchanged.
    // turbulence (w1 == 0): mask = 0x80...0     → BIC clears the sign bit (= fabs).
    movz    x16, #0x8000, lsl #48
    cmp     w1, #0
    csel    x16, xzr, x16, ne
    fmov    d7, x16
    ins     v7.d[1], x16               // both 64-bit lanes identical
    // v7 is now our permanent fabs mask; it is NOT modified elsewhere.

    // ── Pre-build the pack constant vectors (once per call) ───────────────────
    // The pack_clamp path needs [scale,scale], [offset,offset], [0.5,0.5].
    // fractal (w1 != 0):  scale = 127.5, offset = 1.0 (base-1 trick)
    // turbulence (w1 == 0): scale = 255.0, offset = 0.0
    // The octave loops clobber every vector (v0-v31), so these are cached in
    // the frame; each pack then reloads them with straight qword loads.
    cmp     w1, #0
    ldr     d20, const_127_5
    ldr     d21, const_255
    fcsel   d20, d20, d21, ne       // d20 = fractal ? 127.5 : 255.0
    ldr     d21, const_1
    fmov    d22, xzr
    fcsel   d21, d21, d22, ne       // d21 = fractal ? 1.0 : 0.0
    ldr     d22, const_half
    dup     v24.2d, v20.d[0]
    dup     v25.2d, v21.d[0]
    dup     v26.2d, v22.d[0]
    str     q24, [sp, #S_PACK_SCALE]
    str     q25, [sp, #S_PACK_OFFSET]
    str     q26, [sp, #S_PACK_HALF]

    movi    v30.4s, #255               // pack clamp ceiling (0x000000ff per lane)

    // y = clipTop
    ldr     w6, [x0, #A_CLIP_TOP]
    ldr     w9, [x0, #A_CLIP_RIGHT]

row_loop:
    ldr     w17, [x0, #A_CLIP_BOTTOM]
    cmp     w6, w17
    b.ge    finish

    // ── py0 = ((userTop + y*invScaleY) / unitY) * freqY ─────────────────────
    scvtf   d20, w6
    ldr     d21, [x0, #A_INV_SCALE_Y]
    fmul    d20, d20, d21
    ldr     d21, [x0, #A_USER_TOP]
    fadd    d20, d20, d21
    ldr     d21, [x0, #A_UNIT_Y]
    fdiv    d20, d20, d21
    ldr     d21, [x0, #A_FREQ_Y]
    fmul    d20, d20, d21
    str     d20, [sp, #S_PY0]

    // ── curtly = (y - clipTop) * baseFrequencyY ─────────────────────────────
    // d21 still holds freqY (fmul above), so no reload here.
    ldr     w17, [x0, #A_CLIP_TOP]
    sub     w17, w6, w17
    scvtf   d20, w17
    fmul    d20, d20, d21
    str     d20, [sp, #S_CTLY]

    // ── fxBase = ((userLeft + clipLeft*invScaleX) / unitX) * freqX ───────────
    ldr     w17, [x0, #A_CLIP_LEFT]
    scvtf   d20, w17
    ldr     d21, [x0, #A_INV_SCALE_X]
    fmul    d20, d20, d21
    ldr     d21, [x0, #A_USER_LEFT]
    fadd    d20, d20, d21
    ldr     d21, [x0, #A_UNIT_X]
    fdiv    d20, d20, d21
    ldr     d21, [x0, #A_FREQ_X]
    fmul    d20, d20, d21
    str     d20, [sp, #S_FX_BASE]

    // ── fxStep = invScaleX / unitX * freqX ───────────────────────────────────
    // d21 still holds freqX from the fxBase computation; hold unitX in d22
    // (free here — it is a gradient-load temp) so freqX survives without a
    // reload. Same fp operands → bit-identical result.
    ldr     d20, [x0, #A_INV_SCALE_X]
    ldr     d22, [x0, #A_UNIT_X]
    fdiv    d20, d20, d22
    fmul    d20, d20, d21
    str     d20, [sp, #S_FX_STEP]

    // ── curtlx base = 0 for clipLeft pixel, freqX for clipLeft+1 ─────────────
    fmov    d20, xzr
    str     d20, [sp, #S_CTLX_BASE]
    ldr     d20, [x0, #A_FREQ_X]
    str     d20, [sp, #S_CTLX1]

    // ── P1 fx = fxBase + fxStep ──────────────────────────────────────────────
    ldr     d20, [sp, #S_FX_BASE]
    ldr     d21, [sp, #S_FX_STEP]
    fadd    d20, d20, d21
    str     d20, [sp, #S_FX1]

    // ── row destination pointer = pixels + (y*width + clipLeft)*4 ─────────────
    ldr     x16, [sp, #S_PIXELS]
    ldr     w18, [x0, #A_CLIP_LEFT]
    ldr     w17, [x0, #A_WIDTH]
    madd    w17, w6, w17, w18
    add     x2, x16, x17, lsl #2

    ldr     w8, [x0, #A_CLIP_LEFT]

// ══════════════════════════════════════════════════════════════════════════════
// Two-pixel main loop.
// Processes pixels x and x+1 in a single iteration.
// ══════════════════════════════════════════════════════════════════════════════
pixel_loop_2:
    // Need at least 2 pixels remaining.
    add     w17, w8, #1
    cmp     w17, w9
    b.ge    tail_pixel                // fall through to single-pixel tail

    movi    v0.2d, #0                 // P0 sums ch 0/1
    movi    v1.2d, #0                 // P0 sums ch 2/3
    movi    v14.2d, #0                // P1 sums ch 0/1
    movi    v15.2d, #0                // P1 sums ch 2/3

    // ── Load per-pixel starting coordinates ──────────────────────────────────
    ldr     d24, [sp, #S_FX_BASE]     // fx0
    ldr     d25, [sp, #S_PY0]         // fy (shared)
    ldr     d26, [sp, #S_CTLX_BASE]   // curtlx0
    ldr     d27, [sp, #S_CTLY]        // curtly (shared)
    ldr     d28, const_1              // ratio = 1.0 (shared)

    ldr     w7, [x0, #A_OCTAVES]
    ldr     w10, [x0, #A_PERIOD_X]
    ldr     w11, [x0, #A_PERIOD_Y]

    cmp     w7, #0
    b.le    pack_pixel_pair

// ══════════════════════════════════════════════════════════════════════════════
// octave_loop_2
// Processes one octave for BOTH pixels.  The Y geometry (by0/by1/ry0/ry1/sy)
// is shared; X geometry is computed separately for each pixel.
// ══════════════════════════════════════════════════════════════════════════════
octave_loop_2:

    // ──────────────────────────────────────────────────────────────────────────
    //  Shared Y geometry (once per octave, used by both pixels)
    // ──────────────────────────────────────────────────────────────────────────
    ldr     d29, const_4096
    fadd    d29, d25, d29             // ty = fy + 4096
    fcvtms  x14, d29                  // by0_raw
    scvtf   d30, x14
    fsub    d10, d29, d30             // ry0
    ldr     d31, const_1
    fsub    d11, d10, d31             // ry1 = ry0 - 1
    add     x15, x14, #1             // by1_raw

    // Stitch Y
    cmp     w11, #0
    b.le    no_stitch_y_2
    fcvtms  x16, d27
    add     x16, x16, #4096
    add     x16, x16, x11
    cmp     x14, x16
    sub     x17, x14, x11
    csel    x14, x17, x14, hs
    cmp     x15, x16
    sub     x17, x15, x11
    csel    x15, x17, x15, hs
no_stitch_y_2:
    and     x14, x14, #255
    and     x15, x15, #255

    // P0's permutation will overwrite x14/x15 (by0/by1) — P1 needs them later.
    str     w14, [sp, #S_BY0]
    str     w15, [sp, #S_BY1]

    // Smoothstep sy = ry0*ry0*(3 - 2*ry0)
    fmul    d13, d10, d10
    ldr     d29, const_2
    fmul    d30, d10, d29
    ldr     d31, const_3
    fsub    d30, d31, d30
    fmul    d13, d13, d30

    // ──────────────────────────────────────────────────────────────────────────
    //  Pixel 0 — X geometry, permutation, gradients, lerp
    // ──────────────────────────────────────────────────────────────────────────

    // tx0/floor/rx0/rx1
    ldr     d29, const_4096
    fadd    d29, d24, d29
    fcvtms  x12, d29
    scvtf   d30, x12
    fsub    d8, d29, d30              // rx0
    ldr     d31, const_1
    fsub    d9, d8, d31               // rx1
    add     x13, x12, #1

    // Stitch X for P0
    cmp     w10, #0
    b.le    no_stitch_x_p0
    fcvtms  x16, d26
    add     x16, x16, #4096
    add     x16, x16, x10
    cmp     x12, x16
    sub     x17, x12, x10
    csel    x12, x17, x12, hs
    cmp     x13, x16
    sub     x17, x13, x10
    csel    x13, x17, x13, hs
no_stitch_x_p0:
    and     x12, x12, #255
    and     x13, x13, #255

    // Smoothstep sx0 = rx0*rx0*(3 - 2*rx0)
    fmul    d12, d8, d8
    ldr     d29, const_2
    fmul    d30, d8, d29
    ldr     d31, const_3
    fsub    d30, d31, d30
    fmul    d12, d12, d30

    // Permutation P0 (by0/by1 still live in x14/x15)
    ldr     w16, [x5, x12, lsl #2]
    ldr     w17, [x5, x13, lsl #2]
    add     w12, w16, w14
    ldr     w12, [x5, x12, lsl #2]
    add     w13, w17, w14
    ldr     w13, [x5, x13, lsl #2]
    add     w14, w16, w15
    ldr     w14, [x5, x14, lsl #2]
    add     w15, w17, w15
    ldr     w15, [x5, x15, lsl #2]

    // ── Gradients P0 channels 0/1 ────────────────────────────────────────────
    // Lattice row stride is 32 bytes; q-register indexing only scales <<4, so
    // pre-double the indices (x<<1 yields stride 32 via lsl #4).
    lsl     x12, x12, #1
    lsl     x13, x13, #1
    lsl     x14, x14, #1
    lsl     x15, x15, #1
    ldr     q16, [x3, x12, lsl #4]
    ldr     q17, [x4, x12, lsl #4]
    ldr     q18, [x3, x13, lsl #4]
    ldr     q19, [x4, x13, lsl #4]
    ldr     q20, [x3, x14, lsl #4]
    ldr     q21, [x4, x14, lsl #4]
    ldr     q22, [x3, x15, lsl #4]
    ldr     q23, [x4, x15, lsl #4]

    fmul    v2.2d, v16.2d, v8.d[0]
    fmla    v2.2d, v17.2d, v10.d[0]
    fmul    v3.2d, v18.2d, v9.d[0]
    fmla    v3.2d, v19.2d, v10.d[0]
    fmul    v4.2d, v20.2d, v8.d[0]
    fmla    v4.2d, v21.2d, v11.d[0]
    fmul    v5.2d, v22.2d, v9.d[0]
    fmla    v5.2d, v23.2d, v11.d[0]

    fsub    v6.2d, v3.2d, v2.2d
    fmla    v2.2d, v6.2d, v12.d[0]
    fsub    v6.2d, v5.2d, v4.2d
    fmla    v4.2d, v6.2d, v12.d[0]
    fsub    v6.2d, v4.2d, v2.2d
    fmla    v2.2d, v6.2d, v13.d[0]

    // Conditional fabs + accumulate P0 ch 0/1 (BIC with sign mask; v7 untouched)
    bic     v2.16b, v2.16b, v7.16b
    fmla    v0.2d, v2.2d, v28.d[0]

    // ── Gradients P0 channels 2/3 ────────────────────────────────────────────
    add     x16, x3, #16
    add     x17, x4, #16
    ldr     q16, [x16, x12, lsl #4]
    ldr     q17, [x17, x12, lsl #4]
    ldr     q18, [x16, x13, lsl #4]
    ldr     q19, [x17, x13, lsl #4]
    ldr     q20, [x16, x14, lsl #4]
    ldr     q21, [x17, x14, lsl #4]
    ldr     q22, [x16, x15, lsl #4]
    ldr     q23, [x17, x15, lsl #4]

    fmul    v2.2d, v16.2d, v8.d[0]
    fmla    v2.2d, v17.2d, v10.d[0]
    fmul    v3.2d, v18.2d, v9.d[0]
    fmla    v3.2d, v19.2d, v10.d[0]
    fmul    v4.2d, v20.2d, v8.d[0]
    fmla    v4.2d, v21.2d, v11.d[0]
    fmul    v5.2d, v22.2d, v9.d[0]
    fmla    v5.2d, v23.2d, v11.d[0]

    fsub    v6.2d, v3.2d, v2.2d
    fmla    v2.2d, v6.2d, v12.d[0]
    fsub    v6.2d, v5.2d, v4.2d
    fmla    v4.2d, v6.2d, v12.d[0]
    fsub    v6.2d, v4.2d, v2.2d
    fmla    v2.2d, v6.2d, v13.d[0]

    // Conditional fabs + accumulate P0 ch 2/3
    bic     v2.16b, v2.16b, v7.16b
    fmla    v1.2d, v2.2d, v28.d[0]

    // ──────────────────────────────────────────────────────────────────────────
    //  Pixel 1 — X geometry, permutation, gradients, lerp
    // ──────────────────────────────────────────────────────────────────────────
    // ry0/ry1/sy unchanged (shared).  Overwrite rx0/rx1/sx in d8/d9/d12.
    // by0/by1 are reloaded from the stack before the permutation.

    ldr     d29, [sp, #S_FX1]         // fx1
    ldr     d30, [sp, #S_CTLX1]       // curtlx1 (stays live in d30 for stitch)

    // tx1/floor/rx0/rx1
    ldr     d31, const_4096
    fadd    d29, d29, d31
    fcvtms  x12, d29
    scvtf   d31, x12                  // floor value into scratch (d30 = curtlx1 kept)
    fsub    d8, d29, d31              // rx0_p1
    ldr     d31, const_1
    fsub    d9, d8, d31               // rx1_p1
    add     x13, x12, #1

    // Stitch X for P1
    cmp     w10, #0
    b.le    no_stitch_x_p1
    fcvtms  x16, d30                  // d30 = curtlx1 (still live)
    add     x16, x16, #4096
    add     x16, x16, x10
    cmp     x12, x16
    sub     x17, x12, x10
    csel    x12, x17, x12, hs
    cmp     x13, x16
    sub     x17, x13, x10
    csel    x13, x17, x13, hs
no_stitch_x_p1:
    and     x12, x12, #255
    and     x13, x13, #255

    // Smoothstep sx1 = rx0_p1*rx0_p1*(3 - 2*rx0_p1)
    fmul    d12, d8, d8
    ldr     d29, const_2
    fmul    d30, d8, d29
    ldr     d31, const_3
    fsub    d30, d31, d30
    fmul    d12, d12, d30

    // Permutation P1 (restore by0/by1 — P0's permutation clobbered them)
    ldr     w14, [sp, #S_BY0]
    ldr     w15, [sp, #S_BY1]
    ldr     w16, [x5, x12, lsl #2]
    ldr     w17, [x5, x13, lsl #2]
    add     w12, w16, w14
    ldr     w12, [x5, x12, lsl #2]
    add     w13, w17, w14
    ldr     w13, [x5, x13, lsl #2]
    add     w14, w16, w15
    ldr     w14, [x5, x14, lsl #2]
    add     w15, w17, w15
    ldr     w15, [x5, x15, lsl #2]

    // ── Gradients P1 channels 0/1 ────────────────────────────────────────────
    lsl     x12, x12, #1
    lsl     x13, x13, #1
    lsl     x14, x14, #1
    lsl     x15, x15, #1
    ldr     q16, [x3, x12, lsl #4]
    ldr     q17, [x4, x12, lsl #4]
    ldr     q18, [x3, x13, lsl #4]
    ldr     q19, [x4, x13, lsl #4]
    ldr     q20, [x3, x14, lsl #4]
    ldr     q21, [x4, x14, lsl #4]
    ldr     q22, [x3, x15, lsl #4]
    ldr     q23, [x4, x15, lsl #4]

    fmul    v2.2d, v16.2d, v8.d[0]
    fmla    v2.2d, v17.2d, v10.d[0]
    fmul    v3.2d, v18.2d, v9.d[0]
    fmla    v3.2d, v19.2d, v10.d[0]
    fmul    v4.2d, v20.2d, v8.d[0]
    fmla    v4.2d, v21.2d, v11.d[0]
    fmul    v5.2d, v22.2d, v9.d[0]
    fmla    v5.2d, v23.2d, v11.d[0]

    fsub    v6.2d, v3.2d, v2.2d
    fmla    v2.2d, v6.2d, v12.d[0]
    fsub    v6.2d, v5.2d, v4.2d
    fmla    v4.2d, v6.2d, v12.d[0]
    fsub    v6.2d, v4.2d, v2.2d
    fmla    v2.2d, v6.2d, v13.d[0]

    // Conditional fabs + accumulate P1 ch 0/1
    bic     v2.16b, v2.16b, v7.16b
    fmla    v14.2d, v2.2d, v28.d[0]

    // ── Gradients P1 channels 2/3 ────────────────────────────────────────────
    add     x16, x3, #16
    add     x17, x4, #16
    ldr     q16, [x16, x12, lsl #4]
    ldr     q17, [x17, x12, lsl #4]
    ldr     q18, [x16, x13, lsl #4]
    ldr     q19, [x17, x13, lsl #4]
    ldr     q20, [x16, x14, lsl #4]
    ldr     q21, [x17, x14, lsl #4]
    ldr     q22, [x16, x15, lsl #4]
    ldr     q23, [x17, x15, lsl #4]

    fmul    v2.2d, v16.2d, v8.d[0]
    fmla    v2.2d, v17.2d, v10.d[0]
    fmul    v3.2d, v18.2d, v9.d[0]
    fmla    v3.2d, v19.2d, v10.d[0]
    fmul    v4.2d, v20.2d, v8.d[0]
    fmla    v4.2d, v21.2d, v11.d[0]
    fmul    v5.2d, v22.2d, v9.d[0]
    fmla    v5.2d, v23.2d, v11.d[0]

    fsub    v6.2d, v3.2d, v2.2d
    fmla    v2.2d, v6.2d, v12.d[0]
    fsub    v6.2d, v5.2d, v4.2d
    fmla    v4.2d, v6.2d, v12.d[0]
    fsub    v6.2d, v4.2d, v2.2d
    fmla    v2.2d, v6.2d, v13.d[0]

    // Conditional fabs + accumulate P1 ch 2/3
    bic     v2.16b, v2.16b, v7.16b
    fmla    v15.2d, v2.2d, v28.d[0]

    // ──────────────────────────────────────────────────────────────────────────
    //  Update coordinates for next octave (shared)
    // ──────────────────────────────────────────────────────────────────────────
    fadd    d24, d24, d24             // fx0 *= 2
    fadd    d25, d25, d25             // fy  *= 2
    fadd    d26, d26, d26             // curtlx0 *= 2
    fadd    d27, d27, d27             // curtly *= 2
    ldr     d29, const_half
    fmul    d28, d28, d29             // ratio *= 0.5

    // P1 coords on stack
    ldr     d29, [sp, #S_FX1]
    fadd    d29, d29, d29
    str     d29, [sp, #S_FX1]
    ldr     d29, [sp, #S_CTLX1]
    fadd    d29, d29, d29
    str     d29, [sp, #S_CTLX1]

    cmp     w10, #0
    b.le    no_double_x_2
    lsl     w10, w10, #1
no_double_x_2:
    cmp     w11, #0
    b.le    no_double_stitch_2
    lsl     w11, w11, #1
no_double_stitch_2:

    subs    w7, w7, #1
    b.ne    octave_loop_2

// ══════════════════════════════════════════════════════════════════════════════
// SIMD pixel packing for 2 pixels simultaneously.
//
// v0  = P0 [ch0, ch1]   v1  = P0 [ch2, ch3]
// v14 = P1 [ch0, ch1]   v15 = P1 [ch2, ch3]
//
// Pack into ARGB32: (A<<24)|(R<<16)|(G<<8)|B   (ch0=R, ch1=G, ch2=B, ch3=A)
// ══════════════════════════════════════════════════════════════════════════════
pack_pixel_pair:
    // v30 is clobbered every octave: d30 (its low 64 bits) is used as a
    // geometry scratch double (scvtf/fmul). The umin clamp below is only safe
    // with a live 255 ceiling, so re-establish it here. Nothing in pack needs
    // the scratch values, so this is safe and cheap.
    movi    v30.4s, #255

    // ── Load pre-built scale/offset/+0.5 vectors (see entry) ─────────────────
    ldr     q24, [sp, #S_PACK_SCALE]
    ldr     q25, [sp, #S_PACK_OFFSET]
    ldr     q26, [sp, #S_PACK_HALF]

    // ── Interleave channels across pixels ────────────────────────────────────
    // v0=[R0,G0], v14=[R1,G1] → zip → v2=[R0,R1], v3=[G0,G1]
    zip1    v2.2d, v0.2d, v14.2d
    zip2    v3.2d, v0.2d, v14.2d
    // v1=[B0,A0], v15=[B1,A1] → zip → v4=[B0,B1], v5=[A0,A1]
    zip1    v4.2d, v1.2d, v15.2d
    zip2    v5.2d, v1.2d, v15.2d

    // ── Scale → round → truncate (all 4 channel pairs) ───────────────────────
    fadd    v2.2d, v2.2d, v25.2d
    fmul    v2.2d, v2.2d, v24.2d
    fadd    v2.2d, v2.2d, v26.2d
    fcvtzs  v2.2d, v2.2d

    fadd    v3.2d, v3.2d, v25.2d
    fmul    v3.2d, v3.2d, v24.2d
    fadd    v3.2d, v3.2d, v26.2d
    fcvtzs  v3.2d, v3.2d

    fadd    v4.2d, v4.2d, v25.2d
    fmul    v4.2d, v4.2d, v24.2d
    fadd    v4.2d, v4.2d, v26.2d
    fcvtzs  v4.2d, v4.2d

    fadd    v5.2d, v5.2d, v25.2d
    fmul    v5.2d, v5.2d, v24.2d
    fadd    v5.2d, v5.2d, v26.2d
    fcvtzs  v5.2d, v5.2d

    // ── Saturate to [0, 2^32-1] then clamp to [0, 255] ───────────────────────
    // s64 → u32 saturate (negative → 0), then umin caps everything at 255.
    sqxtun  v2.2s, v2.2d
    sqxtun  v3.2s, v3.2d
    sqxtun  v4.2s, v4.2d
    sqxtun  v5.2s, v5.2d
    umin    v2.4s, v2.4s, v30.4s
    umin    v3.4s, v3.4s, v30.4s
    umin    v4.4s, v4.4s, v30.4s
    umin    v5.4s, v5.4s, v30.4s

    // ── Shift to final bit positions and OR-combine (ARGB32) ─────────────────
    // Note: lanes 2/3 contain garbage, but only lanes 0/1 are stored.
    shl     v2.4s, v2.4s, #16         // R << 16
    shl     v3.4s, v3.4s, #8          // G << 8
    shl     v5.4s, v5.4s, #24         // A << 24
    orr     v2.16b, v2.16b, v3.16b
    orr     v2.16b, v2.16b, v4.16b
    orr     v2.16b, v2.16b, v5.16b

    // Store 2 pixels (32-bit stores need only 4-byte alignment; odd clipLeft
    // makes the pixel pointer only 4-byte aligned).
    umov    w16, v2.s[0]
    umov    w17, v2.s[1]
    stp     w16, w17, [x2], #8

    // ── Advance per-row persistent x-state for 2 pixels ─────────────────────
    ldr     d20, [sp, #S_FX_BASE]
    ldr     d21, [sp, #S_FX_STEP]
    fadd    d20, d20, d21
    fadd    d20, d20, d21             // fxBase += 2 * fxStep
    str     d20, [sp, #S_FX_BASE]

    ldr     d20, [sp, #S_CTLX_BASE]
    ldr     d21, [x0, #A_FREQ_X]
    fadd    d20, d20, d21
    fadd    d20, d20, d21             // ctlxBase += 2 * freqX
    str     d20, [sp, #S_CTLX_BASE]

    // P1 fx/ctlx for next pair
    ldr     d20, [sp, #S_FX_BASE]
    ldr     d21, [sp, #S_FX_STEP]
    fadd    d20, d20, d21
    str     d20, [sp, #S_FX1]
    ldr     d20, [sp, #S_CTLX_BASE]
    ldr     d21, [x0, #A_FREQ_X]
    fadd    d20, d20, d21
    str     d20, [sp, #S_CTLX1]

    add     w8, w8, #2
    b       pixel_loop_2

// ══════════════════════════════════════════════════════════════════════════════
// Tail: single remaining pixel when width is odd.
// Reuses the same octave structure but only P0 accumulators.
// ══════════════════════════════════════════════════════════════════════════════
tail_pixel:
    cmp     w8, w9
    b.ge    next_row

    movi    v0.2d, #0
    movi    v1.2d, #0

    ldr     d24, [sp, #S_FX_BASE]
    ldr     d25, [sp, #S_PY0]
    ldr     d26, [sp, #S_CTLX_BASE]
    ldr     d27, [sp, #S_CTLY]
    ldr     d28, const_1

    ldr     w7, [x0, #A_OCTAVES]
    ldr     w10, [x0, #A_PERIOD_X]
    ldr     w11, [x0, #A_PERIOD_Y]

    cmp     w7, #0
    b.le    pack_single

tail_octave_loop:
    // Y geometry (shared — same as octave_loop_2)
    ldr     d29, const_4096
    fadd    d29, d25, d29
    fcvtms  x14, d29
    scvtf   d30, x14
    fsub    d10, d29, d30
    ldr     d31, const_1
    fsub    d11, d10, d31
    add     x15, x14, #1

    cmp     w11, #0
    b.le    no_stitch_y_tail
    fcvtms  x16, d27
    add     x16, x16, #4096
    add     x16, x16, x11
    cmp     x14, x16
    sub     x17, x14, x11
    csel    x14, x17, x14, hs
    cmp     x15, x16
    sub     x17, x15, x11
    csel    x15, x17, x15, hs
no_stitch_y_tail:
    and     x14, x14, #255
    and     x15, x15, #255

    fmul    d13, d10, d10
    ldr     d29, const_2
    fmul    d30, d10, d29
    ldr     d31, const_3
    fsub    d30, d31, d30
    fmul    d13, d13, d30

    // X geometry
    ldr     d29, const_4096
    fadd    d29, d24, d29
    fcvtms  x12, d29
    scvtf   d30, x12
    fsub    d8, d29, d30
    ldr     d31, const_1
    fsub    d9, d8, d31
    add     x13, x12, #1

    cmp     w10, #0
    b.le    no_stitch_x_tail
    fcvtms  x16, d26
    add     x16, x16, #4096
    add     x16, x16, x10
    cmp     x12, x16
    sub     x17, x12, x10
    csel    x12, x17, x12, hs
    cmp     x13, x16
    sub     x17, x13, x10
    csel    x13, x17, x13, hs
no_stitch_x_tail:
    and     x12, x12, #255
    and     x13, x13, #255

    fmul    d12, d8, d8
    ldr     d29, const_2
    fmul    d30, d8, d29
    ldr     d31, const_3
    fsub    d30, d31, d30
    fmul    d12, d12, d30

    // Permutation (by0/by1 live in x14/x15 — no P1 to worry about here)
    ldr     w16, [x5, x12, lsl #2]
    ldr     w17, [x5, x13, lsl #2]
    add     w12, w16, w14
    ldr     w12, [x5, x12, lsl #2]
    add     w13, w17, w14
    ldr     w13, [x5, x13, lsl #2]
    add     w14, w16, w15
    ldr     w14, [x5, x14, lsl #2]
    add     w15, w17, w15
    ldr     w15, [x5, x15, lsl #2]

    // Channels 0/1
    lsl     x12, x12, #1
    lsl     x13, x13, #1
    lsl     x14, x14, #1
    lsl     x15, x15, #1
    ldr     q16, [x3, x12, lsl #4]
    ldr     q17, [x4, x12, lsl #4]
    ldr     q18, [x3, x13, lsl #4]
    ldr     q19, [x4, x13, lsl #4]
    ldr     q20, [x3, x14, lsl #4]
    ldr     q21, [x4, x14, lsl #4]
    ldr     q22, [x3, x15, lsl #4]
    ldr     q23, [x4, x15, lsl #4]

    fmul    v2.2d, v16.2d, v8.d[0]
    fmla    v2.2d, v17.2d, v10.d[0]
    fmul    v3.2d, v18.2d, v9.d[0]
    fmla    v3.2d, v19.2d, v10.d[0]
    fmul    v4.2d, v20.2d, v8.d[0]
    fmla    v4.2d, v21.2d, v11.d[0]
    fmul    v5.2d, v22.2d, v9.d[0]
    fmla    v5.2d, v23.2d, v11.d[0]

    fsub    v6.2d, v3.2d, v2.2d
    fmla    v2.2d, v6.2d, v12.d[0]
    fsub    v6.2d, v5.2d, v4.2d
    fmla    v4.2d, v6.2d, v12.d[0]
    fsub    v6.2d, v4.2d, v2.2d
    fmla    v2.2d, v6.2d, v13.d[0]

    bic     v2.16b, v2.16b, v7.16b
    fmla    v0.2d, v2.2d, v28.d[0]

    // Channels 2/3
    add     x16, x3, #16
    add     x17, x4, #16
    ldr     q16, [x16, x12, lsl #4]
    ldr     q17, [x17, x12, lsl #4]
    ldr     q18, [x16, x13, lsl #4]
    ldr     q19, [x17, x13, lsl #4]
    ldr     q20, [x16, x14, lsl #4]
    ldr     q21, [x17, x14, lsl #4]
    ldr     q22, [x16, x15, lsl #4]
    ldr     q23, [x17, x15, lsl #4]

    fmul    v2.2d, v16.2d, v8.d[0]
    fmla    v2.2d, v17.2d, v10.d[0]
    fmul    v3.2d, v18.2d, v9.d[0]
    fmla    v3.2d, v19.2d, v10.d[0]
    fmul    v4.2d, v20.2d, v8.d[0]
    fmla    v4.2d, v21.2d, v11.d[0]
    fmul    v5.2d, v22.2d, v9.d[0]
    fmla    v5.2d, v23.2d, v11.d[0]

    fsub    v6.2d, v3.2d, v2.2d
    fmla    v2.2d, v6.2d, v12.d[0]
    fsub    v6.2d, v5.2d, v4.2d
    fmla    v4.2d, v6.2d, v12.d[0]
    fsub    v6.2d, v4.2d, v2.2d
    fmla    v2.2d, v6.2d, v13.d[0]

    bic     v2.16b, v2.16b, v7.16b
    fmla    v1.2d, v2.2d, v28.d[0]

    // Next octave
    fadd    d24, d24, d24
    fadd    d25, d25, d25
    fadd    d26, d26, d26
    fadd    d27, d27, d27
    ldr     d29, const_half
    fmul    d28, d28, d29

    cmp     w10, #0
    b.le    no_double_x_tail
    lsl     w10, w10, #1
no_double_x_tail:
    cmp     w11, #0
    b.le    no_double_stitch_tail
    lsl     w11, w11, #1
no_double_stitch_tail:

    subs    w7, w7, #1
    b.ne    tail_octave_loop

// ── Pack single pixel (scalar — one pixel, not worth SIMD) ──────────────────
pack_single:
    // Load pre-built pack scalars (lane 0 of the cached vectors, see entry).
    ldr     d20, [sp, #S_PACK_SCALE]   // scale
    ldr     d21, [sp, #S_PACK_OFFSET]  // offset
    ldr     d22, [sp, #S_PACK_HALF]    // +0.5

    fadd    d23, d0, d21
    fmul    d23, d23, d20
    fadd    d23, d23, d22
    fcvtzs  w12, d23

    fadd    d23, d1, d21
    fmul    d23, d23, d20
    fadd    d23, d23, d22
    fcvtzs  w13, d23

    fadd    d23, d2, d21
    fmul    d23, d23, d20
    fadd    d23, d23, d22
    fcvtzs  w14, d23

    fadd    d23, d3, d21
    fmul    d23, d23, d20
    fadd    d23, d23, d22
    fcvtzs  w15, d23

    mov     w16, #255
    cmp     w12, #0
    csel    w12, wzr, w12, lt
    cmp     w12, w16
    csel    w12, w16, w12, gt
    cmp     w13, #0
    csel    w13, wzr, w13, lt
    cmp     w13, w16
    csel    w13, w16, w13, gt
    cmp     w14, #0
    csel    w14, wzr, w14, lt
    cmp     w14, w16
    csel    w14, w16, w14, gt
    cmp     w15, #0
    csel    w15, wzr, w15, lt
    cmp     w15, w16
    csel    w15, w16, w15, gt

    orr     w16, w14, w13, lsl #8
    orr     w16, w16, w12, lsl #16
    orr     w16, w16, w15, lsl #24
    str     w16, [x2], #4

    // Advance x by 1 (single tail pixel)
    ldr     d20, [sp, #S_FX_BASE]
    ldr     d21, [sp, #S_FX_STEP]
    fadd    d20, d20, d21
    str     d20, [sp, #S_FX_BASE]
    ldr     d20, [sp, #S_CTLX_BASE]
    ldr     d21, [x0, #A_FREQ_X]
    fadd    d20, d20, d21
    str     d20, [sp, #S_CTLX_BASE]

    add     w8, w8, #1
    b       pixel_loop_2

next_row:
    add     w6, w6, #1
    b       row_loop

finish:
    ldp     d14, d15, [sp, #S_SAVE_D14]
    ldp     d12, d13, [sp, #S_SAVE_D12]
    ldp     d10, d11, [sp, #S_SAVE_D10]
    ldp     d8, d9,  [sp, #S_SAVE_D8]
    add     sp, sp, #S_SIZE
    ret

// ── Literal pool ────────────────────────────────────────────────────────────
.align 3
const_1:
    .double 1.0
const_2:
    .double 2.0
const_3:
    .double 3.0
const_4096:
    .double 4096.0
const_half:
    .double 0.5
const_127_5:
    .double 127.5
const_255:
    .double 255.0

.size turbulence64Asm, .-turbulence64Asm
