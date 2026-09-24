@file:Suppress("UnstableApiUsage")

import ksvg.bench.Adb
import ksvg.bench.BenchmarkTableWriter
import ksvg.bench.readBenchmarkRows
import ksvg.gradle.configureKsvgPublication
import ksvg.gradle.configureKsvgRepositories
import ksvg.gradle.configureKsvgSigning
import ksvg.gradle.csvProperty
import ksvg.gradle.findStringProperty

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
    id("maven-publish")
    id("signing")
    id("org.jetbrains.dokka")
    id("org.jetbrains.dokka-javadoc")
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
        //noinspection ChromeOsAbiSupport
        csvProperty("filterAbis").takeIf { it.isNotEmpty() }?.let { abis ->
            ndk { abiFilters += abis }
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
    // of libksvgfilters (see TurbulenceNativeParityTest). Point the test JVM at the
    // generated host library directory (produced by the `buildHostNativeLib` task
    // below) so System.loadLibrary("ksvgfilters") resolves it.
    testOptions {
        unitTests {
            all {
                it.jvmArgs("-Djava.library.path=${layout.buildDirectory.get().asFile.resolve("host-native").absolutePath}")
                // Local-dev escape hatch: fork the test workers with a 32-bit JVM
                // (-Pksvg.testJava32 / KSVG_TEST_JAVA32) so the -m32 host lib
                // can load, while Gradle itself stays on a 64-bit JVM
                // (Gradle native services don't exist for i386 and the daemon
                // won't even start there). Unset: no behavior change. NOTE: CI
                // does not use this — 32-bit HotSpot cannot start on the
                // hosted runners' kernels (SI_KERNEL SIGSEGV under
                // vsyscall=none), so the i386 leg only builds, never executes.
                val testJava32: String? = project.findStringProperty("ksvg.testJava32")
                    ?.takeIf { v -> v.isNotBlank() }
                    ?: System.getenv("KSVG_TEST_JAVA32")?.takeIf { v -> v.isNotBlank() }
                if (testJava32 != null) {
                    it.executable(testJava32)
                }
                it.systemProperty("benchmark.quick", System.getProperty("benchmark.quick"))
                it.systemProperty("benchmark.kernel", System.getProperty("benchmark.kernel"))
                it.systemProperty("benchmark.config", System.getProperty("benchmark.config"))
                it.systemProperty("benchmark.host.profile", System.getProperty("benchmark.host.profile"))
            }
        }
    }

    publishing {
        singleVariant("release") {
            withSourcesJar()
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
 * device, pulls the generated CSV files into `<repo>/tmp/device-bench-<abi>/` (e.g.
 * `tmp/device-bench-arm64-v8a/`, `tmp/device-bench-armeabi-v7a/`), and dumps them as
 * a Markdown table to the terminal.
 *
 * The benchmark reads a `kernel` (kernel name filter), `config` (config-name
 * substring filter) and `quick` (boolean) instrumentation argument. All three
 * are forwarded from the optional project properties `benchmark.kernel`,
 * `benchmark.config` and `benchmark.quick` so the invocation stays consistent
 * with the host benchmark (`KernelPerformanceBenchmark`, which reads the same
 * `benchmark.*` system properties). Without them the whole suite runs (a couple
 * of minutes on a phone).
 *
 * `benchmark.config` is `+`-separated, case-insensitive substrings matched
 * against the cell display name (e.g. "Lighting (diffuse, distant, linear)");
 * `benchmark.kernel` and `benchmark.config` are ANDed when both are given.
 * NOTE: the `+` parts are ORed (any match keeps the cell), and full display
 * names do NOT work here — AGP truncates `-P` values at the first comma, so
 * use comma-free fragments (e.g. `benchmark.config=distant` for all four
 * distant-lighting cells, never `specular+distant` to mean AND).
 *
 *   ./gradlew :filtering:runDeviceBenchmark \
 *       -Pandroid.testInstrumentationRunnerArguments.class=hu.oandras.ksvg.filtering.KernelPerformanceDeviceBenchmark \
 *       -Pandroid.testInstrumentationRunnerArguments.benchmark.kernel=Turbulence \
 *       -Pandroid.testInstrumentationRunnerArguments.benchmark.quick=true
 *
 *   ./gradlew :filtering:runDeviceBenchmark \
 *       -Pandroid.testInstrumentationRunnerArguments.class=hu.oandras.ksvg.filtering.KernelPerformanceDeviceBenchmark \
 *       -Pandroid.testInstrumentationRunnerArguments.benchmark.kernel=Lighting \
 *       -Pandroid.testInstrumentationRunnerArguments.benchmark.config=diffuse+distant+linear \
 *       -Pandroid.testInstrumentationRunnerArguments.benchmark.quick=true
 *
 * Results are pulled with `adb pull` once the instrumentation run finishes and
 * printed as a single flat Markdown table (kernels alphabetical, sizes ascending,
 * backends in ISA superset order; speedup vs. the (kernel, size) group's scalar median).
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
    description = "Runs the device kernel benchmark, pulls the CSV results into tmp/device-bench-<abi>/, and prints them as a flat table."

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
        // Clear previous results from the host's ABI result directory, so the
        // Markdown report only reflects the current run.
        // The ABI is the one the benchmark process actually ran as: the
        // installed test package's primary ABI. This covers both the default
        // install (device primary ABI) and a 32-bit-only APK built with
        // -PfilterAbis=armeabi-v7a. Falls back to the device primary ABI when
        // the package dump is unavailable.
        val serial = Adb.waitForDevice(adb, maxAttempts = 10)
        if (serial == null) {
            logger.warn("runDeviceBenchmark: no adb device available after server restart (connect one and re-run)")
            return@doLast
        }
        val abi = Adb.run(adb, "-s", serial, "shell", "pm", "dump", "hu.oandras.filtering.test")
            .outputLineSequence()
            .firstOrNull { it.startsWith("primaryCpuAbi=") }
            ?.substringAfter("=")
            ?.takeIf { it.isNotEmpty() && it != "null" }
            ?: Adb.run(adb, "-s", serial, "shell", "getprop", "ro.product.cpu.abi")
                .outputLineSequence()
                .firstOrNull { it.isNotEmpty() }
            ?: "unknown"
        val abiDir: File = tmpDir.resolve("device-bench-$abi")
        if (abiDir.exists()) {
            abiDir.listFiles { _, name ->
                ((name.startsWith("benchmarks_device") || name.startsWith("benchmarks_harness_detail")) &&
                    name.endsWith(".csv")) ||
                    name.startsWith("simpleperf_benchmark")
            }?.forEach { it.delete() }
        }
        abiDir.mkdirs()

        // The instrumented run leaves the adb server in a stale state that can
        // return "error: device '' not found" for a freshly spawned adb client;
        // the server restart above (Adb.waitForDevice) already handled that, so
        // target the resolved serial explicitly with -s for both find and pull.

        // Locate every benchmark CSV the run left behind and pull it into tmp/device-bench-<abi>/.
        // The benchmark writes to Context.externalCacheDir/benchmarks/<suite>/, i.e., the canonical
        // /storage/emulated/0/Android/data/<pkg>/cache/benchmarks/ path. adb pull needs that
        // exact path, not the /sdcard symlink. `find` recurses into the per-suite
        // subdirectories on its own; scoping the search to benchmarks/ also keeps
        // pre-subdirectory legacy flat files (which setups no longer manage) out of
        // the pull. `find` also prints "find: <path>:
        // Permission denied" noise to stderr, which adb merges into stdout; only
        // accept lines that are real absolute paths to a benchmarks_device CSV.
        val remote = Adb.run(
            adb, "-s", serial, "shell", "find", "/storage/emulated/0/Android/data/hu.oandras.filtering.test/cache/benchmarks",
            "-name", "benchmarks_device*.csv", "-type", "f",
        )
        // Suite-qualify the host-side name so same-named cells from
        // different suites never overwrite each other on pull. The table
        // writer reads row contents, not file names.
        fun suiteOf(path: String): String {
            val after = path.substringAfter("/cache/benchmarks/", "")
            return if ('/' in after) after.substringBefore('/') else "default"
        }
        val pulled = mutableListOf<File>()
        remote.outputLineSequence()
            .filter { it.startsWith("/storage/emulated/0/Android/data/") && it.endsWith(".csv") }
            .forEach { path ->
                val dest = abiDir.resolve(suiteOf(path) + "_" + path.substringAfterLast('/'))
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
        // simpleperf text dump (.txt) and the parsed CSV are fetched. Profiles live in
        // the per-suite benchmarks/<suite>/ subdirectories; distinctness keys on the
        // suite-qualified path, so same-named cells from different suites both survive.
        val profileRemote = Adb.run(
            adb, "-s", serial, "shell", "find", "/storage/emulated/0/Android/data/hu.oandras.filtering.test/cache/benchmarks",
            "-name", "simpleperf_benchmark_*.csv", "-type", "f",
        )
        val pulledProfiles = mutableListOf<File>()
        profileRemote.outputLineSequence()
            .filter { it.startsWith("/storage/emulated/0/Android/data/") && it.endsWith(".csv") }
            .distinctBy { it.substringAfter("/cache/benchmarks/") }
            .forEach { path ->
                val csvPath = path.trim()
                val txtPath = csvPath.removeSuffix(".csv") + ".txt"
                // Suite-qualify the host-side name: same-named cells from different
                // suites must not overwrite each other on pull.
                val base = suiteOf(csvPath) + "_" + csvPath.substringAfterLast('/').removeSuffix(".csv")
                val destTxt = abiDir.resolve("$base.txt")
                Adb.run(adb, "-s", serial, "pull", txtPath, destTxt.absolutePath)
                Adb.run(adb, "-s", serial, "pull", csvPath, abiDir.resolve("$base.csv").absolutePath)
                logger.lifecycle("== Simpleperf profile: $base ==")
                if (destTxt.exists() && destTxt.length() > 0L) {
                    logger.lifecycle(destTxt.readText().trim())
                } else {
                    logger.lifecycle("(no raw profile text pulled)")
                }
                pulledProfiles.add(abiDir.resolve("$base.csv"))
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
    val propCsv = project.findStringProperty("csv") ?: "tmp/benchmarks_host.csv"
    val propOut = project.findStringProperty("output")

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

        val outPath = propOut ?: (propCsv.removeSuffix(".csv") + ".md")
        val outFile = File(rootDirFile, outPath)
        outFile.writeText(outMd)
        logger.lifecycle("exportBenchmarkTable: Generated Markdown table at ${outFile.absolutePath}")
        println(outMd)
    }
}

//noinspection UseTomlInstead
dependencies {
    implementation("androidx.annotation:annotation:1.11.0")

    testFixturesImplementation("junit:junit:4.13.2")
    testFixturesImplementation("androidx.test:monitor:1.8.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation(testFixtures(project(":filtering")))

    androidTestImplementation("androidx.test:runner:1.7.0")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    androidTestImplementation("androidx.activity:activity-ktx:1.13.0")
    androidTestImplementation("androidx.core:core-ktx:1.19.1")
    androidTestImplementation("androidx.lifecycle:lifecycle-runtime-ktx:2.11.0")
    androidTestImplementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.11.0")
    androidTestImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    androidTestImplementation(testFixtures(project(":filtering")))
}

// PUBLISHING (coordinates live in root gradle.properties: ksvg.group / ksvg.version)

configureKsvgPublication(
    artifactId = "filtering",
    displayName = "KSVG Filtering",
    description = "Native SIMD and pure-Kotlin software filter kernels for KSVG.",
    // Test-fixture-only deps (junit, monitor) would otherwise leak into the main
    // POM as runtime deps; Gradle consumers already get correct GMM variants.
    stripPomDependencies = setOf("junit:junit", "androidx.test:monitor"),
)
configureKsvgRepositories()
configureKsvgSigning()

dokka {
    moduleName.set("KSVG Filtering")
}

tasks.register<Jar>("javadocJar") {
    description = "Packages Dokka Javadoc output for publication."
    dependsOn("dokkaGeneratePublicationJavadoc")
    archiveClassifier.set("javadoc")
    from(tasks.named("dokkaGeneratePublicationJavadoc"))
}
