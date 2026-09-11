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

import android.os.Build
import java.io.File

/**
 * Best-effort CPU and SoC metadata for the benchmark environment (spec §10, §11;
 * TEST_HARNESS_PLAN Step 6).
 *
 * SoC fields (`SOC_MANUFACTURER`, `SOC_MODEL`) are API 31+; the frequency read is a
 * best-effort file I/O of `cpu0/cpufreq/scaling_cur_freq` that may be absent or denied
 * on some devices/ABIs.
 */
internal object CpuInfo {

    @JvmField
    val socManufacturer: String =
        if (Build.VERSION.SDK_INT >= 31) {
            Build.SOC_MANUFACTURER
        } else {
            "unknown"
        }

    @JvmField
    val socModel: String =
        if (Build.VERSION.SDK_INT >= 31) {
            Build.SOC_MODEL
        } else {
            "unknown"
        }

    @JvmField
    val hardware: String = Build.HARDWARE

    /**
     * Best-effort current CPU frequency of the given [cpu], in kHz. Returns `null` if
     * the sysfs file is absent, unreadable, or contains unparseable content.
     */
    fun cpuFreqKhz(cpu: Int): Int? =
        try {
            File("/sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_cur_freq")
                .readText()
                .trim()
                .toInt()
        } catch (_: Throwable) {
            null
        }
}
