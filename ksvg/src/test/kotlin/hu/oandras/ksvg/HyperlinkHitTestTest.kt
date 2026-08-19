/*
 *    Copyright 2013-2020 Paul LeBeau, Cave Rock Software Ltd.
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
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class HyperlinkHitTestTest {

    private fun renderSvg(svgContent: String): SVGImpl {
        val svg = SVG.getFromString(svg = svgContent) as SVGImpl
        val bitmap = createBitmap(200, 200)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)
        return svg
    }

    @Test
    fun hitTest_noAElements_returnsNull() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <rect x="10" y="10" width="100" height="50" fill="red"/>
                </svg>
            """.trimIndent()
        )
        assertNull(svg.hitTest(50f, 25f))
        assertEquals(0, svg.getHitRegions().size)
    }

    @Test
    fun hitTest_singleAElement_returnsHref() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <a href="https://example.com">
                    <rect x="10" y="10" width="100" height="50" fill="red"/>
                  </a>
                </svg>
            """.trimIndent()
        )
        val regions = svg.getHitRegions()
        assertEquals(1, regions.size)
        assertEquals("https://example.com", regions[0].href)

        assertEquals("https://example.com", svg.hitTest(50f, 25f))
    }

    @Test
    fun hitTest_outsideAElement_returnsNull() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <a href="https://example.com">
                    <rect x="10" y="10" width="100" height="50" fill="red"/>
                  </a>
                </svg>
            """.trimIndent()
        )
        assertNull(svg.hitTest(150f, 100f))
    }

    @Test
    fun hitTest_multipleAElements_returnsTopmost() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <a href="https://first.com">
                    <rect x="10" y="10" width="100" height="50" fill="red"/>
                  </a>
                  <a href="https://second.com">
                    <rect x="10" y="10" width="100" height="50" fill="blue"/>
                  </a>
                </svg>
            """.trimIndent()
        )
        val regions = svg.getHitRegions()
        assertEquals(2, regions.size)

        assertEquals("https://second.com", svg.hitTest(50f, 25f))
    }

    @Test
    fun hitTest_aWithoutHref_notIncluded() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <a>
                    <rect x="10" y="10" width="100" height="50" fill="red"/>
                  </a>
                </svg>
            """.trimIndent()
        )
        assertEquals(0, svg.getHitRegions().size)
        assertNull(svg.hitTest(50f, 25f))
    }

    @Test
    fun hitTest_nestedAElement_returnsHref() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <g>
                    <a href="https://nested.com">
                      <rect x="10" y="10" width="100" height="50" fill="red"/>
                    </a>
                  </g>
                </svg>
            """.trimIndent()
        )
        val regions = svg.getHitRegions()
        assertEquals(1, regions.size)
        assertEquals("https://nested.com", svg.hitTest(50f, 25f))
    }

    @Test
    fun listener_invokedOnDispatch() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <a href="https://example.com">
                    <rect x="10" y="10" width="100" height="50" fill="red"/>
                  </a>
                </svg>
            """.trimIndent()
        )

        var receivedHref: String? = null
        svg.setOnSvgClickListener { href ->
            receivedHref = href
            true
        }

        val consumed = svg.dispatchClick(50f, 25f)
        assertTrue(consumed)
        assertEquals("https://example.com", receivedHref)
    }

    @Test
    fun listener_notInvokedWhenNoListener() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <a href="https://example.com">
                    <rect x="10" y="10" width="100" height="50" fill="red"/>
                  </a>
                </svg>
            """.trimIndent()
        )
        val consumed = svg.dispatchClick(50f, 25f)
        assertEquals(false, consumed)
    }

    @Test
    fun hitTest_regionBoundsAreCorrect() {
        val svg = renderSvg(
            """
                <svg width="200" height="200">
                  <a href="https://example.com">
                    <rect x="10" y="10" width="100" height="50" fill="red"/>
                  </a>
                </svg>
            """.trimIndent()
        )
        val regions = svg.getHitRegions()
        assertEquals(1, regions.size)
        val bounds = regions[0].bounds
        assertTrue(bounds.width() > 0f)
        assertTrue(bounds.height() > 0f)
    }
}
