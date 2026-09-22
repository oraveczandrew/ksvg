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

import android.graphics.Canvas
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * CSS substring attribute selectors (`^=`, `$=`, `*=`) and the general
 * sibling combinator (`~`). Raster assertions use NATIVE graphics + pixel
 * reads (per AGENTS.md).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class CssSelectorOpsTest {

    private fun pixels(svgContent: String): IntArray {
        val svg = SVG.getFromString(svg = svgContent) as SVGImpl
        val drawable = KSVGDrawable(svg)
        val bitmap = createBitmap(100, 100)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, 100, 100)
        drawable.draw(canvas)
        // One sample per stacked third.
        return intArrayOf(
            bitmap.getPixel(50, 16),
            bitmap.getPixel(50, 50),
            bitmap.getPixel(50, 83)
        )
    }

    @Test
    fun prefixSelectorMatches() {
        val (first, second) = pixels(
            """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <style>rect[id^="pre"] { fill: blue; }</style>
                  <rect id="pre-1" x="0" y="0" width="100" height="33" fill="red"/>
                  <rect id="other" x="0" y="33" width="100" height="34" fill="red"/>
                </svg>
            """.trimIndent()
        )
        assertEquals(255, first.blue)
        assertEquals(255, second.red)
    }

    @Test
    fun suffixSelectorMatches() {
        val (first, second) = pixels(
            """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <style>rect[id$="suf"] { fill: blue; }</style>
                  <rect id="one-suf" x="0" y="0" width="100" height="33" fill="red"/>
                  <rect id="other" x="0" y="33" width="100" height="34" fill="red"/>
                </svg>
            """.trimIndent()
        )
        assertEquals(255, first.blue)
        assertEquals(255, second.red)
    }

    @Test
    fun substringSelectorMatches() {
        val (first, second) = pixels(
            """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <style>rect[id*="mid"] { fill: blue; }</style>
                  <rect id="a-mid-z" x="0" y="0" width="100" height="33" fill="red"/>
                  <rect id="other" x="0" y="33" width="100" height="34" fill="red"/>
                </svg>
            """.trimIndent()
        )
        assertEquals(255, first.blue)
        assertEquals(255, second.red)
    }

    @Test
    fun existsSelectorMatchesOnlyElementsWithId() {
        val (first, second) = pixels(
            """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <style>rect[id] { fill: blue; }</style>
                  <rect id="one" x="0" y="0" width="100" height="33" fill="red"/>
                  <rect x="0" y="33" width="100" height="34" fill="red"/>
                </svg>
            """.trimIndent()
        )
        assertEquals(255, first.blue)
        assertEquals(255, second.red)
    }

    @Test
    fun generalSiblingCombinatorMatchesAllFollowing() {
        val (first, second, third) = pixels(
            """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <style>#a ~ rect { fill: blue; }</style>
                  <rect id="a" x="0" y="0" width="100" height="33" fill="red"/>
                  <rect x="0" y="33" width="100" height="34" fill="red"/>
                  <rect x="0" y="67" width="100" height="33" fill="red"/>
                </svg>
            """.trimIndent()
        )
        assertEquals(255, first.red)
        assertEquals(255, second.blue)
        assertEquals(255, third.blue)
    }
}
