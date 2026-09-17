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

import org.junit.Assert.assertEquals
import org.junit.Test

class KernelBenchmarkMatrixFilterTest {

    private val sizes512 = arrayOf(512 to 512)

    @Test
    fun noFilterRunsEveryCase() {
        val cases = KernelBenchmarkMatrix.cases(kernels = null, sizes = sizes512)

        assertEquals(24, cases.size)
        assertEquals("ArithmeticComposite (linear)", cases.first().config.name)
    }

    @Test
    fun emptyConfigFilterIsIgnored() {
        val cases = KernelBenchmarkMatrix.cases(kernels = null, configs = emptySet(), sizes = sizes512)

        assertEquals(24, cases.size)
    }

    @Test
    fun configSubstringSelectsAcrossFamilies() {
        val cases = KernelBenchmarkMatrix.cases(kernels = null, configs = setOf("linear"), sizes = sizes512)

        assertEquals(
            listOf(
                "ArithmeticComposite (linear)",
                "ArithmeticComposite (non-linear)",
                "Lighting (diffuse, distant, linear)",
                "Lighting (diffuse, point, linear)",
                "Lighting (diffuse, spot, linear)",
                "Lighting (specular, distant, linear)",
                "Lighting (specular, point, linear)",
                "Lighting (specular, spot, linear)",
                "UnLinearize",
            ),
            cases.map { it.config.name },
        )
    }

    @Test
    fun configSubstringIsCaseInsensitive() {
        val lower = KernelBenchmarkMatrix.cases(kernels = null, configs = setOf("linear"), sizes = sizes512)
        val upper = KernelBenchmarkMatrix.cases(kernels = null, configs = setOf("LINEAR"), sizes = sizes512)

        assertEquals(lower.map { it.config.name }, upper.map { it.config.name })
    }

    @Test
    fun distantLinearTokenSkipsNonLinearVariants() {
        // A bare "linear" also matches "non-linear"; a fuller token like
        // "distant, linear" selects exactly the linear lighting rows.
        val cases = KernelBenchmarkMatrix.cases(kernels = null, configs = setOf("distant, linear"), sizes = sizes512)

        assertEquals(
            listOf(
                "Lighting (diffuse, distant, linear)",
                "Lighting (specular, distant, linear)",
            ),
            cases.map { it.config.name },
        )
    }

    @Test
    fun fullConfigNameMatchesExactlyOneCase() {
        val cases = KernelBenchmarkMatrix.cases(
            kernels = null,
            configs = setOf("Lighting (diffuse, distant, linear)"),
            sizes = sizes512,
        )

        assertEquals(listOf("Lighting (diffuse, distant, linear)"), cases.map { it.config.name })
    }

    @Test
    fun kernelAndConfigFiltersAreAnded() {
        val cases = KernelBenchmarkMatrix.cases(
            kernels = setOf("Lighting"),
            configs = setOf("specular"),
            sizes = sizes512,
        )

        assertEquals(
            listOf(
                "Lighting (specular, distant)",
                "Lighting (specular, distant, linear)",
                "Lighting (specular, point)",
                "Lighting (specular, point, linear)",
                "Lighting (specular, spot)",
                "Lighting (specular, spot, linear)",
            ),
            cases.map { it.config.name },
        )
    }

    @Test
    fun multipleConfigSubstringsSelectMultipleVariants() {
        // Mirrors what the `+`-split benchmark.config parser hands to the matrix:
        // each substring is matched independently (full "diffuse, distant" names
        // included), and the results are unioned.
        val cases = KernelBenchmarkMatrix.cases(
            kernels = setOf("Lighting"),
            configs = setOf("diffuse, distant", "specular, distant, linear"),
            sizes = sizes512,
        )

        assertEquals(
            listOf(
                "Lighting (diffuse, distant)",
                "Lighting (diffuse, distant, linear)",
                "Lighting (specular, distant, linear)",
            ),
            cases.map { it.config.name },
        )
    }
}