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

package hu.oandras.ksvg.filtering

import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Focused guard for negative `diffuseConstant` on spot-diffuse lighting.
 *
 * Per Filter Effects §9.10 the light map is `D = kd * N.L * L` with only the
 * final §9.1 RGBA clamp, so `kd < 0` lights back-facing pixels (rsvg oracle:
 * 378/384 px lit for a `kd = -1` spot fixture). There is deliberately NO
 * `max(dot, 0)` pre-clamp before the `*k` multiply on any backend.
 *
 * Width 12 hits the vector tail path on every row; linear output, fixed params,
 * sloped-alpha bump map. Every advertised backend forced (NEON64 on the
 * phone, SSSE3 on x86 emulators) must match the pure-Kotlin reference
 * byte-exactly, and must contain lit pixels (an all-dark result would mean
 * a pre-clamp regression).
 */
public class SpotDiffuseNegativeKDeviceTest {

    @Test
    public fun negativeKMatchesKotlinAndLightsBackFaces() {
        assertNativeBackendAvailable()

        val width = 12
        val height = 8
        // Alpha-channel ramp (the bump map): varying surface normals.
        val input = IntArray(width * height) { i ->
            val x = i % width
            val y = i / width
            (((x * 97 + y * 61 + 11) and 0xFF) shl 24) or 0x00FFFFFF
        }
        // Grazing spot: many normals face away from the light (N.L < 0).
        val params = doubleArrayOf(0.0, 4.0, 2.0, 12.0, 4.0, 0.0, 90.0, 1.0)

        val ref = IntArray(width * height)
        KotlinKernels.lighting(
            input, ref, width, height,
            0, 0, width, height,
            2f, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f,
            2, false, -1f, 1f,
            255, 255, 255, params, false, true,
        )

        for (backend in getBackendsFor(LightingNative.nativeBackend())) {
            val out = IntArray(width * height)
            LightingNative.applyForced(
                input, out, width, height,
                0, 0, width, height,
                2f, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f,
                2, false, -1f, 1f,
                255, 255, 255, params, false, true,
                backend,
            )

            assertColorArrayEquals(
                "spot diffuse k=-1 ${backendName(backend)} vs Kotlin", ref, out
            )
        }

        var lit = 0
        for (p in ref) {
            if ((p and 0x00FFFFFF) != 0) lit++
        }
        assertTrue("k=-1 must light back-facing pixels, got all dark", lit > 0)
    }
}
