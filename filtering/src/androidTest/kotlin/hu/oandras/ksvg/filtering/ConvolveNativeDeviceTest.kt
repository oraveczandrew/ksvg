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

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Device-side parity check: [ConvolveNative] must produce output bit-identical
 * to the Kotlin reference loop semantics (`doConvolveMatrixKotlin`), including
 * half-up rounding and edge-mode handling, across all three edge modes and a
 * non-square kernel with off-center anchor.
 */
class ConvolveNativeDeviceTest {

    private fun referenceLoop(
        src: IntArray,
        dst: IntArray,
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
        fun sample(c: Int, limit: Int): Int = if (c in 0 until limit) c else when (edgeMode) {
            2 -> -1                       // none
            1 -> c % limit.let { if (it < 0) it + limit else it } // wrap
            else -> if (c < 0) 0 else limit - 1 // duplicate
        }

        fun clamp255(v: Float): Int {
            val i = kotlin.math.floor(v + 0.5f).toInt()
            return if (i < 0) 0 else if (i > 255) 255 else i
        }

        for (y in 0 until height) {
            for (x in 0 until width) {
                var r = 0f; var g = 0f; var b = 0f; var a = 0f
                for (ky in 0 until orderY) {
                    for (kx in 0 until orderX) {
                        val sx = sample(x + kx - targetX, width)
                        val sy = sample(y + ky - targetY, height)
                        val p = if (sx < 0 || sy < 0) 0 else src[sy * width + sx]
                        val w = kernel[ky * orderX + kx]
                        r += ((p shr 16) and 0xFF) * w
                        g += ((p shr 8) and 0xFF) * w
                        b += (p and 0xFF) * w
                        a += ((p shr 24) and 0xFF) * w
                    }
                }
                val outR = clamp255(r / divisor + bias * 255f)
                val outG = clamp255(g / divisor + bias * 255f)
                val outB = clamp255(b / divisor + bias * 255f)
                val outA = if (preserveAlpha) (src[y * width + x] ushr 24) and 0xFF
                else clamp255(a / divisor + bias * 255f)
                dst[y * width + x] = (outA shl 24) or (outR shl 16) or (outG shl 8) or outB
            }
        }
    }

    @Test
    fun nativeMatchesReferenceAcrossEdgeModes() {
        assertTrue("libksvgblur must be loadable on device", ConvolveNative.isAvailable)

        val width = 29
        val height = 19
        val src = IntArray(width * height) { i ->
            var v = i * 1103515245 + 12345
            v = v xor (v shr 11)
            v or 0x20304050 // ensure all channels non-zero-ish
        }
        // Non-square 3x2 kernel with off-center anchor (targetX=1, targetY=1).
        val kernel = floatArrayOf(1f, 2f, -1f, 0.5f, 3f, -2f)
        val orderX = 3
        val orderY = 2
        val divisor = 4f
        val bias = 0.1f

        for (edgeMode in 0..2) {
            for (preserveAlpha in booleanArrayOf(false, true)) {
                val expected = IntArray(width * height)
                referenceLoop(
                    src, expected, width, height, kernel, orderX, orderY,
                    /* targetX */ 1, /* targetY */ 1, divisor, bias,
                    preserveAlpha, edgeMode
                )
                val actual = IntArray(width * height)
                ConvolveNative.apply(
                    src, actual, width, height, kernel, orderX, orderY,
                    1, 1, divisor, bias, preserveAlpha, edgeMode
                )
                for (i in actual.indices) {
                    assertEquals(
                        "Mismatch edgeMode=$edgeMode preserveAlpha=$preserveAlpha at $i",
                        expected[i], actual[i]
                    )
                }
            }
        }
    }
}
