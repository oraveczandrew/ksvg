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
public object KotlinKernels {

    private fun clamp255(value: Float): Int =
        value.roundToInt().coerceIn(0, 255)

    private fun clamp255(value: Double): Int =
        value.roundToInt().coerceIn(0, 255)

    private fun argb(alpha: Int, red: Int, green: Int, blue: Int): Int =
        (alpha shl 24) or (red shl 16) or (green shl 8) or blue

    /**
     * Precomputed linear→sRGB (unlinearize) lookup table, matching librsvg's
     * `build.rs` exactly: `UNLINEARIZE[i] = round(unlinearize(i / 255.0) * 255.0)`
     * where `unlinearize(c) = if c <= 0.0031308: 12.92 * c else: 1.055 * c^(1/2.4) - 0.055`.
     *
     * This is the single authoritative source for the 8-bit transfer table; it is
     * passed to the native kernels and to [unLinearizeArgb]. (It mirrors what
     * used to live in `ColorUtils.UN_LINEARIZE` in `:ksvg`.)
     */
    @JvmField
    public val UN_LINEARIZE: ByteArray = ByteArray(256) { i ->
        val c = i.toDouble() / 255.0
        val x = if (c <= 0.0031308) {
            12.92 * c
        } else {
            1.055 * c.pow(1.0 / 2.4) - 0.055
        }
        (x * 255.0).roundToInt().toByte()
    }

    private fun clamp(v: Float, min: Float, max: Float): Float =
        v.coerceIn(min, max)

    private fun clamp(v: Int, min: Int, max: Int): Int =
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
        for (y in 0 until height) {
            val rowOffset = y * width
            for (x in 0 until width) {
                var r = 0f
                var g = 0f
                var b = 0f
                var a = 0f

                for (ky in 0 until orderY) {
                    for (kx in 0 until orderX) {
                        val srcX = sampleCoordinate(x + kx - targetX, width, edgeMode)
                        val srcY = sampleCoordinate(y + ky - targetY, height, edgeMode)
                        val pixel = if (srcX < 0 || srcY < 0) 0 else srcPixels[srcY * width + srcX]
                        val weight = kernel[ky * orderX + kx]

                        r += ((pixel shr 16) and 0xFF) * weight
                        g += ((pixel shr 8) and 0xFF) * weight
                        b += (pixel and 0xFF) * weight
                        a += ((pixel shr 24) and 0xFF) * weight
                    }
                }

                val outR = clamp255(r / divisor + bias * 255f)
                val outG = clamp255(g / divisor + bias * 255f)
                val outB = clamp255(b / divisor + bias * 255f)
                val outA = if (preserveAlpha) (srcPixels[rowOffset + x] shr 24) and 0xFF
                else clamp255(a / divisor + bias * 255f)
                outPixels[rowOffset + x] = (outA shl 24) or (outR shl 16) or (outG shl 8) or outB
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
        val channelInitialValue = if (erode) 255 else 0
        dst.fill(0)

        for (y in clipTop until clipBottom) {
            val rowOffset = y * width
            val top = maxOf(0, y - radiusY)
            val bottom = minOf(height - 1, y + radiusY)
            val kernelTouchesTopBottom = y - radiusY < 0 || y + radiusY > height - 1
            for (x in clipLeft until clipRight) {
                if (erode && (kernelTouchesTopBottom || x - radiusX < 0 || x + radiusX > width - 1)) {
                    continue
                }
                var a = channelInitialValue
                var r = channelInitialValue
                var g = channelInitialValue
                var b = channelInitialValue
                val left = maxOf(0, x - radiusX)
                val right = minOf(width - 1, x + radiusX)
                for (ky in top..bottom) {
                    val kRowOffset = ky * width
                    for (kx in left..right) {
                        val color = src[kRowOffset + kx]
                        if (erode) {
                            a = minOf(a, (color ushr 24) and 0xFF)
                            r = minOf(r, (color ushr 16) and 0xFF)
                            g = minOf(g, (color ushr 8) and 0xFF)
                            b = minOf(b, color and 0xFF)
                        } else {
                            a = maxOf(a, (color ushr 24) and 0xFF)
                            r = maxOf(r, (color ushr 16) and 0xFF)
                            g = maxOf(g, (color ushr 8) and 0xFF)
                            b = maxOf(b, color and 0xFF)
                        }
                    }
                }
                dst[rowOffset + x] = (a shl 24) or (r shl 16) or (g shl 8) or b
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
        tableA: ByteArray,
        tableR: ByteArray,
        tableG: ByteArray,
        tableB: ByteArray,
    ) {
        dst.fill(0)
        for (y in clipTop until clipBottom) {
            val rowOffset = y * width
            for (x in clipLeft until clipRight) {
                val c = src[rowOffset + x]
                dst[rowOffset + x] =
                    ((tableA[(c shr 24) and 0xFF].toInt() and 0xFF) shl 24) or
                            ((tableR[(c shr 16) and 0xFF].toInt() and 0xFF) shl 16) or
                            ((tableG[(c shr 8) and 0xFF].toInt() and 0xFF) shl 8) or
                            (tableB[c and 0xFF].toInt() and 0xFF)
            }
        }
    }

    // --------------------------------------------------------------- unlinearize

    /**
     * Converts a single straight (non-premultiplied) linear-RGB pixel to straight
     * sRGB using [table] (normally [UN_LINEARIZE]): each colour channel is looked
     * up and alpha is preserved unchanged. Element-wise reference for both
     * [unlinearize] and `unlinearize.cpp`'s scalar loop.
     */
    @JvmStatic
    public fun unLinearizeArgb(pixel: Int, table: ByteArray): Int {
        val a = pixel and -0x1000000
        val rIdx = (pixel ushr 16) and 0xff
        val gIdx = (pixel ushr 8) and 0xff
        val bIdx = pixel and 0xff
        return a or
            ((table[rIdx].toInt() and 0xff) shl 16) or
            ((table[gIdx].toInt() and 0xff) shl 8) or
            (table[bIdx].toInt() and 0xff)
    }

    /**
     * Linear→sRGB (unlinearize) filter-output transfer over straight ARGB_8888
     * pixels. Each pixel's straight R/G/B channel is looked up in a single shared
     * 256-entry byte [table] and alpha is passed through unchanged (identical to
     * [unLinearizeArgb]). Element-wise byte map, so [src] and [dst] may be the
     * same array (in-place). Bit-exact reference for `unlinearize.cpp`.
     */
    public fun unlinearize(
        src: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
        table: ByteArray,
    ) {
        val total = width * height
        for (i in 0 until total) {
            dst[i] = unLinearizeArgb(src[i], table)
        }
    }

    // ---------------------------------------------------------------- lighting

    /**
     * feDiffuseLighting / feSpecularLighting. [params] packing matches
     * [LightingNative.apply]: distant -> [azimuthDeg, elevationDeg];
     * point -> [x, y, z]; spot -> [x, y, z, pointsAtX/Y/Z, coneAngleDeg]
     * (NaN = no cone). Bit-exact reference for `lighting.cpp`.
     */
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
        lightType: Int,
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
        premultipliedOutput: Boolean = false,
        // When true (color-interpolation-filters: linearRGB, the default per the
        // SVG spec), the straight RGB output is gamma-corrected from linear to sRGB
        // to match cairo/rsvg. The premultiplied specular terminal keeps the raw
        // (linear) intensity in alpha and the full light color in RGB, so it is
        // unaffected.
        useLinear: Boolean = false,
    ) {
        // light colors linearized once (only used when `useLinear` is set). For white
        // light sRgbToLinear(255) == 255, so the straight output becomes the sRGB EOTF
        // of the intensity, matching cairo/rsvg's linearRGB rendering.
        val linearLightR = if (useLinear) sRgbToLinear(lightR).toFloat() else lightR.toFloat()
        val linearLightG = if (useLinear) sRgbToLinear(lightG).toFloat() else lightG.toFloat()
        val linearLightB = if (useLinear) sRgbToLinear(lightB).toFloat() else lightB.toFloat()

        for (y in clipTop until clipBottom) {
            val userY = userTop + y * invCanvasScaleY
            val uy = ((userY - originY) / unitSizeY).toFloat()
            val rowOffset = y * width
            for (x in clipLeft until clipRight) {
                val userX = userLeft + x * invCanvasScaleX
                val ux = ((userX - originX) / unitSizeX).toFloat()

                val surfaceZ = heightAt(pix, width, height, surfaceScaleNormalized, x, y)

                var lx = 0f;
                var ly = 0f;
                var lz = 0f;
                var factor: Float
                when (lightType) {
                    0 -> {
                        val az = Math.toRadians(params[0])
                        val el = Math.toRadians(params[1])
                        lx = (cos(az) * cos(el)).toFloat()
                        ly = (sin(az) * cos(el)).toFloat()
                        lz = sin(el).toFloat()
                        factor = 1f
                    }

                    1 -> {
                        val vx = params[0].toFloat() - ux
                        val vy = params[1].toFloat() - uy
                        val vz = params[2].toFloat() - surfaceZ
                        val len = sqrt(vx * vx + vy * vy + vz * vz)
                        if (len == 0f) {
                            factor = 0f
                        } else {
                            lx = vx / len; ly = vy / len; lz = vz / len; factor = 1f
                        }
                    }

                    else -> {
                        val vx = params[0].toFloat() - ux
                        val vy = params[1].toFloat() - uy
                        val vz = params[2].toFloat() - surfaceZ
                        val len = sqrt(vx * vx + vy * vy + vz * vz)
                        if (len == 0f) {
                            factor = 0f
                        } else {
                            lx = vx / len; ly = vy / len; lz = vz / len
                            val tx = params[3] - params[0]
                            val ty = params[4] - params[1]
                            val tz = params[5] - params[2]
                            val tLen = sqrt((tx * tx + ty * ty + tz * tz).toFloat()).toDouble()
                            if (tLen == 0.0) {
                                factor = 1f
                            } else {
                                val sx = tx / tLen;
                                val sy = ty / tLen;
                                val sz = tz / tLen
                                var dot = (sx * -lx + sy * -ly + sz * -lz)
                                if (dot < -1.0) dot = -1.0 else if (dot > 1.0) dot = 1.0
                                var f = dot.toFloat()
                                if (!params[6].isNaN() && f.toDouble() < cos(params[6] * Math.PI / 180.0)) f =
                                    0f
                                factor = f.coerceAtLeast(0f)
                            }
                        }
                    }
                }

                val dzdx = (heightAt(pix, width, height, surfaceScaleNormalized, x + 1, y - 1) + 2 * heightAt(pix, width, height, surfaceScaleNormalized, x + 1, y) + heightAt(pix, width, height, surfaceScaleNormalized, x + 1, y + 1) -
                        (heightAt(pix, width, height, surfaceScaleNormalized, x - 1, y - 1) + 2 * heightAt(pix, width, height, surfaceScaleNormalized, x - 1, y) + heightAt(pix, width, height, surfaceScaleNormalized, x - 1, y + 1))) / (4f / canvasScaleX)
                val dzdy = (heightAt(pix, width, height, surfaceScaleNormalized, x - 1, y + 1) + 2 * heightAt(pix, width, height, surfaceScaleNormalized, x, y + 1) + heightAt(pix, width, height, surfaceScaleNormalized, x + 1, y + 1) -
                        (heightAt(pix, width, height, surfaceScaleNormalized, x - 1, y - 1) + 2 * heightAt(pix, width, height, surfaceScaleNormalized, x, y - 1) + heightAt(pix, width, height, surfaceScaleNormalized, x + 1, y - 1))) / (4f / canvasScaleY)

                var nx = -dzdx;
                var ny = -dzdy;
                var nz = 1f
                val nLen = sqrt(nx * nx + ny * ny + nz * nz)
                if (nLen != 0f) {
                    nx /= nLen; ny /= nLen; nz /= nLen
                }

                val intensity: Float = if (!specular) {
                    clamp((nx * lx + ny * ly + nz * lz).coerceAtLeast(0f) * k * factor, 0f, 1f)
                } else {
                    var hx = lx;
                    var hy = ly;
                    var hz = lz + 1f
                    val hLen = sqrt(hx * hx + hy * hy + hz * hz)
                    if (hLen != 0f) {
                        hx /= hLen; hy /= hLen; hz /= hLen
                    }
                    val ndoth = (nx * hx + ny * hy + nz * hz).coerceAtLeast(0f)
                    clamp(
                        (k * ndoth.toDouble().pow(exponent.toDouble()).toFloat() * factor),
                        0f,
                        1f
                    )
                }

                val outR = if (useLinear) linearToSRgb(clamp255(linearLightR * intensity))
                else clamp255(linearLightR * intensity)
                val outG = if (useLinear) linearToSRgb(clamp255(linearLightG * intensity))
                else clamp255(linearLightG * intensity)
                val outB = if (useLinear) linearToSRgb(clamp255(linearLightB * intensity))
                else clamp255(linearLightB * intensity)
                val outA = if (specular) maxOf(outR, outG, outB) else 255

                out[rowOffset + x] = if (specular && premultipliedOutput) {
                    // Premultiplied (cairo) form: full-strength light color in RGB,
                    // the specular intensity in alpha.
                    val intensityBits = clamp255(intensity * 255f)
                    (intensityBits shl 24) or (lightR shl 16) or (lightG shl 8) or lightB
                } else {
                    (outA shl 24) or (outR shl 16) or (outG shl 8) or outB
                }
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

    /** sRGB->linear for one 0..255 component (matches ColorUtils.sRgbToLinear). */
    private fun sRgbToLinear(c: Int): Int {
        val a = c / 255f
        return if (a <= 0.04045f) {
            clamp255((a / 12.92f) * 255f)
        } else {
            clamp255((((a + 0.055f) / 1.055f).pow(2.4f)) * 255f)
        }
    }

    /** linear->sRGB for one 0..255 component (matches ColorUtils.linearToSRgb). */
    private fun linearToSRgb(c: Int): Int {
        val a = c / 255f
        return if (a <= 0.0031308f) {
            clamp255(a * 12.92f * 255f)
        } else {
            clamp255((1.055f * (a.pow(1f / 2.4f)) - 0.055f) * 255f)
        }
    }

    /** Surface height at (x, y) for feDiffuse/feSpecular lighting (alpha channel scaled). */
    private fun heightAt(
        pix: IntArray,
        width: Int,
        height: Int,
        surfaceScaleNormalized: Float,
        x: Int,
        y: Int,
    ): Float {
        val cx = x.coerceIn(0, width - 1)
        val cy = y.coerceIn(0, height - 1)
        return ((pix[cy * width + cx] shr 24) and 0xff) * surfaceScaleNormalized
    }

    /**
     * feComposite operator="arithmetic". [useLinear] applies the
     * sRGB<->linear folding around each RGB channel exactly like the original
     * implementation in `:ksvg`.
     */
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
        for (y in clipTop until clipBottom) {
            val rowOffset = y * width
            for (x in clipLeft until clipRight) {
                val i = rowOffset + x
                val p = inputPixels[i]
                val q = in2Pixels[i]
                if (useLinear) {
                    outPixels[i] = ((arithmeticChannel(p ushr 24 and 0xFF, q ushr 24 and 0xFF, k1, k2, k3, k4)) shl 24) or
                            ((linearToSRgb(arithmeticChannel(sRgbToLinear(p ushr 16 and 0xFF), sRgbToLinear(q ushr 16 and 0xFF), k1, k2, k3, k4))) shl 16) or
                            ((linearToSRgb(arithmeticChannel(sRgbToLinear(p ushr 8 and 0xFF), sRgbToLinear(q ushr 8 and 0xFF), k1, k2, k3, k4))) shl 8) or
                            linearToSRgb(arithmeticChannel(sRgbToLinear(p and 0xFF), sRgbToLinear(q and 0xFF), k1, k2, k3, k4))
                } else {
                    outPixels[i] = ((arithmeticChannel(p ushr 24 and 0xFF, q ushr 24 and 0xFF, k1, k2, k3, k4)) shl 24) or
                            ((arithmeticChannel(p ushr 16 and 0xFF, q ushr 16 and 0xFF, k1, k2, k3, k4)) shl 16) or
                            ((arithmeticChannel(p ushr 8 and 0xFF, q ushr 8 and 0xFF, k1, k2, k3, k4)) shl 8) or
                            arithmeticChannel(p and 0xFF, q and 0xFF, k1, k2, k3, k4)
                }
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
            for (x in 0 until width) {
                val mapX = if (mapWidth <= 1) 0 else (x.toFloat() / widthDivisor * (mapWidth - 1)).toInt()
                val mapY = if (mapHeight <= 1) 0 else (y.toFloat() / heightDivisor * (mapHeight - 1)).toInt()
                val mapPixel = map[mapY * mapWidth + mapX]

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
     * [SvgPathNoise] lattice samplers (channel order R,G,B,A) pre-built from the
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
        originX: Double,
        originY: Double,
        unitSizeX: Double,
        unitSizeY: Double,
        @Suppress("UNUSED_PARAMETER") seed: Int,
        generators: Array<SvgPathNoise>,
    ) {
        val startX = userLeft + clipLeft.toDouble() * invCanvasScaleX
        val startY = userTop + clipTop.toDouble() * invCanvasScaleY
        val startLatticeX = (startX / unitSizeX) * baseFrequencyX
        val startLatticeY = (startY / unitSizeY) * baseFrequencyY

        for (y in clipTop until clipBottom) {
            val userY = userTop + y.toDouble() * invCanvasScaleY
            val py0 = (userY / unitSizeY) * baseFrequencyY
            for (x in clipLeft until clipRight) {
                val userX = userLeft + x.toDouble() * invCanvasScaleX
                val px0 = (userX / unitSizeX) * baseFrequencyX

                var r = 0.0
                var g = 0.0
                var b = 0.0
                var a = 0.0

                val tileX = (x - clipLeft).toDouble()
                val tileY = (y - clipTop).toDouble()

                for (channel in 0 until 4) {
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
                    var curtlx = tileX * baseFrequencyX
                    var curtly = tileY * baseFrequencyY

                    for (_ in 0 until octaves) {
                        val wrapX = floor(curtlx).toInt() + 4096 + octavePeriodX
                        val wrapY = floor(curtly).toInt() + 4096 + octavePeriodY

                        val n = generators[channel].noise2(
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
                        if (periodX > 0 || periodY > 0) {
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
                pixels[y * width + x] = argb(
                    clamp255(a),
                    clamp255(r),
                    clamp255(g),
                    clamp255(b)
                )
            }
        }
    }
}
