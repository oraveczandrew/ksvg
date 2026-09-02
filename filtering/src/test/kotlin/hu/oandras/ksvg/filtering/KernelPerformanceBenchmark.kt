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
import kotlin.math.max

class KernelPerformanceBenchmark {

    companion object {
        private fun resolveTmpDir(): File {
            val candidates = listOf(File("tmp"), File("../tmp"))
            return candidates.firstOrNull { it.isDirectory } ?: File("tmp")
        }

        @BeforeClass
        @JvmStatic
        fun setup() {
            System.loadLibrary("ksvgblur")
            KernelBenchmarkRunner.clear()
        }
        
        fun getBackendsFor(flags: Int): List<Int> {
            val all = listOf(
                SIMD_SCALAR,
                SIMD_SSSE3,
                SIMD_AVX2,
                SIMD_AVX512,
                SIMD_NEON64,
                SIMD_NEON32
            )
            return all.filter { (flags and it) != 0 }
        }

        private fun backendName(id: Int) = when (id) {
            SIMD_SCALAR -> "scalar"
            SIMD_SSSE3 -> "ssse3"
            SIMD_AVX2 -> "avx2"
            SIMD_AVX512 -> "avx512"
            SIMD_NEON64 -> "neon64"
            SIMD_NEON32 -> "neon32"
            else -> "unknown"
        }
    }

    private val sizes = listOf(512 to 512, 2048 to 2048)

    private fun benchmark(name: String, highestBackend: Int, numBuffers: Int = 2, run: (Int, Int, Int) -> Unit) {
        val backends = getBackendsFor(highestBackend)
        val isQuick = System.getProperty("benchmark.quick") == "true"
        for ((w, h) in sizes) {
            val iterations = if (isQuick) 1 else (if (w <= 512) 50 else 5)
            for (b in backends) {
                KernelBenchmarkRunner.runBenchmark(
                    kernel = name,
                    backendName = backendName(b),
                    width = w,
                    height = h,
                    iterations = iterations,
                    numBuffers = numBuffers,
                    runKernel = { run(w, h, b) }
                )
            }
        }
    }

    @Test
    fun benchmarkAll() {
        val target = System.getProperty("benchmark.kernel")

        if (target == null || target == "Unlinearize") benchmarkUnlinearize()
        if (target == null || target == "ComponentTransfer") benchmarkComponentTransfer()
        if (target == null || target == "Morphology") benchmarkMorphology()
        if (target == null || target == "ArithmeticComposite") benchmarkArithmeticComposite()
        if (target == null || target == "ConvolveMatrix") benchmarkConvolveMatrix()
        if (target == null || target == "DisplacementMap") benchmarkDisplacementMap()
        if (target == null || target == "Lighting") benchmarkLighting()
        if (target == null || target == "Turbulence") benchmarkTurbulence()
        if (target == null || target == "GaussianBlur") benchmarkGaussianBlur()
        
        val suffix = if (target != null) "_$target" else ""
        val output = File(resolveTmpDir(), "benchmarks_host$suffix.csv")
        output.parentFile?.mkdirs()
        KernelBenchmarkRunner.report(output)
    }

    private fun benchmarkUnlinearize() {
        val table = ByteArray(256) { it.toByte() }
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkSingle("Unlinearize", UnlinearizeNative.nativeBackend(), w, h) { b ->
                UnlinearizeNative.applyForced(src, dst, w, h, table, b)
            }
        }
    }

    private fun benchmarkComponentTransfer() {
        val tables = Array(4) { ByteArray(256) { it.toByte() } }
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkSingle("ComponentTransfer", ComponentTransferNative.nativeBackend(), w, h) { b ->
                ComponentTransferNative.applyForced(src, dst, w, h, 0, 0, w, h, tables[0], tables[1], tables[2], tables[3], b)
            }
        }
    }

    private fun benchmarkMorphology() {
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkSingle("Morphology", MorphologyNative.nativeBackend(), w, h) { b ->
                MorphologyNative.applyForced(src, dst, w, h, 5, 5, true, 0, 0, w, h, b)
            }
        }
    }

    private fun benchmarkArithmeticComposite() {
        for ((w, h) in sizes) {
            val src1 = IntArray(w * h)
            val src2 = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkSingle("ArithmeticComposite", ArithmeticCompositeNative.nativeBackend(), w, h) { b ->
                ArithmeticCompositeNative.applyForced(src1, src2, dst, w, 0, 0, w, h, 0.5f, 0.5f, 0.5f, 0.1f, true, b)
            }
        }
    }

    private fun benchmarkConvolveMatrix() {
        val kernel = FloatArray(9) { 0.11f }
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkSingle("ConvolveMatrix", ConvolveNative.nativeBackend(), w, h) { b ->
                ConvolveNative.applyForced(src, dst, w, h, kernel, 3, 3, 1, 1, 1f, 0f, true, 0, b)
            }
        }
    }

    private fun benchmarkDisplacementMap() {
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val map = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkSingle("DisplacementMap", DisplacementMapNative.nativeBackend(), w, h, numBuffers = 3) { b ->
                DisplacementMapNative.applyForced(src, map, dst, w, h, w, h, 20f, 0, 1, b)
            }
        }
    }

    private fun benchmarkLighting() {
        val params = DoubleArray(8) { 1.0 }
        for ((w, h) in sizes) {
            val pix = IntArray(w * h)
            val out = IntArray(w * h)
            benchmarkSingle("Lighting", LightingNative.nativeBackend(), w, h) { b ->
                LightingNative.applyForced(pix, out, w, h, 0, 0, w, h, 1f, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f, 0, false, 1f, 1f, 255, 255, 255, params, false, false, b)
            }
        }
    }

    private fun benchmarkTurbulence() {
        for ((w, h) in sizes) {
            val pix = IntArray(w * h)
            benchmarkSingle("Turbulence", TurbulenceNative.nativeBackend(), w, h, numBuffers = 1) { b ->
                TurbulenceNative.applyForced(pix, w, h, 0, 0, w, h, 0.01, 0.01, 0, 0, 1, false, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 123, b)
            }
        }
    }

    private fun benchmarkGaussianBlur() {
        val scratch = NativeGaussianBlur.createScratch()
        try {
            for ((w, h) in sizes) {
                val pix = IntArray(w * h)
                benchmarkSingle("GaussianBlur", NativeGaussianBlur.nativeBackend(5f, 5f), w, h) { b ->
                    NativeGaussianBlur.applyForced(scratch, pix, w, h, 5f, 5f, b)
                }
            }
        } finally {
            NativeGaussianBlur.destroyScratch(scratch)
        }
    }

    private fun benchmarkSingle(name: String, highestBackend: Int, w: Int, h: Int, numBuffers: Int = 2, run: (Int) -> Unit) {
        val backends = getBackendsFor(highestBackend)
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
}
