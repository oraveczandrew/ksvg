// Handles the upload to Sonatype.

import org.gradle.api.publish.PublishingExtension
import org.gradle.api.publish.maven.MavenPublication
import org.gradle.plugins.signing.SigningExtension

apply(plugin = "maven-publish")
apply(plugin = "signing")

val libraryVersion = "1.5-SNAPSHOT"
// val libraryVersion = "1.3-SNAPSHOT"

val libraryName = "AndroidSVG"
val libraryDescription = "SVG rendering library for Android."

val artifactIdAAR = "androidsvg"
val artifactIdJAR = "androidsvg-jar"
val libraryGroup = "com.caverock"

val developerId = "BigBadaboom"
val developerName = "Paul LeBeau"
val developerEmail = "androidsvgfeedback@gmail.com"

val siteUrl = "https://github.com/BigBadaboom/androidsvg"
val gitUrl = "https://github.com/BigBadaboom/androidsvg.git"

val licenseName = "The Apache Software License, Version 2.0"
val licenseUrl = "http://www.apache.org/licenses/LICENSE-2.0.txt"

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

            artifact(layout.buildDirectory.file("outputs/aar/androidsvg-release.aar")) {
                builtBy(tasks.named("assembleRelease"))
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

val android = extensions.getByName("android") as com.android.build.gradle.BaseExtension

tasks.register<Jar>("sourcesJar") {
    from(android.sourceSets.getByName("main").java.srcDirs)
    archiveClassifier.set("sources")
}

tasks.register<Javadoc>("javadoc") {
    source = android.sourceSets.getByName("main").java.getSourceFiles()
    destinationDir = file("${rootProject.projectDir}/doc/")
    classpath += project.files(android.bootClasspath.join(File.pathSeparator))
    val options = options as StandardJavadocDocletOptions
    options.links("http://docs.oracle.com/javase/7/docs/api/")
    options.linksOffline("http://d.android.com/reference", "${android.sdkDirectory}/docs/reference")
    // Replacement stylesheet for javadocs
    options.stylesheetFile = file("javadoc-stylesheet.css")
}

tasks.register<Jar>("javadocJar") {
    dependsOn("javadoc")
    archiveClassifier.set("javadoc")
    from(tasks.named<Javadoc>("javadoc").map { it.destinationDir!! })
}

tasks.register<Jar>("libraryJar") {
    dependsOn("compileReleaseJavaWithJavac")
    val compileReleaseJavaWithJavac = tasks.named<JavaCompile>("compileReleaseJavaWithJavac")
    from(compileReleaseJavaWithJavac.map { it.destinationDir })

    // Add all dependencies except for android.jar to the fat jar
    from(configurations.findByName("compile")?.filter {
        it.name != "android.jar" && !it.name.startsWith("junit")
    }?.map { if (it.isDirectory) it else zipTree(it) } ?: emptyList<File>())

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
