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

package hu.oandras.ksvg.filtering

import kotlin.math.abs
import kotlin.math.max

/**
 * Reusable per-axis stack-blur scratch buffers, owned by a [StackBlurScratch]
 * instance so that [StackBlur.stackBlur] does not allocate on every invocation. The buffers
 * are rebuilt only when the radius changes.
 */
internal class StackBlurAxisScratch {
    var radius: Int = -1
        private set
    lateinit var dv: IntArray
        private set
    lateinit var stack: Array<IntArray>
        private set

    fun ensure(radius: Int) {
        if (radius == this.radius) return
        val div = radius + radius + 1
        val divSum = (radius + 1) * (radius + 1)
        dv = IntArray(256 * divSum) { it / divSum }
        stack = Array(div) { IntArray(4) }
        this.radius = radius
    }
}

/**
 * Pure-Kotlin stack blur used as the fallback when the native `libksvgblur.so`
 * is unavailable (e.g. under the JVM/Robolectric unit-test runner).
 */
public object StackBlur {

    /**
     * High quality, fast alternative to Gaussian Blur.
     * Reusable buffers must be provided by the caller through a scratch object.
     */
    public fun blur(
        pixels: IntArray,
        width: Int,
        height: Int,
        stdDeviationX: Float,
        stdDeviationY: Float
    ) {
        val rx = max((stdDeviationX * 2.5f + 0.5f).toInt(), 0)
        val ry = max((stdDeviationY * 2.5f + 0.5f).toInt(), 0)
        val scratchX = StackBlurAxisScratch()
        val scratchY = StackBlurAxisScratch()
        if (rx > 0) stackBlur(pixels, width, height, rx, true, scratchX)
        if (ry > 0) stackBlur(pixels, width, height, ry, false, scratchY)
    }

    internal fun stackBlur(
        pix: IntArray,
        w: Int,
        h: Int,
        radius: Int,
        horizontal: Boolean,
        scratch: StackBlurAxisScratch,
    ) {
        scratch.ensure(radius)
        val dv = scratch.dv
        val stack = scratch.stack
        val div = radius + radius + 1
        val r1 = radius + 1

        val outerLimit = if (horizontal) h else w
        val innerLimit = if (horizontal) w else h
        val innerMax = innerLimit - 1

        // Pixels outside the source are transparent black (premultiplied 0), as required by the SVG
        // spec (filter input outside the filter region is transparent). This makes blurred shapes
        // show a correct transition at the filter-region edge (e.g. feSpecularLighting height field).
        for (i in 0 until outerLimit) {
            var aSum = 0
            var rSum = 0
            var gSum = 0
            var bSum = 0
            var aOutSum = 0
            var rOutSum = 0
            var gOutSum = 0
            var bOutSum = 0
            var aInSum = 0
            var rInSum = 0
            var gInSum = 0
            var bInSum = 0

            for (j in -radius..radius) {
                val p = sample(pix, w, i, innerMax, horizontal, j)
                val a = p shr 24 and 0xff
                val sir = stack[j + radius]
                sir[0] = a
                sir[1] = ((p shr 16 and 0xff) * a + 127) / 255
                sir[2] = ((p shr 8 and 0xff) * a + 127) / 255
                sir[3] = ((p and 0xff) * a + 127) / 255

                val rbs = r1 - abs(j)
                aSum += sir[0] * rbs
                rSum += sir[1] * rbs
                gSum += sir[2] * rbs
                bSum += sir[3] * rbs

                if (j > 0) {
                    aInSum += sir[0]
                    rInSum += sir[1]
                    gInSum += sir[2]
                    bInSum += sir[3]
                } else {
                    aOutSum += sir[0]
                    rOutSum += sir[1]
                    gOutSum += sir[2]
                    bOutSum += sir[3]
                }
            }

            var stackPointer = radius

            for (j in 0 until innerLimit) {
                pix[if (horizontal) i * w + j else j * w + i] = argb(
                    dv[aSum],
                    dv[rSum],
                    dv[gSum],
                    dv[bSum]
                )

                aSum -= aOutSum
                rSum -= rOutSum
                gSum -= gOutSum
                bSum -= bOutSum

                val stackIndex = (stackPointer - radius + div) % div
                val sir = stack[stackIndex]

                aOutSum -= sir[0]
                rOutSum -= sir[1]
                gOutSum -= sir[2]
                bOutSum -= sir[3]

                val p = sample(pix, w, i, innerMax, horizontal, j + r1)
                val a = p shr 24 and 0xff
                sir[0] = a
                sir[1] = ((p shr 16 and 0xff) * a + 127) / 255
                sir[2] = ((p shr 8 and 0xff) * a + 127) / 255
                sir[3] = ((p and 0xff) * a + 127) / 255

                aInSum += sir[0]
                rInSum += sir[1]
                gInSum += sir[2]
                bInSum += sir[3]

                aSum += aInSum
                rSum += rInSum
                gSum += gInSum
                bSum += bInSum

                stackPointer = (stackPointer + 1) % div
                val nextSir = stack[stackPointer]

                aOutSum += nextSir[0]
                rOutSum += nextSir[1]
                gOutSum += nextSir[2]
                bOutSum += nextSir[3]

                aInSum -= nextSir[0]
                rInSum -= nextSir[1]
                gInSum -= nextSir[2]
                bInSum -= nextSir[3]
            }
        }
    }

    private fun argb(alpha: Int, red: Int, green: Int, blue: Int): Int =
        (alpha shl 24) or (red shl 16) or (green shl 8) or blue

    private fun sample(pix: IntArray, w: Int, outer: Int, innerMax: Int, horizontal: Boolean, j: Int): Int {
        if (j < 0 || j > innerMax) return 0
        return pix[if (horizontal) outer * w + j else j * w + outer]
    }
}
