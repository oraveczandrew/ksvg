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
class FontFeatureSettingsTest {
    @Suppress("SpellCheckingInspection")
    @Test
    @Throws(SVGParseException::class)
    fun fontFeatures() {
        val test = "<svg>\n" +
                "  <text style=\"font-feature-settings: 'liga' 0, 'clig', 'pnum' on, 'swsh' 42\">Test</text>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm1: Bitmap = Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bm1)
        svg.renderToCanvas(canvas)

        val mock: MockCanvas = canvas.asShadow()

        val ops: List<String> = mock.getOperations()
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(
            sortVariations("'onum' 0,'subs' 0,'unic' 0,'calt' 1,'dlig' 0,'c2pc' 0,'mkmk' 1,'swsh' 42,'zero' 0,'hlig' 0,'c2sc' 0,'sups' 0,'pcap' 0,'jp78' 0,'pwid' 0,'trad' 0,'ordn' 0,'titl' 0,'fwid' 0,'frac' 0,'locl' 1,'pnum' 1,'smpl' 0,'kern' 1,'tnum' 0,'liga' 0,'lnum' 0,'clig' 1,'jp90' 0,'rlig' 1,'ccmp' 1,'ruby' 0,'jp83' 0,'smcp' 0,'afrc' 0,'jp04' 0,'mark' 1"),
            sortVariations(mock.paintProp(3, "ff"))
        )
    }

    //-----------------------------------------------------------------------------------------------
    @Suppress("SpellCheckingInspection")
    @Test
    @Throws(SVGParseException::class)
    fun fontStretch() {
        val test = "<svg>\n" +
                "  <text style=\"font-stretch: ultra-condensed\">Test\n" +
                "  <tspan style=\"font-stretch: normal\">Test</tspan></text>\n" +
                "  <text style=\"font-stretch: ultra-expanded\">Test</text>\n" +
                "  <text style=\"font-stretch: 80%\">Test</text>\n" +
                "  <text style=\"font-stretch: 66\">Test</text>\n" +
                "  <text style=\"font-stretch: -10%\">Test</text>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm1: Bitmap = Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bm1)
        svg.renderToCanvas(canvas)

        val mock: MockCanvas = canvas.asShadow()

        val ops: List<String> = mock.getOperations()
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(sortVariations("'wdth' 50,'wght' 400"), sortVariations(mock.paintProp(5, "fv")))
        assertEquals(sortVariations("'wdth' 100,'wght' 400"), sortVariations(mock.paintProp(7, "fv")))
        assertEquals(sortVariations("'wdth' 200,'wght' 400"), sortVariations(mock.paintProp(11, "fv")))
        assertEquals(sortVariations("'wdth' 80,'wght' 400"), sortVariations(mock.paintProp(14, "fv")))
        assertEquals(sortVariations("'wdth' 100,'wght' 400"), sortVariations(mock.paintProp(17, "fv")))
        assertEquals(sortVariations("'wdth' 100,'wght' 400"), sortVariations(mock.paintProp(20, "fv")))
    }


    companion object {
        //-----------------------------------------------------------------------------------------------
        private fun sortVariations(value: String): String {
            return value.split(",").sorted().joinToString(",")
        }
    }
}
