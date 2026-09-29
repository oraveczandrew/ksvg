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

package hu.oandras.ksvg.aihelpers

import android.graphics.Bitmap
import android.graphics.Canvas
import hu.oandras.ksvg.RenderOptions
import hu.oandras.ksvg.SVG
import hu.oandras.ksvg.SlowSoftwareFiltering
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.render.createBitmap
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * Diagnostic probe for the meteocons mask-strip seen on the API-26 emulator
 * (thin line hugging the mask region edge, only mid-pulse): renders the two
 * icons with and without their mask at t=0 and t=1500 (pulse peak), software
 * canvas. A pixel counts as leaked only if it is painted with the mask on
 * but transparent with the mask stripped at BOTH times, so legit pulse
 * motion can never inflate the count.
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class MaskStripPhaseProbeTest {

    @OptIn(SlowSoftwareFiltering::class)
    private fun renderAt(svgText: String, timeMs: Long): Bitmap {
        val doc = SVG.getFromString(svgText, parseAnimations = true) as SVGImpl
        doc.animationTimeMs = timeMs
        val bitmap = createBitmap(SIZE, SIZE)
        bitmap.eraseColor(0)
        val options = RenderOptions.create()
        options.viewPort(0f, 0f, SIZE.toFloat(), SIZE.toFloat())
        options.softwareFiltering(true)
        doc.renderToCanvas(Canvas(bitmap), options)
        return bitmap
    }

    private fun pixels(bitmap: Bitmap): IntArray {
        val px = IntArray(SIZE * SIZE)
        bitmap.getPixels(px, 0, SIZE, 0, 0, SIZE, SIZE)
        return px
    }

    @Test
    fun pulsePhaseCreatesNoOutsideContentPixels() {
        for (variant in VARIANTS) {
            for (name in FILES) {
                val file = File("test-data/meteocons/animated/$variant/$name")
                if (!file.exists()) {
                    println("$variant/$name: missing, skipped")
                    continue
                }
            val withMask = file.readText()
            val maskAttr = Regex("""\s*mask="url\(#[^"]*\)"""")
            val stripped = withMask.replace(maskAttr, "")
            if (stripped.length == withMask.length) {
                println("$name: no mask attribute, skipped")
                continue
            }
            val legit = BooleanArray(SIZE * SIZE)
            for (t in TIMES) {
                val px = pixels(renderAt(stripped, t))
                for (i in px.indices) {
                    if ((px[i] ushr 24) != 0) legit[i] = true
                }
            }
            for (t in TIMES) {
                val px = pixels(renderAt(withMask, t))
                var leak = 0
                for (i in px.indices) {
                    if ((px[i] ushr 24) != 0 && !legit[i]) leak++
                }
                println("$variant/$name t=$t leak=$leak")
                assertEquals("$variant/$name leaks $leak outside-content pixels at t=$t", 0, leak)
            }
            }
        }
    }

    companion object {
        private const val SIZE = 256
        private val TIMES = longArrayOf(0L, 1500L)
        private val VARIANTS = arrayOf("fill", "flat", "line")
        private val FILES = arrayOf(
            "alert-avalanche-danger.svg",
            "alert-falling-rocks.svg",
        )
    }
}
