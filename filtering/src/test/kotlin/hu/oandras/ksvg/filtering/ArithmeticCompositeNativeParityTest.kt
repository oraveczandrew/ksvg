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

import org.junit.Assert.assertArrayEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

@RunWith(Parameterized::class)
class ArithmeticCompositeNativeParityTest(
    private val k: FloatArray,
    private val useLinear: Boolean,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters
        fun data(): List<Array<Any>> = listOf(
            arrayOf(floatArrayOf(1f, 0f, 0f, 0f), false), // multiply
            arrayOf(floatArrayOf(0f, 1f, 1f, 0f), false), // add
            arrayOf(floatArrayOf(0.5f, 0.5f, 0.5f, 0.5f), true), // mixed linear
            arrayOf(floatArrayOf(0f, 0f, 0f, 0.25f), false), // constant bias
        )
    }

    @Test
    fun nativeMatchesKotlin() {
        assertNativeBackendAvailable()

        val width = 32
        val height = 32
        val src1 = pattern(width, height, k.contentHashCode() + 1)
        val src2 = pattern(width, height, k.contentHashCode() + 2)
        val ref = IntArray(width * height)
        val native = IntArray(width * height)

        KotlinKernels.arithmeticComposite(
            src1, src2, ref, width, 0, 0, width, height,
            k[0], k[1], k[2], k[3], useLinear
        )
        SoftwareKernels.arithmeticComposite(
            src1, src2, native, width, 0, 0, width, height,
            k[0], k[1], k[2], k[3], useLinear
        )

        assertArrayEquals("arithmeticComposite mismatch", ref, native)
    }
}
