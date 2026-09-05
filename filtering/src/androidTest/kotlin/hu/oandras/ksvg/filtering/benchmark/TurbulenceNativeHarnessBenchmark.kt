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

package hu.oandras.ksvg.filtering.benchmark

import androidx.test.ext.junit.runners.AndroidJUnit4
import hu.oandras.ksvg.filtering.TurbulenceNative
import hu.oandras.ksvg.filtering.backendName
import hu.oandras.ksvg.filtering.getBackendsFor
import org.junit.Test
import org.junit.runner.RunWith

/**
 * First concrete benchmark on the harness DSL (TEST_HARNESS_PLAN.md Step 1; spec §24.3):
 * feTurbulence scalar vs NEON at 512x512, the primitive used during the ARM64 optimization
 * campaign. Each backend runs as its own `nativeBenchmark { }` block, so they share the
 * exact same harness (window, priority, warmup, batch loop).
 */
@RunWith(AndroidJUnit4::class)
class TurbulenceNativeHarnessBenchmark {

    @Test
    fun turbulenceScalarVsNeon() {
        val w = 512
        val h = 512
        val pixels = IntArray(w * h)

        val backends = getBackendsFor(TurbulenceNative.nativeBackend())

        for (simdBackend in backends) {
            nativeBenchmark {
                name = "Turbulence"
                backend = backendName(simdBackend)
                width = w
                height = h
                warmupIterations = 10
                measurementBatches = 5
                iterationsPerBatch = 10
                run {
                    TurbulenceNative.applyForced(
                        pixels = pixels,
                        width = w,
                        height = h,
                        clipLeft = 0,
                        clipTop = 0,
                        clipRight = w,
                        clipBottom = h,
                        baseFrequencyX = 0.01,
                        baseFrequencyY = 0.01,
                        periodX = 0,
                        periodY = 0,
                        octaves = 1,
                        fractalNoise = false,
                        invCanvasScaleX = 1.0,
                        invCanvasScaleY = 1.0,
                        userLeft = 0.0,
                        userTop = 0.0,
                        originX = 0.0,
                        originY = 0.0,
                        unitSizeX = 1.0,
                        unitSizeY = 1.0,
                        seed = 123,
                        simdBackend = simdBackend,
                    )
                }
            }
        }
    }
}