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
import android.widget.Button
import android.widget.LinearLayout

internal class HomeActivityBinding(
    @JvmField
    val root: View,
    @JvmField
    val classicButton: Button,
    @JvmField
    val composeButton: Button
)

internal fun Context.homeLayout(): HomeActivityBinding {
    val dp16 = dpInPixels(this, 16f)
    val classicButton = Button(this).apply {
        id = R.id.homeButtonClassic
        text = "Views"
    }
    val composeButton = Button(this).apply {
        id = R.id.homeButtonCompose
        text = "Compose"
    }
    val root = LinearLayout(this).apply {
        layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER
        setPadding(dp16, dp16, dp16, dp16)
        addView(
            classicButton,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dp16 }
        )
        addView(
            composeButton,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        )
    }
    return HomeActivityBinding(root, classicButton, composeButton)
}
