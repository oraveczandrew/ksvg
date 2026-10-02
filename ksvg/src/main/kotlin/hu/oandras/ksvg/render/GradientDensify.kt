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

package hu.oandras.ksvg.render

import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import kotlin.math.pow

/**
 * Straight-space gradient stop densification (F2).
 *
 * The platform `LinearGradient`/`RadialGradient` interpolate premultiplied,
 * which diverges from the spec/rsvg straight interpolation whenever stop
 * alphas differ (mid-tones come out far too bright). Subdividing each
 * segment into straight-lerped sub-stops makes the platform premult-lerp
 * approximate straight arbitrarily well (error ~O(1/N²) per segment).
 * Opaque (uniform-alpha) gradients keep the exact existing path.
 */

/** Subdivisions per stop segment when densifying. */
internal const val GRADIENT_DENSE_SUBDIVISIONS: Int = 16

/**
 * True when stop alphas differ, i.e., platform premult-lerp would diverge
 * from straight (spec). Uniform alpha (including all-opaque) needs no
 * densification: premult-lerp == straight-lerp there.
 */
internal fun needsDensify(colors: IntArray, count: Int): Boolean {
    if (count < 2) return false
    val a0 = colors[0].alpha
    for (i in 1 until count) {
        if (colors[i].alpha != a0) return true
    }
    return false
}

/** Densified stop count for [numStops] straight stops. */
internal fun denseCount(numStops: Int): Int {
    return 1 + (numStops - 1) * GRADIENT_DENSE_SUBDIVISIONS
}

/**
 * Straight-lerp subdivision of straight stops ([srcColors]/[srcPos], first
 * [count]) into [dstColors]/[dstPos] (sized [denseCount]). Integer half-up
 * math, no allocation.
 */
internal fun densifyStops(
    srcColors: IntArray,
    srcPos: FloatArray,
    count: Int,
    dstColors: IntArray,
    dstPos: FloatArray,
) {
    val k = GRADIENT_DENSE_SUBDIVISIONS
    var d = 0
    for (i in 0 until count - 1) {
        val c0 = srcColors[i]
        val c1 = srcColors[i + 1]
        val p0 = srcPos[i]
        val p1 = srcPos[i + 1]
        val a0 = c0.alpha
        val r0 = c0.red
        val g0 = c0.green
        val b0 = c0.blue
        val a1 = c1.alpha
        val r1 = c1.red
        val g1 = c1.green
        val b1 = c1.blue
        for (j in 0 until k) {
            val w1 = j
            val w0 = k - j
            dstColors[d] = ((((a0 * w0 + a1 * w1 + k / 2) / k) shl 24) or
                ((((r0 * w0 + r1 * w1 + k / 2) / k) shl 16) or
                    ((((g0 * w0 + g1 * w1 + k / 2) / k) shl 8) or
                        ((b0 * w0 + b1 * w1 + k / 2) / k))))
            dstPos[d] = p0 + (p1 - p0) * j / k
            d++
        }
    }
    dstColors[d] = srcColors[count - 1]
    dstPos[d] = srcPos[count - 1]
}

/**
 * Linear-RGB densification for `color-interpolation="linearRGB"` gradients.
 *
 * Same structural trick as [densifyStops] (subdivide so the platform's
 * encoded-space lerp approximates the spec interpolation with O(1/N²)
 * error), but the subdivision lerp runs in linearized space: endpoints are
 * linearized once per segment, sub-stops are lerped in linear + straight
 * alpha, then encoded back to sRGB. Alpha is not gamma-encoded, so it
 * lerps straight like in [densifyStops].
 *
 * Unlike [needsDensify], linearRGB always densifies (even uniform-alpha):
 * gamma-lerp and linear-lerp differ for opaque stops too.
 *
 * Float (not LUT) math: 8-bit linear steps are far too coarse in dark
 * tones. Callers gate on color/mode change (see `lastInterpolation` in
 * `ResolvedPaint`), so the `pow` cost lands on shader rebuilds, never on
 * steady-state frames. No allocation.
 */
internal fun densifyStopsLinear(
    srcColors: IntArray,
    srcPos: FloatArray,
    count: Int,
    dstColors: IntArray,
    dstPos: FloatArray,
) {
    val k = GRADIENT_DENSE_SUBDIVISIONS
    var d = 0
    for (i in 0 until count - 1) {
        val c0 = srcColors[i]
        val c1 = srcColors[i + 1]
        val p0 = srcPos[i]
        val p1 = srcPos[i + 1]
        val a0 = c0.alpha.toFloat()
        val r0 = srgbToLinear(c0.red)
        val g0 = srgbToLinear(c0.green)
        val b0 = srgbToLinear(c0.blue)
        val a1 = c1.alpha.toFloat()
        val r1 = srgbToLinear(c1.red)
        val g1 = srgbToLinear(c1.green)
        val b1 = srgbToLinear(c1.blue)
        val pStep = (p1 - p0) / k
        for (j in 0 until k) {
            val t = j.toFloat() / k
            val a = (a0 + (a1 - a0) * t + 0.5f).toInt()
            dstColors[d] = (a shl 24) or
                (linearToSrgb(r0 + (r1 - r0) * t) shl 16) or
                (linearToSrgb(g0 + (g1 - g0) * t) shl 8) or
                linearToSrgb(b0 + (b1 - b0) * t)
            dstPos[d] = p0 + pStep * j
            d++
        }
    }
    dstColors[d] = srcColors[count - 1]
    dstPos[d] = srcPos[count - 1]
}

/** sRGB 0..255 channel to linear 0..1 (exact transfer, not the 8-bit LUT). */
internal fun srgbToLinear(c: Int): Float {
    val v = c / 255.0
    return if (v <= 0.04045) {
        (v / 12.92).toFloat()
    } else {
        ((v + 0.055) / 1.055).pow(2.4).toFloat()
    }
}

/** Linear 0..1 to sRGB 0..255 (exact transfer, half-up rounded, clamped). */
internal fun linearToSrgb(l: Float): Int {
    val v = l.toDouble().coerceIn(0.0, 1.0)
    val s = if (v <= 0.0031308) {
        12.92 * v
    } else {
        1.055 * v.pow(1.0 / 2.4) - 0.055
    }
    return (s * 255.0 + 0.5).toInt().coerceIn(0, 255)
}
