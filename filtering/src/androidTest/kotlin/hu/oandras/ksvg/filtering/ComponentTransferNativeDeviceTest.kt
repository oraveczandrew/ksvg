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
 * Instrumented Android validation test for feComponentTransfer.
 */
@RunWith(AndroidJUnit4::class)
class ComponentTransferNativeDeviceTest {

    private fun checkBackend(backend: Int, backendName: String) {
        assertTrue("libksvgblur not loadable on device", ComponentTransferNative.isAvailable)
        
        Log.i("CompTransValidation", "Testing backend: $backendName")
        Log.i("CompTransValidation", "ABI: ${Build.SUPPORTED_ABIS.joinToString()}")

        for (case in ComponentTransferValidationCorpus.cases) {
            val expected = case.reference()
            val out = IntArray(case.size)
            ComponentTransferNative.applyForced(
                case.input, out, case.width, case.height,
                case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
                case.tableA, case.tableR, case.tableG, case.tableB,
                backend
            )
            assertArrayEquals(
                "$backendName mismatch on ${case.name} (${case.width}x${case.height})",
                expected, out
            )
        }
    }

    @Test
    fun scalarMatchesKotlin() = checkBackend(SIMD_SCALAR, "scalar")

    @Test
    fun neon64MatchesKotlin() {
        val abi = Build.SUPPORTED_ABIS[0]
        if (abi == "arm64-v8a") {
            // Note: This is expected to FAIL for channel values >= 64 due to 
            // vqtbl4q_u8 64-entry limitation in current implementation.
            checkBackend(SIMD_NEON64, "neon64")
        } else {
            Log.i("CompTransValidation", "Skipping neon64 on $abi")
        }
    }

    @Test
    fun neon32MatchesKotlin() {
        val abi = Build.SUPPORTED_ABIS[0]
        if (abi == "armeabi-v7a") {
            checkBackend(SIMD_NEON32, "neon32")
        } else {
            Log.i("CompTransValidation", "Skipping neon32 on $abi")
        }
    }

    @Test
    fun productionApplyMatchesKotlin() {
        assertTrue("libksvgblur not loadable on device", ComponentTransferNative.isAvailable)
        for (case in ComponentTransferValidationCorpus.cases) {
            val expected = case.reference()
            val out = IntArray(case.size)
            ComponentTransferNative.apply(
                case.input, out, case.width, case.height,
                case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
                case.tableA, case.tableR, case.tableG, case.tableB
            )
            assertArrayEquals(
                "production apply mismatch on ${case.name}",
                expected, out
            )
        }
    }
}
