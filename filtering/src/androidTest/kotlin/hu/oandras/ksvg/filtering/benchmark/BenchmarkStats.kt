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

import kotlin.math.sqrt

/**
 * Per-sample distribution math for a benchmark run (spec §14). Comparison order per spec and
 * plan: median first, then p90, then min. Percentiles use linear interpolation ("Method 7",
 * the NumPy default): for p, index = p * (n - 1). StdDev is population (n).
 */
class BenchmarkStats(sortedSamples: DoubleArray) {

    @JvmField
    val count: Int = sortedSamples.size

    @JvmField
    val minMs: Double = sortedSamples.first()
    @JvmField
    val medianMs: Double = percentile(sortedSamples, 0.5)
    @JvmField
    val meanMs: Double = sortedSamples.average()
    @JvmField
    val maxMs: Double = sortedSamples.last()
    @JvmField
    val p90Ms: Double = percentile(sortedSamples, 0.90)
    @JvmField
    val p95Ms: Double = percentile(sortedSamples, 0.95)
    @JvmField
    val p99Ms: Double = percentile(sortedSamples, 0.99)

    @JvmField
    val stdDevMs: Double = run {
        val m = meanMs
        sqrt(sortedSamples.sumOf { (it - m) * (it - m) } / count)
    }

    private fun percentile(sorted: DoubleArray, p: Double): Double {
        if (count == 1) return minMs
        val index = p * (count - 1)
        val lo = index.toInt()
        val hi = minOf(lo + 1, count - 1)
        val frac = index - lo
        return sorted[lo] * (1 - frac) + sorted[hi] * frac
    }
}

/** Sorts [samples] ascending (BenchmarkStats expects sorted input). */
internal fun sortedSamples(samples: DoubleArray): DoubleArray = samples.sortedArray()