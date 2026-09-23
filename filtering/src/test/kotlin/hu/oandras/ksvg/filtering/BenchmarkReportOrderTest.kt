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

import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.File

/**
 * The host benchmark CSV/MD report must follow the ISA superset row convention
 * (`BENCHMARKS.md`), not the arbitrary matrix execution order.
 */
class BenchmarkReportOrderTest {

    @Test
    fun reportFollowsIsaSupersetOrder() {
        KernelBenchmarkRunner.clear()
        try {
            // Scrambled insertion: sizes and backends out of order on purpose.
            record("B-kernel", "avx2", 512)
            record("A-kernel", "scalar", 2048)
            record("A-kernel", "kotlin", 2048)
            record("A-kernel", "avx2", 512)
            record("A-kernel", "scalar", 512)
            record("A-kernel", "kotlin", 512)
            record("A-kernel", "sse2", 512)

            val out = File.createTempFile("benchmark_order", ".csv")
            try {
                KernelBenchmarkRunner.report(out)
                val rows = out.readLines().drop(1)
                val keys = rows.map {
                    val cells = it.split(",")
                    "${cells[0]}|${cells[1]}|${cells[2]}"
                }
                assertEquals(
                    listOf(
                        "A-kernel|kotlin|512x512",
                        "A-kernel|scalar|512x512",
                        "A-kernel|sse2|512x512",
                        "A-kernel|avx2|512x512",
                        "A-kernel|kotlin|2048x2048",
                        "A-kernel|scalar|2048x2048",
                        "B-kernel|avx2|512x512",
                    ),
                    keys,
                )
            } finally {
                out.delete()
            }
        } finally {
            KernelBenchmarkRunner.clear()
        }
    }

    private fun record(kernel: String, backend: String, size: Int) {
        KernelBenchmarkRunner.runBenchmark(
            kernel = kernel,
            backendName = backend,
            width = size,
            height = size,
            warmup = 0,
            iterations = 1,
            runKernel = {},
        )
    }
}
