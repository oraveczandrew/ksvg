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

internal const val FLOOD_SHADER: String = """
            uniform shader uInput;
            layout(color) uniform half4 uColor;
            uniform float4 uPrimitiveRegion;
            half4 main(float2 fragCoord) {
                // fragCoord samples pixel centers: keep exactly the pixels the CPU
                // kernels keep (their clip rects truncate region bounds to ints).
                if (fragCoord.x < floor(uPrimitiveRegion.x) + 0.5 || fragCoord.x > ceil(uPrimitiveRegion.z) - 0.5 ||
                    fragCoord.y < floor(uPrimitiveRegion.y) + 0.5 || fragCoord.y > ceil(uPrimitiveRegion.w) - 0.5) {
                    return half4(0.0);
                }
                return uColor;
            }
        """
