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

import kotlin.math.pow
import kotlin.math.roundToInt

/**
 * Precomputed sRGB ↔ linear-RGB lookup tables for high-performance color
 * conversion in filter kernels.
 */
public object ColorLuts {

    /**
     * Precomputed linear→sRGB (unlinearize) lookup table, matching librsvg's
     * `build.rs` exactly: `LINEAR_TO_SRGB[i] = round(unlinearize(i / 255.0) * 255.0)`
     * where `unlinearize(c) = if c <= 0.0031308: 12.92 * c else: 1.055 * c^(1/2.4) - 0.055`.
     */
    @JvmField
    public val LINEAR_TO_SRGB: ByteArray = createLinearToSrgb()

    /** Alias for [LINEAR_TO_SRGB] for backward compatibility. */
    @JvmField
    public val UN_LINEARIZE: ByteArray = LINEAR_TO_SRGB

    /**
     * Precomputed sRGB→linear lookup table:
     * `SRGB_TO_LINEAR[i] = round(linearize(i / 255.0) * 255.0)`
     * where `linearize(c) = if c <= 0.04045: c / 12.92 else: ((c + 0.055) / 1.055)^2.4`.
     */
    @JvmField
    public val SRGB_TO_LINEAR: ByteArray = createSrgbToLinear()

    private fun createLinearToSrgb(): ByteArray {
        return ByteArray(256) { i ->
            val c = i.toDouble() / 255.0
            val x = if (c <= 0.0031308) {
                12.92 * c
            } else {
                1.055 * c.pow(1.0 / 2.4) - 0.055
            }
            (x * 255.0).roundToInt().toByte()
        }
    }

    private fun createSrgbToLinear(): ByteArray {
        return ByteArray(256) { i ->
            val c = i.toDouble() / 255.0
            val x = if (c <= 0.04045) {
                c / 12.92
            } else {
                ((c + 0.055) / 1.055).pow(2.4)
            }
            (x * 255.0).roundToInt().toByte()
        }
    }
}
