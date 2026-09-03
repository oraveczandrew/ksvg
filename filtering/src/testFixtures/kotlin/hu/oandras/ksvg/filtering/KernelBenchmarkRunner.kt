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
import java.util.*

/**
 * Shared performance benchmark harness for filter kernels, used by both the
 * host JVM benchmark (`KernelPerformanceBenchmark`, src/test) and the Android
 * instrumented benchmark (`KernelPerformanceDeviceBenchmark`, src/androidTest).
 * On Android `println` is routed into logcat, so no explicit `Log` calls are
 * needed here.
 */
public object KernelBenchmarkRunner {

    public data class Result(
        public val kernel: String,
        public val backend: String,
        public val width: Int,
        public val height: Int,
        public val avgMs: Double,
        public val mPixSec: Double,
        public val gbSec: Double,
        public val speedup: Double = 1.0
    )

    private val results: MutableList<Result> = mutableListOf()

    public fun runBenchmark(
        kernel: String,
        backendName: String,
        width: Int,
        height: Int,
        warmup: Int = 10,
        iterations: Int = 100,
        numBuffers: Int = 2, // src + dst usually
        runKernel: () -> Unit,
        verify: (() -> Unit)? = null
    ) {
        // Verification (once)
        verify?.invoke()

        // Warmup
        repeat(warmup) {
            runKernel()
        }

        // Timing
        val start = System.nanoTime()
        repeat(iterations) {
            runKernel()
        }
        val end = System.nanoTime()

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

        results.add(Result(kernel, backendName, width, height, avgMs, mPixSec, gbSec, speedup))

        println(
            String.format(
                Locale.US,
                "[%s] %s %dx%d: %.3f ms, %.2f MPix/s, %.2f GB/s (x%.2f)",
                kernel, backendName, width, height, avgMs, mPixSec, gbSec, speedup,
            ),
        )
    }

    public fun report(outputFile: File) {
        val header = "Kernel,Backend,Size,AvgMs,MPix/s,GB/s,Speedup"
        val csv = StringBuilder(header + "\n")

        val mdHeader = "| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup |"
        val mdSep = "| :--- | :--- | :---: | ---: | ---: | ---: | ---: |"
        val md = StringBuilder("$mdHeader\n$mdSep\n")

        for (r in results) {
            val line = String.format(
                Locale.US, "%s,%s,%dx%d,%.3f,%.2f,%.2f,%.2f",
                r.kernel, r.backend, r.width, r.height, r.avgMs, r.mPixSec, r.gbSec, r.speedup,
            )
            csv.append(line + "\n")

            val mdLine = String.format(
                Locale.US, "| %s | %s | %dx%d | %.3f | %.2f | %.2f | %.2fx |",
                r.kernel, r.backend, r.width, r.height, r.avgMs, r.mPixSec, r.gbSec, r.speedup,
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
                val best = results.filter { it.kernel == k && "${it.width}x${it.height}" == size }.minByOrNull { it.avgMs }
                if (best != null) {
                    println(String.format(Locale.US, "| %s | %s | %s | %.2fx |", k, size, best.backend, best.speedup))
                }
            }
        }
    }

    public fun clear() {
        results.clear()
    }
}
