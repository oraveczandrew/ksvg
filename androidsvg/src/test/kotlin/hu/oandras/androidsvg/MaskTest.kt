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
package hu.oandras.androidsvg

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class MaskTest {
    @Test
    fun alphaMaskUsesTheMaskAlphaInsteadOfItsLuminance() {
        val svg = SVG.getFromString(
            """
            <svg width="10" height="10" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <mask id="mask" style="mask-type:alpha">
                  <rect x="2" y="2" width="6" height="6" fill="black"/>
                </mask>
              </defs>
              <rect width="10" height="10" fill="#ff0000" mask="url(#mask)"/>
            </svg>
            """.trimIndent()
        )
        val bitmap = Bitmap.createBitmap(10, 10, Bitmap.Config.ARGB_8888)

        svg.renderToCanvas(Canvas(bitmap))

        assertEquals(Color.TRANSPARENT, bitmap.getPixel(1, 1))
        assertEquals(Color.RED, bitmap.getPixel(5, 5))
    }

    @Test
    fun maskRegion() {
        val svg = SVG.getFromString(
            """
            <svg width="10" height="10" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <mask id="mask" x="0" y="0" width="0.5" height="1">
                  <rect width="10" height="10" fill="white"/>
                </mask>
              </defs>
              <rect width="10" height="10" fill="#ff0000" mask="url(#mask)"/>
            </svg>
            """.trimIndent()
        )
        val bitmap = Bitmap.createBitmap(10, 10, Bitmap.Config.ARGB_8888)

        svg.renderToCanvas(Canvas(bitmap))

        // Left half (within mask region 0-5) should be RED
        assertEquals("Pixel at (2, 5) should be RED", Color.RED, bitmap.getPixel(2, 5))
        // Right half (outside mask region 5-10) should be TRANSPARENT
        assertEquals("Pixel at (7, 5) should be TRANSPARENT", Color.TRANSPARENT, bitmap.getPixel(7, 5))
    }
}
