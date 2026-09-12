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

/**
 * Platform abstraction for the kernel benchmark suites. The shared driver
 * ([runBenchmarkCase]) performs buffer setup and the Kotlin/native kernel calls for every
 * family; the sink only decides HOW a single measured cell is executed.
 *
 * - Host implementation (`KernelPerformanceBenchmark`): raw JVM timing via
 *   [KernelBenchmarkRunner] (deterministic iteration counts, single aggregate CSV).
 * - Device implementation (`benchmark.DeviceBenchmarkSink`): the stabilized
 *   `nativeBenchmark { }` harness (calibration, thermal gating, classification) plus
 *   optional per-cell simpleperf profiling.
 *
 * [BenchmarkCase.config.name] is the display name for both the Kotlin reference and the
 * native backend cells. [BenchmarkCase.numBuffers] carries the per-pixel buffer traffic
 * (the device sink derives `bytesPerPixel = 4 * numBuffers` from it).
 */
public interface KernelBenchmarkSink {

    /** Runs one Kotlin-reference cell for [case]. */
    public fun runKotlin(case: BenchmarkCase, work: () -> Unit)

    /** Runs one cell per advertised native backend for [case]. */
    public fun runNative(case: BenchmarkCase, work: (simdBackend: Int) -> Unit)
}

/**
 * Executes one matrix cell: buffer setup + the Kotlin reference and every native backend
 * call for the cell's kernel family, delegated to [sink]. Called by both suites'
 * `benchmarkAll` loops.
 */
public fun runBenchmarkCase(case: BenchmarkCase, sink: KernelBenchmarkSink): Unit =
    when (case.kernel) {
        "UnLinearize" -> benchmarkUnLinearize(case, sink)
        "ComponentTransfer" -> benchmarkComponentTransfer(case, sink)
        "Morphology" -> benchmarkMorphology(case, sink)
        "ArithmeticComposite" -> benchmarkArithmeticComposite(case, sink)
        "ConvolveMatrix" -> benchmarkConvolveMatrix(case, sink)
        "DisplacementMap" -> benchmarkDisplacementMap(case, sink)
        "Lighting" -> benchmarkLighting(case, sink)
        "Turbulence" -> benchmarkTurbulence(case, sink)
        "GaussianBlur" -> benchmarkGaussianBlur(case, sink)
        else -> error("Unknown kernel family: ${case.kernel}")
    }

private fun benchmarkUnLinearize(case: BenchmarkCase, sink: KernelBenchmarkSink) {
    val w = case.width
    val h = case.height
    val src = IntArray(w * h)
    val dst = IntArray(w * h)

    sink.runKotlin(case) {
        KotlinKernels.unLinearize(
            src = src,
            dst = dst,
            width = w,
            height = h
        )
    }

    sink.runNative(case) { b ->
        UnLinearizeNative.applyForced(
            src = src,
            dst = dst,
            width = w,
            height = h,
            simdBackend = b
        )
    }
}

private fun benchmarkComponentTransfer(case: BenchmarkCase, sink: KernelBenchmarkSink) {
    val tables = Array(4) { IntArray(256) { it shl it * 8 } }
    val w = case.width
    val h = case.height
    val src = IntArray(w * h)
    val dst = IntArray(w * h)

    sink.runKotlin(case) {
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

    sink.runNative(case) { b ->
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

private fun benchmarkMorphology(case: BenchmarkCase, sink: KernelBenchmarkSink) {
    val cfg = case.config as MorphologyBenchmarkConfig
    val w = case.width
    val h = case.height
    val src = IntArray(w * h)
    val dst = IntArray(w * h)

    sink.runKotlin(case) {
        KotlinKernels.morphology(
            src = src,
            dst = dst,
            width = w,
            height = h,
            radiusX = cfg.radiusX,
            radiusY = cfg.radiusY,
            erode = cfg.erode,
            clipLeft = 0,
            clipTop = 0,
            clipRight = w,
            clipBottom = h
        )
    }

    sink.runNative(case) { b ->
        MorphologyNative.applyForced(
            src = src,
            dst = dst,
            width = w,
            height = h,
            radiusX = cfg.radiusX,
            radiusY = cfg.radiusY,
            erode = cfg.erode,
            clipLeft = 0,
            clipTop = 0,
            clipRight = w,
            clipBottom = h,
            simdBackend = b
        )
    }
}

private fun benchmarkArithmeticComposite(case: BenchmarkCase, sink: KernelBenchmarkSink) {
    val cfg = case.config as ArithmeticCompositeBenchmarkConfig
    val useLinear = cfg.useLinear
    val w = case.width
    val h = case.height
    val src1 = IntArray(w * h)
    val src2 = IntArray(w * h)
    val dst = IntArray(w * h)

    sink.runKotlin(case) {
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

    sink.runNative(case) { b ->
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

private fun benchmarkConvolveMatrix(case: BenchmarkCase, sink: KernelBenchmarkSink) {
    val cfg = case.config as ConvolveBenchmarkConfig
    val w = case.width
    val h = case.height
    val src = IntArray(w * h)
    val dst = IntArray(w * h)

    sink.runKotlin(case) {
        KotlinKernels.convolveMatrix(
            srcPixels = src,
            outPixels = dst,
            width = w,
            height = h,
            kernel = cfg.kernel,
            orderX = cfg.orderX,
            orderY = cfg.orderY,
            targetX = cfg.orderX / 2,
            targetY = cfg.orderY / 2,
            divisor = cfg.divisor,
            bias = cfg.bias,
            preserveAlpha = cfg.preserveAlpha,
            edgeMode = cfg.edgeMode
        )
    }

    sink.runNative(case) { b ->
        ConvolveNative.applyForced(
            src = src,
            dst = dst,
            width = w,
            height = h,
            kernel = cfg.kernel,
            orderX = cfg.orderX,
            orderY = cfg.orderY,
            targetX = cfg.orderX / 2,
            targetY = cfg.orderY / 2,
            divisor = cfg.divisor,
            bias = cfg.bias,
            preserveAlpha = cfg.preserveAlpha,
            edgeMode = cfg.edgeMode,
            simdBackend = b
        )
    }
}

private fun benchmarkDisplacementMap(case: BenchmarkCase, sink: KernelBenchmarkSink) {
    val w = case.width
    val h = case.height
    val src = IntArray(w * h)
    val map = IntArray(w * h)
    val dst = IntArray(w * h)

    sink.runKotlin(case) {
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

    sink.runNative(case) { b ->
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

private fun benchmarkLighting(case: BenchmarkCase, sink: KernelBenchmarkSink) {
    val cfg = case.config as LightingBenchmarkConfig
    val w = case.width
    val h = case.height
    val pix = IntArray(w * h)
    val out = IntArray(w * h)
    val params = cfg.params(w, h)

    sink.runKotlin(case) {
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
            lightType = cfg.lightType,
            specular = cfg.specular,
            k = cfg.k,
            exponent = cfg.exponent,
            lightR = 255,
            lightG = 255,
            lightB = 255,
            params = params,
            premultipliedOutput = false,
            useLinear = cfg.useLinear
        )
    }

    sink.runNative(case) { b ->
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
            lightType = cfg.lightType,
            specular = cfg.specular,
            k = cfg.k,
            exponent = cfg.exponent,
            lightR = 255,
            lightG = 255,
            lightB = 255,
            params = params,
            premultipliedOutput = false,
            useLinear = cfg.useLinear,
            simdBackend = b
        )
    }
}

private fun benchmarkTurbulence(case: BenchmarkCase, sink: KernelBenchmarkSink) {
    val cfg = case.config as TurbulenceBenchmarkConfig
    val w = case.width
    val h = case.height
    val pixels = IntArray(w * h)
    val seed = 123
    val lcg = LcgRandom(seed)
    val p = IntArray(SvgPathNoise.LATTICE_SIZE)
    val generators = Array(4) { SvgPathNoise(lcg, p) }
    SvgPathNoise.buildPermutation(lcg, p)

    sink.runKotlin(case) {
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
            periodX = cfg.periodX,
            periodY = cfg.periodY,
            octaves = cfg.octaves,
            fractalNoise = cfg.fractalNoise,
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

    sink.runNative(case) { b ->
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
            periodX = cfg.periodX,
            periodY = cfg.periodY,
            octaves = cfg.octaves,
            fractalNoise = cfg.fractalNoise,
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

private fun benchmarkGaussianBlur(case: BenchmarkCase, sink: KernelBenchmarkSink) {
    val scratch = NativeGaussianBlur.createScratch()
    try {
        val w = case.width
        val h = case.height
        val pix = IntArray(w * h)

        sink.runKotlin(case) {
            StackBlur.blur(
                pixels = pix,
                width = w,
                height = h,
                stdDeviationX = 5f,
                stdDeviationY = 5f
            )
        }

        sink.runNative(case) { b ->
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
    } finally {
        NativeGaussianBlur.destroyScratch(scratch)
    }
}