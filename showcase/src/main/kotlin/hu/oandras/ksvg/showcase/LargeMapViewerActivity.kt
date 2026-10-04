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

package hu.oandras.ksvg.showcase

import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import hu.oandras.ksvg.SVG
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

// Full-screen pinch-zoom viewer for one large remote SVG.
//
// STRESS TEST: a 20k-element map like this cannot be presented at a normal
// frame rate; this screen exists to measure load/render behavior, not to
// demo smooth scrolling.
class LargeMapViewerActivity : AppCompatActivity() {

    private lateinit var zoomView: ZoomableSvgView
    private lateinit var statusView: TextView
    private lateinit var progress: ProgressBar
    private lateinit var loadButton: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyLightSystemBars()

        val binding = largeMapViewerLayout()
        setContentView(binding.root)
        zoomView = binding.zoomView
        statusView = binding.statusView
        progress = binding.progress
        loadButton = binding.loadButton
        loadButton.setOnClickListener {
            loadButton.visibility = View.GONE
            loadSvg(DEFAULT_MAP_URL)
        }
    }

    private fun loadSvg(url: String) {
        statusView.text = "Loading…"
        progress.visibility = View.VISIBLE
        lifecycleScope.launch {
            try {
                // Everything heavy (network, disk, parse, drawable build) stays
                // off the main thread; only setSvgDrawable touches the view.
                // Vector drawable: stays sharp at any pinch zoom level.
                val drawable = withContext(Dispatchers.IO) { loadCachedDrawable(url) }
                zoomView.setSvgDrawable(drawable)
                statusView.text = ""
            } catch (e: Exception) {
                statusView.text = "Failed to load map:\n${e.message}"
                loadButton.text = "Retry"
                loadButton.visibility = View.VISIBLE
            } finally {
                progress.visibility = View.GONE
            }
        }
    }

    @JvmSynthetic
    internal fun loadCachedDrawable(url: String): android.graphics.drawable.Drawable {
        return loadCachedSvg(url).toDrawable()
    }

    private fun loadCachedSvg(url: String): SVG {
        val cached = cacheFileFor(url)
        if (cached.isFile && cached.length() > 0L) {
            try {
                cached.inputStream().use { stream ->
                    return SVG.getFromInputStream(stream)
                }
            } catch (_: Exception) {
                // Corrupt cache entry: drop it and fall through to re-download.
                cached.delete()
            }
        }
        downloadToCache(url, cached)
        cached.inputStream().use { stream ->
            return SVG.getFromInputStream(stream)
        }
    }

    private fun downloadToCache(url: String, target: File) {
        val parent = target.parentFile
            ?: throw IOException("No parent dir for cache file ${target.absolutePath}")
        parent.mkdirs()
        val tmp = File(parent, "${target.name}.tmp")
        val connection = URL(url).openConnection() as HttpURLConnection
        try {
            connection.connectTimeout = 15_000
            connection.readTimeout = 30_000
            connection.setRequestProperty("User-Agent", "KSVG-Showcase/1.0")
            connection.connect()
            check(connection.responseCode in 200..299) { "HTTP ${connection.responseCode}" }
            connection.inputStream.use { input ->
                tmp.outputStream().use { output ->
                    val buf = ByteArray(32 * 1024)
                    var total = 0L
                    while (true) {
                        val n = input.read(buf)
                        if (n < 0) break
                        total += n
                        check(total <= MAX_DOWNLOAD_BYTES) { "Download exceeds 64 MB" }
                        output.write(buf, 0, n)
                    }
                }
            }
            check(tmp.length() > 0L) { "Empty download" }
            check(tmp.renameTo(target)) { "Failed to commit cache file" }
        } finally {
            tmp.delete()
            connection.disconnect()
        }
    }

    private fun cacheFileFor(url: String): File {
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(url.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
        return File(File(cacheDir, "large_svg"), "$hash.svg")
    }

    companion object {
        const val DEFAULT_MAP_URL: String =
            "https://upload.wikimedia.org/wikipedia/commons/1/1e/Hungary-geographic_map-en.svg"

        // Fixed-map hardening (no external input reaches the loader anymore):
        // cap the download so a changed upstream file can't OOM the parse.
        private const val MAX_DOWNLOAD_BYTES: Long = 64L * 1024L * 1024L
    }
}
