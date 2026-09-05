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
 * normalisation, thermal gating with cooldown/retry, and the five-way classification
 * (VALID / THERMAL_THROTTLED / THERMAL_RECOVERY / UNSTABLE / INSUFFICIENT_SAMPLES). Results
 * are written as summary + detail CSV per cell (matching the `runDeviceBenchmark` pull glob
 * `benchmarks_device*.csv`) in addition to the printed environment/stats/classification.
 *
 * Keeps the legacy kernel-selection arguments:
 *  - `benchmark.kernel` = one of UnLinearize, ComponentTransfer, Morphology,
 *    ArithmeticComposite (both modes), ConvolveMatrix, DisplacementMap, Lighting,
 *    Turbulence, GaussianBlur; empty runs the full suite.
 *  - `benchmark.quick` = true runs 512x512 only (else 512x512 + 2048x2048).
 *  - `benchmark.row` = true runs only the aarch64 morphology **row** kernel
 *    (`neon64-row` backend label, via `MorphologyNative.applyForcedRow`), for
 *    comparing the multi-pixel-per-call variant against the per-pixel `neon64`.
 */
@RunWith(AndroidJUnit4::class)
class KernelPerformanceDeviceBenchmark {

    companion object {

        @BeforeClass
        @JvmStatic
        fun setup() {
            assertNativeBackendAvailable()
        }

        const val WARMUP_ITERATIONS = 10

        const val MEASUREMENT_BATCHES = 5

        const val ITERATIONS_512 = 10

        const val ITERATIONS_2048 = 3
    }

    @Test
    fun benchmarkAll() {
        val quick =
            InstrumentationRegistry.getArguments().getString("benchmark.quick") == "true"
        val target = InstrumentationRegistry.getArguments().getString("benchmark.kernel")
        val row = InstrumentationRegistry.getArguments().getString("benchmark.row") == "true"

        if (row) {
            benchmarkMorphologyRow(quick)
            return
        }

        if (target.isNullOrEmpty() || target == "UnLinearize") benchmarkUnLinearize(quick)
        if (target.isNullOrEmpty() || target == "ComponentTransfer") benchmarkComponentTransfer(quick)
        if (target.isNullOrEmpty() || target == "Morphology") benchmarkMorphology(quick)
        if (target.isNullOrEmpty() || target == "ArithmeticComposite") {
            benchmarkArithmeticCompositeNonLinear(quick)
            benchmarkArithmeticCompositeLinear(quick)
        }
        if (target.isNullOrEmpty() || target == "ConvolveMatrix") benchmarkConvolveMatrix(quick)
        if (target.isNullOrEmpty() || target == "DisplacementMap") benchmarkDisplacementMap(quick)
        if (target.isNullOrEmpty() || target == "Lighting") benchmarkLighting(quick)
        if (target.isNullOrEmpty() || target == "Turbulence") benchmarkTurbulence(quick)
        if (target.isNullOrEmpty() || target == "GaussianBlur") benchmarkGaussianBlur(quick)
    }

    private fun benchmarkUnLinearize(quick: Boolean) {
        val table = ByteArray(256) { it.toByte() }
        for ((w, h) in sizes(quick)) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkCells(
                name = "UnLinearize",
                backendFlags = UnLinearizeNative.nativeBackend(),
                w = w,
                h = h
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

    private fun benchmarkComponentTransfer(quick: Boolean) {
        val tables = Array(4) { ByteArray(256) { it.toByte() } }
        for ((w, h) in sizes(quick)) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkCells(
                name = "ComponentTransfer",
                backendFlags = ComponentTransferNative.nativeBackend(),
                w = w,
                h = h
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

    private fun benchmarkMorphology(quick: Boolean) {
        for ((w, h) in sizes(quick)) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkCells(
                name = "Morphology",
                backendFlags = MorphologyNative.nativeBackend(),
                w = w,
                h = h
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

    /**
     * The aarch64 row kernel (one call per output row, overlapping horizontal
     * windows share a scratch column-reduction row) is not advertised by
     * [MorphologyNative.nativeBackend], so it is benchmarked explicitly with a
     * `neon64-row` backend label and driven through [MorphologyNative.applyForcedRow].
     */
    private fun benchmarkMorphologyRow(quick: Boolean) {
        for ((w, h) in sizes(quick)) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)
            nativeBenchmark {
                this.name = "Morphology"
                backend = "neon64-row"
                width = w
                height = h
                warmupIterations = WARMUP_ITERATIONS
                measurementBatches = MEASUREMENT_BATCHES
                iterationsPerBatch = if (w * h <= 512 * 512) ITERATIONS_512 else ITERATIONS_2048
                run {
                    MorphologyNative.applyForcedRow(
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
                    )
                }
            }
        }
    }

    private fun benchmarkArithmeticComposite(quick: Boolean, useLinear: Boolean) {
        for ((w, h) in sizes(quick)) {
            val src1 = IntArray(w * h)
            val src2 = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkCells(
                name = if (useLinear) "ArithmeticComposite (linear)" else "ArithmeticComposite (non-linear)",
                backendFlags = ArithmeticCompositeNative.nativeBackend(),
                w = w,
                h = h
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

    private fun benchmarkArithmeticCompositeNonLinear(quick: Boolean) = benchmarkArithmeticComposite(quick, useLinear = false)

    private fun benchmarkArithmeticCompositeLinear(quick: Boolean) = benchmarkArithmeticComposite(quick, useLinear = true)

    private fun benchmarkConvolveMatrix(quick: Boolean) {
        // 5x5 weight matrix (the old 9-float driver passed an order-5 kernel with a 9-element
        // array, an out-of-bounds read; a 25-element kernel fixes it with the same workload).
        val kernel = FloatArray(25) { 0.11f }
        for ((w, h) in sizes(quick)) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkCells(
                name = "ConvolveMatrix",
                backendFlags = ConvolveNative.nativeBackend(),
                w = w,
                h = h
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

    private fun benchmarkDisplacementMap(quick: Boolean) {
        for ((w, h) in sizes(quick)) {
            val src = IntArray(w * h)
            val map = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkCells(
                name = "DisplacementMap",
                backendFlags = DisplacementMapNative.nativeBackend(),
                w = w,
                h = h
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

    private fun benchmarkLighting(quick: Boolean) {
        val params = DoubleArray(8) { 1.0 }
        for ((w, h) in sizes(quick)) {
            val pix = IntArray(w * h)
            val out = IntArray(w * h)
            benchmarkCells(
                name = "Lighting",
                backendFlags = LightingNative.nativeBackend(),
                w = w,
                h = h
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

    private fun benchmarkTurbulence(quick: Boolean) {
        for ((w, h) in sizes(quick)) {
            val pixels = IntArray(w * h)
            benchmarkCells(
                name = "Turbulence",
                backendFlags = TurbulenceNative.nativeBackend(),
                w = w,
                h = h
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
                    seed = 123,
                    simdBackend = b
                )
            }
        }
    }

    private fun benchmarkGaussianBlur(quick: Boolean) {
        val scratch = NativeGaussianBlur.createScratch()
        try {
            for ((w, h) in sizes(quick)) {
                val pix = IntArray(w * h)
                benchmarkCells(
                    name = "GaussianBlur",
                    backendFlags = NativeGaussianBlur.nativeBackend(5f, 5f),
                    w = w,
                    h = h
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
    private fun benchmarkCells(
        name: String,
        @SimdBackend backendFlags: Int,
        w: Int,
        h: Int,
        body: (simdBackend: Int) -> Unit
    ) {
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
                iterationsPerBatch = if (w * h <= 512 * 512) ITERATIONS_512 else ITERATIONS_2048
                run { body(b) }
            }
        }
    }

    private fun sizes(quick: Boolean): Array<Pair<Int, Int>> =
        if (quick) arrayOf(512 to 512) else arrayOf(512 to 512, 2048 to 2048)
}
