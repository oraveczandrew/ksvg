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
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

internal class SvgItemBinding(
    @JvmField
    val root: View,
    @JvmField
    val imageView: ImageView,
    @JvmField
    val textView: TextView
)

internal fun Context.svgItemLayout(): SvgItemBinding {
    val context = this
    val dp8 = dpInPixels(context, 8f)
    val dp100 = dpInPixels(context, 100f)

    val imageView = ImageView(context).apply {
        id = R.id.imageView
        layoutParams = LinearLayout.LayoutParams(dp100, dp100).apply {
            gravity = Gravity.CENTER_HORIZONTAL
        }
        scaleType = ImageView.ScaleType.FIT_CENTER
    }

    val textView = TextView(context).apply {
        id = R.id.textView
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        )
        gravity = Gravity.CENTER
        textSize = 12f
    }

    val root = LinearLayout(context).apply {
        layoutParams = RecyclerView.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        )
        orientation = LinearLayout.VERTICAL
        setPadding(dp8, dp8, dp8, dp8)
        addView(imageView)
        addView(textView)
    }

    return SvgItemBinding(root, imageView, textView)
}
