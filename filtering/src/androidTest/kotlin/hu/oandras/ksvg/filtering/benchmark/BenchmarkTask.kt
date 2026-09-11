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
 * Live, per-cell technical state of the currently measured benchmark cell.
 *
 * The harness mutates this object in place while a cell runs: warmup samples consumed,
 * the calibration clamping the per-batch iteration count, batches validated/invalidated,
 * current phase position. [NativeBenchmarkBuilder.publishProgress] snapshots it into an
 * immutable [BenchmarkUiState] for the Activity, so the UI always renders the real
 * (post-calibration) parameters instead of the pre-run defaults. Nothing inside the
 * measured region (`run { }` block) touches this object.
 */
internal class BenchmarkTask {

    /** Kernel display name (e.g. `Turbulence`). */
    @JvmField
    var benchmark: String = ""

    /** Backend display name (e.g. `kotlin`, `scalar`, `neon64`). */
    @JvmField
    var backend: String = ""

    @JvmField
    var width: Int = 0

    @JvmField
    var height: Int = 0

    /** Whether warmup-based batch calibration is active for this cell. */
    @JvmField
    var calibrationActive: Boolean = false

    /** Whether the thermal gate can invalidate batches for this cell. */
    @JvmField
    var thermalGatingEnabled: Boolean = true

    /** Target batch duration the calibration works toward. */
    @JvmField
    var targetBatchMillis: Long = 0L

    /** Per-batch iteration count the benchmark configured before calibration. */
    @JvmField
    var requestedIterationsPerBatch: Int = 0

    /** Upper clamp of the calibration. */
    @JvmField
    var maxIterationsPerBatch: Int = 0

    /** Measurement batches the benchmark asked for. */
    @JvmField
    var requestedBatches: Int = 0

    /** Batches that passed the thermal gate. */
    @JvmField
    var validBatches: Int = 0

    /** Batches thrown away because the device was throttled. */
    @JvmField
    var invalidatedBatches: Int = 0

    /** Wall-clock spent in the timed warmup so far. */
    @JvmField
    var warmupWallMs: Long = 0L

    /** Timed warmup samples collected so far. */
    @JvmField
    var warmupSamples: Int = 0

    /** Calibration result: the real per-batch iteration count once known (`0` until then). */
    @JvmField
    var effectiveIterationsPerBatch: Int = 0

    /** Current position inside the current phase. */
    @JvmField
    var iteration: Int = 0

    /** Phase target for the progress line (`0` = dynamic / not applicable). */
    @JvmField
    var iterationTotal: Int = 0

    /** Free-form phase label (`FOCUSING`, `WARMUP`, `MEASUREMENT BATCH 3`, ...). */
    @JvmField
    var phase: String = ""

    @JvmField
    var status: BenchmarkUiStatus = BenchmarkUiStatus.IDLE

    @JvmField
    var cooldownMillis: Long = 0L

    @JvmField
    var message: String = ""
}