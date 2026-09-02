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

/**
 * ARGB input guaranteed to exercise every 8-bit value (0..255) in each colour
 * channel: pixel `i` has A=i, R=i, G=(i+85)&0xFF, B=(i*137)&0xFF. 85 and 137 are
 * coprime with 256, so G and B are permutations of 0..255 exactly like R and A.
 * This means any single-byte LUT gather bug (e.g. a table that only addresses
 * 64 entries silently zeroing channels 64..255) is caught for every index.
 */
internal fun fullCoverage(width: Int, height: Int): IntArray {
    val out = IntArray(width * height)
    for (i in out.indices) {
        val v = i and 0xFF
        out[i] = argb(v, v, (v + 85) and 0xFF, (v * 137) and 0xFF)
    }
    return out
}
