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

import androidx.test.ext.junit.runners.AndroidJUnit4
import hu.oandras.ksvg.filtering.benchmark.BenchmarkActivity
import hu.oandras.ksvg.filtering.benchmark.BenchmarkViewModel
import hu.oandras.ksvg.filtering.benchmark.DeviceBenchmarkSink
import hu.oandras.ksvg.filtering.benchmark.clearSuiteResults
import org.junit.BeforeClass
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Device kernel benchmark running every native filter kernel through the stable
 * `nativeBenchmark { }` harness (spec `tmp/TEST_HARNESS.md`; TEST_HARNESS_PLAN), replacing
 * the old raw `KernelBenchmarkRunner` driver.
 *
 * The kernel/config/size matrix comes from [KernelBenchmarkMatrix]; the per-cell workload
 * (buffer setup + Kotlin/native kernel calls) is shared with the host suite via
 * `runBenchmarkCase`, and the device execution strategy lives in [DeviceBenchmarkSink]
 * (per-cell harness blocks, thermal gating, simpleperf profiling).
 *
 * Keeps the legacy kernel-selection arguments:
 *  - `benchmark.kernel` = one of UnLinearize, ComponentTransfer, Morphology,
 *    ArithmeticComposite (both modes), ConvolveMatrix, DisplacementMap, Lighting,
 *    Turbulence, GaussianBlur; empty runs the full suite.
 *  - `benchmark.config` = optional config-name filter, `+`-separated case-insensitive
 *    substrings matched against the cell display name, e.g. "diffuse, distant, linear",
 *    "linear" or a full "Lighting (diffuse, distant, linear)"; ANDed with
 *    `benchmark.kernel` when both are given (e.g. kernel=Lighting + config=specular).
 *  - `benchmark.quick` = true runs 512x512 only (else 512x512 + 2048x2048).
 */
@RunWith(AndroidJUnit4::class)
class KernelPerformanceDeviceBenchmark {

    private companion object {
        /** Result suite: `benchmarks/<SUITE>/` on the device; see [clearSuiteResults]. */
        const val SUITE = "kernelBenchmark"

        @BeforeClass
        @JvmStatic
        fun setup() {
            assertNativeBackendAvailable()
            clearSuiteResults(SUITE)
        }

        private fun benchmarkMatrix(args: BenchmarkArguments): List<BenchmarkCase> {
            val benchmarkSizes =
                if (args.isQuick) arrayOf(512 to 512) else arrayOf(512 to 512, 2048 to 2048)
            return KernelBenchmarkMatrix.cases(
                kernels = args.kernels,
                configs = args.configs,
                sizes = benchmarkSizes
            )
        }
    }

    @Test
    fun benchmarkAll() {
        val benchmarkArguments = BenchmarkArguments.fromInstrumentationRegistry()
        val sink = DeviceBenchmarkSink(benchmarkArguments, SUITE)
        val matrix = benchmarkMatrix(benchmarkArguments)
        BenchmarkViewModel.beginSuite(sink.estimatedTotalRuns(matrix))
        try {
            for (case in matrix) {
                runBenchmarkCase(case, sink)
            }
        } finally {
            // Tear down the benchmark window (spinner, sustained mode, screen-on):
            // later suites in this process (parity!) must not inherit capped
            // clocks and a spinning core. Relaunch is on demand (ensureAlive).
            BenchmarkActivity.finishSingleton()
        }
    }
}