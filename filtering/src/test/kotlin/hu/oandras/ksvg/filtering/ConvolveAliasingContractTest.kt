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

package hu.oandras.ksvg.filtering

import org.junit.Assert.assertThrows
import org.junit.Test

/**
 * Audit: in-place convolution is unsupported on every backend (interior taps
 * read rows the kernel already overwrote), so both entry points fail fast
 * instead of silently diverging.
 */
class ConvolveAliasingContractTest {

    private val pixels = IntArray(8 * 8) { it }
    private val kernel = FloatArray(9) { 1f / 9f }

    @Test
    fun kotlinReferenceRejectsAliasing() {
        assertThrows(IllegalArgumentException::class.java) {
            KotlinKernels.convolveMatrix(
                pixels, pixels, 8, 8, kernel,
                3, 3, 1, 1, 1f, 0f, true, 0,
            )
        }
    }

    @Test
    fun softwareDispatchRejectsAliasing() {
        assertThrows(IllegalArgumentException::class.java) {
            SoftwareKernels.convolveMatrix(
                pixels, pixels, 8, 8, kernel,
                3, 3, 1, 1, 1f, 0f, true, 0,
            )
        }
    }
}
