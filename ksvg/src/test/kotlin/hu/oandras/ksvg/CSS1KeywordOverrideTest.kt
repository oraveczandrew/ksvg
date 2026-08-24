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
class CSS1KeywordOverrideTest {

    private fun isRed(bitmap: android.graphics.Bitmap, x: Int, y: Int): Boolean {
        val p = bitmap.getPixel(x, y)
        return (p shr 16 and 0xff) > 200 && (p shr 8 and 0xff) < 60 && (p and 0xff) < 60
    }

    // Parent group clips to the LEFT half; the rect's presentation attribute wants
    // the RIGHT half. The stylesheet's `clip-path: inherit` must win over the
    // presentation attribute, so only the left half is visible.
    @Test
    fun cssInheritOverridesPresentationAttribute() {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <clipPath id="leftHalf"><rect x="0" y="0" width="50" height="100"/></clipPath>
                <clipPath id="rightHalf"><rect x="50" y="0" width="50" height="100"/></clipPath>
              </defs>
              <style>
                .target { clip-path: inherit; }
              </style>
              <g clip-path="url(#leftHalf)">
                <rect class="target" x="0" y="25" width="100" height="50"
                      fill="red" clip-path="url(#rightHalf)"/>
              </g>
            </svg>
        """.trimIndent()

        val bitmap = createBitmap(100, 100)
        SVG.getFromString(svg).renderToCanvas(Canvas(bitmap))

        assertTrue("Left half must be visible (inherited clip)", isRed(bitmap, 25, 50))
        assertTrue("Right half must be clipped", !isRed(bitmap, 75, 50))
    }

    // Regression guard: without any keyword involved an author stylesheet rule
    // still beats a presentation attribute.
    @Test
    fun cssRuleStillBeatsPresentationAttributeWithoutKeyword() {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <clipPath id="leftHalf"><rect x="0" y="0" width="50" height="100"/></clipPath>
                <clipPath id="rightHalf"><rect x="50" y="0" width="50" height="100"/></clipPath>
              </defs>
              <style>
                .target { clip-path: url(#leftHalf); }
              </style>
              <rect class="target" x="10" y="10" width="80" height="80"
                    fill="red" clip-path="url(#rightHalf)"/>
            </svg>
        """.trimIndent()

        val bitmap = createBitmap(100, 100)
        SVG.getFromString(svg).renderToCanvas(Canvas(bitmap))

        assertTrue("Rule clip (left half) applies over presentation attr", isRed(bitmap, 25, 50))
        assertTrue(!isRed(bitmap, 75, 50))
    }

    // fill: inherit through inline style must take the parent's fill color even
    // though the element has its own presentation fill attribute.
    @Test
    fun inlineStyleInheritTakesParentFill() {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <g fill="lime">
                <rect x="0" y="0" width="100" height="100" fill="red" style="fill: inherit"/>
              </g>
            </svg>
        """.trimIndent()

        val bitmap = createBitmap(100, 100)
        SVG.getFromString(svg).renderToCanvas(Canvas(bitmap))

        val p = bitmap.getPixel(50, 50)
        val green = (p shr 8 and 0xff) > 200 && (p shr 16 and 0xff) < 60
        assertTrue("Expected parent's lime fill via style='fill: inherit'", green)
    }
}
