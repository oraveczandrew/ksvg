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
 * Phase 0 baseline (C6): `additive="sum"` frame-accumulates.
 *
 * `additive="sum"` should add the animation's value to the *base* value each
 * frame: base + value. Because `applyAnimatedStyle` resets the style builder
 * from the (already mutated) `renderState.style`, the previous frame's result
 * is treated as the new base, so the value accumulates: base + value + value ...
 *
 * The [KSVGDrawable] caches its render tree, so the mutated `renderState.style`
 * persists between draws — the exact scenario where the bug manifests.
 *
 * Asserts the CORRECT behaviour (base + 0.1). Today it fails.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class C6AdditiveTest {

    @Test
    fun additiveSumUsesBaseNotPreviousFrame() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <rect width="100" height="100" fill="red" opacity="0.3">
                    <animate attributeName="opacity" values="0.1;0.1" dur="1s" additive="sum" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl

        val drawable = KSVGDrawable(svg)
        val bitmap = createBitmap(100, 100)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, 100, 100)

        // Frame 1: base 0.3 + 0.1 = 0.4, stored in node style.
        svg.animationTimeMs = 0L
        drawable.draw(canvas)

        // Frame 2: same cached node. Clear the canvas first, otherwise frame 2
        // composites over frame 1 and the opaque-on-transparent rect accumulates.
        // Correct: base 0.3 + 0.1 = 0.4 -> alpha 102.
        // Bug: (0.4 from frame1) + 0.1 = 0.5 -> alpha 127.
        bitmap.eraseColor(0)
        svg.animationTimeMs = 0L
        drawable.draw(canvas)

        assertEquals("additive=sum must add to base each frame (alpha 102)", 102, bitmap.getPixel(50, 50).alpha)
    }
}
