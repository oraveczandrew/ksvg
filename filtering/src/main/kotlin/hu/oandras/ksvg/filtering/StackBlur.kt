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

/**
 * Reusable per-axis stack-blur scratch buffers, owned by a [StackBlurScratch]
 * instance so that [stackBlur] does not allocate on every invocation. The buffers
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
            val pos = if (horizontal) i * w + j else j * w + i
            val aOut = dv[aSum]
            if (aOut > 0) {
                val r = (dv[rSum] * 255 + aOut / 2) / aOut
                val g = (dv[gSum] * 255 + aOut / 2) / aOut
                val b = (dv[bSum] * 255 + aOut / 2) / aOut
                pix[pos] = argb(aOut, clamp255(r), clamp255(g), clamp255(b))
            } else {
                pix[pos] = 0
            }

            aSum -= aOutSum
            rSum -= rOutSum
            gSum -= gOutSum
            bSum -= bOutSum

            val stackStart = (stackPointer - radius + div) % div
            val sirOut = stack[stackStart]
            aOutSum -= sirOut[0]
            rOutSum -= sirOut[1]
            gOutSum -= sirOut[2]
            bOutSum -= sirOut[3]

            val pNext = sample(pix, w, i, innerMax, horizontal, j + r1)
            val aNext = pNext shr 24 and 0xff
            sirOut[0] = aNext
            sirOut[1] = ((pNext shr 16 and 0xff) * aNext + 127) / 255
            sirOut[2] = ((pNext shr 8 and 0xff) * aNext + 127) / 255
            sirOut[3] = ((pNext and 0xff) * aNext + 127) / 255

            aInSum += sirOut[0]
            rInSum += sirOut[1]
            gInSum += sirOut[2]
            bInSum += sirOut[3]
            aSum += aInSum
            rSum += rInSum
            gSum += gInSum
            bSum += bInSum

            stackPointer = (stackPointer + 1) % div
            val sirIn = stack[stackPointer]
            aOutSum += sirIn[0]
            rOutSum += sirIn[1]
            gOutSum += sirIn[2]
            bOutSum += sirIn[3]
            aInSum -= sirIn[0]
            rInSum -= sirIn[1]
            gInSum -= sirIn[2]
            bInSum -= sirIn[3]
        }
    }
}

private fun argb(alpha: Int, red: Int, green: Int, blue: Int): Int =
    (alpha shl 24) or (red shl 16) or (green shl 8) or blue

private fun sample(
    pix: IntArray,
    w: Int,
    i: Int,
    innerMax: Int,
    horizontal: Boolean,
    j: Int,
): Int {
    if (j < 0 || j > innerMax) return 0
    return if (horizontal) pix[i * w + j] else pix[j * w + i]
}

private fun clamp255(value: Int): Int =
    if (value < 0) 0 else if (value > 255) 255 else value
