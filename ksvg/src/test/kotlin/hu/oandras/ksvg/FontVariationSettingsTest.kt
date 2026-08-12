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
import android.os.Build
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(
    manifest = Config.NONE,
    sdk = [Build.VERSION_CODES.O],
    shadows = [MockCanvas::class, MockPath::class, MockPaint::class]
)
class FontVariationSettingsTest {
    @Test
    @Throws(SVGParseException::class)
    fun fontVariation() {
        val test = "<svg>\n" +
                "  <text style=\"font-variation-settings: 'wght' 100, 'slnt' -14, 'ital' 1 \">Test</text>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm1: Bitmap = Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bm1)
        svg.renderToCanvas(canvas)

        val mock: MockCanvas = canvas.asShadow()

        //List<String>  ops = ((MockCanvas) Shadow.extract(canvas)).getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(
            sortVariations("'ital' 1,'slnt' -14,'wdth' 100,'wght' 100"),
            sortVariations(
                mock.paintProp(
                    3,
                    "fv"
                )
            )
        )
    }

    //-----------------------------------------------------------------------------------------------
    @Test
    @Throws(SVGParseException::class)
    fun fontBoldVsWght() {
        val test = "<svg>\n" +
                "  <text style=\"font-weight: bold; font-variation-settings: 'wght' 100 \">Test</text>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm1: Bitmap = Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bm1)
        svg.renderToCanvas(canvas)

        val mock: MockCanvas = canvas.asShadow()

        //List<String>  ops = ((MockCanvas) Shadow.extract(canvas)).getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(
            sortVariations("'wdth' 100,'wght' 100"),
            sortVariations(
                mock.paintProp(
                    3,
                    "fv"
                )
            )
        )
    }


    companion object {
        //-----------------------------------------------------------------------------------------------
        private fun sortVariations(variations: String): String {
            return variations.split(",").sorted().joinToString(",")
        }
    }
}
