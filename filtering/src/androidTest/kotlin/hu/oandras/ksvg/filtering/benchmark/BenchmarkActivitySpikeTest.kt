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
import android.content.Context
import android.os.PowerManager
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertTrue
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
        val activity = BenchmarkActivity.launchSingleton()

        // The app's activity is RESUMED immediately, but the Window only gains focus once the
        // screen is interactive and no keyguard/other window covers it. Sample the transition
        // to learn whether the test-APK activity ever becomes the focused window on this
        // device during a run.
        var everFocused = false
        repeat(FOCUS_SAMPLE_COUNT) {
            val focused = activity.hasWindowFocus()
            if (focused) everFocused = true
            Log.i(
                "BenchmarkSpike",
                "focusSample t=${((it + 1) * FOCUS_SAMPLE_INTERVAL_MS).toString().padStart(4)}ms " +
                    "focused=$focused interactive=${activity.powerManagerInteractive()}"
            )
            Thread.sleep(FOCUS_SAMPLE_INTERVAL_MS)
        }

        assertTrue("BenchmarkActivity must reach RESUME", BenchmarkActivity.resumeObserved)
        Log.i("BenchmarkSpike", "everFocused=$everFocused (final=${activity.hasWindowFocus()})")

        val report = BenchmarkActivity.report()
        Log.i("BenchmarkSpike", report)
        println(report)

        BenchmarkActivity.finishSingleton()
    }

    private fun Activity.powerManagerInteractive(): Boolean =
        (getSystemService(Context.POWER_SERVICE) as? PowerManager)?.isInteractive ?: false

    companion object {
        private const val FOCUS_SAMPLE_COUNT = 30
        private const val FOCUS_SAMPLE_INTERVAL_MS = 100L
    }
}