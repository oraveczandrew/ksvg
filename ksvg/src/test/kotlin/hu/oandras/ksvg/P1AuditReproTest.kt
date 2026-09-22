/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
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
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.blue
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * Regression tests for audit P1 findings (tmp/AUDIT_FINDINGS.md).
 *
 * Covers: SMIL to-only/by-only float animation (base-relative resolution),
 * unknown calcMode fallback, dur="indefinite", case-insensitive !important.
 * Raster assertions use NATIVE graphics + pixel reads (per AGENTS.md).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class P1AuditReproTest {

    private fun drawAt(svg: SVGImpl, timeMs: Long, size: Int = 100): Int {
        val drawable = KSVGDrawable(svg)
        val bitmap = createBitmap(size, size)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        svg.animationTimeMs = timeMs
        drawable.draw(canvas)
        return bitmap.getPixel(size / 2, size / 2)
    }

    @Test
    fun toOnlyOpacityAnimatesBaseToTarget() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <rect width="100" height="100" fill="red" opacity="0.8">
                    <animate attributeName="opacity" to="0.2" dur="1s" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl

        // SMIL to-animation: base + (to - base) * p.
        // t=0: base 0.8 -> alpha 204.
        assertEquals(204, drawAt(svg, 0L).alpha)
        // t=500ms: 0.8 + (0.2 - 0.8) * 0.5 = 0.5 -> alpha ~127.
        // (Before the fix the animation froze at `to` for the whole duration.)
        val mid = drawAt(svg, 500L).alpha
        assertTrue("expected midpoint near 127, got $mid", mid in 120..135)
        // t=dur (frozen): exactly `to` = 0.2 -> alpha 51.
        assertEquals(51, drawAt(svg, 1000L).alpha)
    }

    @Test
    fun byOnlyOpacityAnimatesBasePlusDelta() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <rect width="100" height="100" fill="red" opacity="0.5">
                    <animate attributeName="opacity" by="0.3" dur="1s" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl

        // SMIL by-animation: base + by * p.
        // t=0: base 0.5 -> alpha ~127.
        // (Before the fix the animation was dropped -> alpha 127 as well, but
        // frozen; the end value distinguishes: 0.8 -> 204 vs dropped 127.)
        val start = drawAt(svg, 0L).alpha
        assertTrue("expected start near 127, got $start", start in 120..135)
        // t=dur (frozen): base 0.5 + 0.3 = 0.8 -> alpha 204.
        assertEquals(204, drawAt(svg, 1000L).alpha)
    }

    @Test
    fun unknownCalcModeFallsBackToLinear() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <rect width="100" height="100" fill="red" opacity="0.0">
                    <animate attributeName="opacity" from="0.0" to="1.0" dur="1s" calcMode="bogus" fill="freeze"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl

        // Must parse (no exception) and behave linearly: midpoint ~127.
        val mid = drawAt(svg, 500L).alpha
        assertTrue("expected linear midpoint near 127, got $mid", mid in 100..155)
        assertEquals(255, drawAt(svg, 1000L).alpha)
    }

    @Test
    fun indefiniteDurKeepsAnimationAlive() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <rect width="100" height="100" fill="red">
                    <animate attributeName="opacity" from="0.0" to="1.0" dur="indefinite"/>
                  </rect>
                </svg>
            """.trimIndent(),
            parseAnimations = true
        ) as SVGImpl

        // Animation active from the start: alpha ~0.
        // (Before the fix dur parsed as 0 -> animation dropped -> alpha 255.)
        assertEquals(0, drawAt(svg, 500L).alpha)
    }

    @Test
    fun uppercaseImportantDoesNotDropRestOfStylesheet() {
        val svg = SVG.getFromString(
            svg = """
                <svg width="100" height="100" viewBox="0 0 100 100">
                  <style>.a { fill: red !IMPORTANT; } .b { fill: blue; }</style>
                  <rect width="100" height="100" class="b"/>
                </svg>
            """.trimIndent()
        ) as SVGImpl

        val drawable = KSVGDrawable(svg)
        val bitmap = createBitmap(100, 100)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, 100, 100)
        drawable.draw(canvas)

        // The .b rule after the !IMPORTANT declaration must still apply.
        // (Before the fix the whole stylesheet was dropped -> black fill.)
        assertEquals(255, bitmap.getPixel(50, 50).blue)
    }
}
