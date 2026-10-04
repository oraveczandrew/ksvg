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

import android.content.Context
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

internal class SvgTestActivityBinding(
    @JvmField
    val root: FrameLayout,
    @JvmField
    val imageView: ImageView,
    @JvmField
    val overlay: TextView
)

internal fun Context.svgTestActivityLayout(): SvgTestActivityBinding {
    val imageView = ImageView(this).apply {
        scaleType = ImageView.ScaleType.FIT_CENTER
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
    }
    // Frame counter overlay for animation debugging (elapsed seconds and
    // Choreographer frame count). Pinned to the bottom, above the navigation
    // bar; hidden until the activity enables it via the svg_overlay extra.
    val overlay = TextView(this).apply {
        textSize = 20f
        setBackgroundColor(0xAA000000.toInt())
        setTextColor(0xFFFFFFFF.toInt())
        setPadding(16, 16, 16, 16)
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.BOTTOM or Gravity.START
        )
        visibility = View.GONE
    }
    val root = FrameLayout(this).apply {
        addView(imageView)
        addView(overlay)
        ViewCompat.setOnApplyWindowInsetsListener(this) { _, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            val cutout = insets.getInsets(WindowInsetsCompat.Type.displayCutout())
            (overlay.layoutParams as FrameLayout.LayoutParams).apply {
                leftMargin = maxOf(systemBars.left, cutout.left)
                rightMargin = maxOf(systemBars.right, cutout.right)
                bottomMargin = maxOf(systemBars.bottom, cutout.bottom)
            }
            overlay.requestLayout()
            insets
        }
    }
    return SvgTestActivityBinding(root, imageView, overlay)
}
