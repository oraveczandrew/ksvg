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
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class D11TransformViewBoxOrderTest {

    @Test
    fun elementTransformIsOutermost() {
        // Nested <svg> with viewBox="0 0 10 10" over a 100x100 viewport (scale x10),
        // plus transform="translate(50,0)". Per SVG the element `transform` is outermost:
        // content (0..10) -> viewBox scale x10 -> (0..100) -> translate(50,0) -> (50..150).
        // So the red rect must sit at x in [50,150], shifted right by 50.
        val svg = """
            <svg width="200" height="200" xmlns="http://www.w3.org/2000/svg">
              <svg x="0" y="0" width="100" height="100" viewBox="0 0 10 10"
                   transform="translate(50,0)" overflow="visible">
                <rect x="0" y="0" width="10" height="10" fill="red"/>
              </svg>
            </svg>
        """.trimIndent()

        val document = SVG.getFromString(svg)
        val bitmap = createBitmap(200, 200)
        val canvas = Canvas(bitmap)
        document.renderToCanvas(canvas)

        // Correct (transform outermost): red spans x 50..150.
        assertTrue("Expected red rect shifted to x=75 (transform outermost)", isRed(bitmap, 75, 50))
        assertTrue("Expected red rect at x=125 (transform outermost)", isRed(bitmap, 125, 50))
        // It must NOT be at the origin (that would be the no-transform / wrong-order case).
        assertTrue("Expected no red at x=25 (rect should be shifted right by 50)", !isRed(bitmap, 25, 50))
    }
}
