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

#ifndef KSVG_TURBULENCE_CORE_H
#define KSVG_TURBULENCE_CORE_H

#include <cmath>
#include <cstdint>

namespace {

constexpr int S_BSIZE = 0x100;
constexpr int S_BM = 0xff;

struct PnrRandom {
    int32_t last;
    explicit PnrRandom(int32_t seed) {
        if (seed <= 0) seed = -(seed % 2147483647 - 1) + 1;
        if (seed > 2147483646) seed = 2147483646;
        last = seed;
    }
    int32_t next() {
        const int32_t hi = last / 127773;
        const int32_t lo = last % 127773;
        int32_t r = 16807 * lo - 2836 * hi;
        if (r <= 0) r += 2147483647;
        last = r;
        return r;
    }
};

struct LatticeTables {
    uint8_t selector[S_BSIZE + S_BSIZE + 2];
    float gradX[4][S_BSIZE + S_BSIZE + 2][2];
};

void initLattice(LatticeTables& t, const int32_t seed) {
    PnrRandom rand(seed);

    for (int32_t k = 0; k < 4; k++) {
        for (int32_t i = 0; i < S_BSIZE; i++) {
            float a, b;
            do {
                a = static_cast<float>(rand.next() % (S_BSIZE + S_BSIZE) - S_BSIZE) / S_BSIZE;
                b = static_cast<float>(rand.next() % (S_BSIZE + S_BSIZE) - S_BSIZE) / S_BSIZE;
            } while (a == 0 && b == 0);
            const float s = std::sqrt(a * a + b * b);
            t.gradX[k][i][0] = a / s;
            t.gradX[k][i][1] = b / s;
        }
    }

    for (int32_t i = 0; i < S_BSIZE; i++) {
        t.selector[i] = static_cast<uint8_t>(i);
    }
    for (int32_t i = S_BSIZE - 1; i > 0; i--) {
        const int32_t j = rand.next() % S_BSIZE;
        const uint8_t tmp = t.selector[i];
        t.selector[i] = t.selector[j];
        t.selector[j] = tmp;
    }

    for (int32_t i = 0; i < S_BSIZE + 2; i++) {
        t.selector[S_BSIZE + i] = t.selector[i];
        for (int32_t k = 0; k < 4; k++) {
            t.gradX[k][S_BSIZE + i][0] = t.gradX[k][i][0];
            t.gradX[k][S_BSIZE + i][1] = t.gradX[k][i][1];
        }
    }
}

struct StitchInfo {
    int32_t width = 0;
    int32_t height = 0;
    int32_t wrapX = 0;
    int32_t wrapY = 0;
};

void noise2(
        const LatticeTables& t,
        const int colorChannel,
        const double pxd, const double pyd,
        const StitchInfo& stitch, const bool stitchEnabled,
        float& out) {
    const double tx = pxd + 4096.0;
    const double fxd = std::floor(tx);
    int32_t bx0 = static_cast<int32_t>(fxd);
    int32_t bx1 = bx0 + 1;
    const float rx0 = static_cast<float>(tx - fxd);
    const float rx1 = rx0 - 1.0f;

    const double ty = pyd + 4096.0;
    const double fyd = std::floor(ty);
    int32_t by0 = static_cast<int32_t>(fyd);
    int32_t by1 = by0 + 1;
    const float ry0 = static_cast<float>(ty - fyd);
    const float ry1 = ry0 - 1.0f;

    if (stitchEnabled) {
        if (bx0 >= stitch.wrapX) bx0 -= stitch.width;
        if (bx1 >= stitch.wrapX) bx1 -= stitch.width;
        if (by0 >= stitch.wrapY) by0 -= stitch.height;
        if (by1 >= stitch.wrapY) by1 -= stitch.height;
    }

    bx0 &= S_BM; bx1 &= S_BM;
    by0 &= S_BM; by1 &= S_BM;

    const uint8_t i = t.selector[bx0];
    const uint8_t j = t.selector[bx1];

    const uint8_t b00 = t.selector[i + by0];
    const uint8_t b10 = t.selector[j + by0];
    const uint8_t b01 = t.selector[i + by1];
    const uint8_t b11 = t.selector[j + by1];

    const float sx = rx0 * rx0 * (3 - 2 * rx0);
    const float sy = ry0 * ry0 * (3 - 2 * ry0);

    const float u = rx0 * t.gradX[colorChannel][b00][0] + ry0 * t.gradX[colorChannel][b00][1];
    const float v = rx1 * t.gradX[colorChannel][b10][0] + ry0 * t.gradX[colorChannel][b10][1];
    const float a = u + sx * (v - u);

    const float u2 = rx0 * t.gradX[colorChannel][b01][0] + ry1 * t.gradX[colorChannel][b01][1];
    const float v2 = rx1 * t.gradX[colorChannel][b11][0] + ry1 * t.gradX[colorChannel][b11][1];
    const float b = u2 + sx * (v2 - u2);

    out = a + sy * (b - a);
}

} // namespace

#endif // KSVG_TURBULENCE_CORE_H
