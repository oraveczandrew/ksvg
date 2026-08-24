/*
 * Separable Gaussian blur, ported from the Android RenderScript Intrinsics
 * Replacement Toolkit's `Blur` (Apache-2.0).
 *
 * Operates on ARGB pixels (as supplied by android.graphics.Bitmap.getPixels):
 * each of the A,R,G,B channels is blurred independently. Pixels outside the
 * bitmap are treated as transparent black, matching the SVG spec for
 * filter-region edges (stdDeviation == Gaussian sigma).
 *
 * Dispatch:
 *  - Isotropic (stdDeviationX == stdDeviationY), radius in [1, 25]:
 *    the RIR optimized kernels (ARM NEON *U4_K / x86 SSE *VFU4_K+*HFU4_K) are
 *    used on a zero-padded copy of the image so the kernels' edge clamp reads
 *    transparent black.
 *  - Anisotropic (stdDeviationX != stdDeviationY) or radius > 25 (the kernels
 *    are unrolled up to 25): the pure-C++ scalar two-pass fallback is used.
 */

#include <jni.h>
#include <cmath>
#include <vector>
#include <cstdint>
#include <cstring>

namespace {

constexpr float kPi = 3.1415926535897932f;
constexpr int kMaxKernelRadius = 25; // RIR kernels are unrolled up to radius 25
constexpr int kScalarMaxRadius = 64;

#if defined(__aarch64__) || defined(__arm__)
extern "C" void rsdIntrinsicBlurU4_K(uint8_t* out, const uint8_t* in,
                                     size_t w, size_t h, size_t p, size_t x,
                                     size_t y, size_t count, size_t r,
                                     const uint16_t* tab);
#elif defined(__i386__) || defined(__x86_64__)
#include "cpu_dispatch.h"
#include "simd_x86.h"

extern "C" void rsdIntrinsicBlurVFU4_K(void* dst, const void* pin, int stride,
                                       const void* gptr, int rct, int x1, int x2);
extern "C" void rsdIntrinsicBlurHFU4_K(void* dst, const void* pin,
                                       const void* gptr, int rct, int x1, int x2);
#endif

// Caller-owned scratch, passed in via JNI as a jlong handle. All reusable
// buffers live here so the blur performs no allocation on the hot path and is
// safe to call concurrently from multiple threads (each render operation owns
// its own instance). Buffers are only re-grown when the dimensions increase.
struct GaussianScratch {
    std::vector<float> bufA;   // premultiplied floats a,r,g,b interleaved (w*h*4)
    std::vector<float> bufB;
    std::vector<uint8_t> paddedIn;   // zero-padded copy for the kernel path (pw*ph*4)
    std::vector<uint8_t> paddedOut;  // kernel path output (pw*ph*4)
    std::vector<float> fbuf;         // column buffer for the x86 kernel path ((pw+2r)*4)
};

// Computes true-Gaussian weights for the given standard deviation (SVG:
// stdDeviation == sigma). Returns the integer radius; fills `weights` with a
// normalized kernel indexed so that weights[radius + k] is the weight for
// offset k (k in [-radius, radius]).
int computeWeights(const float sigma, std::vector<float>& weights) {
    weights.clear();
    if (sigma <= 0.0f) return 0;
    int radius = static_cast<int>(std::ceil(3.0f * sigma));
    if (radius < 1) radius = 1;
    if (radius > kScalarMaxRadius) radius = kScalarMaxRadius;

    weights.reserve(2 * radius + 1);
    const float coeff1 = 1.0f / std::sqrt(2.0f * kPi) / sigma;
    const float coeff2 = -1.0f / (2.0f * sigma * sigma);

    float sum = 0.0f;
    for (int k = -radius; k <= radius; ++k) {
        const float v = coeff1 * std::exp(static_cast<float>(k) * static_cast<float>(k) * coeff2);
        weights.push_back(v);
        sum += v;
    }
    const float inv = 1.0f / sum;
    for (float& w : weights) w *= inv;
    return radius;
}

inline uint32_t pack(const float a, const float r, const float g, const float b) {
    int ia = static_cast<int>(a + 0.5f);
    int ir = static_cast<int>(r + 0.5f);
    int ig = static_cast<int>(g + 0.5f);
    int ib = static_cast<int>(b + 0.5f);
    if (ia < 0) ia = 0; else if (ia > 255) ia = 255;
    if (ir < 0) ir = 0; else if (ir > 255) ir = 255;
    if (ig < 0) ig = 0; else if (ig > 255) ig = 255;
    if (ib < 0) ib = 0; else if (ib > 255) ib = 255;
    return (static_cast<uint32_t>(ia) << 24) |
           (static_cast<uint32_t>(ir) << 16) |
           (static_cast<uint32_t>(ig) << 8) |
           static_cast<uint32_t>(ib);
}

// Pure-C++ two-pass separable blur (reference + fallback). Handles arbitrary
// (possibly anisotropic) radii per axis.
void blurScalar(jint* pix, const int w, const int h,
                const std::vector<float>& wx, const int rx,
                const std::vector<float>& wy, const int ry,
                GaussianScratch& s) {
    const int n = w * h;
    const size_t need = static_cast<size_t>(n) * 4;
    if (s.bufA.size() < need) s.bufA.resize(need);
    if (s.bufB.size() < need) s.bufB.resize(need);

    for (int i = 0; i < n; ++i) {
        const uint32_t p = static_cast<uint32_t>(pix[i]);
        s.bufA[i * 4 + 0] = static_cast<float>((p >> 24) & 0xff);
        s.bufA[i * 4 + 1] = static_cast<float>((p >> 16) & 0xff);
        s.bufA[i * 4 + 2] = static_cast<float>((p >> 8) & 0xff);
        s.bufA[i * 4 + 3] = static_cast<float>(p & 0xff);
    }

    auto separablePass = [&](const std::vector<float>& wt, const int radius, const bool horizontal) {
        if (radius == 0) return;
        const int dim = horizontal ? w : h;
        for (int y = 0; y < h; ++y) {
            for (int x = 0; x < w; ++x) {
                float sa = 0.0f, sr = 0.0f, sg = 0.0f, sb = 0.0f;
                for (int k = -radius; k <= radius; ++k) {
                    const int coord = (horizontal ? x : y) + k;
                    if (coord >= 0 && coord < dim) {
                        const int idx = (horizontal ? (y * w + coord) : (coord * w + x)) * 4;
                        const float wgt = wt[k + radius];
                        sa += s.bufA[idx + 0] * wgt;
                        sr += s.bufA[idx + 1] * wgt;
                        sg += s.bufA[idx + 2] * wgt;
                        sb += s.bufA[idx + 3] * wgt;
                    }  // else: transparent black (0)
                }
                const int o = (y * w + x) * 4;
                s.bufB[o + 0] = sa;
                s.bufB[o + 1] = sr;
                s.bufB[o + 2] = sg;
                s.bufB[o + 3] = sb;
            }
        }
        s.bufA.swap(s.bufB);
    };

    separablePass(wx, rx, /* horizontal = */ true);
    separablePass(wy, ry, /* horizontal = */ false);

    for (int i = 0; i < n; ++i) {
        pix[i] = static_cast<jint>(pack(
                s.bufA[i * 4 + 0], s.bufA[i * 4 + 1],
                s.bufA[i * 4 + 2], s.bufA[i * 4 + 3]));
    }
}

// Isotropic fast path using the RIR separable kernels. `pix` is the raw
// premultiplied-ARGB byte buffer. Returns true if a kernel backend ran.
bool blurIsotropicKernel(uint8_t* pix, const int w, const int h, const int r,
                          const std::vector<float>& weights,
                          GaussianScratch& s) {
#if defined(__aarch64__) || defined(__arm__) || defined(__i386__) || defined(__x86_64__)
    const int pad = r;
    const int pw = w + 2 * pad;
    const int ph = h + 2 * pad;
    const size_t stride = static_cast<size_t>(pw) * 4; // bytes per row
    const size_t pn = static_cast<size_t>(pw) * static_cast<size_t>(ph) * 4;

    // Reuse caller-owned padded buffers so the fast path allocates nothing.
    // Pixels outside [pad, pad+h) x [pad, pad+w) are transparent black, so the
    // kernels' edge clamp reads SVG-correct edges (memset clears the whole pad).
    if (s.paddedIn.size() < pn) s.paddedIn.resize(pn);
    if (s.paddedOut.size() < pn) s.paddedOut.resize(pn);
    std::memset(s.paddedIn.data(), 0, pn);
    std::vector<uint8_t>& in = s.paddedIn;
    std::vector<uint8_t>& out = s.paddedOut;
    for (int y = 0; y < h; ++y) {
        const uint8_t* src = pix + static_cast<size_t>(y) * w * 4;
        uint8_t* dst = in.data() + static_cast<size_t>((y + pad) * pw + pad) * 4;
        std::memcpy(dst, src, static_cast<size_t>(w) * 4);
    }

#if defined(__aarch64__) || defined(__arm__)
    std::vector<uint16_t> mIp(2 * r + 1);
    for (int k = -r; k <= r; ++k)
        mIp[k + r] = static_cast<uint16_t>(weights[k + r] * 65536.0f + 0.5f);
    const uint16_t* tab = mIp.data() + r; // centered for the ARM kernels

    for (int y = pad; y < pad + h; ++y) {
        uint8_t* outRow = out.data() + static_cast<size_t>(y) * stride;
        const uint8_t* inRow = in.data() + static_cast<size_t>(y) * stride;
        rsdIntrinsicBlurU4_K(outRow, inRow, static_cast<size_t>(pw), static_cast<size_t>(ph), stride,
                             0, static_cast<size_t>(y), static_cast<size_t>(pw), static_cast<size_t>(r), tab);
    }
#else
    const float* gptr = weights.data();   // gptr[k] = weight at offset k
    const int rct = 2 * r + 1;
    const size_t fn = static_cast<size_t>(pw + 2 * r) * 4;
    if (s.fbuf.size() < fn) s.fbuf.resize(fn);
    float* fbuf0 = s.fbuf.data();             // valid pointer for pin = fbuf0
    float* fbuf_mid = fbuf0 + (size_t)r * 4;  // float4 per padded column

    for (int y = pad; y < pad + h; ++y) {
        const uint8_t* inTop = in.data() + static_cast<size_t>((y - r) * pw) * 4;

        // Vertical pass -> float4 per column (fbuf_mid[0..pw)).
        // AVX2 path handles 8 columns per iteration; the SSE kernel covers
        // pairs; the remaining <=7 tail runs scalar either way.
        int vEnd;
        if (detectSimdLevel() >= SIMD_AVX2) {
            vEnd = pw & ~7;
            if (vEnd > 0)
                ksvgBlurVerticalAvx2(fbuf_mid, inTop, (int)stride, gptr, rct, 0, vEnd);
        } else {
            vEnd = pw & ~1;
            if (vEnd > 0)
                rsdIntrinsicBlurVFU4_K(fbuf_mid, inTop, (int)stride, gptr, rct, 0, vEnd);
        }
        for (int xx = vEnd; xx < pw; ++xx) {
            float a = 0.0f, rr = 0.0f, g = 0.0f, b = 0.0f;
            for (int k = -r; k <= r; ++k) {
                const uint8_t* p = in.data() + static_cast<size_t>((y + k) * pw + xx) * 4;
                const float wt = weights[k + r];
                a += p[0] * wt; rr += p[1] * wt; g += p[2] * wt; b += p[3] * wt;
            }
            float* f = fbuf_mid + (size_t)xx * 4;
            f[0] = a; f[1] = rr; f[2] = g; f[3] = b;
        }

        // Horizontal pass from fbuf. The kernel reads column (x1+k) weighted by
        // gptr[k]=weight(k-r), so with pin=fbuf0 (=fbuf_mid - r) it computes the
        // blur of fbuf_mid[x1] and writes out[x1]; it covers [0, pw-r), and the
        // remaining [pw-r, pw) columns are done scalarly (edges read transparent
        // black via the bounds guard below).
        uint8_t* outRow = out.data() + static_cast<size_t>(y) * stride;
        const int hx2 = pw - r;
        if (hx2 > 0)
            rsdIntrinsicBlurHFU4_K(outRow, fbuf0, gptr, rct, 0, hx2);

        for (int xx = hx2; xx < pw; ++xx) {
            float a = 0.0f, rr = 0.0f, g = 0.0f, b = 0.0f;
            for (int k = -r; k <= r; ++k) {
                const int xx2 = xx + k;
                if (xx2 >= 0 && xx2 < pw) {
                    const float* p = fbuf_mid + (size_t)xx2 * 4;
                    const float wt = weights[k + r];
                    a += p[0] * wt; rr += p[1] * wt; g += p[2] * wt; b += p[3] * wt;
                }  // else: transparent black (0)
            }
            uint8_t* o = outRow + (size_t)xx * 4;
            o[0] = (uint8_t)(a + 0.5f); o[1] = (uint8_t)(rr + 0.5f);
            o[2] = (uint8_t)(g + 0.5f); o[3] = (uint8_t)(b + 0.5f);
        }
    }
#endif

    for (int y = 0; y < h; ++y) {
        const uint8_t* src = out.data() + static_cast<size_t>((y + pad) * pw + pad) * 4;
        uint8_t* dst = pix + static_cast<size_t>(y) * w * 4;
        std::memcpy(dst, src, static_cast<size_t>(w) * 4);
    }
    return true;
#else
    (void)pix; (void)w; (void)h; (void)r; (void)weights;
    return false;
#endif
}

}  // namespace

extern "C"
JNIEXPORT jlong JNICALL Java_hu_oandras_ksvg_filtering_NativeGaussianBlur_createScratch(
        JNIEnv*, jclass) {
    return reinterpret_cast<jlong>(new GaussianScratch());
}

extern "C"
JNIEXPORT void JNICALL Java_hu_oandras_ksvg_filtering_NativeGaussianBlur_destroyScratch(
        JNIEnv*, jclass, const jlong handle) {
    delete reinterpret_cast<GaussianScratch*>(handle);
}

extern "C"
JNIEXPORT void JNICALL Java_hu_oandras_ksvg_filtering_NativeGaussianBlur_nativeBlur(
        JNIEnv* env, jclass, const jlong scratchHandle, const jintArray pixels, const jint width,
        const jint height, const jfloat stdDeviationX, const jfloat stdDeviationY) {
    GaussianScratch* const s = reinterpret_cast<GaussianScratch*>(scratchHandle);
    jint* pix = env->GetIntArrayElements(pixels, nullptr);
    if (pix == nullptr) return;

    const int w = width;
    const int h = height;

    std::vector<float> wx, wy;
    const int rx = computeWeights(stdDeviationX, wx);
    const int ry = computeWeights(stdDeviationY, wy);
    if (rx == 0 && ry == 0) {
        env->ReleaseIntArrayElements(pixels, pix, 0);
        return;
    }

    // Isotropic + small-enough radius -> optimized RIR kernels.
    const bool isotropic = (rx == ry);
    if (isotropic && rx >= 1 && rx <= kMaxKernelRadius) {
        if (blurIsotropicKernel(reinterpret_cast<uint8_t*>(pix), w, h, rx, wx, *s)) {
            env->ReleaseIntArrayElements(pixels, pix, 0);
            return;
        }
        // No backend for this ABI: fall through to scalar.
    }

    blurScalar(pix, w, h, wx, rx, wy, ry, *s);
    env->ReleaseIntArrayElements(pixels, pix, 0);
}
