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
 * `SVG_REFERENCE_v2.md` §12 interaction matrix: the compositing pipeline must
 * apply its stages in order (filter → clip → mask → opacity → blend) instead
 * of flattening them into one generic alpha step. Each test pairs two stages
 * with probes that only pass when *both* are honored (dropping either stage
 * flips at least one probe).
 *
 * Filter tests render with the software backend (`softwareFiltering = true`)
 * for deterministic output (see AGENTS.md).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class CompositingInteractionTest {

    private fun render(svg: String, softwareFiltering: Boolean = false): Bitmap {
        return renderWithLibrary(svg, createBitmap(200, 200, Bitmap.Config.ARGB_8888), softwareFiltering)
    }

    private fun isRed(b: Bitmap, x: Int, y: Int): Boolean {
        val c = b.getPixel(x, y)
        return c.alpha > 200 && c.red > 200 && c.green < 100 && c.blue < 100
    }

    private fun isBlue(b: Bitmap, x: Int, y: Int): Boolean {
        val c = b.getPixel(x, y)
        return c.alpha > 200 && c.red < 100 && c.green < 100 && c.blue > 200
    }

    private fun isWhite(b: Bitmap, x: Int, y: Int): Boolean {
        val c = b.getPixel(x, y)
        return c.alpha > 200 && c.red > 200 && c.green > 200 && c.blue > 200
    }

    private fun isTransparent(b: Bitmap, x: Int, y: Int): Boolean {
        return b.getPixel(x, y).alpha < 50
    }

    /** Half red over white: opacity honored (opaque red would have green < 100). */
    private fun isPink(b: Bitmap, x: Int, y: Int): Boolean {
        val c = b.getPixel(x, y)
        return c.alpha > 200 && c.red > 200 && c.green in 100..180 && c.blue in 100..180
    }

    // --- filter + clip ---

    @Test
    fun filterThenClip() {
        // Offset moves the full-red source right; the clip keeps the left half:
        // visible band is [60, 100].
        val out = render(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <filter id="f"><feOffset dx="60" dy="0"/></filter>
              </defs>
              <rect width="200" height="200" fill="red" filter="url(#f)" clip-path="inset(0 100px 0 0)"/>
            </svg>
            """.trimIndent(),
            softwareFiltering = true
        )
        assertTrue("unshifted content must be gone", isTransparent(out, 20, 100))
        assertTrue("shifted content inside clip must show", isRed(out, 80, 100))
        assertTrue("shifted content outside clip must be cut", isTransparent(out, 150, 100))
    }

    // --- filter + mask ---

    @Test
    fun filterThenMask() {
        // Same shift, but the left half comes from a luminance mask.
        val out = render(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <filter id="f"><feOffset dx="60" dy="0"/></filter>
                <mask id="m"><rect width="100" height="200" fill="white"/></mask>
              </defs>
              <rect width="200" height="200" fill="red" filter="url(#f)" mask="url(#m)"/>
            </svg>
            """.trimIndent(),
            softwareFiltering = true
        )
        assertTrue("unshifted content must be gone", isTransparent(out, 20, 100))
        assertTrue("shifted content inside mask must show", isRed(out, 80, 100))
        assertTrue("shifted content outside mask must be cut", isTransparent(out, 150, 100))
    }

    // --- filter + opacity ---

    @Test
    fun filterThenOpacity() {
        val out = render(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <filter id="f"><feOffset dx="60" dy="0"/></filter>
              </defs>
              <rect width="200" height="200" fill="white"/>
              <rect width="200" height="200" fill="red" filter="url(#f)" opacity="0.5"/>
            </svg>
            """.trimIndent(),
            softwareFiltering = true
        )
        assertTrue("shifted-away area must be plain background", isWhite(out, 20, 100))
        assertTrue("filtered output must carry the opacity", isPink(out, 140, 100))
    }

    // --- mask + opacity ---

    @Test
    fun maskThenOpacity() {
        val out = render(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <mask id="m"><rect width="100" height="200" fill="white"/></mask>
              </defs>
              <rect width="200" height="200" fill="white"/>
              <rect width="200" height="200" fill="red" mask="url(#m)" opacity="0.5"/>
            </svg>
            """.trimIndent()
        )
        assertTrue("masked output must carry the opacity", isPink(out, 50, 100))
        assertTrue("masked-away area must be plain background", isWhite(out, 150, 100))
    }

    // --- blend + opacity ---

    @Test
    fun blendThenOpacity() {
        // multiply yellow over blue is black; at 0.5 over blue it is (0,0,128).
        val out = render(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="blue"/>
              <rect width="100" height="200" fill="yellow" style="mix-blend-mode: multiply" opacity="0.5"/>
            </svg>
            """.trimIndent()
        )
        val c = out.getPixel(50, 100)
        assertTrue(
            "blended+faded pixel $c must be dark blue (r<100 g<100 b 100..160)",
            c.alpha > 200 && c.red < 100 && c.green < 100 && c.blue in 100..160
        )
        assertTrue("area outside the blended rect must stay blue", isBlue(out, 150, 100))
    }

    // --- nested group opacity ---

    @Test
    fun nestedGroupOpacityMultiplies() {
        // 0.5 × 0.5 = 0.25 red over white: green ≈ 191.
        val out = render(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="white"/>
              <g opacity="0.5">
                <g opacity="0.5">
                  <rect width="200" height="200" fill="red"/>
                </g>
              </g>
            </svg>
            """.trimIndent()
        )
        val c = out.getPixel(100, 100)
        assertTrue(
            "nested opacity pixel $c must be faint red (green/blue 170..215)",
            c.alpha > 200 && c.red > 200 && c.green in 170..215 && c.blue in 170..215
        )
    }

    // --- clip + blend ---

    @Test
    fun clipThenBlend() {
        // Multiply red over blue is black, but only inside the clipped left half.
        val out = render(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <rect width="200" height="200" fill="blue"/>
              <rect width="200" height="200" fill="red" clip-path="inset(0 100px 0 0)" style="mix-blend-mode: multiply"/>
            </svg>
            """.trimIndent()
        )
        val c = out.getPixel(50, 100)
        assertTrue(
            "clipped+blended pixel $c must be dark (r<100 g<100 b<100)",
            c.alpha > 200 && c.red < 100 && c.green < 100 && c.blue < 100
        )
        assertTrue("area outside the clip must stay blue", isBlue(out, 150, 100))
    }

    // --- mask + blend ---

    @Test
    fun maskThenBlend() {
        // Same as above with a luminance mask instead of a clip.
        val out = render(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <mask id="m"><rect width="100" height="200" fill="white"/></mask>
              </defs>
              <rect width="200" height="200" fill="blue"/>
              <rect width="200" height="200" fill="red" mask="url(#m)" style="mix-blend-mode: multiply"/>
            </svg>
            """.trimIndent()
        )
        val c = out.getPixel(50, 100)
        assertTrue(
            "masked+blended pixel $c must be dark (r<100 g<100 b<100)",
            c.alpha > 200 && c.red < 100 && c.green < 100 && c.blue < 100
        )
        assertTrue("area outside the mask must stay blue", isBlue(out, 150, 100))
    }
}
