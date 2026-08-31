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
 * Park–Miller linear congruential generator (CACM 1988, a=16807, m=2147483647)
 * used to build the feTurbulence lattice. Sequence must match the reference
 * (librsvg / SVG 1.1 §15.25) so the noise output is byte-identical.
 */
public class LcgRandom(seed: Int) {
    private var currentSeed: Int = seed.coerceIn(1, Int.MAX_VALUE - 1)

    public fun next(): Int {
        val a = 16807
        val m = 2147483647
        val q = 127773
        val r = 2836
        currentSeed = a * (currentSeed % q) - r * (currentSeed / q)
        if (currentSeed <= 0) currentSeed += m
        return currentSeed
    }
}
