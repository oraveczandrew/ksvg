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

@file:Suppress("SpellCheckingInspection") // AGSL builtins

package hu.oandras.ksvg.render.filters.pipeline.effects

import android.graphics.RectF
import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.os.Build
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.utils.ceilToInt
import kotlin.math.abs

/**
 * Separable two-pass min/max (horizontal pass, then vertical pass), matching
 * the CPU `KotlinKernels.morphology` reference up to platform-rounding races
 * (see below). The old single-pass 41x41 shader exceeded the Skia program
 * limit on strict drivers (`IllegalArgumentException: program is too large`
 * from `RuntimeShader.<init>`); min/max over a rectangle is associative, so a
 * `(2*rx+1)x(2*ry+1)` window splits into a `(2*rx+1)` horizontal pass and a
 * `(2*ry+1)` vertical pass with at most 41 taps each.
 *
 * Representation (verified on-device): the chain input taps carry
 * PREMULTIPLIED values (a radius-0 passthrough is bit-exact against the
 * integer-premultiplied software reference at every alpha, and a translucent
 * single-dot dilate emits exactly the dot's premultiplied value), while the
 * software bitmap holds the same color in straight form (the parity harness
 * converts the reference via exact integer math).
 *
 * Winner selection compares STRAIGHT values (`rgb / max(a, eps)`), exactly
 * like the kernel's per-channel min/max over straight `getPixels` ints —
 * comparing premultiplied taps instead picks different winners wherever
 * alpha varies. The emitted pixel is the winning tap VERBATIM (re-multiplying
 * by alpha double-premultiplies: a translucent-dot probe emits 64 instead of
 * 128). Float32 division preserves the integer order: distinct straight
 * rationals (denominators <= 255) differ by >= 1.5e-5, far above fp32
 * rounding, and exact ties round identically, so winners match the kernel
 * (same scan order + strict inequalities keep the first extreme on ties).
 *
 * Scan order is row-major, top-left first, with strict inequalities: the
 * horizontal pass keeps the leftmost extreme per row, the vertical pass keeps
 * the topmost row extreme, which together select the row-major first extreme.
 * The accumulator starts at +/- infinity (never at the center tap) to
 * preserve that order.
 *
 * Each pass returns `float4` (not `half4`): the horizontal intermediate is
 * re-divided by the vertical pass, and an fp16 round-trip there could flip
 * close winner races. The final pass keeps the same precision so both passes
 * share one shader.
 *
 * `uInterior` (left, top, right, bottom, in `fragCoord` space) replicates the
 * kernel's write rule: erode writes only `[max(clip, r), min(clip, size - r))`
 * (everything else stays transparent), while dilate covers the full clip rect
 * with clamped windows — the host side passes the clip rect as `uInterior`
 * for dilate. The horizontal pass of a two-pass chain writes the interior
 * expanded by the vertical radius (the rows the vertical pass will read);
 * the vertical pass applies the final rule. Radius is clamped to 20 per axis
 * (as before).
 */
private const val MORPHOLOGY_ERODE_1D_SHADER: String = """
            uniform shader uInput;
            uniform float uRadius;
            uniform int uHorizontal;
            uniform float4 uInterior;
            float4 main(float2 fragCoord) {
                if (fragCoord.x < uInterior.x || fragCoord.x >= uInterior.z ||
                    fragCoord.y < uInterior.y || fragCoord.y >= uInterior.w) {
                    return float4(0.0);
                }
                int r = int(min(ceil(abs(uRadius)), 20.0));
                float bsR = 1e30;
                float bsG = 1e30;
                float bsB = 1e30;
                float br = 0.0;
                float bg = 0.0;
                float bb = 0.0;
                float ba = 1e30;
                for (int k = 0; k <= 40; ++k) {
                    int kk = k - 20;
                    if (kk >= -r && kk <= r) {
                        float fk = float(kk);
                        float2 off = uHorizontal != 0 ? float2(fk, 0.0) : float2(0.0, fk);
                        float4 c = uInput.eval(fragCoord + off);
                        float a = c.a;
                        float3 s = c.rgb / max(a, 1e-6);
                        if (s.r < bsR) { bsR = s.r; br = c.r; }
                        if (s.g < bsG) { bsG = s.g; bg = c.g; }
                        if (s.b < bsB) { bsB = s.b; bb = c.b; }
                        if (a < ba) { ba = a; }
                    }
                }
                return float4(br, bg, bb, ba);
            }
        """

private const val MORPHOLOGY_DILATE_1D_SHADER: String = """
            uniform shader uInput;
            uniform float uRadius;
            uniform int uHorizontal;
            uniform float4 uInterior;
            float4 main(float2 fragCoord) {
                if (fragCoord.x < uInterior.x || fragCoord.x >= uInterior.z ||
                    fragCoord.y < uInterior.y || fragCoord.y >= uInterior.w) {
                    return float4(0.0);
                }
                int r = int(min(ceil(abs(uRadius)), 20.0));
                float bsR = -1e30;
                float bsG = -1e30;
                float bsB = -1e30;
                float br = 0.0;
                float bg = 0.0;
                float bb = 0.0;
                float ba = -1e30;
                for (int k = 0; k <= 40; ++k) {
                    int kk = k - 20;
                    if (kk >= -r && kk <= r) {
                        float fk = float(kk);
                        float2 off = uHorizontal != 0 ? float2(fk, 0.0) : float2(0.0, fk);
                        float4 c = uInput.eval(fragCoord + off);
                        float a = c.a;
                        float3 s = c.rgb / max(a, 1e-6);
                        if (s.r > bsR) { bsR = s.r; br = c.r; }
                        if (s.g > bsG) { bsG = s.g; bg = c.g; }
                        if (s.b > bsB) { bsB = s.b; bb = c.b; }
                        if (a > ba) { ba = a; }
                    }
                }
                return float4(br, bg, bb, ba);
            }
        """

/**
 * Builds one 1D pass of an Impl33 morphology chain: the configured
 * [RuntimeShader] (kept by the caller for downstream `resultShaders`
 * lookups) plus the [RenderEffect] wrapping it under [inputUniformName].
 * The caller chains a horizontal pass (over the interior expanded by the
 * vertical radius) with a vertical pass (over the final interior); a
 * zero-radius axis is skipped, so at least one pass always runs.
 *
 * @param erode false selects the dilate (max) variant, true the erode (min).
 * @param horizontal true samples `fragCoord + (k, 0)`, false `(0, k)`.
 * @param radius the 1D morphology radius in bitmap pixels for this pass
 * (`radius * scale`, matching the CPU `ceilToInt` conversion).
 * @param interiorLeft interiorTop interiorRight interiorBottom the write
 * window for this pass in `fragCoord` space (see the file KDoc).
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
private fun createMorphologyPassShaderEffect(
    erode: Boolean,
    horizontal: Boolean,
    radius: Float,
    interiorLeft: Float,
    interiorTop: Float,
    interiorRight: Float,
    interiorBottom: Float,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect> {
    val shader = RuntimeShader(if (erode) MORPHOLOGY_ERODE_1D_SHADER else MORPHOLOGY_DILATE_1D_SHADER)
    shader.setFloatUniform("uRadius", radius)
    shader.setIntUniform("uHorizontal", if (horizontal) 1 else 0)
    shader.setFloatUniform("uInterior", interiorLeft, interiorTop, interiorRight, interiorBottom)
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}

/**
 * Assembled but unchained morphology passes: the caller wires [headEffect]
 * onto its input and [tailEffect] onto the chained head (when [twoPass]),
 * and runs the usual `resultShaders` bookkeeping ([headShader] needs the
 * previous-input binding, [tailShader] is the result downstream raw
 * references must see). In the single-pass case head and tail are the same
 * pass.
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal class MorphologyPasses(
    @JvmField val headShader: RuntimeShader,
    @JvmField val headEffect: RenderEffect,
    @JvmField val tailShader: RuntimeShader,
    @JvmField val tailEffect: RenderEffect,
    @JvmField val twoPass: Boolean,
)

/**
 * Builds the full 1D pass set of an Impl33 morphology primitive (interior
 * rule, pass assembly and raw pass-to-pass wiring included), leaving only
 * input chaining and `resultShaders` bookkeeping to the caller. Returns
 * null when the AGSL program fails to compile (e.g. `program is too large`
 * on strict drivers) so the caller can decline to the software backend
 * instead of crashing.
 *
 * @param erode false selects the dilate (max) variant, true the erode (min).
 * @param radiusX radiusY the morphology radii in bitmap pixels
 * (`radius * scale`, matching the CPU `ceilToInt` conversion).
 * @param primitiveRegion the primitive's user-space subregion (read only).
 * @param filterRegion the filter region in user space.
 * @param scaleX scaleY the primitive-unit scale; [sx] [sy] the buffer scale.
 * @param totalPadX totalPadY the chain padding in buffer pixels.
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createMorphologyShaderEffect(
    erode: Boolean,
    radiusX: Float,
    radiusY: Float,
    primitiveRegion: RectF,
    filterRegion: RectF,
    scaleX: Float,
    scaleY: Float,
    sx: Float,
    sy: Float,
    totalPadX: Int,
    totalPadY: Int,
    inputUniformName: String,
): MorphologyPasses? {
    // Interior rule (matches the CPU-kernel write window). Erode writes
    // only [max(clip, r), min(clip, size - r)) — everything else stays
    // transparent. Dilate instead covers the full clip rect with clamped
    // windows, so it gets the unshrunk clip. Coordinates reuse the lighting
    // mapping into fragCoord space.
    val radiusWsX = if (scaleX != 0f) radiusX * (sx / scaleX) else 0f
    val radiusWsY = if (scaleY != 0f) radiusY * (sy / scaleY) else 0f
    val clipL = (primitiveRegion.left - filterRegion.left) * sx + totalPadX
    val clipT = (primitiveRegion.top - filterRegion.top) * sy + totalPadY
    val clipR = (primitiveRegion.right - filterRegion.left) * sx + totalPadX
    val clipB = (primitiveRegion.bottom - filterRegion.top) * sy + totalPadY
    val inputR = totalPadX + filterRegion.width() * sx
    val inputB = totalPadY + filterRegion.height() * sy
    val finalL: Float
    val finalT: Float
    val finalR: Float
    val finalB: Float
    if (erode) {
        finalL = maxOf(clipL, totalPadX + radiusWsX)
        finalT = maxOf(clipT, totalPadY + radiusWsY)
        finalR = minOf(clipR, inputR - radiusWsX)
        finalB = minOf(clipB, inputB - radiusWsY)
    } else {
        finalL = clipL
        finalT = clipT
        finalR = clipR
        finalB = clipB
    }
    // Separable passes (mirrors the CPU kernel): a zero-radius axis is
    // skipped, but at least one pass always runs so the interior rule
    // applies even at radius 0. Effective radii match the shader's
    // `min(ceil(abs(uRadius)), 20)`.
    val buildH = abs(radiusX).ceilToInt().coerceAtMost(20) > 0
    val buildV = abs(radiusY).ceilToInt().coerceAtMost(20) > 0 || !buildH
    // No local try/catch: AGSL assembly failures propagate to the shared
    // tryBuildChain choke point, which declines to software (see
    // GpuFilterBackend).
    var headShader: RuntimeShader? = null
    var headEffect: RenderEffect? = null
    var tailShader: RuntimeShader? = null
    var tailEffect: RenderEffect? = null
    if (buildH) {
        // The horizontal pass covers the rows the vertical pass will
        // read (expanded by the vertical radius); a lone pass uses the
        // final interior.
        val hTop = if (buildV) finalT - radiusWsY else finalT
        val hBottom = if (buildV) finalB + radiusWsY else finalB
        val (hShader, hEffect) = createMorphologyPassShaderEffect(
            erode = erode,
            horizontal = true,
            radius = radiusX,
            interiorLeft = finalL,
            interiorTop = hTop,
            interiorRight = finalR,
            interiorBottom = hBottom,
            inputUniformName = inputUniformName,
        )
        headShader = hShader
        headEffect = hEffect
        tailShader = hShader
        tailEffect = hEffect
    }
    if (buildV) {
        val (vShader, vEffect) = createMorphologyPassShaderEffect(
            erode = erode,
            horizontal = false,
            radius = radiusY,
            interiorLeft = finalL,
            interiorTop = finalT,
            interiorRight = finalR,
            interiorBottom = finalB,
            inputUniformName = inputUniformName,
        )
        val prevShader = headShader
        if (prevShader != null) {
            // The raw-shader path must see the full two-pass result
            // through the final shader.
            vShader.setInputShader("uInput", prevShader)
        }
        tailShader = vShader
        tailEffect = vEffect
        if (headShader == null) {
            headShader = vShader
            headEffect = vEffect
        }
    }
    val head = headShader ?: return null
    val headE = headEffect ?: return null
    val tail = tailShader ?: return null
    val tailE = tailEffect ?: return null
    return MorphologyPasses(head, headE, tail, tailE, buildH && buildV)
 }
