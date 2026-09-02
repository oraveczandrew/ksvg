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

#ifndef KSVG_TURBULENCE_TABLES_H
#define KSVG_TURBULENCE_TABLES_H

#include <cmath>

constexpr int S_BSIZE = 0x100;
constexpr int S_BM = 0xff;
constexpr int S_TABLE_SIZE = S_BSIZE + S_BSIZE + 2;

struct PnrRandom {
    int32_t last;
    explicit PnrRandom(const int32_t seed) {
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

struct StitchInfo {
    int32_t width = 0;
    int32_t height = 0;
    int32_t wrapX = 0;
    int32_t wrapY = 0;
};

struct PixelGeometry {
    int32_t bx0, bx1, by0, by1;
    double rx0, rx1, ry0, ry1;
    double sx, sy;
    uint8_t b00, b10, b01, b11;
};

static inline jint packPixel(const double sums[4], const bool fractal) {
    const double scale = fractal ? 127.5 : 255.0;
    const double offset = fractal ? 1.0 : 0.0;

    jint comps[4];
    for (int ch = 0; ch < 4; ++ch) {
        jint iv = static_cast<jint>(std::floor((sums[ch] + offset) * scale + 0.5));

        if (iv < 0) iv = 0;
        else if (iv > 255) iv = 255;

        comps[ch] = iv;
    }

    return (comps[3] << 24) |
           (comps[0] << 16) |
           (comps[1] << 8) |
           comps[2];
}

static inline void initBaseTables(
        uint8_t selector[S_TABLE_SIZE],
        double gradX[4][S_TABLE_SIZE][2],
        const int32_t seed) {
    PnrRandom rand(seed);

    for (int32_t k = 0; k < 4; k++) {
        for (int32_t i = 0; i < S_BSIZE; i++) {
            double a, b;
            do {
                a = static_cast<double>(rand.next() % (S_BSIZE + S_BSIZE) - S_BSIZE) / S_BSIZE;
                b = static_cast<double>(rand.next() % (S_BSIZE + S_BSIZE) - S_BSIZE) / S_BSIZE;
            } while (a == 0 && b == 0);
            const double s = std::sqrt(a * a + b * b);
            gradX[k][i][0] = a / s;
            gradX[k][i][1] = b / s;
        }
    }

    for (int32_t i = 0; i < S_BSIZE; i++) {
        selector[i] = static_cast<uint8_t>(i);
    }
    for (int32_t i = S_BSIZE - 1; i > 0; i--) {
        const int32_t j = rand.next() % S_BSIZE;
        const uint8_t tmp = selector[i];
        selector[i] = selector[j];
        selector[j] = tmp;
    }

    for (int32_t i = 0; i < S_BSIZE + 2; i++) {
        selector[S_BSIZE + i] = selector[i];
        for (int32_t k = 0; k < 4; k++) {
            gradX[k][S_BSIZE + i][0] = gradX[k][i][0];
            gradX[k][S_BSIZE + i][1] = gradX[k][i][1];
        }
    }
}

static inline void initBaseTablesSoA(
        uint8_t selector[S_TABLE_SIZE],
        double gradXSoA[4][2][S_TABLE_SIZE],
        const int32_t seed) {
    PnrRandom rand(seed);

    for (int32_t k = 0; k < 4; k++) {
        for (int32_t i = 0; i < S_BSIZE; i++) {
            double a, b;
            do {
                a = static_cast<double>(rand.next() % (S_BSIZE + S_BSIZE) - S_BSIZE) / S_BSIZE;
                b = static_cast<double>(rand.next() % (S_BSIZE + S_BSIZE) - S_BSIZE) / S_BSIZE;
            } while (a == 0 && b == 0);
            const double s = std::sqrt(a * a + b * b);
            gradXSoA[k][0][i] = a / s;
            gradXSoA[k][1][i] = b / s;
        }
    }

    for (int32_t i = 0; i < S_BSIZE; i++) {
        selector[i] = static_cast<uint8_t>(i);
    }
    for (int32_t i = S_BSIZE - 1; i > 0; i--) {
        const int32_t j = rand.next() % S_BSIZE;
        const uint8_t tmp = selector[i];
        selector[i] = selector[j];
        selector[j] = tmp;
    }

    for (int32_t i = 0; i < S_BSIZE + 2; i++) {
        selector[S_BSIZE + i] = selector[i];
        for (int32_t k = 0; k < 4; k++) {
            gradXSoA[k][0][S_BSIZE + i] = gradXSoA[k][0][i];
            gradXSoA[k][1][S_BSIZE + i] = gradXSoA[k][1][i];
        }
    }
}

struct ScalarLatticeTables {
    uint8_t selector[S_TABLE_SIZE];
    double gradX[4][S_TABLE_SIZE][2];
};

static inline void initScalarTables(ScalarLatticeTables& t, const int32_t seed) {
    initBaseTables(t.selector, t.gradX, seed);
}

#if defined(__i386__) || defined(__x86_64__)

struct X86LatticeTables {
    uint8_t selector[S_TABLE_SIZE];
    uint32_t selector32[S_TABLE_SIZE];
    double gradXSoA[4][2][S_TABLE_SIZE];
    double gradPackedX[S_TABLE_SIZE][4];
    double gradPackedY[S_TABLE_SIZE][4];
};

static inline void initX86Tables(X86LatticeTables& t, const int32_t seed) {
    initBaseTablesSoA(t.selector, t.gradXSoA, seed);
    for (int32_t i = 0; i < S_TABLE_SIZE; i++) {
        t.selector32[i] = t.selector[i];
        for (int32_t k = 0; k < 4; k++) {
            t.gradPackedX[i][k] = t.gradXSoA[k][0][i];
            t.gradPackedY[i][k] = t.gradXSoA[k][1][i];
        }
    }
}

#endif

#if defined(__aarch64__)

struct Arm64LatticeTables {
    uint8_t selector[S_TABLE_SIZE];
    uint32_t selector32[S_TABLE_SIZE];
    double gradPackedX[S_TABLE_SIZE][4];
    double gradPackedY[S_TABLE_SIZE][4];
};

static inline void initArm64Tables(Arm64LatticeTables& t, const int32_t seed) {
    double gradX[4][S_TABLE_SIZE][2];
    initBaseTables(t.selector, gradX, seed);
    for (int32_t i = 0; i < S_TABLE_SIZE; i++) {
        t.selector32[i] = t.selector[i];
        for (int32_t k = 0; k < 4; k++) {
            t.gradPackedX[i][k] = gradX[k][i][0];
            t.gradPackedY[i][k] = gradX[k][i][1];
        }
    }
}

#endif

static inline PixelGeometry geometry(
        const uint8_t selector[S_TABLE_SIZE],
        const double pxd,
        const double pyd,
        const StitchInfo& stitch,
        const bool stitchEnabled) {
    PixelGeometry g;

    const double tx = pxd + 4096.0;
    const double fxd = std::floor(tx);
    g.bx0 = static_cast<int32_t>(fxd);
    g.bx1 = g.bx0 + 1;
    g.rx0 = tx - fxd;
    g.rx1 = g.rx0 - 1.0;

    const double ty = pyd + 4096.0;
    const double fyd = std::floor(ty);
    g.by0 = static_cast<int32_t>(fyd);
    g.by1 = g.by0 + 1;
    g.ry0 = ty - fyd;
    g.ry1 = g.ry0 - 1.0;

    if (stitchEnabled) {
        if (stitch.width > 0) {
            if (g.bx0 >= stitch.wrapX) g.bx0 -= stitch.width;
            if (g.bx1 >= stitch.wrapX) g.bx1 -= stitch.width;
        }
        if (stitch.height > 0) {
            if (g.by0 >= stitch.wrapY) g.by0 -= stitch.height;
            if (g.by1 >= stitch.wrapY) g.by1 -= stitch.height;
        }
    }

    g.bx0 &= S_BM;
    g.bx1 &= S_BM;
    g.by0 &= S_BM;
    g.by1 &= S_BM;

    const uint8_t i = selector[g.bx0];
    const uint8_t j = selector[g.bx1];
    g.b00 = selector[i + g.by0];
    g.b10 = selector[j + g.by0];
    g.b01 = selector[i + g.by1];
    g.b11 = selector[j + g.by1];

    g.sx = g.rx0 * g.rx0 * (3.0 - 2.0 * g.rx0);
    g.sy = g.ry0 * g.ry0 * (3.0 - 2.0 * g.ry0);
    return g;
}

static inline PixelGeometry geometry32(
        const uint32_t selector32[S_TABLE_SIZE],
        const double pxd,
        const double pyd,
        const StitchInfo& stitch,
        const bool stitchEnabled) {
    PixelGeometry g;

    const double tx = pxd + 4096.0;
    const double fxd = std::floor(tx);
    g.bx0 = static_cast<int32_t>(fxd);
    g.bx1 = g.bx0 + 1;
    g.rx0 = tx - fxd;
    g.rx1 = g.rx0 - 1.0;

    const double ty = pyd + 4096.0;
    const double fyd = std::floor(ty);
    g.by0 = static_cast<int32_t>(fyd);
    g.by1 = g.by0 + 1;
    g.ry0 = ty - fyd;
    g.ry1 = g.ry0 - 1.0;

    if (stitchEnabled) {
        if (stitch.width > 0) {
            if (g.bx0 >= stitch.wrapX) g.bx0 -= stitch.width;
            if (g.bx1 >= stitch.wrapX) g.bx1 -= stitch.width;
        }
        if (stitch.height > 0) {
            if (g.by0 >= stitch.wrapY) g.by0 -= stitch.height;
            if (g.by1 >= stitch.wrapY) g.by1 -= stitch.height;
        }
    }

    g.bx0 &= S_BM;
    g.bx1 &= S_BM;
    g.by0 &= S_BM;
    g.by1 &= S_BM;

    const uint32_t i = selector32[g.bx0];
    const uint32_t j = selector32[g.bx1];

    g.b00 = static_cast<uint8_t>(selector32[i + g.by0]);
    g.b10 = static_cast<uint8_t>(selector32[j + g.by0]);
    g.b01 = static_cast<uint8_t>(selector32[i + g.by1]);
    g.b11 = static_cast<uint8_t>(selector32[j + g.by1]);

    g.sx = g.rx0 * g.rx0 * (3.0 - 2.0 * g.rx0);
    g.sy = g.ry0 * g.ry0 * (3.0 - 2.0 * g.ry0);

    return g;
}

static inline void noise2(
        const ScalarLatticeTables& t,
        const int colorChannel,
        const double pxd, const double pyd,
        const StitchInfo& stitch, const bool stitchEnabled,
        double& out) {
    const PixelGeometry g = geometry(t.selector, pxd, pyd, stitch, stitchEnabled);

    const double u = g.rx0 * t.gradX[colorChannel][g.b00][0] + g.ry0 * t.gradX[colorChannel][g.b00][1];
    const double v = g.rx1 * t.gradX[colorChannel][g.b10][0] + g.ry0 * t.gradX[colorChannel][g.b10][1];
    const double a = u + g.sx * (v - u);

    const double u2 = g.rx0 * t.gradX[colorChannel][g.b01][0] + g.ry1 * t.gradX[colorChannel][g.b01][1];
    const double v2 = g.rx1 * t.gradX[colorChannel][g.b11][0] + g.ry1 * t.gradX[colorChannel][g.b11][1];
    const double b = u2 + g.sx * (v2 - u2);

    out = a + g.sy * (b - a);
}

#endif // KSVG_TURBULENCE_TABLES_H