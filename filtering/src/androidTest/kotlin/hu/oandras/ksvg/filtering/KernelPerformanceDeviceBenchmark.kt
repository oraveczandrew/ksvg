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

import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertTrue
import org.junit.BeforeClass
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class KernelPerformanceDeviceBenchmark {

    companion object {
        @BeforeClass
        @JvmStatic
        fun setup() {
            assertNativeBackendAvailable()
            KernelBenchmarkRunner.clear()
        }
        
        fun getBackendsFor(flags: Int): List<Int> {
            val all = arrayOf(
                SIMD_SCALAR,
                SIMD_NEON64,
                SIMD_NEON32
            )
            return all.filter { (flags and it) != 0 }
        }

        private fun backendName(id: Int) = when (id) {
            SIMD_SCALAR -> "scalar"
            SIMD_NEON64 -> "neon64"
            SIMD_NEON32 -> "neon32"
            else -> "unknown"
        }
    }

    private val sizes: Array<Pair<Int, Int>> = arrayOf(512 to 512, 2048 to 2048)

    @Test
    fun benchmarkAll() {
        Log.i("Benchmark", "Starting selective benchmark on device")
        val target = InstrumentationRegistry.getArguments().getString("kernel")

        if (target == null || target == "UnLinearize") benchmarkUnLinearize()
        if (target == null || target == "ComponentTransfer") benchmarkComponentTransfer()
        if (target == null || target == "Morphology") benchmarkMorphology()
        if (target == null || target == "ArithmeticComposite") benchmarkArithmeticComposite()
        if (target == null || target == "ConvolveMatrix") benchmarkConvolveMatrix()
        if (target == null || target == "DisplacementMap") benchmarkDisplacementMap()
        if (target == null || target == "Lighting") benchmarkLighting()
        if (target == null || target == "Turbulence") benchmarkTurbulence()
        if (target == null || target == "GaussianBlur") benchmarkGaussianBlur()
        
        val suffix = if (target != null) "_$target" else ""
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val output = File(context.externalCacheDir, "benchmarks_device$suffix.csv")
        KernelBenchmarkRunner.report(output)
        
        Log.i("Benchmark", "Results written to: ${output.absolutePath}")
    }

    private fun benchmarkUnLinearize() {
        val table = ByteArray(256) { it.toByte() }
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkSingle("UnLinearize", UnLinearizeNative.nativeBackend(), w, h) { b ->
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
        val tables = Array(4) { ByteArray(256) { it.toByte() } }
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkSingle("ComponentTransfer", ComponentTransferNative.nativeBackend(), w, h) { b ->
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
            benchmarkSingle("Morphology", MorphologyNative.nativeBackend(), w, h) { b ->
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

    private fun benchmarkArithmeticComposite() {
        for ((w, h) in sizes) {
            val src1 = IntArray(w * h)
            val src2 = IntArray(w * h)
            val dst = IntArray(w * h)
            benchmarkSingle("ArithmeticComposite", ArithmeticCompositeNative.nativeBackend(), w, h) { b ->
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
            benchmarkSingle("ConvolveMatrix", ConvolveNative.nativeBackend(), w, h) { b ->
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
            benchmarkSingle("DisplacementMap", DisplacementMapNative.nativeBackend(), w, h, numBuffers = 3) { b ->
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
            benchmarkSingle("Lighting", LightingNative.nativeBackend(), w, h) { b ->
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
            benchmarkSingle("Turbulence", TurbulenceNative.nativeBackend(), w, h, numBuffers = 1) { b ->
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
                    seed = 123,
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
                benchmarkSingle("GaussianBlur", NativeGaussianBlur.nativeBackend(5f, 5f), w, h) { b ->
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

    private fun benchmarkSingle(name: String, highestBackend: Int, w: Int, h: Int, numBuffers: Int = 2, run: (Int) -> Unit) {
        val backends = getBackendsFor(highestBackend)
        val isQuick = InstrumentationRegistry.getArguments().getString("quick") == "true"
        val iterations = if (isQuick) 1 else (if (w <= 512) 20 else 2)
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
