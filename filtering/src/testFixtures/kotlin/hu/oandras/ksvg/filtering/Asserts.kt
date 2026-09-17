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

import org.junit.Assert.assertTrue
import kotlin.math.abs
import kotlin.text.HexFormat

/** Shared by the host JVM parity tests and the Android instrumented tests. */
public fun assertNativeBackendAvailable() {
    assertTrue(
        "NativeBackend not available on this host JVM",
        NativeBackend.isAvailable,
    )
}

/**
 * Asserts ARGB pixel arrays and reports all mismatches in hexadecimal.
 *
 * Scans the full array and, on failure, throws an [AssertionError] that
 * summarizes the total mismatch count and lists the first [sampleLimit]
 * mismatches. The extra iteration cost only occurs when a comparison fails;
 * the diagnostic value outweighs it for very large arrays.
 */
public fun assertColorArrayEquals(
    message: String,
    expected: IntArray,
    actual: IntArray,
    sampleLimit: Int = 10,
    maxDelta: Int = 0,
) {
    if (expected.size != actual.size) {
        throw AssertionError(
            "$message: array lengths differ, expected=${expected.size}, actual=${actual.size}",
        )
    }
    var mismatchCount = 0
    val samples = mutableListOf<String>()
    for (index in expected.indices) {
        val expColor = expected[index]
        val actColor = actual[index]
        
        if (expColor != actColor) {
            val expA = (expColor ushr 24) and 0xFF
            val expR = (expColor ushr 16) and 0xFF
            val expG = (expColor ushr 8) and 0xFF
            val expB = expColor and 0xFF

            val actA = (actColor ushr 24) and 0xFF
            val actR = (actColor ushr 16) and 0xFF
            val actG = (actColor ushr 8) and 0xFF
            val actB = actColor and 0xFF

            val dA = abs(expA - actA)
            val dR = abs(expR - actR)
            val dG = abs(expG - actG)
            val dB = abs(expB - actB)

            if (dA > maxDelta || dR > maxDelta || dG > maxDelta || dB > maxDelta) {
                mismatchCount++
                if (mismatchCount <= sampleLimit) {
                    samples.add(
                        "  index $index: expected=0x${expColor.toHexString(HexFormat.UpperCase)}, " +
                            "actual=0x${actColor.toHexString(HexFormat.UpperCase)} (deltas: A=$dA, R=$dR, G=$dG, B=$dB)",
                    )
                }
            }
        }
    }
    if (mismatchCount > 0) {
        val summary = buildString {
            append("$message: $mismatchCount pixel mismatch(es) exceeding maxDelta=$maxDelta")
            if (mismatchCount > sampleLimit) {
                append(" (first $sampleLimit listed)")
            }
            append('\n')
            append(samples.joinToString("\n"))
        }
        throw AssertionError(summary)
    }
}

