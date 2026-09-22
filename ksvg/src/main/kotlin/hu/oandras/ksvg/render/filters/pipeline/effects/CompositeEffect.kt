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

import android.graphics.Bitmap
import android.graphics.BitmapShader
import android.graphics.RectF
import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.graphics.Shader
import android.os.Build
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.filtering.ColorLuts

/**
 * Porter-Duff-style compositing plus `arithmetic` (`uOperator == 5`).
 * The arithmetic branch is additionally gated by `uPrimitiveRegion`
 * (transparent outside — mirrors the CPU kernel, which writes the clip
 * only). Other operators are unaffected by the region uniform.
 */
private const val COMPOSITE_SHADER: String = """
            uniform shader uInput;
            uniform shader uIn2;
            uniform int uOperator;
            uniform float4 uK;
            uniform float4 uPrimitiveRegion;
            half4 main(float2 fragCoord) {
                if (uOperator == 5 && (fragCoord.x < uPrimitiveRegion.x || fragCoord.x >= uPrimitiveRegion.z ||
                    fragCoord.y < uPrimitiveRegion.y || fragCoord.y >= uPrimitiveRegion.w)) {
                    return half4(0.0);
                }
                float4 src = uInput.eval(fragCoord);
                float4 dst = uIn2.eval(fragCoord);
                if (uOperator == 0) return half4(src + dst * (1.0 - src.a));
                if (uOperator == 1) return half4(src * dst.a);
                if (uOperator == 2) return half4(src * (1.0 - dst.a));
                if (uOperator == 3) return half4(src * dst.a + dst * (1.0 - src.a));
                if (uOperator == 4) return half4(src * (1.0 - dst.a) + dst * (1.0 - src.a));
                if (uOperator == 5) {
                    // The k-polynomial is straight math (like colorMatrix/
                    // componentTransfer/morphology taps): unpremultiply the
                    // premultiplied chain taps first. Under transparent
                    // pixels straight is 0 (the CPU getPixels contract);
                    // alpha is alpha in both spaces, carried through.
                    float4 s = float4(src.a > 0.0 ? src.rgb / src.a : float3(0.0), src.a);
                    float4 t = float4(dst.a > 0.0 ? dst.rgb / dst.a : float3(0.0), dst.a);
                    float4 res = uK.x * t * s + uK.y * s + uK.z * t + uK.w;
                    res = clamp(res, 0.0, 1.0);
                    // Match the CPU reference display: it computes straight
                    // channel values and premultiplies on store, so the
                    // emitted pixel must be premultiplied too (a no-op for
                    // opaque output, exact for k4-style constants).
                    res.rgb *= res.a;
                    return half4(res);
                }
                return half4(dst);
            }
        """

/**
 * Builds the arithmetic-composite step of an Impl33 chain: the configured
 * [RuntimeShader] (kept by the caller for downstream `resultShaders`
 * lookups) plus the [RenderEffect] wrapping it under [inputUniformName].
 *
 * Only the `arithmetic` operator needs a shader (the rest lower to blend
 * modes, and linear-light arithmetic declines the chain host-side). The
 * caller chains the effect onto the primitive input and registers the
 * shader. The second operand comes from a previously registered chain
 * shader (flood, ...), resolved by the caller via `in2`.
 *
 * @param k1 k2 k3 k4 the arithmetic coefficients
 * @param primitiveRegion the primitive subregion in buffer space (already
 * remapped from user space by the caller); the CPU kernel writes the clip
 * only
 * @param in2Shader the already-configured chain shader feeding `uIn2`
 * @param inputUniformName the shader-input uniform name (`uInput`)
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createArithmeticCompositeShaderEffect(
    k1: Float,
    k2: Float,
    k3: Float,
    k4: Float,
    primitiveRegion: RectF,
    in2Shader: RuntimeShader,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect> {
    val shader = RuntimeShader(COMPOSITE_SHADER)
    shader.setInputShader("uIn2", in2Shader)
    shader.setIntUniform("uOperator", 5)
    shader.setFloatUniform("uK", k1, k2, k3, k4)
    shader.setFloatUniform(
        "uPrimitiveRegion",
        primitiveRegion.left, primitiveRegion.top, primitiveRegion.right, primitiveRegion.bottom,
    )
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}

/**
 * Linear-light arithmetic transfer lookup. Same clip rule as the sRGB
 * branch, but the k-polynomial runs on linearized taps (exact sRGB→linear
 * table, mirroring the CPU `useLinear` path, which linearizes via LUTs)
 * while alpha stays in byte space on both sides; the straight result gets
 * the linear→sRGB transfer (CPU `linearToSrgb` table equivalent — float
 * rounding may differ by 1 LSB at table rounding boundaries, the accepted
 * lighting/turbulence class).
 */
private const val LINEAR_COMPOSITE_SHADER: String = """
            uniform shader uInput;
            uniform shader uIn2;
            uniform shader uLutLin;
            uniform float4 uK;
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
            half4 main(float2 fragCoord) {
                if (fragCoord.x < uPrimitiveRegion.x || fragCoord.x >= uPrimitiveRegion.z ||
                    fragCoord.y < uPrimitiveRegion.y || fragCoord.y >= uPrimitiveRegion.w) {
                    return half4(0.0);
                }
                float4 src = uInput.eval(fragCoord);
                float4 dst = uIn2.eval(fragCoord);
                float3 s = src.a > 0.0 ? src.rgb / src.a : float3(0.0);
                float3 t = dst.a > 0.0 ? dst.rgb / dst.a : float3(0.0);
                float3 sl = toLinear(s);
                float3 tl = toLinear(t);
                float3 res = uK.x * tl * sl + uK.y * sl + uK.z * tl + uK.w;
                res = clamp(res, 0.0, 1.0);
                float3 eotf = srgbEotf(floor(res * 255.0 + 0.5) / 255.0);
                float a = clamp(uK.x * dst.a * src.a + uK.y * src.a + uK.z * dst.a + uK.w, 0.0, 1.0);
                return half4(eotf * a, a);
            }
        """

/**
 * sRGB→linear transfer table as an opaque 256x1 gray texture (same
 * premult-safe data-texture convention as the component-transfer LUTs).
 * Fixed content ([ColorLuts.SRGB_TO_LINEAR]), built once and shared by all
 * linear-arithmetic effects.
 */
private val linearTransferLut: Bitmap by lazy(LazyThreadSafetyMode.PUBLICATION) {
    Bitmap.createBitmap(256, 1, Bitmap.Config.ARGB_8888).also { bitmap ->
        val table = ColorLuts.SRGB_TO_LINEAR
        val pixels = IntArray(256) { i ->
            val v = table[i]
            -0x1000000 or (v shl 16) or (v shl 8) or v
        }
        bitmap.setPixels(pixels, 0, 256, 0, 0, 256, 1)
    }
}

/**
 * Builds the linear-light arithmetic-composite step of an Impl33 chain
 * (F9): like [createArithmeticCompositeShaderEffect] but the polynomial
 * runs linearized with an sRGB EOTF on the output, mirroring the CPU
 * `useLinear` path. Separate factory per mode (no caller-side flag).
 *
 * @param k1 k2 k3 k4 the arithmetic coefficients
 * @param primitiveRegion the primitive subregion in buffer space (already
 * remapped from user space by the caller); the CPU kernel writes the clip
 * only
 * @param in2Shader the already-configured chain shader feeding `uIn2`
 * @param inputUniformName the shader-input uniform name (`uInput`)
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createLinearArithmeticCompositeShaderEffect(
    k1: Float,
    k2: Float,
    k3: Float,
    k4: Float,
    primitiveRegion: RectF,
    in2Shader: RuntimeShader,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect> {
    val shader = RuntimeShader(LINEAR_COMPOSITE_SHADER)
    shader.setInputShader("uIn2", in2Shader)
    shader.setInputShader(
        "uLutLin",
        BitmapShader(linearTransferLut, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP),
    )
    shader.setFloatUniform("uK", k1, k2, k3, k4)
    shader.setFloatUniform(
        "uPrimitiveRegion",
        primitiveRegion.left, primitiveRegion.top, primitiveRegion.right, primitiveRegion.bottom,
    )
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}
