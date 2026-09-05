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
 * (TEST_HARNESS_PLAN.md Step 1-2; spec §12, §13, §14, §17, §19).
 *
 * The benchmark test only describes the workload:
 *
 * ```
 * nativeBenchmark {
 *     name = "Turbulence"
 *     backend = "neon64"
 *     width = 512
 *     height = 512
 *     warmupIterations = 20
 *     measurementBatches = 5
 *     iterationsPerBatch = 10
 *     run { TurbulenceNative.applyForced(...) }
 * }
 * ```
 *
 * The harness provides: foreground Activity + sustained-performance opt-in
 * ([BenchmarkActivity]), benchmark-thread priority raise/restore, warmup, a batch
 * measurement loop with per-iteration `System.nanoTime()` sampling, per-sample
 * statistics ([BenchmarkStats], spec §14), and an environment report. The measured
 * region is exactly the [run] block (spec §20: no logging, I/O, thermal reads or GC
 * inside it).
 *
 * Later steps add thermal/cooldown gating, cache normalization, classification and
 * the validation-vs-raw comparison.
 */
fun nativeBenchmark(configure: NativeBenchmarkBuilder.() -> Unit): NativeBenchmarkReport {
    val builder = NativeBenchmarkBuilder()
    builder.configure()
    return builder.execute()
}

class NativeBenchmarkBuilder {

    var name: String = "benchmark"

    var backend: String = ""

    var width: Int = 0

    var height: Int = 0

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
                backend = backend,
                width = width,
                height = height,
                samples = samples,
                environment =
                    buildEnvironment(
                        frontend = this,
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
    val backend: String,
    val width: Int,
    val height: Int,
    val samples: Array<DoubleArray>,
    val environment: String,
) {

    val batchAveragesMs: List<Double> = samples.map { batch -> batch.average() }

    val stats: BenchmarkStats = BenchmarkStats(sortedSamples(flatten(samples)))

    /** Pixels/s at the median, for parity with the old runner's MPix/s column. */
    val medianMPixSec: Double =
        if (width > 0 && height > 0) {
            (width.toDouble() * height / (stats.medianMs / 1_000.0)) / 1_000_000.0
        } else {
            0.0
        }

    fun print() {
        println(
            buildString {
                appendLine("=== Benchmark: $name ($backend) ${sizeLabel()} ===")
                append(environment)
                appendLine("batchAverageMs=${batchAveragesMs.joinToString(",") { formatMs(it) }}")
                append(
                    "stats(count=${stats.count}) " +
                        "min=${formatMs(stats.minMs)} " +
                        "p90=${formatMs(stats.p90Ms)} " +
                        "median=${formatMs(stats.medianMs)} " +
                        "mean=${formatMs(stats.meanMs)} " +
                        "p95=${formatMs(stats.p95Ms)} " +
                        "max=${formatMs(stats.maxMs)} " +
                        "\n"
                )
            }
        )
    }

    /**
     * Writes two CSVs:
     *  - `benchmarks_device_harness_<name>.csv` — one summary row, glob-compatible with the
     *    existing `runDeviceBenchmark` pull task (spec §24 deliverable 4);
     *  - `benchmarks_harness_detail_<name>.csv` — environment block + per-sample rows.
     */
    fun writeCsv(context: Context) {
        val dir = context.externalCacheDir
        // Backend + size in the name: a kernel run makes one file per backend.
        val fileBase =
            cleanName(name) + "_" + cleanName(backend.ifBlank { "all" }) + "_" + sizeLabel()

        val summary = File(dir, "benchmarks_device_harness_$fileBase.csv")
        summary.writeText(
            buildString {
                append("Kernel,Backend,Size,MinMs,MedianMs,MeanMs,MaxMs,P90,P95,P99,StdDevMs,MPix/s\n")
                appendFormatLn(
                    Locale.US,
                    "%s,%s,%s,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.2f",
                    name,
                    backend.ifBlank { "-" },
                    sizeLabel(),
                    stats.minMs,
                    stats.medianMs,
                    stats.meanMs,
                    stats.maxMs,
                    stats.p90Ms,
                    stats.p95Ms,
                    stats.p99Ms,
                    stats.stdDevMs,
                    medianMPixSec,
                )
            }
        )

        val detail = File(dir, "benchmarks_harness_detail_$fileBase.csv")
        detail.writeText(
            buildString {
                environment.lineSequence()
                    .filter { it.isNotBlank() }
                    .forEach { append("env,").append(it).append('\n') }
                append("batch,iteration,ms\n")
                for ((b, batch) in samples.withIndex()) {
                    for ((i, ms) in batch.withIndex()) {
                        append(b).append(',').append(i).append(',')
                            .append(String.format(Locale.US, "%.4f", ms)).append('\n')
                    }
                }
            }
        )
        println("Harness summary: ${summary.absolutePath}")
        println("Harness detail: ${detail.absolutePath}")
    }

    private fun sizeLabel(): String =
        if (width > 0 && height > 0) "${width}x${height}" else "-"

    private fun StringBuilder.appendFormatLn(
        locale: Locale,
        format: String,
        vararg args: Any?
    ) {
        append(String.format(locale, format, *args)).append('\n')
    }

    private fun cleanName(raw: String): String = raw.replace(Regex("[^A-Za-z0-9_.-]"), "_")

    private fun flatten(batches: Array<DoubleArray>): DoubleArray {
        val total = batches.sumOf { it.size }
        val out = DoubleArray(total)
        var i = 0
        for (batch in batches) {
            for (value in batch) out[i++] = value
        }
        return out
    }

    private fun formatMs(value: Double): String = String.format(Locale.US, "%.4f", value)
}

/** Builds the spec §16 environment block (key=value lines). */
private fun buildEnvironment(
    frontend: NativeBenchmarkBuilder,
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
        appendLine("warmupIterations=${frontend.warmupIterations}")
        appendLine("measurementBatches=${frontend.measurementBatches}")
        appendLine("iterationsPerBatch=${frontend.iterationsPerBatch}")
        appendLine("cooldownSeconds=${frontend.cooldownSeconds}")
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