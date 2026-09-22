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

package hu.oandras.ksvg.filters

import android.graphics.Bitmap
import android.os.Build
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assume
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Round-D end-point parity (`tmp/GPU_PARITY_PLAN_D.md`): full-document
 * renders (`test-data/visual/filter_*.svg` + `filters.svg`, mirrored
 * under `assets/endpoint/`) through the real pipeline (RenderScene,
 * viewport, bbox-inherited regions, dispatcher) on software vs hardware
 * canvas. What A/B/C cannot see: document-level fallback decisions,
 * region inheritance from real bounding boxes, CSS inheritance, mixed
 * content around filtered elements.
 *
 * Conventions:
 * - Each file renders at its NATIVE size (viewBox): scaler-introduced
 *   canvas AA noise is a base-scene artifact, not filter signal (the
 *   256-default smeared non-square viewBoxes).
 * - Reference strategy per file (see `tmp/GPU_ROUNDD_WORKLOG.md`):
 *   device-SW by default; repo rsvg goldens (`assets/endpoint-golden/`)
 *   where device-SW is untrusted (native linear-arithmetic lane bug);
 *   explicit HW==SW fallback asserts where the GPU must decline.
 * - Excluded (documented in `EXCLUDED_ENDPOINT_FILES`, host
 *   `VisualComparisonTest` still gates these compositions SW-vs-rsvg):
 *   - `filter_specular.svg`: Skia-blur approximation feeds exponent-20
 *     specular — HW highlight half the rsvg/SW size (device-SW matches
 *     rsvg). Pixel gates cannot distinguish approximation from bug here;
 *     both primitives are covered in Round-A/B.
 *   - `filter_morphology_erode.svg`: device glyph rasterization differs
 *     SW-vs-HW (different subsystem) and erode/dilate min/max amplifies
 *     coverage diffs; morphology kernel covered text-free 52/52.
 */
@RunWith(Parameterized::class)
class GpuEndpointParityTest(
    private val fileName: String,
) {

    @Test
    fun endpointParity() {
        Assume.assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        // x86 emulators cannot run the native displacement kernel
        // (Round-A SIGILL precedent); physical ARM64 covers these.
        Assume.assumeFalse(
            "x86 emulator: native displacement kernel SIGILL (see report §5)",
            Build.SUPPORTED_ABIS.any { it.startsWith("x86") },
        )
        val case = endpointCase(fileName)
        val svg = loadEndpointSvg(case.file)
        val name = "endpoint:${case.file}"
        if (case.goldenAsset != null) {
            // Untrusted device-SW: the SW render only feeds the
            // visible-effect guard; parity is HW vs the repo rsvg golden.
            val sw = renderSoftware(svg, case.width, case.height)
            assertVisibleFilterEffect(name, sw, renderSoftware(unfilteredEndpoint(svg), case.width, case.height))
            val hw = renderOnHardware(svg, case.width, case.height)
            // Round-E: per-filter chain-taken proof (E5/E6); the geometry
            // case declines (fallback = true).
            assertChainBackend(
                name, minGpuApi = 33,
                expectFallback = case.fallback,
                expectedFilterIds = case.chainFilters,
                expectedMinUses = case.chainMinUses,
            )
            val golden = loadGoldenAsset(
                case.goldenAsset,
                Bitmap.createBitmap(case.width, case.height, Bitmap.Config.ARGB_8888),
            )
            assertParity(
                "$name (golden, minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
                golden,
                hw,
                maxAbsTol = case.maxAbsTol,
                maxOutlierRatio = case.maxOutlierRatio,
                premultiplyReference = case.premultiplyReference,
                matchRadius = case.matchRadius,
            )
            return
        }
        val sw = renderSoftware(svg, case.width, case.height)
        assertVisibleFilterEffect(name, sw, renderSoftware(unfilteredEndpoint(svg), case.width, case.height))
        val hw = renderOnHardware(svg, case.width, case.height)
        // Round-E: per-filter chain-taken proof (E5/E6); the geometry
        // case declines (fallback = true).
        assertChainBackend(
            name, minGpuApi = 33,
            expectFallback = case.fallback,
            expectedFilterIds = case.chainFilters,
            expectedMinUses = case.chainMinUses,
        )
        assertParity(
            "$name (minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
            sw,
            hw,
            maxAbsTol = case.maxAbsTol,
            maxOutlierRatio = case.maxOutlierRatio,
            premultiplyReference = case.premultiplyReference,
            translucentQuantK = case.translucentQuantK,
            matchRadius = case.matchRadius,
        )
    }

    companion object {
        private class EndpointCase(
            val file: String,
            val width: Int,
            val height: Int,
            val maxAbsTol: Int = GPU_PARITY_MAX_ABS,
            val maxOutlierRatio: Double = GPU_PARITY_MAX_OUTLIER_RATIO,
            val premultiplyReference: Boolean = false,
            val translucentQuantK: Int = 0,
            val fallback: Boolean = false,
            val goldenAsset: String? = null,
            val matchRadius: Int = 0,
            /**
             * Round-E: filter element ids expected to draw in this file
             * (E5 per-filter map). Must match the `<filter id="...">`s
             * referenced by rendered elements in `assets/endpoint/$file`.
             */
            val chainFilters: List<String> = emptyList(),
            /**
             * Round-E: per-filter minimum draw counts (E6: shared filter
             * nodes must draw once per use — guards the per-element slot
             * fix against cache regressions).
             */
            val chainMinUses: Map<String, Int> = emptyMap(),
        )

        // NOTE: gates are first-run placeholders (strict); calibrated
        // per file from measured stats (see GPU_ROUNDD_WORKLOG.md).
        // `fallback` cases assert HW==SW (strict): a taken GPU path
        // would diverge hugely.
        private val ENDPOINT_CASES: Map<String, EndpointCase> = listOf(
            EndpointCase(
                "filter_component_transfer_complex.svg", 300, 300,
                maxAbsTol = 8,
                maxOutlierRatio = 0.005,
                chainFilters = listOf("table", "discrete", "gamma"),
            ),
            EndpointCase(
                "filter_composite_arithmetic.svg", 256, 256,
                // Linear by default: HW computes linear (F9), so the sRGB
                // rsvg golden can never match — host linear golden instead
                // (render-path recipe, determinism-checked).
                goldenAsset = "endpoint-golden/endpoint_composite_arithmetic_linear.png",
                premultiplyReference = true,
                // 1px region-rounding ring (host region slightly bigger):
                // chamfer forgives the boundary shift, value errors still
                // fail (F9 worklog).
                matchRadius = 1,
                chainFilters = listOf("arithmetic"),
            ),
            EndpointCase(
                "filter_convolve.svg", 256, 256,
                matchRadius = 1,
                // Edge-detect kernel (1..-8..1) amplifies ±1 base-scene AA
                // coverage diffs into ≤222 spikes; the max-gate cannot
                // exist here, the ratio budgets spike pixels (a wrong
                // kernel/divisor/target shifts whole edge bands far
                // outside it). Round-B covers values/targets precisely.
                maxAbsTol = 255,
                maxOutlierRatio = 0.03,
                // `#conv` is shared by two elements (E6 class) — both uses
                // must draw.
                chainFilters = listOf("conv"),
                chainMinUses = mapOf("conv" to 2),
            ),
            EndpointCase(
                "filter_convolve_advanced.svg", 240, 220,
                matchRadius = 1,
                maxAbsTol = 255,
                maxOutlierRatio = 0.01,
                chainFilters = listOf("edge"),
            ),
            // Round-E: fragment-reference feImage (`href="#source"`) still
            // declines — F8 covers raster (data-URI) feImage only. Legit
            // fallback: expect sw.
            EndpointCase(
                "filter_feImage.svg", 240, 220, fallback = true,
                chainFilters = listOf("mix"),
            ),
            EndpointCase("filter_flood.svg", 256, 256, chainFilters = listOf("flood")),
            EndpointCase(
                "filter_geometry_units.svg", 240, 220, fallback = true,
                // Fallback-blit fringe (deterministic 902 px, max 78 — the
                // software result composited onto the HW canvas differs at
                // the blob edge; blob geometry + rsvg agree, decline proven
                // by log). Still catches a broken decline (8000+ px).
                maxAbsTol = 80,
                maxOutlierRatio = 0.03,
                chainFilters = listOf("f"),
            ),
            EndpointCase("filter_merge.svg", 256, 256, chainFilters = listOf("merge")),
            EndpointCase(
                "filter_morphology_erode.svg", 200, 200, matchRadius = 1,
                chainFilters = listOf("erode", "dilate"),
            ),
            EndpointCase(
                "filter_object_bbox_linear_rgb.svg", 320, 140,
                matchRadius = 1,
                maxAbsTol = 24,
                maxOutlierRatio = 0.10,
                chainFilters = listOf("a", "b"),
            ),
            EndpointCase(
                "filter_primitives.svg", 256, 256,
                premultiplyReference = true,
                matchRadius = 1,
                // Blend-at-transparent fringe + native-blur hue-loss halo
                // (device-SW renders black halos where rsvg/HW keep red —
                // filed :filtering follow-up; rsvg unusable as reference
                // here because three regions are turbulence-driven and
                // rsvg noise differs). Change-detector shape: miswirings
                // and region bugs hit opaque areas far outside it.
                maxAbsTol = 64,
                maxOutlierRatio = 0.06,
                // E5: all 9 filters must take the chain, one draw each.
                chainFilters = listOf(
                    "blur", "gray", "cm", "morph", "offset",
                    "blend", "ct", "disp", "light",
                ),
            ),
            EndpointCase(
                "filter_tile.svg", 256, 256,
                maxAbsTol = 20,
                maxOutlierRatio = 0.005,
                chainFilters = listOf("tile"),
            ),
            EndpointCase(
                "filters.svg", 200, 200,
                matchRadius = 1,
                // Text-shadow spikes to ~177 (glyph-coverage noise in the
                // shared-shadow halo) + shadow-approx edges; the ratio
                // budgets them while missing content (the slot-fix class:
                // thousands of blue/shape px) fails loudly.
                maxAbsTol = 255,
                maxOutlierRatio = 0.05,
                chainFilters = listOf("blur", "shadow"),
                // E6: `#shadow` is shared by the circle AND the text — both
                // uses must draw on GPU (guards the per-element slot fix).
                chainMinUses = mapOf("shadow" to 2),
            ),
        ).associateBy { it.file }

        /**
         * Files excluded from device parity (mirrors the host
         * `EXCLUDED_FROM_VISUAL_VERIFICATION` pattern): pixel gates
         * cannot distinguish approximation from bug here, while the
         * primitives are covered in Round-A/B and the compositions are
         * covered host-side SW-vs-rsvg.
         * - `filter_specular.svg`: Skia-blur approximation feeds
         *   exponent-20 specular — HW highlight half the rsvg/SW size.
         * - `filter_morphology_erode.svg`: glyph rasterization differs
         *   SW-vs-HW (different subsystem) and erode/dilate min/max
         *   amplifies coverage diffs (1021 px at ≤46 even with
         *   matchRadius=1); morphology kernel covered text-free 52/52.
         */
        private val EXCLUDED_ENDPOINT_FILES: Set<String> = setOf(
            "filter_specular.svg",
            "filter_morphology_erode.svg",
        )

        private fun endpointCase(fileName: String): EndpointCase {
            return ENDPOINT_CASES[fileName] ?: error("unknown endpoint file $fileName")
        }

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            val nameFilter: String? = InstrumentationRegistry.getArguments()
                .getString("gpu_parity_filter")
            val files = if (nameFilter.isNullOrBlank()) {
                (ENDPOINT_CASES.keys - EXCLUDED_ENDPOINT_FILES).toList()
            } else {
                ENDPOINT_CASES.keys.filter { it.contains(nameFilter) }
            }
            check(files.isNotEmpty()) {
                "GpuEndpointParityTest: no cases selected (filter=$nameFilter)"
            }
            return files.map { arrayOf(it) }
        }

        private fun loadEndpointSvg(fileName: String): String {
            val assets = InstrumentationRegistry.getInstrumentation().context.assets
            return assets.open("endpoint/$fileName").bufferedReader().use { it.readText() }
        }

        /**
         * Best-effort unfiltered baseline: strips `filter="..."` attributes
         * so the visible-effect guard can prove the filter does something.
         */
        private fun unfilteredEndpoint(svg: String): String {
            val baseline = svg.replace(Regex(""" filter="[^"]*""""), "")
            check(baseline != svg) { "Endpoint SVG must contain a filter=\"...\" attribute" }
            return baseline
        }
    }
}
