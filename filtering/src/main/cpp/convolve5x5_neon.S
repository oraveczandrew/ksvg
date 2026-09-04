.text
.align 2

.global ksvgConvolve5x5NeonAsm
.type ksvgConvolve5x5NeonAsm, %function

// AArch64 NEON 5x5 convolution.
//
// ABI:
//   x0 = dst              jint*
//   x1 = src              const jint*
//   w2 = width
//   w3 = height
//   x4 = kernel           const float* (25 floats)
//   s0 = divisor
//   s1 = bias
//
// Returns:
//   w0 = first interior x which was NOT processed.
//
// Specialization:
//   orderX  = 5
//   orderY  = 5
//   targetX = 2
//   targetY = 2
//   preserveAlpha = true
//   edgeMode = handled by caller
//
// The caller must only invoke this function for the interior region:
//
//   x >= 2
//   x <= width - 3
//   y >= 2
//   y <= height - 3
//
// This function processes 4 output pixels per iteration.
//
// For output x..x+3 it loads 8 source pixels:
//
//   x-2 ... x+5
//
// This gives the complete 5-pixel horizontal window for all four outputs.
//
// Pixel layout:
//   AARRGGBB
//
// Channel order in memory on little-endian AArch64:
//   B G R A
//
// Only RGB are convolved. Alpha is copied from the corresponding source
// pixel because preserveAlpha=true.

ksvgConvolve5x5NeonAsm:

    // ------------------------------------------------------------------
    // Prologue
    // ------------------------------------------------------------------

    stp     x19, x20, [sp, #-80]!
    stp     x21, x22, [sp, #16]
    stp     x23, x24, [sp, #32]
    stp     x25, x26, [sp, #48]
    stp     x27, x28, [sp, #64]

    mov     x19, x0                  // dst
    mov     x20, x1                  // src
    mov     w21, w2                  // width
    mov     w22, w3                  // height
    mov     x23, x4                  // kernel

    // y starts at 2.
    mov     w24, #2

    // Last interior row is height-3.
    // Exclusive end = height-2.
    sub     w25, w22, #2

    // ------------------------------------------------------------------
    // Constants
    // ------------------------------------------------------------------

    // v30 = 1 / divisor
    fmov    s2, #1.0
    fdiv    s2, s2, s0
    dup     v30.4s, v2.s[0]

    // v31 = bias * 255
    mov     w26, #255
    scvtf   s3, w26
    fmul    s3, s3, s1
    dup     v31.4s, v3.s[0]

    // ------------------------------------------------------------------
    // Y loop
    // ------------------------------------------------------------------

.Ly:

    cmp     w24, w25
    b.ge    .Ldone

    // Interior x starts at 2.
    mov     w26, #2

    // Exclusive end for interior pixels.
    //
    // Last valid interior x = width - 3
    // exclusive end       = width - 2
    sub     w27, w21, #2

    // ------------------------------------------------------------------
    // X loop
    // ------------------------------------------------------------------

.Lx:

    // Can we process four pixels?
    //
    // outputs: x, x+1, x+2, x+3
    //
    // Need x+3 <= width-3
    // => x+4 <= width-2
    //
    // w27 = width-2
    add     w28, w26, #4
    cmp     w28, w27
    b.gt    .Ltail

    // ------------------------------------------------------------------
    // Calculate source row pointers.
    //
    // The convolution for output y uses:
    //
    //   source rows y-2 ... y+2
    //
    // Each row starts at x-2.
    // ------------------------------------------------------------------

    // row y-2
    sub     w28, w24, #2
    mul     w28, w28, w21
    add     x9, x20, w28, uxtw #2

    // row y-1
    add     x10, x9, w21, uxtw #2

    // row y
    add     x11, x10, w21, uxtw #2

    // row y+1
    add     x12, x11, w21, uxtw #2

    // row y+2
    add     x13, x12, w21, uxtw #2

    // Move all rows from column 0 to x-2.
    add     x9,  x9,  w26, uxtw #2
    sub     x9,  x9,  #8

    add     x10, x10, w26, uxtw #2
    sub     x10, x10, #8

    add     x11, x11, w26, uxtw #2
    sub     x11, x11, #8

    add     x12, x12, w26, uxtw #2
    sub     x12, x12, #8

    add     x13, x13, w26, uxtw #2
    sub     x13, x13, #8

    // ------------------------------------------------------------------
    // Accumulators
    //
    // v14 = B
    // v15 = G
    // v16 = R
    //
    // Four output pixels in each vector.
    // ------------------------------------------------------------------

    movi    v14.4s, #0
    movi    v15.4s, #0
    movi    v16.4s, #0

    // ================================================================
    // ROW 0
    // ================================================================

    ld4     {v0.8b, v1.8b, v2.8b, v3.8b}, [x9]

    // B
    uxtl    v0.8h, v0.8b

    // G
    uxtl    v1.8h, v1.8b

    // R
    uxtl    v2.8h, v2.8b

    // B -> uint32
    uxtl    v4.4s, v0.4h
    uxtl2   v5.4s, v0.8h

    // G -> uint32
    uxtl    v6.4s, v1.4h
    uxtl2   v7.4s, v1.8h

    // R -> uint32
    uxtl    v8.4s, v2.4h
    uxtl2   v9.4s, v2.8h

    // uint32 -> float
    ucvtf   v4.4s, v4.4s
    ucvtf   v5.4s, v5.4s

    ucvtf   v6.4s, v6.4s
    ucvtf   v7.4s, v7.4s

    ucvtf   v8.4s, v8.4s
    ucvtf   v9.4s, v9.4s

    // Kernel row 0.
    ldr     s10, [x23, #0]
    dup     v10.4s, v10.s[0]

    ldr     s11, [x23, #4]
    dup     v11.4s, v11.s[0]

    ldr     s12, [x23, #8]
    dup     v12.4s, v12.s[0]

    ldr     s13, [x23, #12]
    dup     v13.4s, v13.s[0]

    ldr     s17, [x23, #16]
    dup     v17.4s, v17.s[0]

    // tap 0: pixels 0..3
    fmla    v14.4s, v4.4s, v10.4s
    fmla    v15.4s, v6.4s, v10.4s
    fmla    v16.4s, v8.4s, v10.4s

    // tap 1: pixels 1..4
    ext     v18.16b, v4.16b, v5.16b, #4
    ext     v19.16b, v6.16b, v7.16b, #4
    ext     v20.16b, v8.16b, v9.16b, #4

    fmla    v14.4s, v18.4s, v11.4s
    fmla    v15.4s, v19.4s, v11.4s
    fmla    v16.4s, v20.4s, v11.4s

    // tap 2: pixels 2..5
    ext     v18.16b, v4.16b, v5.16b, #8
    ext     v19.16b, v6.16b, v7.16b, #8
    ext     v20.16b, v8.16b, v9.16b, #8

    fmla    v14.4s, v18.4s, v12.4s
    fmla    v15.4s, v19.4s, v12.4s
    fmla    v16.4s, v20.4s, v12.4s

    // tap 3: pixels 3..6
    ext     v18.16b, v4.16b, v5.16b, #12
    ext     v19.16b, v6.16b, v7.16b, #12
    ext     v20.16b, v8.16b, v9.16b, #12

    fmla    v14.4s, v18.4s, v13.4s
    fmla    v15.4s, v19.4s, v13.4s
    fmla    v16.4s, v20.4s, v13.4s

    // tap 4: pixels 4..7
    fmla    v14.4s, v5.4s, v17.4s
    fmla    v15.4s, v7.4s, v17.4s
    fmla    v16.4s, v9.4s, v17.4s

    // ================================================================
    // ROW 1
    // ================================================================

    ld4     {v0.8b, v1.8b, v2.8b, v3.8b}, [x10]

    uxtl    v0.8h, v0.8b
    uxtl    v1.8h, v1.8b
    uxtl    v2.8h, v2.8b

    uxtl    v4.4s, v0.4h
    uxtl2   v5.4s, v0.8h

    uxtl    v6.4s, v1.4h
    uxtl2   v7.4s, v1.8h

    uxtl    v8.4s, v2.4h
    uxtl2   v9.4s, v2.8h

    ucvtf   v4.4s, v4.4s
    ucvtf   v5.4s, v5.4s
    ucvtf   v6.4s, v6.4s
    ucvtf   v7.4s, v7.4s
    ucvtf   v8.4s, v8.4s
    ucvtf   v9.4s, v9.4s

    ldr     s10, [x23, #20]
    dup     v10.4s, v10.s[0]

    ldr     s11, [x23, #24]
    dup     v11.4s, v11.s[0]

    ldr     s12, [x23, #28]
    dup     v12.4s, v12.s[0]

    ldr     s13, [x23, #32]
    dup     v13.4s, v13.s[0]

    ldr     s17, [x23, #36]
    dup     v17.4s, v17.s[0]

    fmla    v14.4s, v4.4s, v10.4s
    fmla    v15.4s, v6.4s, v10.4s
    fmla    v16.4s, v8.4s, v10.4s

    ext     v18.16b, v4.16b, v5.16b, #4
    ext     v19.16b, v6.16b, v7.16b, #4
    ext     v20.16b, v8.16b, v9.16b, #4

    fmla    v14.4s, v18.4s, v11.4s
    fmla    v15.4s, v19.4s, v11.4s
    fmla    v16.4s, v20.4s, v11.4s

    ext     v18.16b, v4.16b, v5.16b, #8
    ext     v19.16b, v6.16b, v7.16b, #8
    ext     v20.16b, v8.16b, v9.16b, #8

    fmla    v14.4s, v18.4s, v12.4s
    fmla    v15.4s, v19.4s, v12.4s
    fmla    v16.4s, v20.4s, v12.4s

    ext     v18.16b, v4.16b, v5.16b, #12
    ext     v19.16b, v6.16b, v7.16b, #12
    ext     v20.16b, v8.16b, v9.16b, #12

    fmla    v14.4s, v18.4s, v13.4s
    fmla    v15.4s, v19.4s, v13.4s
    fmla    v16.4s, v20.4s, v13.4s

    fmla    v14.4s, v5.4s, v17.4s
    fmla    v15.4s, v7.4s, v17.4s
    fmla    v16.4s, v9.4s, v17.4s

    // ================================================================
    // ROW 2
    // ================================================================

    ld4     {v0.8b, v1.8b, v2.8b, v3.8b}, [x11]

    uxtl    v0.8h, v0.8b
    uxtl    v1.8h, v1.8b
    uxtl    v2.8h, v2.8b

    uxtl    v4.4s, v0.4h
    uxtl2   v5.4s, v0.8h

    uxtl    v6.4s, v1.4h
    uxtl2   v7.4s, v1.8h

    uxtl    v8.4s, v2.4h
    uxtl2   v9.4s, v2.8h

    ucvtf   v4.4s, v4.4s
    ucvtf   v5.4s, v5.4s
    ucvtf   v6.4s, v6.4s
    ucvtf   v7.4s, v7.4s
    ucvtf   v8.4s, v8.4s
    ucvtf   v9.4s, v9.4s

    ldr     s10, [x23, #40]
    dup     v10.4s, v10.s[0]

    ldr     s11, [x23, #44]
    dup     v11.4s, v11.s[0]

    ldr     s12, [x23, #48]
    dup     v12.4s, v12.s[0]

    ldr     s13, [x23, #52]
    dup     v13.4s, v13.s[0]

    ldr     s17, [x23, #56]
    dup     v17.4s, v17.s[0]

    fmla    v14.4s, v4.4s, v10.4s
    fmla    v15.4s, v6.4s, v10.4s
    fmla    v16.4s, v8.4s, v10.4s

    ext     v18.16b, v4.16b, v5.16b, #4
    ext     v19.16b, v6.16b, v7.16b, #4
    ext     v20.16b, v8.16b, v9.16b, #4

    fmla    v14.4s, v18.4s, v11.4s
    fmla    v15.4s, v19.4s, v11.4s
    fmla    v16.4s, v20.4s, v11.4s

    ext     v18.16b, v4.16b, v5.16b, #8
    ext     v19.16b, v6.16b, v7.16b, #8
    ext     v20.16b, v8.16b, v9.16b, #8

    fmla    v14.4s, v18.4s, v12.4s
    fmla    v15.4s, v19.4s, v12.4s
    fmla    v16.4s, v20.4s, v12.4s

    ext     v18.16b, v4.16b, v5.16b, #12
    ext     v19.16b, v6.16b, v7.16b, #12
    ext     v20.16b, v8.16b, v9.16b, #12

    fmla    v14.4s, v18.4s, v13.4s
    fmla    v15.4s, v19.4s, v13.4s
    fmla    v16.4s, v20.4s, v13.4s

    fmla    v14.4s, v5.4s, v17.4s
    fmla    v15.4s, v7.4s, v17.4s
    fmla    v16.4s, v9.4s, v17.4s

    // ================================================================
    // ROW 3
    // ================================================================

    ld4     {v0.8b, v1.8b, v2.8b, v3.8b}, [x12]

    uxtl    v0.8h, v0.8b
    uxtl    v1.8h, v1.8b
    uxtl    v2.8h, v2.8b

    uxtl    v4.4s, v0.4h
    uxtl2   v5.4s, v0.8h

    uxtl    v6.4s, v1.4h
    uxtl2   v7.4s, v1.8h

    uxtl    v8.4s, v2.4h
    uxtl2   v9.4s, v2.8h

    ucvtf   v4.4s, v4.4s
    ucvtf   v5.4s, v5.4s
    ucvtf   v6.4s, v6.4s
    ucvtf   v7.4s, v7.4s
    ucvtf   v8.4s, v8.4s
    ucvtf   v9.4s, v9.4s

    ldr     s10, [x23, #60]
    dup     v10.4s, v10.s[0]

    ldr     s11, [x23, #64]
    dup     v11.4s, v11.s[0]

    ldr     s12, [x23, #68]
    dup     v12.4s, v12.s[0]

    ldr     s13, [x23, #72]
    dup     v13.4s, v13.s[0]

    ldr     s17, [x23, #76]
    dup     v17.4s, v17.s[0]

    fmla    v14.4s, v4.4s, v10.4s
    fmla    v15.4s, v6.4s, v10.4s
    fmla    v16.4s, v8.4s, v10.4s

    ext     v18.16b, v4.16b, v5.16b, #4
    ext     v19.16b, v6.16b, v7.16b, #4
    ext     v20.16b, v8.16b, v9.16b, #4

    fmla    v14.4s, v18.4s, v11.4s
    fmla    v15.4s, v19.4s, v11.4s
    fmla    v16.4s, v20.4s, v11.4s

    ext     v18.16b, v4.16b, v5.16b, #8
    ext     v19.16b, v6.16b, v7.16b, #8
    ext     v20.16b, v8.16b, v9.16b, #8

    fmla    v14.4s, v18.4s, v12.4s
    fmla    v15.4s, v19.4s, v12.4s
    fmla    v16.4s, v20.4s, v12.4s

    ext     v18.16b, v4.16b, v5.16b, #12
    ext     v19.16b, v6.16b, v7.16b, #12
    ext     v20.16b, v8.16b, v9.16b, #12

    fmla    v14.4s, v18.4s, v13.4s
    fmla    v15.4s, v19.4s, v13.4s
    fmla    v16.4s, v20.4s, v13.4s

    fmla    v14.4s, v5.4s, v17.4s
    fmla    v15.4s, v7.4s, v17.4s
    fmla    v16.4s, v9.4s, v17.4s

    // ================================================================
    // ROW 4
    // ================================================================

    ld4     {v0.8b, v1.8b, v2.8b, v3.8b}, [x13]

    uxtl    v0.8h, v0.8b
    uxtl    v1.8h, v1.8b
    uxtl    v2.8h, v2.8b

    uxtl    v4.4s, v0.4h
    uxtl2   v5.4s, v0.8h

    uxtl    v6.4s, v1.4h
    uxtl2   v7.4s, v1.8h

    uxtl    v8.4s, v2.4h
    uxtl2   v9.4s, v2.8h

    ucvtf   v4.4s, v4.4s
    ucvtf   v5.4s, v5.4s
    ucvtf   v6.4s, v6.4s
    ucvtf   v7.4s, v7.4s
    ucvtf   v8.4s, v8.4s
    ucvtf   v9.4s, v9.4s

    ldr     s10, [x23, #80]
    dup     v10.4s, v10.s[0]

    ldr     s11, [x23, #84]
    dup     v11.4s, v11.s[0]

    ldr     s12, [x23, #88]
    dup     v12.4s, v12.s[0]

    ldr     s13, [x23, #92]
    dup     v13.4s, v13.s[0]

    ldr     s17, [x23, #96]
    dup     v17.4s, v17.s[0]

    fmla    v14.4s, v4.4s, v10.4s
    fmla    v15.4s, v6.4s, v10.4s
    fmla    v16.4s, v8.4s, v10.4s

    ext     v18.16b, v4.16b, v5.16b, #4
    ext     v19.16b, v6.16b, v7.16b, #4
    ext     v20.16b, v8.16b, v9.16b, #4

    fmla    v14.4s, v18.4s, v11.4s
    fmla    v15.4s, v19.4s, v11.4s
    fmla    v16.4s, v20.4s, v11.4s

    ext     v18.16b, v4.16b, v5.16b, #8
    ext     v19.16b, v6.16b, v7.16b, #8
    ext     v20.16b, v8.16b, v9.16b, #8

    fmla    v14.4s, v18.4s, v12.4s
    fmla    v15.4s, v19.4s, v12.4s
    fmla    v16.4s, v20.4s, v12.4s

    ext     v18.16b, v4.16b, v5.16b, #12
    ext     v19.16b, v6.16b, v7.16b, #12
    ext     v20.16b, v8.16b, v9.16b, #12

    fmla    v14.4s, v18.4s, v13.4s
    fmla    v15.4s, v19.4s, v13.4s
    fmla    v16.4s, v20.4s, v13.4s

    fmla    v14.4s, v5.4s, v17.4s
    fmla    v15.4s, v7.4s, v17.4s
    fmla    v16.4s, v9.4s, v17.4s

    // ================================================================
    // Normalize
    // ================================================================

    fmul    v14.4s, v14.4s, v30.4s
    fmul    v15.4s, v15.4s, v30.4s
    fmul    v16.4s, v16.4s, v30.4s

    fadd    v14.4s, v14.4s, v31.4s
    fadd    v15.4s, v15.4s, v31.4s
    fadd    v16.4s, v16.4s, v31.4s

    // Scalar reference uses clamp255(float).
    // Add 0.5 and floor gives the same positive-value rounding behavior.
    fmov    v29.4s, #0.5

    fadd    v14.4s, v14.4s, v29.4s
    fadd    v15.4s, v15.4s, v29.4s
    fadd    v16.4s, v16.4s, v29.4s

    frintm  v14.4s, v14.4s
    frintm  v15.4s, v15.4s
    frintm  v16.4s, v16.4s

    // Clamp [0,255].
    movi    v28.4s, #0
    movi    v29.4s, #255

    fmax    v14.4s, v14.4s, v28.4s
    fmin    v14.4s, v14.4s, v29.4s

    fmax    v15.4s, v15.4s, v28.4s
    fmin    v15.4s, v15.4s, v29.4s

    fmax    v16.4s, v16.4s, v28.4s
    fmin    v16.4s, v16.4s, v29.4s

    fcvtzs  v14.4s, v14.4s
    fcvtzs  v15.4s, v15.4s
    fcvtzs  v16.4s, v16.4s

    // ================================================================
    // Preserve alpha from SOURCE
    // ================================================================

    // src[y * width + x]
    mul     w28, w24, w21
    add     x9, x20, w28, uxtw #2
    add     x9, x9, w26, uxtw #2

    ld1     {v21.4s}, [x9]

    // Keep only A.
    ushr    v21.4s, v21.4s, #24
    shl     v21.4s, v21.4s, #24

    // ================================================================
    // Pack RGB
    // ================================================================

    // R << 16
    shl     v16.4s, v16.4s, #16

    // G << 8
    shl     v15.4s, v15.4s, #8

    orr     v16.16b, v16.16b, v15.16b
    orr     v16.16b, v16.16b, v14.16b
    orr     v16.16b, v16.16b, v21.16b

    // Destination address.
    // Recalculate because x9 currently points to source.
    mul     w28, w24, w21
    add     x9, x19, w28, uxtw #2
    add     x9, x9, w26, uxtw #2

    st1     {v16.4s}, [x9]

    // Four outputs completed.
    add     w26, w26, #4
    b       .Lx

    // ================================================================
    // Tail
    // ================================================================

.Ltail:
    // Caller processes x=w0 .. interiorEnd itself.
    mov     w0, w26
    b       .Lreturn

    // ================================================================
    // No more interior rows
    // ================================================================

.Ldone:
    mov     w0, #2

.Lreturn:

    ldp     x27, x28, [sp, #64]
    ldp     x25, x26, [sp, #48]
    ldp     x23, x24, [sp, #32]
    ldp     x21, x22, [sp, #16]
    ldp     x19, x20, [sp], #80

    ret

.size ksvgConvolve5x5NeonAsm, .-ksvgConvolve5x5NeonAsm