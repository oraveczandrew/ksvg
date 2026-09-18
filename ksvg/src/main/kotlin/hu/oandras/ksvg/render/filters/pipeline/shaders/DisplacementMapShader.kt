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

internal const val DISPLACEMENT_MAP_SHADER: String = """
            uniform shader uInput;
            uniform shader uMap;
            uniform float2 uScale;
            uniform int uXChannel;
            uniform int uYChannel;
            float getChannel(float4 color, int selector) {
                if (selector == 0) return color.r;
                if (selector == 1) return color.g;
                if (selector == 2) return color.b;
                return color.a;
            }
            half4 main(float2 fragCoord) {
                // Nearest-neighbor sampling throughout, matching the CPU
                // kernel (integer-truncated shifts, texel-exact map reads):
                // the CPU displaces by trunc(scale * (ch - 0.5)) pixels and
                // samples both bitmaps at integer texels. (Browsers bilinearly
                // interpolate here; migrating both paths is future work. The
                // CPU clamps out-of-range reads to the bitmap edge while this
                // shader relies on the input effect's edge behavior instead.)
                float4 mapColor = uMap.eval(floor(fragCoord) + 0.5);
                int2 d = int2(
                    (getChannel(mapColor, uXChannel) - 0.5) * uScale.x,
                    (getChannel(mapColor, uYChannel) - 0.5) * uScale.y
                );
                return uInput.eval(floor(fragCoord + float2(d)) + 0.5);
            }
        """
