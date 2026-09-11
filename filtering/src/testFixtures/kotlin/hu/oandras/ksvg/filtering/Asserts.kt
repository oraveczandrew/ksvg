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

/** Shared by the host JVM parity tests and the Android instrumented tests. */
public fun assertNativeBackendAvailable() {
    assertTrue(
        "NativeBackend not available on this host JVM",
        NativeBackend.isAvailable,
    )
}

/** Asserts ARGB pixel arrays and reports the first mismatch in hexadecimal. */
public fun assertColorArrayEquals(
    message: String,
    expected: IntArray,
    actual: IntArray,
) {
    if (expected.size != actual.size) {
        throw AssertionError(
            "$message: array lengths differ, expected=${expected.size}, actual=${actual.size}",
        )
    }
    for (index in expected.indices) {
        if (expected[index] != actual[index]) {
            throw AssertionError(
                "$message: mismatch at index $index, " +
                    "expected=0x${expected[index].toHexString(HexFormat.UpperCase)}, " +
                    "actual=0x${actual[index].toHexString(HexFormat.UpperCase)}",
            )
        }
    }
}
