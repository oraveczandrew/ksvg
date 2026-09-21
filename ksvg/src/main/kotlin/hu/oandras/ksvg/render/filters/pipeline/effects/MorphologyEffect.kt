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

import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.os.Build
import androidx.annotation.RequiresApi

/**
 * Full-window min/max with premultiplied output, matching the CPU
 * `KotlinKernels.morphology` reference up to platform-rounding races (see
 * below).
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
 * Scan order is row-major, top-left first, with strict inequalities. The
 * accumulator starts at +/- infinity (never at the center tap) to preserve
 * that order.
 *
 * `uInterior` (left, top, right, bottom, in `fragCoord` space) replicates the
 * kernel's write rule: erode writes only `[max(clip, r), min(clip, size - r))`
 * (everything else stays transparent), while dilate covers the full clip rect
 * with clamped windows — the host side passes the clip rect as `uInterior`
 * for dilate.
 *
 * Residual non-exactness: the platform integer unpremultiply behind
 * `getPixels` can round 1 LSB away from the shader's float division, which
 * may flip close winner races; plus the PNG premultiply round-trip both
 * inputs share. Radius is clamped to 20 per axis (as before).
 */
private const val MORPHOLOGY_ERODE_SHADER: String = """
            uniform shader uInput;
            uniform float2 uRadius;
            uniform float4 uInterior;
            half4 main(float2 fragCoord) {
                if (fragCoord.x < uInterior.x || fragCoord.x >= uInterior.z ||
                    fragCoord.y < uInterior.y || fragCoord.y >= uInterior.w) {
                    return half4(0.0);
                }
                int rx = int(min(ceil(abs(uRadius.x)), 20.0));
                int ry = int(min(ceil(abs(uRadius.y)), 20.0));
                float bsR = 1e30;
                float bsG = 1e30;
                float bsB = 1e30;
                float br = 0.0;
                float bg = 0.0;
                float bb = 0.0;
                float ba = 1e30;
                for (int j = 0; j <= 40; ++j) {
                    int jj = j - 20;
                    for (int i = 0; i <= 40; ++i) {
                        int ii = i - 20;
                        if (ii >= -rx && ii <= rx && jj >= -ry && jj <= ry) {
                            float4 c = uInput.eval(fragCoord + float2(float(ii), float(jj)));
                            float a = c.a;
                            float3 s = c.rgb / max(a, 1e-6);
                            if (s.r < bsR) { bsR = s.r; br = c.r; }
                            if (s.g < bsG) { bsG = s.g; bg = c.g; }
                            if (s.b < bsB) { bsB = s.b; bb = c.b; }
                            if (a < ba) { ba = a; }
                        }
                    }
                }
                return half4(br, bg, bb, ba);
            }
        """

private const val MORPHOLOGY_DILATE_SHADER: String = """
            uniform shader uInput;
            uniform float2 uRadius;
            uniform float4 uInterior;
            half4 main(float2 fragCoord) {
                if (fragCoord.x < uInterior.x || fragCoord.x >= uInterior.z ||
                    fragCoord.y < uInterior.y || fragCoord.y >= uInterior.w) {
                    return half4(0.0);
                }
                int rx = int(min(ceil(abs(uRadius.x)), 20.0));
                int ry = int(min(ceil(abs(uRadius.y)), 20.0));
                float bsR = -1e30;
                float bsG = -1e30;
                float bsB = -1e30;
                float br = 0.0;
                float bg = 0.0;
                float bb = 0.0;
                float ba = -1e30;
                for (int j = 0; j <= 40; ++j) {
                    int jj = j - 20;
                    for (int i = 0; i <= 40; ++i) {
                        int ii = i - 20;
                        if (ii >= -rx && ii <= rx && jj >= -ry && jj <= ry) {
                            float4 c = uInput.eval(fragCoord + float2(float(ii), float(jj)));
                            float a = c.a;
                            float3 s = c.rgb / max(a, 1e-6);
                            if (s.r > bsR) { bsR = s.r; br = c.r; }
                            if (s.g > bsG) { bsG = s.g; bg = c.g; }
                            if (s.b > bsB) { bsB = s.b; bb = c.b; }
                            if (a > ba) { ba = a; }
                        }
                    }
                }
                return half4(br, bg, bb, ba);
            }
        """

/**
 * Builds the erode step of an Impl33 morphology chain: the configured
 * [RuntimeShader] (kept by the caller for downstream `resultShaders`
 * lookups) plus the [RenderEffect] wrapping it under [inputUniformName].
 *
 * @param radiusX radiusY the morphology radius in bitmap pixels
 * (`radius * scale`, matching the CPU `ceilToInt` conversion).
 * @param interiorLeft interiorTop interiorRight interiorBottom the erode
 * write window `[max(clip, r), min(clip, size - r))` in `fragCoord` space;
 * everything outside stays transparent.
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createMorphologyErodeShaderEffect(
    radiusX: Float,
    radiusY: Float,
    interiorLeft: Float,
    interiorTop: Float,
    interiorRight: Float,
    interiorBottom: Float,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect> {
    val shader = RuntimeShader(MORPHOLOGY_ERODE_SHADER)
    shader.setFloatUniform("uRadius", radiusX, radiusY)
    shader.setFloatUniform("uInterior", interiorLeft, interiorTop, interiorRight, interiorBottom)
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}

/**
 * Builds the dilate step of an Impl33 morphology chain: the configured
 * [RuntimeShader] (kept by the caller for downstream `resultShaders`
 * lookups) plus the [RenderEffect] wrapping it under [inputUniformName].
 *
 * @param radiusX radiusY the morphology radius in bitmap pixels
 * (`radius * scale`, matching the CPU `ceilToInt` conversion).
 * @param interiorLeft interiorTop interiorRight interiorBottom the dilate
 * write window — the full (unshrunk) clip rect in `fragCoord` space, since
 * dilate covers it with clamped windows.
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createMorphologyDilateShaderEffect(
    radiusX: Float,
    radiusY: Float,
    interiorLeft: Float,
    interiorTop: Float,
    interiorRight: Float,
    interiorBottom: Float,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect> {
    val shader = RuntimeShader(MORPHOLOGY_DILATE_SHADER)
    shader.setFloatUniform("uRadius", radiusX, radiusY)
    shader.setFloatUniform("uInterior", interiorLeft, interiorTop, interiorRight, interiorBottom)
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}
