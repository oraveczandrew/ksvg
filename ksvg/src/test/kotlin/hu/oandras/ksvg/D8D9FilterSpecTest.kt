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

import android.graphics.Canvas
import hu.oandras.ksvg.render.createBitmap
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

    private fun render(filterBody: String, rectAttrs: String = "x=\"20\" y=\"20\" width=\"60\" height=\"60\" fill=\"blue\""): android.graphics.Bitmap {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <filter id="f" x="-50%" y="-50%" width="200%" height="200%">$filterBody</filter>
              </defs>
              <rect $rectAttrs filter="url(#f)"/>
            </svg>
        """.trimIndent()

        val bitmap = createBitmap(100, 100)
        SVG.getFromString(svg).renderToCanvas(Canvas(bitmap))
        return bitmap
    }

    private fun alpha(bitmap: android.graphics.Bitmap, x: Int, y: Int): Int =
        (bitmap.getPixel(x, y) ushr 24) and 0xff

    // --- D8: feSpecularLighting alpha must be max(R,G,B) ---

    @Test
    fun specularAlphaIsMaxOfChannels() {
        val bitmap = render(
            """<feSpecularLighting surfaceScale="4" specularConstant="1" specularExponent="8"
                 lighting-color="white"><feDistantLight azimuth="235" elevation="40"/></feSpecularLighting>"""
        )
        var sawOpaqueHighlight = false
        var sawTranslucentSlope = false
        // Check well inside the lit square to avoid edge anti-aliasing artifacts.
        for (y in 26 until 74) for (x in 26 until 74) {
            val p = bitmap.getPixel(x, y)
            val a = (p ushr 24) and 0xff
            val r = (p shr 16) and 0xff
            val g = (p shr 8) and 0xff
            val b = p and 0xff
            if (r > 0 || g > 0 || b > 0) {
                // alpha == max(R,G,B) for every non-black output pixel
                // (±1 tolerance for premultiplied-alpha round-trip)
                assertTrue(
                    "alpha ($a) must equal max(R,G,B)=${maxOf(r, g, b)} at $x,$y",
                    kotlin.math.abs(a - maxOf(r, g, b)) <= 1
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
