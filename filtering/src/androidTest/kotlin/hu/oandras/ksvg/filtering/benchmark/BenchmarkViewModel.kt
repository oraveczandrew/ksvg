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

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicInteger

internal enum class BenchmarkUiStatus {
    IDLE,
    RUNNING,
    COOLING,
    THERMAL_RECOVERY,
    COMPLETED,
    FAILED,
}

internal class BenchmarkViewModel : ViewModel() {

    private val mutableState = MutableStateFlow(BenchmarkUiState())

    @JvmField
    val formattedState: StateFlow<String> =
        mutableState
            .map(::formatState)
            .flowOn(Dispatchers.Default)
            .stateIn(viewModelScope, SharingStarted.Eagerly, formatState(BenchmarkUiState()))

    @JvmField
    val progressPercent: StateFlow<Int> =
        mutableState
            .map(::progressPercent)
            .flowOn(Dispatchers.Default)
            .stateIn(viewModelScope, SharingStarted.Eagerly, 0)

    init {
        viewModelScope.launch(Dispatchers.Default) {
            progressFlow.collectLatest { progress -> mutableState.value = progress }
        }
    }

    companion object {
        private val progressFlow: MutableStateFlow<BenchmarkUiState> = MutableStateFlow(BenchmarkUiState())
        private val globalCurrentRun = AtomicInteger()
        private val globalRun = AtomicInteger()

        internal fun beginSuite(totalRuns: Int) {
            globalCurrentRun.set(0)
            globalRun.set(totalRuns.coerceAtLeast(0))
        }

        /**
         * Replaces one cell's static iteration estimate with its real post-calibration plan
         * (actual warmup samples + batches x effective per-batch count). The static estimate
         * seeded by [beginSuite] stays in the total while the cell runs — the denominator
         * therefore always covers the iterations already executed — and only here converges
         * to the sum of the real per-cell plans. The delta can be negative for slow cells
         * whose warmup hit the wall budget (real plan < static estimate).
         */
        internal fun commitCellPlan(staticEstimate: Int, actualForCell: Int) {
            globalRun.addAndGet(actualForCell.coerceAtLeast(0) - staticEstimate.coerceAtLeast(0))
        }

        /**
         * Adds iterations a thermal-invalidated batch will re-run, so the global total keeps
         * counting them while the batch is retried.
         */
        internal fun addInvalidatedIterations(count: Int) {
            globalRun.addAndGet(count.coerceAtLeast(0))
        }

        internal fun advanceGlobalProgress(): Int = globalCurrentRun.incrementAndGet()

        internal fun currentGlobalRun(): Int = globalCurrentRun.get()

        internal fun totalGlobalRuns(): Int = globalRun.get()

        internal fun publishProgress(progress: BenchmarkUiState) {
            progressFlow.value = progress
        }
    }

    private fun formatState(state: BenchmarkUiState): String =
        buildString {
            val benchName = state.benchmark.ifBlank { "-" }
            val backendName = state.backend.ifBlank { "-" }
            val sizeLabel = state.size.ifBlank { "-" }
            val phaseLabel = state.phase.ifBlank { "-" }

            append("KSVG benchmark\n")

            append("Benchmark: ")
            append(benchName)
            append('\n')

            append("Backend: ")
            append(backendName)
            append(" | Size: ")
            append(sizeLabel)
            append('\n')

            append("Phase: ")
            append(phaseLabel)
            append('\n')
            append('\n')

            if (state.phase.startsWith("WARMUP") && state.calibrationActive) {
                // Adaptive warmup: wall-budget capped, no fixed denominator to trust.
                append("Warmup: ")
                append(state.warmupSamples)
                append(" samples (wall ")
                append(state.warmupWallMs)
                append(" ms)")
                append('\n')
            } else {
                append("Iteration: ")
                append(state.iteration)
                append('/')
                if (state.totalIterations > 0) append(state.totalIterations) else append('-')
                append('\n')
            }

            append("Batches: ")
            append(state.validBatches)
            append('/')
            if (state.requestedBatches > 0) append(state.requestedBatches) else append('-')
            append(" valid (+")
            append(state.invalidatedBatches)
            append(" invalidated)")
            append('\n')

            if (state.effectiveIterationsPerBatch > 0) {
                append("Per-batch iters: ")
                append(state.effectiveIterationsPerBatch)
                append(" (requested ")
                append(state.requestedIterationsPerBatch)
                append(", max ")
                append(state.maxIterationsPerBatch)
                append(", target ")
                append(state.targetBatchMillis)
                append(" ms)")
                append('\n')
            } else if (state.requestedIterationsPerBatch > 0) {
                append("Per-batch iters: ")
                append(state.requestedIterationsPerBatch)
                append(" (not yet calibrated)")
                append('\n')
            }
            if (state.calibrationActive) {
                append("Batch calibration: ON")
                append('\n')
            }
            append('\n')

            append("Thermal gate: ")
            if (state.thermalGatingEnabled) {
                append("ON")
            } else {
                append("OFF")
            }
            append(" | Status: ")
            append(state.status)
            append('\n')
            if (state.cooldownMillis > 0L) {
                append("Cooldown: ")
                append(state.cooldownMillis)
                append(" ms")
                append('\n')
            }
            append("Elapsed: ")
            append(state.elapsedMillis)
            append(" ms")
            append('\n')
            if (state.message.isNotBlank()) {
                append("Message: ")
                append(state.message)
                append('\n')
            }
            append('\n')

            val totalRuns = state.globalRun
            val percent = if (totalRuns > 0) {
                (state.globalCurrentRun * 100 / totalRuns).coerceIn(0, 100)
            } else {
                0
            }
            append("Global progress: ")
            append(state.globalCurrentRun)
            append('/')
            if (totalRuns > 0) {
                append(totalRuns)
            } else {
                append('-')
            }
            append(" (")
            append(percent)
            append("%)")
            append('\n')
        }

    private fun progressPercent(state: BenchmarkUiState): Int =
        if (state.globalRun > 0) {
            (state.globalCurrentRun * 100 / state.globalRun).coerceIn(0, 100)
        } else {
            0
        }
}
