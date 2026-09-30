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
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * `color-interpolation="linearRGB"` gradients interpolate in linearized
 * space, not gamma-encoded sRGB.
 *
 * Discriminating case: opaque black→white. sRGB gamma-lerp gives ~128 at
 * the midpoint; linear-lerp (spec/rsvg) gives sRGB(0.5) ≈ 188. The platform
 * `LinearGradient` always lerps encoded values, so linearRGB densifies in
 * linearized space (see `densifyStopsLinear`).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class GradientLinearRgbTest {

    private fun render(gradientAttrs: String, rectAttrs: String = ""): Bitmap {
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
              <defs>
                <linearGradient id="g" $gradientAttrs>
                  <stop offset="0" stop-color="black"/>
                  <stop offset="1" stop-color="white"/>
                </linearGradient>
              </defs>
              <rect x="0" y="0" width="256" height="256" fill="url(#g)" $rectAttrs/>
            </svg>
        """.trimIndent()
        return renderWithLibrary(
            svg,
            createBitmap(256, 256, Bitmap.Config.ARGB_8888),
        )
    }

    @Test
    fun srgbDefaultMidpointIsGammaLerp() {
        val out = render("")
        val p = out.getPixel(128, 128)
        assertTrue(
            "sRGB midpoint must be gamma-lerp (~128), got red=${p.red} (pixel=${p.toUInt().toString(16)})",
            p.red in 115..141,
        )
        assertTrue("gradient stays opaque (alpha=${p.alpha})", p.alpha == 255)
    }

    @Test
    fun linearRgbOnGradientMidpointIsLinearLerp() {
        val out = render("color-interpolation=\"linearRGB\"")
        val p = out.getPixel(128, 128)
        assertTrue(
            "linearRGB midpoint must be linear-lerp (~188), got red=${p.red} (pixel=${p.toUInt().toString(16)})",
            p.red in 178..198,
        )
        assertTrue("gradient stays opaque (alpha=${p.alpha})", p.alpha == 255)
    }

    @Test
    fun linearRgbInheritedFromSvgRoot() {
        // color-interpolation is inherited: set on the root, the gradient in
        // <defs> picks it up through its own ancestor chain.
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256" color-interpolation="linearRGB">
              <defs>
                <linearGradient id="g">
                  <stop offset="0" stop-color="black"/>
                  <stop offset="1" stop-color="white"/>
                </linearGradient>
              </defs>
              <rect x="0" y="0" width="256" height="256" fill="url(#g)"/>
            </svg>
        """.trimIndent()
        val out = renderWithLibrary(
            svg,
            createBitmap(256, 256, Bitmap.Config.ARGB_8888),
        )
        val p = out.getPixel(128, 128)
        assertTrue(
            "inherited linearRGB midpoint must be ~188, got red=${p.red} (pixel=${p.toUInt().toString(16)})",
            p.red in 178..198,
        )
    }

    @Test
    fun referencingElementDoesNotLeakIntoGradient() {
        // The referencing rect's own color-interpolation must NOT affect
        // the gradient: interpolation follows the gradient element's chain.
        val out = render("", "color-interpolation=\"linearRGB\"")
        val p = out.getPixel(128, 128)
        assertTrue(
            "rect-level linearRGB must not change the gradient (still ~128), got red=${p.red} (pixel=${p.toUInt().toString(16)})",
            p.red in 115..141,
        )
    }
}
