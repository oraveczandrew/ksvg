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
 * Instrumented Android validation test for `unlinearize.cpp`.
 *
 * Runs on-device over the exhaustive [UnlinearizeValidationCorpus] and forces
 * the ARM backends (NEON64 on AArch64, NEON32 on armeabi-v7a) explicitly.
 * Reports ABI, SIMD level, and selected backend for the validation matrix.
 */
@RunWith(AndroidJUnit4::class)
class UnlinearizeNativeDeviceTest {

    private fun checkBackend(backend: Int, backendName: String) {
        assertTrue("libksvgblur not loadable on device", UnlinearizeNative.isAvailable)
        
        Log.i("UnlinearizeValidation", "Testing backend: $backendName")
        Log.i("UnlinearizeValidation", "ABI: ${Build.SUPPORTED_ABIS.joinToString()}")
        Log.i("UnlinearizeValidation", "Dispatched backend: ${UnlinearizeNative.nativeBackend()}")

        for (case in UnlinearizeValidationCorpus.cases) {
            val expected = case.reference()
            val actual = if (case.inPlace) {
                val buf = case.freshInput()
                UnlinearizeNative.applyForced(buf, buf, case.width, case.height, case.table, backend)
                buf
            } else {
                val out = IntArray(case.size)
                UnlinearizeNative.applyForced(
                    case.freshInput(), out, case.width, case.height, case.table, backend
                )
                out
            }
            assertArrayEquals(
                "$backendName mismatch on ${case.name} (${case.width}x${case.height})",
                expected, actual
            )
        }
    }

    @Test
    fun scalarMatchesKotlin() = checkBackend(SIMD_SCALAR, "scalar")

    /**
     * NEON64 validation. Only runs on AArch64 devices; on other ABIs the native
     * runForced will assert-fail.
     */
    @Test
    fun neon64MatchesKotlin() {
        val abi = Build.SUPPORTED_ABIS[0]
        if (abi == "arm64-v8a") {
            checkBackend(SIMD_NEON64, "neon64")
        } else {
            Log.i("UnlinearizeValidation", "Skipping neon64 on $abi")
        }
    }

    /**
     * NEON32 validation. Only runs on 32-bit ARM devices; on other ABIs the
     * native runForced will assert-fail.
     */
    @Test
    fun neon32MatchesKotlin() {
        val abi = Build.SUPPORTED_ABIS[0]
        if (abi == "armeabi-v7a") {
            checkBackend(SIMD_NEON32, "neon32")
        } else {
            Log.i("UnlinearizeValidation", "Skipping neon32 on $abi")
        }
    }

    /**
     * Byte-exact normal production path (SoftwareKernels/UnlinearizeNative.apply)
     * over the corpus, confirming the dispatcher works as expected on this device.
     */
    @Test
    fun productionApplyMatchesKotlin() {
        assertTrue("libksvgblur not loadable on device", UnlinearizeNative.isAvailable)
        for (case in UnlinearizeValidationCorpus.cases) {
            val expected = case.reference()
            val actual = if (case.inPlace) {
                val buf = case.freshInput()
                UnlinearizeNative.apply(buf, buf, case.width, case.height, case.table)
                buf
            } else {
                val out = IntArray(case.size)
                UnlinearizeNative.apply(case.freshInput(), out, case.width, case.height, case.table)
                out
            }
            assertArrayEquals(
                "production apply mismatch on ${case.name} (${case.width}x${case.height})",
                expected, actual
            )
        }
    }
}
