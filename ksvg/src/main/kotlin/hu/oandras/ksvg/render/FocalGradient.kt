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

import hu.oandras.ksvg.dom.gradient.GradientSpread
import kotlin.math.sqrt

/**
 * Focal (two-circle) radial gradient math for the API < 31 fallback.
 *
 * `android.graphics.RadialGradient` cannot express an off-center focal point
 * below API 31, so [Renderer] rasterizes such gradients into a bitmap once
 * per geometry/color change (see the bake path in `makeRadialGradient`).
 * Everything here is pure math over unit gradient space, deliberately kept
 * out of the renderer so it stays unit-testable.
 */

/**
 * Focal parameter of point ([px], [py]): solves
 * `|P − (F + t·(C−F))| = fr + t·(r−fr)` for `t`, where `F`/`fr` is the start
 * (focal) circle and `C`/`r` the end circle.
 *
 * Returns `t` in gradient units (`0` = start circle, `1` = end circle); the
 * value may lie outside `[0,1]` — spread handling is the caller's job (see
 * [applyGradientSpread]). Degenerate inputs (zero growth, no real root) fall
 * back to end-circle behavior (`1f`).
 */
internal fun focalGradientT(
    px: Float,
    py: Float,
    fx: Float,
    fy: Float,
    fr: Float,
    cx: Float,
    cy: Float,
    r: Float,
): Float {
    val ex = cx - fx
    val ey = cy - fy
    val er = r - fr
    val ux = px - fx
    val uy = py - fy
    // (e·e − er²)·t² − 2·(u·e + fr·er)·t + (u·u − fr²) = 0
    val a = ex * ex + ey * ey - er * er
    val b = ux * ex + uy * ey + fr * er
    val c = ux * ux + uy * uy - fr * fr
    if (a > -1e-6f && a < 1e-6f) {
        // Tangent-cone degenerate: uniform growth, linear fallback.
        val denom = 2f * b
        if (denom > -1e-9f && denom < 1e-9f) return 1f
        return c / denom
    }
    val discriminant = b * b - a * c
    if (discriminant < 0f) return 1f
    // Root selection is sign-dependent (verified against centered on-circle /
    // interior, off-center interior and exterior on-circle points).
    return if (a > 0f) {
        (b + sqrt(discriminant)) / a
    } else {
        (b - sqrt(discriminant)) / a
    }
}

/**
 * Moves the focal point ([fx], [fy]) onto the end circle when it lies
 * outside it (SVG 1.1 §13.2.3: intersect the center→focal line with the
 * circle), returning the clamped pair. The focal radius is kept as-is.
 * Pure (no allocation): results are written into [out] (`out[0]` = x,
 * `out[1]` = y, sized 2, caller-owned).
 */
internal fun clampFocalToCircle(
    fx: Float,
    fy: Float,
    cx: Float,
    cy: Float,
    r: Float,
    out: FloatArray,
): FloatArray {
    val dx = fx - cx
    val dy = fy - cy
    val dist = sqrt(dx * dx + dy * dy)
    if (dist > r && dist > 0f) {
        val k = r / dist
        out[0] = cx + dx * k
        out[1] = cy + dy * k
    } else {
        out[0] = fx
        out[1] = fy
    }
    return out
}

/**
 * Maps a raw focal parameter to `[0,1]` per [spread] (`pad` clamps,
 * `repeat` wraps, `reflect` mirrors).
 */
internal fun applyGradientSpread(t: Float, spread: GradientSpread): Float {
    return when (spread) {
        GradientSpread.pad -> t.coerceIn(0f, 1f)
        GradientSpread.repeat -> {
            val m = t % 1f
            if (m < 0f) m + 1f else m
        }
        GradientSpread.reflect -> {
            var m = t % 2f
            if (m < 0f) m += 2f
            if (m > 1f) m = 2f - m
            m
        }
    }
}

/**
 * Straight-ARGB interpolation of the stop table ([colors]/[positions], first
 * [count] entries, positions non-decreasing) at [t]. Binary search, no
 * allocation.
 */
internal fun sampleGradientStops(
    colors: IntArray,
    positions: FloatArray,
    count: Int,
    t: Float,
): Int {
    if (t <= positions[0]) return colors[0]
    if (t >= positions[count - 1]) return colors[count - 1]
    var lo = 0
    var hi = count - 1
    while (hi - lo > 1) {
        val mid = (lo + hi) ushr 1
        if (positions[mid] <= t) {
            lo = mid
        } else {
            hi = mid
        }
    }
    val p0 = positions[lo]
    val p1 = positions[hi]
    if (p1 <= p0) return colors[hi]
    val f = (t - p0) / (p1 - p0)
    val c0 = colors[lo]
    val c1 = colors[hi]
    val a = ((c0 ushr 24) + (((c1 ushr 24) - (c0 ushr 24)) * f + 0.5f).toInt()) shl 24
    val r = (((c0 shr 16) and 0xff) + ((((c1 shr 16) and 0xff) - ((c0 shr 16) and 0xff)) * f + 0.5f).toInt()) shl 16
    val g = (((c0 shr 8) and 0xff) + ((((c1 shr 8) and 0xff) - ((c0 shr 8) and 0xff)) * f + 0.5f).toInt()) shl 8
    val b = ((c0 and 0xff) + (((c1 and 0xff) - (c0 and 0xff)) * f + 0.5f).toInt())
    return a or r or g or b
}
