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
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * `feGaussianBlur edgeMode`: `duplicate` extends the input by repeating edge
 * pixels, `none` (the default) extends with transparent black. A rect flush
 * against the filter-region edge stays opaque under `duplicate` but fades
 * under `none`.
 *
 * Renders with the software backend (`softwareFiltering = true`) for
 * deterministic output (see AGENTS.md).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class FeGaussianBlurEdgeModeTest {

    private fun render(edgeModeAttr: String): Bitmap {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
              <defs>
                <filter id="f" x="0" y="0" width="100" height="100" filterUnits="userSpaceOnUse">
                  <feGaussianBlur in="SourceGraphic" stdDeviation="10" $edgeModeAttr/>
                </filter>
              </defs>
              <rect x="0" y="0" width="50" height="100" fill="red" filter="url(#f)"/>
            </svg>
        """.trimIndent()
        return renderWithLibrary(
            svg,
            createBitmap(100, 100, Bitmap.Config.ARGB_8888),
            softwareFiltering = true,
        )
    }

    @Test
    fun duplicateKeepsEdgeOpaqueNoneFades() {
        val duplicate = render("""edgeMode="duplicate"""")
        val none = render("""edgeMode="none"""")
        val default = render("")
        val dupAlpha = duplicate.getPixel(0, 50).alpha
        val noneAlpha = none.getPixel(0, 50).alpha
        val defaultAlpha = default.getPixel(0, 50).alpha
        println("edgeMode alphas: duplicate=$dupAlpha none=$noneAlpha default=$defaultAlpha")
        assertTrue("duplicate edge should stay opaque, was $dupAlpha", dupAlpha > 200)
        assertTrue("none edge should fade, was $noneAlpha", noneAlpha < dupAlpha)
        assertTrue("default should behave as none ($defaultAlpha vs $noneAlpha)", defaultAlpha == noneAlpha)
    }

    @Test
    fun wrapDiffersFromNone() {
        val wrap = render("""edgeMode="wrap"""")
        val none = render("""edgeMode="none"""")
        var differing = 0
        for (y in 0 until 100 step 5) {
            for (x in 0 until 100 step 5) {
                if (wrap.getPixel(x, y) != none.getPixel(x, y)) differing++
            }
        }
        println("wrap vs none differing samples: $differing")
        assertTrue("wrap should differ from none somewhere", differing > 0)
    }
}
