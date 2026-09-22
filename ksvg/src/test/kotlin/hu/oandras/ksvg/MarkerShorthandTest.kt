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
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * The `marker="url(#m)"` shorthand must expand to the three longhands.
 * rsvg (even 2.63) does not implement the shorthand, so
 * `marker_shorthand_strokeWidth.svg` is excluded from the rsvg cross-check
 * (`EXCLUDED_FROM_VISUAL_VERIFICATION`); this test pins the expansion
 * instead: shorthand vs explicit renders must be pixel-identical, and
 * markers must actually paint (non-vacuous).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class MarkerShorthandTest {

    private val defs = """
        <defs>
            <marker id="a" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" markerUnits="strokeWidth" orient="auto">
                <path d="M0 0 L10 5 L0 10 z" fill="red"/>
            </marker>
        </defs>
    """.trimIndent()

    private fun doc(markerAttr: String): String {
        return """
            <svg xmlns="http://www.w3.org/2000/svg" width="240" height="120" viewBox="0 0 240 120">
              $defs
              <path d="M20 35 L110 35" stroke="black" stroke-width="3" fill="none" $markerAttr/>
              <path d="M20 85 L110 85" stroke="black" stroke-width="10" fill="none" $markerAttr/>
            </svg>
        """.trimIndent()
    }

    private fun render(svg: String): Bitmap {
        return renderWithLibrary(
            svg,
            createBitmap(256, 256, Bitmap.Config.ARGB_8888),
        )
    }

    @Test
    fun shorthandEqualsExplicitLonghands() {
        val shorthand = render(doc("""marker="url(#a)""""))
        val explicit = render(
            doc("""marker-start="url(#a)" marker-mid="url(#a)" marker-end="url(#a)""""),
        )
        // Markers must paint: red pixels present on both sides.
        val red = { color: Int -> color.red > 128 }
        assertTrue(
            "shorthand rendered no markers",
            countPixels(shorthand, red) > 100,
        )
        assertTrue(
            "explicit longhands rendered no markers",
            countPixels(explicit, red) > 100,
        )
        // Pixel-identical expansion.
        assertEquals(256, shorthand.width)
        assertEquals(256, explicit.width)
        val a = IntArray(256 * 256)
        val b = IntArray(256 * 256)
        shorthand.getPixels(a, 0, 256, 0, 0, 256, 256)
        explicit.getPixels(b, 0, 256, 0, 0, 256, 256)
        var differing = 0
        for (i in a.indices) {
            if (a[i] != b[i]) differing++
        }
        assertEquals("marker shorthand != explicit longhands", 0, differing)
    }
}
