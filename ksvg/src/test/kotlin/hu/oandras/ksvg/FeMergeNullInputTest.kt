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
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * `feMergeNode` without `in` defaults to the previous primitive's result —
 * `SourceGraphic` only when `feMerge` itself is the first primitive.
 * Reference values from `rsvg-convert` 2.63.2 (`-b none`): non-first merge
 * with `[null]` or `[null, null]` renders the flood blue at the center; a
 * first merge with `[null, null]` renders the source red. Corners stay
 * transparent (outside the default filter region) in all three.
 *
 * Renders with the software backend (`softwareFiltering = true`) for
 * deterministic output (see AGENTS.md); the GPU33 half lives in
 * `GpuChainParityTest.feMergeNullInputs` (device).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class FeMergeNullInputTest {

    private fun render(svg: String): Bitmap {
        return renderWithLibrary(
            svg,
            createBitmap(256, 256, Bitmap.Config.ARGB_8888),
            softwareFiltering = true,
        )
    }

    private fun mergeSvg(primitives: String): String {
        return """
            <svg xmlns="http://www.w3.org/2000/svg" width="256" height="256">
              <defs>
                <filter id="f">
                  $primitives
                </filter>
              </defs>
              <rect x="48" y="48" width="160" height="160" fill="#c83232" filter="url(#f)"/>
            </svg>
        """.trimIndent()
    }

    private fun isBlue(b: Bitmap, x: Int, y: Int): Boolean {
        val c = b.getPixel(x, y)
        return c.alpha > 200 && c.red < 100 && c.green < 100 && c.blue > 150
    }

    private fun isRed(b: Bitmap, x: Int, y: Int): Boolean {
        val c = b.getPixel(x, y)
        return c.alpha > 200 && c.red > 150 && c.green < 100 && c.blue < 100
    }

    private fun isTransparent(b: Bitmap, x: Int, y: Int): Boolean {
        return b.getPixel(x, y).alpha < 50
    }

    @Test
    fun nonFirstMergeTwoNullNodesEndBlue() {
        val b = render(
            mergeSvg(
                """
                <feFlood flood-color="#2020c0" result="f"/>
                <feMerge>
                  <feMergeNode/>
                  <feMergeNode/>
                </feMerge>
                """.trimIndent(),
            ),
        )
        assertTrue("second null node must be the flood (blue), not SourceGraphic", isBlue(b, 128, 128))
        assertTrue("outside the filter region stays transparent", isTransparent(b, 10, 10))
    }

    @Test
    fun nonFirstMergeSingleNullNodeIsPreviousResult() {
        val b = render(
            mergeSvg(
                """
                <feFlood flood-color="#2020c0" result="f"/>
                <feMerge>
                  <feMergeNode/>
                </feMerge>
                """.trimIndent(),
            ),
        )
        assertTrue("first null node of a non-first merge must be the flood (blue)", isBlue(b, 128, 128))
        assertTrue("outside the filter region stays transparent", isTransparent(b, 10, 10))
    }

    @Test
    fun firstMergeNullNodesAreSourceGraphic() {
        val b = render(
            mergeSvg(
                """
                <feMerge>
                  <feMergeNode/>
                  <feMergeNode/>
                </feMerge>
                """.trimIndent(),
            ),
        )
        assertTrue("null nodes of a first merge must be SourceGraphic (red)", isRed(b, 128, 128))
        assertTrue("outside the filter region stays transparent", isTransparent(b, 10, 10))
    }
}
