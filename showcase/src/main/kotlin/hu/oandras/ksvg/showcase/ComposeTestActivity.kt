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

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import hu.oandras.ksvg.compose.KsvgAnimatedImage

// Compose parity of MainActivity: same ViewModel, same categories, same 3-column grid,
// same deep-link contract (`category` + `scroll_to` extras). Cells use KsvgAnimatedImage
// with animation parsing enabled, mirroring the Glide PARSE_ANIMATIONS=true binding.
class ComposeTestActivity : ComponentActivity() {

    private val viewModel: IconsViewModel by viewModels()

    private var pendingScrollTo: String? by mutableStateOf(null)
    private var pendingScrollCategory: Category? by mutableStateOf(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        handleDeepLink(intent)
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    val category: Category by viewModel.currentCategory.collectAsStateWithLifecycle()
                    val icons: List<SvgEntry> by viewModel.icons.collectAsStateWithLifecycle()
                    GalleryContent(
                        category = category,
                        icons = icons,
                        pendingScrollTo = pendingScrollTo,
                        pendingScrollCategory = pendingScrollCategory,
                        onCategorySelected = { viewModel.currentCategory.value = it },
                        onScrollConsumed = {
                            pendingScrollTo = null
                            pendingScrollCategory = null
                        },
                    )
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent) {
        val requestedCategory = when (intent.getStringExtra(MainActivity.EXTRA_CATEGORY)?.lowercase()) {
            "meteocons" -> Category.METEOCONS
            "verification", "visual" -> Category.VISUAL
            else -> null
        }
        if (requestedCategory != null) {
            viewModel.currentCategory.value = requestedCategory
        }
        pendingScrollTo = intent.getStringExtra(MainActivity.EXTRA_SCROLL_TO)
            ?.takeIf { it.isNotBlank() }
        // Pin the target to the currently selected category so an in-flight
        // emission of the previous category cannot consume it.
        pendingScrollCategory = pendingScrollTo?.let {
            requestedCategory ?: viewModel.currentCategory.value
        }
        // Make the intent one-shot so rotation/re-delivery cannot re-scroll.
        intent.removeExtra(MainActivity.EXTRA_SCROLL_TO)
        intent.removeExtra(MainActivity.EXTRA_CATEGORY)
    }
}

@Composable
private fun GalleryContent(
    category: Category,
    icons: List<SvgEntry>,
    pendingScrollTo: String?,
    pendingScrollCategory: Category?,
    onCategorySelected: (Category) -> Unit,
    onScrollConsumed: () -> Unit,
) {
    val gridState = rememberLazyGridState()
    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = category == Category.METEOCONS,
                    onClick = { onCategorySelected(Category.METEOCONS) },
                    icon = { Icon(Icons.AutoMirrored.Filled.List, contentDescription = null) },
                    label = { Text("Meteocons") },
                )
                NavigationBarItem(
                    selected = category == Category.VISUAL,
                    onClick = { onCategorySelected(Category.VISUAL) },
                    icon = { Icon(Icons.Filled.CheckCircle, contentDescription = null) },
                    label = { Text("Verification") },
                )
            }
        },
    ) { innerPadding ->
        LazyVerticalGrid(
            columns = GridCells.Fixed(3),
            state = gridState,
            modifier = Modifier.fillMaxSize(),
            contentPadding = innerPadding,
        ) {
            items(icons, key = { it.uri }) { entry ->
                SvgCell(
                    assetPath = "${category.assetPath}/${entry.displayName}",
                    name = entry.displayName,
                )
            }
        }
    }
    LaunchedEffect(icons, pendingScrollTo, pendingScrollCategory) {
        val target = pendingScrollTo ?: return@LaunchedEffect
        // Only act once the visible list belongs to the requested category.
        if (category != pendingScrollCategory) return@LaunchedEffect
        if (icons.isEmpty()) return@LaunchedEffect
        val index = icons.indexOfFirst { it.displayName == target }
            .takeIf { it >= 0 }
            ?: icons.indexOfFirst { it.displayName.contains(target) }
        // Unknown name: nothing left to wait for, drop the request.
        onScrollConsumed()
        if (index >= 0) {
            gridState.scrollToItem(index)
        }
    }
}

@Composable
private fun SvgCell(assetPath: String, name: String) {
    Column(
        modifier = Modifier.padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        KsvgAnimatedImage(
            assetPath = assetPath,
            contentDescription = name,
            modifier = Modifier.size(100.dp),
        )
        Text(
            text = name,
            fontSize = 12.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}
