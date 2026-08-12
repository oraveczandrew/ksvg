/*
 *    Copyright 2013-2020 Paul LeBeau, Cave Rock Software Ltd.
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
import android.graphics.Canvas
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class StrokeTest {
    /*
       * Checks that stroke-width="1" does render something.
       * This is just a companion test to check that there has been no regression after the #289 fix.
       * See Issue #289. https://github.com/BigBadaboom/androidsvg/issues/289
       */
    @Test
    @Throws(SVGParseException::class)
    fun strokeWidthNonZero() {
        // First test a non-zero stroke so we know that's working
        val test =
            "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100\" height=\"100\" viewBox=\"0 0 20 20\">" +
                    "  <circle cx=\"10\" cy=\"10\" r=\"10\" stroke=\"black\" stroke-width=\"1\" fill=\"none\" />" +
                    "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(newBM)
        svg.renderToCanvas(canvas)

        val mock: MockCanvas = canvas.asShadow()

        assertEquals(1L, countPathsDrawn(mock))
    }


    /*
    * Checks that stroke-width="0" doesn't render anything.
    * See Issue #289. https://github.com/BigBadaboom/androidsvg/issues/289
    */
    @Test
    @Throws(SVGParseException::class)
    fun strokeWidthZero() {
        // Now test a zero stroke so we know that's working
        val test =
            "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100\" height=\"100\" viewBox=\"0 0 20 20\">" +
                    "  <circle cx=\"10\" cy=\"10\" r=\"10\" stroke=\"black\" stroke-width=\"0\" fill=\"none\" />" +
                    "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(newBM)
        svg.renderToCanvas(canvas)

        val mock: MockCanvas = canvas.asShadow()

        assertEquals(0, countPathsDrawn(mock))
    }


    private fun countPathsDrawn(canvas: MockCanvas): Long {
        val ops: List<String> = canvas.getOperations()
        println(ops.joinToString(","))
        return ops.stream().filter { op -> op.startsWith("drawPath(") }.count()
    }
}
