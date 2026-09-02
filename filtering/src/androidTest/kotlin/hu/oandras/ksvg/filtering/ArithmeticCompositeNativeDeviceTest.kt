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

import android.os.Build
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Instrumented Android validation test for feComposite operator="arithmetic".
 */
@RunWith(AndroidJUnit4::class)
class ArithmeticCompositeNativeDeviceTest {

    private fun checkBackend(backend: Int, backendName: String) {
        assertTrue("libksvgblur not loadable on device", ArithmeticCompositeNative.isAvailable)
        
        Log.i("ArithmeticValidation", "Testing backend: $backendName")
        Log.i("ArithmeticValidation", "ABI: ${Build.SUPPORTED_ABIS.joinToString()}")

        for (case in ArithmeticCompositeValidationCorpus.cases) {
            val expected = case.reference()
            val out = IntArray(case.size)
            ArithmeticCompositeNative.applyForced(
                case.input1, case.input2, out, case.width,
                case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
                case.k1, case.k2, case.k3, case.k4, case.useLinear,
                backend
            )
            assertArrayEquals(
                "$backendName mismatch on ${case.name}",
                expected, out
            )
        }
    }

    @Test
    fun scalarMatchesKotlin() = checkBackend(SIMD_SCALAR, "scalar")

    @Test
    fun productionApplyMatchesKotlin() {
        assertTrue("libksvgblur not loadable on device", ArithmeticCompositeNative.isAvailable)
        for (case in ArithmeticCompositeValidationCorpus.cases) {
            val expected = case.reference()
            val out = IntArray(case.size)
            ArithmeticCompositeNative.apply(
                case.input1, case.input2, out, case.width,
                case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
                case.k1, case.k2, case.k3, case.k4, case.useLinear
            )
            assertArrayEquals(
                "production apply mismatch on ${case.name}",
                expected, out
            )
        }
    }
}
