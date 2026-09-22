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
 * True when stop alphas differ, i.e. platform premult-lerp would diverge
 * from straight (spec). Uniform alpha (including all-opaque) needs no
 * densification: premult-lerp == straight-lerp there.
 */
internal fun needsDensify(colors: IntArray, count: Int): Boolean {
    if (count < 2) return false
    val a0 = colors[0] ushr 24
    for (i in 1 until count) {
        if ((colors[i] ushr 24) != a0) return true
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
        val a0 = c0 ushr 24
        val r0 = c0 shr 16 and 0xff
        val g0 = c0 shr 8 and 0xff
        val b0 = c0 and 0xff
        val a1 = c1 ushr 24
        val r1 = c1 shr 16 and 0xff
        val g1 = c1 shr 8 and 0xff
        val b1 = c1 and 0xff
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
