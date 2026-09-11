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

// JNI bridge for Linux CPU-affinity controls used ONLY by the device benchmark
// harness (diagnostic): pin the benchmarking thread to one concrete CPU and read
// which CPU it currently runs on. sched_setaffinity may be denied on unrooted
// devices; callers must treat a nonzero return as "not available".

#include <jni.h>
#include <sched.h>
#include <unistd.h>

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_benchmark_CpuAffinity_nativePinToCore(
        [[maybe_unused]] JNIEnv* env, [[maybe_unused]] jclass clazz, const jint cpuId) {
    if (cpuId < 0) {
        // cpuId < 0 -> reset to the full allowlist (opaque mask from the scheduler).
        const int maxCpus = static_cast<int>(sysconf(_SC_NPROCESSORS_CONF));
        if (maxCpus <= 0) return -1;
        cpu_set_t set;
        CPU_ZERO(&set);
        for (int i = 0; i < maxCpus; ++i) CPU_SET(i, &set);
        return sched_setaffinity(0, sizeof(set), &set);
    }
    cpu_set_t set;
    CPU_ZERO(&set);
    CPU_SET(cpuId, &set);
    return sched_setaffinity(0, sizeof(set), &set);
}

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_benchmark_CpuAffinity_nativeGetCurrentCpu(
        [[maybe_unused]] JNIEnv* env, [[maybe_unused]] jclass clazz) {
    return sched_getcpu();
}