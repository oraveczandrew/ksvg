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

import android.graphics.Bitmap
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.renderWithLibrary
import hu.oandras.ksvg.utils.alpha
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode
import kotlin.math.abs

/**
 * `font-size-adjust`: the effective size scales so the used font's
 * x-height matches the declared aspect (`size * adjust / aspect`).
 *
 * Self-calibrating: doubling the adjust value must (near-)double the
 * rendered x-height, independent of the actual test font. Glyph pixels
 * need real rasterization, hence NATIVE (per AGENTS.md).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class FontSizeAdjustTest {

    private fun xHeightPx(adjustAttr: String): Int {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
              <text x="10" y="70" font-size="40" font-family="sans-serif" $adjustAttr>x</text>
            </svg>
        """.trimIndent()
        val out = renderWithLibrary(
            svg,
            createBitmap(100, 100, Bitmap.Config.ARGB_8888),
        )
        var minY = Int.MAX_VALUE
        var maxY = Int.MIN_VALUE
        for (y in 0 until 100) {
            for (x in 0 until 100) {
                if (out.getPixel(x, y).alpha > 0) {
                    if (y < minY) minY = y
                    if (y > maxY) maxY = y
                }
            }
        }
        assertTrue("expected rasterized pixels for [$adjustAttr]", maxY >= minY)
        return maxY - minY + 1
    }

    @Test
    fun doublingAdjustDoublesXHeight() {
        val full = xHeightPx("font-size-adjust=\"0.9\"")
        val half = xHeightPx("font-size-adjust=\"0.45\"")
        assertTrue("sanity: visible x-height ($full)", full in 5..80)
        assertTrue(
            "adjust ratio must carry to pixels (full=$full, half=$half)",
            abs(full - 2 * half) <= 3,
        )
    }

    @Test
    fun noneMatchesAbsent() {
        assertEquals(xHeightPx(""), xHeightPx("font-size-adjust=\"none\""))
    }
}
