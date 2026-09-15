/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Spot-light diffuse i386 AVX2 entry points.
 *
 * These forward to the verified SSSE3 kernels.  Both use the same
 * 6-argument i386 ABI (srcT, srcM, srcB, dst, count, params) and the
 * same per-pixel math; %eax=0 selects the standard entry and
 * %eax=1 the linear-to-sRGB entry.
 */

#include "asm_macros.S"

.text
.globl SYM(ksvgLightingSpotDiffuseRowAvx2)
TYPE(SYM(ksvgLightingSpotDiffuseRowAvx2), @function)
SYM(ksvgLightingSpotDiffuseRowAvx2):
    JMP(ksvgLightingSpotDiffuseRowSsse3)
SIZE(SYM(ksvgLightingSpotDiffuseRowAvx2))

.globl SYM(ksvgLightingSpotDiffuseRowAvx2Linear)
TYPE(SYM(ksvgLightingSpotDiffuseRowAvx2Linear), @function)
SYM(ksvgLightingSpotDiffuseRowAvx2Linear):
    JMP(ksvgLightingSpotDiffuseRowSsse3Linear)
SIZE(SYM(ksvgLightingSpotDiffuseRowAvx2Linear))
