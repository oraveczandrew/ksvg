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

package hu.oandras.ksvg.render.filters.pipeline.shaders

/**
 * Single-pass convolution over straight taps with premultiplied output.
 * Out-of-bounds taps clamp to [uBounds] (the input extent in `fragCoord`
 * space), mirroring the CPU `duplicate` path (`sampleCoordinate` clamp).
 * Skia child sampling outside the input is NOT reliably clamped (Adreno
 * reads undefined values there), so the clamp is explicit. wrap/none edge
 * modes are declined host-side (software fallback) instead.
 */
internal const val CONVOLVE_MATRIX_SHADER: String = """
            uniform shader uInput;
            uniform float uKernel[25];
            uniform int uOrderX;
            uniform int uOrderY;
            uniform int uTargetX;
            uniform int uTargetY;
            uniform float uDivisor;
            uniform float uBias;
            uniform int uPreserveAlpha;
            uniform float4 uBounds;
            half4 main(float2 fragCoord) {
                float4 sum = float4(0.0);
                int kx = 0;
                int ky = 0;
                for (int i = 0; i < 25; ++i) {
                    if (i >= uOrderX * uOrderY) break;
                    float2 offset = float2(float(kx - uTargetX), float(ky - uTargetY));
                    sum += uInput.eval(clamp(fragCoord + offset, uBounds.xy, uBounds.zw)) * uKernel[i];
                    kx++;
                    if (kx >= uOrderX) {
                        kx = 0;
                        ky++;
                    }
                }
                float4 res = sum / uDivisor + uBias;
                if (uPreserveAlpha != 0) res.a = uInput.eval(fragCoord).a;
                return half4(res);
            }
        """
