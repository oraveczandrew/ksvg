/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.baselineprofile

import androidx.benchmark.macro.junit4.BaselineProfileRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Until
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.util.regex.Pattern

/**
 * Generates the showcase baseline profile (`generateBaselineProfile`).
 *
 * Journeys mirror the janky paths from the Perfetto traces: cold startup
 * plus grid flings (parse → buildScene → first renderDocument → JIT).
 */
@RunWith(AndroidJUnit4::class)
class BaselineProfileGenerator {

    @get:Rule
    val rule = BaselineProfileRule()

    @Test
    fun startup() = rule.collect(PACKAGE) {
        pressHome()
        startActivityAndWait()
        device.waitForIdle()
    }

    @Test
    fun renderAll() = rule.collect(PACKAGE) {
        pressHome()
        val intent = android.content.Intent(android.content.Intent.ACTION_MAIN).apply {
            addCategory(android.content.Intent.CATEGORY_LAUNCHER)
            setClassName(PACKAGE, "$PACKAGE.RenderAllActivity")
        }
        startActivityAndWait(intent)
        // RenderAllActivity shows "compiling... i/N", then "DONE (ok/N)".
        val done = java.util.regex.Pattern.compile(".*DONE.*")
        device.wait(Until.hasObject(By.text(done)), 600_000)
        device.pressBack()
    }

    @Test
    fun scrollGrid() = rule.collect(PACKAGE) {
        pressHome()
        startActivityAndWait()
        // Launcher is HomeActivity: open the classic (Views) gallery list.
        // NOTE: AppCompat buttons render textAllCaps, so match case-insensitively.
        // NOTE 2: By.text(Pattern) requires a FULL match — wrap in .*.*.
        val classic = Pattern.compile(".*classic.*", Pattern.CASE_INSENSITIVE)
        if (!device.wait(Until.hasObject(By.text(classic)), 10_000)) {
            val texts = device.findObjects(By.clickable(true)).mapNotNull { it.text }
            throw AssertionError("classic button not found; clickable texts=$texts")
        }
        device.findObject(By.text(classic)).click()
        device.wait(Until.hasObject(By.clazz("androidx.recyclerview.widget.RecyclerView")), 10_000)
        device.waitForIdle()
        val w = device.displayWidth
        val h = device.displayHeight
        repeat(6) {
            // fling up, then settle: exercises fresh-cell bind + first draw
            device.swipe(w / 2, h * 3 / 4, w / 2, h / 4, 12)
            device.waitForIdle()
            device.swipe(w / 2, h / 4, w / 2, h * 3 / 4, 12)
            device.waitForIdle()
        }
    }

    companion object {
        private const val PACKAGE = "hu.oandras.ksvg.showcase"
    }
}
