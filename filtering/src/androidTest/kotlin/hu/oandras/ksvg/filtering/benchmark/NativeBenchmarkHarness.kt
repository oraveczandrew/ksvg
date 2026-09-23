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

@file:OptIn(ExperimentalContracts::class)

package hu.oandras.ksvg.filtering.benchmark

import android.content.Context
import android.os.Build
import android.os.Process
import android.os.SystemClock
import hu.oandras.ksvg.filtering.getTestTargetContext
import java.io.File
import java.util.*
import kotlin.contracts.ExperimentalContracts
import kotlin.contracts.InvocationKind
import kotlin.contracts.contract

/** Device cache subdirectory holding every benchmark result file. */
internal const val BENCHMARKS_DIR_NAME = "benchmarks"

/**
 * Clears one benchmark suite's previous result files (`benchmarks/<suite>/` in the
 * device's external cache directory, spec §24), so a fresh run is not mixed with
 * stale files on pull. Each benchmark class calls this in its setup with its own
 * [SUITE]-style name: per-suite subdirectories make cross-class deletion
 * structurally impossible within a shared instrumentation run.
 */
fun clearSuiteResults(suite: String) {
    val cacheDir = getTestTargetContext().externalCacheDir ?: return
    if (!cacheDir.exists()) return
    val dir = File(cacheDir, "$BENCHMARKS_DIR_NAME/$suite")
    if (!dir.exists()) return
    val files = dir.listFiles()
    val totalDeleted = files?.size ?: 0
    files?.forEach { it.delete() }
    if (totalDeleted > 0) {
        println("Benchmark harness: cleared $totalDeleted previous result files from ${dir.absolutePath}")
    }
}

/**
 * Public DSL + orchestration for the stable native benchmark harness
 * (TEST_HARNESS_PLAN.md Step 1-2; spec §12, §13, §14, §17, §19).
 *
 * The benchmark test only describes the workload:
 *
 * ```
 * nativeBenchmark {
 *     name = "Turbulence"
 *     suite = "kernelBenchmark"
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
     * measurement loop with per-iteration `System.nanoTime()` sampling, thermal gating
     * ([ThermalStateMonitor], spec §6/§7: batches measured while throttled are dropped),
     * optional warmup-based batch calibration — set [NativeBenchmarkBuilder.targetBatchMillis]
     * to time the warmup and scale the per-batch iteration count toward a target batch
     * duration, so sub-ms kernels average out per-iteration timer/GC noise — per-sample
     * statistics ([BenchmarkStats], spec §14), and an environment report. The
     * measured region is exactly the [run] block (spec §20: no logging, I/O, thermal reads
     * or GC inside it).
     *
     * Later steps add cache normalization, CPU-frequency info, and the validation-vs-raw
     * comparison.
     */
fun nativeBenchmark(configure: NativeBenchmarkBuilder.() -> Unit): NativeBenchmarkReport {
    contract {
        callsInPlace(configure, InvocationKind.EXACTLY_ONCE)
    }

    val builder = NativeBenchmarkBuilder()
    builder.configure()
    return builder.execute()
}

class NativeBenchmarkBuilder {

    @JvmField
    var name: String = "benchmark"

    /**
     * Result suite (owning benchmark class, e.g. `"kernelBenchmark"`). Results land in
     * `benchmarks/<suite>/`, so classes sharing one instrumentation run can never
     * delete or overwrite each other's files.
     */
    @JvmField
    var suite: String = "default"

    @JvmField
    var backend: String = ""

    @JvmField
    var width: Int = 0

    @JvmField
    var height: Int = 0

    @JvmField
    var warmupIterations: Int = 20

    @JvmField
    var measurementBatches: Int = 5

    @JvmField
    var iterationsPerBatch: Int = 10

    /**
     * Warmup-based batch calibration (short-kernel fix): when `> 0`, every warmup iteration
     * is timed with the same `System.nanoTime()` sampling, the median warmup time becomes
     * the per-iteration estimate, and the batch count is derived from [targetBatchMillis]
     * (clamped to `iterationsPerBatch..max(iterationsPerBatch, maxIterationsPerBatch)`).
     * Sub-ms cells then gather enough samples per batch for the batch-average CV rule to
     * average out per-iteration timer/GC noise (~1/√n). `0` disables calibration and keeps
     * the legacy exact-`iterationsPerBatch` behavior.
     */
    @JvmField
    var targetBatchMillis: Long = 0L

    /**
     * Upper cap for the [targetBatchMillis] calibration so a very fast kernel cannot stretch
     * one batch far beyond the target duration.
     */
    @JvmField
    var maxIterationsPerBatch: Int = 200

    /**
     * Bytes read+written per pixel by the measured kernel (4 bytes/pixel × buffer count),
     * used to derive the GB/s throughput column (`GB/s = MPix/s × bytesPerPixel / 1000`,
     * matching the host runner's `4 × numBuffers` convention). Defaults to 8 (ARGB in +
     * ARGB out). Two-source composite kernels (DisplacementMap, ArithmeticComposite) use 12;
     * pure generators that only write output (Turbulence) use 4.
     */
    @JvmField
    var bytesPerPixel: Int = 8

    /**
     * When `false`, the thermal gate is disabled: batches are never invalidated by the
     * thermal monitor. Intended for deterministic environments (emulators, CI) where the
     * API<29 fallback compute-probe is noisy without representing real throttling; real
     * devices keep this enabled.
     */
    @JvmField
    var thermalGatingEnabled: Boolean = true

    /**
     * If set, pins the benchmark thread to this concrete Linux CPU for warmup + all
     * measurement batches (diagnostic runs only, e.g. Lighting scalar-vs-NEON). The
     * chosen core is reported as `benchmarkCpu=<N>` in the environment block.
     * `sched_setaffinity` may be denied without root; the pin then fails quietly and
     * `affinityApplied=false` is reported so the run is not mistaken for pinned.
     */
    @JvmField
    var cpuCore: Int? = null

    /**
     * Sleep before retrying a batch invalidated by thermal throttling (spec §9). Actual
     * sleep duration accumulates into the report's `cooldownTimeMs`.
     */
    @JvmField
    var cooldownMillis: Long = 5_000

    private var body: (() -> Unit)? = null

    /** Last wall-clock timestamp a progress state was pushed (rate-limit for the UI). */
    private var lastProgressPushMs = -1L

    /** Live per-cell technical state; mutated by [execute] and snapshotted by [publishProgress]. */
    private var currentTask = BenchmarkTask()

    /** The measured region: the native kernel call and nothing else. */
    fun run(runBody: () -> Unit) {
        body = runBody
    }

    internal fun execute(): NativeBenchmarkReport {
        val kernel = requireNotNull(body) { "nativeBenchmark { run { ... } } is required" }
        val startedAt = SystemClock.elapsedRealtime()

        // Live task state for the Activity: the static config first, the dynamic fields
        // (warmup samples, effective per-batch count, batch count) are updated while running.
        currentTask.benchmark = name
        currentTask.backend = backend
        currentTask.width = width
        currentTask.height = height
        currentTask.calibrationActive = targetBatchMillis > 0L
        currentTask.thermalGatingEnabled = thermalGatingEnabled
        currentTask.targetBatchMillis = targetBatchMillis
        currentTask.requestedIterationsPerBatch = iterationsPerBatch
        currentTask.maxIterationsPerBatch = maxIterationsPerBatch
        currentTask.requestedBatches = measurementBatches
        currentTask.phase = "FOCUSING"
        currentTask.iteration = 0
        currentTask.iterationTotal = 1
        // The cell's static iteration estimate stays in the global total until
        // `commitCellPlan` swaps it for the real post-calibration plan. Keeping the estimate
        // in the denominator while the cell runs means the total always covers the
        // iterations already executed (no current/total overshoot during warmup). When
        // calibration is active the warmup loop may run up to [MIN_CALIBRATION_SAMPLES]
        // samples (not `warmupIterations`), so the estimate must use that bound.
        val staticEstimate =
            (
                if (targetBatchMillis > 0L) MIN_CALIBRATION_SAMPLES else warmupIterations
                ) +
                measurementBatches * iterationsPerBatch
        publishProgress(startedAt, BenchmarkUiStatus.RUNNING)
        BenchmarkActivity.waitForFocusedWindow()

        val thermal = ThermalStateMonitor.create(getTestTargetContext())
        thermal.computeBaselineIfNeeded()
        val thermalStatusBefore = thermal.currentThermalStatus()

        val tid = Process.myTid()
        val previousPriority = capturePriority(tid)
        val pinnedCore = cpuCore
        var affinityApplied = false
        if (pinnedCore != null) {
            affinityApplied = CpuAffinity.pinToCore(pinnedCore)
            if (!affinityApplied) {
                println(
                    "Benchmark harness: WARNING sched_setaffinity(cpu$pinnedCore) failed; " +
                        "this run is NOT pinned to the requested core"
                )
            }
        }
        val cpuFreqBeforeKhz = CpuInfo.cpuFreqKhz(pinnedCore ?: 0)

        val validBatches = ArrayList<DoubleArray>(measurementBatches)
        var threadPriorityApplied: Boolean
        var thermalThrottled = false
        var invalidatedBatches = 0
        var cooldownTimeMs = 0L
        var benchCpuAfter: Int
        var calibratedPerIterationMs = 0.0
        val effectiveIterationsPerBatch: Int
        try {
            val calibrationActive = targetBatchMillis > 0L
            currentTask.calibrationActive = calibrationActive
            val warmupActualIterations: Int
            if (!calibrationActive) {
                // Legacy path: untimed warmup, fixed iterationsPerBatch per batch.
                var iteration = 0
                currentTask.phase = "WARMUP"
                while (iteration < warmupIterations) {
                    iteration++
                    currentTask.iteration = iteration
                    currentTask.iterationTotal = warmupIterations
                    BenchmarkViewModel.advanceGlobalProgress()
                    publishProgress(startedAt, BenchmarkUiStatus.RUNNING)
                    kernel.invoke()
                }
                warmupActualIterations = warmupIterations
                effectiveIterationsPerBatch = iterationsPerBatch
                currentTask.effectiveIterationsPerBatch = effectiveIterationsPerBatch
            } else {
                // Calibration path: time the warmup iterations with the same nanoTime
                // sampling. The 25th percentile is robust even when a GC/JIT storm inflates a
                // large share of the samples; it calibrates the batch so short kernels gather
                // enough samples to average out per-iteration timer/GC noise. Multi-second
                // cells stop early at [MAX_WARMUP_WALL_MS] — for them the precise estimate is
                // irrelevant because the derived batch count already floors to the minimum.
                val warmupTimes = DoubleArray(MIN_CALIBRATION_SAMPLES)
                var iteration = 0
                var warmupWallMs = 0L
                currentTask.phase = "WARMUP"
                while (
                    iteration < MIN_CALIBRATION_SAMPLES &&
                    warmupWallMs < MAX_WARMUP_WALL_MS
                ) {
                    iteration++
                    currentTask.iteration = iteration
                    currentTask.iterationTotal = MIN_CALIBRATION_SAMPLES
                    currentTask.warmupSamples = iteration
                    currentTask.warmupWallMs = warmupWallMs
                    BenchmarkViewModel.advanceGlobalProgress()
                    publishProgress(startedAt, BenchmarkUiStatus.RUNNING)
                    val t0 = System.nanoTime()
                    kernel.invoke()
                    val t1 = System.nanoTime()
                    val sampleMs = (t1 - t0) / 1_000_000.0
                    warmupWallMs += sampleMs.toLong()
                    warmupTimes[iteration - 1] = sampleMs
                }
                warmupActualIterations = iteration
                currentTask.warmupSamples = warmupActualIterations
                currentTask.warmupWallMs = warmupWallMs
                warmupTimes.sort(0, warmupActualIterations)
                calibratedPerIterationMs =
                    robustShortIterationMs(warmupTimes, warmupActualIterations)
                effectiveIterationsPerBatch =
                    if (calibratedPerIterationMs > 0.0) {
                        val cap = maxOf(iterationsPerBatch, maxIterationsPerBatch)
                        (targetBatchMillis.toDouble() / calibratedPerIterationMs).toInt()
                            .coerceIn(iterationsPerBatch, cap)
                    } else {
                        maxOf(iterationsPerBatch, maxIterationsPerBatch)
                    }
                currentTask.effectiveIterationsPerBatch = effectiveIterationsPerBatch
            }
            // The real per-cell plan is known once calibration fixed the per-batch count
            // (warmup + batches x effective per batch). Swap the static estimate for the
            // real plan (the delta is negative for slow cells whose warmup hit the wall
            // budget). Thermal invalidation re-runs a batch later and adds its iterations.
            BenchmarkViewModel.commitCellPlan(
                staticEstimate,
                warmupActualIterations + measurementBatches * effectiveIterationsPerBatch
            )

            // Batches are gated on thermal state (spec §6/§9): a batch measured while
            // throttled is invalidated (not counted) -> cooldown sleep -> fresh batch.
            var attempted = 0
            val maxAttempts = maxOf(measurementBatches * 3, measurementBatches + 8)
            while (validBatches.size < measurementBatches && attempted < maxAttempts) {
                attempted++
                if (thermalGatingEnabled && thermal.isThrottled()) {
                    thermalThrottled = true
                    currentTask.invalidatedBatches = ++invalidatedBatches
                    currentTask.phase = "THERMAL GATE"
                    currentTask.iteration = validBatches.size
                    currentTask.iterationTotal = measurementBatches
                    // The rejected batch would have run `effective` iterations; keep the
                    // live global total honest across the retry.
                    BenchmarkViewModel.addInvalidatedIterations(effectiveIterationsPerBatch)
                    publishProgress(
                        startedAt,
                        BenchmarkUiStatus.COOLING,
                        "Thermal gate rejected the next batch",
                    )
                    cooldownTimeMs += cooldown()
                    currentTask.cooldownMillis = cooldownTimeMs
                    continue
                }
                // Flush CPU-cache state left by the previous batch (spec §8; outside
                // the measured region — no kernel call, no timing here).
                CacheNormalizer.normalize()
                val batch = DoubleArray(effectiveIterationsPerBatch)
                val batchIndex = validBatches.size + 1
                currentTask.phase = "MEASUREMENT BATCH $batchIndex"
                currentTask.iterationTotal = effectiveIterationsPerBatch
                for (i in 0 until effectiveIterationsPerBatch) {
                    currentTask.iteration = i + 1
                    BenchmarkViewModel.advanceGlobalProgress()
                    publishProgress(startedAt, BenchmarkUiStatus.RUNNING)
                    val t0 = System.nanoTime()
                    kernel.invoke()
                    val t1 = System.nanoTime()
                    batch[i] = (t1 - t0) / 1_000_000.0
                }
                if (thermalGatingEnabled && thermal.isThrottled()) {
                    // Status rose while the batch was being measured -> invalid (spec §6).
                    thermalThrottled = true
                    currentTask.invalidatedBatches = ++invalidatedBatches
                    currentTask.phase = "THERMAL RECOVERY"
                    currentTask.iteration = validBatches.size
                    currentTask.iterationTotal = measurementBatches
                    BenchmarkViewModel.addInvalidatedIterations(effectiveIterationsPerBatch)
                    publishProgress(
                        startedAt,
                        BenchmarkUiStatus.THERMAL_RECOVERY,
                        "Measured batch invalidated by thermal throttling",
                    )
                    cooldownTimeMs += cooldown()
                    currentTask.cooldownMillis = cooldownTimeMs
                    continue
                }
                validBatches.add(batch)
                currentTask.validBatches = validBatches.size
            }
        } catch (t: Throwable) {
            currentTask.phase = "FAILED"
            currentTask.iteration = validBatches.size
            currentTask.iterationTotal = measurementBatches
            publishProgress(
                startedAt,
                BenchmarkUiStatus.FAILED,
                t.message ?: t::class.java.simpleName,
            )
            throw t
        } finally {
            benchCpuAfter = CpuAffinity.currentCpu()
            threadPriorityApplied = restorePriority(tid, previousPriority)
            if (affinityApplied) {
                CpuAffinity.resetAffinity()
            }
        }

        val thermalStatusAfter = thermal.currentThermalStatus()
        val cpuFreqAfterKhz = CpuInfo.cpuFreqKhz(pinnedCore ?: 0)

        val report =
            NativeBenchmarkReport(
                name = name,
                backend = backend,
                suite = suite,
                width = width,
                height = height,
                samples = validBatches.toTypedArray(),
                requestedBatches = measurementBatches,
                thermalThrottled = thermalThrottled,
                invalidatedBatches = invalidatedBatches,
                cooldownTimeMs = cooldownTimeMs,
                bytesPerPixel = bytesPerPixel,
                environment =
                    buildEnvironment(
                        frontend = this,
                        threadPriorityApplied = threadPriorityApplied,
                        thermalStatusBefore = thermalStatusBefore,
                        thermalStatusAfter = thermalStatusAfter,
                        thermalThrottled = thermalThrottled,
                        thermalSource = thermal.source,
                        invalidatedBatches = invalidatedBatches,
                        cooldownTimeMs = cooldownTimeMs,
                        cpuFreqBeforeKhz = cpuFreqBeforeKhz,
                        cpuFreqAfterKhz = cpuFreqAfterKhz,
                        pinnedCore = pinnedCore,
                        affinityApplied = affinityApplied,
                        benchCpuAfter = benchCpuAfter,
                        calibratedPerIterationMs = calibratedPerIterationMs,
                        effectiveIterationsPerBatch = effectiveIterationsPerBatch,
                    ),
            )
        report.print()
        report.writeCsv(getTestTargetContext())
        currentTask.phase = "COMPLETED"
        currentTask.iteration = measurementBatches
        currentTask.iterationTotal = measurementBatches
        currentTask.validBatches = validBatches.size
        currentTask.cooldownMillis = cooldownTimeMs
        publishProgress(
            startedAt,
            BenchmarkUiStatus.COMPLETED,
            "classification=${report.classification}",
        )
        return report
    }

    private fun publishProgress(
        startedAt: Long,
        status: BenchmarkUiStatus,
        message: String = "",
    ) {
        currentTask.status = status
        currentTask.message = message
        // Rate-limited: pushing a fresh BenchmarkUiState per iteration allocates enough to
        // park the GC in the middle of measured batches. Always push on phase/batch start and
        // on terminal states; otherwise at ~PROGRESS_PUSH_INTERVAL_MS granularity only.
        val now = SystemClock.elapsedRealtime()
        val mustPush =
            currentTask.iteration <= 1 ||
                status == BenchmarkUiStatus.COMPLETED ||
                status == BenchmarkUiStatus.FAILED ||
                now - lastProgressPushMs >= PROGRESS_PUSH_INTERVAL_MS
        if (!mustPush) return
        lastProgressPushMs = now
        BenchmarkViewModel.publishProgress(
            BenchmarkUiState(
                benchmark = currentTask.benchmark,
                backend = currentTask.backend,
                size =
                    if (currentTask.width > 0 && currentTask.height > 0) {
                        "${currentTask.width}x${currentTask.height}"
                    } else {
                        "-"
                    },
                phase = currentTask.phase,
                iteration = currentTask.iteration,
                totalIterations = currentTask.iterationTotal,
                status = status,
                invalidatedBatches = currentTask.invalidatedBatches,
                cooldownMillis = currentTask.cooldownMillis,
                elapsedMillis = SystemClock.elapsedRealtime() - startedAt,
                globalCurrentRun = BenchmarkViewModel.currentGlobalRun(),
                globalRun = BenchmarkViewModel.totalGlobalRuns(),
                message = message,
                calibrationActive = currentTask.calibrationActive,
                thermalGatingEnabled = currentTask.thermalGatingEnabled,
                targetBatchMillis = currentTask.targetBatchMillis,
                requestedIterationsPerBatch = currentTask.requestedIterationsPerBatch,
                maxIterationsPerBatch = currentTask.maxIterationsPerBatch,
                requestedBatches = currentTask.requestedBatches,
                validBatches = currentTask.validBatches,
                warmupSamples = currentTask.warmupSamples,
                warmupWallMs = currentTask.warmupWallMs,
                effectiveIterationsPerBatch = currentTask.effectiveIterationsPerBatch,
            )
        )
    }

    /**
     * Blocks for the configured cooldown (spec §9) and returns the actual elapsed time.
     * Uses `SystemClock.sleep` so an interrupt never truncates the recovery; the measured
     * region is untouched — no kernel call happens here.
     */
    private fun cooldown(): Long {
        val start = SystemClock.elapsedRealtime()
        SystemClock.sleep(cooldownMillis)
        return SystemClock.elapsedRealtime() - start
    }
}

class NativeBenchmarkReport(
    @JvmField
    val name: String,
    @JvmField
    val backend: String,
    /** Owning benchmark suite; selects the `benchmarks/<suite>/` result subdirectory. */
    @JvmField
    val suite: String,
    @JvmField
    val width: Int,
    @JvmField
    val height: Int,
    @JvmField
    val samples: Array<DoubleArray>,
    @JvmField
    val requestedBatches: Int,
    @JvmField
    val thermalThrottled: Boolean,
    @JvmField
    val invalidatedBatches: Int,
    @JvmField
    val cooldownTimeMs: Long,
    @JvmField
    val bytesPerPixel: Int,
    @JvmField
    val environment: String,
) {

    @JvmField
    val batchAveragesMs: List<Double> = samples.map { batch -> batch.average() }

    @JvmField
    val stats: BenchmarkStats = BenchmarkStats(sortedSamples(flatten(samples)))

    /** Pixels/s at the median, for parity with the old runner's MPix/s column. */
    @JvmField
    val medianMPixSec: Double =
        if (width > 0 && height > 0) {
            (width.toDouble() * height / (stats.medianMs / 1_000.0)) / 1_000_000.0
        } else {
            0.0
        }

    /**
     * GB/s at the median: `medianMPixSec × bytesPerPixel / 1000` (bytes per pixel ×
     * megapixels per second ÷ 1000). Matches the host runner's `4 × numBuffers` convention.
     */
    @JvmField
    val medianGBsSec: Double =
        if (medianMPixSec > 0.0) {
            medianMPixSec * bytesPerPixel / 1000.0
        } else {
            0.0
        }

    /**
     * Result classification (spec §15): `VALID / THERMAL_THROTTLED / THERMAL_RECOVERY /
     * UNSTABLE / INSUFFICIENT_SAMPLES`.
     *
     *  - `INSUFFICIENT_SAMPLES` — no batch collected, or fewer than requested without any
     *    thermal event (attempt cap exhausted).
     *  - `THERMAL_THROTTLED` — throttling occurred, and the run ended with fewer batches than
     *    requested.
     *  - `THERMAL_RECOVERY` — throttling occurred, but all requested batches were still
     *    collected afterward.
     *  - `UNSTABLE` — all batches collected, no throttling, but batch averages spread too
     *    widely (CV above [UNSTABLE_CV]).
     *  - `VALID` — otherwise.
     */
    @JvmField
    val classification: String =
        when {
            samples.isEmpty() -> INSUFFICIENT_SAMPLES
            thermalThrottled && samples.size < requestedBatches -> THERMAL_THROTTLED
            thermalThrottled -> THERMAL_RECOVERY
            samples.size < requestedBatches -> INSUFFICIENT_SAMPLES
            batchCv > UNSTABLE_CV -> UNSTABLE
            else -> VALID
        }

    val isValid: Boolean
        get() = classification == VALID

    /** Coefficient of variation of the batch averages (population). */
    private val batchCv: Double
        get() {
            if (batchAveragesMs.size < 2) return 0.0
            val mean = batchAveragesMs.average()
            if (mean <= 0.0) return 0.0
            val variance =
                batchAveragesMs.sumOf { avg -> (avg - mean) * (avg - mean) } / batchAveragesMs.size
            return kotlin.math.sqrt(variance) / mean
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
                appendLine(
                    "classification=$classification valid=$isValid " +
                        "invalidatedBatches=$invalidatedBatches cooldownTimeMs=$cooldownTimeMs"
                )
                appendLine(
                    String.format(
                        Locale.US,
                        "throughput medianMPixSec=%.2f medianGBsSec=%.2f bytesPerPixel=%d",
                        medianMPixSec,
                        medianGBsSec,
                        bytesPerPixel,
                    )
                )
            }
        )
    }

    /**
     * Writes two CSVs into `benchmarks/<suite>/`:
     *  - `benchmarks_device_harness_<name>.csv` — one summary row, glob-compatible with the
     *    existing `runDeviceBenchmark` pull task (spec §24 deliverable 4);
     *  - `benchmarks_harness_detail_<name>.csv` — environment block and per-sample rows.
     */
    fun writeCsv(context: Context) {
        val cacheDir = context.externalCacheDir
        val dir = File(cacheDir, "$BENCHMARKS_DIR_NAME/$suite")
        dir.mkdirs()
        // Backend + size in the name: a kernel run makes one file per backend.
        val fileBase =
            cleanName(name) + "_" + cleanName(backend.ifBlank { "all" }) + "_" + sizeLabel()

        val escapedName = if (name.contains(",") || name.contains("\"")) "\"${name.replace("\"", "\"\"")}\"" else name
        val summary = File(dir, "benchmarks_device_harness_$fileBase.csv")
        summary.writeText(
            buildString {
                append(
                    "Kernel,Backend,Size,MinMs,MedianMs,MeanMs,MaxMs,P90,P95,P99,StdDevMs," +
                        "MPix/s,GB/s,InvalidatedBatches,CooldownMs,Classification,VALID\n"
                )
                appendFormatLn(
                    Locale.US,
                    "%s,%s,%s,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.2f,%.2f,%d,%d,%s,%b",
                    escapedName,
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
                    medianGBsSec,
                    invalidatedBatches,
                    cooldownTimeMs,
                    classification,
                    isValid,
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

    @Suppress("SameParameterValue")
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
    thermalStatusBefore: Int,
    thermalStatusAfter: Int,
    thermalThrottled: Boolean,
    thermalSource: String,
    invalidatedBatches: Int,
    cooldownTimeMs: Long,
    cpuFreqBeforeKhz: Int?,
    cpuFreqAfterKhz: Int?,
    pinnedCore: Int?,
    affinityApplied: Boolean,
    benchCpuAfter: Int,
    calibratedPerIterationMs: Double,
    effectiveIterationsPerBatch: Int,
): String =
    buildString {
        appendLine("device=${Build.DEVICE}")
        appendLine("model=${Build.MODEL}")
        appendLine("androidVersion=${Build.VERSION.SDK_INT}")
        appendLine("abi=${Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown"}")
        appendLine("cpuCoreCount=${Runtime.getRuntime().availableProcessors()}")
        appendLine("socManufacturer=${CpuInfo.socManufacturer}")
        appendLine("socModel=${CpuInfo.socModel}")
        appendLine("hardware=${CpuInfo.hardware}")
        appendLine("benchmarkCpu=${pinnedCore?.toString() ?: "unspecified"}")
        appendLine("affinityApplied=$affinityApplied")
        appendLine("benchThreadCpuAfter=$benchCpuAfter")
        appendLine("cpuFreqBeforeKhz=${cpuFreqBeforeKhz ?: "unavailable"}")
        appendLine("cpuFreqAfterKhz=${cpuFreqAfterKhz ?: "unavailable"}")
        appendLine("cpuTopology=${CpuTopology.summarize(CpuTopology.discoverTopology())}")
        appendLine(
            "sustainedPerformanceMode=" +
                (BenchmarkActivity.sustainedPerformanceModeInUse && BenchmarkActivity.sustainedSetResult != false)
        )
        appendLine("sustainedSetResult=${BenchmarkActivity.sustainedSetResult}")
        appendLine("thermalSource=$thermalSource")
        appendLine("thermalStatusBefore=$thermalStatusBefore")
        appendLine("thermalStatusAfter=$thermalStatusAfter")
        appendLine("thermalThrottled=$thermalThrottled")
        appendLine("thermalGatingEnabled=${frontend.thermalGatingEnabled}")
        appendLine("invalidatedBatches=$invalidatedBatches")
        appendLine("cooldownTimeMs=$cooldownTimeMs")
        appendLine("windowFocused=${BenchmarkActivity.isWindowFocused}")
        appendLine("warmupIterations=${frontend.warmupIterations}")
        appendLine("measurementBatches=${frontend.measurementBatches}")
        appendLine("iterationsPerBatch=${frontend.iterationsPerBatch}")
        appendLine("bytesPerPixel=${frontend.bytesPerPixel}")
        appendLine("requestedIterationsPerBatch=${frontend.iterationsPerBatch}")
        appendLine("effectiveIterationsPerBatch=$effectiveIterationsPerBatch")
        appendLine("targetBatchMillis=${frontend.targetBatchMillis}")
        appendLine("maxIterationsPerBatch=${frontend.maxIterationsPerBatch}")
        appendLine(
            "calibratedPerIterationMs=${String.format(Locale.US, "%.4f", calibratedPerIterationMs)}"
        )
        appendLine("cooldownMillis=${frontend.cooldownMillis}")
        appendLine("benchThreadPriority=$HIGH_PRIORITY")
        appendLine("threadPriorityApplied=$threadPriorityApplied")
    }

/** Result classifications (spec §15). */
private const val VALID = "VALID"
private const val THERMAL_THROTTLED = "THERMAL_THROTTLED"
private const val THERMAL_RECOVERY = "THERMAL_RECOVERY"
private const val UNSTABLE = "UNSTABLE"
private const val INSUFFICIENT_SAMPLES = "INSUFFICIENT_SAMPLES"

/** Batch-average CV above which an otherwise clean run is classified UNSTABLE (spec §15). */
private const val UNSTABLE_CV = 0.05

/**
 * Minimum warmup samples timed for batch calibration, so the robust per-iteration estimate
 * stays meaningful even when a GC/JIT storm inflates a large share of them.
 */
internal const val MIN_CALIBRATION_SAMPLES = 32

/**
 * Wall-clock budget for the timed warmup (calibration path). Fast kernels still collect the
 * full [MIN_CALIBRATION_SAMPLES]; multi-second cells (e.g. 2048x2048 scalar/kotlin) stop well
 * below it, so one cell cannot burn 32 x wall-time warmup samples.
 */
private const val MAX_WARMUP_WALL_MS = 10_000L

/** Minimum wall-clock interval between per-iteration UI progress pushes. */
private const val PROGRESS_PUSH_INTERVAL_MS = 100L

/** Highest Linux nice priority (best-effort like the platform docs; needs no root). */
private const val HIGH_PRIORITY = -20

private fun capturePriority(tid: Int): Int? {
    return try {
        val previous = Process.getThreadPriority(tid)
        Process.setThreadPriority(tid, HIGH_PRIORITY)
        previous
    } catch (_: Throwable) {
        null
    }
}

/**
 * Robust per-iteration estimate from the first `count` sorted warmup times: the 25th
 * percentile. Survives a GC/JIT storm inflating most of the samples — a plain median already
 * fails when >= half of a run's warmup iterations are swallowed by a pause. `sorted` may hold
 * up to [MIN_CALIBRATION_SAMPLES] entries but only the first `count` are filled (the warmup is
 * wall-budget capped, see [MAX_WARMUP_WALL_MS]).
 */
private fun robustShortIterationMs(sorted: DoubleArray, count: Int): Double {
    val idx = (count * 0.25).toInt().coerceAtMost(count - 1)
    return sorted[idx]
}

private fun restorePriority(tid: Int, previous: Int?): Boolean {
    return previous != null && try {
        Process.setThreadPriority(tid, previous)
        true
    } catch (_: Throwable) {
        false
    }
}