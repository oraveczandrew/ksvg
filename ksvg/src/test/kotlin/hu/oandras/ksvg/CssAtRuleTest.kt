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
import hu.oandras.ksvg.css.CSSParser
import hu.oandras.ksvg.css.MediaType
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import hu.oandras.ksvg.mocks.asShadow
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.utils.ceilToInt
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Coverage for the CSS at-rule paths (coverage round): media matching units,
 * non-matching `@media` blocks, unknown at-rule skipping and malformed
 * `@import` containment.
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class CssAtRuleTest {

    @Test
    fun mediaMatchesUnits() {
        assertTrue(CSSParser.mediaMatches("", MediaType.screen))
        assertTrue(CSSParser.mediaMatches("all", MediaType.screen))
        assertTrue(CSSParser.mediaMatches("screen", MediaType.screen))
        assertTrue(CSSParser.mediaMatches("SCREEN", MediaType.screen))
        assertTrue(CSSParser.mediaMatches("print, screen", MediaType.screen))
        assertFalse(CSSParser.mediaMatches("print", MediaType.screen))
        assertFalse(CSSParser.mediaMatches("print, projection", MediaType.screen))
        // Unknown media types are false per CSS (not match-all).
        assertFalse(CSSParser.mediaMatches("hologram", MediaType.screen))
        assertTrue(CSSParser.mediaMatches("hologram, screen", MediaType.screen))
    }

    private fun rectFillWithCss(css: String): String {
        val test = "<svg width=\"100\" height=\"100\">" +
            "  <rect width=\"10\" height=\"10\"/>" +
            "  <style>$css</style>" +
            "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = createBitmap(
            svg.documentWidth.ceilToInt(),
            svg.documentHeight.ceilToInt(),
        )
        val canvas = Canvas(newBM)

        val renderOptions: RenderOptions = RenderOptions.create().css("")
        svg.renderToCanvas(canvas, renderOptions)

        val mock: MockCanvas = canvas.asShadow()
        return mock.paintProp(4, "color")
    }

    @Test
    @Throws(KSVGParseException::class)
    fun nonMatchingMediaBlockIgnored() {
        assertEquals("#ff000000", rectFillWithCss("@media print { rect { fill: #0f0; } }"))
    }

    @Test
    @Throws(KSVGParseException::class)
    fun matchingMediaListApplies() {
        assertEquals("#ff00ff00", rectFillWithCss("@media print, screen { rect { fill: #0f0; } }"))
    }

    @Test
    @Throws(KSVGParseException::class)
    fun unknownAtRuleSkipped() {
        assertEquals(
            "#ff00ff00",
            rectFillWithCss("@foobar { nonsense; } rect { fill: #0f0; }")
        )
    }

    @Test
    @Throws(KSVGParseException::class)
    fun malformedImportContained() {
        assertEquals(
            "#ff00ff00",
            rectFillWithCss("@import; rect { fill: #0f0; }")
        )
    }
}
