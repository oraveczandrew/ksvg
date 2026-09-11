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

import java.io.File

/**
 * Best-effort per-core topology read from sysfs for the diagnostic benchmark.
 *
 * CLUSTER IDENTIFICATION: On ARM big.LITTLE (SM8550: 4x Cortex-X3 + 4x Cortex-A715 +
 * 4x A510) performance cores are the ones with the highest `cpuinfo_max_freq`. The
 * mapping is device-specific and MUST NOT be assumed equal across devices, which is why
 * the chosen core is derived from the measured sysfs data and reported in the log
 * (`benchmarkCpu=<N>`).
 *
 * All reads are best-effort; sysfs paths may be absent/denied on some devices.
 */
internal object CpuTopology {

    data class CpuCoreInfo(
        @JvmField
        val cpuId: Int,
        @JvmField
        val maxFreqKhz: Int,
        @JvmField
        val curFreqKhz: Int?,
        @JvmField
        val packageId: Int?,
        @JvmField
        val coreId: Int?,
    ) {
        override fun toString(): String {
            return buildString {
                append("cpu")
                append(cpuId)
                append(":max=")
                append(maxFreqKhz / 1000.0)
                append("GHz")
                curFreqKhz?.let {
                    append(",cur=")
                    append(it / 1000.0)
                    append("GHz")
                }
                packageId?.let {
                    append(",pkg=")
                    append(it)
                }
                coreId?.let {
                    append(",core=")
                    append(it)
                }
            }
        }
    }

    private val cpuRegex = Regex("cpu(\\d+)")

    /** Reads one integer from a sysfs path, tolerating absence/unparseable content. */
    private fun readInt(path: String): Int? =
        try {
            File(path).readText().trim().toIntOrNull()
        } catch (_: Throwable) {
            null
        }

    /** All present CPUs with their max frequency from the cpufreq sysfs tree. */
    fun discoverTopology(): List<CpuCoreInfo> {
        val base = File("/sys/devices/system/cpu")
        val dirs = base
            .listFiles { f -> cpuRegex.matches(f.name) }
            ?.sortedBy { f ->
                cpuRegex.find(f.name)!!.groupValues[1].toInt()
            }.orEmpty()

        return dirs.mapNotNull { dir ->
            val dirPath = dir.path
            val cpuId = cpuRegex.find(dir.name)?.groupValues?.get(1)?.toInt() ?: return@mapNotNull null
            val freq = readInt("$dirPath/cpufreq/cpuinfo_max_freq") ?: return@mapNotNull null
            CpuCoreInfo(
                cpuId = cpuId,
                maxFreqKhz = freq,
                curFreqKhz = readInt("$dirPath/cpufreq/scaling_cur_freq"),
                packageId = readInt("$dirPath/topology/physical_package_id"),
                coreId = readInt("$dirPath/topology/core_id"),
            )
        }
    }

    /**
     * The performance-core candidate: the CPU with the highest `cpuinfo_max_freq`.
     * Returns null if the topology could not be read at all.
     */
    fun findBiggestCore(topology: List<CpuCoreInfo> = discoverTopology()): CpuCoreInfo? =
        topology.maxByOrNull { it.maxFreqKhz }

    /** All CPUs grouped by package then descending max frequency (human-readable log). */
    fun summarize(topology: List<CpuCoreInfo>): String =
        topology.joinToString(";") { it.toString() }
}