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

import android.content.Context
import android.os.Build
import android.os.PowerManager
import android.os.Process
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.util.Locale

/**
 * Public DSL + orchestration for the stable native benchmark harness
 * (TEST_HARNESS_PLAN.md Step 1; spec §12, §13, §17, §19).
 *
 * The benchmark test only describes the workload:
 *
 * ```
 * nativeBenchmark {
 *     name = "Turbulence"
 *     warmupIterations = 20
 *     measurementBatches = 5
 *     iterationsPerBatch = 10
 *     run { TurbulenceNative.applyForced(...) }
 * }
 * ```
 *
 * The harness provides: foreground Activity + sustained-performance opt-in
 * ([BenchmarkActivity]), benchmark-thread priority raise/restore, warmup, a batch
 * measurement loop with per-iteration `System.nanoTime()` sampling, and an
 * environment report. The measured region is exactly the [run] block (spec §20:
 * no logging, I/O, thermal reads or GC inside it).
 *
 * Later steps add thermal/cooldown gating, cache normalization, full statistics
 * and classification; the report shape here is deliberately a stepping stone.
 */
fun nativeBenchmark(configure: NativeBenchmarkBuilder.() -> Unit): NativeBenchmarkReport {
    val builder = NativeBenchmarkBuilder()
    builder.configure()
    return builder.execute()
}

class NativeBenchmarkBuilder {

    var name: String = "benchmark"

    var warmupIterations: Int = 20

    var measurementBatches: Int = 5

    var iterationsPerBatch: Int = 10

    /** Reserved for thermal-recovery cooldown (spec §9); wired up in a later step. */
    var cooldownSeconds: Long = 10

    private var body: (() -> Unit)? = null

    /** The measured region: the native kernel call and nothing else. */
    fun run(runBody: () -> Unit) {
        body = runBody
    }

    internal fun execute(): NativeBenchmarkReport {
        val kernel = requireNotNull(body) { "nativeBenchmark { run { ... } } is required" }

        BenchmarkActivity.waitForFocusedWindow()

        val tid = Process.myTid()
        val previousPriority = capturePriority(tid)

        val samples = Array(measurementBatches) { DoubleArray(iterationsPerBatch) }
        var threadPriorityApplied = false
        try {
            // Warmup never touches the measured region either.
            repeat(warmupIterations) { kernel.invoke() }

            for (b in 0 until measurementBatches) {
                for (i in 0 until iterationsPerBatch) {
                    val t0 = System.nanoTime()
                    kernel.invoke()
                    val t1 = System.nanoTime()
                    samples[b][i] = (t1 - t0) / 1_000_000.0
                }
            }
        } finally {
            threadPriorityApplied = restorePriority(tid, previousPriority)
        }

        val report =
            NativeBenchmarkReport(
                name = name,
                samples = samples,
                environment =
                    buildEnvironment(
                        warmupIterations = warmupIterations,
                        measurementBatches = measurementBatches,
                        iterationsPerBatch = iterationsPerBatch,
                        cooldownSeconds = cooldownSeconds,
                        threadPriorityApplied = threadPriorityApplied,
                    ),
            )
        report.print()
        report.writeCsv(context())
        return report
    }
}

class NativeBenchmarkReport(
    val name: String,
    val samples: Array<DoubleArray>,
    val environment: String,
) {

    val batchAveragesMs: List<Double> = samples.map { batch -> batch.average() }

    val allSamplesMs: List<Double> = samples.flatMap { it.toList() }

    /** Overall min/median/mean/max across all batches (full stats land in a later step). */
    val minMs: Double = allSamplesMs.min()
    val medianMs: Double = median(allSamplesMs)
    val meanMs: Double = allSamplesMs.average()
    val maxMs: Double = allSamplesMs.max()

    fun print() {
        println(
            buildString {
                appendLine("=== Benchmark: $name ===")
                append(environment)
                appendLine("batchAverageMs=${batchAveragesMs.joinToString(",") { formatMs(it) }}")
                append(
                    "overall=" +
                        "min=${formatMs(minMs)} " +
                        "median=${formatMs(medianMs)} " +
                        "mean=${formatMs(meanMs)} " +
                        "max=${formatMs(maxMs)}" +
                        "\n"
                )
            }
        )
    }

    fun writeCsv(context: Context) {
        val out = File(context.externalCacheDir, "benchmarks_harness_${name}.csv")
        val sb = StringBuilder()
        environment.lineSequence()
            .filter { it.isNotBlank() }
            .forEach { sb.append("env,").append(it).append('\n') }
        sb.append("batch,iteration,ms\n")
        for ((b, batch) in samples.withIndex()) {
            for ((i, ms) in batch.withIndex()) {
                sb.append(b).append(',').append(i).append(',')
                    .append(String.format(Locale.US, "%.4f", ms)).append('\n')
            }
        }
        out.writeText(sb.toString())
        println("Harness results saved to ${out.absolutePath}")
    }

    private fun formatMs(value: Double): String = String.format(Locale.US, "%.4f", value)

    private fun median(sortedList: List<Double>): Double {
        val sorted = sortedList.sorted()
        val mid = sorted.size / 2
        return if (sorted.size % 2 == 0) (sorted[mid - 1] + sorted[mid]) / 2 else sorted[mid]
    }
}

/** Builds the spec §16 environment block (key=value lines). */
private fun buildEnvironment(
    warmupIterations: Int,
    measurementBatches: Int,
    iterationsPerBatch: Int,
    cooldownSeconds: Long,
    threadPriorityApplied: Boolean,
): String =
    buildString {
        appendLine("device=${Build.DEVICE}")
        appendLine("model=${Build.MODEL}")
        appendLine("androidVersion=${Build.VERSION.SDK_INT}")
        appendLine("abi=${Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown"}")
        appendLine("cpuCoreCount=${Runtime.getRuntime().availableProcessors()}")
        appendLine(
            "sustainedPerformanceMode=" +
                (BenchmarkActivity.sustainedPerformanceModeInUse && BenchmarkActivity.sustainedSetResult != false)
        )
        appendLine("sustainedSetResult=${BenchmarkActivity.sustainedSetResult}")
        appendLine("thermalStatus=${thermalStatus()}")
        appendLine("windowFocused=${BenchmarkActivity.isWindowFocused}")
        appendLine("warmupIterations=$warmupIterations")
        appendLine("measurementBatches=$measurementBatches")
        appendLine("iterationsPerBatch=$iterationsPerBatch")
        appendLine("cooldownSeconds=$cooldownSeconds")
        appendLine("benchThreadPriority=$HIGH_PRIORITY")
        appendLine("threadPriorityApplied=$threadPriorityApplied")
    }

private fun context(): Context = InstrumentationRegistry.getInstrumentation().targetContext

private fun thermalStatus(): Int? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
    val pm = context().getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return null
    return pm.currentThermalStatus
}

/** Highest Linux nice priority (best-effort like the platform docs; needs no root). */
private const val HIGH_PRIORITY = -20

private fun capturePriority(tid: Int): Int? {
    return try {
        val previous = Process.getThreadPriority(tid)
        Process.setThreadPriority(tid, HIGH_PRIORITY)
        previous
    } catch (t: Throwable) {
        null
    }
}

private fun restorePriority(tid: Int, previous: Int?): Boolean {
    if (previous == null) return false
    return try {
        Process.setThreadPriority(tid, previous)
        true
    } catch (t: Throwable) {
        false
    }
}