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

package hu.oandras.ksvg

import android.graphics.Bitmap
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.core.ElementBase
import hu.oandras.ksvg.logger.NoopLoggerContext
import hu.oandras.ksvg.render.GroupRenderNode
import hu.oandras.ksvg.render.MarkerRenderNode
import hu.oandras.ksvg.render.FeImageRenderNode
import hu.oandras.ksvg.render.PathRenderNode
import hu.oandras.ksvg.render.PatternRenderNode
import hu.oandras.ksvg.render.RenderNode
import hu.oandras.ksvg.render.RenderTreeBuilder
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.render.pool.PoolOwner
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * Reference cycles must terminate (no hang, no `StackOverflowError`).
 * `fillInChainedGradientFields` / `fillInChainedPatternFields` only guard
 * self-references, and `buildMask` has no `buildingIds` guard (only the
 * end-of-build cache), so only cycles *not* containing the entry point or
 * id-less content can loop. These tests pin termination; the exact fallback
 * rendering of a broken chain is deliberately unasserted here.
 *
 * Hang-type regressions (e.g., render-time mask recursion) would stall the
 * suite forever, so every test carries a JUnit timeout: a stuck render fails
 * fast instead. (Coroutine `withTimeout` would not help: cancellation is
 * cooperative and the render loop never suspends. Note the timeout only fails
 * the test — a runaway thread keeps spinning in the background.)
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class ReferenceCycleTest {

    private companion object {
        // A healthy render of these 200x200 SVGs takes ~10-20 ms, so this is
        // ~1000x headroom. `@Before` warm-up keeps the one-time Robolectric
        // native-runtime load (~3.7 s) out of the timed window, so a slow CI
        // machine cannot flake the budget.
        const val HANG_BUDGET_MS = 15_000L
    }

    @Before
    fun warmUpNativeRuntime() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="8" height="8">
              <rect width="8" height="8" fill="red"/>
            </svg>
            """.trimIndent()
        )
    }

    private fun renders(svg: String): Bitmap {
        return renderWithLibrary(svg, createBitmap(200, 200, Bitmap.Config.ARGB_8888))
    }

    @Test(timeout = HANG_BUDGET_MS)
    fun gradientHrefCycleTerminates() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <linearGradient id="a" href="#b"/>
                <linearGradient id="b" href="#c">
                  <stop offset="0" stop-color="red"/>
                  <stop offset="1" stop-color="blue"/>
                </linearGradient>
                <linearGradient id="c" href="#b"/>
              </defs>
              <rect width="200" height="200" fill="url(#a)"/>
            </svg>
            """.trimIndent()
        )
    }

    @Test(timeout = HANG_BUDGET_MS)
    fun gradientSelfReferenceTerminates() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <linearGradient id="a" href="#a">
                  <stop offset="0" stop-color="red"/>
                  <stop offset="1" stop-color="blue"/>
                </linearGradient>
              </defs>
              <rect width="200" height="200" fill="url(#a)"/>
            </svg>
            """.trimIndent()
        )
    }

    @Test(timeout = HANG_BUDGET_MS)
    fun patternHrefCycleTerminates() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <pattern id="pa" href="#pb" width="20" height="20" patternUnits="userSpaceOnUse"/>
                <pattern id="pb" href="#pc" width="20" height="20" patternUnits="userSpaceOnUse">
                  <rect width="20" height="20" fill="red"/>
                </pattern>
                <pattern id="pc" href="#pb" width="20" height="20" patternUnits="userSpaceOnUse"/>
              </defs>
              <rect width="200" height="200" fill="url(#pa)"/>
            </svg>
            """.trimIndent()
        )
    }

    @Test(timeout = HANG_BUDGET_MS)
    fun maskInMaskTerminates() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <mask id="m1">
                  <rect width="200" height="200" fill="white" mask="url(#m2)"/>
                </mask>
                <mask id="m2">
                  <rect width="200" height="200" fill="white" mask="url(#m1)"/>
                </mask>
              </defs>
              <rect width="200" height="200" fill="red" mask="url(#m1)"/>
            </svg>
            """.trimIndent()
        )
    }

    @Test(timeout = HANG_BUDGET_MS)
    fun markerSelfReferenceTerminates() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <marker id="m" markerWidth="10" markerHeight="10" refX="5" refY="5" orient="auto">
                  <path d="M0,0 L10,10" marker-start="url(#m)"/>
                </marker>
              </defs>
              <path d="M10,10 L190,190" fill="none" stroke="red" stroke-width="4" marker-start="url(#m)"/>
            </svg>
            """.trimIndent()
        )
    }

    @Test(timeout = HANG_BUDGET_MS)
    fun patternContentSelfReferenceTerminates() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <pattern id="P" width="20" height="20" patternUnits="userSpaceOnUse">
                  <rect width="20" height="20" fill="url(#P)"/>
                </pattern>
              </defs>
              <rect width="200" height="200" fill="url(#P)"/>
            </svg>
            """.trimIndent()
        )
    }

    @Test(timeout = HANG_BUDGET_MS)
    fun feImageFilteredElementCycleTerminates() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <filter id="F" x="0" y="0" width="200" height="200" filterUnits="userSpaceOnUse">
                  <feImage href="#el"/>
                </filter>
              </defs>
              <rect id="el" width="200" height="200" fill="red" filter="url(#F)"/>
            </svg>
            """.trimIndent()
        )
    }

    @Test(timeout = HANG_BUDGET_MS)
    fun clipChildSelfReferenceTerminates() {
        renders(
            """
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
              <defs>
                <clipPath id="c">
                  <rect width="200" height="200" clip-path="url(#c)"/>
                </clipPath>
              </defs>
              <rect width="200" height="200" fill="red" clip-path="url(#c)"/>
            </svg>
            """.trimIndent()
        )
    }

    // --- Cycle fallbacks: the cyclic (inner) reference is dropped, the outer user is intact. ---

    private fun buildTree(svg: String): RenderNode<*>? {
        val doc = SVGImpl.getFromString(svg, loggerContext = NoopLoggerContext)
        val builder = RenderTreeBuilder(doc, 160f, null, PoolOwner(), doc)
        return builder.build(Box(0f, 0f, 200f, 200f))
    }

    private fun RenderNode<*>.allNodes(): List<RenderNode<*>> {
        val out = ArrayList<RenderNode<*>>()
        val seen = HashSet<RenderNode<*>>()
        fun visit(n: RenderNode<*>) {
            if (!seen.add(n)) return
            out.add(n)
            when (n) {
                is GroupRenderNode<*> -> n.children.forEach(::visit)
                is PatternRenderNode -> n.children.forEach(::visit)
                else -> {}
            }
            // Paint/marker/clip references live in fields, not in children.
            n.markerStartNode?.let(::visit)
            n.markerMidNode?.let(::visit)
            n.markerEndNode?.let(::visit)
            n.fillPatternNode?.let(::visit)
            n.strokePatternNode?.let(::visit)
        }
        visit(this)
        return out
    }

    @Test
    fun markerCycleDropsInnerReference() {
        val root = checkNotNull(
            buildTree(
                """
                <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
                  <defs>
                    <marker id="m" markerWidth="10" markerHeight="10" refX="5" refY="5" orient="auto">
                      <path d="M0,0 L10,10" marker-start="url(#m)"/>
                    </marker>
                  </defs>
                  <path d="M10,10 L190,190" fill="none" stroke="red" stroke-width="4" marker-start="url(#m)"/>
                </svg>
                """.trimIndent()
            )
        )
        val nodes = root.allNodes()
        val markers = nodes.filterIsInstance<MarkerRenderNode>()
        assert(markers.isNotEmpty()) { "outer marker missing" }
        val inMarker = markers.flatMap { it.allNodes().toSet() }.toSet()
        // The outer path keeps its marker …
        val outerPaths = nodes.filterIsInstance<PathRenderNode>().filter { it !in inMarker }
        assert(outerPaths.size == 1) { "expected one outer path, got ${outerPaths.size}" }
        assertNotNull(outerPaths.single().markerStartNode)
        // … but the cyclic reference inside the marker content is dropped.
        val innerPaths = markers.flatMap { it.children.filterIsInstance<PathRenderNode>() }
        assert(innerPaths.isNotEmpty()) { "marker content missing" }
        innerPaths.forEach {
            assertNull(it.markerStartNode)
            assertNull(it.markerMidNode)
            assertNull(it.markerEndNode)
        }
    }

    @Test
    fun patternCycleDropsInnerReference() {
        val root = checkNotNull(
            buildTree(
                """
                <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
                  <defs>
                    <pattern id="P" width="20" height="20" patternUnits="userSpaceOnUse">
                      <rect width="20" height="20" fill="url(#P)"/>
                    </pattern>
                  </defs>
                  <rect width="200" height="200" fill="url(#P)"/>
                </svg>
                """.trimIndent()
            )
        )
        val nodes = root.allNodes()
        val patterns = nodes.filterIsInstance<PatternRenderNode>()
        assert(patterns.isNotEmpty()) { "outer pattern missing" }
        val inPattern = patterns.flatMap { it.allNodes().toSet() }.toSet()
        // The outer rect keeps its pattern …
        val outerRects = nodes.filterIsInstance<PathRenderNode>()
            .filter { it !in inPattern && it.fillPatternNode != null }
        assert(outerRects.size == 1) { "expected one outer rect, got ${outerRects.size}" }
        // … but the cyclic fill inside the pattern content falls back to none.
        val innerRects = patterns.flatMap { it.children.filterIsInstance<PathRenderNode>() }
        assert(innerRects.isNotEmpty()) { "pattern content missing" }
        innerRects.forEach {
            assertNull(it.fillPatternNode)
            assertNull(it.strokePatternNode)
        }
    }

    @Test
    fun sharedFilterCycleSkipsInnerFilter() {
        val root = checkNotNull(
            buildTree(
                """
                <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
                  <defs>
                    <filter id="F" x="0" y="0" width="200" height="200" filterUnits="userSpaceOnUse">
                      <feImage href="#el2"/>
                    </filter>
                  </defs>
                  <rect id="el1" width="100" height="200" fill="red" filter="url(#F)"/>
                  <rect id="el2" x="100" width="100" height="200" fill="blue" filter="url(#F)"/>
                </svg>
                """.trimIndent()
            )
        )
        fun nodeById(id: String): RenderNode<*> {
            return root.allNodes().single { (it.sourceElement as? ElementBase)?.id == id }
        }
        // The outer element keeps its filter …
        val filterNode = nodeById("el1").filterNode
        assertNotNull(filterNode)
        // … but the re-entrant filter application on the feImage target is skipped:
        // the element copy rendered inside the filter draws unfiltered.
        val feImage = checkNotNull(filterNode!!.primitives.singleOrNull()) as FeImageRenderNode
        val innerTarget = checkNotNull(feImage.referencedNode)
        assertNull(innerTarget.filterNode)
    }
}
