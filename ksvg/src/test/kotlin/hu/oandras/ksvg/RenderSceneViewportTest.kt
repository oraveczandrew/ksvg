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
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * RenderScene viewport update: resizing a KSVGDrawable must render identically
 * to a freshly built tree, WITHOUT rebuilding (nested <svg> viewBox case).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class RenderSceneViewportTest {

    private val nestedSvgDocument = """
        <svg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
          <rect width="100" height="100" fill="#222222"/>
          <rect x="10" y="10" width="80" height="80" fill="#eeeeee"/>
          <!-- Nested viewport: content scales with the outer bounds -->
          <svg x="20" y="20" width="60" height="60" viewBox="0 0 10 10">
            <rect x="2" y="2" width="6" height="6" fill="#ff0000"/>
          </svg>
        </svg>
    """.trimIndent()

    private fun drawAt(svg: SVGImpl, size: Int): android.graphics.Bitmap {
        val drawable = KSVGDrawable(svg)
        val bitmap = createBitmap(size, size)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)
        return bitmap
    }

    @Test
    fun resizedDrawableMatchesFreshBuild() {
        val svg = SVG.getFromString(svg = nestedSvgDocument) as SVGImpl

        // Draw at 200 first, then resize to 100: exercises the update path.
        drawAt(svg, 200)
        val updatedBitmap = drawAt(svg, 100)

        // Reference: fresh drawable built directly at 100.
        val freshSvg = SVG.getFromString(svg = nestedSvgDocument) as SVGImpl
        val freshBitmap = drawAt(freshSvg, 100)

        assertEquals(
            "resized scene must match fresh build",
            freshBitmap.getPixel(50, 50),
            updatedBitmap.getPixel(50, 50)
        )
        // Center of the nested red square (user 5,5 -> outer ~50% of inner svg area)
        assertEquals(
            freshBitmap.getPixel(38, 38),
            updatedBitmap.getPixel(38, 38)
        )
    }

    @Test
    fun percentTextPositionResizedMatchesFreshBuild() {
        val doc = """
            <svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
              <rect width="64" height="64" fill="#004488"/>
              <text x="50%" y="30%" font-size="12" fill="#ffffff">Hi</text>
            </svg>
        """.trimIndent()

        val svg = SVG.getFromString(svg = doc) as SVGImpl
        drawAt(svg, 128)
        val updated = drawAt(svg, 64)

        val fresh = SVG.getFromString(svg = doc) as SVGImpl
        val reference = drawAt(fresh, 64)

        assertEquals(reference.getPixel(32, 20), updated.getPixel(32, 20))
    }

    @Test
    fun plainDocumentResizedMatchesFreshBuild() {
        val doc = """
            <svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
              <circle cx="32" cy="32" r="28" fill="#00aa55"/>
            </svg>
        """.trimIndent()

        val svg = SVG.getFromString(svg = doc) as SVGImpl
        drawAt(svg, 128) // build at one size...
        val updated = drawAt(svg, 64) // ...then shrink through the update path

        val fresh = SVG.getFromString(svg = doc) as SVGImpl
        val reference = drawAt(fresh, 64)

        assertEquals(reference.getPixel(32, 32), updated.getPixel(32, 32))
        assertEquals(reference.getPixel(4, 4), updated.getPixel(4, 4))
    }
}
