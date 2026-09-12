import java.io.File
import java.util.concurrent.TimeUnit

val uninstallBenchmarkApk = tasks.register("uninstallBenchmarkApk") {
    group = "verification"
    description = "Removes the previous filtering instrumentation APK before benchmarking."
    doLast {
        val adb = System.getenv("ANDROID_HOME")?.let { h -> File(h, "platform-tools/adb") }
            ?.takeIf { it.exists() } ?: File("adb")

        // The previous instrumentation run can leave the adb server in a stale state where a
        // fresh adb client HANGS instead of returning. Restart the server and wait for the
        // device before touching it (same workaround as runDeviceBenchmark's pull step).
        var adbOut = ""
        fun adbWait(timeoutSec: Long, vararg args: String): Int? {
            val proc = ProcessBuilder(listOf(adb.absolutePath) + args.toList())
                .redirectErrorStream(true)
                .start()
            if (!proc.waitFor(timeoutSec, TimeUnit.SECONDS)) {
                proc.destroyForcibly()
                return null
            }
            adbOut = proc.inputStream.readBytes().toString(Charsets.UTF_8).trim()
            return proc.exitValue()
        }

        adbWait(10, "kill-server")
        adbWait(10, "start-server")
        var deviceReady = false
        for (attempt in 1..10) {
            if (adbWait(10, "devices") == 0 &&
                adbOut.lineSequence().any { it.trim().endsWith("\tdevice") }) {
                deviceReady = true
                break
            }
            Thread.sleep(1000L)
        }
        if (!deviceReady) {
            logger.lifecycle("runDeviceBenchmark: no adb device available after restart; skipping uninstall")
            return@doLast
        }

        var attempts = 0
        var success = false
        while (attempts < 5 && !success) {
            attempts++
            val rc = adbWait(5, "uninstall", "hu.oandras.filtering.test")
            if (rc == null) {
                logger.lifecycle("runDeviceBenchmark: adb uninstall timed out (attempt $attempts/5)")
            } else if (rc == 0) {
                logger.lifecycle("runDeviceBenchmark: removed hu.oandras.filtering.test")
                success = true
            } else if (adbOut.isNotBlank()) {
                logger.lifecycle("runDeviceBenchmark: APK was not installed (adb uninstall: $adbOut)")
            }
        }
    }
}
tasks.matching { it.name == "connectedDebugAndroidTest" }
    .configureEach { mustRunAfter(uninstallBenchmarkApk) }


// Aggregate all pulled CSV rows by (Kernel, Size) and emit one combined
// table per group, sorted by MedianMs ascending (fastest backend first).
data class BenchRow(val header: List<String>, val values: List<String>)

/*
 * Device kernel benchmark wrapper.
 *
 * Runs the instrumented `KernelPerformanceDeviceBenchmark` on the connected
 * device, pulls the generated CSV files into `<repo>/tmp/`, and dumps them as
 * a Markdown table to the terminal.
 *
 * The benchmark reads a `kernel` (kernel name filter) and `quick` (boolean)
 * instrumentation argument. Both are forwarded from the optional project
 * properties `benchmark.kernel` and `benchmark.quick` so the invocation stays
 * consistent with the host benchmark (`KernelPerformanceBenchmark`, which reads
 * the same `benchmark.*` system properties). Without them the whole suite runs
 * (a couple of minutes on a phone).
 *
 *   ./gradlew :filtering:runDeviceBenchmark \
 *       -Pandroid.testInstrumentationRunnerArguments.class=hu.oandras.ksvg.filtering.KernelPerformanceDeviceBenchmark \
 *       -Pandroid.testInstrumentationRunnerArguments.benchmark.kernel=Turbulence \
 *       -Pandroid.testInstrumentationRunnerArguments.benchmark.quick=true
 *
 * Results are pulled with `adb pull` once the instrumentation run finishes.
 * `android.injected.androidTest.leaveApksInstalledAfterRun=true` keeps the
 * test APK (and its cache dir) on the device so the file survives the run
 * window long enough to be pulled.
 *
 * Optional simpleperf profiling (see KernelPerformanceDeviceBenchmark):
 * the run then also pulls and prints the per-cell `simpleperf_benchmark_*.txt|.csv`
 * profile dumps from the same cache dir.
 *
 *   ./gradlew :filtering:runDeviceBenchmark \
 *       -Pandroid.testInstrumentationRunnerArguments.class=hu.oandras.ksvg.filtering.KernelPerformanceDeviceBenchmark \
 *       -Pandroid.testInstrumentationRunnerArguments.benchmark.kernel=Lighting \
 *       -Pandroid.testInstrumentationRunnerArguments.benchmark.quick=true \
 *       -Pandroid.testInstrumentationRunnerArguments.benchmark.simpleperf=true \
 *       -Pandroid.testInstrumentationRunnerArguments.benchmark.simpleperf.events=cpu-cycles+instructions
 * (Note: AGP coerces a comma-separated instrumentation value down to its first element, so
 *  through `runDeviceBenchmark` the events must be joined with `+`; commas are accepted only
 *  when invoking `am instrument` directly.)
 */
val runDeviceBenchmark = tasks.register("runDeviceBenchmark") {
    group = "verification"
    description = "Runs the device kernel benchmark, pulls the CSV results into tmp/, and prints them."

    // Instrumentation arguments are forwarded the AGP-native way, on the
    // command line, e.g.:
    //   ./gradlew :filtering:runDeviceBenchmark \
    //       -Pandroid.testInstrumentationRunnerArguments.class=hu.oandras.ksvg.filtering.KernelPerformanceDeviceBenchmark \
    //       -Pandroid.testInstrumentationRunnerArguments.benchmark.quick=true

    // Resolve the tmp dir once, at configuration time, so the doLast action
    // only touches serializable File/String values (configuration-cache safe).
    val adb: File = System.getenv("ANDROID_HOME")?.let { h -> File(h, "platform-tools/adb") }
        ?.takeIf { it.exists() } ?: File("adb")
    val tmpDir: File = rootProject.file("tmp")

    dependsOn(uninstallBenchmarkApk, tasks.named("connectedDebugAndroidTest"))

    doLast {
        // Clear previous results from the host's tmp directory so the Markdown
        // report only reflects the current run.
        if (tmpDir.exists()) {
            tmpDir.listFiles { _, name ->
                ((name.startsWith("benchmarks_device") || name.startsWith("benchmarks_harness_detail")) &&
                    name.endsWith(".csv")) ||
                    name.startsWith("simpleperf_benchmark")
            }?.forEach { it.delete() }
        }
        tmpDir.mkdirs()

        fun adbRun(vararg args: String): String {
            val proc = ProcessBuilder(listOf(adb.absolutePath) + args.toList())
                .redirectErrorStream(true)
                .start()
            val out = proc.inputStream.readBytes().toString(Charsets.UTF_8).trim()
            proc.waitFor()
            if (proc.exitValue() != 0) {
                logger.warn("adb ${args.joinToString(" ")} exited ${proc.exitValue()}:\n$out")
            }
            return out
        }

        // The instrumented run leaves the adb server in a stale state that can
        // return "error: device '' not found" for a freshly-spawned adb client.
        // Restart the server, wait for the USB device to come back, then target
        // its serial explicitly with -s for both the find and the pull.
        adbRun("kill-server")
        adbRun("start-server")
        var serial: String? = null
        for (attempt in 1..10) {
            val devices = adbRun("devices")
            serial = devices.lineSequence()
                .map { it.trim() }
                .firstOrNull { it.endsWith("\tdevice") }
                .takeIf { it != null }?.substringBefore('\t')
            if (serial != null) break
            Thread.sleep(1000L)
        }
        if (serial == null) {
            logger.warn("runDeviceBenchmark: no adb device available after server restart (connect one and re-run)")
            return@doLast
        }

        // Locate every benchmark CSV the run left behind and pull it into tmp/.
        // The benchmark writes to Context.externalCacheDir, i.e. the canonical
        // /storage/emulated/0/Android/data/<pkg>/cache/ path. adb pull needs that
        // exact path, not the /sdcard symlink. `find` also prints "find: <path>:
        // Permission denied" noise to stderr, which adb merges into stdout; only
        // accept lines that are real absolute paths to a benchmarks_device CSV.
        val remote = adbRun(
            "-s", serial, "shell", "find", "/storage/emulated/0/Android/data",
            "-name", "benchmarks_device*.csv", "-type", "f",
        )
        val pulled = mutableListOf<File>()
        remote.lineSequence()
            .map { it.trim() }
            .filter { it.startsWith("/storage/emulated/0/Android/data/") && it.endsWith(".csv") }
            .forEach { path ->
                val dest = tmpDir.resolve(path.substringAfterLast('/'))
                val pull = adbRun("-s", serial, "pull", path, dest.absolutePath)
                if ("1 file pulled" in pull || dest.exists()) {
                    pulled.add(dest)
                }
            }

        if (pulled.isEmpty()) {
            logger.warn("runDeviceBenchmark: no benchmarks_device*.csv found on device (did the instrumentation run?)")
            return@doLast
        }

        pulled.forEach { p -> logger.lifecycle("runDeviceBenchmark: pulled ${p.absolutePath}") }

        // Pull + print the per-cell simpleperf profiles when the run used profiling.
        // Cell names are simpleperf_benchmark_<Kernel>_<Backend>_<W>x<H>; both the raw
        // simpleperf text dump (.txt) and the parsed CSV are fetched.
        val profileRemote = adbRun(
            "-s", serial, "shell", "find", "/storage/emulated/0/Android/data",
            "-name", "simpleperf_benchmark_*.csv", "-type", "f",
        )
        val pulledProfiles = mutableListOf<File>()
        profileRemote.lineSequence()
            .map { it.trim() }
            .filter { it.startsWith("/storage/emulated/0/Android/data/") && it.endsWith(".csv") }
            .distinctBy { it.substringAfterLast('/') }
            .forEach { path ->
                val csvPath = path.trim()
                val txtPath = csvPath.removeSuffix(".csv") + ".txt"
                val base = csvPath.substringAfterLast('/').removeSuffix(".csv")
                val destTxt = tmpDir.resolve("$base.txt")
                adbRun("-s", serial, "pull", txtPath, destTxt.absolutePath)
                adbRun("-s", serial, "pull", csvPath, tmpDir.resolve("$base.csv").absolutePath)
                logger.lifecycle("== Simpleperf profile: $base ==")
                if (destTxt.exists() && destTxt.length() > 0L) {
                    logger.lifecycle(destTxt.readText().trim())
                } else {
                    logger.lifecycle("(no raw profile text pulled)")
                }
                pulledProfiles.add(tmpDir.resolve("$base.csv"))
            }
        if (pulledProfiles.isNotEmpty()) {
            pulledProfiles.forEach { p ->
                logger.lifecycle("runDeviceBenchmark: pulled profile ${p.absolutePath}")
            }
        }

        val rows: List<BenchRow> = run {
            val rows = mutableListOf<BenchRow>()
            for (reportFile in pulled) {
                reportFile.bufferedReader().use {
                    val lines = it.lineSequence().mapNotNull { line ->
                        line.trim().ifEmpty { null }
                    }

                    val linesIterator = lines.iterator()
                    val firstLine = linesIterator.next()
                    if (!linesIterator.hasNext()) continue
                    val header = firstLine.split(",")
                    for (line in linesIterator) {
                        rows.add(BenchRow(header, line.split(",")))
                    }
                }
            }
            rows
        }

        if (rows.isEmpty()) {
            logger.warn("runDeviceBenchmark: no data rows found in pulled CSVs")
            return@doLast
        }

        // Column indices for grouping and sorting.
        val firstRowHeader = rows.first().header
        val kernelIdx = firstRowHeader.indexOf("Kernel")
        val sizeIdx = firstRowHeader.indexOf("Size")
        val medianIdx = firstRowHeader.indexOf("MedianMs")

        val groups = rows.groupBy { row ->
            val values = row.values
            listOf(values[kernelIdx], values[sizeIdx])
        }

        // Merge headers: keep the unique union in CSV-header order.
        val mergedHeader = rows.flatMap { it.header }.distinct()

        for ((key, group) in groups.entries.sortedBy { it.key.joinToString("\u0000") }) {
            val kernel = key[0]
            val size = key[1]
            logger.lifecycle("\n### $kernel ($size)")
            val sorted = group.sortedBy { row ->
                row.values.getOrNull(medianIdx)?.toDoubleOrNull() ?: Double.MAX_VALUE
            }
            // Build a 2-D string grid: header + data rows, then left-pad every
            // cell to the column's max width so the Markdown table is readable
            // even in raw form.
            val grid = mutableListOf(mergedHeader)
            for ((header, values) in sorted) {
                val valueMap = header.zip(values).toMap()
                grid.add(mergedHeader.map { col -> valueMap[col] ?: "" })
            }
            val colWidths = IntArray(mergedHeader.size) { col ->
                grid.maxOf { row -> row[col].length }
            }
            for ((i, row) in grid.withIndex()) {
                val line = row.mapIndexed { col, cell -> cell.padEnd(colWidths[col]) }
                    .joinToString(" | ")
                logger.lifecycle("| $line |")
                if (i == 0) {
                    val sep = colWidths.indices.joinToString(" | ") { col ->
                        "-".repeat(colWidths[col])
                    }
                    logger.lifecycle("| $sep |")
                }
            }
        }
    }
}

// Convert CSV to formatted Markdown benchmark table
val exportBenchmarkTable = tasks.register("exportBenchmarkTable") {
    group = "verification"
    description = "Converts a benchmark results CSV file into a formatted Markdown table following ISA superset order."

    val rootDirFile = rootProject.rootDir
    val propCsv = project.findProperty("csv")?.toString() ?: "tmp/benchmarks_host.csv"
    val propOut = project.findProperty("output")?.toString()

    doLast {
        val csvFile = File(rootDirFile, propCsv)
        if (!csvFile.exists()) {
            logger.warn("exportBenchmarkTable: CSV file not found at ${csvFile.absolutePath}")
            return@doLast
        }

        fun parseCsvLine(line: String): List<String> {
            val result = mutableListOf<String>()
            val sb = StringBuilder()
            var inQuotes = false
            for (ch in line) {
                when {
                    ch == '\"' -> inQuotes = !inQuotes
                    ch == ',' && !inQuotes -> {
                        result.add(sb.toString().trim())
                        sb.clear()
                    }
                    else -> sb.append(ch)
                }
            }
            result.add(sb.toString().trim())
            return result
        }

        val rows = mutableListOf<BenchRow>()
        csvFile.bufferedReader().use {
            val lines = it.lineSequence().mapNotNull { l -> l.trim().ifEmpty { null } }
            val itLine = lines.iterator()
            if (!itLine.hasNext()) return@use
            val header = parseCsvLine(itLine.next())
            for (line in itLine) {
                rows.add(BenchRow(header, parseCsvLine(line)))
            }
        }

        if (rows.isEmpty()) {
            logger.warn("exportBenchmarkTable: no data in ${csvFile.absolutePath}")
            return@doLast
        }

        val header = rows.first().header
        val kernelIdx = header.indexOf("Kernel")
        val sizeIdx = header.indexOf("Size")
        val backendIdx = header.indexOf("Backend")
        val isDeviceFormat = header.contains("MedianMs")

        val isaOrder = listOf("kotlin", "scalar", "sse2", "ssse3", "avx2", "avx512", "neon32", "neon64")

        fun backendRank(b: String): Int {
            val lower = b.lowercase()
            val idx = isaOrder.indexOfFirst { lower.contains(it) }
            return if (idx >= 0) idx else 999
        }

        val outMd = StringBuilder()

        if (isDeviceFormat) {
            val groups = rows.groupBy { listOf(it.values[kernelIdx], it.values[sizeIdx]) }
            for ((key, group) in groups.entries.sortedBy { it.key.joinToString(" ") }) {
                val kernel = key[0]
                val size = key[1]
                outMd.append("### $kernel ($size)\n\n")

                val sorted = group.sortedBy { backendRank(it.values[backendIdx]) }

                outMd.append("| Backend | Median (ms) | Min (ms) | Max (ms) | Speedup (vs Scalar) | Speedup (vs Kotlin) | Status |\n")
                outMd.append("| :--- | :--- | :--- | :--- | :--- | :--- | :--- |\n")

                val scalarMedian = sorted.firstOrNull { it.values[backendIdx].equals("scalar", ignoreCase = true) }
                    ?.let { it.header.zip(it.values).toMap()["MedianMs"]?.toDoubleOrNull() }
                val kotlinMedian = sorted.firstOrNull { it.values[backendIdx].equals("kotlin", ignoreCase = true) }
                    ?.let { it.header.zip(it.values).toMap()["MedianMs"]?.toDoubleOrNull() }

                for (row in sorted) {
                    val map = row.header.zip(row.values).toMap()
                    val b = map["Backend"] ?: ""
                    val medStr = map["MedianMs"] ?: ""
                    val minStr = map["MinMs"] ?: ""
                    val maxStr = map["MaxMs"] ?: ""
                    val med = medStr.toDoubleOrNull()

                    val spScalar = map["SpeedupVsScalar"]?.takeIf { it.isNotEmpty() } ?: if (med != null && scalarMedian != null && med > 0.0) {
                        String.format(java.util.Locale.US, "%.2fx", scalarMedian / med)
                    } else "—"

                    val spKotlin = map["SpeedupVsKotlin"]?.takeIf { it.isNotEmpty() } ?: if (med != null && kotlinMedian != null && med > 0.0) {
                        String.format(java.util.Locale.US, "%.2fx", kotlinMedian / med)
                    } else "—"

                    val speedupNum = spScalar.removeSuffix("x").toDoubleOrNull() ?: 1.0

                    val status = when {
                        b.equals("Kotlin", ignoreCase = true) -> "—"
                        b.equals("scalar", ignoreCase = true) -> "🟢 baseline"
                        speedupNum >= 2.0 -> "🚀 $spScalar"
                        speedupNum > 1.05 -> "🟢 $spScalar"
                        speedupNum < 0.95 -> "🔴 regression"
                        else -> "—"
                    }

                    outMd.append("| $b | $medStr | $minStr | $maxStr | $spScalar | $spKotlin | $status |\n")
                }
                outMd.append("\n")
            }
        } else {
            // Host benchmark CSV format (AvgMs, MPix/s, GB/s, Speedup) -> BENCHMARKS.md-style
            // flat table: kernels alphabetical, sizes ascending, backends in ISA superset
            // order (`kotlin -> scalar -> sse2 -> ssse3 -> avx2 -> avx512 -> neon32 -> neon64`).
            // Status conventions match BENCHMARKS.md: >9x -> 🚀 (speedup bolded),
            // >1x -> 🟢, <1x -> 🔴, scalar -> no icon; faster-than-scalar Kotlin -> ⬆️.
            outMd.append("| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup | Status | Note |\n")
            outMd.append("| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |\n")

            fun sizeRank(s: String): Int {
                val parts = s.lowercase().split("x")
                val w = parts.getOrNull(0)?.toIntOrNull() ?: Int.MAX_VALUE
                val h = parts.getOrNull(1)?.toIntOrNull() ?: Int.MAX_VALUE
                return if (w == Int.MAX_VALUE || h == Int.MAX_VALUE) Int.MAX_VALUE else w * h
            }

            val sorted = rows.sortedWith(
                compareBy<BenchRow>(
                    { it.values[kernelIdx] },
                    { sizeRank(it.values[sizeIdx]) },
                    { backendRank(it.values[backendIdx]) },
                )
            )

            for (row in sorted) {
                val map = row.header.zip(row.values).toMap()
                val name = map["Kernel"] ?: ""
                val b = map["Backend"] ?: ""
                val size = map["Size"] ?: ""
                val avgMs = map["AvgMs"] ?: ""
                val mpix = map["MPix/s"] ?: ""
                val gbs = map["GB/s"] ?: ""
                val spRaw = map["Speedup"] ?: ""
                val spNum = spRaw.removeSuffix("x").toDoubleOrNull()
                val spText = if (spRaw.endsWith("x")) spRaw else "${spRaw}x"

                val isKotlin = b.equals("kotlin", ignoreCase = true)
                val isScalar = b.equals("scalar", ignoreCase = true)
                val status: String
                val bold: Boolean
                when {
                    isScalar -> {
                        status = ""
                        bold = false
                    }
                    isKotlin -> {
                        bold = false
                        status = if (spNum != null && spNum > 1.0) "⬆️" else ""
                    }
                    else -> {
                        val rocket = spNum != null && spNum > 9.0
                        bold = rocket
                        status = when {
                            rocket -> "🚀"
                            spNum != null && spNum > 1.0 -> "🟢"
                            spNum != null && spNum < 1.0 -> "🔴"
                            else -> ""
                        }
                    }
                }
                val spCell = if (bold) "**${spText}**" else spText
                outMd.append("| $name | $b | $size | $avgMs | $mpix | $gbs | $spCell | $status |  |\n")
            }
            outMd.append("\n")
        }

        val outPath = propOut ?: propCsv.removeSuffix(".csv") + ".md"
        val outFile = File(rootDirFile, outPath)
        outFile.writeText(outMd.toString())
        logger.lifecycle("exportBenchmarkTable: Generated Markdown table at ${outFile.absolutePath}")
        println(outMd.toString())
    }
}
