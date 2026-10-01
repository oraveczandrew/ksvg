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
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Middle-ground `pointer-events` hit-testing: only `none` opts out;
 * `visibility` hidden/collapse contributes no region; everything else
 * keeps the bounding-box region.
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class PointerEventsHitTestTest {

    private fun renderSvg(svgContent: String): SVGImpl {
        val svg = SVG.getFromString(svg = svgContent) as SVGImpl
        val bitmap = createBitmap(200, 200)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)
        return svg
    }

    @Test
    fun pointerEventsNone_onAnchor_noRegion() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <a href="https://example.com" pointer-events="none">
                    <rect x="10" y="10" width="100" height="50" fill="red"/>
                  </a>
                </svg>
            """.trimIndent()
        )
        assertEquals(0, svg.getHitRegions().size)
        assertNull(svg.hitTest(50f, 25f))
    }

    @Test
    fun pointerEventsNone_viaStyle_noRegion() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <a href="https://example.com" style="pointer-events:none">
                    <rect x="10" y="10" width="100" height="50" fill="red"/>
                  </a>
                </svg>
            """.trimIndent()
        )
        assertEquals(0, svg.getHitRegions().size)
        assertNull(svg.hitTest(50f, 25f))
    }

    @Test
    fun pointerEventsNone_onAncestor_noRegion() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <g pointer-events="none">
                    <a href="https://example.com">
                      <rect x="10" y="10" width="100" height="50" fill="red"/>
                    </a>
                  </g>
                </svg>
            """.trimIndent()
        )
        assertEquals(0, svg.getHitRegions().size)
        assertNull(svg.hitTest(50f, 25f))
    }

    @Test
    fun pointerEventsVisiblePainted_keepsRegion() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <a href="https://example.com" pointer-events="visiblePainted">
                    <rect x="10" y="10" width="100" height="50" fill="red"/>
                  </a>
                </svg>
            """.trimIndent()
        )
        assertEquals(1, svg.getHitRegions().size)
        assertEquals("https://example.com", svg.hitTest(50f, 25f))
    }

    @Test
    fun visibilityHidden_onAnchor_noRegion() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <a href="https://example.com" visibility="hidden">
                    <rect x="10" y="10" width="100" height="50" fill="red"/>
                  </a>
                </svg>
            """.trimIndent()
        )
        assertEquals(0, svg.getHitRegions().size)
        assertNull(svg.hitTest(50f, 25f))
    }

    @Test
    fun visibilityHidden_onAncestor_noRegion() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <g visibility="hidden">
                    <a href="https://example.com">
                      <rect x="10" y="10" width="100" height="50" fill="red"/>
                    </a>
                  </g>
                </svg>
            """.trimIndent()
        )
        assertEquals(0, svg.getHitRegions().size)
        assertNull(svg.hitTest(50f, 25f))
    }

    @Test
    fun displayNone_onAnchor_noRegion() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <a href="https://example.com" display="none">
                    <rect x="10" y="10" width="100" height="50" fill="red"/>
                  </a>
                </svg>
            """.trimIndent()
        )
        assertEquals(0, svg.getHitRegions().size)
        assertNull(svg.hitTest(50f, 25f))
    }
}
