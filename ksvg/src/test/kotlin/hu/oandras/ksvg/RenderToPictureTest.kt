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

import android.graphics.Picture
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(
    manifest = Config.NONE,
    shadows = [MockCanvas::class, MockPath::class, MockPicture::class, MockPaint::class]
)
class RenderToPictureTest {
    @Test
    @Throws(SVGParseException::class)
    fun renderToPicture() {
        val test = "<svg viewBox=\"0 0 200 100\">\n" +
                "  <rect width=\"200\" height=\"100\" fill=\"green\"/>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val picture: Picture = svg.renderToPicture()

        val ops: List<String?> = picture.asShadow().operations
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(512, picture.getWidth())
        assertEquals(512, picture.getHeight())
        assertEquals("concat(Matrix(2.56 0 0 2.56 0 128))", ops[1])
        assertEquals(
            "drawPath('M 0 0 L 200 0 L 200 100 L 0 100 L 0 0 Z', Paint(color:#ff008000; f:ANTI_ALIAS|LINEAR_TEXT|SUBPIXEL_TEXT; h:OFF; ls:0; s:FILL; tf:android.graphics.Typeface@0; ts:16))",
            ops[3]
        )
    }


    @Test
    @Throws(SVGParseException::class)
    fun renderToPictureIntrinsic() {
        // Calc height of picture given only width
        var test = "<svg width=\"400\" viewBox=\"0 0 200 100\">\n" +
                "</svg>"
        var svg: SVG = SVG.getFromString(test)

        var picture: Picture = svg.renderToPicture()

        var ops: List<String?> = picture.asShadow().operations
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(400, picture.getWidth())
        assertEquals(200, picture.getHeight())
        assertEquals("concat(Matrix(2 0 0 2 0 0))", ops[1])

        // Calc width of picture given only height
        test = "<svg height=\"400\" viewBox=\"0 0 200 100\">\n" +
                "</svg>"
        svg = SVG.getFromString(test)

        picture = svg.renderToPicture()

        ops = picture.asShadow().operations
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(800, picture.getWidth())
        assertEquals(400, picture.getHeight())
        assertEquals("concat(Matrix(4 0 0 4 0 0))", ops[1])
    }


    @Test
    @Throws(SVGParseException::class)
    fun renderToPictureWithDims() {
        val test = "<svg viewBox=\"0 0 200 100\">\n" +
                "  <rect width=\"200\" height=\"100\" fill=\"green\"/>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val picture: Picture = svg.renderToPicture(400, 400)

        val ops: List<String?> = picture.asShadow().operations
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(400, picture.getWidth())
        assertEquals(400, picture.getHeight())
        assertEquals("concat(Matrix(2 0 0 2 0 100))", ops[1])
        assertEquals(
            "drawPath('M 0 0 L 200 0 L 200 100 L 0 100 L 0 0 Z', Paint(color:#ff008000; f:ANTI_ALIAS|LINEAR_TEXT|SUBPIXEL_TEXT; h:OFF; ls:0; s:FILL; tf:android.graphics.Typeface@0; ts:16))",
            ops[3]
        )
    }


    //--------------------------------------------------------------------------
    @Test
    @Throws(SVGParseException::class)
    fun renderViewToPicture() {
        val test = "<svg viewBox=\"0 0 100 100\">\n" +
                "  <view id=\"test\" viewBox=\"25 25 50 50\"/>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val picture: Picture = svg.renderViewToPicture("test", 200, 300)

        val ops: List<String?> = picture.asShadow().operations
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("concat(Matrix(4 0 0 4 -100 -50))", ops[1])
    }


    //--------------------------------------------------------------------------
    @Test
    @Throws(SVGParseException::class)
    fun renderToPictureWithDimsRO() {
        val test = "<svg viewBox=\"0 0 200 100\">\n" +
                "  <rect width=\"200\" height=\"100\" fill=\"green\"/>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val opts: RenderOptions = RenderOptions.create().viewPort(100f, 100f, 200f, 300f)
        val picture: Picture = svg.renderToPicture(400, 400, opts)

        val ops: List<String?> = picture.asShadow().operations
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(400, picture.getWidth())
        assertEquals(400, picture.getHeight())
        assertEquals("concat(Matrix(1 0 0 1 100 200))", ops[1])
        assertEquals(
            "drawPath('M 0 0 L 200 0 L 200 100 L 0 100 L 0 0 Z', Paint(color:#ff008000; f:ANTI_ALIAS|LINEAR_TEXT|SUBPIXEL_TEXT; h:OFF; ls:0; s:FILL; tf:android.graphics.Typeface@0; ts:16))",
            ops[3]
        )
    }


    @Test
    @Throws(SVGParseException::class)
    fun renderToPictureRO() {
        val test = "<svg>\n" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        // Step 1
        var opts: RenderOptions = RenderOptions.create()
        opts.viewPort(0f, 0f, 200f, 300f)
            .viewBox(0f, 0f, 100f, 50f)

        var picture: Picture = svg.renderToPicture(opts)

        var mock: MockPicture = picture.asShadow()
        var ops: List<String?> = mock.operations
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("concat(Matrix(2 0 0 2 0 100))", ops[1])

        // Step 2
        opts = RenderOptions.create()
        opts.viewPort(0f, 0f, 200f, 300f)
            .viewBox(0f, 0f, 100f, 50f)
            .preserveAspectRatio(PreserveAspectRatio.of("xMinYMax meet"))

        picture = svg.renderToPicture(opts)

        mock = picture.asShadow()
        ops = mock.operations
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("concat(Matrix(2 0 0 2 0 200))", ops[1])

        // Step 3
        opts = RenderOptions.create()
        opts.viewPort(0f, 0f, 200f, 300f)
            .viewBox(0f, 0f, 100f, 50f)
            .preserveAspectRatio(PreserveAspectRatio.of("none"))

        picture = svg.renderToPicture(opts)

        mock = picture.asShadow()
        ops = mock.operations
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("concat(Matrix(2 0 0 6 0 0))", ops[1])
    }
}
