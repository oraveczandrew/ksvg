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
import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView

internal class LargeMapViewerBinding(
    @JvmField
    val root: View,
    @JvmField
    val zoomView: ZoomableSvgView,
    @JvmField
    val statusView: TextView,
    @JvmField
    val progress: ProgressBar,
    @JvmField
    val loadButton: Button
)

internal fun Context.largeMapViewerLayout(): LargeMapViewerBinding {
    val zoomView = ZoomableSvgView(this).apply {
        id = R.id.mapZoomView
        setBackgroundColor(Color.WHITE)
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
    }
    val statusView = TextView(this).apply {
        id = R.id.mapStatus
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER_HORIZONTAL
            bottomMargin = dpInPixels(this@largeMapViewerLayout, 16f)
        }
        gravity = Gravity.CENTER
        setTextColor(Color.DKGRAY)
        textSize = 14f
        text = "Tap Load to fetch the map"
    }
    val progress = ProgressBar(this).apply {
        id = R.id.mapProgress
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER_HORIZONTAL
            bottomMargin = dpInPixels(this@largeMapViewerLayout, 16f)
        }
        isIndeterminate = true
        visibility = View.GONE
    }
    val loadButton = Button(this).apply {
        id = R.id.mapLoadButton
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER_HORIZONTAL
        }
        text = "Load map"
    }
    // Spinner on top, status text under it, button last — one centered block.
    val overlay = LinearLayout(this).apply {
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.CENTER
        )
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER
        addView(progress)
        addView(statusView)
        addView(loadButton)
    }
    val root = FrameLayout(this).apply {
        layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        addView(zoomView)
        addView(overlay)
    }
    return LargeMapViewerBinding(root, zoomView, statusView, progress, loadButton)
}
