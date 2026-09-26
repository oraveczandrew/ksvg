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

import android.content.Intent
import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.google.android.material.bottomnavigation.BottomNavigationView
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {

    private val viewModel: IconsViewModel by viewModels()

    private lateinit var recyclerView: RecyclerView
    private lateinit var bottomNavigation: BottomNavigationView
    private lateinit var adapter: SvgAdapter

    /** Filename to scroll to once the requested list arrives; consumed on first match/miss. */
    private var pendingScrollTo: String? = null
    /** Category whose list the pending scroll target belongs to; guards against stale emissions. */
    private var pendingScrollCategory: Category? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        WindowCompat.setDecorFitsSystemWindows(window, false)
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.isAppearanceLightNavigationBars = true

        val binding = mainActivityLayout()
        setContentView(binding.root)
        recyclerView = binding.recyclerView
        bottomNavigation = binding.bottomNavigation

        val adapter = SvgAdapter(Glide.with(this))
        this.adapter = adapter
        // Our programmatic scroll must win over RecyclerView's saved-state restore (position 0).
        adapter.stateRestorationPolicy =
            RecyclerView.Adapter.StateRestorationPolicy.PREVENT
        binding.recyclerView.adapter = adapter

        binding.bottomNavigation.setOnItemSelectedListener { item ->
            when (item.itemId) {
                R.id.menu_meteocons -> {
                    viewModel.currentCategory.value = Category.METEOCONS
                    true
                }
                R.id.menu_verification -> {
                    viewModel.currentCategory.value = Category.VISUAL
                    true
                }
                else -> false
            }
        }

        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.icons.collect { icons ->
                    adapter.submitList(icons) {
                        consumePendingScroll()
                    }
                }
            }
        }

        handleDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleDeepLink(intent)
    }

    /**
     * Debug/development deep link for screenshot sessions:
     * `adb shell am start -n hu.oandras.ksvg.showcase/.MainActivity
     * --es category verification --es scroll_to blend_mode.svg`
     * Category is one of `meteocons` or `verification` (aka `visual`);
     * scroll_to matches SvgEntry.displayName exactly, falling back to the
     * first substring match. Unknown values are ignored.
     */
    private fun handleDeepLink(intent: Intent) {
        val requestedCategory = when (intent.getStringExtra(EXTRA_CATEGORY)?.lowercase()) {
            "meteocons" -> Category.METEOCONS
            "verification", "visual" -> Category.VISUAL
            else -> null
        }
        if (requestedCategory != null) {
            val menuId = if (requestedCategory == Category.METEOCONS) R.id.menu_meteocons
                else R.id.menu_verification
            bindingSelectedCategory(requestedCategory, menuId)
        }
        pendingScrollTo = intent.getStringExtra(EXTRA_SCROLL_TO)
            ?.takeIf { it.isNotBlank() }
        // Pin the target to the currently selected category so an in-flight
        // emission of the previous category cannot consume it (that early
        // scroll is what visibly jumped back to the top on the next submitList).
        pendingScrollCategory = pendingScrollTo?.let {
            requestedCategory ?: viewModel.currentCategory.value
        }
        // Never scroll synchronously here: the next icons emission replaces
        // the list and would reset the position. consumePendingScroll runs
        // in the submitList commit callback and posts the scroll.
        // Make the intent one-shot so rotation/re-delivery cannot re-scroll.
        intent.removeExtra(EXTRA_SCROLL_TO)
        intent.removeExtra(EXTRA_CATEGORY)
    }

    private fun bindingSelectedCategory(category: Category, menuId: Int) {
        viewModel.currentCategory.value = category
        bottomNavigation.selectedItemId = menuId
    }

    private fun consumePendingScroll() {
        val target = pendingScrollTo ?: return
        // Only act once the visible list belongs to the requested category.
        // A stale emission (previous category, or initial empty list) must not
        // consume the request.
        if (viewModel.currentCategory.value != pendingScrollCategory) return
        val icons = adapter.currentList
        if (icons.isEmpty()) return
        val index = icons.indexOfFirst { it.displayName == target }
            .takeIf { it >= 0 }
            ?: icons.indexOfFirst { it.displayName.contains(target) }
        // Unknown name: nothing left to wait for, drop the request.
        pendingScrollTo = null
        pendingScrollCategory = null
        if (index < 0) return
        // Post to the next layout pass: scrollToPosition before layout is
        // what let the following layout jump back to the top.
        recyclerView.post {
            recyclerView.scrollToPosition(index)
        }
    }

    companion object {
        const val EXTRA_CATEGORY: String = "category"
        const val EXTRA_SCROLL_TO: String = "scroll_to"
    }
}
