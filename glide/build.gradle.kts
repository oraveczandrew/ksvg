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

plugins {
    id("com.android.library")
    id("com.google.devtools.ksp")
    id("maven-publish")
    id("signing")
    id("org.jetbrains.dokka")
    id("org.jetbrains.dokka-javadoc")
}

kotlin {
    explicitApi()
}

android {
    namespace = "hu.oandras.ksvg.glide"
    compileSdk = 37
    // Pinned so AGP never auto-downloads its own default revisions into the
    // CI SDK dir (that re-poisoned the cache every run: NDK 28.2,
    // build-tools 36.0.0). Must match the sdkmanager specs in
    // .github/workflows/*.yml.
    ndkVersion = "29.0.14206865"
    buildToolsVersion = "37.0.0"

    defaultConfig.apply {
        minSdk = 26

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
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

    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }
}

//noinspection UseTomlInstead
dependencies {
    implementation("com.github.bumptech.glide:glide:5.0.9")
    ksp("com.github.bumptech.glide:ksp:5.0.9")

    val ksvgProject = rootProject.findProject(":ksvg:ksvg")
        ?: rootProject.findProject(":ksvg")
        ?: error("KSVG project not found")

    implementation(ksvgProject)

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.17")
}

// PUBLISHING (coordinates live in root gradle.properties: ksvg.group / ksvg.version)

configureKsvgPublication(
    artifactId = "glide",
    displayName = "KSVG Glide",
    description = "Glide image-loading integration for KSVG.",
)
configureKsvgRepositories()
configureKsvgSigning()

dokka {
    moduleName.set("KSVG Glide")
}

tasks.register<Jar>("javadocJar") {
    description = "Packages Dokka Javadoc output for publication."
    dependsOn("dokkaGeneratePublicationJavadoc")
    archiveClassifier.set("javadoc")
    from(tasks.named("dokkaGeneratePublicationJavadoc"))
}
