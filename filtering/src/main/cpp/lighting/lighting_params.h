//    Copyright 2026 András Oravecz <info@oandras.hu>
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        https://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

#ifndef KSVG_LIGHTING_PARAMS_H
#define KSVG_LIGHTING_PARAMS_H

// Parameter blocks passed by lighting.cpp to the per-ISA assembly row
// kernels (declared in simd_x86.h for x86, called directly for NEON).
// Field order is part of the ABI: the .S rows load by fixed offsets, so
// append-only changes here, mirrored in every kernel. Plain aggregates,
// no padding surprises (all floats).
struct LightingParams {
    float invDx, invDy, k, lx, ly, lz, lr, lg, lb, ss;
};

// Point-light kernel parameter block.  The assembly rows compute the
// per-pixel light direction from (lx,ly,lz) - (ux,uy,surfaceZ).
struct PointLightingParams {
    float invDx, invDy, k, lx, ly, lz, lr, lg, lb, ss, ux0, uy, dux;
};

// Spot-light kernel parameter block.  Extends PointLightingParams with the
// normalised direction-to-target and cosine of the cutoff cone angle.
struct SpotLightingParams {
    float invDx, invDy, k, lx, ly, lz, lr, lg, lb, ss, ux0, uy, dux,
          spotDirX, spotDirY, spotDirZ, spotCos;
};

#endif // KSVG_LIGHTING_PARAMS_H
