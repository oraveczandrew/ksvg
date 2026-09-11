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

import android.content.Context
import android.os.Build
import android.os.PowerManager
import hu.oandras.ksvg.filtering.benchmark.ThermalStateMonitor.Companion.THROTTLE_RATIO

/**
 * Thermal state source for the benchmark harness (spec §6, §7; TEST_HARNESS_PLAN Step 3).
 *
 * API 29+ routes through `PowerManager.currentThermalStatus`; a status above
 * `THERMAL_STATUS_NONE` invalidates the current batch (spec §6). Under API 29 the status
 * API does not exist, so a deterministic single-threaded compute probe is used instead
 * (spec §7): a baseline is taken at the start of the run and a probe that slows down by
 * more than [THROTTLE_RATIO] (≈10%, matching the AndroidX ThrottleDetector heuristic)
 * counts as throttling. The probe never reconstructs a frequency, it only flags degradation.
 *
 * Every call happens outside the measured region (spec §20).
 */
internal class ThermalStateMonitor private constructor(
    private val powerManager: PowerManager?,
    @JvmField
    internal val source: String,
) {

    private var fallbackBaselineNs: Double = 0.0

    /** Status value above [PowerManager.THERMAL_STATUS_NONE] invalidates the batch. */
    internal fun currentThermalStatus(): Int {
        val pm = powerManager ?: return PowerManager.THERMAL_STATUS_NONE
        return try {
            pm.currentThermalStatus
        } catch (t: Throwable) {
            PowerManager.THERMAL_STATUS_NONE
        }
    }

    internal fun isThrottled(): Boolean {
        if (powerManager != null) return currentThermalStatus() > PowerManager.THERMAL_STATUS_NONE
        if (fallbackBaselineNs <= 0.0) return false
        return probeNs() > fallbackBaselineNs * THROTTLE_RATIO
    }

    /** Establishes the API<29 probe baseline once per run; no-op on API 29+. */
    internal fun computeBaselineIfNeeded() {
        if (powerManager == null && fallbackBaselineNs <= 0.0) {
            fallbackBaselineNs = probeNs()
        }
    }

    /**
     * Deterministic fixed computation, timed as min-of-repeats: scheduler noise inflates
     * the mean but never the min, and the min is the strongest signal for a systematic
     * (frequency/thermal) degradation.
     */
    private fun probeNs(): Double {
        var best = Double.POSITIVE_INFINITY
        repeat(PROBE_REPEATS) {
            var acc = 0
            val t0 = System.nanoTime()
            repeat(PROBE_WORK) { i -> acc = acc * 31 + i }
            val elapsed = System.nanoTime() - t0
            if (elapsed < best) best = elapsed.toDouble()
        }
        return best
    }

    companion object {
        /** Slowdown ratio of the probe that flags throttling on API < 29 (spec §7). */
        private const val THROTTLE_RATIO = 1.10

        private const val PROBE_REPEATS = 7

        private const val PROBE_WORK = 1_000_000

        internal fun create(context: Context): ThermalStateMonitor {
            val pm =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    context.getSystemService(Context.POWER_SERVICE) as? PowerManager
                } else {
                    null
                }
            return ThermalStateMonitor(pm, if (pm != null) "powerManager" else "fallbackProbe")
        }
    }
}