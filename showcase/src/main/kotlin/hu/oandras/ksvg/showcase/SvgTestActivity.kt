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
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity
import hu.oandras.ksvg.SVG

// Simple debug activity: renders a single SVG asset from intent extras.
// Launch: adb shell am start -n hu.oandras.ksvg.showcase/.SvgTestActivity \
//   --es svg_asset "blend_mode.svg"
// Extras:
//   svg_asset (String): asset path of the SVG to render.
//   svg_software_rendering (boolean): force software rendering for comparison
//     with the default hardware path
//     (--ez svg_software_rendering "true").
class SvgTestActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        applyLightSystemBars()

        val imageView = ImageView(this).apply {
            scaleType = ImageView.ScaleType.FIT_CENTER
        }
        if (intent.getBooleanExtra(EXTRA_SVG_SOFTWARE_RENDERING, false)) {
            imageView.setLayerType(View.LAYER_TYPE_SOFTWARE, null)
        }
        setContentView(imageView)

        val assetPath = intent.getStringExtra(EXTRA_SVG_ASSET) ?: return
        val svg = SVG.getFromAsset(assets, assetPath, parseAnimations = true)
        imageView.setImageDrawable(svg.toAnimatedDrawable())
    }

    companion object {
        const val EXTRA_SVG_ASSET: String = "svg_asset"
        const val EXTRA_SVG_SOFTWARE_RENDERING: String = "svg_software_rendering"
    }
}
