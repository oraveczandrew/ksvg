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
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.argb
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
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
 * value may lie outside `[0,1]` on the covered side (`t > 1` beyond the end
 * circle) — spread handling is the caller's job (see [applyGradientSpread]).
 * Points inside the start circle solve naturally to a `t > 0` through the
 * cone (no special-casing: this is what the platform two-point
 * `RadialGradient` and rsvg do).
 *
 * Returns `NaN` when the point is not covered by any forward (`t ≥ 0`) circle
 * — the region behind the focal apex that the cone never reaches. Callers must
 * paint `NaN` as transparent (again matching the platform constructor and rsvg
 * on every tile mode); feeding it into [applyGradientSpread] is meaningless.
 *
 * Degenerate inputs (zero growth, no real root) fall back to end-circle
 * behavior (`1f`), except when they also imply no coverage (`NaN`).
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
        val t = c / denom
        // A negative single root means the (single) solution circle lies
        // behind the start: no forward coverage.
        return if (t < 0f) Float.NaN else t
    }
    val discriminant = b * b - a * c
    if (discriminant < 0f) return Float.NaN
    // Root selection is sign-dependent (verified against centered on-circle /
    // interior, off-center interior and exterior on-circle points, and against
    // the platform two-point constructor inside the start circle). A negative
    // selected root implies no forward coverage: for `a > 0` the pair is
    // same-sign (both negative); the `a < 0` selection is always non-negative.
    val t = if (a > 0f) {
        (b + sqrt(discriminant)) / a
    } else {
        (b - sqrt(discriminant)) / a
    }
    return if (t < 0f) Float.NaN else t
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
    return argb(
        alpha = c0.alpha + ((c1.alpha - c0.alpha) * f + 0.5f).toInt(),
        red = c0.red + ((c1.red - c0.red) * f + 0.5f).toInt(),
        green = c0.green + ((c1.green - c0.green) * f + 0.5f).toInt(),
        blue = c0.blue + ((c1.blue - c0.blue) * f + 0.5f).toInt(),
    )
}
