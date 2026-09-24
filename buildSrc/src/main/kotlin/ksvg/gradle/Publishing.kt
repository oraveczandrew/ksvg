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

package ksvg.gradle

import org.gradle.api.Project
import org.gradle.api.publish.PublishingExtension
import org.gradle.api.publish.maven.MavenPublication
import org.gradle.kotlin.dsl.configure
import org.gradle.kotlin.dsl.getByName
import org.gradle.kotlin.dsl.getByType
import org.gradle.kotlin.dsl.register
import org.gradle.plugins.signing.SigningExtension

private const val SITE_URL = "https://github.com/oraveczandrew/ksvg"
private const val GIT_URL = "https://github.com/oraveczandrew/ksvg.git"
private const val GITHUB_OWNER = "oraveczandrew"
private const val GITHUB_REPO = "ksvg"

/** Published group, single source of truth in root gradle.properties (`ksvg.group`). */
public fun Project.ksvgGroup(): String =
    findStringProperty("ksvg.group") ?: error("Missing 'ksvg.group' in gradle.properties")

/** Published version, single source of truth in root gradle.properties (`ksvg.version`). */
public fun Project.ksvgVersion(): String =
    findStringProperty("ksvg.version") ?: error("Missing 'ksvg.version' in gradle.properties")

/**
 * Gradle property with env-var fallback (for CI secrets). Returns null when neither is set,
 * so plain local configuration never fails — only the actual upload task needs them.
 */
public fun Project.ksvgCredential(propertyName: String, vararg envNames: String): String? =
    findStringProperty(propertyName)?.takeIf(String::isNotBlank)
        ?: envNames.firstNotNullOfOrNull { System.getenv(it)?.takeIf(String::isNotBlank) }

/** Shared POM (license/developers/scm) for every published KSVG artifact. */
public fun MavenPublication.ksvgPom(displayName: String, description: String): Unit {
    pom {
        name.set(displayName)
        this.description.set(description)
        url.set(SITE_URL)
        licenses {
            license {
                name.set("The Apache Software License, Version 2.0")
                url.set("https://www.apache.org/licenses/LICENSE-2.0.txt")
                distribution.set("repo")
            }
        }
        developers {
            developer {
                id.set("oraveczandrew")
                name.set("András Oravecz")
                email.set("info@oandras.hu")
            }
        }
        scm {
            connection.set(GIT_URL)
            developerConnection.set(GIT_URL)
            url.set(SITE_URL)
        }
    }
}

/**
 * Registers the `release` MavenPublication on top of the AGP `singleVariant("release")`
 * component (declared in the module's `android { publishing { ... } }` block).
 *
 * Per the AGP docs the component only exists after evaluation, so the publication is
 * registered lazily and `from(...)` runs in a nested afterEvaluate. Sources jar comes
 * from AGP's `withSourcesJar()`; the Dokka javadoc jar is attached here.
 *
 * @param stripPomDependencies `group:artifact` coordinates to drop from the generated
 * POM (Maven can't represent variants, so e.g. test-fixture-only deps would otherwise
 * leak into the main POM as runtime deps; Gradle consumers are unaffected thanks to
 * Gradle Module Metadata).
 */
public fun Project.configureKsvgPublication(
    artifactId: String,
    displayName: String,
    description: String,
    stripPomDependencies: Set<String> = emptySet(),
): Unit {
    extensions.configure<PublishingExtension> {
        publications.register<MavenPublication>("release") {
            groupId = ksvgGroup()
            this.artifactId = artifactId
            version = ksvgVersion()
            ksvgPom(displayName, description)
            if (stripPomDependencies.isNotEmpty()) {
                pom.withXml {
                    val root = asElement()
                    val containers = root.getElementsByTagName("dependencies")
                    for (c in 0 until containers.length) {
                        val container = containers.item(c)
                        val children = container.childNodes
                        for (i in children.length - 1 downTo 0) {
                            val dep = children.item(i)
                            if (dep.nodeName != "dependency") continue
                            var group = ""
                            var artifact = ""
                            val fields = dep.childNodes
                            for (j in 0 until fields.length) {
                                when (fields.item(j).nodeName) {
                                    "groupId" -> group = fields.item(j).textContent.trim()
                                    "artifactId" -> artifact = fields.item(j).textContent.trim()
                                }
                            }
                            if ("$group:$artifact" in stripPomDependencies) {
                                container.removeChild(dep)
                            }
                        }
                    }
                }
            }
            // Deferred: both the AGP component and the module's javadocJar task
            // only exist after evaluation.
            afterEvaluate {
                from(components.getByName("release"))
                artifact(tasks.named("javadocJar"))
            }
        }
    }
}

public fun Project.configureKsvgRepositories(): Unit {
    extensions.configure<PublishingExtension> {
        repositories {
            maven {
                name = "github"
                url = uri("https://maven.pkg.github.com/$GITHUB_OWNER/$GITHUB_REPO")
                credentials {
                    username = ksvgCredential("githubUsername", "GITHUB_ACTOR")
                    password = ksvgCredential("githubPassword", "GITHUB_TOKEN")
                }
            }
            // NOTE: Maven Central has no plain maven repo endpoint — uploads go through
            // the Central Publisher Portal (namespace + portal token, bundle upload).
            // See tmp/RELEASE_CHECKLIST.md; wire it here once publishing starts.
        }
    }
}

/**
 * Signs the publication only for remote uploads. `publishToMavenLocal` stays
 * key-free so local verification never needs GPG configured.
 */
public fun Project.configureKsvgSigning(publicationName: String = "release"): Unit {
    val wantsRemotePublish = gradle.startParameter.taskNames.any { task ->
        task.startsWith("publish") && !task.startsWith("publishToMavenLocal")
    }
    extensions.configure<SigningExtension> {
        isRequired = wantsRemotePublish
    }
    // Deferred: the AGP single-variant publication only exists after evaluation.
    afterEvaluate {
        val signing = extensions.getByType<SigningExtension>()
        val publishing = extensions.getByType<PublishingExtension>()
        signing.sign(publishing.publications.getByName(publicationName))
    }
}
