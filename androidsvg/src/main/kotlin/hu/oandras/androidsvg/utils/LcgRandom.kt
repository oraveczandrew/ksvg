package hu.oandras.androidsvg.utils

internal class LcgRandom(seed: Int) {
    private var currentSeed: Int = clamp(
        n = seed,
        min = 1,
        max = Int.MAX_VALUE - 1
    )

    fun next(): Int {
        val a = 16807
        val m = 2147483647
        val q = 127773
        val r = 2836
        currentSeed = a * (currentSeed % q) - r * (currentSeed / q)
        if (currentSeed <= 0) currentSeed += m
        return currentSeed
    }
}