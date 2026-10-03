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

import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import hu.oandras.ksvg.SVG
import java.util.concurrent.Executors

/**
 * Baseline-profile helper: renders every bundled example SVG offscreen on a
 * worker thread so the generator journey executes the whole library
 * (parse → buildScene → renderDocument, incl. filters and text).
 *
 * Not in the launcher; started by explicit intent from the baselineprofile
 * generator (or manually via adb). Shows `compiling... i/N` progress and
 * `DONE` when finished. One broken file never aborts the run.
 */
class RenderAllActivity : AppCompatActivity() {

    private lateinit var status: TextView
    private val worker = Executors.newSingleThreadExecutor()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        status = TextView(this).apply {
            gravity = Gravity.CENTER
            textSize = 20f
            text = "starting..."
        }
        setContentView(FrameLayout(this).apply { addView(status) })
        worker.execute(::renderAll)
    }

    override fun onDestroy() {
        worker.shutdownNow()
        super.onDestroy()
    }

    private fun renderAll() {
        val files = Category.entries.flatMap { category ->
            assets.list(category.assetPath).orEmpty()
                .filter { it.endsWith(".svg") }
                .map { "${category.assetPath}/$it" }
        }
        var ok = 0
        files.forEachIndexed { index, path ->
            try {
                val svg = SVG.getFromAsset(assets, path, parseAnimations = true)
                val bitmap = Bitmap.createBitmap(RENDER_PX, RENDER_PX, Bitmap.Config.ARGB_8888)
                try {
                    svg.renderToCanvas(Canvas(bitmap))
                } finally {
                    bitmap.recycle()
                }
                ok++
            } catch (e: Exception) {
                Log.w(TAG, "render failed: $path", e)
            }
            val done = index + 1
            runOnUiThread { status.text = "compiling... $done/${files.size}" }
        }
        runOnUiThread { status.text = "DONE ($ok/${files.size})" }
    }

    companion object {
        private const val TAG = "RenderAll"
        private const val RENDER_PX = 512
    }
}
