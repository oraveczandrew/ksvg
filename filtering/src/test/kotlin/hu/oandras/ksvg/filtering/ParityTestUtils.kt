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

/**
 * Deterministic ARGB input so both kernels see identical data. Not
 * cryptographic; just a fixed, varied pattern (alpha too, for lighting's
 * alpha heightmap and morphology's per-channel pass).
 */
internal fun pattern(width: Int, height: Int, prime: Int): IntArray {
    val out = IntArray(width * height)
    var state = 0x9E3779B9.toInt() + prime
    for (i in out.indices) {
        state = state * 1664525 + 1013904223
        val v = state ushr 24
        out[i] = (v shl 24) or ((state ushr 16) and 0xFF shl 16) or
                ((state ushr 8) and 0xFF shl 8) or (state and 0xFF)
    }
    return out
}

internal fun argb(a: Int, r: Int, g: Int, b: Int): Int =
        (a shl 24) or (r shl 16) or (g shl 8) or b
