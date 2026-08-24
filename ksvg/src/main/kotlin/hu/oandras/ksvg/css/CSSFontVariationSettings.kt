/*
 *    Copyright 2013-2020 Paul LeBeau, Cave Rock Software Ltd.
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
@file:OptIn(ExperimentalContracts::class)

package hu.oandras.ksvg.css

import hu.oandras.ksvg.parser.TextScanner
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.*
import kotlin.contracts.ExperimentalContracts
import kotlin.contracts.contract

@ConsistentCopyVisibility
internal data class CSSFontVariationSettings private constructor(
    @JvmField
    val weight: Float,
    @JvmField
    val italic: Float,
    @JvmField
    val slant: Float,
    @JvmField
    val width: Float
) {

    private constructor() : this(
        weight = Float.NaN,
        italic = Float.NaN,
        slant = Float.NaN,
        width = Float.NaN
    )

    constructor(
        weight: Float,
        width: Float,
    ): this(
        weight = weight,
        italic = Float.NaN,
        slant = Float.NaN,
        width = width,
    )

    fun toBuilder(): Builder = Builder().apply { reset(this@CSSFontVariationSettings) }

    class Builder {
        private lateinit var original: CSSFontVariationSettings
        private var weight: Float = Float.NaN
        private var italic: Float = Float.NaN
        private var slant: Float = Float.NaN
        private var width: Float = Float.NaN

        fun reset(original: CSSFontVariationSettings) {
            this.original = original
            this.weight = original.weight
            this.italic = original.italic
            this.slant = original.slant
            this.width = original.width
        }

        fun addSetting(
            key: String,
            value: Float
        ) {
            when (key) {
                VARIATION_WEIGHT -> weight = value
                VARIATION_ITALIC -> italic = value
                VARIATION_SLANT -> slant = value
                VARIATION_WIDTH -> width = value
            }
        }

        fun addSettings(other: CSSFontVariationSettings?) {
            if (other == null) return

            if (!other.weight.isNaN()) weight = other.weight
            if (!other.italic.isNaN()) italic = other.italic
            if (!other.slant.isNaN()) slant = other.slant
            if (!other.width.isNaN()) width = other.width
        }

        fun applySettings(other: CSSFontVariationSettings?) {
            if (other == null) return

            weight = other.weight
            italic = other.italic
            slant = other.slant
            width = other.width
        }

        private var lastBuilt: CSSFontVariationSettings? = null
        fun build(): CSSFontVariationSettings {
            val original = original
            if (dataIsEqualsWith(original)) {
                return original
            }

            val lastBuilt = lastBuilt
            if (dataIsEqualsWith(lastBuilt)) {
                return lastBuilt
            }

            return CSSFontVariationSettings(
                weight = weight,
                italic = italic,
                slant = slant,
                width = width
            ).also {
                this.lastBuilt = it
            }
        }

        private fun dataIsEqualsWith(settings: CSSFontVariationSettings?): Boolean {
            contract {
                returns(true) implies (settings != null)
            }

            return settings != null &&
                    (weight == settings.weight || (weight.isNaN() && settings.weight.isNaN())) &&
                    (italic == settings.italic || (italic.isNaN() && settings.italic.isNaN())) &&
                    (slant == settings.slant || (slant.isNaN() && settings.slant.isNaN())) &&
                    (width == settings.width || (width.isNaN() && settings.width.isNaN()))
        }
    }

    override fun toString(): String {
        return buildString {
            appendSetting(
                key = VARIATION_WEIGHT,
                value = weight,
            )

            appendSetting(
                key = VARIATION_ITALIC,
                value = italic,
            )

            appendSetting(
                key = VARIATION_SLANT,
                value = slant,
            )

            appendSetting(
                key = VARIATION_WIDTH,
                value = width,
            )
        }
    }

    private fun StringBuilder.appendSetting(
        key: String,
        value: Float,
    ) {
        if (value.isNaN()) return

        if (isNotEmpty()) {
            append(',')
        }

        append('\'')
        append(key)
        append("' ")
        append(format.get()!!.format(value.toDouble()))
    }

    companion object {

        private const val NORMAL = "normal"

        const val VARIATION_WEIGHT: String = "wght"
        const val VARIATION_ITALIC: String = "ital"
        const val VARIATION_SLANT: String = "slnt"
        const val VARIATION_WIDTH: String = "wdth"

        const val VARIATION_ITALIC_VALUE_ON: Float = 1f
        const val VARIATION_OBLIQUE_VALUE_ON: Float = -14f // -14 degrees

        @JvmField
        val EMPTY = CSSFontVariationSettings()

        private val format = ThreadLocal.withInitial {
            DecimalFormat("#.##", DecimalFormatSymbols(Locale.US))
        }

        // -----------------------------------------------------------------------------------------------
        // Parsing font-variation-settings property value

        /*
         * Parse the value of the CSS property "font-variation-settings".
         *
         * Format is: normal | [ <string> <number>]#
         */
        fun parseFontVariationSettings(
            value: String
        ): CSSFontVariationSettings? {
            val scan = TextScanner(value)
            scan.skipWhitespace()

            if (scan.consume(NORMAL)) {
                return null
            }

            val builder = EMPTY.toBuilder()

            while (!scan.empty()) {
                scan.skipWhitespace()

                val name = scan.nextQuotedString()
                    ?: return null

                if (name.length != 4) {
                    return null
                }

                scan.skipWhitespace()

                if (scan.empty()) {
                    return null
                }

                val num = scan.nextFloat()

                if (num.isNaN()) {
                    return null
                }

                builder.addSetting(name, num)
                scan.skipCommaWhitespace()
            }

            return builder.build()
        }
    }
}