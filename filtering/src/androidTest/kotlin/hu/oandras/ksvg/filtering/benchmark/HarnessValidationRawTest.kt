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
import org.junit.BeforeClass
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.math.sqrt

/**
 * Validation test (spec §22; TEST_HARNESS_PLAN Step 8): prove the harness stabilises the
 * measurement versus a raw (harness-free) run of the same kernel.
 *
 * Both approaches measure the same `TurbulenceNative` neon64-dispatch call on 512x512. The
 * raw pass simply times N individual calls back-to-back on the instrumentation thread (no
 * foreground window, no priority bump, no warmup, no cache normalizer, no thermal gating).
 * The harness pass runs the same work through `nativeBenchmark { }`.
 *
 * The success criterion is NOT "faster" — it is lower variance in the batch-spread sense,
 * a stabler median/p95, and no worse classification. The test reports both side-by-side so a
 * human (and CI logs) can judge; it does not hard-fail on a marginal regression, because on a
 * non-sustained-performance device the device-wide thermal/frequency drift between the two
 * passes can be larger than the spread within one run.
 */
@RunWith(AndroidJUnit4::class)
class HarnessValidationRawTest {

    @Test
    fun rawVsHarnessVariance() {
        val w = 512
        val h = 512
        val backends = getBackendsFor(TurbulenceNative.nativeBackend())
        val neon = backends.firstOrNull { backendName(it) == "neon64" }
            ?: error("neon64 backend not available on this device")

        val pixels = IntArray(w * h)
        val kernel: () -> Unit = {
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
                simdBackend = neon,
            )
        }

        // Raw: N back-to-back calls, no harness at all.
        val rawSamples = DoubleArray(RAW_RUNS) { timedMs(kernel) }

        // Harness: the same work through nativeBenchmark { }.
        val harnessReport =
            nativeBenchmark {
                name = "ValidationHarness"
                backend = "neon64"
                width = w
                height = h
                warmupIterations = 10
                measurementBatches = 5
                iterationsPerBatch = 10
                run { kernel() }
            }

        val raw = describe(rawSamples)
        val harnessStats = harnessReport.stats
        val harnessSamples = harnessReport.samples.sumOf { it.size }

        println(
            "Validation raw-vs-harness (Turbulence neon64 512x512):\n" +
                "  raw      : n=$RAW_RUNS median=${raw.medianMs}p p95=${raw.p95Ms} max=${raw.maxMs} cv=${raw.cv}\n" +
                "  harness  : n=$harnessSamples median=${harnessStats.medianMs} " +
                "p95=${harnessStats.p95Ms} max=${harnessStats.maxMs} " +
                "cv=${harnessCv(harnessReport)} classification=${harnessReport.classification}"
        )
    }

    private fun timedMs(kernel: () -> Unit): Double {
        val t0 = System.nanoTime()
        kernel()
        return (System.nanoTime() - t0) / 1_000_000.0
    }

    /** CV of the whole sample set, computed here (host-side only, for reporting). */
    private fun describe(samples: DoubleArray): RawStats {
        val sorted = samples.sorted()
        val count = sorted.size
        val mean = sorted.average()
        val variance = sorted.sumOf { d -> (d - mean) * (d - mean) } / count
        val median = percentile(sorted, 0.5)
        val p95 = percentile(sorted, 0.95)
        return RawStats(median, p95, sorted[count - 1], sqrt(variance) / mean)
    }

    private fun percentile(sorted: List<Double>, p: Double): Double {
        val idx = p * (sorted.size - 1)
        val lo = idx.toInt()
        val hi = if (lo + 1 < sorted.size) lo + 1 else lo
        val frac = idx - lo
        return sorted[lo] * (1 - frac) + sorted[hi] * frac
    }

    private fun harnessCv(report: NativeBenchmarkReport): Double {
        val avgs = report.batchAveragesMs
        val mean = avgs.average()
        val variance = avgs.sumOf { a -> (a - mean) * (a - mean) } / avgs.size
        return sqrt(variance) / mean
    }

    private data class RawStats(
        val medianMs: Double,
        val p95Ms: Double,
        val maxMs: Double,
        val cv: Double,
    )

    private companion object {
        @BeforeClass
        @JvmStatic
        fun setup() {
            clearPreviousResults()
        }
        
        const val RAW_RUNS = 50
    }
}
