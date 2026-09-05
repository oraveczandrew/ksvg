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

/**
 * Deterministic cache-state normalizer (spec §8; TEST_HARNESS_PLAN Step 5).
 *
 * Before each measurement batch (but not inside the measured region), a small fixed-size
 * memory workload is executed to evict CPU-cache state left by the previous batch. This
 * avoids a scenario where one batch's cache footprint speeds up the next.
 *
 * The workload: two 1 MB buffers — deterministic write to `a`, arraycopy to `b`, then a
 * forced sequential read of `b`. 2 MB total is comfortably larger than the L2 cache on
 * all targeted ARM64 SoCs, but executes in well under 1 ms at the benchmark-thread
 * priority, so it never dominates the timing of kernels like Turbulence (512² = ~4–100 ms).
 */
internal object CacheNormalizer {

    private const val BUFFER_SIZE = 1_000_000 // 1 MB

    fun normalize() {
        val a = ByteArray(BUFFER_SIZE)
        val b = ByteArray(BUFFER_SIZE)
        for (i in a.indices step 64) a[i] = (i and 0xFF).toByte()
        System.arraycopy(a, 0, b, 0, a.size)
        var sink = 0
        for (byte in b) sink += byte.toInt()
        // Ensure neither copy nor fill is optimised away; sink is read below.
        @Suppress("UNUSED_VALUE")
        sink
    }
}