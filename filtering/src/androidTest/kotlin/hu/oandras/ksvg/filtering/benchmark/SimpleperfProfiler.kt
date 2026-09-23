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

package hu.oandras.ksvg.filtering.benchmark

import android.content.Context
import android.os.Process
import android.os.SystemClock
import java.io.File
import java.lang.Process as JProcess
import java.util.Locale
import java.util.concurrent.TimeUnit

/**
 * In-process `simpleperf` wrapper for per-kernel benchmark profiling.
 *
 * The benchmark process spawns `simpleperf stat -p <own pid> -t <own tid>` as a child, runs a
 * deadline-based loop of the kernel on the SAME thread (thread-scoped counters, GC/alloc threads
 * excluded), then stops the child and parses the counter table. The child writes to the app's
 * internal cache (guaranteed writable by the app uid); the result is copied to the external cache
 * so the host runner can `adb pull` it without `run-as`.
 */
class SimpleperfProfiler(private val appContext: Context) {

    fun isAvailable(): Boolean =
        try {
            val process =
                ProcessBuilder("sh", "-c", "command -v simpleperf").redirectErrorStream(true).start()
            val output = process.inputStream.bufferedReader().readText().trim()
            process.waitFor() == 0 && output.isNotEmpty()
        } catch (_: Throwable) {
            false
        }

    /**
     * Filters [requested] down to the events this device's `simpleperf` actually supports,
     * validated via `simpleperf list`. `cycles` maps to `cpu-cycles`; unknown names are
     * dropped, never guessed. Returns the requested list unchanged when `simpleperf list`
     * cannot be read (availability is then re-checked when a profile actually runs).
     */
    fun supportedEvents(requested: List<String>): List<String> =
        if (requested.isEmpty()) {
            emptyList()
        } else {
            val available =
                runCatching {
                    val process =
                        ProcessBuilder("sh", "-c", "simpleperf list 2>&1")
                            .redirectErrorStream(true)
                            .start()
                    val output = process.inputStream.bufferedReader().readText()
                    process.waitFor()
                    output.lineSequence().map { it.trim() }.toSet()
                }.getOrElse { emptySet() }
                if (available.isEmpty()) {
                    requested
                } else {
                    val normalized =
                        requested.map { name -> if (name == "cycles") "cpu-cycles" else name.lowercase(Locale.US) }
                    normalized.filter { name ->
                        available.any { a -> a == name || a.endsWith(":$name") || a == "$name:" }
                    }
                }
        }

    /**
     * Runs [work] on the calling thread inside a window of [durationMs] milliseconds while
     * `simpleperf stat` counts [events] for that thread. Pins the caller to [cpuCore] and raises
     * its priority to mirror the timing harness conditions, then restores both. Returns a parsed
     * [SimpleperfProfile] or null when profiling could not be established.
     */
    fun profile(
        name: String,
        suite: String = "default",
        events: List<String>,
        durationMs: Long,
        cpuCore: Int?,
        work: () -> Unit,
    ): SimpleperfProfile? {
        val internalDir = appContext.cacheDir
        val externalDir = appContext.externalCacheDir
        if (internalDir == null || externalDir == null) {
            println("Simpleperf: no cache dirs; skipping profile of $name")
            return null
        }
        if (events.isEmpty()) {
            println("Simpleperf: empty event list; skipping profile of $name")
            return null
        }
        val tid = Process.myTid()
        val rawInternal = File(internalDir, "simpleperf_$name.txt")
        rawInternal.delete()

        val binary = resolveSimpleperf() ?: run {
            println("Simpleperf: binary not found; skipping profile of $name")
            return null
        }

        val previousPriority = captureAndRaisePriority(tid)
        var affinityApplied = false
        if (cpuCore != null) {
            affinityApplied = CpuAffinity.pinToCore(cpuCore)
            if (!affinityApplied) {
                println("Simpleperf: sched_setaffinity(cpu$cpuCore) failed; profile window NOT pinned")
            }
        }

        val command =
            listOf(
                binary,
                "stat",
                "-p",
                Process.myPid().toString(),
                "-t",
                tid.toString(),
                "-e",
                events.joinToString(","),
                "-o",
                rawInternal.absolutePath,
                "--duration",
                String.format(Locale.US, "%.2f", durationMs / 1000.0 + 0.5),
            )

        var process: JProcess? = null
        var iterations = 0
        var spawnError: String? = null
        try {
            process =
                ProcessBuilder(command).start()
            SystemClock.sleep(250)
            val deadline = SystemClock.elapsedRealtime() + durationMs
            while (SystemClock.elapsedRealtime() < deadline) {
                work()
                iterations++
            }
        } catch (t: Throwable) {
            spawnError = t.message ?: t::class.java.simpleName
        } finally {
            if (process != null) {
                var rc = -1
                try {
                    rc =
                        if (process.waitFor((durationMs + 1000).coerceAtLeast(1500), TimeUnit.MILLISECONDS)) {
                            0
                        } else {
                            -1
                        }
                } catch (_: InterruptedException) {
                    Thread.currentThread().interrupt()
                }
                if (process.isAlive) {
                    process.destroyForcibly()
                    try {
                        if (!process.waitFor(2000, TimeUnit.MILLISECONDS)) {
                            rc = -1
                        }
                    } catch (_: InterruptedException) {
                        Thread.currentThread().interrupt()
                    }
                }
                println("Simpleperf: stat exit=$rc (nostop=${!processIsAlive(process)})")
            }
            if (affinityApplied) {
                CpuAffinity.resetAffinity()
            }
            restorePriority(tid, previousPriority)
        }

        if (spawnError != null) {
            println("Simpleperf: profile of $name failed to spawn: $spawnError")
            return null
        }

        val counts = parseCounts(rawInternal)
        if (counts.isEmpty()) {
            val diag =
                if (rawInternal.exists()) {
                    rawInternal
                        .readLines()
                        .filter { it.isNotBlank() }
                        .takeLast(6)
                        .joinToString(" | ")
                } else {
                    "no output file"
                }
            println("Simpleperf: profile of $name produced no counters -> $diag")
            return null
        }

        val windowMs = windowMsOf(rawInternal) ?: durationMs
        // Suite subdirectory (mirrors the timing-harness layout): classes sharing
        // one instrumentation run never touch each other's profiles.
        val suiteDir = File(externalDir, "$BENCHMARKS_DIR_NAME/$suite")
        suiteDir.mkdirs()
        val rawExternal = File(suiteDir, "simpleperf_$name.txt")
        rawInternal.copyTo(rawExternal, overwrite = true)
        val csv = File(suiteDir, "simpleperf_$name.csv")
        writeCsv(csv, name, counts, windowMs, iterations)

        val profile = SimpleperfProfile(
            name = name,
            counts = counts,
            windowMs = windowMs,
            iterations = iterations,
            rawFile = rawExternal,
            csvFile = csv,
        )
        println(profile.block())
        return profile
    }

    private fun resolveSimpleperf(): String? =
        try {
            val process = ProcessBuilder("sh", "-c", "command -v simpleperf").start()
            val path = process.inputStream.bufferedReader().readText().trim()
            if (process.waitFor() == 0 && path.isNotEmpty()) path else null
        } catch (_: Throwable) {
            null
        }

    private fun processIsAlive(process: JProcess): Boolean =
        try {
            process.isAlive
        } catch (_: Throwable) {
            false
        }

    private fun captureAndRaisePriority(tid: Int): Int? =
        try {
            val previous = Process.getThreadPriority(tid)
            Process.setThreadPriority(tid, PROFILE_PRIORITY)
            previous
        } catch (_: Throwable) {
            null
        }

    private fun restorePriority(tid: Int, previous: Int?) {
        if (previous == null) return
        try {
            Process.setThreadPriority(tid, previous)
        } catch (_: Throwable) {
            // best-effort only
        }
    }

    private fun parseCounts(file: File): Map<String, Long> {
        if (!file.exists()) return mapOf()
        return file.readLines()
            .mapNotNull { line ->
                val match = countRow.find(line) ?: return@mapNotNull null
                val count = match.groupValues[1].replace(",", "").toLongOrNull() ?: return@mapNotNull null
                val event = match.groupValues[2]
                event to count
            }
            .toMap()
    }

    private fun windowMsOf(file: File): Long? {
        val line = file.readLines().lastOrNull { it.startsWith("Total test time:") } ?: return null
        val seconds = totalTimeRow.find(line)?.groupValues?.get(1)?.toDoubleOrNull() ?: return null
        return (seconds * 1000).toLong()
    }

    private fun writeCsv(
        file: File,
        name: String,
        counts: Map<String, Long>,
        windowMs: Long,
        iterations: Int,
    ) {
        file.writeText(
            buildString {
                append("profile,event,count,windowMs,iterations\n")
                for ((event, count) in counts) {
                    append(name)
                    append(',')
                    append(event)
                    append(',')
                    append(count)
                    append(',')
                    append(windowMs)
                    append(',')
                    append(iterations)
                    append('\n')
                }
            }
        )
    }

    private companion object {
        @JvmField
        val countRow = Regex("^\\s*([0-9][0-9,]*)\\s+(\\S+)")
        @JvmField
        val totalTimeRow = Regex("([0-9.]+)")

        const val PROFILE_PRIORITY = -20
    }
}

data class SimpleperfProfile(
    @JvmField
    val name: String,
    @JvmField
    val counts: Map<String, Long>,
    @JvmField
    val windowMs: Long,
    @JvmField
    val iterations: Int,
    @JvmField
    val rawFile: File,
    @JvmField
    val csvFile: File,
) {
    val ipc: Double?
        get() {
            val cycles = counts["cpu-cycles"] ?: return null
            val instructions = counts["instructions"] ?: return null
            if (cycles <= 0L) return null
            return instructions.toDouble() / cycles
        }

    fun block(): String =
        buildString {
            appendLine(
                String.format(Locale.US, "== Simpleperf: %s (window=%dms iterations=%d) ==",
                    name, windowMs, iterations)
            )
            for ((event, count) in counts) {
                appendLine(String.format(Locale.US, "  %-16s %14d", event, count))
            }
            ipc?.let { appendLine(String.format(Locale.US, "  %-16s %14.3f", "ipc", it)) }
            val cycles = counts["cpu-cycles"]
            if (iterations > 0 && cycles != null && cycles > 0 && cycles / iterations > 0) {
                appendLine(String.format(Locale.US, "  %-16s %14d", "cycles/iter", cycles / iterations))
            }
            appendLine("  raw=${rawFile.absolutePath}")
        }
}