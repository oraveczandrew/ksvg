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

import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import hu.oandras.ksvg.mocks.asShadow
import hu.oandras.ksvg.render.PaintConfiguration
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * `shape-rendering`/`text-rendering` switch the paint anti-alias flag per
 * element (op-list assertions on shapes, per AGENTS.md); `color-rendering`
 * parses but has no rendering effect.
 */
@RunWith(RobolectricTestRunner::class)
@Config(
    manifest = Config.NONE,
    sdk = [Build.VERSION_CODES.O],
    shadows = [MockCanvas::class, MockPath::class, MockPaint::class]
)
class ShapeRenderingTest {

    private fun pathPaintAntiAlias(svg: String): Boolean? {
        val parsed: SVG = SVG.getFromString(svg)
        val bitmap: Bitmap = createBitmap(200, 200)
        val canvas = Canvas(bitmap)
        parsed.renderToCanvas(canvas)
        val mock: MockCanvas = canvas.asShadow()
        return mock.lastPathPaint?.isAntiAlias
    }

    private fun rectWith(renderingAttr: String): String {
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"200\" height=\"200\">" +
            "<rect x=\"10\" y=\"10\" width=\"80\" height=\"80\" fill=\"#FF0000\" $renderingAttr/>" +
            "</svg>"
    }

    @Test
    fun defaultKeepsAntiAlias() {
        assertEquals(true, pathPaintAntiAlias(rectWith("")))
    }

    @Test
    fun crispEdgesDisablesAntiAlias() {
        assertEquals(false, pathPaintAntiAlias(rectWith("shape-rendering=\"crispEdges\"")))
    }

    @Test
    fun optimizeSpeedDisablesAntiAlias() {
        assertEquals(false, pathPaintAntiAlias(rectWith("shape-rendering=\"optimizeSpeed\"")))
    }

    @Test
    fun geometricPrecisionKeepsAntiAlias() {
        assertEquals(true, pathPaintAntiAlias(rectWith("shape-rendering=\"geometricPrecision\"")))
    }

    @Test
    fun invalidShapeRenderingKeepsAntiAlias() {
        assertEquals(true, pathPaintAntiAlias(rectWith("shape-rendering=\"banana\"")))
    }

    @Test
    fun shapeRenderingInheritedFromGroup() {
        val svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"200\" height=\"200\">" +
            "<g shape-rendering=\"crispEdges\">" +
            "<rect x=\"10\" y=\"10\" width=\"80\" height=\"80\" fill=\"#FF0000\"/>" +
            "</g></svg>"
        assertEquals(false, pathPaintAntiAlias(svg))
    }

    @Test
    fun paintConfigurationAntiAliasSync() {
        val cfg = PaintConfiguration()
        assertTrue(cfg.antiAlias)
        val before = cfg.version
        cfg.setAntiAlias(true)
        assertEquals(before, cfg.version)
        cfg.setAntiAlias(false)
        assertEquals(false, cfg.antiAlias)
        assertTrue(cfg.version > before)
        val copy = PaintConfiguration()
        copy.setFrom(cfg)
        assertFalse(copy.antiAlias)
    }
}
