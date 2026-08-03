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
package hu.oandras.androidsvg

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Rect
import hu.oandras.androidsvg.utils.ceilToInt
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class RenderTest {
    /*
       * Checks that calling renderToCanvas() does not have any side effects for the Canvas object.
       * See Issue #50. https://github.com/BigBadaboom/androidsvg/issues/50
       */
    @Test
    @Throws(SVGParseException::class)
    fun renderToCanvasPreservesState() {
        //disableLogging();
        val test =
            "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100\" height=\"100\" viewBox=\"0 0 20 20\">" +
                    "  <circle cx=\"10\" cy=\"10\" r=\"10\" transform=\"scale(2)\"/>" +
                    "  <g transform=\"rotate(45)\"></g>" +
                    "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = Bitmap.createBitmap(
            svg.documentWidth.ceilToInt(),
            svg.documentHeight.ceilToInt(),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(newBM)

        @Suppress("DEPRECATION")
        val beforeMatrix: Matrix = canvas.matrix
        val beforeClip: Rect = canvas.getClipBounds()
        val beforeSaves: Int = canvas.saveCount

        //canvas.save(); canvas.scale(2f, 2f); canvas.restore();
        svg.renderToCanvas(canvas)

        @Suppress("DEPRECATION")
        val afterMatrix: Matrix = canvas.matrix
        assertEquals(beforeMatrix, afterMatrix)
        assertTrue(beforeMatrix.isIdentity)
        assertTrue(afterMatrix.isIdentity)

        val afterClip: Rect = canvas.getClipBounds()
        assertEquals(beforeClip, afterClip)

        val afterSaves: Int = canvas.saveCount
        assertEquals(beforeSaves, afterSaves)
    }
}
