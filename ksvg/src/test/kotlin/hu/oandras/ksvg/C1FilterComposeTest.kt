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
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import hu.oandras.ksvg.mocks.asShadow
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Phase 0 baseline (C1): `filter` currently drops `opacity` / `mask` / `mix-blend-mode`.
 *
 * When an element has a `filter`, [Renderer.renderWithFilter] composites the filtered
 * bitmap with a `null` paint (see Renderer.kt ~969), so the element's `opacity`,
 * `mask` and `mix-blend-mode` are silently ignored.
 *
 * These tests assert the CORRECT (post-fix) behaviour: the final composite
 * `drawBitmap` must be drawn through a paint that honours `opacity` (alpha) and
 * `mix-blend-mode` (blend mode). Today they fail because the paint is `null`.
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class C1FilterComposeTest {

    private fun lastDrawBitmapPaint(svg: String): String {
        val document = SVG.getFromString(svg)
        // Real Canvas wrapping a Bitmap. Robolectric swaps in the MockCanvas shadow,
        // which records the draw operations we inspect via asShadow().
        val canvas = Canvas(createBitmap(100, 100))
        document.renderToCanvas(canvas)
        val ops = canvas.asShadow().getOperations()
        return ops.last { it.startsWith("drawBitmap") }
    }

    @Test
    fun filterHonorsOpacity() {
        val op = lastDrawBitmapPaint(
            """
            <svg width="100" height="100">
              <defs>
                <filter id="f">
                  <feColorMatrix type="matrix" values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 1 0"/>
                </filter>
              </defs>
              <rect width="100" height="100" fill="red" filter="url(#f)" opacity="0.5"/>
            </svg>
            """.trimIndent()
        )

        // The composite paint must carry the element opacity (0.5 -> alpha 127).
        // Currently the paint is `null` (", null)"), so this fails.
        assertFalse("Filter composite must not be drawn with a null paint (opacity dropped)", op.endsWith("null)"))
        assertTrue("Filter composite paint should carry alpha for opacity=0.5 (a:127)", op.contains("a:127"))
    }

    @Test
    fun filterHonorsBlendMode() {
        val op = lastDrawBitmapPaint(
            """
            <svg width="100" height="100">
              <defs>
                <filter id="f">
                  <feColorMatrix type="matrix" values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 1 0"/>
                </filter>
              </defs>
              <rect width="100" height="100" fill="red" filter="url(#f)" style="mix-blend-mode: multiply"/>
            </svg>
            """.trimIndent()
        )

        // The composite paint must carry the blend mode.
        // Currently the paint is `null`, so this fails.
        assertFalse("Filter composite must not be drawn with a null paint (blend-mode dropped)", op.endsWith("null)"))
        assertTrue("Filter composite paint should carry the blend mode", op.contains("blend:"))
    }
}
