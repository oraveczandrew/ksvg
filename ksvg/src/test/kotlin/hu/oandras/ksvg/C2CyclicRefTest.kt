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

import android.graphics.Canvas
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Phase 0 baseline (C2): Cyclic `<use>` / `clip-path` references crash.
 *
 * `RenderTreeBuilder.buildUse` and `buildClipPath` recurse without a visited-set,
 * so an A→B→A reference cycle causes unbounded recursion (StackOverflowError)
 * instead of being treated as an empty/missing reference per spec.
 *
 * These tests assert the CORRECT behaviour (no crash). Today they fail because
 * rendering throws.
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class C2CyclicRefTest {

    @Test
    fun cyclicUseDoesNotCrash() {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <g id="a"><use href="#b"/></g>
                <g id="b"><use href="#a"/></g>
              </defs>
              <use href="#a"/>
            </svg>
        """.trimIndent()

        try {
            val document = SVG.getFromString(svg)
            val canvas = Canvas(createBitmap(100, 100))
            document.renderToCanvas(canvas)
        } catch (e: Throwable) {
            fail("Cyclic <use> reference crashed rendering with: ${e::class.java.simpleName}: ${e.message}")
        }
    }

    @Test
    fun cyclicClipPathDoesNotCrash() {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <clipPath id="a" clip-path="url(#b)"><rect width="50" height="50"/></clipPath>
                <clipPath id="b" clip-path="url(#a)"><rect width="50" height="50"/></clipPath>
              </defs>
              <rect width="100" height="100" clip-path="url(#a)"/>
            </svg>
        """.trimIndent()

        try {
            val document = SVG.getFromString(svg)
            val canvas = Canvas(createBitmap(100, 100))
            document.renderToCanvas(canvas)
        } catch (e: Throwable) {
            fail("Cyclic clip-path reference crashed rendering with: ${e::class.java.simpleName}: ${e.message}")
        }
    }
}
