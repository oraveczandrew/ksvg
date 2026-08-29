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

import android.graphics.Bitmap
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.dom.style.WritingMode
import hu.oandras.ksvg.dom.text.BaselineShift
import hu.oandras.ksvg.dom.text.DominantBaseline
import hu.oandras.ksvg.dom.text.TextOrientation
import hu.oandras.ksvg.dom.text.TextTransform
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.render.textLayoutStyleCacheVersion
import hu.oandras.ksvg.test.countPixels
import hu.oandras.ksvg.test.forEachPixel
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.ParameterizedRobolectricTestRunner
import org.robolectric.ParameterizedRobolectricTestRunner.Parameters
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * Guards the [hu.oandras.ksvg.render.Renderer.renderTextNode] display-list cache wrap:
 *  - repeated renders on a hardware-accelerated (NATIVE) canvas must stay byte-identical,
 *    exercising the real display-list cache path (not just the software passthrough),
 *  - text must actually be rasterized,
 *  - the layout-style cache key must differentiate text-affecting style.
 *
 * Note: the test runs under @GraphicsMode(NATIVE) so text is rasterized (the LEGACY software
 * canvas does not draw glyphs in Robolectric) and the display-list cache is actually active.
 * MockCanvas/MockPaint are intentionally NOT used here: MockPaint overrides setters without
 * calling super, so the real Paint never receives color/textSize and nothing is drawn.
 */
@RunWith(ParameterizedRobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class TextDisplayListCacheTest(
    private val svg: String,
) {

    @Test
    fun softwareRenderIsStableAcrossRenders() {
        val bm1 = renderWithLibrary(svg, createBitmap(120, 120))
        val bm2 = renderWithLibrary(svg, createBitmap(120, 120))

        // The wrapper must not alter the software output: the two renders are byte-identical.
        assertTrue("repeated software renders must be identical", bm1.sameAs(bm2))
    }

    @Test
    fun rendersNonEmptyText() {
        val bm = renderWithLibrary(svg, createBitmap(120, 120))
        // Text must actually be rasterized (at least one opaque pixel).
        val opaque = countPixels(bm) { (it ushr 24) != 0 }
        assertTrue("expected rasterized text pixels (got $opaque opaque)", opaque > 0)
    }

    @Test
    fun underlineDecorationChangesOutput() {
        val plain = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="40"><text x="10" y="20" font-size="20" fill="black">Hi</text></svg>""",
            createBitmap(120, 120),
        )
        val underlined = renderWithLibrary(
            """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="40"><text x="10" y="20" font-size="20" fill="black" text-decoration="underline">Hi</text></svg>""",
            createBitmap(120, 120),
        )
        // Underline must add rasterized pixels below the glyphs.
        assertFalse("underline decoration must change the rendered output", plain.sameAs(underlined))
    }

    companion object {
        @JvmStatic
        @Parameters(name = "{0}")
        fun data(): Collection<Array<Any>> = listOf(
            arrayOf("""<svg xmlns="http://www.w3.org/2000/svg" width="100" height="40"><text x="10" y="20" font-size="20" fill="black">Hello</text></svg>"""),
            arrayOf("""<svg xmlns="http://www.w3.org/2000/svg" width="100" height="40"><text x="10" y="20" font-size="20" fill="black">A<tspan fill="red">B</tspan>C</text></svg>"""),
            arrayOf("""<svg xmlns="http://www.w3.org/2000/svg" width="100" height="40"><text x="10" y="20" font-size="20" fill="black" style="letter-spacing:2">Spaced</text></svg>"""),
            arrayOf("""<svg xmlns="http://www.w3.org/2000/svg" width="100" height="40"><text x="10" y="20" font-size="20" fill="black" style="text-transform:uppercase">abc</text></svg>"""),
        )
    }
}

class TextLayoutStyleCacheVersionTest {

    @Test
    fun baselineVersionIsStable() {
        val a = textLayoutStyleCacheVersion(Style().toBuilder().build())
        val b = textLayoutStyleCacheVersion(Style().toBuilder().build())
        assertTrue("identical styles must hash identically", a == b)
    }

    @Test
    fun writingModeChangesKey() {
        val horizontal = textLayoutStyleCacheVersion(Style().toBuilder().apply { writingMode = WritingMode.horizontal_tb }.build())
        val vertical = textLayoutStyleCacheVersion(Style().toBuilder().apply { writingMode = WritingMode.vertical_rl }.build())
        assertFalse("writing-mode must affect the cache key", horizontal == vertical)
    }

    @Test
    fun textOrientationChangesKey() {
        val mixed = textLayoutStyleCacheVersion(Style().toBuilder().apply { textOrientation = TextOrientation.mixed }.build())
        val upright = textLayoutStyleCacheVersion(Style().toBuilder().apply { textOrientation = TextOrientation.upright }.build())
        assertFalse("text-orientation must affect the cache key", mixed == upright)
    }

    @Test
    fun textTransformChangesKey() {
        val none = textLayoutStyleCacheVersion(Style().toBuilder().apply { textTransform = TextTransform.None }.build())
        val upper = textLayoutStyleCacheVersion(Style().toBuilder().apply { textTransform = TextTransform.Uppercase }.build())
        assertFalse("text-transform must affect the cache key", none == upper)
    }

    @Test
    fun baselineShiftChangesKey() {
        val a = textLayoutStyleCacheVersion(Style().toBuilder().apply {
            baselineShift = BaselineShift(null, BaselineShift.Type.Sub)
        }.build())
        val b = textLayoutStyleCacheVersion(Style().toBuilder().apply {
            baselineShift = BaselineShift(null, BaselineShift.Type.Super)
        }.build())
        assertFalse("baseline-shift must affect the cache key", a == b)
    }

    @Test
    fun dominantBaselineChangesKey() {
        val a = textLayoutStyleCacheVersion(Style().toBuilder().apply { dominantBaseline = DominantBaseline.Auto }.build())
        val b = textLayoutStyleCacheVersion(Style().toBuilder().apply { dominantBaseline = DominantBaseline.Middle }.build())
        assertFalse("dominant-baseline must affect the cache key", a == b)
    }
}
