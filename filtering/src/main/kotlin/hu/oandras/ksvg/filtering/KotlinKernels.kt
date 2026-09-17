/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.filtering

import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Pure-Kotlin reference kernels over unpremultiplied ARGB_8888 IntArrays.
 *
 * These are the scalar reference implementations of the native kernels in this
 * module ([ComponentTransferNative], [ConvolveNative], [MorphologyNative]):
 * they run on JVMs where `libksvgblur` cannot load (Robolectric unit tests) and
 * serve as the executable specification the C++ ports must match bit-exactly.
 *
 * All functions are stateless, allocation-free (caller-owned arrays) and take
 * plain parameters so this module has no dependency on SVG/DOM types; mapping
 * DOM attributes to kernel parameters happens in the `:ksvg` module.
 */
@Suppress("NOTHING_TO_INLINE")
public object KotlinKernels {

    private fun clamp255(value: Float): Int =
        value.roundToInt().coerceIn(0, 255)

    private fun clamp255(value: Double): Int =
        value.roundToInt().coerceIn(0, 255)

    internal inline fun argb(alpha: Int, red: Int, green: Int, blue: Int): Int =
        (alpha shl 24) or (red shl 16) or (green shl 8) or blue

    @Suppress("SameParameterValue")
    private inline fun clamp(v: Float, min: Float, max: Float): Float =
        v.coerceIn(min, max)

    @Suppress("SameParameterValue")
    private inline fun clamp(v: Int, min: Int, max: Int): Int =
        v.coerceIn(min, max)

    private fun sampleCoordinate(coordinate: Int, limit: Int, edgeMode: Int): Int =
        if (coordinate in 0 until limit) coordinate else when (edgeMode) {
            2 -> -1
            1 -> {
                val m = coordinate % limit
                if (m < 0) m + limit else m
            }

            else -> if (coordinate < 0) 0 else limit - 1
        }

    private fun channelValue(p: Int, ch: Int): Float = when (ch) {
        0 -> ((p shr 16) and 0xFF) / 255f
        1 -> ((p shr 8) and 0xFF) / 255f
        2 -> (p and 0xFF) / 255f
        else -> ((p shr 24) and 0xFF) / 255f
    }

    // ---------------------------------------------------------------- convolve

    /**
     * feConvolveMatrix. [edgeMode]: 0=duplicate(clamp), 1=wrap, 2=none
     * (`ConvolveMatrixEdgeMode` ordinal in `:ksvg`). Bit-exact reference for
     * `convolve_matrix.cpp`.
     */
    public fun convolveMatrix(
        srcPixels: IntArray,
        outPixels: IntArray,
        width: Int,
        height: Int,
        kernel: FloatArray,
        orderX: Int,
        orderY: Int,
        targetX: Int,
        targetY: Int,
        divisor: Float,
        bias: Float,
        preserveAlpha: Boolean,
        edgeMode: Int,
    ) {
        val bias255 = bias * 255f

        // Fast interior path: no edge handling is needed because every sampled
        // coordinate is guaranteed to be inside the image.
        val interiorLeft = maxOf(0, targetX)
        val interiorTop = maxOf(0, targetY)
        val interiorRight = minOf(width, width - (orderX - 1 - targetX))
        val interiorBottom = minOf(height, height - (orderY - 1 - targetY))

        for (y in 0 until height) {
            val rowOffset = y * width

            val interiorY = y >= interiorTop && y < interiorBottom
            for (x in 0 until width) {
                val interior = interiorY && x >= interiorLeft && x < interiorRight

                var r = 0f
                var g = 0f
                var b = 0f
                var a = 0f

                if (interior) {
                    for (ky in 0 until orderY) {
                        val srcRowOffset = (y + ky - targetY) * width
                        var kernelIndex = ky * orderX
                        for (kx in 0 until orderX) {
                            val pixel = srcPixels[srcRowOffset + x + kx - targetX]
                            val weight = kernel[kernelIndex++]

                            r += ((pixel shr 16) and 0xFF) * weight
                            g += ((pixel shr 8) and 0xFF) * weight
                            b += (pixel and 0xFF) * weight
                            if (!preserveAlpha) {
                                a += ((pixel shr 24) and 0xFF) * weight
                            }
                        }
                    }
                } else {
                    for (ky in 0 until orderY) {
                        val srcY = sampleCoordinate(y + ky - targetY, height, edgeMode)
                        val srcRowOffset = if (srcY < 0) 0 else srcY * width
                        var kernelIndex = ky * orderX

                        for (kx in 0 until orderX) {
                            val srcX = sampleCoordinate(x + kx - targetX, width, edgeMode)
                            val pixel = if (srcX < 0 || srcY < 0) 0 else srcPixels[srcRowOffset + srcX]
                            val weight = kernel[kernelIndex++]

                            r += ((pixel shr 16) and 0xFF) * weight
                            g += ((pixel shr 8) and 0xFF) * weight
                            b += (pixel and 0xFF) * weight
                            if (!preserveAlpha) {
                                a += ((pixel shr 24) and 0xFF) * weight
                            }
                        }
                    }
                }

                val outR = clamp255(r / divisor + bias255)
                val outG = clamp255(g / divisor + bias255)
                val outB = clamp255(b / divisor + bias255)
                val outA = if (preserveAlpha) {
                    srcPixels[rowOffset + x] ushr 24
                } else {
                    clamp255(a / divisor + bias255)
                }

                outPixels[rowOffset + x] =
                    (outA shl 24) or
                    (outR shl 16) or
                    (outG shl 8) or
                    outB
            }
        }
    }

    // -------------------------------------------------------------- morphology

    /**
     * feMorphology: per-channel min/max on all four channels, transparent-black
     * padding semantics, clip-region-only output (dst pre-zeroed here).
     * Bit-exact reference for `morphology.cpp`.
     */
    public fun morphology(
        src: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
        radiusX: Int,
        radiusY: Int,
        erode: Boolean,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
    ) {
        dst.fill(0)
        // Separable min/max: a 2D window min/max equals the column pass over
        // row-pass results (min/max are associative), so (2r+1)^2 taps become
        // ~2*(2r+1). The packed intermediate round-trips exactly (channels live
        // in disjoint bits, values stay masked), and the clamped index sets
        // below are identical to the original 2D windows.
        val tmp = IntArray(width * height)
        if (erode) {
            val rInit = 255 shl 16
            val gInit = 255 shl 8
            val firstY = maxOf(clipTop, radiusY)
            val lastY = minOf(clipBottom, height - radiusY)
            val firstX = maxOf(clipLeft, radiusX)
            val lastX = minOf(clipRight, width - radiusX)
            // Phase 1 covers every row phase 2 will read: the column pass
            // reaches radiusY above/below the interior rows, and unwritten
            // tmp rows would read as zero. Bounds hold by construction of
            // firstY/lastY (0 <= firstY-radiusY, lastY+radiusY <= height).
            for (y in firstY - radiusY until lastY + radiusY) {
                val rowOffset = y * width
                for (x in firstX until lastX) {
                    // Phase 1 (rows): per-channel min over the in-bounds
                    // horizontal segment [x-radiusX, x+radiusX].
                    var a = 255
                    var r = rInit
                    var g = gInit
                    var b = 255
                    for (kx in x - radiusX..x + radiusX) {
                        val color = src[rowOffset + kx]
                        a = minOf(a, color ushr 24)
                        r = minOf(r, color and 0xFF0000)
                        g = minOf(g, color and 0xFF00)
                        b = minOf(b, color and 0xFF)
                    }
                    tmp[rowOffset + x] = (a shl 24) or r or g or b
                }
            }
            for (y in firstY until lastY) {
                val rowOffset = y * width
                val top = y - radiusY
                val bottom = y + radiusY
                for (x in firstX until lastX) {
                    // Phase 2 (columns): per-channel min over the in-bounds
                    // vertical segment of phase-1 results.
                    var a = 255
                    var r = rInit
                    var g = gInit
                    var b = 255
                    for (ky in top..bottom) {
                        val color = tmp[ky * width + x]
                        a = minOf(a, color ushr 24)
                        r = minOf(r, color and 0xFF0000)
                        g = minOf(g, color and 0xFF00)
                        b = minOf(b, color and 0xFF)
                    }
                    dst[rowOffset + x] = (a shl 24) or r or g or b
                }
            }
        } else {
            // Dilate covers the full clip rect with per-pixel clamped windows.
            // Phase 1 must span every row phase 2 reads (radiusY beyond the
            // clip rows on both sides, clamped into the image).
            val phaseTop = maxOf(0, clipTop - radiusY)
            val phaseBottom = minOf(height, clipBottom + radiusY)
            for (y in phaseTop until phaseBottom) {
                val rowOffset = y * width
                for (x in clipLeft until clipRight) {
                    // Phase 1 (rows): per-channel max over the clamped
                    // horizontal segment (identical indices to the original
                    // interior fast path where it applied).
                    var a = 0
                    var r = 0
                    var g = 0
                    var b = 0
                    val left = maxOf(0, x - radiusX)
                    val right = minOf(width - 1, x + radiusX)
                    for (kx in left..right) {
                        val color = src[rowOffset + kx]
                        a = maxOf(a, color ushr 24)
                        r = maxOf(r, color and 0xFF0000)
                        g = maxOf(g, color and 0xFF00)
                        b = maxOf(b, color and 0xFF)
                    }
                    tmp[rowOffset + x] = (a shl 24) or r or g or b
                }
            }
            for (y in clipTop until clipBottom) {
                val rowOffset = y * width
                val top = maxOf(0, y - radiusY)
                val bottom = minOf(height - 1, y + radiusY)
                for (x in clipLeft until clipRight) {
                    // Phase 2 (columns): per-channel max over the clamped
                    // vertical segment of phase-1 results.
                    var a = 0
                    var r = 0
                    var g = 0
                    var b = 0
                    for (ky in top..bottom) {
                        val color = tmp[ky * width + x]
                        a = maxOf(a, color ushr 24)
                        r = maxOf(r, color and 0xFF0000)
                        g = maxOf(g, color and 0xFF00)
                        b = maxOf(b, color and 0xFF)
                    }
                    dst[rowOffset + x] = (a shl 24) or r or g or b
                }
            }
        }
    }

    // ------------------------------------------------------ component transfer

    /**
     * feComponentTransfer through four precomputed per-channel 256-entry byte
     * tables (built by the caller — the table construction depends on DOM
     * attribute parsing which stays in `:ksvg`). Pixels outside the clip become
     * transparent black. Bit-exact reference for `component_transfer.cpp`.
     */
    public fun componentTransfer(
        src: IntArray,
        dst: IntArray,
        width: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        tableA: IntArray,
        tableR: IntArray,
        tableG: IntArray,
        tableB: IntArray,
    ) {
        dst.fill(0)
        for (y in clipTop until clipBottom) {
            val rowOffset = y * width
            for (x in clipLeft until clipRight) {
                val c = src[rowOffset + x]
                dst[rowOffset + x] =
                    tableA[(c shr 24) and 0xFF] or
                            tableR[(c shr 16) and 0xFF] or
                            tableG[(c shr 8) and 0xFF] or
                            tableB[c and 0xFF]
            }
        }
    }

    // --------------------------------------------------------------- unLinearize

    /**
     * Converts a single straight (non-premultiplied) linear-RGB pixel to straight
     * sRGB using [linearToSrgb] (normally [ColorLuts.LINEAR_TO_SRGB]): each color channel is looked
     * up and alpha is preserved unchanged. Element-wise reference for both
     * [unLinearize] and `unlinearize.cpp`'s scalar loop.
     */
    context(linearToSrgb: LinearToSrgb)
    internal inline fun unLinearizeArgb(pixel: Int): Int {
        return (pixel and 0xFF000000.toInt()) or
                (linearToSrgb[pixel ushr 16] shl 16) or
                (linearToSrgb[pixel ushr 8] shl 8) or
                linearToSrgb[pixel]
    }

    /**
     * Linear→sRGB (unLinearize) filter-output transfer over straight ARGB_8888
     * pixels. Each pixel's straight R/G/B channel is looked up using [linearToSrgb]
     * and alpha is passed through unchanged (identical to
     * [unLinearizeArgb]). Element-wise byte map, so [src] and [dst] may be the
     * same array (in-place). Bit-exact reference for `unlinearize.cpp`.
     */
    context(linearToSrgb: LinearToSrgb)
    private fun unLinearizeImpl(
        src: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
    ) {
        val total = width * height
        for (i in 0 until total) {
            dst[i] = unLinearizeArgb(src[i])
        }
    }

    public fun unLinearize(
        src: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
    ) {
        with(ColorLuts.LINEAR_TO_SRGB) {
            unLinearizeImpl(src, dst, width, height)
        }
    }

    // ---------------------------------------------------------------- lighting

    /**
     * feDiffuseLighting / feSpecularLighting. [params] packing matches
     * [LightingNative.apply]: distant -> [azimuthDeg, elevationDeg];
     * point -> [x, y, z]; spot -> [x, y, z, pointsAtX/Y/Z, coneAngleDeg]
     * (NaN = no cone). Bit-exact reference for `lighting.cpp`.
     */
    context(linearToSrgb: LinearToSrgb, sRgbToLinear: SrgbToLinear)
    private fun lightingImpl(
        pix: IntArray,
        out: IntArray,
        width: Int,
        height: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        surfaceScaleNormalized: Float,
        invCanvasScaleX: Double,
        invCanvasScaleY: Double,
        userLeft: Double,
        userTop: Double,
        originX: Double,
        originY: Double,
        unitSizeX: Double,
        unitSizeY: Double,
        canvasScaleX: Float,
        canvasScaleY: Float,
        @LightType lightType: Int,
        specular: Boolean,
        k: Float,
        exponent: Float,
        lightR: Int,
        lightG: Int,
        lightB: Int,
        params: DoubleArray,
        // When true (feSpecularLighting as the terminal filter output), emit the
        // premultiplied form (lightColor, intensity) to match cairo: full-strength
        // color channels with the intensity in alpha. Intermediate specular output
        // (straight, alpha = max(R,G,B)) is preserved for consumer kernels.
        premultipliedOutput: Boolean,
        // When true (color-interpolation-filters: linearRGB, the default per the
        // SVG spec), the straight RGB output is gamma-corrected from linear to sRGB
        // to match cairo/rsvg. The premultiplied specular terminal keeps the raw
        // (linear) intensity in alpha and the full light color in RGB, so it is
        // unaffected.
        useLinear: Boolean,
    ) {
        // light colors linearized once (only used when `useLinear` is set). For white
        // light sRgbToLinear(255) == 255, so the straight output becomes the sRGB EOTF
        // of the intensity, matching cairo/rsvg's linearRGB rendering.
        val linearLightR = (if (useLinear) sRgbToLinear[lightR] else lightR).toFloat()
        val linearLightG = (if (useLinear) sRgbToLinear[lightG] else lightG).toFloat()
        val linearLightB = (if (useLinear) sRgbToLinear[lightB] else lightB).toFloat()

        val shiftedLightR: Int = lightR shl 16
        val shiftedLightG: Int = lightG shl 8
        val shiftedLightB: Int = lightB
        val distantLx: Float
        val distantLy: Float
        val distantLz: Float
        if (lightType == LightType.DISTANT) {
            val az = Math.toRadians(params[0])
            val el = Math.toRadians(params[1])
            val cosElevation = cos(el)
            distantLx = (cos(az) * cosElevation).toFloat()
            distantLy = (sin(az) * cosElevation).toFloat()
            distantLz = sin(el).toFloat()
        } else {
            distantLx = 0f
            distantLy = 0f
            distantLz = 0f
        }
        val spotTargetX: Double
        val spotTargetY: Double
        val spotTargetZ: Double
        val spotConeCosine: Double
        val hasSpotTarget: Boolean
        if (lightType != LightType.SPOT) {
            spotTargetX = 0.0
            spotTargetY = 0.0
            spotTargetZ = 0.0
            spotConeCosine = -1.0
            hasSpotTarget = false
        } else {
            val targetX = params[3] - params[0]
            val targetY = params[4] - params[1]
            val targetZ = params[5] - params[2]
            val targetLength = sqrt((targetX * targetX + targetY * targetY + targetZ * targetZ))
            if (targetLength == 0.0) {
                spotTargetX = 0.0
                spotTargetY = 0.0
                spotTargetZ = 0.0
                hasSpotTarget = false
            } else {
                spotTargetX = targetX / targetLength
                spotTargetY = targetY / targetLength
                spotTargetZ = targetZ / targetLength
                hasSpotTarget = true
            }
            spotConeCosine = if (params[6].isNaN()) {
                -1.0
            } else {
                cos(params[6] * Math.PI / 180.0)
            }
        }
        val lightX = if (lightType == LightType.DISTANT) 0f else params[0].toFloat()
        val lightY = if (lightType == LightType.DISTANT) 0f else params[1].toFloat()
        val lightZ = if (lightType == LightType.DISTANT) 0f else params[2].toFloat()
        val dzdxScale = canvasScaleX * 0.25f
        val dzdyScale = canvasScaleY * 0.25f

        // Sliding 3-column Sobel tap window, reused across all rows (no
        // per-row or per-pixel allocation; rotation swaps references only).
        // Column invariant at pixel x: colL = max(x-1,0), colM = x,
        // colR = min(x+1,width-1); each holds (top, mid, bot) scaled heights.
        var colL = FloatArray(3)
        var colM = FloatArray(3)
        var colR = FloatArray(3)

        for (y in clipTop until clipBottom) {
            val userY = userTop + y * invCanvasScaleY
            val uy = ((userY - originY) / unitSizeY).toFloat()
            val rowOffset = y * width
            // y-only edge rows: hoisted out of the x loop (same Ints, same addressing).
            val topY = maxOf(0, y - 1)
            val bottomY = minOf(height - 1, y + 1)
            // Seed the tap window. Guarded by the same condition as the x loop
            // below, so no read can go out of bounds on empty clip ranges.
            if (clipLeft < clipRight) {
                readHeightColumn(colL, pix, width, surfaceScaleNormalized, maxOf(0, clipLeft - 1), topY, y, bottomY)
                readHeightColumn(colM, pix, width, surfaceScaleNormalized, clipLeft, topY, y, bottomY)
                readHeightColumn(colR, pix, width, surfaceScaleNormalized, minOf(width - 1, clipLeft + 1), topY, y, bottomY)
            }
            for (x in clipLeft until clipRight) {
                // userX/ux are only read by the point/spot branch below;
                // computing them here would waste a Double division per
                // distant pixel.
                var lx = 0f
                var ly = 0f
                var lz = 0f
                var factor: Float
                when (lightType) {
                    LightType.DISTANT -> {
                        lx = distantLx
                        ly = distantLy
                        lz = distantLz
                        factor = 1f
                    }

                    else -> {
                        val userX = userLeft + x * invCanvasScaleX
                        val ux = ((userX - originX) / unitSizeX).toFloat()
                        // colM[1] is heightAt(x, y) by window construction
                        // (same address, same value); the center tap is free
                        // for point/spot, and distant never touches it.
                        val surfaceZ = colM[1]
                        val vx = lightX - ux
                        val vy = lightY - uy
                        val vz = lightZ - surfaceZ
                        val len = sqrt(vx * vx + vy * vy + vz * vz)
                        if (len == 0f) {
                            factor = 0f
                        } else {
                            lx = vx / len; ly = vy / len; lz = vz / len
                            if (lightType == LightType.POINT || !hasSpotTarget) {
                                factor = 1f
                            } else {
                                var dot = (spotTargetX * -lx + spotTargetY * -ly + spotTargetZ * -lz)
                                dot = dot.coerceIn(-1.0, 1.0)
                                var f = dot.toFloat()
                                if (f.toDouble() < spotConeCosine) f = 0f
                                factor = f.coerceAtLeast(0f)
                            }
                        }
                    }
                }

                // Sobel taps from the sliding window (same values, same formula
                // text as the direct heightAt reads below; only the source
                // of each named tap changed).
                val leftTop = colL[0]
                val left = colL[1]
                val leftBottom = colL[2]
                val rightTop = colR[0]
                val right = colR[1]
                val rightBottom = colR[2]
                val top = colM[0]
                val bottom = colM[2]
                val dzdx = (rightTop + 2 * right + rightBottom -
                        (leftTop + 2 * left + leftBottom)) * dzdxScale
                val dzdy = (leftBottom + 2 * bottom + rightBottom -
                        (leftTop + 2 * top + rightTop)) * dzdyScale

                var nx = -dzdx
                var ny = -dzdy
                var nz = 1f
                val nLen = sqrt(nx * nx + ny * ny + nz * nz)
                nx /= nLen; ny /= nLen; nz /= nLen

                val intensity: Float = if (!specular) {
                    clamp((nx * lx + ny * ly + nz * lz).coerceAtLeast(0f) * k * factor, 0f, 1f)
                } else {
                    var hx = lx
                    var hy = ly
                    var hz = lz + 1f
                    val hLen = sqrt(hx * hx + hy * hy + hz * hz)
                    if (hLen != 0f) {
                        hx /= hLen; hy /= hLen; hz /= hLen
                    }
                    val ndoth = (nx * hx + ny * hy + nz * hz).coerceAtLeast(0f)
                    clamp(
                        (k * ndoth.pow(exponent) * factor),
                        0f,
                        1f
                    )
                }

                val outR: Int
                val outG: Int
                val outB: Int
                if (useLinear) {
                    outR = linearToSrgb[clamp255(linearLightR * intensity)]
                    outG = linearToSrgb[clamp255(linearLightG * intensity)]
                    outB = linearToSrgb[clamp255(linearLightB * intensity)]
                } else {
                    outR = clamp255(linearLightR * intensity)
                    outG = clamp255(linearLightG * intensity)
                    outB = clamp255(linearLightB * intensity)
                }
                val outA = if (specular) maxOf(outR, outG, outB) else 255

                out[rowOffset + x] = if (specular && premultipliedOutput) {
                    // Premultiplied (cairo) form: full-strength light color in RGB,
                    // the specular intensity in alpha.
                    (clamp255(intensity * 255f) shl 24) or shiftedLightR or shiftedLightG or shiftedLightB
                } else {
                    argb(outA, outR, outG, outB)
                }
                // Slide the window: rotate the buffers (reference swap only,
                // no copy, no allocation) and read the single new right column.
                // Runs only inside the x loop, so minOf keeps every read in bounds.
                val tmpCol = colL
                colL = colM
                colM = colR
                colR = tmpCol
                readHeightColumn(colR, pix, width, surfaceScaleNormalized, minOf(width - 1, x + 2), topY, y, bottomY)
            }
        }
    }

    public fun lighting(
        pix: IntArray,
        out: IntArray,
        width: Int,
        height: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        surfaceScaleNormalized: Float,
        invCanvasScaleX: Double,
        invCanvasScaleY: Double,
        userLeft: Double,
        userTop: Double,
        originX: Double,
        originY: Double,
        unitSizeX: Double,
        unitSizeY: Double,
        canvasScaleX: Float,
        canvasScaleY: Float,
        @LightType lightType: Int,
        specular: Boolean,
        k: Float,
        exponent: Float,
        lightR: Int,
        lightG: Int,
        lightB: Int,
        params: DoubleArray,
        premultipliedOutput: Boolean,
        useLinear: Boolean,
    ) {
        with(ColorLuts.LINEAR_TO_SRGB) {
            with(ColorLuts.SRGB_TO_LINEAR) {
                lightingImpl(
                    pix, out, width, height, clipLeft, clipTop, clipRight, clipBottom,
                    surfaceScaleNormalized, invCanvasScaleX, invCanvasScaleY,
                    userLeft, userTop, originX, originY, unitSizeX, unitSizeY,
                    canvasScaleX, canvasScaleY, lightType, specular, k, exponent,
                    lightR, lightG, lightB, params, premultipliedOutput, useLinear,
                )
            }
        }
    }

    // ---------------------------------------------------- arithmetic composite

    private fun arithmeticChannel(
        in1: Int,
        in2: Int,
        k1: Float,
        k2: Float,
        k3: Float,
        k4: Float,
    ): Int {
        val a = in1 / 255f
        val b = in2 / 255f
        return clamp255((k1 * a * b + k2 * a + k3 * b + k4) * 255f)
    }

    /** Surface height at (x, y) for feDiffuse/feSpecular lighting (alpha channel scaled). */
    private inline fun heightAt(
        pix: IntArray,
        width: Int,
        surfaceScaleNormalized: Float,
        x: Int,
        y: Int,
    ): Float = (pix[y * width + x] ushr 24) * surfaceScaleNormalized

    // Reads one full tap column (top/mid/bot scaled heights) for the sliding
    // Sobel window. Private inline like heightAt: zero call overhead, explicit
    // parameters so nothing is captured and nothing is allocated.
    private inline fun readHeightColumn(
        dst: FloatArray,
        pix: IntArray,
        width: Int,
        surfaceScaleNormalized: Float,
        cx: Int,
        topY: Int,
        y: Int,
        bottomY: Int,
    ) {
        dst[0] = heightAt(pix, width, surfaceScaleNormalized, cx, topY)
        dst[1] = heightAt(pix, width, surfaceScaleNormalized, cx, y)
        dst[2] = heightAt(pix, width, surfaceScaleNormalized, cx, bottomY)
    }

    /**
     * feComposite operator="arithmetic". [useLinear] applies the
     * sRGB<->linear folding around each RGB channel exactly like the original
     * implementation in `:ksvg`.
     */
    context(linearToSrgb: LinearToSrgb, sRgbToLinear: SrgbToLinear)
    private fun arithmeticCompositeImpl(
        inputPixels: IntArray,
        in2Pixels: IntArray,
        outPixels: IntArray,
        width: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        k1: Float,
        k2: Float,
        k3: Float,
        k4: Float,
        useLinear: Boolean,
    ) {
        for (y in clipTop until clipBottom) {
            val rowOffset = y * width
            for (x in clipLeft until clipRight) {
                val i = rowOffset + x
                val p = inputPixels[i]
                val q = in2Pixels[i]
                val outA: Int
                val outR: Int
                val outG: Int
                val outB: Int

                if (useLinear) {
                    outA = arithmeticChannel(p ushr 24, q ushr 24, k1, k2, k3, k4)
                    outR = linearToSrgb[
                        arithmeticChannel(
                            sRgbToLinear[p ushr 16 and 0xFF],
                            sRgbToLinear[q ushr 16 and 0xFF],
                            k1, k2, k3, k4
                        )
                    ]
                    outG = linearToSrgb[
                        arithmeticChannel(
                            sRgbToLinear[p ushr 8 and 0xFF],
                            sRgbToLinear[q ushr 8 and 0xFF],
                            k1, k2, k3, k4
                        )
                    ]
                    outB = linearToSrgb[
                        arithmeticChannel(
                            sRgbToLinear[p and 0xFF],
                            sRgbToLinear[q and 0xFF],
                            k1, k2, k3, k4
                        )
                    ]
                } else {
                    outA = arithmeticChannel(p ushr 24, q ushr 24, k1, k2, k3, k4)
                    outR = arithmeticChannel(p ushr 16 and 0xFF, q ushr 16 and 0xFF, k1, k2, k3, k4)
                    outG = arithmeticChannel(p ushr 8 and 0xFF, q ushr 8 and 0xFF, k1, k2, k3, k4)
                    outB = arithmeticChannel(p and 0xFF, q and 0xFF, k1, k2, k3, k4)
                }

                outPixels[i] = (outA shl 24) or (outR shl 16) or (outG shl 8) or outB
            }
        }
    }

    public fun arithmeticComposite(
        inputPixels: IntArray,
        in2Pixels: IntArray,
        outPixels: IntArray,
        width: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        k1: Float,
        k2: Float,
        k3: Float,
        k4: Float,
        useLinear: Boolean,
    ) {
        with(ColorLuts.LINEAR_TO_SRGB) {
            with(ColorLuts.SRGB_TO_LINEAR) {
                arithmeticCompositeImpl(
                    inputPixels, in2Pixels, outPixels, width,
                    clipLeft, clipTop, clipRight, clipBottom,
                    k1, k2, k3, k4, useLinear,
                )
            }
        }
    }

    // -------------------------------------------------------- displacement map

    /**
     * feDisplacementMap kernel. [xChannel]/[yChannel]: 0=R, 1=G, 2=B, 3=A.
     * Maps SourceGraphic pixels to SourceMap offsets.
     */
    public fun displacementMap(
        src: IntArray,
        map: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
        mapWidth: Int,
        mapHeight: Int,
        scale: Float,
        xChannel: Int,
        yChannel: Int,
    ) {
        val widthDivisor = maxOf(width - 1, 1)
        val heightDivisor = maxOf(height - 1, 1)

        for (y in 0 until height) {
            val rowOffset = y * width
            val mapY = if (mapHeight <= 1) 0 else (y.toFloat() / heightDivisor * (mapHeight - 1)).toInt()
            val mapRowOffset = mapY * mapWidth
            for (x in 0 until width) {
                val mapX = if (mapWidth <= 1) 0 else (x.toFloat() / widthDivisor * (mapWidth - 1)).toInt()
                val mapPixel = map[mapRowOffset + mapX]

                val dx = (scale * (channelValue(mapPixel, xChannel) - 0.5f)).toInt()
                val dy = (scale * (channelValue(mapPixel, yChannel) - 0.5f)).toInt()

                val srcX = clamp(x + dx, 0, width - 1)
                val srcY = clamp(y + dy, 0, height - 1)
                dst[rowOffset + x] = src[srcY * width + srcX]
            }
        }
    }

    /**
     * feTurbulence software fallback. [generators] holds the four per-channel
     * [SvgPathNoise] lattice samplers (channel order R, G, B, A) pre-built from the
     * primitive's seed (see `RenderTreeBuilder` in `:ksvg`). Bit-exact reference
     * for `turbulence_core.h` / `TurbulenceNative.apply`.
     */
    public fun turbulence(
        pixels: IntArray,
        width: Int,
        height: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        baseFrequencyX: Double,
        baseFrequencyY: Double,
        periodX: Int,
        periodY: Int,
        octaves: Int,
        fractalNoise: Boolean,
        invCanvasScaleX: Double,
        invCanvasScaleY: Double,
        userLeft: Double,
        userTop: Double,
        unitSizeX: Double,
        unitSizeY: Double,
        @Suppress("UNUSED_PARAMETER") seed: Int,
        generators: Array<SvgPathNoise>,
    ) {
        val stitch = periodX > 0 || periodY > 0

        for (y in clipTop until clipBottom) {
            val userY = userTop + y.toDouble() * invCanvasScaleY
            val py0 = (userY / unitSizeY) * baseFrequencyY
            val rowOffset = y * width
            for (x in clipLeft until clipRight) {
                val userX = userLeft + x.toDouble() * invCanvasScaleX
                val px0 = (userX / unitSizeX) * baseFrequencyX

                var r = 0.0
                var g = 0.0
                var b = 0.0
                var a = 0.0

                for (channel in 0 until 4) {
                    val generator = generators[channel]
                    var value = 0.0
                    var ratio = 1.0
                    var px = px0
                    var py = py0
                    var octavePeriodX = periodX
                    var octavePeriodY = periodY

                    // Stitch wrap-lattice offset. librsvg uses the RAW pixel index
                    // (tile_x * base_frequency), not a user-space / unitSize-scaled factor:
                    // wrap_x_initial = (tile_x * bf) as usize + PERLIN_N + width.
                    // So curtlx must be tileX * baseFrequencyX (drop invCanvasScale/unitSize).
                    var curtlx = (x - clipLeft).toDouble() * baseFrequencyX
                    var curtly = (y - clipTop).toDouble() * baseFrequencyY

                    for (_ in 0 until octaves) {
                        val wrapX = floor(curtlx).toInt() + 4096 + octavePeriodX
                        val wrapY = floor(curtly).toInt() + 4096 + octavePeriodY

                        val n = generator.noise2(
                            px,
                            py,
                            octavePeriodX,
                            octavePeriodY,
                            wrapX,
                            wrapY
                        )
                        value += if (fractalNoise) n / ratio else abs(n) / ratio
                        px *= 2.0
                        py *= 2.0
                        curtlx *= 2.0
                        curtly *= 2.0
                        ratio *= 2.0
                        if (stitch) {
                            octavePeriodX *= 2
                            octavePeriodY *= 2
                        }
                    }
                    val finalVal = if (fractalNoise) (value + 1.0) * 127.5 else value * 255.0
                    when (channel) {
                        0 -> r = finalVal
                        1 -> g = finalVal
                        2 -> b = finalVal
                        3 -> a = finalVal
                    }
                }
                pixels[rowOffset + x] = argb(
                    clamp255(a),
                    clamp255(r),
                    clamp255(g),
                    clamp255(b)
                )
            }
        }
    }
}
