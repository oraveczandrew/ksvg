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
class CSSTest {
    /* !important not supported yet
      @Test
      public void important() throws SVGParseException
      {
         //disableLogging();
         String  test = "<svg width=\"100\" height=\"100\">" +
                        "  <rect id=\"one\" width=\"10\" height=\"10\"/>" +
                        "  <rect id=\"two\" width=\"10\" height=\"10\" x=\"10\"/>" +
                        "  <rect id=\"three\" width=\"10\" height=\"10\" x=\"20\"/>" +
                        "  <rect id=\"four\" width=\"10\" height=\"10\" x=\"30\"/>" +
                        "  <style>" +
                        "    rect { fill: #0f0 ! important; }" +
                        "    rect { fill: #f00; }" +
                        "    #four { fill: #f00; }" +
                        "  </style>" +
                        "</svg>";
         SVG  svg = SVG.getFromString(test);
   
         Bitmap newBM = Bitmap.createBitmap((int) Math.ceil(svg.getDocumentWidth()),
                                            (int) Math.ceil(svg.getDocumentHeight()),
                                            Bitmap.Config.ARGB_8888);
         Canvas canvas = new Canvas(newBM);
   
         RenderOptions renderOptions = RenderOptions.create().css("");
         svg.renderToCanvas(canvas, renderOptions);
   
         MockCanvas    mock = ((MockCanvas) Shadow.extract(canvas));
         List<String> ops = mock.getOperations();
         //println("DEBUG OPS: " + ops.joinToString(", "))
   
         assertEquals("#ff00ff00", mock.paintProp(3, "color"));
         assertEquals("#ff000000", mock.paintProp(6, "color"));
         assertEquals("#ff00ff00", mock.paintProp(9, "color"));
         assertEquals("#ff000000", mock.paintProp(12, "color"));
      }
   */
    @Test
    @Throws(SVGParseException::class)
    fun use() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <defs>" +
                "    <rect id=\"r\" width=\"10\" height=\"10\"/>" +
                "  </defs>" +
                "  <style>" +
                "    use { fill: #0f0; }" +
                "  </style>" +
                "  <use href=\"#r\"/>" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = Bitmap.createBitmap(
            svg.documentWidth.ceilToInt(),
            svg.documentHeight.ceilToInt(),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(newBM)

        val renderOptions: RenderOptions = RenderOptions.create().css("")
        svg.renderToCanvas(canvas, renderOptions)

        val mock: MockCanvas = canvas.asShadow()

        //List<String> ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff00ff00", mock.paintProp(5, "color"))
    }


    // Issue 204
    @Test
    @Throws(SVGParseException::class)
    fun nonAsciiClassNames() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <style>" +
                "    .зеленый {fill:#0f0}" +
                "  </style>" +
                "  <rect class=\"зеленый\" width=\"10\" height=\"10\"/>" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = Bitmap.createBitmap(
            svg.documentWidth.ceilToInt(),
            svg.documentHeight.ceilToInt(),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(newBM)

        val renderOptions: RenderOptions = RenderOptions.create().css("")
        svg.renderToCanvas(canvas, renderOptions)

        val mock: MockCanvas = canvas.asShadow()

        //List<String> ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
    }
}
