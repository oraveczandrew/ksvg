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
        private val progressFlow = MutableStateFlow(BenchmarkUiState())
        private val globalCurrentRun = AtomicInteger()
        private val globalRun = AtomicInteger()

        internal fun beginSuite(totalRuns: Int) {
            globalCurrentRun.set(0)
            globalRun.set(totalRuns.coerceAtLeast(0))
        }

        /**
         * Withdraws one measured cell's *static* iteration estimate from the global total.
         * Calibration changes the real per-batch count, so [commitCellPlan] re-adds the true
         * plan for the cell once it is known; this keeps the live global total (= sum of the
         * real per-cell plans) honest for the progress bar without precomputing calibration.
         */
        internal fun enterCell(estimatedForCell: Int) {
            var done = false
            while (!done) {
                val current = globalRun.get()
                done = globalRun.compareAndSet(
                    current,
                    (current - estimatedForCell.coerceAtLeast(0)).coerceAtLeast(0),
                )
            }
        }

        /**
         * Re-adds the real per-cell plan (actual warmup samples + batches x effective
         * per-batch count) after calibration fixed it; see [enterCell].
         */
        internal fun commitCellPlan(actualForCell: Int) {
            globalRun.addAndGet(actualForCell.coerceAtLeast(0))
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
            appendLine("KSVG benchmark")
            appendLine("Benchmark: ${state.benchmark.ifBlank { "-" }}")
            appendLine("Backend: ${state.backend.ifBlank { "-" }} | Size: ${state.size.ifBlank { "-" }}")
            appendLine("Phase: ${state.phase.ifBlank { "-" }}")
            if (state.phase.startsWith("WARMUP") && state.calibrationActive) {
                // Adaptive warmup: wall-budget capped, no fixed denominator to trust.
                appendLine("Warmup: ${state.warmupSamples} samples (wall ${state.warmupWallMs} ms)")
            } else {
                appendLine(
                    "Iteration: ${state.iteration}/${state.totalIterations.takeIf { it > 0 } ?: "-"}"
                )
            }
            appendLine(
                "Batches: ${state.validBatches}/${state.requestedBatches.takeIf { it > 0 } ?: "-"} valid" +
                    " (+${state.invalidatedBatches} invalidated)"
            )
            if (state.effectiveIterationsPerBatch > 0) {
                appendLine(
                    "Per-batch iters: ${state.effectiveIterationsPerBatch}" +
                        " (requested ${state.requestedIterationsPerBatch}, " +
                        "max ${state.maxIterationsPerBatch}, target ${state.targetBatchMillis} ms)"
                )
            } else if (state.requestedIterationsPerBatch > 0) {
                appendLine("Per-batch iters: ${state.requestedIterationsPerBatch} (not yet calibrated)")
            }
            if (state.calibrationActive) appendLine("Batch calibration: ON")
            appendLine(
                "Thermal gate: ${if (state.thermalGatingEnabled) "ON" else "OFF"} | " +
                    "Status: ${state.status}"
            )
            if (state.cooldownMillis > 0L) appendLine("Cooldown: ${state.cooldownMillis} ms")
            appendLine("Elapsed: ${state.elapsedMillis} ms")
            if (state.message.isNotBlank()) appendLine("Message: ${state.message}")
            val totalRuns = state.globalRun
            val percent =
                if (totalRuns > 0) {
                    (state.globalCurrentRun * 100 / totalRuns).coerceIn(0, 100)
                } else {
                    0
                }
            appendLine(
                "Global progress: ${state.globalCurrentRun}/${
                    totalRuns.takeIf { it > 0 } ?: "-"
                } ($percent%)"
            )
        }

    private fun progressPercent(state: BenchmarkUiState): Int =
        if (state.globalRun > 0) {
            (state.globalCurrentRun * 100 / state.globalRun).coerceIn(0, 100)
        } else {
            0
        }
}
