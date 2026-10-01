/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
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
import java.lang.module.ModuleFinder.compose

plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.compose.compiler)
    id("maven-publish")
    id("signing")
    alias(libs.plugins.dokka)
    alias(libs.plugins.dokka.javadoc)
}

kotlin {
    explicitApi()
}

android {
    namespace = "hu.oandras.ksvg.compose"
    compileSdk = libs.versions.compileSdk.get().toInt()
    ndkVersion = libs.versions.ndk.get()
    buildToolsVersion = libs.versions.buildTools.get()

    defaultConfig.apply {
        minSdk = libs.versions.minSdk.get().toInt()

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

    buildFeatures.apply {
        compose = true
    }

    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }
}

dependencies {
    implementation(project(":ksvg"))

    implementation(libs.coroutines.android)

    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.foundation)
    implementation(libs.lifecycle.runtime.compose)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
}

// PUBLISHING (coordinates live in root gradle.properties: ksvg.group / ksvg.version)

configureKsvgPublication(
    artifactId = "compose",
    displayName = "KSVG Compose",
    description = "Jetpack Compose integration for KSVG.",
)
configureKsvgRepositories()
configureKsvgSigning()

dokka {
    moduleName.set("KSVG Compose")
}

tasks.register<Jar>("javadocJar") {
    description = "Packages Dokka Javadoc output for publication."
    dependsOn("dokkaGeneratePublicationJavadoc")
    archiveClassifier.set("javadoc")
    from(tasks.named("dokkaGeneratePublicationJavadoc"))
}
