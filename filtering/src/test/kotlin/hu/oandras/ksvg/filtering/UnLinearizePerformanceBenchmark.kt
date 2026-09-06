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

class UnLinearizePerformanceBenchmark {

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

            val tmpDir = resolveTmpDir()
            if (tmpDir.exists()) {
                tmpDir.listFiles { _, name -> name.startsWith("benchmarks_host") && name.endsWith(".csv") }
                    ?.forEach { it.delete() }
            }
        }
    }

    private val sizes = listOf(512 to 512, 2048 to 2048)

    @Test
    fun benchmarkUnLinearize() {
        val table = ByteArray(256) { it.toByte() }
        for ((w, h) in sizes) {
            val src = IntArray(w * h)
            val dst = IntArray(w * h)
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

        val output = File(resolveTmpDir(), "benchmarks_host_UnLinearize.csv")
        output.parentFile?.mkdirs()
        KernelBenchmarkRunner.report(output)
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
}