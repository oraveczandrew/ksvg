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

/** Concrete per-family benchmark variant carried by a [BenchmarkCase]. */
public sealed interface BenchmarkConfig {
    /** Display name used in suite/CSV output. */
    public val name: String
}

/** Benchmark geometry/operator variant for the morphology family. */
public data class MorphologyBenchmarkConfig(
    override val name: String,
    @JvmField
    public val radiusX: Int,
    @JvmField
    public val radiusY: Int,
    @JvmField
    public val erode: Boolean
) : BenchmarkConfig

/**
 * Benchmark variant for the convolveMatrix family. [divisor] and [bias] live on the shared
 * config so host and device suites cannot drift apart (they were hardcoded 1f vs 16f before).
 */
public data class ConvolveBenchmarkConfig(
    override val name: String,
    @JvmField
    public val orderX: Int,
    @JvmField
    public val orderY: Int,
    @JvmField
    public val preserveAlpha: Boolean,
    @JvmField
    public val edgeMode: Int,
    @JvmField
    public val kernel: FloatArray,
    @JvmField
    public val divisor: Float = 16f,
    @JvmField
    public val bias: Float = 0f
) : BenchmarkConfig {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as ConvolveBenchmarkConfig

        if (orderX != other.orderX) return false
        if (orderY != other.orderY) return false
        if (preserveAlpha != other.preserveAlpha) return false
        if (edgeMode != other.edgeMode) return false
        if (name != other.name) return false
        if (!kernel.contentEquals(other.kernel)) return false
        if (divisor != other.divisor) return false
        if (bias != other.bias) return false

        return true
    }

    override fun hashCode(): Int {
        var result = orderX
        result = 31 * result + orderY
        result = 31 * result + preserveAlpha.hashCode()
        result = 31 * result + edgeMode
        result = 31 * result + name.hashCode()
        result = 31 * result + kernel.contentHashCode()
        result = 31 * result + divisor.hashCode()
        result = 31 * result + bias.hashCode()
        return result
    }
}

/** Benchmark variant for the arithmeticComposite family (sRGB vs linear-light path). */
public data class ArithmeticCompositeBenchmarkConfig(
    override val name: String,
    @JvmField
    public val useLinear: Boolean
) : BenchmarkConfig

/** Benchmark variant for the lighting family. */
public data class LightingBenchmarkConfig(
    override val name: String,
    @JvmField
    public val lightType: Int,
    @JvmField
    public val specular: Boolean,
    @JvmField
    public val k: Float = 1f,
    @JvmField
    public val exponent: Float = 1f,
    @JvmField
    public val useLinear: Boolean = false,
    public val params: (w: Int, h: Int) -> DoubleArray
) : BenchmarkConfig

/** Benchmark variant for the turbulence family. */
public data class TurbulenceBenchmarkConfig(
    override val name: String,
    @JvmField
    public val octaves: Int,
    @JvmField
    public val fractalNoise: Boolean,
    @JvmField
    public val periodX: Int = 0,
    @JvmField
    public val periodY: Int = 0
) : BenchmarkConfig

/** Benchmark variant for kernel families with exactly one fixed configuration. */
public data class SingleVariantBenchmarkConfig(
    override val name: String
) : BenchmarkConfig

/**
 * One cell of the kernel/config/size matrix. Self-contained: the suites only need
 * this cell to dispatch ([kernel]), name and parametrize the run ([config]),
 * pick the enabled SIMD backends ([backendFlags], prefilled from `XxxNative.nativeBackend()`),
 * size the buffers ([width], [height]) and account the per-pixel traffic ([numBuffers]).
 */
public data class BenchmarkCase(
    @JvmField
    public val kernel: String,
    @JvmField
    public val config: BenchmarkConfig,
    @JvmField
    public val backendFlags: Int,
    @JvmField
    public val width: Int,
    @JvmField
    public val height: Int,
    /** ARGB buffers the family touches per pixel: 1=generate, 2=read+write, 3=two sources. */
    @JvmField
    public val numBuffers: Int
)

/**
 * Kernel/config/size matrix shared by the host and device benchmark suites.
 *
 * ConvolveMatrix is always measured at 5x5 (25 taps): it is the heavier workload
 * and the device suite's explicit intent (a 9-element 3x3 kernel was the original
 * bug here). Keeping one order means host and device MPix/s are comparable.
 */
public object KernelBenchmarkMatrix {

    public val morphologyConfigs: List<MorphologyBenchmarkConfig> = listOf(
        MorphologyBenchmarkConfig("Morphology (erode, r=1)", 1, 1, erode = true),
        MorphologyBenchmarkConfig("Morphology (erode, r=5)", 5, 5, erode = true),
        MorphologyBenchmarkConfig("Morphology (dilate, r=5)", 5, 5, erode = false),
    )

    public val convolveConfigs: List<ConvolveBenchmarkConfig> = listOf(
        ConvolveBenchmarkConfig(
            "ConvolveMatrix (duplicate, alpha)",
            5, 5, preserveAlpha = true, edgeMode = 0,
            kernel = FloatArray(25) { 0.11f }
        ),
        ConvolveBenchmarkConfig(
            "ConvolveMatrix (duplicate, no-alpha)",
            5, 5, preserveAlpha = false, edgeMode = 0,
            kernel = FloatArray(25) { 0.11f }
        ),
    )

    public val arithmeticCompositeConfigs: List<ArithmeticCompositeBenchmarkConfig> = listOf(
        ArithmeticCompositeBenchmarkConfig("ArithmeticComposite (non-linear)", useLinear = false),
        ArithmeticCompositeBenchmarkConfig("ArithmeticComposite (linear)", useLinear = true),
    )

    public val lightingConfigs: List<LightingBenchmarkConfig> = listOf(
        LightingBenchmarkConfig(
            "Lighting (diffuse, distant)",
            LightType.DISTANT,
            specular = false,
            useLinear = false
        ) { _, _ -> doubleArrayOf(45.0, 45.0) },
        LightingBenchmarkConfig(
            "Lighting (specular, distant)",
            LightType.DISTANT,
            specular = true,
            exponent = 20f,
            useLinear = false
        ) { _, _ -> doubleArrayOf(45.0, 45.0) },
    )

    public val turbulenceConfigs: List<TurbulenceBenchmarkConfig> = listOf(
        TurbulenceBenchmarkConfig("Turbulence (turbulence, 1 oct)", octaves = 1, fractalNoise = false),
    )

    /** Kernel families with exactly one case and no per-variant parameters. */
    private val singleCaseKernels: Map<String, String> = linkedMapOf(
        "UnLinearize" to "UnLinearize",
        "ComponentTransfer" to "ComponentTransfer",
        "DisplacementMap" to "DisplacementMap",
        "GaussianBlur" to "GaussianBlur",
    )

    /** SIMD backend flags for a kernel family (see `XxxNative.nativeBackend()`). */
    private fun backendFlags(kernel: String): Int =
        when (kernel) {
            "UnLinearize" -> UnLinearizeNative.nativeBackend()
            "ComponentTransfer" -> ComponentTransferNative.nativeBackend()
            "Morphology" -> MorphologyNative.nativeBackend()
            "ArithmeticComposite" -> ArithmeticCompositeNative.nativeBackend()
            "ConvolveMatrix" -> ConvolveNative.nativeBackend()
            "DisplacementMap" -> DisplacementMapNative.nativeBackend()
            "Lighting" -> LightingNative.nativeBackend()
            "Turbulence" -> TurbulenceNative.nativeBackend()
            "GaussianBlur" -> NativeGaussianBlur.nativeBackend(5f, 5f)
            else -> error("Unknown kernel family: $kernel")
        }

    /** ARGB buffers read/written per pixel by a kernel family (1=generate, 3=two sources). */
    private fun numBuffers(kernel: String): Int =
        when (kernel) {
            "ArithmeticComposite", "DisplacementMap" -> 3
            "Turbulence" -> 1
            "UnLinearize", "ComponentTransfer", "Morphology", "ConvolveMatrix",
            "Lighting", "GaussianBlur" -> 2
            else -> error("Unknown kernel family: $kernel")
        }

    /**
     * Builds the kernel/config/size matrix: one [BenchmarkCase] per (kernel, variant, size)
     * triple, optionally restricted to [kernels] and/or [configs] and sorted alphabetically by
     * case name.
     *
     * [kernels] is an exact kernel-family name filter ("Lighting"). [configs] is a set of
     * case-insensitive substrings matched against the cell display name
     * ([BenchmarkConfig.name], e.g. "Lighting (diffuse, distant, linear)"); a config is kept
     * when any of its filters is a substring of the name, which makes both partial ("linear")
     * and full-name selectors work. When both filters are given they are ANDed.
     */
    public fun cases(
        kernels: Set<String>?,
        sizes: Array<Pair<Int, Int>>,
        configs: Set<String>? = null
    ): List<BenchmarkCase> {
        val families: List<Pair<String, BenchmarkConfig>> = buildList {
            for ((kernel, name) in singleCaseKernels) {
                add(kernel to SingleVariantBenchmarkConfig(name))
            }
            for (config in morphologyConfigs) {
                add("Morphology" to config)
            }
            for (config in convolveConfigs) {
                add("ConvolveMatrix" to config)
            }
            for (config in arithmeticCompositeConfigs) {
                add("ArithmeticComposite" to config)
            }
            for (config in lightingConfigs) {
                add("Lighting" to config)
            }
            for (config in turbulenceConfigs) {
                add("Turbulence" to config)
            }
        }
        val all: List<BenchmarkCase> = buildList {
            for ((kernel, config) in families) {
                for ((w, h) in sizes) {
                    add(BenchmarkCase(kernel, config, backendFlags(kernel), w, h, numBuffers(kernel)))
                }
            }
        }
        val selected = all.filter { case ->
            (kernels.isNullOrEmpty() || kernels.contains(case.kernel)) &&
                (configs.isNullOrEmpty() || configs.any { case.config.name.contains(it, ignoreCase = true) })
        }
        return selected.sortedBy { it.config.name }
    }
}