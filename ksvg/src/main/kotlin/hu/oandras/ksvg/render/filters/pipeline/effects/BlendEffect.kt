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

@file:Suppress("SpellCheckingInspection") // AGSL builtins

package hu.oandras.ksvg.render.filters.pipeline.effects

import android.graphics.BitmapShader
import android.graphics.RectF
import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.graphics.Shader
import android.os.Build
import androidx.annotation.RequiresApi

/**
 * Linear-light feBlend for all non-normal modes: the CSS Compositing L1
 * general formula (backdrop/source compositing around the per-mode blend
 * function) evaluated linearized with an sRGB EOTF on the output, mirroring
 * the CPU `useLinear` path (`KotlinKernels.feBlend`).
 *
 * `uMode` carries the `FeBlendMode` ordinal in `:ksvg` as a float
 * (1=multiply … 15=luminosity). Precision notes vs the CPU kernel: EOTF float
 * rounding and the soft-light `sqrt` may differ by 1 LSB at rounding
 * boundaries (the accepted lighting/turbulence class).
 */
private const val LINEAR_BLEND_SHADER: String = """
            uniform shader uInput;
            uniform shader uIn2;
            uniform shader uLutLin;
            uniform float uMode;
            uniform float4 uPrimitiveRegion;
            float3 toLinear(float3 c) {
                return float3(
                    uLutLin.eval(float2(c.r * 255.0 + 0.5, 0.5)).r,
                    uLutLin.eval(float2(c.g * 255.0 + 0.5, 0.5)).g,
                    uLutLin.eval(float2(c.b * 255.0 + 0.5, 0.5)).b
                );
            }
            // Linear->sRGB EOTF matching the CPU linearToSrgb table
            // (threshold branch identical; float rounding may differ by 1 LSB
            // at table rounding boundaries).
            float3 srgbEotf(float3 c) {
                float3 lo = c * 12.92;
                float3 hi = 1.055 * pow(c, float3(1.0 / 2.4)) - 0.055;
                return float3(
                    c.r <= 0.0031308 ? lo.r : hi.r,
                    c.g <= 0.0031308 ? lo.g : hi.g,
                    c.b <= 0.0031308 ? lo.b : hi.b
                );
            }
            float sepBlend(float cb, float cs, float m) {
                if (m < 1.5) return cb * cs;                                        // multiply
                if (m < 2.5) return cb + cs - cb * cs;                             // screen
                if (m < 3.5) return cb <= 0.5 ? 2.0 * cb * cs                      // overlay
                    : 1.0 - 2.0 * (1.0 - cb) * (1.0 - cs);
                if (m < 4.5) return min(cb, cs);                                   // darken
                if (m < 5.5) return max(cb, cs);                                   // lighten
                if (m < 6.5) {                                                    // color-dodge
                    if (cb == 0.0) return 0.0;
                    if (cs >= 1.0) return 1.0;
                    return min(cb / (1.0 - cs), 1.0);
                }
                if (m < 7.5) {                                                    // color-burn
                    if (cb >= 1.0) return 1.0;
                    if (cs <= 0.0) return 0.0;
                    return 1.0 - min((1.0 - cb) / cs, 1.0);
                }
                if (m < 8.5) return cs <= 0.5 ? 2.0 * cs * cb                      // hard-light
                    : 1.0 - 2.0 * (1.0 - cs) * (1.0 - cb);
                if (m < 9.5) {                                                    // soft-light
                    float d = cb <= 0.25
                        ? ((16.0 * cb - 12.0) * cb + 4.0) * cb
                        : sqrt(cb);
                    return cb + (2.0 * cs - 1.0) * (d - cb);
                }
                if (m < 10.5) return abs(cb - cs);                                 // difference
                return cb + cs - 2.0 * cb * cs;                                   // exclusion
            }
            float lum(float3 c) {
                return 0.3 * c.r + 0.59 * c.g + 0.11 * c.b;
            }
            float sat(float3 c) {
                return max(max(c.r, c.g), c.b) - min(min(c.r, c.g), c.b);
            }
            float clipChannel(float3 c, float l, float n, float x, float v) {
                if (n < 0.0) v = l + ((v - l) * l / (l - n));
                if (x > 1.0) v = l + ((v - l) * (1.0 - l) / (x - l));
                return v;
            }
            float setLum(float3 c, float l, int ch) {
                float d = l - lum(c);
                float3 s = c + d;
                float ll = lum(s);
                float n = min(min(s.r, s.g), s.b);
                float x = max(max(s.r, s.g), s.b);
                float v = ch == 0 ? s.r : (ch == 1 ? s.g : s.b);
                return clipChannel(s, ll, n, x, v);
            }
            float setSat(float3 c, float s, int ch) {
                float cMax = max(max(c.r, c.g), c.b);
                float cMin = min(min(c.r, c.g), c.b);
                if (cMax <= cMin) return 0.0;
                float v = ch == 0 ? c.r : (ch == 1 ? c.g : c.b);
                if (v == cMax) return s;
                if (v == cMin) return 0.0;
                return (v - cMin) * s / (cMax - cMin);
            }
            float nonSep(float3 cb, float3 cs, float m, int ch) {
                float3 t;
                if (m < 12.5) {                                                   // hue
                    float s = sat(cb);
                    t = float3(setSat(cs, s, 0), setSat(cs, s, 1), setSat(cs, s, 2));
                    float l = lum(cb);
                    return setLum(t, l, ch);
                }
                if (m < 13.5) {                                                   // saturation
                    float s = sat(cs);
                    t = float3(setSat(cb, s, 0), setSat(cb, s, 1), setSat(cb, s, 2));
                    float l = lum(cb);
                    return setLum(t, l, ch);
                }
                if (m < 14.5) return setLum(cs, lum(cb), ch);                      // color
                return setLum(cb, lum(cs), ch);                                    // luminosity
            }
            half4 main(float2 fragCoord) {
                if (fragCoord.x < uPrimitiveRegion.x || fragCoord.x >= uPrimitiveRegion.z ||
                    fragCoord.y < uPrimitiveRegion.y || fragCoord.y >= uPrimitiveRegion.w) {
                    return half4(0.0);
                }
                float4 src = uInput.eval(fragCoord);
                float4 dst = uIn2.eval(fragCoord);
                float as = src.a;
                float ab = dst.a;
                float ao = as + ab - as * ab;
                if (ao <= 0.0) return half4(0.0);
                float3 cs = as > 0.0 ? src.rgb / as : float3(0.0);
                float3 cb = ab > 0.0 ? dst.rgb / ab : float3(0.0);
                float3 sl = toLinear(cs);
                float3 bl = toLinear(cb);
                float3 b;
                if (uMode < 11.5) {
                    b = float3(sepBlend(bl.r, sl.r, uMode),
                               sepBlend(bl.g, sl.g, uMode),
                               sepBlend(bl.b, sl.b, uMode));
                } else {
                    b = float3(nonSep(bl, sl, uMode, 0),
                               nonSep(bl, sl, uMode, 1),
                               nonSep(bl, sl, uMode, 2));
                }
                float3 comp = (1.0 - ab) * sl * as + (1.0 - as) * bl * ab + as * ab * b;
                comp = comp / ao;
                float3 eotf = srgbEotf(floor(comp * 255.0 + 0.5) / 255.0);
                return half4(eotf * ao, ao);
            }
        """

/**
 * Builds the linear-light feBlend step of an Impl33 chain (like
 * [createLinearArithmeticCompositeShaderEffect] but with the 15 blend modes):
 * the configured [RuntimeShader] (kept by the caller for downstream
 * `resultShaders` lookups) plus the [RenderEffect] wrapping it under
 * [inputUniformName].
 *
 * @param mode the `FeBlendMode` ordinal in `:ksvg` as a float
 * (1=multiply … 15=luminosity; 0=normal must not reach here)
 * @param in2Shader the already-configured chain shader feeding `uIn2`
 * @param primitiveRegion the primitive subregion in buffer space (already
 * remapped from user space by the caller); the CPU kernel writes the clip
 * only
 * @param inputUniformName the shader-input uniform name (`uInput`)
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createLinearBlendShaderEffect(
    mode: Float,
    in2Shader: RuntimeShader,
    primitiveRegion: RectF,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect> {
    val shader = RuntimeShader(LINEAR_BLEND_SHADER)
    shader.setFloatUniform("uMode", mode)
    shader.setInputShader("uIn2", in2Shader)
    shader.setInputShader(
        "uLutLin",
        BitmapShader(linearTransferLut, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP),
    )
    shader.setFloatUniform(
        "uPrimitiveRegion",
        primitiveRegion.left, primitiveRegion.top, primitiveRegion.right, primitiveRegion.bottom,
    )
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}
