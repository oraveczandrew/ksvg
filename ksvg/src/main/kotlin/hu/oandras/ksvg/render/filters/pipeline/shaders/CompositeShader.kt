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

internal const val COMPOSITE_SHADER: String = """
            uniform shader uInput;
            uniform shader uIn2;
            uniform int uOperator;
            uniform float4 uK;
            half4 main(float2 fragCoord) {
                float4 src = uInput.eval(fragCoord);
                float4 dst = uIn2.eval(fragCoord);
                if (uOperator == 0) return half4(src + dst * (1.0 - src.a));
                if (uOperator == 1) return half4(src * dst.a);
                if (uOperator == 2) return half4(src * (1.0 - dst.a));
                if (uOperator == 3) return half4(src * dst.a + dst * (1.0 - src.a));
                if (uOperator == 4) return half4(src * (1.0 - dst.a) + dst * (1.0 - src.a));
                if (uOperator == 5) {
                    float4 res = uK.x * dst * src + uK.y * src + uK.z * dst + uK.w;
                    return half4(clamp(res, 0.0, 1.0));
                }
                return half4(dst);
            }
        """
