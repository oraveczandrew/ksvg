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

internal const val MORPHOLOGY_SHADER: String = """
            uniform shader uInput;
            uniform float2 uRadius;
            uniform int uErode;
            half4 main(float2 fragCoord) {
                float2 r = abs(uRadius);
                int steps = int(max(r.x, r.y));
                float2 dir = sign(uRadius);
                float4 res = uInput.eval(fragCoord);
                for (int i = 1; i <= 20; ++i) {
                    if (i > steps) break;
                    res = (uErode != 0) 
                        ? min(res, min(uInput.eval(fragCoord + float(i) * dir), uInput.eval(fragCoord - float(i) * dir)))
                        : max(res, max(uInput.eval(fragCoord + float(i) * dir), uInput.eval(fragCoord - float(i) * dir)));
                }
                return half4(res);
            }
        """
