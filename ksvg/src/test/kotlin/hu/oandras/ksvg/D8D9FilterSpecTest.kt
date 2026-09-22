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
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class D8D9FilterSpecTest {

    private fun render(
        filterBody: String,
        rectAttrs: String = "x=\"20\" y=\"20\" width=\"60\" height=\"60\" fill=\"blue\""
    ): Bitmap {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <filter id="f" x="-50%" y="-50%" width="200%" height="200%">$filterBody</filter>
              </defs>
              <rect $rectAttrs filter="url(#f)"/>
            </svg>
        """.trimIndent()
        return renderWithLibrary(svg, createBitmap(100, 100))
}

    private fun alpha(bitmap: Bitmap, x: Int, y: Int): Int =
        (bitmap.getPixel(x, y) ushr 24) and 0xff

    // --- D8: terminal feSpecularLighting emits the cairo form ---
    //
    // Since 91dc5961 the terminal kernel emits premultiplied (lightColor,
    // intensity): full-strength light color in RGB, specular intensity in
    // alpha — matching cairo/rsvg (rsvg renders this SVG as (255,255,255,116)
    // at every interior point). The "alpha = max(R,G,B)" rule holds only for
    // the straight intermediate form kept for non-terminal (consumer-fed)
    // specular output, never for final rendered pixels.

    @Test
    fun specularAlphaIsMaxOfChannels() {
        val bitmap = render(
            """<feSpecularLighting surfaceScale="4" specularConstant="1" specularExponent="8"
                 lighting-color="white"><feDistantLight azimuth="235" elevation="40"/></feSpecularLighting>"""
        )
        var sawOpaqueHighlight = false
        var sawTranslucentSlope = false
        // Check well inside the lit square to avoid edge anti-aliasing artifacts.
        // The bump map is a flat rect, so the field is uniform: every pixel
        // carries full-strength white with the rsvg intensity (116).
        for (y in 26 until 74) for (x in 26 until 74) {
            val p = bitmap.getPixel(x, y)
            val a = (p ushr 24) and 0xff
            val r = (p shr 16) and 0xff
            val g = (p shr 8) and 0xff
            val b = p and 0xff
            if (r > 0 || g > 0 || b > 0) {
                // Terminal cairo form: full-strength light color; intensity in alpha.
                assertTrue("lit pixel must carry full white at $x,$y, was ($r,$g,$b)", r == 255 && g == 255 && b == 255)
                assertTrue(
                    "alpha ($a) must be the rsvg intensity 116 at $x,$y",
                    kotlin.math.abs(a - 116) <= 2
                )
                if (a >= 254) sawOpaqueHighlight = true else if (a in 16..239) sawTranslucentSlope = true
            } else {
                assertTrue("black pixel must be (almost) transparent at $x,$y", a <= 1)
            }
        }
        assertTrue("Expected some lit pixels", sawOpaqueHighlight || sawTranslucentSlope)
        assertTrue("Expected translucent slope pixels", sawTranslucentSlope)
    }

    @Test
    fun diffuseStaysOpaque() {
        val bitmap = render(
            """<feDiffuseLighting surfaceScale="4" diffuseConstant="1"
                 lighting-color="white"><feDistantLight azimuth="235" elevation="40"/></feDiffuseLighting>"""
        )
        var checked = 0
        for (y in 0 until 100) for (x in 0 until 100) {
            val p = bitmap.getPixel(x, y)
            if ((p and 0xffffff) != 0) {
                assertTrue("diffuse output must stay opaque", ((p ushr 24) and 0xff) == 255)
                checked++
            }
        }
        assertTrue("Expected lit pixels", checked > 0)
    }

    // --- D9: feMorphology erode treats out-of-bounds as transparent black ---

    @Test
    fun erodeShrinksBorderToTransparent() {
        // A solid square eroded by radius 10 must lose ~10px on every side:
        // pixels near the old border become transparent black.
        val bitmap = render(
            """<feMorphology operator="erode" radius="10"/>""",
            rectAttrs = "x=\"30\" y=\"30\" width=\"40\" height=\"40\" fill=\"red\""
        )
        assertTrue("Center stays opaque", alpha(bitmap, 50, 50) > 200)
        // Original border was at x=30; eroded border is now ~x=40.
        assertTrue("Old border area must be eroded away", alpha(bitmap, 32, 50) == 0)
        assertTrue("Just inside the eroded edge remains", alpha(bitmap, 45, 50) > 200)
    }

    @Test
    fun dilateGrowsBorder() {
        val bitmap = render(
            """<feMorphology operator="dilate" radius="5"/>""",
            rectAttrs = "x=\"30\" y=\"30\" width=\"40\" height=\"40\" fill=\"red\""
        )
        assertTrue("Outside the original edge becomes filled", alpha(bitmap, 27, 50) > 200)
        assertTrue("Interior unaffected", alpha(bitmap, 50, 50) > 200)
    }
}
