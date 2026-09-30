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
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.renderWithLibrary
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode
import kotlin.math.abs

/**
 * `FillPaint`/`StrokePaint` filter inputs on the software backend.
 *
 * `FillPaint` is the element's fill without its stroke (and without its own
 * filter); `StrokePaint` the stroke without the fill. Both resolve through
 * the generic `results` map, so every primitive's `in`/`in2`/`feMergeNode`
 * works once they are recorded — no per-primitive changes.
 *
 * Renders with the software backend (`softwareFiltering = true`) for
 * deterministic output (see AGENTS.md); the GPU33 decline lives in the
 * device suite (`assertChainBackend(expectFallback = true)`).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class FillStrokePaintTest {

    private fun render(svg: String): Bitmap {
        return renderWithLibrary(
            svg,
            createBitmap(256, 256, Bitmap.Config.ARGB_8888),
            softwareFiltering = true,
        )
    }

    private fun rectSvg(filterBody: String, fill: String, strokeWidth: Int = 24): String {
        return """
            <svg xmlns="http://www.w3.org/2000/svg" width="256" height="256">
              <defs>
                <filter id="f" x="-20%" y="-20%" width="140%" height="140%">
                  $filterBody
                </filter>
              </defs>
              <rect x="48" y="48" width="160" height="160"
                    fill="$fill" stroke="#0000ff" stroke-width="$strokeWidth"
                    filter="url(#f)"/>
            </svg>
        """.trimIndent()
    }

    private fun countDiffering(a: Bitmap, b: Bitmap, threshold: Int = 16): Int {
        var differing = 0
        for (y in 0 until 256) {
            for (x in 0 until 256) {
                val c1 = a.getPixel(x, y)
                val c2 = b.getPixel(x, y)
                if (abs(c1.alpha - c2.alpha) >= threshold ||
                    abs(c1.red - c2.red) >= threshold ||
                    abs(c1.green - c2.green) >= threshold ||
                    abs(c1.blue - c2.blue) >= threshold
                ) {
                    differing++
                }
            }
        }
        return differing
    }

    @Test
    fun compositeFillOverStrokeDiffersFromStrokeOverFill() {
        // Two DISTINCT inputs must arrive: swapping them changes the output.
        // Before the fix both resolve to null (primitives skipped) and the two
        // renders are identical.
        val fillOverStroke = render(
            rectSvg(
                """<feComposite in="FillPaint" in2="StrokePaint" operator="over"/>""",
                fill = "#ff0000",
            ),
        )
        val strokeOverFill = render(
            rectSvg(
                """<feComposite in="StrokePaint" in2="FillPaint" operator="over"/>""",
                fill = "#ff0000",
            ),
        )
        val differing = countDiffering(fillOverStroke, strokeOverFill)
        assertTrue(
            "FillPaint/StrokePaint order swap must change pixels, differing=$differing",
            differing > 500,
        )
        // Fill-over-stroke: deep interior is the red fill.
        val interior = fillOverStroke.getPixel(128, 128)
        assertTrue(
            "interior must be red fill, was ${Integer.toHexString(interior)}",
            interior.alpha > 200 && interior.red > 150 && interior.blue < 100,
        )
        // Stroke-over-fill: the same interior band near the edge is blue stroke.
        // Stroke straddles the rect edge (48..208); the 24-wide stroke covers
        // 36..60 on the left, so sample well inside that band.
        val edgeBand = strokeOverFill.getPixel(54, 128)
        assertTrue(
            "edge band must be blue stroke when stroke is on top, was ${Integer.toHexString(edgeBand)}",
            edgeBand.alpha > 200 && edgeBand.blue > 150 && edgeBand.red < 100,
        )
    }

    @Test
    fun fillPaintExcludesStroke() {
        // Identity on FillPaint: the blue stroke ring must vanish, the red
        // fill must stay. Before the fix the source (with stroke) passes
        // through and the stroke pixel is opaque blue.
        val b = render(
            rectSvg(
                """<feOffset in="FillPaint" dx="0" dy="0"/>""",
                fill = "#ff0000",
            ),
        )
        // Outside the fill edge but inside the stroke (rect edge at 48, the
        // 24-wide stroke reaches out to 36): must be transparent, not blue.
        val strokeBand = b.getPixel(42, 128)
        assertTrue(
            "stroke band must be transparent in FillPaint, was ${Integer.toHexString(strokeBand)}",
            strokeBand.alpha < 50,
        )
        // Fill interior stays opaque red.
        val interior = b.getPixel(128, 128)
        assertTrue(
            "interior must stay red fill, was ${Integer.toHexString(interior)}",
            interior.alpha > 200 && interior.red > 150 && interior.blue < 100,
        )
    }

    @Test
    fun fillPaintCarriesGradientFill() {
        // A shader-backed (gradient) fill must flow through FillPaint, not
        // just solid colors: identity on FillPaint over a gradient rect shows
        // the gradient without the stroke.
        val b = render(
            rectSvg(
                """<feOffset in="FillPaint" dx="0" dy="0"/>""",
                fill = "url(#g)",
            ).replace(
                "<defs>",
                """<defs>
                <linearGradient id="g" x1="0" y1="0" x2="1" y2="0">
                  <stop offset="0" stop-color="#ff0000"/>
                  <stop offset="1" stop-color="#0000ff"/>
                </linearGradient>""",
            ),
        )
        // Left interior: red end of the gradient.
        val left = b.getPixel(70, 128)
        assertTrue(
            "gradient left must be red-ish, was ${Integer.toHexString(left)}",
            left.alpha > 200 && left.red > 150 && left.blue < 150,
        )
        // Right interior: blue end of the gradient.
        val right = b.getPixel(186, 128)
        assertTrue(
            "gradient right must be blue-ish, was ${Integer.toHexString(right)}",
            right.alpha > 200 && right.blue > 150 && right.red < 150,
        )
        // Stroke band stays transparent (no blue stroke leaking in).
        val strokeBand = b.getPixel(42, 128)
        assertTrue(
            "stroke band must be transparent in FillPaint, was ${Integer.toHexString(strokeBand)}",
            strokeBand.alpha < 50,
        )
    }
}
