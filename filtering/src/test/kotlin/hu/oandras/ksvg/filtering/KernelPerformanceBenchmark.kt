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

import hu.oandras.ksvg.filtering.StackBlur
import org.junit.BeforeClass
import org.junit.Test
import java.io.File

class KernelPerformanceBenchmark {

    companion object {
        private fun resolveTmpDir(): File {
            val candidates = listOf(File("tmp"), File("../tmp"))
            return candidates.firstOrNull { it.isDirectory } ?: File("tmp")
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

    private val sizes = listOf(512 to 512, 2048 to 2048)

    @Test
    fun benchmarkAll() {
        val target = System.getProperty("benchmark.kernel")

        if (target.isNullOrEmpty() || target == "UnLinearize") benchmarkUnLinearize()
        if (target.isNullOrEmpty() || target == "ComponentTransfer") benchmarkComponentTransfer()
        if (target.isNullOrEmpty() || target == "Morphology") benchmarkMorphology()
        if (target.isNullOrEmpty() || target == "ArithmeticComposite") {
            benchmarkArithmeticCompositeNonLinear()
            benchmarkArithmeticCompositeLinear()
        }
        if (target.isNullOrEmpty() || target == "ConvolveMatrix") benchmarkConvolveMatrix()
        if (target.isNullOrEmpty() || target == "DisplacementMap") benchmarkDisplacementMap()
        if (target.isNullOrEmpty() || target == "Lighting") benchmarkLighting()
        if (target.isNullOrEmpty() || target == "Turbulence") benchmarkTurbulence()
        if (target.isNullOrEmpty() || target == "GaussianBlur") benchmarkGaussianBlur()
        
        val suffix = if (target != null) "_$target" else ""
        val output = File(resolveTmpDir(), "benchmarks_host$suffix.csv")
        output.parentFile?.mkdirs()
        KernelBenchmarkRunner.report(output)
    }

    private fun benchmarkUnLinearize() {
        val table = ByteArray(256) { it.toByte() }
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)

            benchmarkSingleManual(
                kernel = "UnLinearize",
                backend = "kotlin",
                w = w,
                h = h
            ) {
                KotlinKernels.unLinearize(src, dst, w, h, table)
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
                    table = table,
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

    private fun benchmarkMorphology() {
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)

            // Add Kotlin reference
            benchmarkSingleManual(
                kernel = "Morphology",
                backend = "kotlin",
                w = w,
                h = h
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

            benchmarkSingle(
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

    private fun benchmarkConvolveMatrix() {
        val kernel = FloatArray(9) { 0.11f }
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)

            benchmarkSingleManual(
                kernel = "ConvolveMatrix",
                backend = "kotlin",
                w = w,
                h = h
            ) {
                KotlinKernels.convolveMatrix(
                    src, dst, w, h, kernel, 3, 3, 1, 1, 1f, 0f, true, 0
                )
            }

            benchmarkSingle(
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
                    orderX = 3,
                    orderY = 3,
                    targetX = 1,
                    targetY = 1,
                    divisor = 1f,
                    bias = 0f,
                    preserveAlpha = true,
                    edgeMode = 0,
                    simdBackend = b
                )
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

    private fun benchmarkLighting() {
        val params = DoubleArray(8) { 1.0 }
        for ((w, h) in sizes) {
            val pix = IntArray(w * h)
            val out = IntArray(w * h)

            benchmarkSingleManual(
                kernel = "Lighting",
                backend = "kotlin",
                w = w,
                h = h
            ) {
                KotlinKernels.lighting(
                    pix, out, w, h, 0, 0, w, h,
                    1f, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f,
                    0, false, 1f, 1f, 255, 255, 255, params
                )
            }

            benchmarkSingle(
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

    private fun benchmarkTurbulence() {
        for ((w, h) in sizes) {
            val pix = IntArray(w * h)
            val seed = 123
            val lcg = LcgRandom(seed)
            val p = IntArray(SvgPathNoise.LATTICE_SIZE)
            val generators = Array(4) { SvgPathNoise(lcg, p) }
            SvgPathNoise.buildPermutation(lcg, p)

            benchmarkSingleManual(
                kernel = "Turbulence",
                backend = "kotlin",
                w = w,
                h = h,
                numBuffers = 1
            ) {
                KotlinKernels.turbulence(
                    pix, w, h, 0, 0, w, h,
                    0.01, 0.01, 0, 0, 1, false,
                    1.0, 1.0, 0.0, 0.0, 1.0, 1.0, seed, generators
                )
            }

            benchmarkSingle(
                name = "Turbulence",
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
        val isQuick = System.getProperty("benchmark.quick") == "true"
        val iterations = if (isQuick) 1 else (if (w <= 512) 50 else 5)
        for (b in backends) {
            KernelBenchmarkRunner.runBenchmark(
                kernel = name,
                backendName = backendName(b),
                width = w,
                height = h,
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
        val isQuick = System.getProperty("benchmark.quick") == "true"
        val iterations = if (isQuick) 1 else (if (w <= 512) 50 else 5)
        KernelBenchmarkRunner.runBenchmark(
            kernel = kernel,
            backendName = backend,
            width = w,
            height = h,
            iterations = iterations,
            numBuffers = numBuffers,
            runKernel = run
        )
    }
}
