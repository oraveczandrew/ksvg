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
import hu.oandras.ksvg.test.countPixels
import hu.oandras.ksvg.test.renderWithLibrary
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * F3 (`tmp/VISUAL_FIX_PLAN.md`): CSS `clip` is ignored when `overflow` is
 * not `visible` (used value `auto` — Chrome and rsvg agree: the circle in
 * `clip_overflow.svg` renders whole). The renderer used to apply both the
 * overflow viewport clip AND the `clip` rect, over-clipping the circle to
 * a sliver.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class ClipOverflowTest {

    @Test
    fun clipIgnoredUnderHiddenOverflow() {
        // Same content as test-data/visual/clip_overflow.svg.
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="240" height="120" viewBox="0 0 240 120">
              <defs>
                <clipPath id="c">
                  <circle cx="0" cy="0" r="38"/>
                </clipPath>
              </defs>
              <rect width="240" height="120" fill="#eee"/>
              <svg x="20" y="20" width="80" height="80" viewBox="-40 -40 80 80" overflow="hidden"
                  clip="rect(-25px,25px,25px,-25px)">
                <rect x="-40" y="-40" width="80" height="80" fill="orange"/>
                <circle cx="0" cy="0" r="32" fill="blue" opacity=".6" clip-path="url(#c)"/>
              </svg>
            </svg>
        """.trimIndent()
        val out = renderWithLibrary(
            svg,
            createBitmap(256, 256, Bitmap.Config.ARGB_8888),
        )
        // Blue-ish pixels (b>100, r<150 — the .6-opacity blue over orange
        // blends to ~(102,66,153)): the full r32 circle is ~3k px at this
        // size (rsvg 3402); the over-clipped sliver was ~100.
        val blue = countPixels(out) { color -> color.blue > 100 && color.red < 150 }
        assertTrue(
            "circle must survive (blue-ish pixels: $blue, want > 1500)",
            blue > 1500,
        )
    }
}
