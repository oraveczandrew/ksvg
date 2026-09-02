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
import kotlin.math.abs

/**
 * Instrumented Android validation test for feGaussianBlur.
 */
@RunWith(AndroidJUnit4::class)
class GaussianBlurNativeDeviceTest {

    private fun checkBackend(backend: Int, backendName: String, tolerance: Int = 0) {
        assertTrue("libksvgblur not loadable on device", NativeGaussianBlur.isAvailable)
        
        Log.i("BlurValidation", "Testing backend: $backendName")
        Log.i("BlurValidation", "ABI: ${Build.SUPPORTED_ABIS.joinToString()}")

        val scratch = NativeGaussianBlur.createScratch()
        try {
            for (case in GaussianBlurValidationCorpus.cases) {
                val expected = case.reference()
                val out = case.input.copyOf()
                NativeGaussianBlur.applyForced(
                    scratch, out, case.width, case.height,
                    case.stdDeviationX, case.stdDeviationY,
                    backend
                )

                if (tolerance == 0) {
                    assertArrayEquals(
                        "$backendName mismatch on ${case.name}",
                        expected, out
                    )
                } else {
                    for (i in expected.indices) {
                        for (ch in 0..3) {
                            val shift = ch * 8
                            val d = abs(((out[i] shr shift) and 0xff) - ((expected[i] shr shift) and 0xff))
                            assertTrue(
                                "$backendName mismatch on ${case.name} at element [$i] channel $ch: " +
                                    "expected ${((expected[i] shr shift) and 0xff)} but was ${((out[i] shr shift) and 0xff)} " +
                                    "(diff $d > tolerance $tolerance)",
                                d <= tolerance
                            )
                        }
                    }
                }
            }
        } finally {
            NativeGaussianBlur.destroyScratch(scratch)
        }
    }

    @Test
    fun scalarMatchesKotlin() = checkBackend(UnlinearizeNative.SIMD_SCALAR, "scalar")

    @Test
    fun neon64MatchesKotlin() {
        val abi = Build.SUPPORTED_ABIS[0]
        if (abi == "arm64-v8a") {
            // Neon path uses fixed-point math, so expect some diff.
            checkBackend(UnlinearizeNative.SIMD_NEON64, "neon64", tolerance = 2)
        } else {
            Log.i("BlurValidation", "Skipping neon64 on $abi")
        }
    }

    @Test
    fun productionApplyMatchesKotlin() {
        assertTrue("libksvgblur not loadable on device", NativeGaussianBlur.isAvailable)
        val scratch = NativeGaussianBlur.createScratch()
        try {
            for (case in GaussianBlurValidationCorpus.cases) {
                val expected = case.reference()
                val out = case.input.copyOf()
                NativeGaussianBlur.nativeBlur(
                    scratch, out, case.width, case.height,
                    case.stdDeviationX, case.stdDeviationY
                )
                
                // Allow tolerance for optimized paths
                for (i in expected.indices) {
                    for (ch in 0..3) {
                        val shift = ch * 8
                        val d = abs(((out[i] shr shift) and 0xff) - ((expected[i] shr shift) and 0xff))
                        assertTrue(
                            "production mismatch on ${case.name} at element [$i] channel $ch: diff $d > 2",
                            d <= 2
                        )
                    }
                }
            }
        } finally {
            NativeGaussianBlur.destroyScratch(scratch)
        }
    }
}
