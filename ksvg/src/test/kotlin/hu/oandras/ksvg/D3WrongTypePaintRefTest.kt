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
class D3WrongTypePaintRefTest {

    private fun render(fillAttr: String): android.graphics.Bitmap {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <rect id="notAPaint" x="0" y="0" width="10" height="10" fill="green"/>
                <linearGradient id="grad">
                  <stop offset="0" stop-color="lime"/>
                  <stop offset="1" stop-color="lime"/>
                </linearGradient>
              </defs>
              <rect x="0" y="0" width="100" height="100" fill="$fillAttr"/>
            </svg>
        """.trimIndent()

        val bitmap = createBitmap(100, 100)
        SVG.getFromString(svg).renderToCanvas(Canvas(bitmap))
        return bitmap
    }

    @Test
    fun wrongTypeReferencePaintsNothing() {
        // url(#rect) points at a non-paint-server element -> invalid reference.
        // Per spec the element must not be painted with the inherited color;
        // with no fallback it renders as 'none'.
        val bitmap = render("url(#notAPaint)")
        assertTrue("Expected nothing painted for a wrong-type paint ref", !isGreen(bitmap, 50, 50))
        assertTrue("Expected transparent output (paint = none)", isTransparent(bitmap, 50, 50))
    }

    @Test
    fun fallbackColorIsUsedForWrongTypeReference() {
        // With a fallback color, an invalid reference falls back to it.
        val bitmap = render("url(#notAPaint) lime")
        assertTrue("Expected fallback color to apply", isGreen(bitmap, 50, 50))
    }

    @Test
    fun validGradientReferenceStillWorks() {
        val bitmap = render("url(#grad)")
        assertTrue("Expected gradient paint to work", isGreen(bitmap, 50, 50))
    }
}
