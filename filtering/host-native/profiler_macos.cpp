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

#include <jni.h>
#include <pthread.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <mutex>

#define KPC_CLASS_FIXED_MASK        (1 << 0)
#define KPC_CLASS_CONFIGURABLE_MASK (1 << 1)

typedef int (*kpc_get_counter_count_t)(uint32_t classes);
typedef int (*kpc_get_thread_counters_t)(uint32_t thread, uint32_t count, uint64_t *values);
typedef int (*kpc_set_thread_counting_t)(uint32_t classes);
typedef int (*kpc_set_counting_t)(uint32_t classes);

static kpc_get_counter_count_t kpc_get_counter_count = nullptr;
static kpc_get_thread_counters_t kpc_get_thread_counters = nullptr;
static kpc_set_thread_counting_t kpc_set_thread_counting = nullptr;
static kpc_set_counting_t kpc_set_counting = nullptr;

static std::once_flag kpc_init_once;
static bool kpc_initialized = false;
static uint32_t fixed_count = 0;

static void init_kpc() {
    std::call_once(kpc_init_once, []() {
        void* handle = dlopen("/System/Library/PrivateFrameworks/kperf.framework/kperf", RTLD_LAZY);
        if (!handle) return;

        kpc_get_counter_count = (kpc_get_counter_count_t)dlsym(handle, "kpc_get_counter_count");
        kpc_get_thread_counters = (kpc_get_thread_counters_t)dlsym(handle, "kpc_get_thread_counters");
        kpc_set_thread_counting = (kpc_set_thread_counting_t)dlsym(handle, "kpc_set_thread_counting");
        kpc_set_counting = (kpc_set_counting_t)dlsym(handle, "kpc_set_counting");

        if (kpc_get_counter_count && kpc_get_thread_counters && kpc_set_thread_counting && kpc_set_counting) {
            fixed_count = kpc_get_counter_count(KPC_CLASS_FIXED_MASK);
            kpc_initialized = true;
        }
    });
}

static jboolean is_available() {
    init_kpc();
    return kpc_initialized ? JNI_TRUE : JNI_FALSE;
}

static jint get_fixed_count() {
    if (!kpc_initialized) init_kpc();
    return (jint)fixed_count;
}

static void start_counting() {
    if (!kpc_initialized) init_kpc();
    if (kpc_initialized) {
        kpc_set_counting(KPC_CLASS_FIXED_MASK);
        kpc_set_thread_counting(KPC_CLASS_FIXED_MASK);
    }
}

static jlongArray get_thread_counters(JNIEnv *env) {
    if (!kpc_initialized) init_kpc();
    if (!kpc_initialized) return nullptr;

    if (fixed_count == 0) return nullptr;

    uint64_t* values = (uint64_t*)malloc(fixed_count * sizeof(uint64_t));
    if (!values) return nullptr;

    // 0 = current thread
    int ret = kpc_get_thread_counters(0, fixed_count, values);
    if (ret != 0) {
        free(values);
        return nullptr;
    }

    jlongArray result = env->NewLongArray(fixed_count);
    if (result) {
        env->SetLongArrayRegion(result, 0, fixed_count, (const jlong*)values);
    }

    free(values);
    return result;
}

// JNI exports
extern "C" JNIEXPORT jboolean JNICALL Java_hu_oandras_ksvg_filtering_IntelMacOSProfiler_nativeIsAvailable(JNIEnv *env, jobject thiz) { return is_available(); }
extern "C" JNIEXPORT void JNICALL Java_hu_oandras_ksvg_filtering_IntelMacOSProfiler_nativeStart(JNIEnv *env, jobject thiz) { start_counting(); }
extern "C" JNIEXPORT jint JNICALL Java_hu_oandras_ksvg_filtering_IntelMacOSProfiler_nativeGetFixedCount(JNIEnv *env, jobject thiz) { return get_fixed_count(); }
extern "C" JNIEXPORT jlongArray JNICALL Java_hu_oandras_ksvg_filtering_IntelMacOSProfiler_nativeGetThreadCounters(JNIEnv *env, jobject thiz) { return get_thread_counters(env); }

extern "C" JNIEXPORT jboolean JNICALL Java_hu_oandras_ksvg_filtering_Arm64MacOSProfiler_nativeIsAvailable(JNIEnv *env, jobject thiz) { return is_available(); }
extern "C" JNIEXPORT void JNICALL Java_hu_oandras_ksvg_filtering_Arm64MacOSProfiler_nativeStart(JNIEnv *env, jobject thiz) { start_counting(); }
extern "C" JNIEXPORT jint JNICALL Java_hu_oandras_ksvg_filtering_Arm64MacOSProfiler_nativeGetFixedCount(JNIEnv *env, jobject thiz) { return get_fixed_count(); }
extern "C" JNIEXPORT jlongArray JNICALL Java_hu_oandras_ksvg_filtering_Arm64MacOSProfiler_nativeGetThreadCounters(JNIEnv *env, jobject thiz) { return get_thread_counters(env); }
