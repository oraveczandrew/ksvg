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
 * Intel macOS implementation of [HostProfiler] using the private `kpc` API.
 */
class IntelMacOSProfiler : HostProfiler {

    private var startCounters: LongArray? = null

    override fun start(name: String) {
        if (!nativeIsAvailable()) return
        nativeStart()
        startCounters = nativeGetThreadCounters()
    }

    override fun stop(): Map<String, Long>? {
        val start = startCounters ?: return null
        val end = nativeGetThreadCounters() ?: return null
        startCounters = null

        if (start.size != end.size || start.size < 2) return null

        val fixedCount = nativeGetFixedCount()
        val metrics = mutableMapOf<String, Long>()

        if (fixedCount >= 2) {
            metrics["cycles"] = end[0] - start[0]
            metrics["instructions"] = end[1] - start[1]
        }

        return metrics
    }

    private external fun nativeIsAvailable(): Boolean
    private external fun nativeStart()
    private external fun nativeGetFixedCount(): Int
    private external fun nativeGetThreadCounters(): LongArray?

    companion object {
        init {
            try {
                System.loadLibrary("ksvgfilters")
            } catch (_: Throwable) {
            }
        }

        val isSupported: Boolean
            get() = try {
                val os = System.getProperty("os.name")?.lowercase() ?: ""
                val arch = System.getProperty("os.arch")?.lowercase() ?: ""
                os.contains("mac") && (arch == "x86_64" || arch == "amd64") &&
                        IntelMacOSProfiler().nativeIsAvailable()
            } catch (_: Throwable) {
                false
            }
    }
}
