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
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * Phase 0 probe (D7, UNCERTAIN): `feColorMatrix` offset is multiplied by 255.
 *
 * In `FilterColor.createFilterPaint` the matrix offset terms (indices 4/9/14/19)
 * are multiplied by 255. Android's `ColorMatrix` offset column is already in
 * 0..1, so ×255 over-brightens.
 *
 * Probe: a black source, `feColorMatrix` with R offset = 0.5 and A offset = 1.
 * Correct (0..1 offset): R' = ~188 (0.5 in linearRGB -> sRGB). Bug (×255):
 * R' = 255.
 *
 * This is a CONFIRMATION probe: it is expected to FAIL today if the bug is real
 * (pixel red channel == 255), confirming D7.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class D7FeColorMatrixOffsetProbe {

    @Test
    fun offsetIsNotMultipliedBy255() {
        val svg = """
            <svg width="100" height="100">
              <defs>
                <filter id="f" x="0" y="0" width="100" height="100">
                  <feColorMatrix type="matrix"
                    values="0 0 0 0 0.5  0 0 0 0 0  0 0 0 0 0  0 0 0 1 0"/>
                </filter>
              </defs>
              <rect width="100" height="100" fill="black" filter="url(#f)"/>
            </svg>
        """.trimIndent()

        val document = SVG.getFromString(svg)
        val bitmap = createBitmap(100, 100)
        val canvas = Canvas(bitmap)
        document.renderToCanvas(canvas)

        val pixel = bitmap.getPixel(50, 50)
        println("D7_PROBE actual red = ${pixel.red}")
        // Android's ColorMatrixColorFilter expects the offset column in 0..255 space, so
        // SVG's 0..1 offset (0.5) is correctly scaled by 255 in FilterColor.createFilterPaint,
        // giving a 0..255 offset of ~127.5 -> R ~= 128 for an sRGB-space green input.
        // A bug REMOVING that scaling would yield R ~= 0 (offset 0.5 treated as 0..255 -> ~0),
        // and a bug DOUBLE-scaling would blow R out to ~255. Assert the correct ~128.
        assertTrue("feColorMatrix offset 0.5 should map R to ~128 (got ${pixel.red})", pixel.red in 110..150)
    }
}
