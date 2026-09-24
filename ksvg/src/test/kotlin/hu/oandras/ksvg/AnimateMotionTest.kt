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
import hu.oandras.ksvg.mocks.MockPathMeasure
import hu.oandras.ksvg.mocks.asShadow
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, shadows = [MockCanvas::class, MockPath::class, MockPaint::class, MockPathMeasure::class])
class AnimateMotionTest {

    @Test
    fun renderAppliesAnimateMotionWithPathAttribute() {
        val svg = SVG.getFromString(
            svg = """
                    <svg width="20" height="20" viewBox="0 0 20 20">
                      <rect width="2" height="2">
                        <animateMotion path="M 0 0 L 10 0" dur="1s" fill="freeze"/>
                      </rect>
                    </svg>
                    """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(20, 20)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        // Path is 10 units long. At 500ms (progress 0.5), it should be at (5, 0).
        assertTrue("Expected translation to (5,0), but got: $operations", operations.contains("concat(Matrix(1 0 0 1 5 0))"))
    }

    @Test
    fun renderAppliesAnimateMotionWithMPath() {
        val svg = SVG.getFromString(
            svg = """
                    <svg width="20" height="20" viewBox="0 0 20 20">
                      <path id="motionPath" d="M 0 0 L 0 10"/>
                      <rect width="2" height="2">
                        <animateMotion dur="1s" fill="freeze">
                          <mpath href="#motionPath"/>
                        </animateMotion>
                      </rect>
                    </svg>
                    """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(20, 20)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        // Path is 10 units long vertically. At 500ms (progress 0.5), it should be at (0, 5).
        assertTrue("Expected translation to (0,5), but got: $operations", operations.contains("concat(Matrix(1 0 0 1 0 5))"))
    }

    @Test
    fun renderAppliesAnimateMotionWithRotateAuto() {
         val svg = SVG.getFromString(
            svg = """
                    <svg width="20" height="20" viewBox="0 0 20 20">
                      <rect width="2" height="2">
                        <animateMotion path="M 0 0 L 10 10" dur="1s" rotate="auto" fill="freeze"/>
                      </rect>
                    </svg>
                    """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(20, 20)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        // Path is diagonal from (0,0) to (10,10). Angle is 45 degrees.
        // At 500ms, it should be at (5, 5) with 45 degree rotation.
        assertTrue("Expected rotation and translation at (5,5), but got: $operations", 
            operations.any { it.startsWith("concat(Matrix(") && it.contains(" 5 5))") && !it.contains(" 1 0 0 1 5 5") })
    }

    @Test
    fun renderAppliesAnimateMotionWithMultiSegmentPath() {
        val svg = SVG.getFromString(
            svg = """
                    <svg width="20" height="20" viewBox="0 0 20 20">
                      <rect width="2" height="2">
                        <animateMotion path="M 0 0 L 10 0 L 10 10" dur="2s" fill="freeze"/>
                      </rect>
                    </svg>
                    """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        
        // At 1.5s, progress is 0.75. Total length is 20. Distance is 15.
        // It should be halfway through the second segment (10, 0) to (10, 10).
        // So at (10, 5).
        svg.animationTimeMs = 1500L

        val bitmap = createBitmap(20, 20)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue("Expected translation to (10,5), but got: $operations", operations.contains("concat(Matrix(1 0 0 1 10 5))"))
    }

    @Test
    fun renderAppliesAnimateMotionAccumulateFreeze() {
        val svg = SVG.getFromString(
            svg = """
                    <svg width="40" height="20" viewBox="0 0 40 20">
                      <rect width="2" height="2">
                        <animateMotion path="M 0 0 L 10 0" dur="1s" repeatCount="2" accumulate="sum" fill="freeze"/>
                      </rect>
                    </svg>
                    """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        // Frozen past the active end: end point (10,0) + one completed range.
        svg.animationTimeMs = 5000L

        val bitmap = createBitmap(40, 20)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue("Expected translation to (20,0), but got: $operations", operations.contains("concat(Matrix(1 0 0 1 20 0))"))
    }

    @Test
    fun renderAppliesAnimateMotionKeyPointsWithoutKeyTimesIgnored() {
        val svg = SVG.getFromString(
            svg = """
                    <svg width="20" height="20" viewBox="0 0 20 20">
                      <rect width="2" height="2">
                        <animateMotion path="M 0 0 L 10 0" dur="1s" keyPoints="0;0.2" fill="freeze"/>
                      </rect>
                    </svg>
                    """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        // Per SMIL, keyPoints without keyTimes are ignored: linear progress.
        svg.animationTimeMs = 500L

        val bitmap = createBitmap(20, 20)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        assertTrue("Expected translation to (5,0), but got: $operations", operations.contains("concat(Matrix(1 0 0 1 5 0))"))
    }

    @Test
    fun renderAppliesAnimateMotionWithKeyPoints() {
        val svg = SVG.getFromString(
            svg = """
                    <svg width="20" height="20" viewBox="0 0 20 20">
                      <rect width="2" height="2">
                        <animateMotion path="M 0 0 L 10 0" dur="1s" keyPoints="0;0.2" keyTimes="0;1" fill="freeze"/>
                      </rect>
                    </svg>
                    """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl
        svg.animationTimeMs = 500L // progress 0.5. effectiveProgress = 0.1.

        val bitmap = createBitmap(20, 20)
        val canvas = Canvas(bitmap)
        svg.renderToCanvas(canvas)

        val operations = canvas.asShadow().getOperations()
        // 10 * 0.1 = 1.
        assertTrue("Expected translation to (1,0), but got: $operations", operations.contains("concat(Matrix(1 0 0 1 1 0))"))
    }
}
