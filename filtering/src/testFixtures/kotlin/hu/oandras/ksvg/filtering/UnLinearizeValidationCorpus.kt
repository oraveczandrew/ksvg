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

package hu.oandras.ksvg.filtering

/**
 * Deterministic, architecture-independent validation corpus for the native
 * unlinearize kernels, shared verbatim by:
 *
 *  - the host JVM harness (`UnLinearizeNativeParityTest`, src/test);
 *  - the Android instrumented test (`UnlinearizeNativeDeviceTest`, src/androidTest).
 *
 * Same bytes on every ABI, so every executable native backend is compared
 * against the exact same [KotlinKernels.unLinearize] oracle (NATIVE_TESTING:
 * "shared deterministic test suite with the same input corpus on every
 * architecture"). This file lives under src/testFixtures and is wired into both
 * the host JVM and the Android instrumented test source sets only.
 */
public object UnLinearizeValidationCorpus {

    // ------------------------------------------------------------------ shapes

    /** Flat pixel-count buffers around every vector width (4/8/16 px) and its scalar tail. */
    @JvmField
    public val boundarySizes: IntArray = intArrayOf(
        0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17,
        31, 32, 33, 63, 64, 65, 127, 128, 129, 255, 256, 257,
    )

    /** Image-shaped buffers: odd/non-multiple widths, single/multiple rows. */
    @JvmField
    public val shapes: Array<Pair<Int, Int>> = arrayOf(
        1 to 1, 1 to 5, 2 to 3, 3 to 3, 5 to 7, 7 to 5, 9 to 9,
        16 to 1, 1 to 16, 33 to 9, 8 to 17, 64 to 1, 65 to 33,
    )

    // ------------------------------------------------------------------ inputs

    private fun argb(alpha: Int, red: Int, green: Int, blue: Int): Int =
        (alpha shl 24) or (red shl 16) or (green shl 8) or blue

    /**
     * Guarantees every 8-bit value 0..255 appears in each colour channel AND in
     * alpha (i has A=i, R=i, G=(i+85)&255, B=(i*137)&255). Exhaustive LUT domain.
     */
    public fun exhaustiveLut(size: Int): IntArray {
        val out = IntArray(size)
        for (i in out.indices) {
            val v = i and 0xFF
            out[i] = argb(v, v, (v + 85) and 0xFF, (v * 137) and 0xFF)
        }
        return out
    }

    /** Fixed RGB; alpha sweeps all 256 values (alpha-passthrough contract). */
    public fun allAlpha(size: Int): IntArray {
        val out = IntArray(size)
        for (i in out.indices) {
            out[i] = argb(i and 0xFF, 0x12, 0x34, 0x56)
        }
        return out
    }

    /**
     * Separately isolates each channel's full domain with the other channels fixed:
     * drives R=0..255 (G/B/A fixed), then G, then B. Catches per-channel gather bugs
     * more directly than the interleaved [exhaustiveLut].
     */
    public fun perChannelDomain(size: Int): IntArray {
        val out = IntArray(size)
        var i = 0
        var k = 0
        while (i < size) {
            val v = k and 0xFF
            when ((k ushr 8) and 0xFF) {
                0 -> out[i++] = argb(0x40, v, 0x11, 0x22) // R sweep
                1 -> out[i++] = argb(0x40, 0x11, v, 0x22) // G sweep
                else -> out[i++] = argb(0x40, 0x11, 0x22, v) // B sweep
            }
            k++
        }
        return out
    }

    /** Hard boundaries: repeated 0, repeated 255, and alternating 0xFFFFFFFF/0x00000000. */
    public fun alternating(size: Int): IntArray = IntArray(size) { if (it % 2 == 0) 0xFFFFFFFF.toInt() else 0 }

    /** Fixed-seed deterministic pseudo-random ARGB (alpha included). */
    public fun fixedSeedRandom(size: Int): IntArray {
        val out = IntArray(size)
        var state = 0x9E3779B9.toInt()
        for (i in out.indices) {
            state = state * 1664525 + 1013904223
            val a = (state ushr 24) and 0xFF
            val r = (state ushr 16) and 0xFF
            val g = (state ushr 8) and 0xFF
            val b = state and 0xFF
            out[i] = argb(a, r, g, b)
        }
        return out
    }

    // ------------------------------------------------------------------ case

    /**
     * One named validation case: a shape, an input kind, and whether to
     * run the JNI in-place (src == dst) path. Byte-exact compare against
     * [KotlinKernels.unLinearize] for every forced backend.
     */
    public class Case(
        @JvmField
        public val name: String,
        @JvmField
        public val width: Int,
        @JvmField
        public val height: Int,
        @JvmField
        public val inPlace: Boolean,
        @JvmField
        public val input: IntArray,
    ) {
        public val size: Int get() = width * height

        /** Reference oracle (never calls native). */
        public fun reference(): IntArray {
            val out = IntArray(size)
            KotlinKernels.unLinearize(input, out, width, height)
            return out
        }

        /** Independent fresh copy so a native backend cannot mutate the shared input. */
        public fun freshInput(): IntArray = input.copyOf()
    }

    /** The full corpus of cases for unlinearize validation. */
    @JvmField
    public val cases: List<Case> = buildList {
        // Exhaustive LUT over SIMD-aligned and odd-tail sizes, separate src/dst.
        for ((w, h) in listOf(32 to 8, 16 to 16, 33 to 9, 65 to 33, 16 to 1)) {
            add(Case("exhaustive ${w}x$h", w, h, inPlace = false, exhaustiveLut(w * h)))
        }
        // Channel-isolated full-domain, out of place.
        add(Case("perChannel 33x9", 33, 9, inPlace = false, perChannelDomain(33 * 9)))
        // Alpha passthrough contract over the production LUT.
        add(Case("allAlpha 16x16", 16, 16, inPlace = false, allAlpha(16 * 16)))
        // Boundaries / tails / random / alternating, out of place.
        for (pixels in boundarySizes) {
            add(Case("tail random $pixels", pixels, 1, inPlace = false, fixedSeedRandom(pixels)))
        }
        add(Case("alternating 7x5", 7, 5, inPlace = false, alternating(7 * 5)))
        // Image shapes with odd widths.
        for ((w, h) in shapes) {
            add(Case("shape ${w}x$h", w, h, inPlace = false, fixedSeedRandom(w * h)))
        }
        // In-place (src == dst) — the path the pipeline uses.
        for ((w, h) in listOf(36 to 10, 13 to 3, 9 to 9, 3 to 5)) {
            add(Case("inPlace ${w}x$h", w, h, inPlace = true, fixedSeedRandom(w * h)))
        }
    }
}
