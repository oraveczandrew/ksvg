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
import android.graphics.RectF
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class RenderToCanvasTest {
    @Test
    @Throws(SVGParseException::class)
    fun renderToCanvas() {
        val test = "<svg viewBox=\"0 0 200 100\">\n" +
                "  <rect width=\"200\" height=\"100\" fill=\"green\"/>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm1: Bitmap = Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888)
        val bmCanvas1 = Canvas(bm1)
        svg.renderToCanvas(bmCanvas1)

        val ops: List<String?> = bmCanvas1.asShadow().getOperations()
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("concat(Matrix(1 0 0 1 0 50))", ops[1])
        assertEquals(
            "drawPath('M 0 0 L 200 0 L 200 100 L 0 100 L 0 0 Z', Paint(color:#ff008000; f:ANTI_ALIAS|LINEAR_TEXT|SUBPIXEL_TEXT; h:OFF; ls:0; s:FILL; tf:android.graphics.Typeface@0; ts:16))",
            ops[3]
        )
    }


    @Test
    @Throws(SVGParseException::class)
    fun renderToCanvasWithViewPort() {
        val test = "<svg viewBox=\"0 0 200 100\">\n" +
                "  <rect width=\"200\" height=\"100\" fill=\"green\"/>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm2: Bitmap = Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888)
        val bmCanvas2 = Canvas(bm2)
        svg.renderToCanvas(bmCanvas2, RectF(50f, 50f, 150f, 150f))

        val ops: List<String> = bmCanvas2.asShadow().getOperations()
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("concat(Matrix(0.5 0 0 0.5 50 75))", ops[1])
        assertEquals(
            "drawPath('M 0 0 L 200 0 L 200 100 L 0 100 L 0 0 Z', Paint(color:#ff008000; f:ANTI_ALIAS|LINEAR_TEXT|SUBPIXEL_TEXT; h:OFF; ls:0; s:FILL; tf:android.graphics.Typeface@0; ts:16))",
            ops[3]
        )
    }


    //--------------------------------------------------------------------------
    @Test
    @Throws(SVGParseException::class)
    fun renderViewToCanvas() {
        val test = "<svg viewBox=\"0 0 100 100\">\n" +
                "  <view id=\"test\" viewBox=\"25 25 50 50\"/>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm1: Bitmap = Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888)
        val bmCanvas1 = Canvas(bm1)
        svg.renderViewToCanvas("test", bmCanvas1)

        val ops: List<String?> = bmCanvas1.asShadow().getOperations()
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("concat(Matrix(4 0 0 4 -100 -100))", ops[1])
    }


    @Test
    @Throws(SVGParseException::class)
    fun renderViewToCanvasViewPort() {
        val test = "<svg viewBox=\"0 0 100 100\">\n" +
                "  <view id=\"test\" viewBox=\"25 25 50 50\"/>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm1: Bitmap = Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888)
        val bmCanvas1 = Canvas(bm1)
        svg.renderViewToCanvas("test", bmCanvas1, RectF(100f, 100f, 200f, 200f))

        val ops: List<String?> = bmCanvas1.asShadow().getOperations()
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("concat(Matrix(2 0 0 2 50 50))", ops[1])
    }


    //--------------------------------------------------------------------------
    @Test
    @Throws(SVGParseException::class)
    fun renderToCanvasWithViewPortRO() {
        val test = "<svg viewBox=\"0 0 200 100\">\n" +
                "  <rect width=\"200\" height=\"100\" fill=\"green\"/>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm2: Bitmap = Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888)
        val bmCanvas2 = Canvas(bm2)

        val opts: RenderOptions = RenderOptions.create().viewPort(100f, 100f, 100f, 50f)
        svg.renderToCanvas(bmCanvas2, opts)

        val ops: List<String?> = bmCanvas2.asShadow().getOperations()
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("concat(Matrix(0.5 0 0 0.5 100 100))", ops[1])
        assertEquals(
            "drawPath('M 0 0 L 200 0 L 200 100 L 0 100 L 0 0 Z', Paint(color:#ff008000; f:ANTI_ALIAS|LINEAR_TEXT|SUBPIXEL_TEXT; h:OFF; ls:0; s:FILL; tf:android.graphics.Typeface@0; ts:16))",
            ops[3]
        )
    }


    @Test
    @Throws(SVGParseException::class)
    fun renderToCanvasRO() {
        val test = "<svg>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm2: Bitmap = Bitmap.createBitmap(200, 300, Bitmap.Config.ARGB_8888)
        val bmCanvas2 = Canvas(bm2)

        // Step 1
        var opts: RenderOptions = RenderOptions.create()
        opts.viewPort(0f, 0f, 200f, 300f)
            .viewBox(0f, 0f, 100f, 50f)

        svg.renderToCanvas(bmCanvas2, opts)

        val mock: MockCanvas = bmCanvas2.asShadow()
        val ops: List<String> = mock.getOperations()
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("concat(Matrix(2 0 0 2 0 100))", ops[1])

        // Step 2
        mock.clearOperations()

        opts = RenderOptions.create()
        opts.viewPort(0f, 0f, 200f, 300f)
            .viewBox(0f, 0f, 100f, 50f)
            .preserveAspectRatio(PreserveAspectRatio.of("xMinYMax meet"))

        svg.renderToCanvas(bmCanvas2, opts)

        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("concat(Matrix(2 0 0 2 0 200))", ops[1])

        // Step 3
        mock.clearOperations()

        opts = RenderOptions.create()
        opts.viewPort(0f, 0f, 200f, 300f)
            .viewBox(0f, 0f, 100f, 50f)
            .preserveAspectRatio(PreserveAspectRatio.of("none"))

        svg.renderToCanvas(bmCanvas2, opts)

        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("concat(Matrix(2 0 0 6 0 0))", ops[1])
    }
}
