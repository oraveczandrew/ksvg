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

import android.app.Activity
import android.app.KeyguardManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.os.Process
import android.util.Log
import android.view.WindowManager
import androidx.test.platform.app.InstrumentationRegistry
import java.util.concurrent.atomic.AtomicReference
import kotlin.concurrent.thread

/**
 * Minimal opaque foreground Activity that owns the benchmark Window.
 *
 * Implements the *idea* of androidx.benchmark.IsolationActivity (a foreground window that
 * keeps the process in the "foreground app" scheduling class and opts into sustained
 * performance mode) without copying any AndroidX code (spec §18).
 *
 * Everything this Activity reports is observable state; the harness never asserts that
 * sustained performance mode actually took effect (a device/platform may silently ignore it,
 * in which case [report] simply reports `sustainedSetResult=false`).
 *
 * Note: on the compile-SDK 37 stubs `Window.setSustainedPerformanceMode` returns void and the
 * no-argument `setShowWhenLocked()`/`setTurnScreenOn()` overloads are hidden, so support
 * probing goes through `PowerManager.isSustainedPerformanceModeSupported` and the flag-taking
 * overloads are called directly (guard: `Build.VERSION.SDK_INT >= O_MR1`).
 */
internal class BenchmarkActivity : Activity() {

    private var destroyed = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Disable launch/close animations that would add noise to measurements.
        @Suppress("Deprecation") overridePendingTransition(0, 0)

        if (firstInit) {
            if (isSustainedPerformanceModeSupported()) {
                sustainedPerformanceModeInUse = true
            }
            if (sustainedPerformanceModeInUse) {
                // Keep at least one core busy. Together with the single-threaded benchmark
                // this makes the process look multi-threaded, which keeps sustained
                // performance mode at the multi-threaded clock level across runs.
                // (Thread names are capped at 15 chars in systrace.)
                @Suppress("RETURN_VALUE_NOT_USED")
                thread(name = "BenchSpinThread") {
                    Process.setThreadPriority(Process.THREAD_PRIORITY_LOWEST)
                    // Intentionally never returns; the process is torn down with it.
                    while (true) {
                    }
                }
            }
            firstInit = false
        }

        val old = singleton.getAndSet(this)
        if (old != null && !old.destroyed && !old.isFinishing) {
            throw IllegalStateException("Only one BenchmarkActivity should exist")
        }

        // Keep the screen on and wake the device so long-running benchmarks do not kill
        // the window (and with it any sustained-performance state).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            requestDismissKeyguardCompat()
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
    }

    override fun onResume() {
        super.onResume()
        resumeObserved = true
        if (sustainedPerformanceModeInUse && !sustainedSetAttempted) {
            sustainedSetAttempted = true
            sustainedSetResult = try {
                window.setSustainedPerformanceMode(true)
                true
            } catch (t: Throwable) {
                Log.w(TAG, "setSustainedPerformanceMode threw", t)
                false
            }
        }
    }

    override fun onPause() {
        super.onPause()
        resumeObserved = false
    }

    override fun onDestroy() {
        super.onDestroy()
        destroyed = true
    }

    /** finish() is intentionally a no-op; tear-down goes through [finishSingleton]. */
    override fun finish() {}

    internal fun actuallyFinish() {
        // Disable close animation.
        @Suppress("Deprecation") overridePendingTransition(0, 0)
        super.finish()
    }

    private fun requestDismissKeyguardCompat() {
        val keyguardManager = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
        keyguardManager.requestDismissKeyguard(this, null)
    }

    private fun isSustainedPerformanceModeSupported(): Boolean {
        val pm = getSystemService(POWER_SERVICE) as? PowerManager ?: return false
        return pm.isSustainedPerformanceModeSupported
    }

    companion object {

        private const val TAG = "BenchmarkActivity"

        private val singleton = AtomicReference<BenchmarkActivity>()
        private var firstInit = true

        var sustainedPerformanceModeInUse: Boolean = false
            private set

        var resumeObserved: Boolean = false
            private set

        /** true = setSustainedPerformanceMode(true) returned without throwing. */
        var sustainedSetResult: Boolean? = null
            private set

        private var sustainedSetAttempted: Boolean = false

        fun launchSingleton(): Activity {
            val intent =
                Intent(Intent.ACTION_MAIN).apply {
                    Log.d(TAG, "launching BenchmarkActivity")
                    setClassName(
                        InstrumentationRegistry.getInstrumentation().targetContext.packageName,
                        BenchmarkActivity::class.java.name,
                    )
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                }
            return InstrumentationRegistry.getInstrumentation().startActivitySync(intent)
        }

        fun finishSingleton() {
            singleton.getAndSet(null)?.apply { runOnUiThread { actuallyFinish() } }
        }

        /** Snapshot of the observable environment for the spike / environment report. */
        fun report(): String =
            buildString {
                appendLine("manufacturer=${Build.MANUFACTURER}")
                appendLine("model=${Build.MODEL}")
                appendLine("sdk=${Build.VERSION.SDK_INT}")
                appendLine("abis=${Build.SUPPORTED_ABIS.joinToString(",")}")
                appendLine("cores=${Runtime.getRuntime().availableProcessors()}")
                appendLine("sustainedSupported=${sustainedSupportedSnapshot()}")
                appendLine("sustainedInUse=$sustainedPerformanceModeInUse")
                appendLine("sustainedSetResult=$sustainedSetResult")
                appendLine("resumed=$resumeObserved")
                appendLine("hasWindowFocus=${singleton.get()?.hasWindowFocus()}")
                appendLine("thermalStatus=${thermalStatus()}")
            }

        private fun sustainedSupportedSnapshot(): Boolean {
            val activity = singleton.get() ?: return false
            val pm = activity.getSystemService(POWER_SERVICE) as? PowerManager ?: return false
            return pm.isSustainedPerformanceModeSupported
        }

        private fun thermalStatus(): Int? {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
            val activity = singleton.get() ?: return null
            val pm = activity.getSystemService(POWER_SERVICE) as? PowerManager ?: return null
            return pm.currentThermalStatus
        }
    }
}