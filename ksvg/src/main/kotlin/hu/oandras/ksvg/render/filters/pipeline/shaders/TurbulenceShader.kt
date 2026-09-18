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

internal const val TURBULENCE_SHADER: String = """
            uniform shader uLattice;
            uniform shader in_source;
            uniform float2 uBaseFrequency;
            uniform int uNumOctaves;
            uniform int uIsFractal;
            uniform float2 uTilePeriod;
            uniform float2 uOrigin;
            uniform float2 uPrimitiveUnitSize;
            uniform float2 uUserLeftTop;
            uniform float2 uInvCanvasScale;
            uniform float2 uOffset;
            uniform float4 uPrimitiveRegion;

            int customMod(int x, int y) {
                return x - y * int(floor(float(x) / float(y)));
            }

            float4 getLattice(int x, int row) {
                return uLattice.eval(float2(float(x) + 0.5, float(row) + 0.5));
            }

            float4 sCurve(float4 t) {
                return t * t * (3.0 - 2.0 * t);
            }

            float4 noise2(float2 p, float2 period) {
                float2 pf = floor(p);
                float2 r0 = p - pf;
                float2 r1 = r0 - 1.0;
                int2 b0 = int2(pf);

                if (period.x > 0.0) {
                    b0.x = customMod(b0.x, int(period.x));
                } else {
                    b0.x = customMod(b0.x, 256);
                }

                int bx1;
                if (period.x > 0.0) {
                    bx1 = customMod(b0.x + 1, int(period.x));
                } else {
                    bx1 = customMod(b0.x + 1, 256);
                }

                if (period.y > 0.0) {
                    b0.y = customMod(b0.y, int(period.y));
                } else {
                    b0.y = customMod(b0.y, 256);
                }

                int by1;
                if (period.y > 0.0) {
                    by1 = customMod(b0.y + 1, int(period.y));
                } else {
                    by1 = customMod(b0.y + 1, 256);
                }

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

                float4 q00x = float4(getLattice(int(b00.r+0.5), 0).g, getLattice(int(b00.g+0.5), 1).g, getLattice(int(b00.b+0.5), 2).g, getLattice(int(b00.a+0.5), 3).g) * 2.0 - 1.0;
                float4 q00y = float4(getLattice(int(b00.r+0.5), 0).b, getLattice(int(b00.g+0.5), 1).b, getLattice(int(b00.b+0.5), 2).b, getLattice(int(b00.a+0.5), 3).b) * 2.0 - 1.0;
                float4 q10x = float4(getLattice(int(b10.r+0.5), 0).g, getLattice(int(b10.g+0.5), 1).g, getLattice(int(b10.b+0.5), 2).g, getLattice(int(b10.a+0.5), 3).g) * 2.0 - 1.0;
                float4 q10y = float4(getLattice(int(b10.r+0.5), 0).b, getLattice(int(b10.g+0.5), 1).b, getLattice(int(b10.b+0.5), 2).b, getLattice(int(b10.a+0.5), 3).b) * 2.0 - 1.0;
                float4 q01x = float4(getLattice(int(b01.r+0.5), 0).g, getLattice(int(b01.g+0.5), 1).g, getLattice(int(b01.b+0.5), 2).g, getLattice(int(b01.a+0.5), 3).g) * 2.0 - 1.0;
                float4 q01y = float4(getLattice(int(b01.r+0.5), 0).b, getLattice(int(b01.g+0.5), 1).b, getLattice(int(b01.b+0.5), 2).b, getLattice(int(b01.a+0.5), 3).b) * 2.0 - 1.0;
                float4 q11x = float4(getLattice(int(b11.r+0.5), 0).g, getLattice(int(b11.g+0.5), 1).g, getLattice(int(b11.b+0.5), 2).g, getLattice(int(b11.a+0.5), 3).g) * 2.0 - 1.0;
                float4 q11y = float4(getLattice(int(b11.r+0.5), 0).b, getLattice(int(b11.g+0.5), 1).b, getLattice(int(b11.b+0.5), 2).b, getLattice(int(b11.a+0.5), 3).b) * 2.0 - 1.0;

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
                if (fragCoord.x < floor(uPrimitiveRegion.x) + 0.5 || fragCoord.x > ceil(uPrimitiveRegion.z) - 0.5 ||
                    fragCoord.y < floor(uPrimitiveRegion.y) + 0.5 || fragCoord.y > ceil(uPrimitiveRegion.w) - 0.5) {
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
                for (int i = 0; i < 8; ++i) {
                    if (i >= uNumOctaves) break;
                    float4 n = noise2(p, period);
                    if (uIsFractal != 0) sums += n / ratio; else sums += abs(n) / ratio;
                    p *= 2.0; ratio *= 2.0; if (period.x > 0.0) period *= 2.0;
                }
                float4 finalVal = (uIsFractal != 0) ? (sums + 1.0) * 0.5 : sums;
                finalVal = clamp(finalVal, 0.0, 1.0);
                // Straight (non-premultiplied) terminal output: the CPU kernel
                // writes straight bytes into the result bitmap, and parity (plus
                // the golden references pinning the CPU side) requires the same
                // convention here.
                return half4(finalVal.rgb, finalVal.a);
            }
        """
