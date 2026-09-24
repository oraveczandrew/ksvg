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
 * Linux implementation of [HostProfiler] using perf_event_open.
 */
class LinuxHardwareProfiler : HostProfiler {

    private var handle: Long = 0

    init {
        handle = nativeOpen()
    }

    override fun start(name: String) {
        if (handle != 0L) {
            nativeStart(handle)
        }
    }

    override fun stop(): Map<String, Long>? {
        if (handle == 0L) return null
        val values = nativeStop(handle) ?: return null
        
        return mapOf(
            "cycles" to values[0],
            "instructions" to values[1]
        )
    }

    protected fun finalize() {
        if (handle != 0L) {
            nativeClose(handle)
            handle = 0
        }
    }

    private external fun nativeOpen(): Long
    private external fun nativeClose(handle: Long)
    private external fun nativeStart(handle: Long)
    private external fun nativeStop(handle: Long): LongArray?

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
                os.contains("linux") && LinuxHardwareProfiler().handle != 0L
            } catch (_: Throwable) {
                false
            }
    }
}
