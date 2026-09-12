@file:Suppress("UnstableApiUsage")

import java.io.File
import ksvg.bench.Adb
import ksvg.bench.BenchmarkTableWriter
import ksvg.bench.readBenchmarkRows

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

apply(from = "host-native.gradle.kts")

val uninstallBenchmarkApk = tasks.register("uninstallBenchmarkApk") {
    group = "verification"
    description = "Removes the previous filtering instrumentation APK before benchmarking."
    doLast {
        val adb = Adb.resolve()

        // The previous instrumentation run can leave the adb server in a stale state where a
        // fresh adb client HANGS instead of returning. Restart the server and wait for the
        // device before touching it (same workaround as runDeviceBenchmark's pull step).
        val serial = Adb.waitForDevice(adb, maxAttempts = 10)
        if (serial == null) {
            logger.lifecycle("runDeviceBenchmark: no adb device available after restart; skipping uninstall")
            return@doLast
        }

        var attempts = 0
        var success = false
        while (attempts < 5 && !success) {
            attempts++
            val res = Adb.runBlocking(adb, 5L, "uninstall", "hu.oandras.filtering.test")
            if (res == null) {
                logger.lifecycle("runDeviceBenchmark: adb uninstall timed out (attempt $attempts/5)")
            } else if (res.exitCode == 0) {
                logger.lifecycle("runDeviceBenchmark: removed hu.oandras.filtering.test")
                success = true
            } else if (res.output.isNotBlank()) {
                logger.lifecycle("runDeviceBenchmark: APK was not installed (adb uninstall: ${res.output})")
            }
        }
    }
}
tasks.matching { it.name == "connectedDebugAndroidTest" }
    .configureEach { mustRunAfter(uninstallBenchmarkApk) }

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
 * Results are pulled with `adb pull` once the instrumentation run finishes and
 * printed as a single flat Markdown table (kernels alphabetical, sizes ascending,
 * backends in ISA superset order; speedup vs the (kernel,size) group's scalar median).
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
    description = "Runs the device kernel benchmark, pulls the CSV results into tmp/, and prints them as a flat table."

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

        // The instrumented run leaves the adb server in a stale state that can
        // return "error: device '' not found" for a freshly-spawned adb client.
        // Restart the server, wait for the USB device to come back, then target
        // its serial explicitly with -s for both the find and the pull.
        val serial = Adb.waitForDevice(adb, maxAttempts = 10)
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
        val remote = Adb.run(
            adb, "-s", serial, "shell", "find", "/storage/emulated/0/Android/data",
            "-name", "benchmarks_device*.csv", "-type", "f",
        ).output
        val pulled = mutableListOf<File>()
        remote.lineSequence()
            .map { it.trim() }
            .filter { it.startsWith("/storage/emulated/0/Android/data/") && it.endsWith(".csv") }
            .forEach { path ->
                val dest = tmpDir.resolve(path.substringAfterLast('/'))
                val pull = Adb.run(adb, "-s", serial, "pull", path, dest.absolutePath).output
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
        val profileRemote = Adb.run(
            adb, "-s", serial, "shell", "find", "/storage/emulated/0/Android/data",
            "-name", "simpleperf_benchmark_*.csv", "-type", "f",
        ).output
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
                Adb.run(adb, "-s", serial, "pull", txtPath, destTxt.absolutePath)
                Adb.run(adb, "-s", serial, "pull", csvPath, tmpDir.resolve("$base.csv").absolutePath)
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

        val table = BenchmarkTableWriter.deviceFlatTable(pulled)
        if (table.isEmpty()) {
            logger.warn("runDeviceBenchmark: no data rows found in pulled CSVs")
            return@doLast
        }
        logger.lifecycle(table)
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

        val rows = readBenchmarkRows(csvFile)
        if (rows.isEmpty()) {
            logger.warn("exportBenchmarkTable: no data in ${csvFile.absolutePath}")
            return@doLast
        }

        val outMd = BenchmarkTableWriter.markdownTable(rows)

        val outPath = propOut ?: propCsv.removeSuffix(".csv") + ".md"
        val outFile = File(rootDirFile, outPath)
        outFile.writeText(outMd)
        logger.lifecycle("exportBenchmarkTable: Generated Markdown table at ${outFile.absolutePath}")
        println(outMd)
    }
}

//noinspection UseTomlInstead
dependencies {
    implementation("androidx.annotation:annotation:1.10.0")

    testFixturesImplementation("junit:junit:4.13.2")
    testFixturesImplementation("androidx.test:monitor:1.8.0")

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
