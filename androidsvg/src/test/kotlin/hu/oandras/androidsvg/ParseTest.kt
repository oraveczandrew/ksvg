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
import android.graphics.Path
import android.os.Build
import hu.oandras.androidsvg.dom.SVGImpl
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
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
class ParseTest {
    @Test
    @Throws(SVGParseException::class)
    fun emptySVG() {
        // XmlPullParser
        val test = "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                "</svg>"
        val svg: SVGImpl = SVGImpl.getFromString(test)
        assertNotNull(svg.rootElement)
    }

    @Test
    @Throws(SVGParseException::class)
    fun emptySVGEntitiesEnabled() {
        // NOTE: Is *really* slow when running under JUnit (15-20secs).
        // However, the speed seems to be okay under normal usage (a real app).
        val test =
            "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.0//EN\" \"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd\" [" +
                    "  <!ENTITY hello \"Hello World!\">" +
                    "]>" +
                    "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                    "</svg>"
        val svg: SVGImpl = SVGImpl.getFromString(test)
        assertNotNull(svg.rootElement)
    }

    @Test
    @Throws(SVGParseException::class)
    fun emptySVGEntitiesDisabled() {
        val test =
            "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.0//EN\" \"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd\" [" +
                    "  <!ENTITY hello \"Hello World!\">" +
                    "]>" +
                    "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                    "</svg>"
        SVG.setInternalEntitiesEnabled(false)
        val svg: SVGImpl = SVGImpl.getFromString(test)
        assertNotNull(svg.rootElement)
    }

    @Test(expected = SVGParseException::class)
    @Throws(SVGParseException::class)
    fun unbalancedClose() {
        val test = "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                "</svg>" +
                "</svg>"
        val _: SVG = SVG.getFromString(test)
    }


    @Test
    fun parsePath() {
        var test = "M100,200 C100,100 250,100 250,200 S400,300 400,200"
        var path: Path = SVG.parsePath(test)
        assertEquals(
            "M 100 200 C 100 100 250 100 250 200 C 250 300 400 300 400 200",
            path.asShadow().pathDescription
        )

        // The arcs in a path get converted to cubic Béziers
        test = "M-100 0 A 100 100 0 0 0 0,100"
        path = SVG.parsePath(test)
        assertEquals(
            "M -100 0 C -100 55.22848 -55.22848 100 0 100",
            path.asShadow().pathDescription
        )

        // Path with errors
        test = "M 0 0 L 100 100 C 200 200 Z"
        path = SVG.parsePath(test)
        assertEquals("M 0 0 L 100 100", path.asShadow().pathDescription)
    }


    /*
   @Test
   public void issue177() throws SVGParseException
   {
      String  test = "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                     "  <defs></defs>" +
                     "  <g></g>" +
                     "  <a></a>" +
                     "  <use></use>" +
                     "  <image></image>" +
                     "  <text>" +
                     "    <tspan></tspan>" +
                     "    <textPath></textPath>" +
                     "  </text>" +
                     "  <switch></switch>" +
                     "  <symbol></symbol>" +
                     "  <marker></marker>" +
                     "  <linearGradient>" +
                     "    <stop></stop>" +
                     "  </linearGradient>" +
                     "  <radialGradient></radialGradient>" +
                     "  <clipPath></clipPath>" +
                     "  <pattern></pattern>" +
                     "  <view></view>" +
                     "  <mask></mask>" +
                     "  <solidColor></solidColor>" +
                     "  <g>" +
                     "    <path>" +
                     "      <style media=\"print\">" +
                     "      </style>" +
                     "    </path>" +
                     "  </g>" +
                     "</svg>";

      try {
         SVG  svg = SVG.getFromString(test);
         fail("Should have thrown ParseException");
      } catch (SVGParseException e) {
         // passed!
      }
   }
*/
    /*
    * Checks that A elements are parsed and rendered correctly.
    * @throws SVGParseException
    */
    @Test
    @Throws(SVGParseException::class)
    fun parseA() {
        val test = "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                "<a>" +
                "  <rect width=\"10\" height=\"10\" fill=\"red\"/>" +
                "</a>" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm: Bitmap = Bitmap.createBitmap(10, 10, Bitmap.Config.ARGB_8888)
        val bmCanvas = Canvas(bm)

        // Test that A element has been inserted in the DOM tree correctly
        val opts: RenderOptions = RenderOptions.create()
        opts.css("a rect { fill: green; }")

        svg.renderToCanvas(bmCanvas, opts)

        val mock: MockCanvas = bmCanvas.asShadow()
        val ops: List<String> = mock.getOperations()
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(
            "drawPath('M 0 0 L 10 0 L 10 10 L 0 10 L 0 0 Z', Paint(color:#ff008000; f:ANTI_ALIAS|LINEAR_TEXT|SUBPIXEL_TEXT; h:OFF; s:FILL; tf:android.graphics.Typeface@0; ts:16))",
            ops[4]
        )
    }


    @Test
    @Throws(SVGParseException::class)
    fun parseB() {
        // Test that A elements are being visited properly while rendering
        val test = "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                "<a fill=\"green\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "</a>" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm: Bitmap = Bitmap.createBitmap(10, 10, Bitmap.Config.ARGB_8888)
        val bmCanvas = Canvas(bm)

        svg.renderToCanvas(bmCanvas)

        val mock: MockCanvas = bmCanvas.asShadow()
        val ops: List<String> = mock.getOperations()
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(
            "drawPath('M 0 0 L 10 0 L 10 10 L 0 10 L 0 0 Z', Paint(color:#ff008000; f:ANTI_ALIAS|LINEAR_TEXT|SUBPIXEL_TEXT; h:OFF; s:FILL; tf:android.graphics.Typeface@0; ts:16))",
            ops[4]
        )
    }


    /**
     * Issue 186
     * CSS properties without a value are badly parsed.
     */
    @Test
    @Throws(SVGParseException::class)
    fun issue186() {
        val test = "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                "<text style=\"text-decoration:;fill:green\">Test</text>" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm: Bitmap = Bitmap.createBitmap(10, 10, Bitmap.Config.ARGB_8888)
        val bmCanvas = Canvas(bm)

        svg.renderToCanvas(bmCanvas)

        val mock: MockCanvas = bmCanvas.asShadow()
        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff008000", mock.paintProp(3, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun parseStyleLeadingColon() {
        val test = "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                "<text style=\"fill:green;:fill:red\">Test</text>" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val bm: Bitmap = Bitmap.createBitmap(10, 10, Bitmap.Config.ARGB_8888)
        val bmCanvas = Canvas(bm)

        svg.renderToCanvas(bmCanvas)

        val mock: MockCanvas = bmCanvas.asShadow()
        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff008000", mock.paintProp(3, "color"))
    }


    /**
     * Issue 199
     * Semi-thread safe parsing properties (enableInternalEntities and externalFileResolver)
     */
    @Test
    @Throws(SVGParseException::class)
    fun issue199() {
        val test = "<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>"

        val svg: SVG = SVG.getFromString(test)
        assertTrue(svg.isInternalEntitiesEnabled)
        assertNull(svg.externalFileResolver)

        SVG.setInternalEntitiesEnabled(false)
        val resolver: SVGExternalFileResolver = TestAssetResolver()
        SVG.registerExternalFileResolver(resolver)

        val svg2: SVG = SVG.getFromString(test)
        assertFalse(svg2.isInternalEntitiesEnabled)
        assertEquals(resolver, svg2.externalFileResolver)

        // Ensure settings for "svg" haven't changed
        assertTrue(svg.isInternalEntitiesEnabled)
        assertNull(svg.externalFileResolver)
    }

    private class TestAssetResolver: SVGExternalFileResolver()
}
