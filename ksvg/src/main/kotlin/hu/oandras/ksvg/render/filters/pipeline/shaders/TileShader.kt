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

internal const val TILE_SHADER: String = """
            uniform shader uInput;
            uniform float4 uRect;
            half4 main(float2 fragCoord) {
                // feTile only paints inside its own subregion (uRect); outside it is transparent.
                if (fragCoord.x < uRect.x || fragCoord.x > uRect.z ||
                    fragCoord.y < uRect.y || fragCoord.y > uRect.w) {
                    return half4(0.0);
                }
                float w = uRect.z - uRect.x;
                float h = uRect.w - uRect.y;
                float2 coord = float2(
                    mod(fragCoord.x - uRect.x, w),
                    mod(fragCoord.y - uRect.y, h)
                ) + uRect.xy;
                return uInput.eval(coord);
            }
        """
