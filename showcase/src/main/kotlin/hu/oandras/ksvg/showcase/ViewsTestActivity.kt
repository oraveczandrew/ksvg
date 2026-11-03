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
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.google.android.material.bottomnavigation.BottomNavigationView
import kotlinx.coroutines.launch

class ViewsTestActivity : AppCompatActivity() {

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

        applyLightSystemBars()

        val binding = viewsTestActivityLayout()
        setContentView(binding.root)
        recyclerView = binding.recyclerView
        bottomNavigation = binding.bottomNavigation

        val adapter = SvgAdapter(Glide.with(this))
        this.adapter = adapter
        // Our programmatic scroll must win over RecyclerView's saved-state restore (position 0).
        adapter.stateRestorationPolicy =
            RecyclerView.Adapter.StateRestorationPolicy.PREVENT
        binding.recyclerView.adapter = adapter
        // While the list flings, silence the animation tickers of attached
        // cells: their per-frame invalidations compete with the first draws
        // of newly bound cells for the frame budget (Perfetto: Full Self-Jank
        // during fling). Only SETTLING pauses — slow drags keep animating so
        // the freeze is never stared at. setVisible keeps the pooled render state,
        // so resume draws stay cheap. Glide still owns start/stop via attach state.
        binding.recyclerView.addOnScrollListener(object : RecyclerView.OnScrollListener() {
            override fun onScrollStateChanged(recyclerView: RecyclerView, newState: Int) {
                setAttachedAnimationsVisible(newState != RecyclerView.SCROLL_STATE_SETTLING)
            }
        })

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
     * `adb shell am start -n hu.oandras.ksvg.showcase/.ViewsTestActivity
     * --es category verification --es scroll_to blend_mode.svg`
     * Category is one of `meteocons` or `verification` (aka `visual`);
     * scroll_to matches SvgEntry.displayName exactly, falling back to the
     * first substring match. Unknown values are ignored.
     *
     * Passing `--ez highlights true` shows only the curated highlights of the
     * selected gallery (one representative per type); without `--es category`
     * it defaults to the Meteocons tab. Combine with
     * `--es category verification` for the verification gallery highlights.
     */
    private fun handleDeepLink(intent: Intent) {
        // Only touch the flag when the intent actually carries it: on
        // recreation the extra is already stripped (see the removes below),
        // and resetting the ViewModel state here would lose the highlights
        // view after rotation.
        val highlightsRequested = intent.hasExtra(EXTRA_HIGHLIGHTS)
        val highlights = highlightsRequested && intent.getBooleanExtra(EXTRA_HIGHLIGHTS, false)
        if (highlightsRequested) {
            viewModel.highlightsOnly.value = highlights
        }

        val requestedCategory = when (intent.getStringExtra(EXTRA_CATEGORY)?.lowercase()) {
            "meteocons" -> Category.METEOCONS
            "verification", "visual" -> Category.VISUAL
            else -> null
        }
        // Highlights apply to whichever gallery is shown; without an explicit
        // category they default to Meteocons.
        val effectiveCategory = requestedCategory
            ?: if (highlights) Category.METEOCONS else null
        if (effectiveCategory != null) {
            val menuId = if (effectiveCategory == Category.METEOCONS) {
                R.id.menu_meteocons
            } else {
                R.id.menu_verification
            }
            bindingSelectedCategory(effectiveCategory, menuId)
        }
        pendingScrollTo = intent.getStringExtra(EXTRA_SCROLL_TO)
            ?.takeIf { it.isNotBlank() }
        // Pin the target to the currently selected category so an in-flight
        // emission of the previous category cannot consume it (that early
        // scroll is what visibly jumped back to the top on the next submitList).
        pendingScrollCategory = pendingScrollTo?.let {
            effectiveCategory ?: viewModel.currentCategory.value
        }
        // Never scroll synchronously here: the next icons emission replaces
        // the list and would reset the position. consumePendingScroll runs
        // in the submitList commit callback and posts the scroll.
        // Make the intent one-shot so rotation/re-delivery cannot re-scroll.
        intent.removeExtra(EXTRA_SCROLL_TO)
        intent.removeExtra(EXTRA_CATEGORY)
        intent.removeExtra(EXTRA_HIGHLIGHTS)
    }

    private fun bindingSelectedCategory(category: Category, menuId: Int) {
        viewModel.currentCategory.value = category
        bottomNavigation.selectedItemId = menuId
    }

    private fun setAttachedAnimationsVisible(visible: Boolean) {
        for (i in 0 until recyclerView.childCount) {
            val holder = recyclerView.getChildViewHolder(recyclerView.getChildAt(i))
            (holder as? SvgAdapter.ViewHolder)?.setAnimationsVisible(visible)
        }
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
        const val EXTRA_HIGHLIGHTS: String = "highlights"
    }
}
