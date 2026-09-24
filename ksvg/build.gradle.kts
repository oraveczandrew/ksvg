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

import ksvg.gradle.configureKsvgPublication
import ksvg.gradle.configureKsvgRepositories
import ksvg.gradle.configureKsvgSigning
import ksvg.gradle.findStringProperty

plugins {
    id("com.android.library")
    id("maven-publish")
    id("signing")
    id("org.jetbrains.dokka")
    id("org.jetbrains.dokka-javadoc")
    id("jacoco")
}

kotlin {
    explicitApi()
}

jacoco {
    toolVersion = "0.8.12"
}

android.apply {
    namespace = "hu.oandras.ksvg"
    compileSdk = 37

    defaultConfig.apply {
        minSdk = 26

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildFeatures.apply {
        buildConfig = true
    }

    buildTypes.apply {
        getByName("release") {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        getByName("debug") {
            isMinifyEnabled = false
            enableUnitTestCoverage = true
            enableAndroidTestCoverage = true
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

    sourceSets {
        getByName("test") {
            resources.directories.add("../test-data")
        }
        getByName("androidTest") {
            assets.directories.add("test-data")
        }
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
        unitTests.all {
            it.jvmArgs("-noverify")
            // Forward `-PverifyFilter=name` so visual-comparison tests can run on a single SVG.
            val verifyFilter = project.findStringProperty("verifyFilter")
            if (!verifyFilter.isNullOrBlank()) {
                it.systemProperty("ksvg.verify.filter", verifyFilter)
            }
            val turbDebug = project.findStringProperty("turbDebug")
            if (!turbDebug.isNullOrBlank()) {
                it.systemProperty("ksvg.debug.turbulence", turbDebug)
            }
        }
    }

    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }
}

tasks.withType<Test>().configureEach {
    if (project.hasProperty("excludeSlowTests")) {
        exclude("**/MeteoconsVisualComparisonTest.*")
        exclude("**/VerificationVisualComparisonTest.*")
    }
    extensions.findByType<JacocoTaskExtension>()?.apply {
        isIncludeNoLocationClasses = true
        excludes = listOf("jdk.internal.*")
    }
}

tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.add("-Xlint:deprecation")
}

//noinspection UseTomlInstead
dependencies.apply {
    implementation("androidx.annotation:annotation:1.11.0")
    implementation("androidx.lifecycle:lifecycle-common:2.11.0")
    implementation("com.google.guava:guava:33.7.1-android")
    implementation("androidx.collection:collection:1.6.0")

    implementation(project(":filtering"))

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")

    androidTestImplementation("androidx.test:runner:1.7.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.16.1")

    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    // Round-B corpus parity runners reuse the :filtering validation corpora
    // and the pure-Kotlin parity SVG builders (tmp/GPU_PARITY_PLAN_B.md §3).
    androidTestImplementation(testFixtures(project(":filtering")))
}

// PUBLISHING (coordinates live in root gradle.properties: ksvg.group / ksvg.version)

configureKsvgPublication(
    artifactId = "ksvg",
    displayName = "KSVG",
    description = "SVG rendering library for Android.",
)
configureKsvgRepositories()
configureKsvgSigning()

dokka {
    moduleName.set("KSVG")
    dokkaPublications.html {
        suppressInheritedMembers.set(true)
        failOnWarning.set(true)
        outputDirectory.set(rootProject.layout.projectDirectory.dir("doc"))
    }
    dokkaSourceSets {
        create("main") {
            sourceLink {
                localDirectory.set(file("src/main/kotlin"))
                remoteUrl("https://oraveczandrew.github.io/ksvg/")
                remoteLineSuffix.set("#L")
            }
        }
    }
    pluginsConfiguration.html {
        footerMessage.set("(c) András Oravecz")
    }
}

tasks.register<Jar>("javadocJar") {
    description = "Packages Dokka Javadoc output for publication."
    dependsOn("dokkaGeneratePublicationJavadoc")
    archiveClassifier.set("javadoc")
    from(tasks.named("dokkaGeneratePublicationJavadoc"))
}

tasks.register<JacocoReport>("jacocoTestReport") {
    description = "Generates Jacoco coverage report for Debug unit tests."
    group = "Reporting"
    dependsOn("testDebugUnitTest")

    reports {
        xml.required.set(true)
        html.required.set(true)
    }

    val fileFilter = listOf(
        "**/R.class", "**/R$*.class", "**/BuildConfig.*", "**/Manifest*.*", "**/*Test*.*", "android/**/*.*"
    )
    
    val kotlinClasses = fileTree("${layout.buildDirectory.get()}/intermediates/built_in_kotlinc/debug/compileDebugKotlin/classes") {
        exclude(fileFilter)
    }
    val javaClasses = fileTree("${layout.buildDirectory.get()}/intermediates/javac/debug/compileDebugJavaWithJavac/classes") {
        exclude(fileFilter)
    }

    sourceDirectories.setFrom(files("${project.projectDir}/src/main/kotlin", "${project.projectDir}/src/main/java"))
    classDirectories.setFrom(files(kotlinClasses, javaClasses))
    executionData.setFrom(fileTree(layout.buildDirectory.get()) {
        include(
            "outputs/unit_test_code_coverage/debugUnitTest/testDebugUnitTest.exec",
            "jacoco/testDebugUnitTest.exec"
        )
    })
}

tasks.register<JacocoCoverageVerification>("jacocoTestCoverageVerification") {
    description = "Fails the build when :ksvg unit-test coverage drops below the ratchet."
    group = "Verification"
    dependsOn("testDebugUnitTest")

    // Same class/execution inputs as jacocoTestReport above; keep in sync.
    val fileFilter = listOf(
        "**/R.class", "**/R$*.class", "**/BuildConfig.*", "**/Manifest*.*", "**/*Test*.*", "android/**/*.*"
    )

    val kotlinClasses = fileTree("${layout.buildDirectory.get()}/intermediates/built_in_kotlinc/debug/compileDebugKotlin/classes") {
        exclude(fileFilter)
    }
    val javaClasses = fileTree("${layout.buildDirectory.get()}/intermediates/javac/debug/compileDebugJavaWithJavac/classes") {
        exclude(fileFilter)
    }

    sourceDirectories.setFrom(files("${project.projectDir}/src/main/kotlin", "${project.projectDir}/src/main/java"))
    classDirectories.setFrom(files(kotlinClasses, javaClasses))
    executionData.setFrom(fileTree(layout.buildDirectory.get()) {
        include(
            "outputs/unit_test_code_coverage/debugUnitTest/testDebugUnitTest.exec",
            "jacoco/testDebugUnitTest.exec"
        )
    })

    // Ratchet just under the measured level (LINE ~75%, BRANCH ~58% as of the
    // coverage round): normal PRs pass with headroom, large drops fail loudly.
    // Raise together with real coverage gains, never lower to fit a PR.
    violationRules {
        rule {
            limit {
                counter = "LINE"
                minimum = "0.70".toBigDecimal()
            }
            limit {
                counter = "BRANCH"
                minimum = "0.50".toBigDecimal()
            }
        }
    }
}
