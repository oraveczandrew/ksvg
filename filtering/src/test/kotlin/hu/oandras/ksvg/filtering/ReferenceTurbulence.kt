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

import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.roundToInt

/**
 * Isolated duplicate of the KSVG feTurbulence kernel ([KotlinKernels.turbulence])
 * that consumes librsvg's ACTUAL runtime inputs directly — per-pixel user-space
 * point, per-pixel tile coords, post-stitch base frequencies — instead of
 * reconstructing those coordinates from clip/userLeft/invCanvasScale/unitSize.
 *
 * Used by [TurbulenceKernelParityTest] to answer: given exactly the inputs librsvg
 * used, does the KSVG octave loop (Perlin noise2 + stitch wrapping + energy
 * accumulation) reproduce librsvg's raw output bit-exactly?
 *
 * The file intentionally mirrors `KotlinKernels.turbulence`'s inner octave loop so
 * the comparison isolates kernel math and nothing else. The one intentionally
 * parameterized bit is the per-octave stitch-wrap rule, because librsvg and KSVG
 * derive it differently (see [WrapRule]).
 *
 * Wrap-rule background (from the capture format spec / turbulence.rs):
 *   librsvg: wrap0 = (tile * bf) as usize + PERLIN_N + width; then per octave
 *            width *= 2, wrap = 2*wrap - PERLIN_N  => wrap_k = 2^k*floor(tile*bf) + 4096 + 2^k*width.
 *   KSVG:    wrap_k = floor(2^k * tile * bf) + 4096 + 2^k*width  (recomputed from a
 *            doubled `curtlx`). Differs when frac(tile*bf) >= 1/2.
 */
internal object ReferenceTurbulence {

    internal enum class WrapRule {
        /** librsvg: keep doubling the previous (already wrapped) value. */
        LIRSVC_DOUBLE_WRAP,

        /** KSVG production (KotlinKernels.kt): recompute from doubled tile coord. */
        KSVG_RECOMPUTE_FROM_TILE,
    }

    /** Per-octave intermediate state, mirroring librsvg's captured per-octave data. */
    internal class OctaveTrace(
        val vecX: Double,
        val vecY: Double,
        val stW: Int,
        val stH: Int,
        val wrapX: Int,
        val wrapY: Int,
        val noise: Double,
        val runningValue: Double,
    )

    /**
     * Runs the KSVG octave loop for ONE color channel of ONE pixel.
     *
     * @param curtlx0 / [curtly0] tile coordinate scaled by the post-stitch base
     *        frequency (= tileX * baseFrequencyX / tileY * baseFrequencyY). This is
     *        the quantity librsvg wraps on (`(tile * bf) as usize`) and KSVG
     *        recomputes from (`floor(curtlx)`) — the caller computes it from the
     *        captured record so both rules share the identical product.
     * @param px0 / [py0] Perlin lattice coordinates for octave 0
     *        (= user-space point * post-stitch base frequency, librsvg's convention,
     *        caller supplies them verbatim from the capture).
     * @param periodX / [periodY] initial stitch period (librsvg `width`/`height`,
     *        = (tileWidth * bf + 0.5) as usize). 0 => no stitching.
     */
    internal fun octaveLoop(
        px0: Double,
        py0: Double,
        curtlx0: Double,
        curtly0: Double,
        periodX: Int,
        periodY: Int,
        octaves: Int,
        fractalNoise: Boolean,
        generator: SvgPathNoise,
        wrapRule: WrapRule,
    ): List<OctaveTrace> {
        val traces = ArrayList<OctaveTrace>(octaves)
        var value = 0.0
        var ratio = 1.0
        var px = px0
        var py = py0
        var octavePeriodX = periodX
        var octavePeriodY = periodY
        var curtlx = curtlx0
        var curtly = curtly0
        var librsvgWrapX = 0
        var librsvgWrapY = 0
        // librsvg does not instantiate StitchInfo (nor set oct_wrap_x/y) unless
        // stitching is active; the capture therefore reports wrap = 0 for the
        // no-stitch case regardless of any coordinate arithmetic.
        val stitching = periodX > 0 || periodY > 0

        for (octave in 0 until octaves) {
            val wrapX: Int
            val wrapY: Int
            if (!stitching) {
                wrapX = 0
                wrapY = 0
            } else when (wrapRule) {
                WrapRule.LIRSVC_DOUBLE_WRAP -> {
                    if (octave == 0) {
                        librsvgWrapX = floor(curtlx0).toInt() + 4096 + octavePeriodX
                        librsvgWrapY = floor(curtly0).toInt() + 4096 + octavePeriodY
                    } else {
                        librsvgWrapX = 2 * librsvgWrapX - 4096
                        librsvgWrapY = 2 * librsvgWrapY - 4096
                    }
                    wrapX = librsvgWrapX
                    wrapY = librsvgWrapY
                }
                WrapRule.KSVG_RECOMPUTE_FROM_TILE -> {
                    wrapX = floor(curtlx).toInt() + 4096 + octavePeriodX
                    wrapY = floor(curtly).toInt() + 4096 + octavePeriodY
                }
            }

            val n = generator.noise2(px, py, octavePeriodX, octavePeriodY, wrapX, wrapY)
            value += if (fractalNoise) n / ratio else abs(n) / ratio
            traces.add(
                OctaveTrace(
                    vecX = px,
                    vecY = py,
                    stW = octavePeriodX,
                    stH = octavePeriodY,
                    wrapX = wrapX,
                    wrapY = wrapY,
                    noise = n,
                    runningValue = value,
                )
            )
            px *= 2.0
            py *= 2.0
            curtlx *= 2.0
            curtly *= 2.0
            ratio *= 2.0
            if (periodX > 0 || periodY > 0) {
                octavePeriodX *= 2
                octavePeriodY *= 2
            }
        }
        return traces
    }

    /** Final channel conversion, matching KotlinKernels.clamp255 (roundToInt + coerceIn). */
    internal fun finalChannel(value: Double, fractalNoise: Boolean): Int {
        val finalVal = if (fractalNoise) (value + 1.0) * 127.5 else value * 255.0
        return finalVal.roundToInt().coerceIn(0, 255)
    }
}