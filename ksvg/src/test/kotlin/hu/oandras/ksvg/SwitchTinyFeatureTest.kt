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
import hu.oandras.ksvg.test.countPixels
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * SVG Tiny 1.2 feature URIs in `requiredFeatures`: supported sets match (the
 * `switch` branch renders), unsupported ones stay hidden. In particular Tiny
 * `#Animation` (the `<animation>` media element) must NOT match just because
 * the SVG 1.1 short name `Animation` (SMIL) does.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class SwitchTinyFeatureTest {

    private fun render(featureUri: String): Bitmap {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
              <rect x="0" y="0" width="100" height="100" fill="white"/>
              <switch>
                <rect x="10" y="10" width="40" height="40" fill="red" requiredFeatures="$featureUri"/>
              </switch>
            </svg>
        """.trimIndent()
        return renderWithLibrary(
            svg,
            Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888),
        )
    }

    private fun redCount(bitmap: Bitmap): Int =
        countPixels(bitmap) { it == 0xFFFF0000.toInt() }

    @Test
    fun supportedTinySetRenders() {
        val out = render("http://www.w3.org/Graphics/SVG/feature/1.2/#Shape")
        assertTrue("Tiny #Shape branch should render", redCount(out) > 1000)
    }

    @Test
    fun supportedTimedAnimationRenders() {
        val out = render("http://www.w3.org/Graphics/SVG/feature/1.2/#TimedAnimation")
        assertTrue("Tiny #TimedAnimation branch should render", redCount(out) > 1000)
    }

    @Test
    fun unsupportedTinySetStaysHidden() {
        val out = render("http://www.w3.org/Graphics/SVG/feature/1.2/#Video")
        assertEquals("Tiny #Video branch should stay hidden", 0, redCount(out))
    }

    @Test
    fun tinyAnimationElementDoesNotMatchSmilAnimation() {
        val out = render("http://www.w3.org/Graphics/SVG/feature/1.2/#Animation")
        assertEquals("Tiny #Animation (media element) should stay hidden", 0, redCount(out))
    }

    @Test
    fun tinyCompositeStaysHidden() {
        val out = render("http://www.w3.org/Graphics/SVG/feature/1.2/#SVG-static")
        assertEquals("Tiny #SVG-static composite should stay hidden", 0, redCount(out))
    }
}
