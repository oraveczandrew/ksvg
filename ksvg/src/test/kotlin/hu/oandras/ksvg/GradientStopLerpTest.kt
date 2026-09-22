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
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * F2 (`tmp/VISUAL_FIX_PLAN.md`): gradient stops interpolate in straight
 * space (spec/rsvg), not premultiplied (platform `LinearGradient` default).
 *
 * The platform lerps premultiplied, which diverges from straight whenever
 * stop alphas differ: mid-gradient tones come out far too bright
 * (`stop_opacity.svg` differed 27.72% from rsvg). Regression test on the
 * discriminating pixel: quarter-way red→yellow the green channel must be
 * dim (rsvg 0x4d), not premult-bright (was 0xd0).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class GradientStopLerpTest {

    private fun render(): Bitmap {
        // Same content as test-data/visual/stop_opacity.svg.
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="240" height="120" viewBox="0 0 240 120">
              <defs>
                <linearGradient id="g">
                  <stop offset="0" stop-color="red" stop-opacity="0.1"/>
                  <stop offset=".5" stop-color="yellow" stop-opacity="1"/>
                  <stop offset="1" stop-color="blue" stop-opacity="0.15"/>
                </linearGradient>
              </defs>
              <rect x="15" y="20" width="210" height="80" fill="url(#g)"/>
            </svg>
        """.trimIndent()
        return renderWithLibrary(
            svg,
            createBitmap(256, 256, Bitmap.Config.ARGB_8888),
        )
    }

    @Test
    fun midGradientToneIsStraight() {
        val out = render()
        // (50,128): quarter-way across the bar (t≈0.16 of the gradient).
        // Straight lerp (rsvg): r=0xff g=0x4d; premult lerp was g=0xd0.
        val p = out.getPixel(50, 128)
        assertTrue(
            "mid-tone green must be dim, not premult-bright " +
                "(pixel=${p.toUInt().toString(16)})",
            p.green in 30..120,
        )
        assertTrue(
            "red channel stays full (pixel=${p.toUInt().toString(16)})",
            p.red > 200,
        )
        assertTrue(
            "gradient is translucent here (alpha=${p.alpha})",
            p.alpha in 20..120,
        )
    }

    @Test
    fun opaqueGradientUnchanged() {
        // All-opaque stops must keep the exact existing path (no
        // densification): solid red→blue gradient renders end colors.
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
              <defs>
                <linearGradient id="g">
                  <stop offset="0" stop-color="red"/>
                  <stop offset="1" stop-color="blue"/>
                </linearGradient>
              </defs>
              <rect x="0" y="0" width="256" height="256" fill="url(#g)"/>
            </svg>
        """.trimIndent()
        val out = renderWithLibrary(
            svg,
            createBitmap(256, 256, Bitmap.Config.ARGB_8888),
        )
        val left = out.getPixel(8, 128)
        val right = out.getPixel(247, 128)
        assertTrue("left stays red (${left.toUInt().toString(16)})", left.red > 200)
        assertTrue("right stays blue (${right.toUInt().toString(16)})", right.red < 60)
    }
}
