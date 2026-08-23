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

import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Defs
import hu.oandras.ksvg.dom.gradient.Gradient
import hu.oandras.ksvg.dom.gradient.Stop
import hu.oandras.ksvg.utils.forEachElement
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * Phase 0 baseline (C4): `stop` offset clamp is `[0,100]` instead of `[0,1]`.
 *
 * `Stop.parseGradientOffset` (dom/gradient/Stop.kt) divides a `%` by 100 but then
 * clamps the result to `[0, 100]`. So `offset="120%"` stores `1.2f` and
 * `offset="150"` stores `100f` — both outside the valid `[0,1]` shader range.
 *
 * These tests assert the CORRECT behaviour (clamp to `[0,1]`). Today they fail.
 */
@RunWith(RobolectricTestRunner::class)
class C4StopOffsetTest {

    private fun collectOffsets(svg: String): List<Float> {
        val document = SVG.getFromString(svg) as SVGImpl
        val root = document.requireRootElement()
        val offsets = mutableListOf<Float>()
        root.getChildren().forEachElement { child ->
            if (child is Defs) {
                child.getChildren().forEachElement { defsChild ->
                    if (defsChild is Gradient) {
                        defsChild.getChildren().forEachElement { gradientChild ->
                            if (gradientChild is Stop) {
                                offsets.add(gradientChild.offset)
                            }
                        }
                    }
                }
            }
        }
        return offsets
    }

    @Test
    fun percentageOverOneClampsToOne() {
        val offsets = collectOffsets(
            """
            <svg xmlns="http://www.w3.org/2000/svg">
              <defs>
                <linearGradient id="g">
                  <stop offset="0%" stop-color="red"/>
                  <stop offset="120%" stop-color="blue"/>
                </linearGradient>
              </defs>
            </svg>
            """.trimIndent()
        )
        assertEquals(listOf(0f, 1.2f), offsets)
        // Correct behaviour: 120% -> 1.0f
        assertEquals(1.0f, offsets[1], 0.001f)
    }

    @Test
    fun unitlessOverOneClampsToOne() {
        val offsets = collectOffsets(
            """
            <svg xmlns="http://www.w3.org/2000/svg">
              <defs>
                <linearGradient id="g">
                  <stop offset="0" stop-color="red"/>
                  <stop offset="150" stop-color="blue"/>
                </linearGradient>
              </defs>
            </svg>
            """.trimIndent()
        )
        assertEquals(1.0f, offsets[1], 0.001f)
    }

    @Test
    fun percentageUnderOneKeepsFraction() {
        val offsets = collectOffsets(
            """
            <svg xmlns="http://www.w3.org/2000/svg">
              <defs>
                <linearGradient id="g">
                  <stop offset="0%" stop-color="red"/>
                  <stop offset="50%" stop-color="blue"/>
                </linearGradient>
              </defs>
            </svg>
            """.trimIndent()
        )
        assertEquals(0.5f, offsets[1], 0.001f)
    }
}
