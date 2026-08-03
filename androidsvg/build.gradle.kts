plugins {
    id("com.android.library")
}

kotlin {
    explicitApi()
}

android.apply {
    namespace = "hu.oandras.androidsvg"
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
}

tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.add("-Xlint:deprecation")
}

dependencies.apply {
    implementation("androidx.annotation:annotation:1.10.0")
    implementation("androidx.lifecycle:lifecycle-common:2.11.0")
    implementation("com.google.guava:guava:33.6.0-android")
    implementation("androidx.collection:collection:1.6.0")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")

    androidTestImplementation("androidx.test:runner:1.7.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.16.1")

    androidTestImplementation("androidx.test.ext:junit:1.3.0")
}
