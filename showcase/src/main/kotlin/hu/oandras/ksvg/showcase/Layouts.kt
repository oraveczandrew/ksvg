/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
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
import android.graphics.drawable.Drawable
import android.util.TypedValue
import android.view.Gravity
import android.view.Menu
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.bottomnavigation.BottomNavigationView
import hu.oandras.ksvg.SVG

// Official Material Symbols ("list", "check_circle"), rendered by KSVG itself so the
// legacy gallery uses the same icons as the Compose bottom bar.
private const val MENU_LIST_SVG: String =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" height=\"24\" viewBox=\"0 -960 960 960\" width=\"24\">" +
        "<path d=\"M280-600v-80h560v80H280Zm0 160v-80h560v80H280Zm0 160v-80h560v80H280Z" +
        "M160-600q-17 0-28.5-11.5T120-640q0-17 11.5-28.5T160-680q17 0 28.5 11.5T200-640q0 17-11.5 28.5T160-600Z" +
        "m0 160q-17 0-28.5-11.5T120-480q0-17 11.5-28.5T160-520q17 0 28.5 11.5T200-480q0 17-11.5 28.5T160-440Z" +
        "m0 160q-17 0-28.5-11.5T120-320q0-17 11.5-28.5T160-360q17 0 28.5 11.5T200-320q0 17-11.5 28.5T160-280Z\"/></svg>"

private const val MENU_CHECK_CIRCLE_SVG: String =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" height=\"24\" viewBox=\"0 -960 960 960\" width=\"24\">" +
        "<path d=\"m424-296 282-282-56-56-226 226-114-114-56 56 170 170Zm56 216q-83 0-156-31.5T197-197q-54-54-85.5-127T80-480" +
        "q0-83 31.5-156T197-763q54-54 127-85.5T480-880q83 0 156 31.5T763-763q54 54 85.5 127T880-480q0 83-31.5 156T763-197" +
        "q-54 54-127 85.5T480-80Zm0-80q134 0 227-93t93-227q0-134-93-227t-227-93q-134 0-227 93t-93 227q0 134 93 227t227 93Zm0-320Z\"/></svg>"

internal fun dpInPixels(context: Context, dp: Float): Int {
    return TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        dp,
        context.resources.displayMetrics
    ).toInt()
}

internal fun Context.ksvgMenuIcon(svg: String, fallbackRes: Int): Drawable {
    try {
        return SVG.getFromString(svg).toDrawable()
    } catch (_: Exception) {
        // Fall through to the fallback drawable below.
    }
    return checkNotNull(getDrawable(fallbackRes)) { "Missing fallback drawable resource" }
}

internal class MainActivityBinding(
    @JvmField
    val root: View,
    @JvmField
    val recyclerView: RecyclerView,
    @JvmField
    val bottomNavigation: BottomNavigationView
)

internal fun Context.mainActivityLayout(): MainActivityBinding {
    val recyclerView = RecyclerView(this).apply {
        id = R.id.recyclerView
        layoutParams = ConstraintLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            0
        ).apply {
            topToTop = ConstraintLayout.LayoutParams.PARENT_ID
            bottomToTop = R.id.bottomNavigation
        }
        layoutManager = GridLayoutManager(this@mainActivityLayout, 3)
        clipToPadding = false
    }

    // Material3-themed context so the bar matches the Compose NavigationBar: M3 container
    // color, M3 icon/label tints and the selected-item pill indicator come from the
    // Widget.Material3.BottomNavigationView style instead of the AppCompat app theme.
    val bottomNavigation = BottomNavigationView(
        android.view.ContextThemeWrapper(
            this,
            com.google.android.material.R.style.Theme_Material3_Light_NoActionBar
        )
    ).apply {
        id = R.id.bottomNavigation
        layoutParams = ConstraintLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply {
            bottomToBottom = ConstraintLayout.LayoutParams.PARENT_ID
        }

        menu.add(Menu.NONE, R.id.menu_meteocons, Menu.NONE, "Meteocons").icon =
            ksvgMenuIcon(MENU_LIST_SVG, android.R.drawable.ic_menu_gallery)
        menu.add(Menu.NONE, R.id.menu_verification, Menu.NONE, "Verification").icon =
            ksvgMenuIcon(MENU_CHECK_CIRCLE_SVG, android.R.drawable.ic_menu_manage)
    }

    val root = ConstraintLayout(this).apply {
        layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        addView(recyclerView)
        addView(bottomNavigation)

        val statusBarScrim = View(this@mainActivityLayout).apply {
            id = R.id.statusBarScrim
            setBackgroundColor(Color.WHITE)
            layoutParams = ConstraintLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0
            ).apply {
                topToTop = ConstraintLayout.LayoutParams.PARENT_ID
            }
        }
        addView(statusBarScrim)

        val navigationBarScrim = View(this@mainActivityLayout).apply {
            id = R.id.navigationBarScrim
            setBackgroundColor(Color.WHITE)
            layoutParams = ConstraintLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0
            ).apply {
                bottomToBottom = ConstraintLayout.LayoutParams.PARENT_ID
            }
        }
        addView(navigationBarScrim)

        ViewCompat.setOnApplyWindowInsetsListener(this) { _, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            val statusBars = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            val navBars = insets.getInsets(WindowInsetsCompat.Type.navigationBars())

            statusBarScrim.visibility = if (statusBars.top > 0) View.VISIBLE else View.GONE
            statusBarScrim.layoutParams = (statusBarScrim.layoutParams as ConstraintLayout.LayoutParams).apply {
                height = statusBars.top
            }

            navigationBarScrim.visibility = if (navBars.bottom > 0) View.VISIBLE else View.GONE
            navigationBarScrim.layoutParams = (navigationBarScrim.layoutParams as ConstraintLayout.LayoutParams).apply {
                height = navBars.bottom
            }

            recyclerView.setPadding(
                systemBars.left,
                systemBars.top,
                systemBars.right,
                0
            )

            bottomNavigation.setPadding(0, 0, 0, navBars.bottom)

            insets
        }
    }

    return MainActivityBinding(root, recyclerView, bottomNavigation)
}

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
        text = "Classic (Views)"
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
