/*
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

import android.graphics.Canvas
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.mocks.MockCanvas
import hu.oandras.ksvg.mocks.MockPaint
import hu.oandras.ksvg.mocks.MockPath
import hu.oandras.ksvg.mocks.asShadow
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class])
class AnimationTest {

    @Test
    fun renderSetElement_color() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" fill="red">
                    <set attributeName="fill" to="blue" dur="1s"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 0L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderSetElement_color_afterBegin() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" fill="red">
                    <set attributeName="fill" to="blue" dur="1s"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun pointsAnimation_morphsPolyline() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="100" viewBox="0 0 200 100">
                  <polyline points="10,90 60,10 110,90 160,10 190,90" fill="yellow" stroke="blue" stroke-width="2">
                    <animate attributeName="points" dur="3s" repeatCount="indefinite"
                      values="10,90 60,10 110,90 160,10 190,90; 10,10 60,90 110,10 160,90 190,10; 10,90 60,10 110,90 160,10 190,90; 10,10 60,90 110,10 160,90 190,10; 10,90 60,10 110,90 160,10 190,90"/>
                  </polyline>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl

        fun polylinePathDescAt(t: Long): String {
            svg.animationTimeMs = t
            val bitmap = createBitmap(200, 100)
            val canvas = Canvas(bitmap)
            svg.renderToCanvas(canvas)
            return canvas.asShadow().getOperations()
                .first { it.startsWith("drawPath") && it.contains("L 60") }
                .substringAfter("drawPath('")
                .substringBefore("', ")
        }

        val at0 = polylinePathDescAt(0L)
        assertTrue("expected base peak (60,10) at t=0, got: $at0", at0.contains("L 60 10"))

        val at750 = polylinePathDescAt(750L)
        assertTrue("expected inverted peak (60,90) at t=750, got: $at750", at750.contains("L 60 90"))
    }

    @Test
    fun roundedRect_insideA_isRounded() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
                  <a href="#target">
                    <rect x="20" y="20" width="160" height="80" fill="steelblue" rx="10"/>
                  </a>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 0L
        val bitmap = createBitmap(200, 200)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val ops = canvas.asShadow().getOperations()
        assertTrue("expected a rounded rect (RR rx=10) for rect with only rx set, ops: $ops", ops.any { it.contains("RR 20 20 180 100 10 10") })
    }

    @Test
    fun renderSetElement_float() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" stroke="black" stroke-width="2">
                    <set attributeName="stroke-width" to="10" dur="1s"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderAnimateColorElement() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" fill="red">
                    <animateColor attributeName="fill" from="red" to="blue" dur="1s" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderAnimateColorElement_withValues() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" fill="red">
                    <animateColor attributeName="fill" values="red;blue;green" dur="2s" repeatCount="indefinite"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 0L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderDiscreteCalcMode_color() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" fill="red">
                    <animate attributeName="fill" values="red;blue;green" dur="2s" calcMode="discrete" repeatCount="indefinite"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 0L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderDiscreteCalcMode_float() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" fill="red">
                    <animate attributeName="opacity" values="0;0.5;1" dur="2s" calcMode="discrete" repeatCount="indefinite"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 0L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderPacedCalcMode_float() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" fill="red">
                    <animate attributeName="opacity" values="0;1;0.5" dur="2s" calcMode="paced" repeatCount="indefinite"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 1000L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderPacedCalcMode_color() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" fill="red">
                    <animate attributeName="fill" values="red;blue;green" dur="3s" calcMode="paced" repeatCount="indefinite"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 1000L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderSplineCalcMode_float() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" fill="red">
                    <animate attributeName="opacity" from="0" to="1" dur="1s" calcMode="spline" keySplines="0.5 0 0.5 1" keyTimes="0;1" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderSplineCalcMode_color() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" fill="red">
                    <animate attributeName="fill" from="red" to="blue" dur="1s" calcMode="spline" keySplines="0.5 0 0.5 1" keyTimes="0;1" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderColorAttribute_animation() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" color="red" fill="currentColor">
                    <animate attributeName="color" from="red" to="blue" dur="1s" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderFloatAnimation_strokeWidth() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" stroke="black" stroke-width="2">
                    <animate attributeName="stroke-width" from="2" to="10" dur="1s" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderMultiAttributeAnimation() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" stroke="red" stroke-width="2">
                    <animate attributeName="stroke-width" from="2" to="8" dur="1s" fill="freeze"/>
                    <animate attributeName="stroke-opacity" from="0.3" to="1.0" dur="1s" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderTransformDiscreteCalcMode() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="200" viewBox="0 0 200 200">
                  <rect x="50" y="50" width="100" height="100" fill="red">
                    <animateTransform attributeName="translate" values="0,0;50,50;100,0" dur="2s" calcMode="discrete" repeatCount="indefinite"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(200, 200)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderTransformPacedCalcMode() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="200" viewBox="0 0 200 200">
                  <rect x="50" y="50" width="100" height="100" fill="red">
                    <animateTransform attributeName="translate" values="0,0;100,0;50,100" dur="3s" calcMode="paced" repeatCount="indefinite"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 1000L

        val bitmap = createBitmap(200, 200)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderTransformSplineCalcMode() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="200" viewBox="0 0 200 200">
                  <rect x="50" y="50" width="100" height="100" fill="red">
                    <animateTransform attributeName="translate" from="0,0" to="100,100" dur="1s" calcMode="spline" keySplines="0.5 0 0.5 1" keyTimes="0;1" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(200, 200)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderAnimateColorBy() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" fill="rgb(50,50,50)">
                    <animate attributeName="fill" from="rgb(50,50,50)" by="rgb(100,100,100)" dur="1s" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }

    @Test
    fun renderNumericRepeatCount() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" fill="red">
                    <animate attributeName="opacity" from="0" to="1" dur="1s" repeatCount="2" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl

        svg.animationTimeMs = 500L
        val bitmap1 = createBitmap(200, 50)
        val canvas1 = Canvas(bitmap1)
        svg.renderToCanvas(canvas1)
        val ops1 = canvas1.asShadow().getOperations()
        assertTrue(ops1.isNotEmpty())

        svg.animationTimeMs = 1500L
        val bitmap2 = createBitmap(200, 50)
        val canvas2 = Canvas(bitmap2)
        svg.renderToCanvas(canvas2)
        val ops2 = canvas2.asShadow().getOperations()
        assertTrue(ops2.isNotEmpty())

        svg.animationTimeMs = 2500L
        val bitmap3 = createBitmap(200, 50)
        val canvas3 = Canvas(bitmap3)
        svg.renderToCanvas(canvas3)
        val ops3 = canvas3.asShadow().getOperations()
        assertTrue(ops3.isNotEmpty())
    }

    @Test
    fun renderLightingColorAttribute() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="200" height="50" viewBox="0 0 200 50">
                  <rect x="10" y="10" width="180" height="30" fill="red">
                    <animate attributeName="lighting-color" from="white" to="gold" dur="1s" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(200, 50)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue(operations.isNotEmpty())
    }
}
