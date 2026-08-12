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

import org.gradle.api.publish.PublishingExtension
import org.gradle.api.publish.maven.MavenPublication
import org.gradle.plugins.signing.SigningExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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

// PUBLISHING

val libraryVersion = "1.0-SNAPSHOT"

val libraryName = "KSVG"
val libraryDescription = "SVG rendering library for Android."

val artifactIdAAR = "ksvg"
val artifactIdJAR = "ksvg-jar"
val libraryGroup = "hu.oandras"

val developerId = "oraveczandrew"
val developerName = "András Oravecz"
val developerEmail = "info@oandras.hu"

val siteUrl = "https://github.com/oraveczandrew/ksvg"
val gitUrl = "https://github.com/oraveczandrew/ksvg.git"

val licenseName = "The Apache Software License, Version 2.0"
val licenseUrl = "https://www.apache.org/licenses/LICENSE-2.0.txt"

val releaseRepoUrl = "https://oss.sonatype.org/service/local/staging/deploy/maven2/"
val snapshotRepoUrl = "https://oss.sonatype.org/content/repositories/snapshots/"

val sonatypeUsername = project.findProperty("sonatypeUsername") as? String ?: ""
val sonatypePassword = project.findProperty("sonatypePassword") as? String ?: ""

configure<PublishingExtension> {
    repositories {
        maven {
            url = uri(if (libraryVersion.endsWith("SNAPSHOT")) snapshotRepoUrl else releaseRepoUrl)
            credentials {
                username = sonatypeUsername
                password = sonatypePassword
            }
        }
    }

    publications {
        create<MavenPublication>("mavenAAR") {
            artifactId = artifactIdAAR
            groupId = libraryGroup
            version = libraryVersion

            artifact(layout.buildDirectory.file("outputs/aar/ksvg-release.aar")) {
                builtBy(tasks.named("assemble"))
            }

            pom {
                packaging = "aar"
                name.set(libraryName)
                description.set(libraryDescription)
                url.set(siteUrl)

                licenses {
                    license {
                        name.set(licenseName)
                        url.set(licenseUrl)
                        distribution.set("repo")
                    }
                }
                developers {
                    developer {
                        id.set(developerId)
                        name.set(developerName)
                        email.set(developerEmail)
                    }
                }
                scm {
                    connection.set(gitUrl)
                    developerConnection.set(gitUrl)
                    url.set(siteUrl)
                }
            }
        }

        create<MavenPublication>("mavenJAR") {
            artifactId = artifactIdJAR
            groupId = libraryGroup
            version = libraryVersion

            pom {
                packaging = "jar"
                name.set(libraryName)
                description.set(libraryDescription)
                url.set(siteUrl)

                licenses {
                    license {
                        name.set(licenseName)
                        url.set(licenseUrl)
                        distribution.set("repo")
                    }
                }
                developers {
                    developer {
                        id.set(developerId)
                        name.set(developerName)
                        email.set(developerEmail)
                    }
                }
                scm {
                    connection.set(gitUrl)
                    developerConnection.set(gitUrl)
                    url.set(siteUrl)
                }
            }
        }
    }
}

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

tasks.register<Jar>("sourcesJar") {
    description = ""
    from("src/main/java")
    from("src/main/kotlin")
    archiveClassifier.set("sources")
}

tasks.register<Jar>("javadocJar") {
    description = ""
    dependsOn("dokkaGeneratePublicationJavadoc")
    archiveClassifier.set("javadoc")
    from(tasks.named("dokkaGeneratePublicationJavadoc"))
}

tasks.register<Jar>("libraryJar") {
    description = ""

    dependsOn("compileReleaseKotlin")

    duplicatesStrategy = DuplicatesStrategy.EXCLUDE

    exclude("META-INF/*.SF")
    exclude("META-INF/*.DSA")
    exclude("META-INF/*.RSA")

    from(tasks.named<KotlinCompile>("compileReleaseKotlin").map { it.destinationDirectory })

    // Java classes, ha vannak Java source-ok is
    dependsOn("compileReleaseJavaWithJavac")
    from(tasks.named<JavaCompile>("compileReleaseJavaWithJavac").map { it.destinationDirectory })

    // Add all dependencies except android.jar and JUnit
    from(
        configurations.findByName("releaseRuntimeClasspath")
        !!.filter {
                it.name != "android.jar" &&
                        !it.name.startsWith("junit")
            }
            .map { if (it.isDirectory) it else zipTree(it) }
    )

    archiveFileName.set("${artifactIdJAR}-${libraryVersion}.jar")
}

configure<SigningExtension> {
    val publishing = extensions.getByType<PublishingExtension>()
    sign(publishing.publications["mavenAAR"])
    sign(publishing.publications["mavenJAR"])
}

afterEvaluate {
    val publishing = extensions.getByType<PublishingExtension>()
    publishing.publications.getByName<MavenPublication>("mavenAAR").apply {
        artifact(tasks.named("sourcesJar"))
        artifact(tasks.named("javadocJar"))
    }
    publishing.publications.getByName<MavenPublication>("mavenJAR").apply {
        artifact(tasks.named("libraryJar"))
        artifact(tasks.named("sourcesJar"))
        artifact(tasks.named("javadocJar"))
    }
}
