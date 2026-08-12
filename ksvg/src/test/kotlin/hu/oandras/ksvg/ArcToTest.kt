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
class ArcToTest {
    @Test
    @Throws(SVGParseException::class)
    fun testIssue155() {
        val test = "<svg>" +
                "  <path d=\"M 163.637 412.021 a 646225.813 646225.813 0 0 1 -36.313 162\"/>" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(newBM)

        svg.renderToCanvas(canvas)

        val ops: List<String> = canvas.asShadow().getOperations()
        assertEquals(6, ops.size)
        assertEquals(
            "drawPath('M 163.63701 412.02103 C 151.5625 466.03125 139.4375 520.0156 127.32401 574.021', Paint(color:#ff000000; f:ANTI_ALIAS|LINEAR_TEXT|SUBPIXEL_TEXT; h:OFF; ls:0; s:FILL; tf:android.graphics.Typeface@0; ts:16))",
            ops[3]
        )
    }


    @Test
    @Throws(SVGParseException::class)
    fun testIssue156() {
        val test = "<svg>" +
                "  <path d=\"M 422.776 332.659 a 539896.23 539896.23 0 0 0-22.855-26.558\"/>" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(newBM)

        svg.renderToCanvas(canvas)

        val ops: List<String> = canvas.asShadow().getOperations()
        assertEquals(6, ops.size)
        assertEquals(
            "drawPath('M 422.77603 332.65903 C 415.15625 323.8125 407.53125 314.96875 399.92102 306.101', Paint(color:#ff000000; f:ANTI_ALIAS|LINEAR_TEXT|SUBPIXEL_TEXT; h:OFF; ls:0; s:FILL; tf:android.graphics.Typeface@0; ts:16))",
            ops[3]
        )
    }
}
