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

package hu.oandras.ksvg.css

import androidx.collection.MutableObjectFloatMap
import hu.oandras.ksvg.parser.TextScanner
import hu.oandras.ksvg.utils.copyIfNotEmpty
import java.text.DecimalFormat

internal class CSSFontVariationSettings(
    private var settings: MutableObjectFloatMap<String>?
) {

    private class FontVariationEntry(
        @JvmField
        var name: String,
        @JvmField
        var value: Float
    )

    constructor() : this(null)

    constructor(other: CSSFontVariationSettings) : this(other.settings.copyIfNotEmpty())

    private fun ensureSettings(): MutableObjectFloatMap<String> {
        return settings ?: MutableObjectFloatMap<String>(1).also {
            settings = it
        }
    }

    fun addSetting(key: String, value: Float) {
        ensureSettings()[key] = value
    }

    fun applySettings(other: CSSFontVariationSettings?) {
        val otherSettings = other?.settings

        if (otherSettings == null || otherSettings.isEmpty()) return

        val settings = settings
        if (settings == null) {
            this.settings = otherSettings.copyIfNotEmpty()
        } else {
            settings.putAll(otherSettings)
        }
    }

    override fun toString(): String {
        return buildString {
            val format = DecimalFormat("#.##")

            settings?.forEach { key, value ->
                if (isNotEmpty()) {
                    append(',')
                }

                append('\'')
                append(key)
                append("' ")
                append(format.format(value))
            }
        }
    }

    companion object {
        private const val NORMAL = "normal"

        const val VARIATION_WEIGHT: String = "wght"
        const val VARIATION_ITALIC: String = "ital"
        const val VARIATION_SLANT: String = "slnt"
        const val VARIATION_WIDTH: String = "wdth"

        const val VARIATION_ITALIC_VALUE_ON: Float = 1f
        const val VARIATION_OBLIQUE_VALUE_ON: Float = -14f // -14 degrees


        //-----------------------------------------------------------------------------------------------
        // Parsing font-variation-settings property value
        /*
        * Parse the value of the CSS property "font-variation-settings".
        *
        * Format is: normal | [ <string> <number>]#
        */
        fun parseFontVariationSettings(value: String): CSSFontVariationSettings? {
            val scan = TextScanner(value)
            scan.skipWhitespace()

            if (scan.consume(NORMAL)) return null

            val result = MutableObjectFloatMap<String>()

            val tempEntry = FontVariationEntry("", 0f)

            while (true) {
                if (scan.empty()) break
                val entry: FontVariationEntry? = nextFeatureEntry(scan, tempEntry)
                if (entry == null || entry.value.isNaN()) break
                result[entry.name] = entry.value
                scan.skipCommaWhitespace()
            }

            return CSSFontVariationSettings(result)
        }

        private fun nextFeatureEntry(scan: TextScanner, tempEntry: FontVariationEntry): FontVariationEntry? {
            scan.skipWhitespace()
            val name = scan.nextQuotedString()
            if (name == null || name.length != 4) return null
            scan.skipWhitespace()
            if (scan.empty()) return null
            val num = scan.nextFloat()
            tempEntry.name = name
            tempEntry.value = num
            return tempEntry
        }
    }
}
