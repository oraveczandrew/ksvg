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
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicReference

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
internal class BenchmarkActivity : ComponentActivity() {

    private var destroyed = false
    private val cpuSpinner = BenchmarkCpuSpinner()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        @Suppress("DEPRECATION")
        window.statusBarColor = Color.BLACK
        @Suppress("DEPRECATION")
        window.navigationBarColor = Color.BLACK

        val basePadding = (24f * resources.displayMetrics.density).toInt()
        val statusText = BenchmarkProgressTextView(this).apply {
            setTextColor(Color.WHITE)
            textSize = 14f
            gravity = Gravity.TOP or Gravity.START
            includeFontPadding = false
            setPadding(basePadding, basePadding, basePadding, basePadding)
            text = ""
        }

        setContentView(statusText)

        ViewCompat.setOnApplyWindowInsetsListener(statusText) { view, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.setPadding(
                basePadding + systemBars.left,
                basePadding + systemBars.top,
                basePadding + systemBars.right,
                basePadding + systemBars.bottom,
            )
            insets
        }
        ViewCompat.requestApplyInsets(statusText)

        val viewModel = ViewModelProvider(this)[BenchmarkViewModel::class.java]
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                combine(viewModel.formattedState, viewModel.progressPercent) { text, percent ->
                    text to percent
                }.collect { (text, percent) ->
                    statusText.text = text
                    statusText.progressPercent = percent
                }
            }
        }

        // Disable launch/close animations that would add noise to measurements.
        @Suppress("Deprecation") overridePendingTransition(0, 0)

        if (firstInit) {
            if (sustainedSupportedSnapshot()) {
                sustainedPerformanceModeInUse = true
            }
            if (sustainedPerformanceModeInUse) {
                // Keep at least one core busy. Together with the single-threaded benchmark
                // this makes the process look multithreaded, which keeps sustained
                // performance mode at the multithreaded clock level across runs.
                // (Thread names are capped at 15 chars in systrace.)
                cpuSpinner.start()
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
        cpuSpinner.stop()
        // Disable close animation.
        @Suppress("Deprecation") overridePendingTransition(0, 0)
        super.finish()
    }

    private fun requestDismissKeyguardCompat() {
        val keyguardManager = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
        keyguardManager.requestDismissKeyguard(this, null)
    }

    companion object {

        private const val TAG = "BenchmarkActivity"

        private val singleton = AtomicReference<BenchmarkActivity>()
        private var firstInit = true

        var sustainedPerformanceModeInUse: Boolean = false
            private set

        var resumeObserved: Boolean = false
            private set

        /** Whether the benchmark window currently holds focus (a late-settling indicator). */
        val isWindowFocused: Boolean
            get() = singleton.get()?.hasWindowFocus() ?: false

        /** true = setSustainedPerformanceMode(true) returned without throwing. */
        var sustainedSetResult: Boolean? = null
            private set

        private var sustainedSetAttempted: Boolean = false

        /**
         * Brings the foreground window up (spec §17) if no live instance exists. Reuses the
         * already-foreground Activity across the whole instrumentation process so benchmarks
         * never create/destroy a Window in the middle of a suite.
         */
        fun ensureAlive() {
            val current = singleton.get()
            if (current == null || current.isFinishing) {
                launchSingleton()
            }
        }

        /**
         * Ensures the window is alive AND holds focus, waiting up to [timeoutMs]. Focus
         * settles ~100 ms after launch (see worklog Step 0); measurements must not start
         * while unfocused.
         */
        fun waitForFocusedWindow(timeoutMs: Long = 5_000): Boolean {
            ensureAlive()
            val deadline = SystemClock.uptimeMillis() + timeoutMs
            while (SystemClock.uptimeMillis() < deadline) {
                if (isWindowFocused) return true
                Thread.sleep(50)
            }
            return isWindowFocused
        }

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
        fun report(): String {
            val activity = singleton.get()
            return buildString {
                appendLine("manufacturer=${Build.MANUFACTURER}")
                appendLine("model=${Build.MODEL}")
                appendLine("sdk=${Build.VERSION.SDK_INT}")
                appendLine("abis=${Build.SUPPORTED_ABIS.joinToString(",")}")
                appendLine("cores=${Runtime.getRuntime().availableProcessors()}")
                appendLine("sustainedSupported=${activity?.sustainedSupportedSnapshot()}")
                appendLine("sustainedInUse=$sustainedPerformanceModeInUse")
                appendLine("sustainedSetResult=$sustainedSetResult")
                appendLine("resumed=$resumeObserved")
                appendLine("hasWindowFocus=${activity?.hasWindowFocus()}")
                appendLine("thermalStatus=${activity?.thermalStatus()}")
            }
        }
    }
}