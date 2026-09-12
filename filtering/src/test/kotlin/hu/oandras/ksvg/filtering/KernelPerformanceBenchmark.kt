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

import org.junit.BeforeClass
import org.junit.Test
import java.io.File

class KernelPerformanceBenchmark {

    companion object {

        private val benchmarkArguments = BenchmarkArguments.fromSystemProperties()

        private fun resolveTmpDir(): File {
            val candidates = listOf(File("../tmp"), File("tmp"))
            return candidates.firstOrNull { it.isDirectory } ?: File("../tmp").apply { mkdirs() }
        }

        @BeforeClass
        @JvmStatic
        fun setup() {
            assertNativeBackendAvailable()
            KernelBenchmarkRunner.clear()
            
            // Clear previous host results from tmp/
            val tmpDir = resolveTmpDir()
            if (tmpDir.exists()) {
                tmpDir.listFiles { _, name -> name.startsWith("benchmarks_host") && name.endsWith(".csv") }
                    ?.forEach { it.delete() }
            }
        }
    }

    private val sizes: List<Pair<Int, Int>>
        get() = if (benchmarkArguments.isQuick) listOf(512 to 512) else listOf(512 to 512, 2048 to 2048)

    @Test
    fun benchmarkAll() {
        val target = System.getProperty("benchmark.kernel")
        val targetSet = benchmarkArguments.kernels
        fun isSelected(name: String) = targetSet.isNullOrEmpty() || targetSet.contains(name)

        if (isSelected("UnLinearize")) benchmarkUnLinearize()
        if (isSelected("ComponentTransfer")) benchmarkComponentTransfer()
        if (isSelected("Morphology")) benchmarkMorphology()
        if (isSelected("ArithmeticComposite")) {
            benchmarkArithmeticCompositeNonLinear()
            benchmarkArithmeticCompositeLinear()
        }
        if (isSelected("ConvolveMatrix")) benchmarkConvolveMatrix()
        if (isSelected("DisplacementMap")) benchmarkDisplacementMap()
        if (isSelected("Lighting")) benchmarkLighting()
        if (isSelected("Turbulence")) benchmarkTurbulence()
        if (isSelected("GaussianBlur")) benchmarkGaussianBlur()
        
        val suffix = if (!target.isNullOrEmpty()) "_${target.replace("+", "_").replace(",", "_")}" else ""
        val output = File(resolveTmpDir(), "benchmarks_host$suffix.csv")
        output.parentFile?.mkdirs()
        KernelBenchmarkRunner.report(output)
    }

    private fun benchmarkUnLinearize() {
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)

            benchmarkSingleManual(
                kernel = "UnLinearize",
                backend = "kotlin",
                w = w,
                h = h
            ) {
                KotlinKernels.unLinearize(src, dst, w, h)
            }

            benchmarkSingle(
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
                    simdBackend = b
                )
            }
        }
    }

    private fun benchmarkComponentTransfer() {
        val tables = Array(4) { IntArray(256) { it shl it * 8 } }
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)
            
            // Add Kotlin reference
            benchmarkSingleManual(
                kernel = "ComponentTransfer",
                backend = "kotlin",
                w = w,
                h = h
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

            benchmarkSingle(
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

    private data class MorphologyBenchmarkConfig(
        @JvmField
        val name: String,
        @JvmField
        val radiusX: Int,
        @JvmField
        val radiusY: Int,
        @JvmField
        val erode: Boolean
    )

    private val morphologyConfigs = listOf(
        MorphologyBenchmarkConfig("Morphology (erode, r=1)", 1, 1, erode = true),
        MorphologyBenchmarkConfig("Morphology (erode, r=5)", 5, 5, erode = true),
        MorphologyBenchmarkConfig("Morphology (dilate, r=5)", 5, 5, erode = false),
    )

    private fun benchmarkMorphology() {
        for (cfg in morphologyConfigs) {
            for ((w, h) in sizes) {
                val src = IntArray(w * h)
                val dst = IntArray(w * h)

                // Add Kotlin reference
                benchmarkSingleManual(
                    kernel = cfg.name,
                    backend = "kotlin",
                    w = w,
                    h = h
                ) {
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

                benchmarkSingle(
                    name = cfg.name,
                    backendFlags = MorphologyNative.nativeBackend(),
                    w = w,
                    h = h
                ) { b ->
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
        }
    }

    private fun benchmarkArithmeticCompositeNonLinear() {
        for ((w, h) in sizes) {
            val src1 = IntArray(w * h)
            val src2 = IntArray(w * h)
            val dst = IntArray(w * h)

            benchmarkSingleManual(
                kernel = "ArithmeticComposite (non-linear)",
                backend = "kotlin",
                w = w,
                h = h
            ) {
                KotlinKernels.arithmeticComposite(
                    src1, src2, dst, w,
                    0, 0, w, h,
                    0.5f, 0.5f, 0.5f, 0.1f,
                    false
                )
            }

            benchmarkSingle(
                name = "ArithmeticComposite (non-linear)",
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
                    useLinear = false,
                    simdBackend = b
                )
            }
        }
    }

    private fun benchmarkArithmeticCompositeLinear() {
        for ((w, h) in sizes) {
            val src1 = IntArray(w * h)
            val src2 = IntArray(w * h)
            val dst = IntArray(w * h)

            benchmarkSingleManual(
                kernel = "ArithmeticComposite (linear)",
                backend = "kotlin",
                w = w,
                h = h
            ) {
                KotlinKernels.arithmeticComposite(
                    src1, src2, dst, w,
                    0, 0, w, h,
                    0.5f, 0.5f, 0.5f, 0.1f,
                    true
                )
            }

            benchmarkSingle(
                name = "ArithmeticComposite (linear)",
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
                    useLinear = true,
                    simdBackend = b
                )
            }
        }
    }

    private class ConvolveBenchmarkConfig(
        @JvmField
        val name: String,
        @JvmField
        val orderX: Int,
        @JvmField
        val orderY: Int,
        @JvmField
        val preserveAlpha: Boolean,
        @JvmField
        val edgeMode: Int,
        @JvmField
        val kernel: FloatArray
    )

    private val convolveConfigs = arrayOf(
        ConvolveBenchmarkConfig("ConvolveMatrix (duplicate, alpha)", 3, 3, preserveAlpha = true, edgeMode = 0, FloatArray(9) { 0.11f }),
        ConvolveBenchmarkConfig("ConvolveMatrix (duplicate, no-alpha)", 3, 3, preserveAlpha = false, edgeMode = 0, FloatArray(9) { 0.11f }),
    )

    private fun benchmarkConvolveMatrix() {
        for (cfg in convolveConfigs) {
            for ((w, h) in sizes) {
                val src = IntArray(w * h)
                val dst = IntArray(w * h)

                benchmarkSingleManual(
                    kernel = cfg.name,
                    backend = "kotlin",
                    w = w,
                    h = h
                ) {
                    KotlinKernels.convolveMatrix(
                        src, dst, w, h, cfg.kernel, cfg.orderX, cfg.orderY, cfg.orderX / 2, cfg.orderY / 2, 1f, 0f, cfg.preserveAlpha, cfg.edgeMode
                    )
                }

                benchmarkSingle(
                    name = cfg.name,
                    backendFlags = ConvolveNative.nativeBackend(),
                    w = w,
                    h = h
                ) { b ->
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
                        divisor = 1f,
                        bias = 0f,
                        preserveAlpha = cfg.preserveAlpha,
                        edgeMode = cfg.edgeMode,
                        simdBackend = b
                    )
                }
            }
        }
    }

    private fun benchmarkDisplacementMap() {
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val map = IntArray(w * h)
            val dst = IntArray(w * h)

            benchmarkSingleManual(
                kernel = "DisplacementMap",
                backend = "kotlin",
                w = w,
                h = h,
                numBuffers = 3
            ) {
                KotlinKernels.displacementMap(
                    src, map, dst, w, h, w, h, 20f, 0, 1
                )
            }

            benchmarkSingle(
                name = "DisplacementMap",
                backendFlags = DisplacementMapNative.nativeBackend(),
                w = w,
                h = h,
                numBuffers = 3
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

    private data class LightingBenchmarkConfig(
        @JvmField
        val name: String,
        @JvmField
        val lightType: Int,
        @JvmField
        val specular: Boolean,
        @JvmField
        val k: Float = 1f,
        @JvmField
        val exponent: Float = 1f,
        @JvmField
        val useLinear: Boolean = false,
        @JvmField
        val params: (w: Int, h: Int) -> DoubleArray
    )

    private val lightingConfigs = listOf(
        LightingBenchmarkConfig("Lighting (diffuse, distant)", LightType.DISTANT, specular = false, useLinear = false) { _, _ -> doubleArrayOf(45.0, 45.0) },
        LightingBenchmarkConfig("Lighting (specular, distant)", LightType.DISTANT, specular = true, exponent = 20f, useLinear = false) { _, _ -> doubleArrayOf(45.0, 45.0) },
    )

    private fun benchmarkLighting() {
        for (cfg in lightingConfigs) {
            for ((w, h) in sizes) {
                val pix = IntArray(w * h)
                val out = IntArray(w * h)
                val params = cfg.params(w, h)

                benchmarkSingleManual(
                    kernel = cfg.name,
                    backend = "kotlin",
                    w = w,
                    h = h
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

                benchmarkSingle(
                    name = cfg.name,
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
        }
    }

    private data class TurbulenceBenchmarkConfig(
        @JvmField
        val name: String,
        @JvmField
        val octaves: Int,
        @JvmField
        val fractalNoise: Boolean,
        @JvmField
        val periodX: Int = 0,
        @JvmField
        val periodY: Int = 0
    )

    private val turbulenceConfigs = arrayOf(
        TurbulenceBenchmarkConfig("Turbulence (turbulence, 1 oct)", octaves = 1, fractalNoise = false),
    )

    private fun benchmarkTurbulence() {
        for (cfg in turbulenceConfigs) {
            for ((w, h) in sizes) {
                val pix = IntArray(w * h)
                val seed = 123
                val lcg = LcgRandom(seed)
                val p = IntArray(SvgPathNoise.LATTICE_SIZE)
                val generators = Array(4) { SvgPathNoise(lcg, p) }
                SvgPathNoise.buildPermutation(lcg, p)

                benchmarkSingleManual(
                    kernel = cfg.name,
                    backend = "kotlin",
                    w = w,
                    h = h,
                    numBuffers = 1
                ) {
                    KotlinKernels.turbulence(
                        pix, w, h, 0, 0, w, h,
                        0.01, 0.01, cfg.periodX, cfg.periodY, cfg.octaves, cfg.fractalNoise,
                        1.0, 1.0, 0.0, 0.0, 1.0, 1.0, seed, generators
                    )
                }

                benchmarkSingle(
                    name = cfg.name,
                    backendFlags = TurbulenceNative.nativeBackend(),
                    w = w,
                    h = h,
                    numBuffers = 1
                ) { b ->
                    TurbulenceNative.applyForced(
                        pixels = pix,
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
        }
    }

    private fun benchmarkGaussianBlur() {
        val scratch = NativeGaussianBlur.createScratch()
        try {
            for ((w, h) in sizes) {
                val pix = IntArray(w * h)

                benchmarkSingleManual(
                    kernel = "GaussianBlur",
                    backend = "kotlin",
                    w = w,
                    h = h
                ) {
                    StackBlur.blur(pix, w, h, 5f, 5f)
                }

                benchmarkSingle(
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

    private fun benchmarkSingle(
        name: String,
        @SimdBackend backendFlags: Int,
        w: Int,
        h: Int,
        numBuffers: Int = 2,
        run: (Int) -> Unit
    ) {
        val backends = getBackendsFor(backendFlags)
        val iterations = if (benchmarkArguments.isQuick) 1 else (if (w <= 512) 50 else 5)
        val warmup = if (benchmarkArguments.isQuick) 1 else (if (w <= 512) 10 else 2)
        for (b in backends) {
            KernelBenchmarkRunner.runBenchmark(
                kernel = name,
                backendName = backendName(b),
                width = w,
                height = h,
                warmup = warmup,
                iterations = iterations,
                numBuffers = numBuffers,
                runKernel = { run(b) }
            )
        }
    }

    private fun benchmarkSingleManual(
        kernel: String,
        backend: String,
        w: Int,
        h: Int,
        numBuffers: Int = 2,
        run: () -> Unit
    ) {
        val iterations = if (benchmarkArguments.isQuick) 1 else (if (w <= 512) 50 else 5)
        val warmup = if (benchmarkArguments.isQuick) 1 else (if (w <= 512) 10 else 2)
        KernelBenchmarkRunner.runBenchmark(
            kernel = kernel,
            backendName = backend,
            width = w,
            height = h,
            warmup = warmup,
            iterations = iterations,
            numBuffers = numBuffers,
            runKernel = run
        )
    }
}
