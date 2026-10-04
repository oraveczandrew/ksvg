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
import android.view.Choreographer
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import hu.oandras.ksvg.KSVGAnimatedDrawable
import hu.oandras.ksvg.SVG
import kotlin.math.roundToLong

// Simple debug activity: renders a single SVG asset from intent extras.
// Launch: adb shell am start -n hu.oandras.ksvg.showcase/.SvgTestActivity \
//   --es svg_asset "blend_mode.svg"
// Extras:
//   svg_asset (String): asset path of the SVG to render.
//   svg_software_rendering (boolean): force software rendering for comparison
//     with the default hardware path
//     (--ez svg_software_rendering "true").
//   svg_overlay (boolean): show a frame counter overlay (elapsed seconds and
//     Choreographer frame count) for animation debugging
//     (--ez svg_overlay "true").
class SvgTestActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        applyLightSystemBars()

        val binding = svgTestActivityLayout()
        if (intent.getBooleanExtra(EXTRA_SVG_SOFTWARE_RENDERING, false)) {
            binding.imageView.setLayerType(View.LAYER_TYPE_SOFTWARE, null)
        }

        val assetPath = intent.getStringExtra(EXTRA_SVG_ASSET) ?: return
        val svg = SVG.getFromAsset(assets, assetPath, parseAnimations = true)
        animatedDrawable = svg.toAnimatedDrawable()
        binding.imageView.setImageDrawable(animatedDrawable)

        setContentView(binding.root)
        if (intent.getBooleanExtra(EXTRA_SVG_OVERLAY, false)) {
            binding.overlay.visibility = View.VISIBLE
            startOverlay(binding.overlay)
        }
    }

    private var overlayCallback: Choreographer.FrameCallback? = null
    private var animatedDrawable: KSVGAnimatedDrawable? = null

    override fun onStart() {
        super.onStart()
        animatedDrawable?.start()
    }

    override fun onStop() {
        animatedDrawable?.stop()
        super.onStop()
    }

    private fun startOverlay(overlay: TextView) {
        val startNanos = System.nanoTime()
        var frames = 0L
        val callback = object : Choreographer.FrameCallback {
            private val stringBuilder = StringBuilder(16)

            override fun doFrame(frameTimeNanos: Long) {
                frames++
                if (frames % 5 == 0L) {
                    val elapsed = (frameTimeNanos - startNanos) / 1_000_000_000.0
                    overlay.text = formatFrameOverlay(stringBuilder, elapsed, frames)
                }
                Choreographer.getInstance().postFrameCallback(this)
            }
        }
        overlayCallback = callback
        Choreographer.getInstance().postFrameCallback(callback)
    }

    override fun onDestroy() {
        overlayCallback?.let { Choreographer.getInstance().removeFrameCallback(it) }
        overlayCallback = null
        super.onDestroy()
    }

    companion object {
        const val EXTRA_SVG_ASSET: String = "svg_asset"
        const val EXTRA_SVG_SOFTWARE_RENDERING: String = "svg_software_rendering"
        const val EXTRA_SVG_OVERLAY: String = "svg_overlay"
    }
}

/**
 * Shared frame-counter line for animation debug overlays: elapsed seconds
 * with two decimals and the Choreographer frame count. Hand-rolled instead
 * of `String.format` (which allocates a `Formatter`, parses the pattern and
 * boxes the args on every call: `new Formatter(l).format(...)`). The decimal
 * separator is a literal dot, so output is stable across device locales
 * (a Hungarian-locale format would print `t=2,70s`).
 */
internal fun formatFrameOverlay(builder: StringBuilder, elapsedSeconds: Double, frames: Long): String {
    val hundredths = (elapsedSeconds * 100.0).roundToLong()
    builder.clear()
    return builder
        .append("t=")
        .append(hundredths / 100)
        .append('.')
        .append((hundredths % 100).toString().padStart(2, '0'))
        .append("s f=")
        .append(frames)
        .toString()
}
