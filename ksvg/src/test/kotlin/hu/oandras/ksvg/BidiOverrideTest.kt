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
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.style.parseUnicodeBidi
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.render.text.visualOrderForOverride
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * Scoped G12: `unicode-bidi: bidi-override` / `isolate-override` reorder
 * LTR-content chunks into visual order at build time (rsvg parity:
 * `"Hello 123"` under an RTL override renders as `"321 olleH"`).
 *
 * Pixel assertions pin the override render against the statically reversed
 * control with [Bitmap.sameAs] (NATIVE graphics, no Mock shadows — per
 * AGENTS.md). Middle anchoring centers both on the same point (identical
 * total width), so only glyph order matters.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class BidiOverrideTest {

    // --- visualOrderForOverride units ---

    @Test
    fun rtlOverride_reversesLatinAndDigits() {
        assertEquals("321 olleH", visualOrderForOverride("Hello 123", baseRtl = true))
    }

    @Test
    fun ltrOverride_onLtrText_isNoop() {
        assertNull(visualOrderForOverride("Hello 123", baseRtl = false))
    }

    @Test
    fun rtlOverride_onRtlText_keepsPlatformBehavior() {
        // Documented scope cut: strong-RTL chunks are declined (a second
        // platform reordering would corrupt them).
        assertNull(visualOrderForOverride("مرحبا", baseRtl = true))
    }

    @Test
    fun empty_isNoop() {
        assertNull(visualOrderForOverride("", baseRtl = true))
    }

    @Test
    fun combiningMark_travelsWithBase() {
        // "a" + combining acute + "b" under an RTL override becomes
        // "b" + "a" + combining acute (mark follows its base).
        assertEquals("bá", visualOrderForOverride("áb", baseRtl = true))
    }

    @Test
    fun surrogatePair_staysIntact() {
        assertEquals("ba\uD83D\uDE00", visualOrderForOverride("\uD83D\uDE00ab", baseRtl = true))
    }

    @Test
    fun parse_acceptsOverrideValues_caseInsensitive() {
        assertEquals(
            hu.oandras.ksvg.dom.style.UnicodeBidi.bidiOverride,
            parseUnicodeBidi("BIDI-OVERRIDE")
        )
        assertEquals(
            hu.oandras.ksvg.dom.style.UnicodeBidi.isolateOverride,
            parseUnicodeBidi("isolate-override")
        )
    }

    // --- pixel parity (sample rows 5-6) ---

    private fun render(svgContent: String, width: Int = 400, height: Int = 100): Bitmap {
        val parsed = SVG.getFromString(svgContent) as SVGImpl
        val bitmap = createBitmap(width, height)
        parsed.renderToCanvas(Canvas(bitmap))
        return bitmap
    }

    private fun textSvg(inner: String): String {
        return """<svg xmlns="http://www.w3.org/2000/svg" width="400" height="100">""" +
            """<text x="200" y="60" font-size="36" font-family="sans-serif" text-anchor="middle">$inner</text></svg>"""
    }

    @Test
    fun bidiOverride_matchesReversedControl() {
        val overridden = render(
            textSvg("""<tspan direction="rtl" unicode-bidi="bidi-override">Hello 123</tspan>""")
        )
        val control = render(textSvg("321 olleH"))
        assertTrue(overridden.sameAs(control))
    }

    @Test
    fun isolateOverride_matchesReversedControl() {
        val overridden = render(
            textSvg("""<tspan direction="rtl" unicode-bidi="isolate-override">Hello 123</tspan>""")
        )
        val control = render(textSvg("321 olleH"))
        assertTrue(overridden.sameAs(control))
    }

    @Test
    fun noOverride_keepsLogicalOrder() {
        val plain = render(textSvg("Hello 123"))
        val control = render(textSvg("321 olleH"))
        assertTrue(!plain.sameAs(control))
    }
}
