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
    alias(libs.plugins.android.application)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.ksp)
}

android {
    namespace = "hu.oandras.ksvg.showcase"
    compileSdk = libs.versions.compileSdk.get().toInt()
    ndkVersion = libs.versions.ndk.get()
    buildToolsVersion = libs.versions.buildTools.get()

    defaultConfig.apply {
        minSdk = libs.versions.minSdk.get().toInt()

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes.apply {
        getByName("release") {
            // Baseline-profile generation runs against the non-minified build
            // (KSVG_NOMINIFY=1): readable rules, remapped by R8 at ship time.
            // Real releases stay minified.
            val noMinify = System.getenv("KSVG_NOMINIFY") == "1"
            isMinifyEnabled = !noMinify
            isShrinkResources = !noMinify
            isProfileable = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Baseline-profile generation installs the release APK on-device;
            // an unsigned APK cannot be installed. Sign with the debug key only
            // for that flow (KSVG_SIGN_DEBUG=1); real releases stay untouched.
            if (System.getenv("KSVG_SIGN_DEBUG") == "1") {
                signingConfig = signingConfigs.getByName("debug")
            }
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

    sourceSets {
        getByName("main") {
            assets.directories.apply {
                add("asset-roots")
            }
        }
    }

    buildFeatures.apply {
        compose = true
    }
}

dependencies {
    implementation(project(":ksvg"))
    implementation(project(":glide"))
    implementation(project(":compose"))

    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.foundation)
    implementation(libs.compose.material3)
    implementation(libs.compose.material.icons.core)
    implementation(libs.activity.compose)

    implementation(libs.appcompat)
    implementation(libs.activity.ktx)
    implementation(libs.material)
    implementation(libs.constraintlayout)
    implementation(libs.recyclerview)
    implementation(libs.lifecycle.viewmodel.ktx)

    implementation(libs.coroutines.android)

    implementation(libs.glide)

    // Baseline-profile installer (backports profile installs below API 33).
    implementation(libs.profileinstaller)
    // Enables ProfileInstallerInitializer discovery via androidx.startup.
    implementation(libs.startup.runtime)

    ksp(libs.glide.ksp)
}
