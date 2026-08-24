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
 * Device-side parity check: [MorphologyNative] must produce output bit-identical
 * to the Kotlin reference loop semantics (`doMorphologyKotlin`) — per-channel
 * min/max on all four channels, transparent-black padding, clip-region output —
 * for both operators across radii that exercise vectorized interiors, scalar
 * borders and erosion border short-circuits.
 */
class MorphologyNativeDeviceTest {

    private fun referenceLoop(
        src: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
        radiusX: Int,
        radiusY: Int,
        erode: Boolean,
        init: Int,
        clipL: Int,
        clipT: Int,
        clipR: Int,
        clipB: Int,
    ) {
        dst.fill(0)
        for (y in clipT until clipB) {
            val rowOffset = y * width
            val top = maxOf(0, y - radiusY)
            val bottom = minOf(height - 1, y + radiusY)
            val touchesTB = y - radiusY < 0 || y + radiusY > height - 1
            for (x in clipL until clipR) {
                if (erode && (touchesTB || x - radiusX < 0 || x + radiusX > width - 1)) continue
                var a = init; var r = init; var g = init; var b = init
                val left = maxOf(0, x - radiusX)
                val right = minOf(width - 1, x + radiusX)
                for (ky in top..bottom) {
                    for (kx in left..right) {
                        val c = src[ky * width + kx]
                        if (erode) {
                            a = minOf(a, (c ushr 24) and 0xFF); r = minOf(r, (c ushr 16) and 0xFF)
                            g = minOf(g, (c ushr 8) and 0xFF); b = minOf(b, c and 0xFF)
                        } else {
                            a = maxOf(a, (c ushr 24) and 0xFF); r = maxOf(r, (c ushr 16) and 0xFF)
                            g = maxOf(g, (c ushr 8) and 0xFF); b = maxOf(b, c and 0xFF)
                        }
                    }
                }
                dst[rowOffset + x] = (a shl 24) or (r shl 16) or (g shl 8) or b
            }
        }
    }

    @Test
    fun nativeMatchesReferenceAcrossOperatorsAndRadii() {
        assertTrue("libksvgblur must be loadable on device", MorphologyNative.isAvailable)

        val width = 33
        val height = 21
        val src = IntArray(width * height) { i ->
            var v = i * 40503 + 97
            v = v xor (v shr 7)
            if (i % 11 == 0) v and 0x00FFFFFF else v // some fully transparent pixels
        }

        for (erode in booleanArrayOf(false, true)) {
            for (radius in intArrayOf(1, 2, 5)) {
                val clipL = 3; val clipT = 2; val clipR = width - 4; val clipB = height - 3
                val expected = IntArray(width * height)
                referenceLoop(
                    src, expected, width, height, radius, radius + 1, erode,
                    if (erode) 255 else 0, clipL, clipT, clipR, clipB
                )
                val actual = IntArray(width * height)
                MorphologyNative.apply(
                    src, actual, width, height, radius, radius + 1, erode,
                    clipL, clipT, clipR, clipB
                )
                for (i in actual.indices) {
                    assertEquals(
                        "Mismatch erode=$erode radius=$radius at $i",
                        expected[i], actual[i]
                    )
                }
            }
        }
    }
}
