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
import hu.oandras.androidsvg.utils.ceilToInt
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class RenderCSSTest {
    /*
       * Checks that calling renderToCanvas() does not have any side effects for the Canvas object.
       * See Issue #50. https://github.com/BigBadaboom/androidsvg/issues/50
       */
    @Test
    @Throws(SVGParseException::class)
    fun renderWithCSS() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = Bitmap.createBitmap(
            svg.documentWidth.ceilToInt(),
            svg.documentHeight.ceilToInt(),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(newBM)

        var renderOptions: RenderOptions? = RenderOptions.create().css("")
        svg.renderToCanvas(canvas, renderOptions)

        val mock: MockCanvas = canvas.asShadow()

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))

        // Step 2
        mock.clearOperations()

        renderOptions = RenderOptions.create().css("rect { fill: red }")
        svg.renderToCanvas(canvas, renderOptions)

        //println("DEBUG OPS: " + ops.joinToString(", "))

        // rect should be red now
        assertEquals("#ffff0000", mock.paintProp(3, "color"))


        // Step 3: Make sure temp CSS hasn't stuck around
        mock.clearOperations()

        svg.renderToCanvas(canvas)

        //println("DEBUG OPS: " + ops.joinToString(", "))

        // rect should be black again
        assertEquals("#ff000000", mock.paintProp(3, "color"))
    }
}
