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

import kotlin.math.pow

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
            Math.round(value).coerceIn(0, 255)

    private fun sampleCoordinate(coordinate: Int, limit: Int, edgeMode: Int): Int =
            if (coordinate in 0 until limit) coordinate else when (edgeMode) {
                2 -> -1
                1 -> coordinate % limit.let { if (it < 0) it + limit else it }
                else -> if (coordinate < 0) 0 else limit - 1
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
            height: Int,
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
            height: Int,
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
}
