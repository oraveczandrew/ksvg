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

import hu.oandras.ksvg.filtering.BenchmarkArguments
import hu.oandras.ksvg.filtering.BenchmarkCase
import hu.oandras.ksvg.filtering.KernelBenchmarkSink
import hu.oandras.ksvg.filtering.backendName
import hu.oandras.ksvg.filtering.getBackendsFor
import hu.oandras.ksvg.filtering.getTestTargetContext

/**
 * Device implementation of [KernelBenchmarkSink]: every cell runs through the stable
 * `nativeBenchmark { }` harness (spec `tmp/TEST_HARNESS.md`; TEST_HARNESS_PLAN) as its own
 * harness block, so every cell shares the same stabilizers (foreground window + focus wait,
 * thread-priority bump, warmup, per-batch cache normalization, optional warmup-calibrated
 * batch counts, thermal gating with cooldown/retry, and the five-way classification
 * VALID / THERMAL_THROTTLED / THERMAL_RECOVERY / UNSTABLE / INSUFFICIENT_SAMPLES). Results
 * are written as summary and detail CSV per cell plus the printed environment/stats block.
 *
 * Owns the device timing policy [KernelBenchmarkSink] does not standardize: the warmup /
 * measurement-batch / calibration constants and the throughput byte accounting
 * (`bytesPerPixel = 4 * numBuffers`, matching the host runner's `4 * numBuffers` convention).
 *
 * Optional per-cell simpleperf profiling (opt-in; the default run is byte-identical to a
 * run without profiling):
 *  - `benchmark.simpleperf` = `true` profiles every measured cell (native backends + the
 *    Kotlin reference) in its own thread-scoped window AFTER the timing cell — simpleperf
 *    overhead never enters the reported MPix/s.
 *  - `benchmark.simpleperf.events` = comma- or plus-separated events (validated against
 *    `simpleperf list` on the device; default `cpu-cycles,instructions`). When the value is
 *    forwarded through AGP's `-Pandroid.testInstrumentationRunnerArguments.*`, use `+` as the
 *    separator — AGP coerces a comma-separated instrumentation value down to its first element.
 *  - `benchmark.simpleperf.durationMs` = profile window in ms (default 2000).
 *  - `benchmark.simpleperf.pinCore` = optional CPU index for the profile window
 *    (default: unpinned, like the timing harness).
 * Profiles land in the suite's result subdirectory as
 * `benchmarks/<suite>/simpleperf_benchmark_<Kernel>_<Backend>_<W>x<H>`
 * `.txt`/`.csv` and are pulled+printed by `runDeviceBenchmark`.
 *
 * @param suite owning benchmark suite; selects the `benchmarks/<suite>/` result
 * subdirectory so classes sharing one instrumentation run never touch each
 * other's files.
 */
class DeviceBenchmarkSink(
    private val arguments: BenchmarkArguments,
    private val suite: String,
) : KernelBenchmarkSink {

    private val simpleperfProfiler: SimpleperfProfiler? =
        if (arguments.simpleperfEnabled) SimpleperfProfiler(getTestTargetContext()) else null

    private val simpleperfAvailable: Boolean = simpleperfProfiler?.isAvailable() ?: false

    private val supportedEvents: List<String> =
        if (simpleperfAvailable) {
            simpleperfProfiler!!.supportedEvents(arguments.requestedSimplePerfEvents)
        } else {
            emptyList()
        }

    init {
        if (arguments.simpleperfEnabled) {
            if (supportedEvents.isEmpty()) {
                println("Simpleperf: profiling requested but no supported events resolved; skipping all profiles")
            } else {
                println("Simpleperf: resolved events -> ${supportedEvents.joinToString(",")}")
            }
        }
    }

    override fun runKotlin(case: BenchmarkCase, work: () -> Unit) {
        val bytesPerPixel = case.numBuffers * 4
        nativeBenchmark {
            this.name = case.config.name
            this.suite = this@DeviceBenchmarkSink.suite
            backend = "kotlin"
            this.width = case.width
            this.height = case.height
            warmupIterations = WARMUP_ITERATIONS
            measurementBatches = MEASUREMENT_BATCHES
            iterationsPerBatch = iterationsForSize(case)
            targetBatchMillis = TARGET_BATCH_MILLIS
            maxIterationsPerBatch = MAX_ITERATIONS_PER_BATCH
            this.bytesPerPixel = bytesPerPixel
            thermalGatingEnabled = arguments.thermalGatingEnabled
            run(work)
        }
        profileCell(case, "kotlin") { work() }
    }

    override fun runNative(case: BenchmarkCase, work: (simdBackend: Int) -> Unit) {
        val bytesPerPixel = case.numBuffers * 4
        for (b in getBackendsFor(case.backendFlags)) {
            nativeBenchmark {
                this.name = case.config.name
                this.suite = this@DeviceBenchmarkSink.suite
                backend = backendName(b)
                width = case.width
                height = case.height
                warmupIterations = WARMUP_ITERATIONS
                measurementBatches = MEASUREMENT_BATCHES
                // Fewer iterations per batch at 2048x2048 so the large-kernel cells stay
                // bounded (old runner used 20/2); batch-average CV needs only ~3-5 samples.
                iterationsPerBatch = iterationsForSize(case)
                targetBatchMillis = TARGET_BATCH_MILLIS
                maxIterationsPerBatch = MAX_ITERATIONS_PER_BATCH
                this.bytesPerPixel = bytesPerPixel
                thermalGatingEnabled = arguments.thermalGatingEnabled
                run { work(b) }
            }
            profileCell(case, backendName(b)) { work(b) }
        }
    }

    /**
     * Upper bound on harness iterations for one matrix sweep, for the [BenchmarkViewModel]
     * global progress bar. Calibration and thermal retries adjust the live total afterwards
     * (`commitCellPlan` / `addInvalidatedIterations`), so this is only the static estimate.
     * The warmup term uses [MIN_CALIBRATION_SAMPLES] (not [WARMUP_ITERATIONS]) because this
     * sink always enables warmup-based calibration, whose warmup loop runs until that bound
     * (or the wall budget) — it must never seed a total smaller than the harness runs.
     */
    fun estimatedTotalRuns(matrix: List<BenchmarkCase>): Int {
        var total = 0
        for (case in matrix) {
            val backends = getBackendsFor(case.backendFlags)
            total += (1 + backends.size) * (MIN_CALIBRATION_SAMPLES + MEASUREMENT_BATCHES * iterationsForSize(case))
        }
        return total
    }

    /**
     * Profiles one cell in its own simpleperf window on the SAME thread as the timing cell
     * (thread-scoped counters, GC/alloc threads excluded). Runs only when profiling was
     * requested and the device exposes `simpleperf`. The profile window shares the cell's
     * work but is entirely separate from the timing iterations, so profiling never
     * changes the reported MPix/s.
     */
    private fun profileCell(case: BenchmarkCase, backend: String, work: () -> Unit) {
        val profiler = simpleperfProfiler ?: return
        if (!simpleperfAvailable) return
        val events = supportedEvents
        if (events.isEmpty()) return
        profiler.profile(
            name = "benchmark_${sanitizeName(case.config.name)}_${sanitizeName(backend)}_${case.width}x${case.height}",
            suite = suite,
            events = events,
            durationMs = arguments.simpleperfDurationMs,
            cpuCore = arguments.simplePerfPinCore,
            work = work,
        )
    }

    private fun sanitizeName(raw: String): String = raw.replace(SANITIZE_NAME_REGEX, "_")

    private fun iterationsForSize(case: BenchmarkCase): Int {
        return if (case.width * case.height <= 512 * 512) ITERATIONS_512 else ITERATIONS_2048
    }

    private companion object {

        const val WARMUP_ITERATIONS = 10

        const val MEASUREMENT_BATCHES = 5

        const val ITERATIONS_512 = 10

        const val ITERATIONS_2048 = 3

        /**
         * Warmup-calibrated target batch duration (ms): short kernels (sub-ms at 512²) get
         * more iterations per batch so the batch-average-CV classifier averages out
         * per-iteration timer/GC noise instead of flagging the cell UNSTABLE.
         */
        const val TARGET_BATCH_MILLIS = 100L

        /**
         * Upper cap on calibration, so very fast kernels cannot stretch one batch beyond
         * the target duration.
         */
        const val MAX_ITERATIONS_PER_BATCH = 200

        private val SANITIZE_NAME_REGEX = Regex("[^A-Za-z0-9_.-]")
    }
}