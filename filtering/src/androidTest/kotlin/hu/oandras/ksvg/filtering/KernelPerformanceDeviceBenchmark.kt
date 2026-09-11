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
import androidx.test.platform.app.InstrumentationRegistry
import hu.oandras.ksvg.filtering.benchmark.BenchmarkViewModel
import hu.oandras.ksvg.filtering.benchmark.SimpleperfProfiler
import hu.oandras.ksvg.filtering.benchmark.clearPreviousResults
import hu.oandras.ksvg.filtering.benchmark.nativeBenchmark
import org.junit.BeforeClass
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Device kernel benchmark running every native filter kernel through the stable
 * `nativeBenchmark { }` harness (spec `tmp/TEST_HARNESS.md`; TEST_HARNESS_PLAN), replacing
 * the old raw `KernelBenchmarkRunner` driver.
 *
 * Each (kernel, backend, size) cell is its own harness block, so every cell shares the same
 * stabilizers: foreground window + focus wait, thread-priority bump, warmup, per-batch cache
 * normalization, thermal gating with cooldown/retry, and the five-way classification
 * (VALID / THERMAL_THROTTLED / THERMAL_RECOVERY / UNSTABLE / INSUFFICIENT_SAMPLES). Results
 * are written as summary and detail CSV per cell (matching the `runDeviceBenchmark` pull glob
 * `benchmarks_device*.csv`) in addition to the printed environment/stats/classification.
 *
 * Keeps the legacy kernel-selection arguments:
 *  - `benchmark.kernel` = one of UnLinearize, ComponentTransfer, Morphology,
 *    ArithmeticComposite (both modes), ConvolveMatrix, DisplacementMap, Lighting,
 *    Turbulence, GaussianBlur; empty runs the full suite.
 *  - `benchmark.quick` = true runs 512x512 only (else 512x512 + 2048x2048).
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
 * Profiles land in the external cache as `simpleperf_benchmark_<Kernel>_<Backend>_<W>x<H>`
 * `.txt`/`.csv` and are pulled+printed by `runDeviceBenchmark`.
 */
@RunWith(AndroidJUnit4::class)
class KernelPerformanceDeviceBenchmark {

    companion object {

        @BeforeClass
        @JvmStatic
        fun setup() {
            assertNativeBackendAvailable()
            clearPreviousResults()
            val args = InstrumentationRegistry.getArguments()
            thermalGatingEnabled = args.getString("benchmark.thermalGating") != "false"
            simpleperfEnabled = args.getString("benchmark.simpleperf") == "true"
            if (simpleperfEnabled) {
                val profiler = SimpleperfProfiler(getTestTargetContext())
                simpleperfProfiler = profiler
                simpleperfAvailable = profiler.isAvailable()
                val requested = args.getString("benchmark.simpleperf.events")
                        ?.split(",", "+")
                        ?.map { it.trim() }
                        ?.filter { it.isNotEmpty() }
                        ?.takeIf { it.isNotEmpty() }
                        ?: DEFAULT_SIMPLEPERF_EVENTS.split(",")
                supportedEvents =
                    if (simpleperfAvailable) profiler.supportedEvents(requested) else emptyList()
                if (supportedEvents.isEmpty()) {
                    println("Simpleperf: profiling requested but no supported events resolved; skipping all profiles")
                } else {
                    println("Simpleperf: resolved events -> ${supportedEvents.joinToString(",")}")
                }
                val duration = args.getString("benchmark.simpleperf.durationMs")?.toLongOrNull()
                simpleperfDurationMs = if (duration != null && duration > 0) duration else DEFAULT_SIMPLEPERF_DURATION_MS
                simpleperfPinCore = args.getString("benchmark.simpleperf.pinCore")?.toIntOrNull()
            }
        }

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

        /** GB/s byte counts: ARGB read + ARGB write per pixel. */
        private const val BYTES_PER_PIXEL_RW = 8

        /** Two-source kernels also read a second input buffer per pixel. */
        private const val BYTES_PER_PIXEL_TWO_SOURCES = 12

        /** Pure generators only write the output buffer. */
        private const val BYTES_PER_PIXEL_GENERATE = 4

        private const val DEFAULT_SIMPLEPERF_EVENTS = "cpu-cycles,instructions"

        private const val DEFAULT_SIMPLEPERF_DURATION_MS = 2000L

        private val SANITIZE_NAME_REGEX = Regex("[^A-Za-z0-9_.-]")

        private var simpleperfEnabled: Boolean = false

        private var simpleperfAvailable: Boolean = false

        private var simpleperfProfiler: SimpleperfProfiler? = null

        private var supportedEvents: List<String> = emptyList()

        private var simpleperfDurationMs: Long = DEFAULT_SIMPLEPERF_DURATION_MS

        private var simpleperfPinCore: Int? = null

        /** Thermal gate on/off for the whole suite; `benchmark.thermalGating=false` disables it. */
        private var thermalGatingEnabled: Boolean = true
    }

    @Test
    fun benchmarkAll() {
        val instrumentationArguments = InstrumentationRegistry.getArguments()
        val quick = instrumentationArguments.getString("benchmark.quick") == "true"
        val target = instrumentationArguments.getString("benchmark.kernel")
        val benchmarkSizes = sizes(quick)
        BenchmarkViewModel.beginSuite(totalRuns(target, benchmarkSizes))
        if (target.isNullOrEmpty() || target == "UnLinearize") benchmarkUnLinearize(benchmarkSizes)
        if (target.isNullOrEmpty() || target == "ComponentTransfer") benchmarkComponentTransfer(benchmarkSizes)
        if (target.isNullOrEmpty() || target == "Morphology") benchmarkMorphology(benchmarkSizes)
        if (target.isNullOrEmpty() || target == "ArithmeticComposite") {
            benchmarkArithmeticCompositeNonLinear(benchmarkSizes)
            benchmarkArithmeticCompositeLinear(benchmarkSizes)
        }
        if (target.isNullOrEmpty() || target == "ConvolveMatrix") benchmarkConvolveMatrix(benchmarkSizes)
        if (target.isNullOrEmpty() || target == "DisplacementMap") benchmarkDisplacementMap(benchmarkSizes)
        if (target.isNullOrEmpty() || target == "Lighting") benchmarkLighting(benchmarkSizes)
        if (target.isNullOrEmpty() || target == "Turbulence") benchmarkTurbulence(benchmarkSizes)
        if (target.isNullOrEmpty() || target == "GaussianBlur") benchmarkGaussianBlur(benchmarkSizes)
    }

    private fun benchmarkUnLinearize(sizes: Array<Pair<Int, Int>>) {
        val table = ByteArray(256) { it.toByte() }
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)

            benchmarkKotlin(
                name = "UnLinearize",
                width = w,
                height = h,
                bytesPerPixel = BYTES_PER_PIXEL_RW
            ) {
                KotlinKernels.unLinearize(
                    src = src,
                    dst = dst,
                    width = w,
                    height = h,
                    table = table
                )
            }

            benchmarkCells(
                name = "UnLinearize",
                backendFlags = UnLinearizeNative.nativeBackend(),
                w = w,
                h = h,
                bytesPerPixel = BYTES_PER_PIXEL_RW
            ) { b ->
                UnLinearizeNative.applyForced(
                    src = src,
                    dst = dst,
                    width = w,
                    height = h,
                    table = table,
                    simdBackend = b
                )
            }
        }
    }

    private fun benchmarkComponentTransfer(sizes: Array<Pair<Int, Int>>) {
        val tables = Array(4) { IntArray(256) { it shl it * 8 } }
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)

            benchmarkKotlin(
                name = "ComponentTransfer",
                width = w,
                height = h,
                bytesPerPixel = BYTES_PER_PIXEL_RW
            ) {
                KotlinKernels.componentTransfer(
                    src = src,
                    dst = dst,
                    width = w,
                    clipLeft = 0,
                    clipTop = 0,
                    clipRight = w,
                    clipBottom = h,
                    tableA = tables[0],
                    tableR = tables[1],
                    tableG = tables[2],
                    tableB = tables[3]
                )
            }

            benchmarkCells(
                name = "ComponentTransfer",
                backendFlags = ComponentTransferNative.nativeBackend(),
                w = w,
                h = h,
                bytesPerPixel = BYTES_PER_PIXEL_RW
            ) { b ->
                ComponentTransferNative.applyForced(
                    src = src,
                    dst = dst,
                    width = w,
                    height = h,
                    clipLeft = 0,
                    clipTop = 0,
                    clipRight = w,
                    clipBottom = h,
                    tableA = tables[0],
                    tableR = tables[1],
                    tableG = tables[2],
                    tableB = tables[3],
                    simdBackend = b
                )
            }
        }
    }

    private fun benchmarkMorphology(sizes: Array<Pair<Int, Int>>) {
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)

            benchmarkKotlin(
                name = "Morphology",
                width = w,
                height = h,
                bytesPerPixel = BYTES_PER_PIXEL_RW
            ) {
                KotlinKernels.morphology(
                    src = src,
                    dst = dst,
                    width = w,
                    height = h,
                    radiusX = 5,
                    radiusY = 5,
                    erode = true,
                    clipLeft = 0,
                    clipTop = 0,
                    clipRight = w,
                    clipBottom = h
                )
            }

            benchmarkCells(
                name = "Morphology",
                backendFlags = MorphologyNative.nativeBackend(),
                w = w,
                h = h,
                bytesPerPixel = BYTES_PER_PIXEL_RW
            ) { b ->
                MorphologyNative.applyForced(
                    src = src,
                    dst = dst,
                    width = w,
                    height = h,
                    radiusX = 5,
                    radiusY = 5,
                    erode = true,
                    clipLeft = 0,
                    clipTop = 0,
                    clipRight = w,
                    clipBottom = h,
                    simdBackend = b
                )
            }
        }
    }

    private fun benchmarkArithmeticComposite(
        sizes: Array<Pair<Int, Int>>,
        useLinear: Boolean
    ) {
        for ((w, h) in sizes) {
            val src1 = IntArray(w * h)
            val src2 = IntArray(w * h)
            val dst = IntArray(w * h)

            benchmarkKotlin(
                name = if (useLinear) "ArithmeticComposite (linear)" else "ArithmeticComposite (non-linear)",
                width = w,
                height = h,
                bytesPerPixel = BYTES_PER_PIXEL_TWO_SOURCES
            ) {
                KotlinKernels.arithmeticComposite(
                    inputPixels = src1,
                    in2Pixels = src2,
                    outPixels = dst,
                    width = w,
                    clipLeft = 0,
                    clipTop = 0,
                    clipRight = w,
                    clipBottom = h,
                    k1 = 0.5f,
                    k2 = 0.5f,
                    k3 = 0.5f,
                    k4 = 0.1f,
                    useLinear = useLinear
                )
            }

            benchmarkCells(
                name = if (useLinear) "ArithmeticComposite (linear)" else "ArithmeticComposite (non-linear)",
                backendFlags = ArithmeticCompositeNative.nativeBackend(),
                w = w,
                h = h,
                bytesPerPixel = BYTES_PER_PIXEL_TWO_SOURCES
            ) { b ->
                ArithmeticCompositeNative.applyForced(
                    src1 = src1,
                    src2 = src2,
                    dst = dst,
                    width = w,
                    clipLeft = 0,
                    clipTop = 0,
                    clipRight = w,
                    clipBottom = h,
                    k1 = 0.5f,
                    k2 = 0.5f,
                    k3 = 0.5f,
                    k4 = 0.1f,
                    useLinear = useLinear,
                    simdBackend = b
                )
            }
        }
    }

    private fun benchmarkArithmeticCompositeNonLinear(sizes: Array<Pair<Int, Int>>) =
        benchmarkArithmeticComposite(sizes, useLinear = false)

    private fun benchmarkArithmeticCompositeLinear(sizes: Array<Pair<Int, Int>>) =
        benchmarkArithmeticComposite(sizes, useLinear = true)

    private fun benchmarkConvolveMatrix(sizes: Array<Pair<Int, Int>>) {
        // 5x5 weight matrix (the old 9-float driver passed an order-5 kernel with a 9-element
        // array, an out-of-bounds read; a 25-element kernel fixes it with the same workload).
        val kernel = FloatArray(25) { 0.11f }
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)

            benchmarkKotlin(
                name = "ConvolveMatrix",
                width = w,
                height = h,
                bytesPerPixel = BYTES_PER_PIXEL_RW
            ) {
                KotlinKernels.convolveMatrix(
                    srcPixels = src,
                    outPixels = dst,
                    width = w,
                    height = h,
                    kernel = kernel,
                    orderX = 5,
                    orderY = 5,
                    targetX = 2,
                    targetY = 2,
                    divisor = 16f,
                    bias = 0f,
                    preserveAlpha = true,
                    edgeMode = 0
                )
            }

            benchmarkCells(
                name = "ConvolveMatrix",
                backendFlags = ConvolveNative.nativeBackend(),
                w = w,
                h = h,
                bytesPerPixel = BYTES_PER_PIXEL_RW
            ) { b ->
                ConvolveNative.applyForced(
                    src = src,
                    dst = dst,
                    width = w,
                    height = h,
                    kernel = kernel,
                    orderX = 5,
                    orderY = 5,
                    targetX = 2,
                    targetY = 2,
                    divisor = 16f,
                    bias = 0f,
                    preserveAlpha = true,
                    edgeMode = 0,
                    simdBackend = b
                )
            }
        }
    }

    private fun benchmarkDisplacementMap(sizes: Array<Pair<Int, Int>>) {
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val map = IntArray(w * h)
            val dst = IntArray(w * h)

            benchmarkKotlin(
                name = "DisplacementMap",
                width = w,
                height = h,
                bytesPerPixel = BYTES_PER_PIXEL_TWO_SOURCES
            ) {
                KotlinKernels.displacementMap(
                    src = src,
                    map = map,
                    dst = dst,
                    width = w,
                    height = h,
                    mapWidth = w,
                    mapHeight = h,
                    scale = 20f,
                    xChannel = 0,
                    yChannel = 1
                )
            }

            benchmarkCells(
                name = "DisplacementMap",
                backendFlags = DisplacementMapNative.nativeBackend(),
                w = w,
                h = h,
                bytesPerPixel = BYTES_PER_PIXEL_TWO_SOURCES
            ) { b ->
                DisplacementMapNative.applyForced(
                    src = src,
                    map = map,
                    dst = dst,
                    width = w,
                    height = h,
                    mapWidth = w,
                    mapHeight = h,
                    scale = 20f,
                    xChannel = 0,
                    yChannel = 1,
                    simdBackend = b
                )
            }
        }
    }

    private fun benchmarkLighting(sizes: Array<Pair<Int, Int>>) {
        val params = DoubleArray(8) { 1.0 }
        for ((w, h) in sizes) {
            val pix = IntArray(w * h)
            val out = IntArray(w * h)

            benchmarkKotlin(
                name = "Lighting",
                width = w,
                height = h,
                bytesPerPixel = BYTES_PER_PIXEL_RW
            ) {
                KotlinKernels.lighting(
                    pix = pix,
                    out = out,
                    width = w,
                    height = h,
                    clipLeft = 0,
                    clipTop = 0,
                    clipRight = w,
                    clipBottom = h,
                    surfaceScaleNormalized = 1f,
                    invCanvasScaleX = 1.0,
                    invCanvasScaleY = 1.0,
                    userLeft = 0.0,
                    userTop = 0.0,
                    originX = 0.0,
                    originY = 0.0,
                    unitSizeX = 1.0,
                    unitSizeY = 1.0,
                    canvasScaleX = 1f,
                    canvasScaleY = 1f,
                    lightType = 0,
                    specular = false,
                    k = 1f,
                    exponent = 1f,
                    lightR = 255,
                    lightG = 255,
                    lightB = 255,
                    params = params,
                    premultipliedOutput = false,
                    useLinear = false
                )
            }

            benchmarkCells(
                name = "Lighting",
                backendFlags = LightingNative.nativeBackend(),
                w = w,
                h = h,
                bytesPerPixel = BYTES_PER_PIXEL_RW
            ) { b ->
                LightingNative.applyForced(
                    pix = pix,
                    out = out,
                    width = w,
                    height = h,
                    clipLeft = 0,
                    clipTop = 0,
                    clipRight = w,
                    clipBottom = h,
                    surfaceScaleNormalized = 1f,
                    invCanvasScaleX = 1.0,
                    invCanvasScaleY = 1.0,
                    userLeft = 0.0,
                    userTop = 0.0,
                    originX = 0.0,
                    originY = 0.0,
                    unitSizeX = 1.0,
                    unitSizeY = 1.0,
                    canvasScaleX = 1f,
                    canvasScaleY = 1f,
                    lightType = 0,
                    specular = false,
                    k = 1f,
                    exponent = 1f,
                    lightR = 255,
                    lightG = 255,
                    lightB = 255,
                    params = params,
                    premultipliedOutput = false,
                    useLinear = false,
                    simdBackend = b
                )
            }
        }
    }

    private fun benchmarkTurbulence(sizes: Array<Pair<Int, Int>>) {
        for ((w, h) in sizes) {
            val pixels = IntArray(w * h)
            val seed = 123
            val lcg = LcgRandom(seed)
            val p = IntArray(SvgPathNoise.LATTICE_SIZE)
            val generators = Array(4) { SvgPathNoise(lcg, p) }
            SvgPathNoise.buildPermutation(lcg, p)

            benchmarkKotlin("Turbulence", w, h, BYTES_PER_PIXEL_GENERATE) {
                KotlinKernels.turbulence(
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
                    unitSizeX = 1.0,
                    unitSizeY = 1.0,
                    seed = seed,
                    generators = generators
                )
            }

            benchmarkCells(
                name = "Turbulence",
                backendFlags = TurbulenceNative.nativeBackend(),
                w = w,
                h = h,
                bytesPerPixel = BYTES_PER_PIXEL_GENERATE
            ) { b ->
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
                    seed = seed,
                    simdBackend = b
                )
            }
        }
    }

    private fun benchmarkGaussianBlur(sizes: Array<Pair<Int, Int>>) {
        val scratch = NativeGaussianBlur.createScratch()
        try {
            for ((w, h) in sizes) {
                val pix = IntArray(w * h)

                benchmarkKotlin("GaussianBlur", w, h, BYTES_PER_PIXEL_RW) {
                    StackBlur.blur(
                        pixels = pix,
                        width = w,
                        height = h,
                        stdDeviationX = 5f,
                        stdDeviationY = 5f
                    )
                }

                benchmarkCells(
                    name = "GaussianBlur",
                    backendFlags = NativeGaussianBlur.nativeBackend(5f, 5f),
                    w = w,
                    h = h,
                    bytesPerPixel = BYTES_PER_PIXEL_RW
                ) { b ->
                    NativeGaussianBlur.applyForced(
                        scratch = scratch,
                        pixels = pix,
                        width = w,
                        height = h,
                        stdDeviationX = 5f,
                        stdDeviationY = 5f,
                        simdBackend = b
                    )
                }
            }
        } finally {
            NativeGaussianBlur.destroyScratch(scratch)
        }
    }

    /**
     * One `nativeBenchmark { }` block per advertised backend for the given kernel/size.
     * Buffers are owned by the caller and reused across backends, so the measured region is
     * exactly the kernel call (spec §20).
     */
    private fun benchmarkKotlin(
        name: String,
        width: Int,
        height: Int,
        bytesPerPixel: Int,
        body: () -> Unit
    ) {
        val runWithThermalGating = thermalGatingEnabled
        nativeBenchmark {
            this.name = name
            backend = "kotlin"
            this.width = width
            this.height = height
            warmupIterations = WARMUP_ITERATIONS
            measurementBatches = MEASUREMENT_BATCHES
            iterationsPerBatch =
                if (width * height <= 512 * 512) ITERATIONS_512 else ITERATIONS_2048
            targetBatchMillis = TARGET_BATCH_MILLIS
            maxIterationsPerBatch = MAX_ITERATIONS_PER_BATCH
            this.bytesPerPixel = bytesPerPixel
            thermalGatingEnabled = runWithThermalGating
            run(body)
        }
        profileCell(name, "kotlin", width, height, body)
    }

    private fun benchmarkCells(
        name: String,
        @SimdBackend backendFlags: Int,
        w: Int,
        h: Int,
        bytesPerPixel: Int,
        body: (simdBackend: Int) -> Unit
    ) {
        val runWithThermalGating = thermalGatingEnabled
        for (b in getBackendsFor(backendFlags)) {
            nativeBenchmark {
                this.name = name
                backend = backendName(b)
                width = w
                height = h
                warmupIterations = WARMUP_ITERATIONS
                measurementBatches = MEASUREMENT_BATCHES
                // Fewer iterations per batch at 2048x2048 so the large-kernel cells stay
                // bounded (old runner used 20/2); batch-average CV needs only ~3-5 samples.
                iterationsPerBatch = iterationsForSize(w, h)
                targetBatchMillis = TARGET_BATCH_MILLIS
                maxIterationsPerBatch = MAX_ITERATIONS_PER_BATCH
                this.bytesPerPixel = bytesPerPixel
                thermalGatingEnabled = runWithThermalGating
                run { body(b) }
            }
            profileCell(name, backendName(b), w, h) { body(b) }
        }
    }

    /**
     * Profiles one cell in its own simpleperf window on the SAME thread as the timing cell
     * (thread-scoped counters, GC/alloc threads excluded). Runs only when profiling was
     * requested and the device exposes `simpleperf`. The profile window shares the cell's
     * work but is entirely separate from the timing iterations, so profiling never
     * changes the reported MPix/s.
     */
    private fun profileCell(name: String, backend: String, w: Int, h: Int, work: () -> Unit) {
        val profiler = simpleperfProfiler ?: return
        if (!simpleperfAvailable) return
        val events = supportedEvents
        if (events.isEmpty()) return
        profiler.profile(
            name = "benchmark_${sanitizeName(name)}_${sanitizeName(backend)}_${w}x${h}",
            events = events,
            durationMs = simpleperfDurationMs,
            cpuCore = simpleperfPinCore,
            work = work,
        )
    }

    private fun sanitizeName(raw: String): String = raw.replace(SANITIZE_NAME_REGEX, "_")

    private fun sizes(quick: Boolean): Array<Pair<Int, Int>> =
        if (quick) arrayOf(512 to 512) else arrayOf(512 to 512, 2048 to 2048)

    private fun iterationsForSize(w: Int, h: Int): Int {
        return if (w * h <= 512 * 512) ITERATIONS_512 else ITERATIONS_2048
    }

    private fun totalRuns(target: String?, sizes: Array<Pair<Int, Int>>): Int {
        val iterationsPerCell = sizes.sumOf { (w, h) ->
            WARMUP_ITERATIONS + MEASUREMENT_BATCHES * iterationsForSize(w, h)
        }

        fun count(name: String, backendFlags: Int, modes: Int = 1): Int =
            if (target.isNullOrEmpty() || target == name) {
                modes * (1 + getBackendsFor(backendFlags).size) * iterationsPerCell
            } else {
                0
            }

        return count("UnLinearize", UnLinearizeNative.nativeBackend()) +
            count("ComponentTransfer", ComponentTransferNative.nativeBackend()) +
            count("Morphology", MorphologyNative.nativeBackend()) +
            count("ArithmeticComposite", ArithmeticCompositeNative.nativeBackend(), modes = 2) +
            count("ConvolveMatrix", ConvolveNative.nativeBackend()) +
            count("DisplacementMap", DisplacementMapNative.nativeBackend()) +
            count("Lighting", LightingNative.nativeBackend()) +
            count("Turbulence", TurbulenceNative.nativeBackend()) +
            count("GaussianBlur", NativeGaussianBlur.nativeBackend(5f, 5f))
    }
}
