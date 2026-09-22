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
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.filter.FeStitchTiles
import hu.oandras.ksvg.dom.filter.FeTurbulenceType
import hu.oandras.ksvg.render.FeTurbulenceRenderNode
import hu.oandras.ksvg.render.createBitmap
import kotlin.math.ceil
import kotlin.math.floor

private const val TURBULENCE_SHADER: String = """
            uniform shader uLattice;
            // Companion lattice texture: row k holds channel k's
            // (permutation, gradientY-hi, gradientY-lo); X gradients live in
            // uLattice. Split for 16-bit gradient precision.
            uniform shader uLatticeB;
            uniform shader in_source;
            uniform float2 uBaseFrequency;
            uniform int uNumOctaves;
            uniform int uIsFractal;
            uniform float2 uTilePeriod;
            // Stitch wrap origin: the primitive clip left/top in device px
            // from the filter-region left/top (CPU `clipLeft`/`clipTop`).
            uniform float2 uClip;
            uniform float2 uOrigin;
            uniform float2 uPrimitiveUnitSize;
            uniform float2 uUserLeftTop;
            uniform float2 uInvCanvasScale;
            uniform float2 uOffset;
            uniform float4 uPrimitiveRegion;
            // Terminal feTurbulence under linearRGB gets the linear->sRGB
            // transfer on its straight RGB (CPU unLinearizeBitmap equivalent).
            uniform int uUnlinearize;

            int customMod(int x, int y) {
                return x - y * int(floor(float(x) / float(y)));
            }

            float4 getLattice(int x, int row) {
                return uLattice.eval(float2(float(x) + 0.5, float(row) + 0.5));
            }

            float4 getLatticeB(int x, int row) {
                return uLatticeB.eval(float2(float(x) + 0.5, float(row) + 0.5));
            }

            // 16-bit gradient dequantization matching packGradient16:
            // value = hi * 256 + lo maps [0, 65535] onto [-1, 1].
            float grad16(float4 t) {
                return (t.g * 255.0 * 256.0 + t.b * 255.0) / 32767.5 - 1.0;
            }

            float4 sCurve(float4 t) {
                return t * t * (3.0 - 2.0 * t);
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

            float4 noise2(float2 p, float2 period, int2 wrap) {
                float2 pf = floor(p);
                float2 r0 = p - pf;
                float2 r1 = r0 - 1.0;
                int2 b0 = int2(pf);

                int bx1 = b0.x + 1;
                int by1 = b0.y + 1;

                // Stitch wrap-lattice offset (rsvg form, mirroring
                // SvgPathNoise.noise2 exactly): conditional subtraction past
                // the wrap line, NOT modular wrapping. The 256-mask below
                // applies to both paths (CPU `and BM`).
                if (period.x > 0.0) {
                    if (b0.x >= wrap.x) b0.x -= int(period.x);
                    if (bx1 >= wrap.x) bx1 -= int(period.x);
                }
                if (period.y > 0.0) {
                    if (b0.y >= wrap.y) b0.y -= int(period.y);
                    if (by1 >= wrap.y) by1 -= int(period.y);
                }

                b0.x = customMod(b0.x, 256);
                bx1 = customMod(bx1, 256);
                b0.y = customMod(b0.y, 256);
                by1 = customMod(by1, 256);

                float4 i = float4(getLattice(b0.x, 0).r, getLattice(b0.x, 1).r, getLattice(b0.x, 2).r, getLattice(b0.x, 3).r) * 255.0;
                float4 j = float4(getLattice(bx1, 0).r, getLattice(bx1, 1).r, getLattice(bx1, 2).r, getLattice(bx1, 3).r) * 255.0;

                float4 val00 = i + float4(b0.y) + 0.5;
                float4 val10 = j + float4(b0.y) + 0.5;
                float4 val01 = i + float4(by1) + 0.5;
                float4 val11 = j + float4(by1) + 0.5;

                int4 idx00 = int4(val00 - 256.0 * floor(val00 / 256.0));
                int4 idx10 = int4(val10 - 256.0 * floor(val10 / 256.0));
                int4 idx01 = int4(val01 - 256.0 * floor(val01 / 256.0));
                int4 idx11 = int4(val11 - 256.0 * floor(val11 / 256.0));

                float4 b00 = float4(getLattice(idx00.r, 0).r, getLattice(idx00.g, 1).r, getLattice(idx00.b, 2).r, getLattice(idx00.a, 3).r) * 255.0;
                float4 b10 = float4(getLattice(idx10.r, 0).r, getLattice(idx10.g, 1).r, getLattice(idx10.b, 2).r, getLattice(idx10.a, 3).r) * 255.0;
                float4 b01 = float4(getLattice(idx01.r, 0).r, getLattice(idx01.g, 1).r, getLattice(idx01.b, 2).r, getLattice(idx01.a, 3).r) * 255.0;
                float4 b11 = float4(getLattice(idx11.r, 0).r, getLattice(idx11.g, 1).r, getLattice(idx11.b, 2).r, getLattice(idx11.a, 3).r) * 255.0;

                float4 sx = sCurve(float4(r0.x));
                float4 sy = sCurve(float4(r0.y));

                float4 q00x = float4(grad16(getLattice(int(b00.r+0.5), 0)), grad16(getLattice(int(b00.g+0.5), 1)), grad16(getLattice(int(b00.b+0.5), 2)), grad16(getLattice(int(b00.a+0.5), 3)));
                float4 q00y = float4(grad16(getLatticeB(int(b00.r+0.5), 0)), grad16(getLatticeB(int(b00.g+0.5), 1)), grad16(getLatticeB(int(b00.b+0.5), 2)), grad16(getLatticeB(int(b00.a+0.5), 3)));
                float4 q10x = float4(grad16(getLattice(int(b10.r+0.5), 0)), grad16(getLattice(int(b10.g+0.5), 1)), grad16(getLattice(int(b10.b+0.5), 2)), grad16(getLattice(int(b10.a+0.5), 3)));
                float4 q10y = float4(grad16(getLatticeB(int(b10.r+0.5), 0)), grad16(getLatticeB(int(b10.g+0.5), 1)), grad16(getLatticeB(int(b10.b+0.5), 2)), grad16(getLatticeB(int(b10.a+0.5), 3)));
                float4 q01x = float4(grad16(getLattice(int(b01.r+0.5), 0)), grad16(getLattice(int(b01.g+0.5), 1)), grad16(getLattice(int(b01.b+0.5), 2)), grad16(getLattice(int(b01.a+0.5), 3)));
                float4 q01y = float4(grad16(getLatticeB(int(b01.r+0.5), 0)), grad16(getLatticeB(int(b01.g+0.5), 1)), grad16(getLatticeB(int(b01.b+0.5), 2)), grad16(getLatticeB(int(b01.a+0.5), 3)));
                float4 q11x = float4(grad16(getLattice(int(b11.r+0.5), 0)), grad16(getLattice(int(b11.g+0.5), 1)), grad16(getLattice(int(b11.b+0.5), 2)), grad16(getLattice(int(b11.a+0.5), 3)));
                float4 q11y = float4(grad16(getLatticeB(int(b11.r+0.5), 0)), grad16(getLatticeB(int(b11.g+0.5), 1)), grad16(getLatticeB(int(b11.b+0.5), 2)), grad16(getLatticeB(int(b11.a+0.5), 3)));

                float4 u = r0.x * q00x + r0.y * q00y;
                float4 v = r1.x * q10x + r0.y * q10y;
                float4 a = u + sx * (v - u);
                float4 u2 = r0.x * q01x + r1.y * q01y;
                float4 v2 = r1.x * q11x + r1.y * q11y;
                float4 b = u2 + sx * (v2 - u2);
                return a + sy * (b - a);
            }

            half4 main(float2 fragCoord) {
                // fragCoord samples pixel centers: keep exactly the pixels the CPU
                // kernels keep (their clip rects truncate region bounds to ints).
                // The 1e-3 epsilon (flood-effect guard precedent) keeps exact-boundary
                // pixel centers inside: without it Adreno resolves integral
                // region edges landing exactly on pixel centers as CUT for
                // scattered edge pixels (float interpolation error).
                if (fragCoord.x < floor(uPrimitiveRegion.x) + 0.5 - 1e-3 || fragCoord.x > ceil(uPrimitiveRegion.z) - 0.5 + 1e-3 ||
                    fragCoord.y < floor(uPrimitiveRegion.y) + 0.5 - 1e-3 || fragCoord.y > ceil(uPrimitiveRegion.w) - 0.5 + 1e-3) {
                    return half4(0.0);
                }

                // fragCoord is in gpuNode-local buffer space; uOffset maps it back to
                // device-pixel coordinates relative to the filter region top-left.
                // Sampled at integer pixel coordinates (local - 0.5): the CPU
                // kernels address texel (x, y) at userLeft + x, not at pixel
                // centers, and parity requires the same sampling phase.
                float2 local = fragCoord - uOffset;
                float2 user = uUserLeftTop + (local - 0.5) * uInvCanvasScale;
                float2 p = ((user - uOrigin) / uPrimitiveUnitSize) * uBaseFrequency;
                float4 sums = float4(0.0);
                float ratio = 1.0;
                float2 period = uTilePeriod;
                // Stitch wrap origin, mirroring the CPU kernel: tile-relative
                // pixel index times the (adjusted) base frequency, doubled
                // per octave like the lattice position. uClip carries the
                // primitive clip left/top in the same device-px space as
                // `local - 0.5` (the kernel bitmap pixel index).
                float2 curt = ((local - 0.5) - uClip) * uBaseFrequency;
                for (int i = 0; i < 8; ++i) {
                    if (i >= uNumOctaves) break;
                    int2 wrap = int2(int(floor(curt.x)), int(floor(curt.y))) + int2(int(period.x), int(period.y));
                    float4 n = noise2(p, period, wrap);
                    if (uIsFractal != 0) sums += n / ratio; else sums += abs(n) / ratio;
                    p *= 2.0; ratio *= 2.0; curt *= 2.0;
                    if (period.x > 0.0 || period.y > 0.0) period *= 2.0;
                }
                float4 finalVal = (uIsFractal != 0) ? (sums + 1.0) * 0.5 : sums;
                finalVal = clamp(finalVal, 0.0, 1.0);
                // Straight (non-premultiplied) terminal output: the CPU kernel
                // writes straight bytes into the result bitmap, and parity (plus
                // the golden references pinning the CPU side) requires the same
                // convention here.
                float3 outRgb = finalVal.rgb;
                if (uUnlinearize != 0) {
                    outRgb = srgbEotf(floor(outRgb * 255.0 + 0.5) / 255.0);
                }
                return half4(outRgb, finalVal.a);
            }
        """

/**
 * Builds the turbulence step of an Impl33 chain: the configured
 * [RuntimeShader] (kept by the caller for downstream `resultShaders`
 * lookups) plus the [RenderEffect] wrapping it under [inputUniformName].
 *
 * Turbulence is generative: the returned effect stands alone (wired under
 * `in_source`, never chained onto the primitive input). The caller
 * registers the shader for downstream `in2` references (displacement).
 *
 * @param node the turbulence render node (seed-built lattice generators)
 * @param primitiveScaleX primitiveScaleY one primitive unit in user units
 * (matches the CPU FilterGeneration math)
 * @param filterRegion the filter region in user space
 * @param canvasScaleX canvasScaleY the canvas scale in device pixels per
 * user unit
 * @param padX padY the device-space padding of the filter region top-left
 * @param unlinearize true for terminal turbulence under linearRGB
 * (linear->sRGB transfer, the CPU unLinearizeBitmap equivalent)
 * @param primitiveUnitsAreUser false when primitive units are
 * objectBoundingBox (origin at the bounding box instead of 0,0)
 * @param boundingBox the filtered element bounding box (only read when
 * primitive units are objectBoundingBox)
 * @param primitiveRegion the primitive subregion in buffer space (already
 * remapped from user space by the caller)
 * @param clipLeft clipTop the primitive clip left/top in device px from the
 * filter-region left/top (CPU `clipLeft`/`clipTop`: the stitch wrap origin;
 * exact for full-region clips, best-effort mirrored formula otherwise)
 * @param inputUniformName the shader-input uniform name (`in_source`)
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createTurbulenceShaderEffect(
    node: FeTurbulenceRenderNode,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
    filterRegion: RectF,
    canvasScaleX: Float,
    canvasScaleY: Float,
    padX: Int,
    padY: Int,
    unlinearize: Boolean,
    primitiveUnitsAreUser: Boolean,
    boundingBox: Box,
    primitiveRegion: RectF,
    clipLeft: Int,
    clipTop: Int,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect> {
    val shader = RuntimeShader(TURBULENCE_SHADER)
    val element = node.sourceElement
    val originX = if (primitiveUnitsAreUser) 0f else boundingBox.minX
    val originY = if (primitiveUnitsAreUser) 0f else boundingBox.minY
    // Size of one primitive unit in user units (matches the CPU FilterGeneration math).
    val unitSizeX = primitiveScaleX / canvasScaleX
    val unitSizeY = primitiveScaleY / canvasScaleY

    // Stitch adjustment (F6): mirror FilterGeneration exactly — the tile is
    // the filter-region device size (int-truncated, like the CPU bitmap),
    // the adjusted frequency is the nearest integral-period one, and the
    // period is the tile in those periods. Non-stitch keeps raw values.
    var baseFrequencyX = element.baseFrequencyX
    var baseFrequencyY = element.baseFrequencyY
    var tilePeriodX = 0f
    var tilePeriodY = 0f
    if (element.stitchTiles == FeStitchTiles.stitch) {
        val tileWidthPx = (filterRegion.width() * canvasScaleX).toInt().toDouble()
        val tileHeightPx = (filterRegion.height() * canvasScaleY).toInt().toDouble()
        val baseX = maxOf(0.0, element.baseFrequencyX.toDouble())
        val baseY = maxOf(0.0, element.baseFrequencyY.toDouble())
        if (tileWidthPx > 0.0 && baseX != 0.0) {
            val fLo = floor(tileWidthPx * baseX) / tileWidthPx
            val fHi = ceil(tileWidthPx * baseX) / tileWidthPx
            val adjusted = if (baseX / fLo < fHi / baseX) fLo else fHi
            baseFrequencyX = adjusted.toFloat()
            tilePeriodX = (tileWidthPx * adjusted + 0.5).toInt().toFloat()
        }
        if (tileHeightPx > 0.0 && baseY != 0.0) {
            val fLo = floor(tileHeightPx * baseY) / tileHeightPx
            val fHi = ceil(tileHeightPx * baseY) / tileHeightPx
            val adjusted = if (baseY / fLo < fHi / baseY) fLo else fHi
            baseFrequencyY = adjusted.toFloat()
            tilePeriodY = (tileHeightPx * adjusted + 0.5).toInt().toFloat()
        }
    }

    shader.setFloatUniform(
        /* uniformName = */ "uBaseFrequency",
        /* value1 = */ baseFrequencyX,
        /* value2 = */ baseFrequencyY
    )
    shader.setIntUniform("uNumOctaves", element.numOctaves)
    shader.setIntUniform("uIsFractal", if (element.type == FeTurbulenceType.fractalNoise) 1 else 0)
    shader.setFloatUniform("uTilePeriod", tilePeriodX, tilePeriodY)
    shader.setFloatUniform("uClip", clipLeft.toFloat(), clipTop.toFloat())
    shader.setFloatUniform("uOrigin", originX, originY)
    shader.setFloatUniform("uUserLeftTop", filterRegion.left, filterRegion.top)
    shader.setFloatUniform("uInvCanvasScale", 1f / canvasScaleX, 1f / canvasScaleY)
    shader.setFloatUniform("uPrimitiveUnitSize", unitSizeX, unitSizeY)
    // fragCoord is in gpuNode-local buffer space; the filter region top-left sits at (padX, padY).
    shader.setFloatUniform("uOffset", padX.toFloat(), padY.toFloat())
    // Terminal turbulence under linearRGB gets the linear->sRGB transfer
    // (CPU unLinearizeBitmap equivalent); anything else stays linear.
    shader.setIntUniform("uUnlinearize", if (unlinearize) 1 else 0)

    val lattice = obtainLatticeBitmap(node)
    shader.setInputShader("uLattice", BitmapShader(lattice, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP))
    val latticeB = obtainLatticeBitmapB(node)
    shader.setInputShader("uLatticeB", BitmapShader(latticeB, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP))
    shader.setFloatUniform(
        "uPrimitiveRegion",
        primitiveRegion.left, primitiveRegion.top, primitiveRegion.right, primitiveRegion.bottom,
    )
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}

private fun obtainLatticeBitmap(node: FeTurbulenceRenderNode): Bitmap {
    val cached = node.gpuLatticeBitmap
    if (cached != null) {
        return cached
    }
    val generators = node.generators
    // 256x4 data texture: row k holds channel k's (permutation,
    // gradientX-hi, gradientX-lo) in RGB with opaque alpha. Data bitmaps
    // MUST stay opaque: the GPU backend uploads textures premultiplied,
    // which corrupts any data byte packed into RGB wherever alpha < 255.
    // Gradients are 16-bit (hi/lo bytes): 8-bit packing leaves ~1-2 LSB
    // of Perlin noise error, amplified by the terminal EOTF.
    val bitmap = createBitmap(256, 4)
    val pixels = IntArray(256 * 4)
    for (i in 0 until 256) {
        pixels[i] = packLattice(generators[0].p[i], packGradient16(generators[0].gx[i]))
        pixels[256 + i] = packLattice(generators[1].p[i], packGradient16(generators[1].gx[i]))
        pixels[512 + i] = packLattice(generators[2].p[i], packGradient16(generators[2].gx[i]))
        pixels[768 + i] = packLattice(generators[3].p[i], packGradient16(generators[3].gx[i]))
    }
    bitmap.setPixels(pixels, 0, 256, 0, 0, 256, 4)
    node.gpuLatticeBitmap = bitmap
    return bitmap
}

private fun obtainLatticeBitmapB(node: FeTurbulenceRenderNode): Bitmap {
    val cached = node.gpuLatticeBitmapB
    if (cached != null) {
        return cached
    }
    val generators = node.generators
    // Companion to [obtainLatticeBitmap]: row k holds channel k's
    // (permutation, gradientY-hi, gradientY-lo), opaque.
    val bitmap = createBitmap(256, 4)
    val pixels = IntArray(256 * 4)
    for (i in 0 until 256) {
        pixels[i] = packLattice(generators[0].p[i], packGradient16(generators[0].gy[i]))
        pixels[256 + i] = packLattice(generators[1].p[i], packGradient16(generators[1].gy[i]))
        pixels[512 + i] = packLattice(generators[2].p[i], packGradient16(generators[2].gy[i]))
        pixels[768 + i] = packLattice(generators[3].p[i], packGradient16(generators[3].gy[i]))
    }
    bitmap.setPixels(pixels, 0, 256, 0, 0, 256, 4)
    node.gpuLatticeBitmapB = bitmap
    return bitmap
}

private fun packLattice(p: Int, g16: Int): Int {
    return -0x1000000 or ((p and 0xFF) shl 16) or (((g16 shr 8) and 0xFF) shl 8) or (g16 and 0xFF)
}

private fun packGradient16(g: Double): Int =
    (((g + 1.0) * 32767.5 + 0.5).toInt()).coerceIn(0, 65535)
