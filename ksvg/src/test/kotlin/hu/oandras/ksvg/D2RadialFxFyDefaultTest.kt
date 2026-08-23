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
import kotlin.math.abs

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class D2RadialFxFyDefaultTest {

    @Test
    fun unspecifiedFxFyDefaultsToCx() {
        // OBB gradient with an off-center cx (0.25) and no fx/fy.
        // Per spec fx defaults to cx, so the gradient stays concentric:
        // points equidistant from the center must have the same stop color.
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <radialGradient id="g" cx="0.25" cy="0.5" r="0.5">
                  <stop offset="0" stop-color="white"/>
                  <stop offset="1" stop-color="black"/>
                </radialGradient>
              </defs>
              <rect x="0" y="0" width="100" height="100" fill="url(#g)"/>
            </svg>
        """.trimIndent()

        val bitmap = createBitmap(100, 100)
        SVG.getFromString(svg).renderToCanvas(Canvas(bitmap))

        // Center is (25,50); both points are 30px away -> identical gray level.
        val lum = { x: Int, y: Int ->
            val p = bitmap.getPixel(x, y)
            ((p shr 16 and 0xff) + (p shr 8 and 0xff) + (p and 0xff)) / 3f
        }
        val a = lum(25, 20)
        val b = lum(55, 50)

        assertTrue("Expected concentric gradient (fx defaults to cx): a=$a b=$b", abs(a - b) < 12f)
    }
}
