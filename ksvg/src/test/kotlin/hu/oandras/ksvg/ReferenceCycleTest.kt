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

package hu.oandras.ksvg

import android.graphics.Bitmap
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * Reference cycles must terminate (no hang, no `StackOverflowError`).
 * `fillInChainedGradientFields` / `fillInChainedPatternFields` only guard
 * self-references, and `buildMask` has no `buildingIds` guard (only the
 * end-of-build cache), so only cycles *not* containing the entry point or
 * id-less content can loop. These tests pin termination; the exact fallback
 * rendering of a broken chain is deliberately unasserted here.
 *
 * Hang-type regressions (e.g., render-time mask recursion) would stall the
 * suite forever, so every test carries a JUnit timeout: a stuck render fails
 * fast instead. (Coroutine `withTimeout` would not help: cancellation is
 * cooperative and the render loop never suspends. Note the timeout only fails
 * the test — a runaway thread keeps spinning in the background.)
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class ReferenceCycleTest {

    private companion object {
        // A healthy render of these 200x200 SVGs takes ~10-20 ms, so this is
        // ~1000x headroom. `@Before` warm-up keeps the one-time Robolectric
        // native-runtime load (~3.7 s) out of the timed window, so a slow CI
        // machine cannot flake the budget.
        const val HANG_BUDGET_MS = 15_000L
    }

    @Before
    fun warmUpNativeRuntime() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="8" height="8">
              <rect width="8" height="8" fill="red"/>
            </svg>
            """.trimIndent()
        )
    }

    private fun renders(svg: String): Bitmap {
        return renderWithLibrary(svg, createBitmap(200, 200, Bitmap.Config.ARGB_8888))
    }

    @Test(timeout = HANG_BUDGET_MS)
    fun gradientHrefCycleTerminates() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <linearGradient id="a" href="#b"/>
                <linearGradient id="b" href="#c">
                  <stop offset="0" stop-color="red"/>
                  <stop offset="1" stop-color="blue"/>
                </linearGradient>
                <linearGradient id="c" href="#b"/>
              </defs>
              <rect width="200" height="200" fill="url(#a)"/>
            </svg>
            """.trimIndent()
        )
    }

    @Test(timeout = HANG_BUDGET_MS)
    fun gradientSelfReferenceTerminates() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <linearGradient id="a" href="#a">
                  <stop offset="0" stop-color="red"/>
                  <stop offset="1" stop-color="blue"/>
                </linearGradient>
              </defs>
              <rect width="200" height="200" fill="url(#a)"/>
            </svg>
            """.trimIndent()
        )
    }

    @Test(timeout = HANG_BUDGET_MS)
    fun patternHrefCycleTerminates() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <pattern id="pa" href="#pb" width="20" height="20" patternUnits="userSpaceOnUse"/>
                <pattern id="pb" href="#pc" width="20" height="20" patternUnits="userSpaceOnUse">
                  <rect width="20" height="20" fill="red"/>
                </pattern>
                <pattern id="pc" href="#pb" width="20" height="20" patternUnits="userSpaceOnUse"/>
              </defs>
              <rect width="200" height="200" fill="url(#pa)"/>
            </svg>
            """.trimIndent()
        )
    }

    @Test(timeout = HANG_BUDGET_MS)
    fun maskInMaskTerminates() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <mask id="m1">
                  <rect width="200" height="200" fill="white" mask="url(#m2)"/>
                </mask>
                <mask id="m2">
                  <rect width="200" height="200" fill="white" mask="url(#m1)"/>
                </mask>
              </defs>
              <rect width="200" height="200" fill="red" mask="url(#m1)"/>
            </svg>
            """.trimIndent()
        )
    }
}
