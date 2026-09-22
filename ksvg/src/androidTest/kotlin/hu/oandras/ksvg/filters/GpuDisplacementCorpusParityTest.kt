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

import android.os.Build
import androidx.test.platform.app.InstrumentationRegistry
import hu.oandras.ksvg.filtering.DisplacementMapValidationCorpus
import hu.oandras.ksvg.filtering.parity.DisplacementMapParitySvg
import org.junit.Assume.assumeFalse
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Round-B corpus coverage for `feDisplacementMap`
 * (`tmp/GPU_PARITY_PLAN_B.md` §2): each
 * [DisplacementMapValidationCorpus.Case] becomes an SVG via
 * [DisplacementMapParitySvg] and is measured SW-vs-HW.
 *
 * Reference strategy: on-device software bitmap (the native displacement
 * kernel is trusted on ARM64 — bit-exact vs the Kotlin reference; the
 * x86 SIGILL dispatch issue from Round-A does not apply on-device here).
 * The corpus map array is replaced by a fixed `feTurbulence` field
 * (documented in the builder); scale, channel selectors and src size run
 * verbatim. Comparison is in premultiplied space (`premultiplyReference`):
 * the GPU chain is premultiplied end to end (morphology-shader kdoc) and
 * displacement copies the selected texel through untouched, so hardware
 * output is the premultiplied texel while the software bitmap holds it
 * straight. Selection itself is exact (no min/max races), so the PNG
 * round-trip stays parity-neutral; pixels where ±1 LSB map quantization
 * flips the truncated shift select a random neighbor texel (corpus src is
 * noise), which the per-case outlier gates below budget.
 */
@RunWith(Parameterized::class)
class GpuDisplacementCorpusParityTest(
    private val caseName: String,
    private val case: DisplacementMapValidationCorpus.Case,
) {

    @Test
    fun displacementCorpusParity() {
        assumeTrue(
            "GpuParityHarness needs API 29+ (HardwareRenderer)",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q,
        )
        // Round-A precedent: the native displacement kernel SIGILL-crashes
        // on x86 emulators (native-dispatch issue, not GPU). Physical ARM64
        // covers these cases.
        assumeFalse(
            "x86 emulator: native displacement kernel SIGILL (see report §5)",
            Build.SUPPORTED_ABIS.any { it.startsWith("x86") },
        )
        val svg = DisplacementMapParitySvg.toSvg(
            case,
            imageSource(case.src, case.width, case.height),
        )
        val name = "displacement:$caseName"
        val sw = renderSoftware(svg, case.width, case.height)
        if (case.scale != 0f) {
            assertVisibleFilterEffect(
                name = name,
                filtered = sw,
                unfiltered = renderSoftware(
                    svgString = corpusBaseline(svg),
                    width = case.width,
                    height = case.height
                )
            )
        }
        val hw = renderOnHardware(svg, case.width, case.height)
        // Per-case gates (Adreno CPH2449 measured 2026-09-21; flip rate
        // grows with |scale| as modeled: ±1 LSB map quantization flips
        // trunc(scale*(ch-0.5)) with P ≈ 2*scale/255):
        // - identity (scale 0): exact passthrough, strict (passed 0/256).
        // - negative (scale -5): 2/256 (0.008), mean 1.61.
        // - match (scale 10): 8/256 (0.031), mean 3.97.
        // - different (scale 20): 62/256 (0.242), mean 34.2. Map-size
        //   routing itself is a documented gap (same-size map here).
        // - large (scale 100): 203/256 (0.793), mean 107.7. At this scale
        //   the gate is a change-detector, not a tight bound: real bugs
        //   (wrong channel/sign, missing in2, no displacement) land at
        //   ~95-100% or exactly 0, both outside the 0.85 gate; tight
        //   scale coverage lives in the smaller cases. With
        //   translucentQuantK active the bound-exceeding pixels ARE the
        //   outliers, so maxOutlierRatio budgets them directly.
        val (maxAbsTol, maxOutlierRatio) = when (caseName) {
            "identity 16x16" -> GPU_PARITY_MAX_ABS to GPU_PARITY_MAX_OUTLIER_RATIO
            "negative scale 16x16" -> 4 to 0.05
            "match 16x16" -> 4 to 0.10
            "different 32x8" -> 4 to 0.35
            else -> 4 to 0.85
        }
        assertParity(
            name = "$name (minGpuApi=33, deviceApi=${Build.VERSION.SDK_INT})",
            sw = sw,
            hw = hw,
            maxAbsTol = maxAbsTol,
            maxOutlierRatio = maxOutlierRatio,
            // Premultiplied-space comparison (see class kdoc): the chain
            // emits the selected texel verbatim = premultiplied. The
            // alpha-scaled bound absorbs the float-vs-integer premult
            // rounding at low alpha (offline: identity maxAbs 10 all at
            // alpha < 50, covered by K=510); real mis-selections land far
            // outside it (random neighbor texel over noise src).
            premultiplyReference = true,
            translucentQuantK = 510,
        )
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            // Full corpus (5 cases).
            val nameFilter: String? = InstrumentationRegistry.getArguments()
                .getString("gpu_parity_filter")
            val cases = if (nameFilter.isNullOrBlank()) {
                DisplacementMapValidationCorpus.cases
            } else {
                DisplacementMapValidationCorpus.cases.filter { it.name.contains(nameFilter) }
            }
            check(cases.isNotEmpty()) {
                "GpuDisplacementCorpusParityTest: no cases selected " +
                    "(filter=$nameFilter, corpus=${DisplacementMapValidationCorpus.cases.size})"
            }
            return cases.map { arrayOf(it.name, it) }
        }
    }
}
