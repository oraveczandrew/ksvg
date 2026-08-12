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
import hu.oandras.ksvg.utils.ceilToInt
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class CssPseudoClassesTest {
    @Test
    @Throws(SVGParseException::class)
    fun firstChild() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <style>" +
                "    rect:first-child { fill: #0f0; }" +
                "  </style>" +
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
        val ops: MutableList<String> = mock.getOperations()

        println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
        assertEquals("#ff000000", mock.paintProp(6, "color"))

        ops.clear()

        // ":first-child" by itself should match everything (matches <svg>, which affects all children)
        renderOptions.css(":first-child { fill: #00f; }")
        svg.renderToCanvas(canvas, renderOptions)

        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(
            "#ff00ff00",
            mock.paintProp(3, "color")
        ) // Still green because it is more specific
        assertEquals("#ff0000ff", mock.paintProp(6, "color")) // Should now be blue
    }


    @Test
    @Throws(SVGParseException::class)
    fun lastChild() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <style>" +
                "    rect:last-child { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun root() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <style>" +
                "    :root rect:last-child { fill: #0f0; }" +
                "    rect:root { fill: #f00; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun firstOfType() {
        //disableLogging();
        var test = "<svg width=\"100\" height=\"100\">" +
                "  <circle cx=\"10\" cy=\"10\" r=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <style>" +
                "    rect:first-of-type { fill: #0f0; }" +
                "  </style>" +
                "</svg>"
        var svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = Bitmap.createBitmap(
            svg.documentWidth.ceilToInt(),
            svg.documentHeight.ceilToInt(),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(newBM)

        val renderOptions: RenderOptions = RenderOptions.create().css("")
        svg.renderToCanvas(canvas, renderOptions)

        var mock: MockCanvas = canvas.asShadow()
        val ops: MutableList<String> = mock.getOperations()

        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))

        ops.clear()

        test = "<svg width=\"100\" height=\"100\">" +
                "  <circle cx=\"10\" cy=\"10\" r=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <style>" +
                "    :first-of-type { fill: #0f0; }" +
                "  </style>" +
                "</svg>"
        svg = SVG.getFromString(test)

        svg.renderToCanvas(canvas, renderOptions)

        mock = canvas.asShadow()

        //ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))

        // All the elements will be green because :first-of-type matches the <svg> and all the child elements inherit that green
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff00ff00", mock.paintProp(9, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun lastOfType() {
        //disableLogging();
        var test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <circle cx=\"10\" cy=\"10\" r=\"10\"/>" +
                "  <style>" +
                "    rect:last-of-type { fill: #0f0; }" +
                "  </style>" +
                "</svg>"
        var svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = Bitmap.createBitmap(
            svg.documentWidth.ceilToInt(),
            svg.documentHeight.ceilToInt(),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(newBM)

        val renderOptions: RenderOptions = RenderOptions.create().css("")
        svg.renderToCanvas(canvas, renderOptions)

        var mock: MockCanvas = canvas.asShadow()
        val ops: MutableList<String> = mock.getOperations()

        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))

        // Test tagless version
        ops.clear()

        test = "<svg width=\"100\" height=\"100\">" +
                "  <circle cx=\"10\" cy=\"10\" r=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <style>" +
                "    svg :last-of-type { fill: #0f0; }" +
                "  </style>" +
                "</svg>"
        svg = SVG.getFromString(test)

        svg.renderToCanvas(canvas, renderOptions)

        mock = canvas.asShadow()

        //ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))

        // All the elements will be green because :first-of-type matches the <svg> and all the child elements inherit that green
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
        assertEquals("#ff000000", mock.paintProp(6, "color"))
        assertEquals("#ff00ff00", mock.paintProp(9, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun onlyChild() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <g>" +
                "    <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  </g>" +
                "  <style>" +
                "    rect:only-child { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(7, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun onlyOfType() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <circle cx=\"10\" cy=\"10\" r=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <style>" +
                "    svg :only-of-type { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun empty() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\">" +
                "    <title>Hello</title>" +
                "  </rect>" +
                "  <style>" +
                "    :empty { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
        //assertEquals("#ff000000", mock.paintProp(6, "color"));   TODO uncomment when we support children of graphics elements (e.g. when we have a proper DOM)
        assertEquals(
            "#ff00ff00",
            mock.paintProp(6, "color")
        ) // TODO temporary: remove when above fix happens
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthChildOdd() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <style>" +
                "    rect:nth-child(odd) { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
        assertEquals("#ff000000", mock.paintProp(6, "color"))
        assertEquals("#ff00ff00", mock.paintProp(9, "color"))
        assertEquals("#ff000000", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthChildOddAlt() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <style>" +
                "    rect:nth-child(2n+1) { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
        assertEquals("#ff000000", mock.paintProp(6, "color"))
        assertEquals("#ff00ff00", mock.paintProp(9, "color"))
        assertEquals("#ff000000", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthChildEven() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <style>" +
                "    rect:nth-child(even) { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff00ff00", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthChildEvenAlt() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <style>" +
                "    rect:nth-child(2n) { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff00ff00", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthChild4th() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"40\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"50\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"60\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"70\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"80\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"90\"/>" +
                "  <style>" +
                "    rect:nth-child(5n-1) { fill: #0f0; }" +  // 4th, 9th, 14th etc
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff000000", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff00ff00", mock.paintProp(12, "color"))
        assertEquals("#ff000000", mock.paintProp(15, "color"))
        assertEquals("#ff000000", mock.paintProp(18, "color"))
        assertEquals("#ff000000", mock.paintProp(21, "color"))
        assertEquals("#ff000000", mock.paintProp(24, "color"))
        assertEquals("#ff00ff00", mock.paintProp(27, "color"))
        assertEquals("#ff000000", mock.paintProp(30, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthChild4thAlt() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"40\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"50\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"60\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"70\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"80\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"90\"/>" +
                "  <style>" +
                "    rect:nth-child(5n+4) { fill: #0f0; }" +  // 4th, 9th, 14th etc
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff000000", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff00ff00", mock.paintProp(12, "color"))
        assertEquals("#ff000000", mock.paintProp(15, "color"))
        assertEquals("#ff000000", mock.paintProp(18, "color"))
        assertEquals("#ff000000", mock.paintProp(21, "color"))
        assertEquals("#ff000000", mock.paintProp(24, "color"))
        assertEquals("#ff00ff00", mock.paintProp(27, "color"))
        assertEquals("#ff000000", mock.paintProp(30, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthChildFirst3() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"40\"/>" +
                "  <style>" +
                "    rect:nth-child(-1n+3) { fill: #0f0; }" +  // 1st, 2nd, 3rd
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff00ff00", mock.paintProp(9, "color"))
        assertEquals("#ff000000", mock.paintProp(12, "color"))
        assertEquals("#ff000000", mock.paintProp(15, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthChild2nd() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"40\"/>" +
                "  <style>" +
                "    rect:nth-child(2) { fill: #0f0; }" +  // 2nd
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff000000", mock.paintProp(12, "color"))
        assertEquals("#ff000000", mock.paintProp(15, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthChild2ndAlt() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"40\"/>" +
                "  <style>" +
                "    rect:nth-child( -2n + 2 ) { fill: #0f0; }" +  // 2nd
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff000000", mock.paintProp(12, "color"))
        assertEquals("#ff000000", mock.paintProp(15, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun unsupported() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"40\"/>" +
                "  <style>" +
                "    rect:lang(en) { fill: #0f0; }" +
                "    rect:lang(en, fr) { fill: #0f0; }" +
                "    rect:hover { fill: #0f0; }" +
                "    rect:focus { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff000000", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff000000", mock.paintProp(12, "color"))
        assertEquals("#ff000000", mock.paintProp(15, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthChildMinus4Plus10() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"40\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"50\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"60\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"70\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"80\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"90\"/>" +
                "  <style>" +
                "    rect:nth-child(-4n+10) { fill: #0f0; }" +  // 2nd, 6th, 10th
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff000000", mock.paintProp(12, "color"))
        assertEquals("#ff000000", mock.paintProp(15, "color"))
        assertEquals("#ff00ff00", mock.paintProp(18, "color"))
        assertEquals("#ff000000", mock.paintProp(21, "color"))
        assertEquals("#ff000000", mock.paintProp(24, "color"))
        assertEquals("#ff000000", mock.paintProp(27, "color"))
        assertEquals("#ff00ff00", mock.paintProp(30, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthChildAll() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"40\"/>" +
                "  <style>" +
                "    rect:nth-child(1n+0) { fill: #0f0; }" +  // 2nd
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff00ff00", mock.paintProp(9, "color"))
        assertEquals("#ff00ff00", mock.paintProp(12, "color"))
        assertEquals("#ff00ff00", mock.paintProp(15, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthChildAllAlt1() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"40\"/>" +
                "  <style>" +
                "    rect:nth-child(n+0) { fill: #0f0; }" +  // 2nd
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff00ff00", mock.paintProp(9, "color"))
        assertEquals("#ff00ff00", mock.paintProp(12, "color"))
        assertEquals("#ff00ff00", mock.paintProp(15, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthChildAllAlt2() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"40\"/>" +
                "  <style>" +
                "    rect:nth-child(n) { fill: #0f0; }" +  // 2nd
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff00ff00", mock.paintProp(9, "color"))
        assertEquals("#ff00ff00", mock.paintProp(12, "color"))
        assertEquals("#ff00ff00", mock.paintProp(15, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthOfTypeOdd() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <circle cx=\"10\" cy=\"10\" r=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <style>" +
                "    svg :nth-of-type(odd) { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff00ff00", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthOfTypeEven() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <circle cx=\"10\" cy=\"10\" r=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <style>" +
                "    svg :nth-of-type(even) { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff000000", mock.paintProp(6, "color"))
        assertEquals("#ff00ff00", mock.paintProp(9, "color"))
        assertEquals("#ff000000", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthLastChildOdd() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <circle cx=\"30\" cy=\"10\" r=\"10\"/>" +
                "  <style>" +
                "    svg :nth-last-child(odd) { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff00ff00", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthLastChildEven() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <circle cx=\"30\" cy=\"10\" r=\"10\"/>" +
                "  <style>" +
                "    svg :nth-last-child(even) { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
        assertEquals("#ff000000", mock.paintProp(6, "color"))
        assertEquals("#ff00ff00", mock.paintProp(9, "color"))
        assertEquals("#ff000000", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthLastOfTypeOdd() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <circle cx=\"30\" cy=\"10\" r=\"10\"/>" +
                "  <style>" +
                "    svg :nth-last-of-type(odd) { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff00ff00", mock.paintProp(3, "color"))
        assertEquals("#ff000000", mock.paintProp(6, "color"))
        assertEquals("#ff00ff00", mock.paintProp(9, "color"))
        assertEquals("#ff00ff00", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun nthLastOfTypeEven() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect width=\"10\" height=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <circle cx=\"30\" cy=\"10\" r=\"10\"/>" +
                "  <style>" +
                "    svg :nth-last-of-type(even) { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff000000", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun not() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <circle cx=\"10\" cy=\"10\" r=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\" class=\"skip\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <style>" +
                "    rect:not(.skip) { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff00ff00", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun not2() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <circle cx=\"10\" cy=\"10\" r=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\" class=\"skip\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <style>" +
                "    rect:not(.skip, :last-of-type) { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff000000", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun not3() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <circle cx=\"10\" cy=\"10\" r=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\" class=\"skip\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <style>" +
                "    rect:not(.skip):not(:last-of-type) { fill: #0f0; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff000000", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun notNotInNot() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <circle cx=\"10\" cy=\"10\" r=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"20\" class=\"skip\"/>" +
                "  <rect width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <style>" +
                "    rect:last-of-type { fill: #0f0; }" +
                "    rect:not(:not(:last-of-type)) { fill: #f00; }" +
                "  </style>" +
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

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff000000", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff00ff00", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun idSelect() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect id=\"one\" width=\"10\" height=\"10\"/>" +
                "  <rect id=\"two\" width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect id=\"three\" width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect id=\"four\" width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <style>" +
                "    #one { fill: #f00; }" +
                "    #two { fill: #ff0; }" +
                "    #three { fill: #0f0; }" +
                "    #four { fill: #00f; }" +
                "  </style>" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = Bitmap.createBitmap(
            svg.documentWidth.ceilToInt(),
            svg.documentHeight.ceilToInt(),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(newBM)

        val renderOptions: RenderOptions =
            RenderOptions.create().css("svg :not(#three) { display: none; }")
        svg.renderToCanvas(canvas, renderOptions)

        val mock: MockCanvas = canvas.asShadow()
        val ops: List<String> = mock.getOperations()

        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(12, ops.size)
        assertEquals("#ff00ff00", mock.paintProp(7, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun target() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect id=\"one\" width=\"10\" height=\"10\"/>" +
                "  <rect id=\"two\" width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect id=\"three\" width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect id=\"four\" width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <style>" +
                "    :target { fill: #0f0; }" +
                "    circle:target { fill: #f00; }" +
                "  </style>" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = Bitmap.createBitmap(
            svg.documentWidth.ceilToInt(),
            svg.documentHeight.ceilToInt(),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(newBM)

        val renderOptions: RenderOptions = RenderOptions.create().target("two")
        svg.renderToCanvas(canvas, renderOptions)

        val mock: MockCanvas = canvas.asShadow()

        //List<String>  ops = mock.getOperations();
        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals("#ff000000", mock.paintProp(3, "color"))
        assertEquals("#ff00ff00", mock.paintProp(6, "color"))
        assertEquals("#ff000000", mock.paintProp(9, "color"))
        assertEquals("#ff000000", mock.paintProp(12, "color"))
    }


    @Test
    @Throws(SVGParseException::class)
    fun idTargetSelect() {
        //disableLogging();
        val test = "<svg width=\"100\" height=\"100\">" +
                "  <rect id=\"one\" width=\"10\" height=\"10\"/>" +
                "  <rect id=\"two\" width=\"10\" height=\"10\" x=\"10\"/>" +
                "  <rect id=\"three\" width=\"10\" height=\"10\" x=\"20\"/>" +
                "  <rect id=\"four\" width=\"10\" height=\"10\" x=\"30\"/>" +
                "  <style>" +
                "    #one { fill: #f00; }" +
                "    #two { fill: #ff0; }" +
                "    #three { fill: #0f0; }" +
                "    #four { fill: #00f; }" +
                "  </style>" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val newBM: Bitmap = Bitmap.createBitmap(
            svg.documentWidth.ceilToInt(),
            svg.documentHeight.ceilToInt(),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(newBM)

        val renderOptions: RenderOptions =
            RenderOptions.create().css("svg :not(:target) { display: none; }")

        renderOptions.target("two")
        svg.renderToCanvas(canvas, renderOptions)

        var mock: MockCanvas = canvas.asShadow()
        var ops: MutableList<String> = mock.getOperations()

        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(12, ops.size)
        assertEquals("#ffffff00", mock.paintProp(5, "color"))

        ops.clear()

        renderOptions.target("four")
        svg.renderToCanvas(canvas, renderOptions)

        mock = canvas.asShadow()
        ops = mock.getOperations()

        //println("DEBUG OPS: " + ops.joinToString(", "))
        assertEquals(12, ops.size)
        assertEquals("#ff0000ff", mock.paintProp(9, "color"))
    }
}
