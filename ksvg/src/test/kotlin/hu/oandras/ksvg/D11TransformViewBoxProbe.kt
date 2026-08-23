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
import android.graphics.Color
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * Phase 0 probe (D11, UNCERTAIN): `transform` + `viewBox` application order.
 *
 * Per SVG, an element's `transform` is applied within the user coordinate
 * system established by the `viewBox` (viewBox mapping is applied first, then
 * the element transform). This probe confirms the current behaviour matches
 * the spec.
 *
 * viewBox 0 0 100 100 on a 200x200 canvas => 2x scale. A 50x50 rect with
 * `transform="translate(50,0)"` should be at user (50,0)..(100,50) => px
 * (100..200, 0..100). So (150,25) is RED and (50,25) is TRANSPARENT.
 *
 * This is a CONFIRMATION probe: it is expected to PASS if the order is correct,
 * or FAIL if the element transform is applied outermost in device space.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class D11TransformViewBoxProbe {

    @Test
    fun elementTransformAppliedWithinViewBox() {
        val svg = """
            <svg width="200" height="200" viewBox="0 0 100 100">
              <rect width="50" height="50" fill="red" transform="translate(50,0)"/>
            </svg>
        """.trimIndent()

        val document = SVG.getFromString(svg)
        val bitmap = createBitmap(200, 200)
        val canvas = Canvas(bitmap)
        document.renderToCanvas(canvas)

        assertEquals("Element transform must be applied within viewBox space (150,25) -> red", Color.RED, bitmap.getPixel(150, 25))
        assertEquals("Outside the translated rect (50,25) must be transparent", 0, bitmap.getPixel(50, 25))
    }
}
