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

package hu.oandras.ksvg.utils

import kotlin.math.abs

internal data class CubicBezier(
    @JvmField
    val x1: Float,
    @JvmField
    val y1: Float,
    @JvmField
    val x2: Float,
    @JvmField
    val y2: Float
) {
    fun evaluate(t: Float): Float {
        val u = 1f - t
        val tt = t * t
        val uu = u * u
        val uuu = uu * u
        val ttt = tt * t

        val x = uuu * 0f + 3f * uu * t * x1 + 3f * u * tt * x2 + ttt * 1f
        val y = uuu * 0f + 3f * uu * t * y1 + 3f * u * tt * y2 + ttt * 1f

        return if (x == 0f) 0f else y / x
    }

    fun solveY(y: Float): Float {
        var t = y
        var i = 0
        while (i < 8) {
            val x = cubicBezierX(t)
            val diff = x - y
            if (abs(diff) < 0.001f) break
            val dx = cubicBezierDX(t)
            if (dx == 0f) break
            t -= diff / dx
            t = t.coerceIn(0f, 1f)
            i++
        }
        return t
    }

    private fun cubicBezierX(t: Float): Float {
        val u = 1f - t
        val tt = t * t
        val uu = u * u
        return 3f * uu * t * x1 + 3f * u * tt * x2 + ttt(t)
    }

    private fun cubicBezierDX(t: Float): Float {
        val u = 1f - t
        return 3f * u * u * x1 + 6f * u * t * (x2 - x1) + 3f * t * t * (1f - x2)
    }

    private fun ttt(t: Float): Float = t * t * t
}