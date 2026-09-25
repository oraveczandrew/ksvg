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
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/syscall.h>
#include <linux/perf_event.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>

/**
 * Linux PMC access via perf_event_open syscall.
 * Measures cycles and instructions for the calling thread.
 */

static long perf_event_open(struct perf_event_attr *hw_event, pid_t pid,
                           int cpu, int group_fd, unsigned long flags) {
    return syscall(__NR_perf_event_open, hw_event, pid, cpu, group_fd, flags);
}

struct PerfGroup {
    int fd_cycles = -1;
    int fd_instructions = -1;
};

extern "C"
JNIEXPORT jlong JNICALL
Java_hu_oandras_ksvg_filtering_LinuxHardwareProfiler_nativeOpen(JNIEnv *env, jobject thiz) {
    struct perf_event_attr pe;
    memset(&pe, 0, sizeof(struct perf_event_attr));
    // Try standard hardware cycles first
    pe.type = PERF_TYPE_HARDWARE;
    pe.size = sizeof(struct perf_event_attr);
    pe.config = PERF_COUNT_HW_CPU_CYCLES;
    pe.disabled = 1;
    pe.exclude_kernel = 0;
    pe.exclude_hv = 0;

    int fd_cycles = perf_event_open(&pe, 0, -1, -1, 0);
    if (fd_cycles == -1) {
        // Fallback for virtualized PMUs (e.g. VMware vPMC) using raw Intel CPU_CLK_UNHALTED (0x3c)
        pe.type = PERF_TYPE_RAW;
        pe.config = 0x3c;
        fd_cycles = perf_event_open(&pe, 0, -1, -1, 0);
    }

    if (fd_cycles == -1) {
        return 0;
    }

    // Instructions (optional; if unsupported by hypervisor vPMC, we use -1)
    memset(&pe, 0, sizeof(struct perf_event_attr));
    pe.type = PERF_TYPE_HARDWARE;
    pe.size = sizeof(struct perf_event_attr);
    pe.config = PERF_COUNT_HW_INSTRUCTIONS;
    pe.disabled = 1;
    pe.exclude_kernel = 0;
    pe.exclude_hv = 0;

    int fd_instructions = perf_event_open(&pe, 0, -1, fd_cycles, 0);
    if (fd_instructions == -1) {
        pe.type = PERF_TYPE_RAW;
        pe.config = 0xc0; // INST_RETIRED fallback or disable
        fd_instructions = perf_event_open(&pe, 0, -1, fd_cycles, 0);
    }

    PerfGroup* group = new PerfGroup();
    group->fd_cycles = fd_cycles;
    group->fd_instructions = fd_instructions; // may be -1 if unsupported
    return (jlong)group;
}

extern "C"
JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_LinuxHardwareProfiler_nativeClose(JNIEnv *env, jobject thiz, jlong handle) {
    PerfGroup* group = (PerfGroup*)handle;
    if (group) {
        if (group->fd_cycles != -1) close(group->fd_cycles);
        if (group->fd_instructions != -1) close(group->fd_instructions);
        delete group;
    }
}

extern "C"
JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_LinuxHardwareProfiler_nativeStart(JNIEnv *env, jobject thiz, jlong handle) {
    PerfGroup* group = (PerfGroup*)handle;
    if (group && group->fd_cycles != -1) {
        ioctl(group->fd_cycles, PERF_EVENT_IOC_RESET, PERF_IOC_FLAG_GROUP);
        ioctl(group->fd_cycles, PERF_EVENT_IOC_ENABLE, PERF_IOC_FLAG_GROUP);
    }
}

extern "C"
JNIEXPORT jlongArray JNICALL
Java_hu_oandras_ksvg_filtering_LinuxHardwareProfiler_nativeStop(JNIEnv *env, jobject thiz, jlong handle) {
    PerfGroup* group = (PerfGroup*)handle;
    if (!group || group->fd_cycles == -1) return nullptr;

    ioctl(group->fd_cycles, PERF_EVENT_IOC_DISABLE, PERF_IOC_FLAG_GROUP);

    uint64_t cycles = 0, instructions = 0;
    if (read(group->fd_cycles, &cycles, sizeof(uint64_t)) != sizeof(uint64_t)) return nullptr;
    if (group->fd_instructions != -1) {
        read(group->fd_instructions, &instructions, sizeof(uint64_t));
    }

    jlongArray result = env->NewLongArray(2);
    if (result) {
        jlong values[2] = { (jlong)cycles, (jlong)instructions };
        env->SetLongArrayRegion(result, 0, 2, values);
    }
    return result;
}
