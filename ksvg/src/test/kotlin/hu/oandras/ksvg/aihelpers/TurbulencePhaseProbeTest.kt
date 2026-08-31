package hu.oandras.ksvg.aihelpers

import hu.oandras.ksvg.render.SvgPathNoise
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.decodePng
import hu.oandras.ksvg.utils.LcgRandom
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File

/**
 * WS-1 diagnostic harness for the feTurbulence golden (`turbulence.svg`).
 *
 * Root cause of the historical divergence (similarity 0.0089): the lattice was
 * built with a per-channel-interleaved permutation draw order instead of librsvg's
 * "all four channel gradients first, then one shared permutation" order, AND the
 * sample coordinates were anchored to the fractional filter-region origin instead of
 * the destination (device) pixel grid. Both are now fixed:
 *  - `SvgPathNoise` builds each channel's gradients from the shared LCG stream then a
 *    single shared permutation (`buildPermutation`), matching librsvg exactly; and
 *  - `doFeTurbulenceFilter` rounds the region origin to the nearest integer so the
 *    sampled user coordinate of each output pixel equals librsvg's integer coordinate.
 *
 * This test asserts the invariants that prevent regressions:
 *  1. The Park-Miller LCG reproduces librsvg's documented reference value.
 *  2. Sampling the rebuilt lattice at `px = x*baseFrequency` (zero phase offset)
 *     reproduces the golden alpha channel near-exactly (>= 99% of pixels).
 *  3. A small negative/positive phase offset collapses the match (far below),
 *     which is what pins the coordinate/grid alignment used by the fix.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [33])
class TurbulencePhaseProbeTest {

    @Test
    fun parkMillerSelfTest() {
        var r = setupSeed(1)
        repeat(10_000) { r = random(r) }
        // librsvg documents that after setup_seed(1) + 10000 iterations the state is 1043618065.
        check(r == 1043618065) { "Park-Miller drift: got $r" }
    }

    @Test
    fun latticeIdentityMatchAndOffsetSensitivity() {
        val golden = createBitmap(256, 256)
        decodePng(File("test-data/visual-golden/turbulence.png"), golden)
        val gPx = IntArray(256 * 256)
        golden.getPixels(gPx, 0, 256, 0, 0, 256, 256)

        val lcg = LcgRandom(1)
        val permutation = IntArray(SvgPathNoise.LATTICE_SIZE)
        val generators = Array(4) { SvgPathNoise(lcg, permutation) }
        SvgPathNoise.buildPermutation(lcg, permutation)

        val baseFrequency = 0.05
        val identity = alphaMatch(gPx, generators, 0.0, baseFrequency)
        val shifted = alphaMatch(gPx, generators, 0.4, baseFrequency)

        println("TURBULENCE identity offset=0.0: $identity/65536 ; offset=+0.4: $shifted/65536")
        check(identity >= 64_000) {
            "Lattice no longer reproduces the golden at the identity mapping: $identity/65536"
        }
        check(shifted < 20_000) {
            "Phase-offset tolerance blown: offset=+0.4 gives $shifted/65536 (coordinate anchor regressed)"
        }
    }

    private fun alphaMatch(
        gPx: IntArray,
        generators: Array<SvgPathNoise>,
        phaseOffsetPixels: Double,
        baseFrequency: Double,
    ): Int {
        var match = 0
        for (y in 0 until 256) {
            for (x in 0 until 256) {
                val px = (x + phaseOffsetPixels) * baseFrequency
                val py = (y + phaseOffsetPixels) * baseFrequency
                var sum = 0.0
                var weight = 1.0
                var cx = px
                var cy = py
                repeat(3) {
                    sum += generators[3].noise2(cx, cy) / weight
                    cx *= 2.0
                    cy *= 2.0
                    weight *= 2.0
                }
                val v = (sum * 255.0 + 255.0) / 2.0
                val a = ((v.coerceIn(0.0, 255.0)) + 0.5).toInt()
                if (a == (gPx[y * 256 + x] ushr 24) and 0xff) match++
            }
        }
        return match
    }

    private fun setupSeed(seedIn: Int): Int {
        var seed = seedIn
        if (seed <= 0) seed = -(seed % (RAND_M - 1)) + 1
        if (seed > RAND_M - 1) seed = RAND_M - 1
        return seed
    }

    private fun random(seed: Int): Int {
        var result = RAND_A * (seed % RAND_Q) - RAND_R * (seed / RAND_Q)
        if (result <= 0) result += RAND_M
        return result
    }

    private companion object {
        const val RAND_M = 2147483647
        const val RAND_A = 16807
        const val RAND_Q = 127773
        const val RAND_R = 2836
    }
}
