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

import org.gradle.api.DefaultTask
import org.gradle.api.Project
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.tasks.InputDirectory
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction
import org.gradle.kotlin.dsl.register
import java.io.File
import java.net.HttpURLConnection
import java.util.*

private const val UPLOAD_URL = "https://central.sonatype.com/api/v1/publisher/upload"
private const val STATUS_URL = "https://central.sonatype.com/api/v1/publisher/status"

/**
 * Credentials for the Central Publisher Portal user token. Environment wins
 * over the Gradle property; the values are never logged or written anywhere
 * by this task (only sent as an HTTP Basic header over TLS).
 */
internal fun Project.centralUsername(): String =
    providers.environmentVariable("CENTRAL_USERNAME")
        .orElse(providers.gradleProperty("centralUsername"))
        .getOrElse("")
        .also { require(it.isNotBlank()) { centralCredentialHelp("centralUsername") } }

internal fun Project.centralPassword(): String =
    providers.environmentVariable("CENTRAL_PASSWORD")
        .orElse(providers.gradleProperty("centralPassword"))
        .getOrElse("")
        .also { require(it.isNotBlank()) { centralCredentialHelp("centralPassword") } }

private fun centralCredentialHelp(name: String): String =
    "Missing Central credential '$name': pass -P$name=... on the command line, " +
        "set $name in ~/.gradle/gradle.properties (never in the repo), or export " +
        "CENTRAL_${if (name == "centralUsername") "USERNAME" else "PASSWORD"}."

/**
 * Zips the `centralStaging` repo (minus inter-module-only test-fixtures) and
 * uploads it as a Central Publisher Portal deployment bundle, then polls the
 * deployment status until it leaves the validating/uploading states.
 *
 * Run after the module publishes, e.g.:
 * `./gradlew :ksvg:publishReleasePublicationToCentralStagingRepository ... uploadCentralBundle`
 */
public fun Project.registerCentralUpload(): Unit {
    tasks.register<UploadCentralBundle>("uploadCentralBundle") {
        group = "publishing"
        description = "Uploads the centralStaging bundle to the Maven Central Publisher Portal."
        // The portal token is read at execution time (never cached): opting
        // out keeps it out of the configuration-cache files by construction.
        notCompatibleWithConfigurationCache(
            "Reads Central portal credentials at execution time; " +
                "they must never be written to the configuration cache."
        )
        bundleFile.set(layout.buildDirectory.file("central-bundle.zip"))
        stagingDir.set(layout.buildDirectory.dir("central-staging"))
        // The staging repo only exists after the module publishes; depend on
        // them so a single invocation works end to end.
        dependsOn(
            ":ksvg:publishReleasePublicationToCentralStagingRepository",
            ":filtering:publishReleasePublicationToCentralStagingRepository",
            ":glide:publishReleasePublicationToCentralStagingRepository",
            ":compose:publishReleasePublicationToCentralStagingRepository"
        )
        outputs.upToDateWhen { false }
    }
}

public abstract class UploadCentralBundle : DefaultTask() {
    @get:OutputFile
    public abstract val bundleFile: RegularFileProperty

    @get:InputDirectory
    @get:PathSensitive(PathSensitivity.RELATIVE)
    public abstract val stagingDir: DirectoryProperty

    @TaskAction
    public fun upload() {
        val staging = stagingDir.get().asFile
        require(staging.isDirectory) {
            "Staging repo not found at ${staging.path}: run the " +
                "publishReleasePublicationToCentralStagingRepository tasks first."
        }
        // Inter-module-only artifact: AGP attaches it to the publication (so it
        // cannot be dropped there without breaking module metadata), but it
        // must not ship to Central.
        staging.walkTopDown()
            .filter { it.isFile && it.name.endsWith("-test-fixtures.aar") }
            .forEach { it.delete() }
        staging.walkTopDown()
            .filter { it.isFile && it.name.endsWith("-test-fixtures.aar.asc") }
            .forEach { it.delete() }

        val bundle = bundleFile.get().asFile
        zipReproducible(staging, bundle)
        logger.lifecycle("Central bundle: ${bundle.path} (${bundle.length()} bytes)")

        val deploymentId = postBundle(bundle)
        logger.lifecycle("Central deployment id: $deploymentId")
        pollStatus(deploymentId)
    }

    private fun zipReproducible(root: File, out: File) {
        // Reproducible layout Central accepts: plain `zip -qr -X bundle hu`.
        val files = root.walkTopDown().filter { it.isFile }.sortedBy { it.relativeTo(root).path }
        java.util.zip.ZipOutputStream(out.outputStream().buffered()).use { zip ->
            for (file in files) {
                val entry = java.util.zip.ZipEntry(file.relativeTo(root).path.replace(File.separatorChar, '/'))
                entry.time = 0L
                zip.putNextEntry(entry)
                file.inputStream().buffered().use { it.copyTo(zip) }
                zip.closeEntry()
            }
        }
    }

    private fun basicAuth(): String {
        val user = project.centralUsername()
        val pass = project.centralPassword()
        return "Basic " + Base64.getEncoder().encodeToString("$user:$pass".toByteArray())
    }

    private fun postBundle(bundle: File): String {
        val boundary = "----ksvg${UUID.randomUUID().toString().replace("-", "")}"
        val connection = java.net.URI(UPLOAD_URL).toURL().openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.connectTimeout = 30_000
            connection.readTimeout = 300_000
            connection.setRequestProperty("Authorization", basicAuth())
            connection.setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")
            connection.outputStream.bufferedWriter(Charsets.UTF_8).use { writer ->
                writer.write("--$boundary\r\n")
                writer.write("Content-Disposition: form-data; name=\"bundle\"; filename=\"${bundle.name}\"\r\n")
                writer.write("Content-Type: application/octet-stream\r\n\r\n")
                writer.flush()
                bundle.inputStream().buffered().use { it.copyTo(connection.outputStream) }
                connection.outputStream.flush()
                writer.write("\r\n--$boundary--\r\n")
            }
            val code = connection.responseCode
            val body = (if (code in 200..299) connection.inputStream else connection.errorStream)
                ?.bufferedReader()?.readText().orEmpty()
            if (code !in 200..299) {
                throw IllegalStateException("Central upload failed (HTTP $code): $body")
            }
            return body.trim()
        } finally {
            connection.disconnect()
        }
    }

    private fun pollStatus(deploymentId: String) {
        repeat(60) {
            Thread.sleep(30_000)
            val connection = java.net.URI("$STATUS_URL?id=$deploymentId").toURL().openConnection() as HttpURLConnection
            try {
                connection.connectTimeout = 30_000
                connection.readTimeout = 60_000
                connection.setRequestProperty("Authorization", basicAuth())
                val code = connection.responseCode
                val body = (if (code in 200..299) connection.inputStream else connection.errorStream)
                    ?.bufferedReader()?.readText().orEmpty()
                // The status payload carries a deploymentState field; match it
                // textually to stay independent of its JSON shape.
                val state = Regex("\"deploymentState\"\\s*:\\s*\"([A-Z_]+)\"").find(body)?.groupValues?.get(1)
                    ?: "HTTP_$code"
                logger.lifecycle("Central deployment $deploymentId: $state")
                if (state == "PUBLISHED" || state == "PUBLISHING") return
                if (state == "FAILED" || state == "ERROR") {
                    throw IllegalStateException("Central deployment $deploymentId failed: $body")
                }
            } finally {
                connection.disconnect()
            }
        }
        logger.warn("Central deployment $deploymentId did not finish within 30 minutes; check the portal.")
    }
}
