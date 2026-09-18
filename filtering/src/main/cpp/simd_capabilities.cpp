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

#include <jni.h>

#include "cpu_dispatch.h"

// Kernel-independent device capability report: which SIMD execution sets this
// build can dispatch to on this CPU. Unlike the per-kernel nativeBackend()
// masks (which describe what one kernel implements), this answers "what can
// run here" for diagnostics. It intentionally mirrors the per-kernel ABI
// logic (scalar always; i386 scalar-only since no SIMD kernels are built
// there), so capability and dispatch stay consistent by construction.
namespace {

jint supportedBackendsForDevice() {
    jint backends = SIMD_BACKEND_SCALAR;
#if defined(__aarch64__)
    backends |= SIMD_BACKEND_NEON64;
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
    backends |= SIMD_BACKEND_NEON32;
#elif defined(__x86_64__) || defined(_M_X64)
    backends |= SIMD_BACKEND_SSSE3;
    if (detectSimdLevel() >= SIMD_AVX2) {
        backends |= SIMD_BACKEND_AVX2;
    }
#endif
    return backends;
}

} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_NativeBackend_supportedBackendsMask(
    [[maybe_unused]] JNIEnv* env, [[maybe_unused]] jclass clazz) {
    return supportedBackendsForDevice();
}
