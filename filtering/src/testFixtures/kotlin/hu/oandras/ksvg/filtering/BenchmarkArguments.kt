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

import androidx.test.platform.app.InstrumentationRegistry

private const val DEFAULT_SIMPLEPERF_EVENTS = "cpu-cycles,instructions"

private const val DEFAULT_SIMPLEPERF_DURATION_MS = 2000L

@ConsistentCopyVisibility
public data class BenchmarkArguments private constructor(
    @JvmField
    val isQuick: Boolean,
    @JvmField
    val kernels: Set<String>?,
    @JvmField
    val thermalGatingEnabled: Boolean,
    @JvmField
    val simpleperfEnabled: Boolean,
    @JvmField
    val requestedSimplePerfEvents: List<String>,
    @JvmField
    val simpleperfDurationMs: Long,
    @JvmField
    val simplePerfPinCore: Int?,
) {
    public companion object {

        private fun String.kernelsArgToSet(): Set<String> {
            return split("+", ",")
                .map { it.trim() }
                .filter { it.isNotEmpty() }
                .toSet()
        }

        public fun fromInstrumentationRegistry(): BenchmarkArguments {
            val args = InstrumentationRegistry.getArguments()
            return BenchmarkArguments(
                isQuick = args.getString("benchmark.quick") == "true",
                kernels = args.getString("benchmark.kernel")?.kernelsArgToSet(),
                thermalGatingEnabled = args.getString("benchmark.thermalGating") != "false",
                simpleperfEnabled = args.getString("benchmark.simpleperf") == "true",
                requestedSimplePerfEvents = args.getString("benchmark.simpleperf.events")
                    ?.split(",", "+")
                    ?.map { it.trim() }
                    ?.filter { it.isNotEmpty() }
                    ?.takeIf { it.isNotEmpty() }
                    ?: DEFAULT_SIMPLEPERF_EVENTS.split(","),
                simpleperfDurationMs = run {
                    val duration = args.getString("benchmark.simpleperf.durationMs")?.toLongOrNull()
                    if (duration != null && duration > 0) duration else DEFAULT_SIMPLEPERF_DURATION_MS
                },
                simplePerfPinCore = args.getString("benchmark.simpleperf.pinCore")?.toIntOrNull(),
            )
        }

        public fun fromSystemProperties(): BenchmarkArguments {
            return BenchmarkArguments(
                isQuick = System.getProperty("benchmark.quick") == "true",
                kernels = System.getProperty("benchmark.kernel")?.kernelsArgToSet(),
                thermalGatingEnabled = false,
                simpleperfEnabled = false,
                requestedSimplePerfEvents = emptyList(),
                simpleperfDurationMs = DEFAULT_SIMPLEPERF_DURATION_MS,
                simplePerfPinCore = null,
            )
        }
    }
}
