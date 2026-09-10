@file:Suppress("UnstableApiUsage")

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

plugins {
    id("com.android.library")
}

kotlin {
    explicitApi()
}

android {
    namespace = "hu.oandras.filtering"
    compileSdk = 37

    testFixtures {
        enable = true
    }

    defaultConfig.apply {
        minSdk = 26

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        externalNativeBuild {
            cmake {
                // Arguments are intentionally empty; per-ABI source selection
                // (Blur_advsimd.S for armeabi-v7a, x86.cpp for x86/x86_64) lives
                // in CMakeLists.txt via ANDROID_ABI.
            }
        }

        // Optional ABI filter: pass -PfilterAbis=armeabi-v7a to build a 32-bit-only
        // test APK (useful for exercising the ARM32 NEON kernel on arm64 devices).
        // Without the property, all ABIs are built as usual.
        project.findProperty("filterAbis")?.toString()?.split(",")?.map { it.trim() }?.filter { it.isNotEmpty() }?.toList()?.let { abis ->
            ndk { abiFilters.addAll(abis) }
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    buildTypes.apply {
        getByName("release") {
            isMinifyEnabled = false
        }
        getByName("debug") {
            isMinifyEnabled = false
        }
        create("beta") {
            isMinifyEnabled = false
            matchingFallbacks.add("release")
        }
        create("benchmark") {
            isMinifyEnabled = false
            matchingFallbacks.add("release")
        }
    }

    compileOptions.apply {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin.apply {
        compilerOptions.freeCompilerArgs = listOf(
            "-opt-in=kotlin.RequiresOptIn",
            "-Xno-param-assertions",
            "-Xvalidate-bytecode",
            "-Xjspecify-annotations=strict",
            "-Xjsr305=strict",
            "-XXLanguage:+WhenGuards",
            "-Xreturn-value-checker=check",
        )
    }

    // JVM unit tests may drive the native kernels directly through the host build
    // of libksvgblur (see TurbulenceNativeParityTest). Point the test JVM at the
    // generated host library directory (produced by the `buildHostNativeLib` task
    // below) so System.loadLibrary("ksvgblur") resolves it.
    testOptions {
        unitTests {
            all {
                it.jvmArgs("-Djava.library.path=${layout.buildDirectory.get().asFile.resolve("host-native").absolutePath}")
                it.systemProperty("benchmark.quick", System.getProperty("benchmark.quick"))
                it.systemProperty("benchmark.kernel", System.getProperty("benchmark.kernel"))
            }
        }
    }

}

// Host-architecture build of the native kernels (turbulence, blur, lighting, ...)
// so JVM unit tests can drive the real native path bit-exactly against the Kotlin
// reference (TurbulenceNativeParityTest). Output lands in this module's build dir.
val hostNativeCpp: FileTree = fileTree("src/main/cpp") {
    include("**/*.cpp", "**/*.h", "**/*.S")
}
val hostNativeOutputDir: File = layout.buildDirectory.dir("host-native").get().asFile
val hostLibName: String = when {
    System.getProperty("os.name").lowercase().contains("mac") -> "libksvgblur.dylib"
    System.getProperty("os.name").lowercase().contains("linux") -> "libksvgblur.so"
    else -> "ksvgblur.dll"
}
val buildHostNativeLib = tasks.register<Exec>("buildHostNativeLib") {
    group = "verification"
    description = "Builds a host-architecture libksvgblur for native-vs-Kotlin kernel parity tests."
    inputs.files(hostNativeCpp)
    inputs.file(rootProject.file("filtering/host-native/CMakeLists.txt"))
    outputs.file(hostNativeOutputDir.resolve(hostLibName))
    workingDir(rootProject.file("filtering/host-native"))
    val configureDir = hostNativeOutputDir.resolve("cmake")
    commandLine(
        "sh", "-c",
        "cmake -S . -B ${configureDir.absolutePath} " +
            "-DCMAKE_BUILD_TYPE=Release " +
            "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${hostNativeOutputDir.absolutePath} " +
            "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=${hostNativeOutputDir.absolutePath} " +
            "&& cmake --build ${configureDir.absolutePath} -j",
    )
}
tasks.matching { it.name == "testDebugUnitTest" }.configureEach { dependsOn(buildHostNativeLib) }

val uninstallBenchmarkApk = tasks.register("uninstallBenchmarkApk") {
    group = "verification"
    description = "Removes the previous filtering instrumentation APK before benchmarking."
    doLast {
        val adb = System.getenv("ANDROID_HOME")?.let { h -> File(h, "platform-tools/adb") }
            ?.takeIf { it.exists() } ?: File("adb")
        val proc = ProcessBuilder(adb.absolutePath, "uninstall", "hu.oandras.filtering.test")
            .redirectErrorStream(true)
            .start()
        val out = proc.inputStream.readBytes().toString(Charsets.UTF_8).trim()
        proc.waitFor()
        if (proc.exitValue() == 0) {
            logger.lifecycle("runDeviceBenchmark: removed hu.oandras.filtering.test")
        } else if (out.isNotBlank()) {
            logger.lifecycle("runDeviceBenchmark: APK was not installed (adb uninstall: $out)")
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
 *       -Pbenchmark.kernel=Turbulence -Pbenchmark.quick=true
 *
 * Results are pulled with `adb pull` once the instrumentation run finishes.
 * `android.injected.androidTest.leaveApksInstalledAfterRun=true` keeps the
 * test APK (and its cache dir) on the device so the file survives the run
 * window long enough to be pulled.
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
                (name.startsWith("benchmarks_device") || name.startsWith("benchmarks_harness_detail")) &&
                    name.endsWith(".csv")
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

//noinspection UseTomlInstead
dependencies {
    implementation("androidx.annotation:annotation:1.10.0")

    testFixturesImplementation("junit:junit:4.13.2")

    testImplementation("junit:junit:4.13.2")
    testImplementation(testFixtures(project(":filtering")))

    androidTestImplementation("androidx.test:runner:1.7.0")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    androidTestImplementation("androidx.activity:activity-ktx:1.13.0")
    androidTestImplementation("androidx.core:core-ktx:1.19.0")
    androidTestImplementation("androidx.lifecycle:lifecycle-runtime-ktx:2.11.0")
    androidTestImplementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.11.0")
    androidTestImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    androidTestImplementation(testFixtures(project(":filtering")))
}
