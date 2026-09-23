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

import org.junit.BeforeClass
import org.junit.Test
import java.io.File

class KernelPerformanceBenchmark {

    companion object {

        private fun resolveTmpDir(): File {
            val candidates = listOf(File("../tmp"), File("tmp"))
            return candidates.firstOrNull { it.isDirectory } ?: File("../tmp").apply { mkdirs() }
        }

        @BeforeClass
        @JvmStatic
        fun setup() {
            assertNativeBackendAvailable()
            KernelBenchmarkRunner.clear()

            // Clear previous host results from tmp/
            val tmpDir = resolveTmpDir()
            if (tmpDir.exists()) {
                tmpDir
                    .listFiles { _, name ->
                        name.startsWith("benchmarks_host") && name.endsWith(".csv")
                    }
                    ?.forEach { it.delete() }
            }
        }
    }

    @Test
    fun benchmarkAll() {
        // Forcing a re-run of the benchmark
        val benchmarkArguments = BenchmarkArguments.fromSystemProperties()
        val sizes = if (benchmarkArguments.isQuick) listOf(512 to 512) else listOf(512 to 512, 2048 to 2048)

        val matrix = KernelBenchmarkMatrix.cases(
            kernels = benchmarkArguments.kernels,
            configs = benchmarkArguments.configs,
            sizes = sizes.toTypedArray()
        )

        // Hardware-counter profiling (cycles/instructions -> IPC column) is opt-in:
        // run with `-Dbenchmark.host.profile=true`. Without it the profiler stays
        // NoOp and the IPC / CyclesPerIter columns read 0 — that is expected, not
        // a measurement failure. Supported collectors: Intel macOS (IntelMacOSProfiler),
        // ARM64 macOS (Arm64MacOSProfiler), Linux perf (LinuxHardwareProfiler).
        val profileEnabled = System.getProperty("benchmark.host.profile") == "true"
        val profiler = when {
            profileEnabled && IntelMacOSProfiler.isSupported -> IntelMacOSProfiler()
            profileEnabled && Arm64MacOSProfiler.isSupported -> Arm64MacOSProfiler()
            profileEnabled && LinuxHardwareProfiler.isSupported -> LinuxHardwareProfiler()
            else -> HostProfiler.NoOp
        }

        val sink = HostBenchmarkSink(benchmarkArguments, profiler)

        for (case in matrix) {
            runBenchmarkCase(case, sink)
        }

        val target = (benchmarkArguments.kernels.orEmpty() + benchmarkArguments.configs.orEmpty()).joinToString("_")
        val suffix = if (!target.isNullOrEmpty()) "_$target" else ""
        val output = File(resolveTmpDir(), "benchmarks_host$suffix.csv")
        output.parentFile?.mkdirs()
        KernelBenchmarkRunner.report(output)
    }

    /**
     * Host implementation of [KernelBenchmarkSink]: raw JVM timing through the legacy
     * [KernelBenchmarkRunner] with deterministic iteration/warmup counts per size.
     */
    private class HostBenchmarkSink(
        private val arguments: BenchmarkArguments,
        private val profiler: HostProfiler
    ) : KernelBenchmarkSink {

        override fun runKotlin(case: BenchmarkCase, work: () -> Unit) {
            benchmark(case, backend = "kotlin", work)
        }

        override fun runNative(case: BenchmarkCase, work: (simdBackend: Int) -> Unit) {
            for (b in getBackendsFor(case.backendFlags)) {
                benchmark(case, backendName(b)) { work(b) }
            }
        }

        private fun benchmark(case: BenchmarkCase, backend: String, run: () -> Unit) {
            val quick = arguments.isQuick
            val iterations = if (quick) 1 else (if (case.width <= 512) 50 else 5)
            val warmup = if (quick) 1 else (if (case.width <= 512) 10 else 2)
            KernelBenchmarkRunner.runBenchmark(
                kernel = case.config.name,
                backendName = backend,
                width = case.width,
                height = case.height,
                warmup = warmup,
                iterations = iterations,
                numBuffers = case.numBuffers,
                profiler = profiler,
                runKernel = run
            )
        }
    }
}