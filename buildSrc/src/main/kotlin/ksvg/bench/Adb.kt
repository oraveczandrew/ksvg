package ksvg.bench

import java.io.File
import java.util.concurrent.TimeUnit

class AdbResult(val exitCode: Int, val output: String)

object Adb {
    /** Resolves the adb binary: $ANDROID_HOME/platform-tools/adb, falling back to PATH. */
    fun resolve(): File {
        return System.getenv("ANDROID_HOME")
            ?.let { h -> File(h, "platform-tools/adb") }
            ?.takeIf { it.exists() }
            ?: File("adb")
    }

    /** Synchronous adb run with no timeout; returns merged stdout+stderr and the exit code. */
    fun run(adb: File, vararg args: String): AdbResult {
        val proc = ProcessBuilder(listOf(adb.absolutePath) + args.toList())
            .redirectErrorStream(true)
            .start()
        val out = proc.inputStream.readBytes().toString(Charsets.UTF_8).trim()
        proc.waitFor()
        return AdbResult(proc.exitValue(), out)
    }

    /** adb run with a hard timeout; null when the process had to be killed. */
    fun runBlocking(adb: File, timeoutSeconds: Long, vararg args: String): AdbResult? {
        val proc = ProcessBuilder(listOf(adb.absolutePath) + args.toList())
            .redirectErrorStream(true)
            .start()
        if (!proc.waitFor(timeoutSeconds, TimeUnit.SECONDS)) {
            proc.destroyForcibly()
            return null
        }
        return AdbResult(proc.exitValue(), proc.inputStream.readBytes().toString(Charsets.UTF_8).trim())
    }

    /**
     * Restarts the adb server and waits until an online device appears. Returns the
     * first device serial, or null when none showed up within [maxAttempts] (1s apart).
     */
    fun waitForDevice(adb: File, maxAttempts: Int = 10): String? {
        run(adb, "kill-server")
        run(adb, "start-server")
        for (attempt in 1..maxAttempts) {
            val devices = run(adb, "devices").output
            val serial = devices.lineSequence()
                .map { it.trim() }
                .firstOrNull { it.endsWith("\tdevice") }
                .takeIf { it != null }?.substringBefore('\t')
            if (serial != null) return serial
            if (attempt < maxAttempts) Thread.sleep(1000L)
        }
        return null
    }
}