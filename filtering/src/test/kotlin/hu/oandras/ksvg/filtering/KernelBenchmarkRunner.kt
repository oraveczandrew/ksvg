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

import java.io.File
import java.util.Locale

/**
 * Legacy raw performance benchmark runner for filter kernels. Used only by the
 * host JVM benchmark (`KernelPerformanceBenchmark`, src/test). The Android
 * device benchmark (`KernelPerformanceDeviceBenchmark`, src/androidTest) no
 * longer uses this: it runs through the stable `nativeBenchmark { }` harness
 * (`benchmark` package, spec `tmp/TEST_HARNESS.md`).
 */
object KernelBenchmarkRunner {

    data class Result(
        @JvmField val kernel: String,
        @JvmField val backend: String,
        @JvmField val width: Int,
        @JvmField val height: Int,
        @JvmField val avgMs: Double,
        @JvmField val mPixSec: Double,
        @JvmField val gbSec: Double,
        @JvmField val speedup: Double = 1.0,
        @JvmField val ipc: Double = 0.0,
        @JvmField val cyclesPerIter: Long = 0
    )

    private val results: MutableList<Result> = mutableListOf()

    private val LOCALE: Locale = Locale.US

    /**
     * Backend order for emitted rows. Mirrors the ISA superset convention
     * (`BENCHMARKS.md` header + `BenchmarkTableWriter.isaOrder` in buildSrc):
     * reference first, then native backends from oldest to newest ISA.
     */
    private val isaOrder = listOf("kotlin", "scalar", "sse2", "ssse3", "avx2", "avx512", "neon32", "neon64")

    internal fun backendRank(backend: String): Int {
        val lower = backend.lowercase(LOCALE)
        val idx = isaOrder.indexOfFirst { lower.contains(it) }
        return if (idx >= 0) idx else 999
    }

    fun runBenchmark(
        kernel: String,
        backendName: String,
        width: Int,
        height: Int,
        warmup: Int = 10,
        iterations: Int = 100,
        numBuffers: Int = 2, // src + dst usually
        profiler: HostProfiler = HostProfiler.NoOp,
        runKernel: () -> Unit,
        verify: (() -> Unit)? = null
    ) {
        // Verification (once)
        verify?.invoke()

        // Warmup
        repeat(warmup) {
            runKernel()
        }

        // Timing + Profiling
        profiler.start("${kernel}_${backendName}")
        val start = System.nanoTime()
        repeat(iterations) {
            runKernel()
        }
        val end = System.nanoTime()
        val metrics = profiler.stop()

        val totalNs = (end - start).toDouble()
        val avgNs = totalNs / iterations
        val avgMs = avgNs / 1_000_000.0

        val totalPixels = width.toDouble() * height * iterations
        val mPixSec = (totalPixels / (totalNs / 1_000_000_000.0)) / 1_000_000.0

        // GB/s = (bytes per pixel * pixels * iterations * numBuffers) / seconds / 1e9
        val bytesReadWrite = 4.0 * width * height * iterations * numBuffers
        val gbSec = (bytesReadWrite / (totalNs / 1_000_000_000.0)) / 1_000_000_000.0

        val scalarMs = results.find {
            it.kernel == kernel && it.backend == "scalar" && it.width == width && it.height == height
        }?.avgMs
        val speedup = if (scalarMs != null) scalarMs / avgMs else 1.0

        val cycles = metrics?.get("cycles") ?: 0L
        val instructions = metrics?.get("instructions") ?: 0L
        val ipc = if (cycles > 0) instructions.toDouble() / cycles else 0.0
        val cyclesPerIter = if (iterations > 0) cycles / iterations else 0L

        results.add(Result(
            kernel = kernel,
            backend = backendName,
            width = width,
            height = height,
            avgMs = avgMs,
            mPixSec = mPixSec,
            gbSec = gbSec,
            speedup = speedup,
            ipc = ipc,
            cyclesPerIter = cyclesPerIter
        ))

        val diag = if (ipc > 0) {
            String.format(LOCALE, ", IPC: %.2f, Cycles/Iter: %d", ipc, cyclesPerIter)
        } else ""

        println(
            String.format(
                LOCALE,
                "[%s] %s %dx%d: %.3f ms, %.2f MPix/s, %.2f GB/s (x%.2f)%s",
                kernel, backendName, width, height, avgMs, mPixSec, gbSec, speedup, diag
            ),
        )
    }

    fun report(outputFile: File) {
        val header = "Kernel,Backend,Size,AvgMs,MPix/s,GB/s,Speedup,IPC,CyclesPerIter"
        val csv = StringBuilder(header + "\n")

        val mdHeader = "| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup | IPC | Cycles/Iter |"
        val mdSep = "| :--- | :--- | :---: | ---: | ---: | ---: | ---: | ---: | ---: |"
        val md = StringBuilder("$mdHeader\n$mdSep\n")

        // Execution order is arbitrary (matrix/filter driven); emitted rows follow
        // the ISA superset convention: kernels alphabetical, sizes ascending,
        // backends kotlin -> scalar -> sse2 -> ... -> neon64.
        val ordered = results.sortedWith(
            compareBy<Result>(
                { it.kernel },
                { it.width * it.height },
                { backendRank(it.backend) },
            )
        )
        for (r in ordered) {
            val scalarMs = results.find {
                it.kernel == r.kernel && it.backend == "scalar" && it.width == r.width && it.height == r.height
            }?.avgMs
            val relSpeedup = if (scalarMs != null) scalarMs / r.avgMs else 1.0

            val escapedKernel = if (r.kernel.contains(",") || r.kernel.contains("\"")) {
                "\"${r.kernel.replace("\"", "\"\"")}\""
            } else {
                r.kernel
            }
            val line = String.format(
                LOCALE, "%s,%s,%dx%d,%.3f,%.2f,%.2f,%.2f,%.2f,%d",
                escapedKernel, r.backend, r.width, r.height, r.avgMs, r.mPixSec, r.gbSec, relSpeedup, r.ipc, r.cyclesPerIter
            )
            csv.append(line + "\n")

            val mdLine = String.format(
                LOCALE, "| %s | %s | %dx%d | %.3f | %.2f | %.2f | %.2fx | %.2f | %d |",
                r.kernel, r.backend, r.width, r.height, r.avgMs, r.mPixSec, r.gbSec, relSpeedup, r.ipc, r.cyclesPerIter
            )
            md.append(mdLine + "\n")
        }

        outputFile.writeText(csv.toString())
        println("\nBenchmark results saved to ${outputFile.absolutePath}")
        println("\nHuman-readable report:\n")
        println(md.toString())

        // Fastest backend summary
        println("\n### Fastest Backend Summary")
        val kernels = results.map { it.kernel }.distinct()
        val summaryHeader = "| Kernel | Size | Fastest Backend | Speedup over Scalar |"
        val summarySep = "| :--- | :---: | :--- | ---: |"
        println(summaryHeader)
        println(summarySep)
        for (k in kernels) {
            for (size in results.filter { it.kernel == k }.map { "${it.width}x${it.height}" }.distinct()) {
                val group = results.filter { it.kernel == k && "${it.width}x${it.height}" == size }
                val best = group.minByOrNull { it.avgMs }
                if (best != null) {
                    // Recomputed here: the stored speedup was captured at insertion
                    // time and is stale when scalar runs after faster backends.
                    val scalarMs = group.find { it.backend == "scalar" }?.avgMs
                    val bestSpeedup = if (scalarMs != null && best.avgMs > 0.0) scalarMs / best.avgMs else 1.0
                    println(String.format(Locale.US, "| %s | %s | %s | %.2fx |", k, size, best.backend, bestSpeedup))
                }
            }
        }
    }

    fun clear() {
        results.clear()
    }
}
