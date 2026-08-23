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
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.utils.alpha
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * Phase 0 baseline (C5): `fill="remove"` never reverts.
 *
 * With `fill="remove"`, once an animation finishes the element must render with
 * its *base* value again. Because the renderer mutates `renderState.style` in
 * place and never snapshots the base, the last animated value stays "frozen"
 * (so `remove` behaves like `freeze`).
 *
 * The [KSVGDrawable] caches its render tree across frames, so the mutated
 * `renderState.style` persists between draws — exactly the scenario where the
 * bug manifests.
 *
 * Asserts the CORRECT behaviour (base value restored). Today it fails.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class C5FillRemoveTest {

    @Test
    fun fillRemoveRevertsToBaseAfterEnd() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <rect width="100" height="100" fill="red" opacity="1">
                    <animate attributeName="opacity" from="0" to="1" dur="1s" fill="remove"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl

        val drawable = KSVGDrawable(svg)
        val bitmap = createBitmap(100, 100)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, 100, 100)

        // Frame 1: mid-animation (t=500ms) -> opacity 0.5, stored in node style.
        svg.animationTimeMs = 500L
        drawable.draw(canvas)

        // Frame 2: past the end (t=1500ms) with fill="remove".
        // Correct: reverts to base opacity 1.0 -> fully opaque (alpha 255).
        // Bug: last animated value persists -> alpha 127.
        svg.animationTimeMs = 1500L
        drawable.draw(canvas)

        assertEquals("fill=remove should revert to base opacity (alpha 255)", 255, bitmap.getPixel(50, 50).alpha)
    }
}
