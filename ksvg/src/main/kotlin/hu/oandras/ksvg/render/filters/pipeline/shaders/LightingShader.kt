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

internal const val LIGHTING_SHADER: String = """
            uniform shader uInput;
            uniform float uSurfaceScale;
            uniform float uConstant;
            uniform float uExponent;
            // Linearized light color when uUseLinear != 0 (exact sRGB->linear
            // table lookup on the Kotlin side), raw sRGB otherwise.
            uniform float3 uLightColor;
            // Always the raw sRGB light color: terminal specular output carries
            // the full-strength light color (no EOTF), matching the CPU kernel.
            uniform float3 uLightColorRaw;
            // Linear-RGB EOTF on the straight output (color-interpolation-
            // filters: linearRGB, the default), matching the CPU kernel.
            uniform int uUseLinear;
            // Terminal feSpecularLighting emits premultiplied output
            // (full light color + intensity alpha), matching the CPU kernel.
            uniform int uTerminalPremult;
            uniform int uIsSpecular;
            uniform int uLightType;
            uniform float3 uLightPosDir;
            uniform float3 uPointsAt;
            uniform float2 uSpotParams;

            uniform float2 uUserLeftTop;
            uniform float2 uInvCanvasScale;
            uniform float2 uOffset;
            uniform float4 uPrimitiveRegion;

            float3 getNormal(float2 fragCoord) {
                float h0 = uInput.eval(fragCoord + float2(-1.0, -1.0)).a;
                float h1 = uInput.eval(fragCoord + float2(0.0, -1.0)).a;
                float h2 = uInput.eval(fragCoord + float2(1.0, -1.0)).a;
                float h3 = uInput.eval(fragCoord + float2(-1.0, 0.0)).a;
                float h5 = uInput.eval(fragCoord + float2(1.0, 0.0)).a;
                float h6 = uInput.eval(fragCoord + float2(-1.0, 1.0)).a;
                float h7 = uInput.eval(fragCoord + float2(0.0, 1.0)).a;
                float h8 = uInput.eval(fragCoord + float2(1.0, 1.0)).a;
                
                float dx = (h2 + 2.0*h5 + h8) - (h0 + 2.0*h3 + h6);
                float dy = (h6 + 2.0*h7 + h8) - (h0 + 2.0*h1 + h2);
                
                // SVG spec kernel: Nx = -surfaceScale * dx / 4.0. 
                // Since samples are separated by 2 pixels, Nx is the slope per pixel.
                // We multiply by uInvCanvasScale to get user-space slopes.
                float Nx = -dx * 0.25 * uSurfaceScale * uInvCanvasScale.x;
                float Ny = -dy * 0.25 * uSurfaceScale * uInvCanvasScale.y;
                
                float3 n = float3(Nx, Ny, 1.0);
                return normalize(n);
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
                // fragCoord samples pixel centers: keep exactly the pixels the CPU
                // kernels keep (their clip rects truncate region bounds to ints).
                if (fragCoord.x < floor(uPrimitiveRegion.x) + 0.5 || fragCoord.x > ceil(uPrimitiveRegion.z) - 0.5 ||
                    fragCoord.y < floor(uPrimitiveRegion.y) + 0.5 || fragCoord.y > ceil(uPrimitiveRegion.w) - 0.5) {
                    return half4(0.0);
                }

                float3 n = getNormal(fragCoord);
                float3 l;
                if (uLightType == 0) {
                    l = normalize(uLightPosDir);
                } else {
                    float2 local = fragCoord - uOffset;
                    float2 user = uUserLeftTop + local * uInvCanvasScale;

                    float3 p = float3(user, uInput.eval(fragCoord).a * uSurfaceScale);
                    l = normalize(uLightPosDir - p);
                }
                
            float dotNL = max(dot(n, l), 0.0);
            float3 color;
            float a = 1.0;
            if (uIsSpecular == 0) {
                float intensity = clamp(dotNL * uConstant, 0.0, 1.0);
                float3 lin = uLightColor * intensity;
                color = (uUseLinear != 0) ? srgbEotf(floor(lin * 255.0 + 0.5) / 255.0) : lin;
            } else {
                float3 v = float3(0.0, 0.0, 1.0);
                float3 h = normalize(l + v);
                float intensity = clamp(uConstant * pow(max(dot(n, h), 0.0), uExponent), 0.0, 1.0);
                if (uTerminalPremult != 0) {
                    return half4(uLightColorRaw, intensity);
                }
                float3 lin = uLightColor * intensity;
                color = (uUseLinear != 0) ? srgbEotf(floor(lin * 255.0 + 0.5) / 255.0) : lin;
                a = max(max(color.r, color.g), color.b);
            }

            return half4(color, a);
        }
        """
