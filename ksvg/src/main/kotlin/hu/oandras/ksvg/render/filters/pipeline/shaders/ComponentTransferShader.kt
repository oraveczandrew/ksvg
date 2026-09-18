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

internal const val COMPONENT_TRANSFER_SHADER: String = """
            uniform shader uInput;
            uniform shader uLutRgb;
            uniform shader uLutA;
            half4 main(float2 fragCoord) {
                float4 color = uInput.eval(fragCoord);
                float alpha = color.a;
                if (alpha > 0.0) color.rgb /= alpha;
                float r = uLutRgb.eval(float2(color.r * 255.0 + 0.5, 0.5)).r;
                float g = uLutRgb.eval(float2(color.g * 255.0 + 0.5, 0.5)).g;
                float b = uLutRgb.eval(float2(color.b * 255.0 + 0.5, 0.5)).b;
                float a = uLutA.eval(float2(color.a * 255.0 + 0.5, 0.5)).r;
                return half4(r * a, g * a, b * a, a);
            }
        """
