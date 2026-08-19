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
import android.content.res.ColorStateList
import android.graphics.Color
import android.util.TypedValue
import android.view.Gravity
import android.view.Menu
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.bottomnavigation.BottomNavigationView

internal fun dpInPixels(context: Context, dp: Float): Int {
    return TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        dp,
        context.resources.displayMetrics
    ).toInt()
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

    val bottomNavigation = BottomNavigationView(this).apply {
        id = R.id.bottomNavigation
        layoutParams = ConstraintLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply {
            bottomToBottom = ConstraintLayout.LayoutParams.PARENT_ID
        }

        setBackgroundColor(Color.WHITE)
        val states = arrayOf(
            intArrayOf(android.R.attr.state_selected),
            intArrayOf(-android.R.attr.state_selected)
        )
        val colors = intArrayOf(
            0xFF007AFF.toInt(), // iOS Blue style
            Color.GRAY
        )
        val colorStateList = ColorStateList(states, colors)
        itemIconTintList = colorStateList
        itemTextColor = colorStateList

        menu.add(Menu.NONE, R.id.menu_meteocons, Menu.NONE, "Meteocons").setIcon(android.R.drawable.ic_menu_gallery)
        menu.add(Menu.NONE, R.id.menu_verification, Menu.NONE, "Verification").setIcon(android.R.drawable.ic_menu_manage)
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
