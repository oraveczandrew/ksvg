/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg

import hu.oandras.ksvg.render.GRADIENT_DENSE_SUBDIVISIONS
import hu.oandras.ksvg.render.denseCount
import hu.oandras.ksvg.render.densifyStopsLinear
import hu.oandras.ksvg.render.linearToSrgb
import hu.oandras.ksvg.render.srgbToLinear
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * Unit tests for linear-space gradient densification
 * (`color-interpolation="linearRGB"`).
 */
@RunWith(RobolectricTestRunner::class)
class GradientDensifyLinearTest {

    @Test
    fun transferRoundTripsAtExtremes() {
        assertEquals(0f, srgbToLinear(0), 0f)
        assertEquals(1f, srgbToLinear(255), 0f)
        assertEquals(0, linearToSrgb(0f))
        assertEquals(255, linearToSrgb(1f))
    }

    @Test
    fun linearToSrgbIsMonotonic() {
        var prev = -1
        for (i in 0..100) {
            val v = linearToSrgb(i / 100f)
            assertTrue("non-monotonic at $i: $v < $prev", v >= prev)
            prev = v
        }
    }

    @Test
    fun blackToWhiteMidpointIsLinear() {
        val k = GRADIENT_DENSE_SUBDIVISIONS
        val n = denseCount(2)
        val dst = IntArray(n)
        val pos = FloatArray(n)
        densifyStopsLinear(
            intArrayOf(0xFF000000.toInt(), 0xFFFFFFFF.toInt()),
            floatArrayOf(0f, 1f),
            2, dst, pos,
        )
        assertEquals(n, 1 + k)
        // Endpoints preserved exactly.
        assertEquals(0xFF000000.toInt(), dst[0])
        assertEquals(0xFFFFFFFF.toInt(), dst[n - 1])
        assertEquals(0f, pos[0], 0f)
        assertEquals(1f, pos[n - 1], 0f)
        // Positions evenly spaced.
        for (i in 1 until n) {
            assertEquals(i.toFloat() / k, pos[i], 1e-6f)
        }
        // Midpoint (t=0.5): sRGB(0.5 linear) = 188, not the gamma-lerp 128.
        val mid = dst[k / 2]
        assertEquals(0xFF, mid.alpha)
        assertEquals(188, mid.red)
        assertEquals(188, mid.green)
        assertEquals(188, mid.blue)
    }

    @Test
    fun alphaLerpsStraight() {
        val k = GRADIENT_DENSE_SUBDIVISIONS
        val n = denseCount(2)
        val dst = IntArray(n)
        val pos = FloatArray(n)
        densifyStopsLinear(
            intArrayOf(0x00000000, 0xFFFFFFFF.toInt()),
            floatArrayOf(0f, 1f),
            2, dst, pos,
        )
        // Alpha is not gamma-encoded: straight half of 0..255 rounds to 128.
        assertEquals(128, dst[k / 2].alpha)
        assertEquals(255, dst[n - 1].alpha)
    }
}
