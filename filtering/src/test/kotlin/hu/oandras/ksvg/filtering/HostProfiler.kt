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

/**
 * Host-side profiling abstraction for auditing SIMD kernels.
 */
interface HostProfiler {

    /** Starts recording performance counters for the current thread. */
    fun start(name: String)

    /**
     * Stops recording and returns a map of deltas (e.g. "cycles", "instructions").
     * Returns null if profiling is unavailable or failed.
     */
    fun stop(): Map<String, Long>?

    object NoOp : HostProfiler {
        override fun start(name: String) {}
        override fun stop(): Map<String, Long>? = null
    }
}
