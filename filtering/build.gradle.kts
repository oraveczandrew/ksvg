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

//noinspection UseTomlInstead
dependencies {
    implementation("androidx.annotation:annotation:1.10.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation(testFixtures(project(":filtering")))

    androidTestImplementation("androidx.test:runner:1.7.0")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    androidTestImplementation(testFixtures(project(":filtering")))
}
