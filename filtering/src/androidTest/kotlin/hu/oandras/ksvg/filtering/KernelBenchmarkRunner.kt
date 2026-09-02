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

import android.util.Log
import java.io.File
import java.util.*
import kotlin.math.abs

/**
 * Shared performance benchmark harness for filter kernels.
 */
object KernelBenchmarkRunner {

    data class Result(
        val kernel: String,
        val backend: String,
        val width: Int,
        val height: Int,
        val avgMs: Double,
        val mpixSec: Double,
        val gbSec: Double,
        val speedup: Double = 1.0
    )

    private val results = mutableListOf<Result>()

    fun runBenchmark(
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
        val mpixSec = (totalPixels / (totalNs / 1_000_000_000.0)) / 1_000_000.0
        
        // GB/s = (bytes per pixel * pixels * iterations * numBuffers) / seconds / 1e9
        val bytesReadWrite = 4.0 * width * height * iterations * numBuffers
        val gbSec = (bytesReadWrite / (totalNs / 1_000_000_000.0)) / 1_000_000_000.0

        val scalarMs = results.find { it.kernel == kernel && it.backend == "scalar" && it.width == width && it.height == height }?.avgMs
        val speedup = if (scalarMs != null) scalarMs / avgMs else 1.0

        results.add(Result(kernel, backendName, width, height, avgMs, mpixSec, gbSec, speedup))
        
        println(String.format(Locale.US, "[%s] %s %dx%d: %.3f ms, %.2f MPix/s, %.2f GB/s (x%.2f)", 
            kernel, backendName, width, height, avgMs, mpixSec, gbSec, speedup))
    }

    fun report(outputFile: File) {
        val header = "Kernel,Backend,Size,AvgMs,MPix/s,GB/s,Speedup"
        val csv = StringBuilder(header + "\n")
        
        val mdHeader = "| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup |"
        val mdSep = "| :--- | :--- | :---: | ---: | ---: | ---: | ---: |"
        val md = StringBuilder("$mdHeader\n$mdSep\n")

        for (r in results) {
            val line = String.format(Locale.US, "%s,%s,%dx%d,%.3f,%.2f,%.2f,%.2f",
                r.kernel, r.backend, r.width, r.height, r.avgMs, r.mpixSec, r.gbSec, r.speedup)
            csv.append(line + "\n")
            
            val mdLine = String.format(Locale.US, "| %s | %s | %dx%d | %.3f | %.2f | %.2f | %.2fx |",
                r.kernel, r.backend, r.width, r.height, r.avgMs, r.mpixSec, r.gbSec, r.speedup)
            md.append(mdLine + "\n")
        }

        outputFile.writeText(csv.toString())
        val msg = "\nBenchmark results saved to ${outputFile.absolutePath}\n\nHuman-readable report:\n\n$md\n"
        println(msg)
        Log.i("Benchmark", msg)
        
        // Fastest backend summary
        val summaryHeader = "| Kernel | Size | Fastest Backend | Speedup over Scalar |"
        val summarySep = "| :--- | :---: | :--- | ---: |"
        val summary = StringBuilder("\n### Fastest Backend Summary\n$summaryHeader\n$summarySep\n")
        val kernels = results.map { it.kernel }.distinct()
        for (k in kernels) {
            for (size in results.filter { it.kernel == k }.map { "${it.width}x${it.height}" }.distinct()) {
                val best = results.filter { it.kernel == k && "${it.width}x${it.height}" == size }.minByOrNull { it.avgMs }
                if (best != null) {
                    summary.append(String.format(Locale.US, "| %s | %s | %s | %.2fx |\n", k, size, best.backend, best.speedup))
                }
            }
        }
        println(summary.toString())
        Log.i("Benchmark", summary.toString())
    }
    
    fun clear() {
        results.clear()
    }
    
    // Tolerance helper for verification
    fun assertTolerance(expected: IntArray, actual: IntArray, tolerance: Int, message: String) {
        for (i in expected.indices) {
            for (ch in 0..3) {
                val shift = ch * 8
                val d = abs(((actual[i] shr shift) and 0xff) - ((expected[i] shr shift) and 0xff))
                if (d > tolerance) {
                    throw AssertionError("$message at index $i channel $ch: expected ${((expected[i] shr shift) and 0xff)} but was ${((actual[i] shr shift) and 0xff)} (diff $d > $tolerance)")
                }
            }
        }
    }
}
