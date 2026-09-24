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
import android.content.Context
import android.os.PowerManager
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Step-0 spike (see TEST_HARNESS_PLAN.md Step 0): proves that a [BenchmarkActivity]
 * declared in the test APK's manifest can come to the foreground of the connected device
 * and that `setSustainedPerformanceMode(true)` is callable/observable there.
 *
 * The result is only ever reported ([BenchmarkActivity.report], logcat tag
 * "BenchmarkSpike"); a silently-ignoring device is a valid outcome.
 */
@RunWith(AndroidJUnit4::class)
class BenchmarkActivitySpikeTest {

    @Test
    fun launchActivity_andReportEnvironment() {
        // Activity launch can time out waiting for an idle main
        // thread after marathon benchmark runs (hot, throttled, possibly
        // non-interactive device). Retry with backoff and dump the device state
        // on every attempt, so the next timeout names its cause instead of
        // just saying "not idle".
        var activity: Activity? = null
        var lastError: Throwable? = null
        for (attempt in 1..LAUNCH_ATTEMPTS) {
            try {
                activity = BenchmarkActivity.launchSingleton()
                lastError = null
                break
            } catch (t: Throwable) {
                lastError = t
                Log.w("BenchmarkSpike", "launch attempt $attempt/$LAUNCH_ATTEMPTS failed: $t")
                Log.w("BenchmarkSpike", environmentReport("attempt-$attempt-failure"))
                if (attempt < LAUNCH_ATTEMPTS) Thread.sleep(LAUNCH_RETRY_DELAY_MS)
            }
        }
        if (activity == null) {
            Log.e("BenchmarkSpike", environmentReport("final-failure"))
            fail("BenchmarkActivity launch failed after $LAUNCH_ATTEMPTS attempts: $lastError")
        }
        val launched = activity!!

        // The app's activity is RESUMED immediately, but the Window only gains focus once the
        // screen is interactive and no keyguard/other window covers it. Sample the transition
        // to learn whether the test-APK activity ever becomes the focused window on this
        // device during a run.
        var everFocused = false
        repeat(FOCUS_SAMPLE_COUNT) {
            val focused = launched.hasWindowFocus()
            if (focused) everFocused = true
            Log.i(
                "BenchmarkSpike",
                "focusSample t=${((it + 1) * FOCUS_SAMPLE_INTERVAL_MS).toString().padStart(4)}ms " +
                    "focused=$focused interactive=${launched.powerManagerInteractive()}"
            )
            Thread.sleep(FOCUS_SAMPLE_INTERVAL_MS)
        }

        assertTrue("BenchmarkActivity must reach RESUME", BenchmarkActivity.resumeObserved)
        Log.i("BenchmarkSpike", "everFocused=$everFocused (final=${launched.hasWindowFocus()})")
        Log.i("BenchmarkSpike", environmentReport("success"))

        val report = BenchmarkActivity.report()
        Log.i("BenchmarkSpike", report)
        println(report)

        BenchmarkActivity.finishSingleton()
    }

    private fun Activity.powerManagerInteractive(): Boolean =
        (getSystemService(Context.POWER_SERVICE) as? PowerManager)?.isInteractive ?: false

    /**
     * One-line device-state snapshot for launch-timeout forensics: interactive
     * screen, keyguard, thermal status, resume/focus flags. Best-effort —
     * every probe is individually guarded so diagnostics never throw.
     */
    private fun environmentReport(tag: String): String {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val interactive = try {
            (ctx.getSystemService(Context.POWER_SERVICE) as? PowerManager)?.isInteractive
        } catch (_: Exception) {
            null
        }
        val keyguardLocked = try {
            (ctx.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager)?.isKeyguardLocked
        } catch (_: Exception) {
            null
        }
        val thermal = try {
            ThermalStateMonitor.create(ctx).currentThermalStatus()
        } catch (_: Exception) {
            null
        }
        return "BenchmarkSpike env[$tag]: interactive=$interactive " +
            "keyguardLocked=$keyguardLocked thermalStatus=$thermal " +
            "resumed=${BenchmarkActivity.resumeObserved} focused=${BenchmarkActivity.isWindowFocused}"
    }

    companion object {
        private const val FOCUS_SAMPLE_COUNT = 30
        private const val FOCUS_SAMPLE_INTERVAL_MS = 100L
        private const val LAUNCH_ATTEMPTS = 3
        private const val LAUNCH_RETRY_DELAY_MS = 5_000L
    }
}