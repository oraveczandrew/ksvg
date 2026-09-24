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
 * JNI bridge to the Linux `sched_setaffinity` controls added to `libksvgfilters`
 * (`benchmark/cpu_affinity.cpp`). Lets the diagnostic benchmark pin the caller
 * thread to one concrete CPU so scalar and NEON runs share the same core and
 * frequency state.
 *
 * `sched_setaffinity` may be denied for unrooted apps on some devices; [pinToCore]
 * then returns false and the caller must cope (report-only).
 */
internal object CpuAffinity {

    @JvmStatic
    external fun nativePinToCore(cpuId: Int): Int

    @JvmStatic
    external fun nativeGetCurrentCpu(): Int

    /** Pins the calling thread to [cpuId]; returns true only on an OS-level success. */
    fun pinToCore(cpuId: Int): Boolean =
        try {
            nativePinToCore(cpuId) == 0
        } catch (_: Throwable) {
            false
        }

    /** Resets affinity to the scheduler's full allow-list. */
    fun resetAffinity(): Boolean =
        try {
            nativePinToCore(-1) == 0
        } catch (_: Throwable) {
            false
        }

    /** CPU number the calling thread is (currently) running on, or -1 on failure. */
    fun currentCpu(): Int =
        try {
            nativeGetCurrentCpu()
        } catch (_: Throwable) {
            -1
        }
}