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

import androidx.collection.MutableObjectIntMap
import hu.oandras.ksvg.dom.Style
import hu.oandras.ksvg.parser.TextScanner
import hu.oandras.ksvg.utils.copyIfNotEmpty

/*
 * Keeps a list of font feature settings and their values.
 */
internal class CSSFontFeatureSettings private constructor(
    private var settings: MutableObjectIntMap<String>?
) {

    private fun ensureSettings(): MutableObjectIntMap<String> {
        return settings ?: MutableObjectIntMap<String>(1).also {
            settings = it
        }
    }

    constructor() : this(
        settings = null
    )

    constructor(initialCapacity: Int) : this(
        settings = MutableObjectIntMap(initialCapacity)
    )

    constructor(other: CSSFontFeatureSettings) : this(
        settings = other.settings.copyIfNotEmpty()
    )

    fun applySettings(other: CSSFontFeatureSettings?) {
        val otherSettings = other?.settings

        if (otherSettings == null || otherSettings.isEmpty()) return

        val settings = settings
        if (settings == null) {
            this.settings = otherSettings.copyIfNotEmpty()
        } else {
            settings.putAll(otherSettings)
        }
    }

    fun applyKerning(kern: Style.FontKerning?) {
        ensureSettings()[FEATURE_KERN] = if (kern == Style.FontKerning.none) {
            VALUE_OFF
        } else {
            VALUE_ON
        }
    }

    override fun toString(): String {
        val sb = StringBuilder()
        settings?.forEach { key, value ->
            if (sb.isNotEmpty()) {
                sb.append(',')
            }
            sb.append('\'')
            sb.append(key)
            sb.append("' ")
            sb.append(value)
        }
        return sb.toString()
    }

    private fun addSetting(feature: String, onOrOff: Int) {
        ensureSettings()[feature] = onOrOff
    }

    private fun addSettings(feature1: String, feature2: String, onOrOff: Int) {
        val settings = ensureSettings()
        settings[feature1] = onOrOff
        settings[feature2] = onOrOff
    }

    @Suppress("SpellCheckingInspection")
    companion object {
        @JvmField
        val FONT_FEATURE_SETTINGS_NORMAL: CSSFontFeatureSettings = run {
            // See: https://www.w3.org/TR/css-fonts-3/#default-features
            val result = CSSFontFeatureSettings(8).apply {
                addSetting("rlig", VALUE_ON)
                addSetting("liga", VALUE_ON)
                addSetting("clig", VALUE_ON)
                addSetting("calt", VALUE_ON)
                addSetting("locl", VALUE_ON)
                addSetting("ccmp", VALUE_ON)
                addSetting("mark", VALUE_ON)
                addSetting("mkmk", VALUE_ON)
            }
            // TODO FIXME  also enable "vert" for vertical runs in complex scripts
            result
        }

        @JvmField
        val ERROR: CSSFontFeatureSettings = CSSFontFeatureSettings()

        const val FONT_VARIANT_NORMAL: String = "normal"
        private const val FONT_VARIANT_AUTO = "auto"
        private const val FONT_VARIANT_NONE = "none"

        private const val FEATURE_ON = "on"
        private const val FEATURE_OFF = "off"

        private const val VALUE_ON = 1
        private const val VALUE_OFF = 0

        private const val TOKEN_ERROR = "ERR"

        // For font-kerning
        const val FEATURE_KERN: String = "kern"

        // For font-variant-ligatures
        @JvmField
        val LIGATURES_NORMAL: CSSFontFeatureSettings = CSSFontFeatureSettings(5).apply {
            addSetting(FEATURE_LIGA, VALUE_ON)
            addSetting(FEATURE_CLIG, VALUE_ON)
            addSetting(FEATURE_DLIG, VALUE_OFF)
            addSetting(FEATURE_HLIG, VALUE_OFF)
            addSetting(FEATURE_CALT, VALUE_ON)
        }

        private val LIGATURES_ALL_OFF: CSSFontFeatureSettings = CSSFontFeatureSettings(5).apply {
            addSetting("liga", VALUE_OFF)
            addSetting("clig", VALUE_OFF)
            addSetting("dlig", VALUE_OFF)
            addSetting("hlig", VALUE_OFF)
            addSetting("calt", VALUE_OFF)
        }

        private const val FONT_VARIANT_COMMON_LIGATURES = "common-ligatures"
        private const val FONT_VARIANT_NO_COMMON_LIGATURES = "no-common-ligatures"
        private const val FONT_VARIANT_DISCRETIONARY_LIGATURES = "discretionary-ligatures"
        private const val FONT_VARIANT_NO_DISCRETIONARY_LIGATURES = "no-discretionary-ligatures"
        private const val FONT_VARIANT_HISTORICAL_LIGATURES = "historical-ligatures"
        private const val FONT_VARIANT_NO_HISTORICAL_LIGATURES = "no-historical-ligatures"
        private const val FONT_VARIANT_CONTEXTUAL_LIGATURES = "contextual"
        private const val FONT_VARIANT_NO_CONTEXTUAL_LIGATURES = "no-contextual"

        const val FEATURE_CLIG: String = "clig"
        const val FEATURE_LIGA: String = "liga"
        const val FEATURE_DLIG: String = "dlig"
        const val FEATURE_HLIG: String = "hlig"
        const val FEATURE_CALT: String = "calt"

        // For font-variant-position
        @JvmField
        val POSITION_ALL_OFF: CSSFontFeatureSettings = CSSFontFeatureSettings(2).apply {
            addSetting(FEATURE_SUBS, VALUE_OFF)
            addSetting(FEATURE_SUPS, VALUE_OFF)
        }

        private const val FONT_VARIANT_SUB = "sub"
        private const val FONT_VARIANT_SUPER = "super"

        private const val FEATURE_SUBS = "subs"
        private const val FEATURE_SUPS = "sups"

        // For font-variant-caps
        @JvmField
        val CAPS_ALL_OFF: CSSFontFeatureSettings = CSSFontFeatureSettings(6).apply {
            addSetting(FEATURE_SMCP, VALUE_OFF)
            addSetting(FEATURE_C2SC, VALUE_OFF)
            addSetting(FEATURE_PCAP, VALUE_OFF)
            addSetting(FEATURE_C2PC, VALUE_OFF)
            addSetting(FEATURE_UNIC, VALUE_OFF)
            addSetting(FEATURE_TITL, VALUE_OFF)
        }

        @JvmField
        val CAPS_SMALL_CAPS: CSSFontFeatureSettings = CSSFontFeatureSettings(6).apply {
            addSetting(FEATURE_SMCP, VALUE_ON)
            addSetting(FEATURE_C2SC, VALUE_OFF)
            addSetting(FEATURE_PCAP, VALUE_OFF)
            addSetting(FEATURE_C2PC, VALUE_OFF)
            addSetting(FEATURE_UNIC, VALUE_OFF)
            addSetting(FEATURE_TITL, VALUE_OFF)
        }

        const val FONT_VARIANT_SMALL_CAPS: String = "small-caps"
        private const val FONT_VARIANT_ALL_SMALL_CAPS = "all-small-caps"
        private const val FONT_VARIANT_PETITE_CAPS = "petite-caps"
        private const val FONT_VARIANT_ALL_PETITE_CAPS = "all-petite-caps"
        private const val FONT_VARIANT_UNICASE = "unicase"
        private const val FONT_VARIANT_TITLING_CAPS = "titling-caps"

        private const val FEATURE_SMCP = "smcp"
        private const val FEATURE_C2SC = "c2sc"
        private const val FEATURE_PCAP = "pcap"
        private const val FEATURE_C2PC = "c2pc"
        private const val FEATURE_UNIC = "unic"
        private const val FEATURE_TITL = "titl"

        // For font-variant-numeric
        @JvmField
        val NUMERIC_ALL_OFF: CSSFontFeatureSettings = CSSFontFeatureSettings(8).apply {
            addSetting(FEATURE_LNUM, VALUE_OFF)
            addSetting(FEATURE_ONUM, VALUE_OFF)
            addSetting(FEATURE_PNUM, VALUE_OFF)
            addSetting(FEATURE_TNUM, VALUE_OFF)
            addSetting(FEATURE_FRAC, VALUE_OFF)
            addSetting(FEATURE_AFRC, VALUE_OFF)
            addSetting(FEATURE_ORDN, VALUE_OFF)
            addSetting(FEATURE_ZERO, VALUE_OFF)
        }

        private const val FONT_VARIANT_LINING_NUMS = "lining-nums"
        private const val FONT_VARIANT_OLDSTYLE_NUMS = "oldstyle-nums"
        private const val FONT_VARIANT_PROPORTIONAL_NUMS = "proportional-nums"
        private const val FONT_VARIANT_TABULAR_NUMS = "tabular-nums"
        private const val FONT_VARIANT_DIAGONAL_FRACTIONS = "diagonal-fractions"
        private const val FONT_VARIANT_STACKED_FRACTIONS = "stacked-fractions"
        private const val FONT_VARIANT_ORDINAL = "ordinal"
        private const val FONT_VARIANT_SLASHED_ZERO = "slashed-zero"

        const val FEATURE_LNUM: String = "lnum"
        const val FEATURE_ONUM: String = "onum"
        const val FEATURE_PNUM: String = "pnum"
        const val FEATURE_TNUM: String = "tnum"
        const val FEATURE_FRAC: String = "frac"
        const val FEATURE_AFRC: String = "afrc"
        const val FEATURE_ORDN: String = "ordn"
        const val FEATURE_ZERO: String = "zero"

        // For font-variant-east-asian
        @JvmField
        val EAST_ASIAN_ALL_OFF: CSSFontFeatureSettings = CSSFontFeatureSettings(9).apply {
            addSetting(FEATURE_JP78, VALUE_OFF)
            addSetting(FEATURE_JP83, VALUE_OFF)
            addSetting(FEATURE_JP90, VALUE_OFF)
            addSetting(FEATURE_JP04, VALUE_OFF)
            addSetting(FEATURE_SMPL, VALUE_OFF)
            addSetting(FEATURE_TRAD, VALUE_OFF)
            addSetting(FEATURE_FWID, VALUE_OFF)
            addSetting(FEATURE_PWID, VALUE_OFF)
            addSetting(FEATURE_RUBY, VALUE_OFF)
        }

        private const val FONT_VARIANT_JIS78 = "jis78"
        private const val FONT_VARIANT_JIS83 = "jis83"
        private const val FONT_VARIANT_JIS90 = "jis90"
        private const val FONT_VARIANT_JIS04 = "jis04"
        private const val FONT_VARIANT_SIMPLIFIED = "simplified"
        private const val FONT_VARIANT_TRADITIONAL = "traditional"
        private const val FONT_VARIANT_FULL_WIDTH = "full-width"
        private const val FONT_VARIANT_PROPORTIONAL_WIDTH = "proportional-width"
        private const val FONT_VARIANT_RUBY = "ruby"

        const val FEATURE_JP78: String = "jp78"
        const val FEATURE_JP83: String = "jp83"
        const val FEATURE_JP90: String = "jp90"
        const val FEATURE_JP04: String = "jp04"
        const val FEATURE_SMPL: String = "smpl"
        const val FEATURE_TRAD: String = "trad"
        const val FEATURE_FWID: String = "fwid"
        const val FEATURE_PWID: String = "pwid"
        const val FEATURE_RUBY: String = "ruby"

        //-----------------------------------------------------------------------------------------------
        // Parsing font-feature-settings property value
        /**
         * Parse the value of the CSS property "font-feature-settings".
         *
         * Format is: <feature-tag-value>[comma-wsp <feature-tag-value>]*
         *            <feature-tag-value> = <string> [ <integer> | on | off ]?
         */
        fun parseFontFeatureSettings(value: String): CSSFontFeatureSettings? {
            val result = CSSFontFeatureSettings()

            val scan = TextScanner(value)
            scan.skipWhitespace()

            while (!scan.empty()) {
                if (!nextFeatureEntry(result, scan)) {
                    return null
                }
                scan.skipCommaWhitespace()
            }

            return result
        }

        private fun nextFeatureEntry(settings: CSSFontFeatureSettings, scan: TextScanner): Boolean {
            scan.skipWhitespace()
            val name = scan.nextQuotedString()
            if (name == null || name.length != 4) {
                return false
            }

            scan.skipWhitespace()
            var value = 1
            if (!scan.empty()) {
                val num = scan.nextInteger(false)
                if (num == null) {
                    if (scan.consume(FEATURE_OFF)) {
                        value = 0
                    } else {
                        scan.consume(FEATURE_ON) // "on" == 1 == default, so consume quietly if it is present
                    }
                } else {
                    value = num
                }
            }

            settings.addSetting(name, value)
            return true
        }

        //-----------------------------------------------------------------------------------------------
        // Parse a font-kerning keyword
        fun parseFontKerning(value: String): Style.FontKerning? {
            return when (value) {
                FONT_VARIANT_AUTO -> Style.FontKerning.auto
                FONT_VARIANT_NORMAL -> Style.FontKerning.normal
                FONT_VARIANT_NONE -> Style.FontKerning.none
                else -> null
            }
        }


        private fun extractTokensAsList(value: String): MutableList<String>? {
            val scan = TextScanner(value)
            scan.skipWhitespace()
            if (scan.empty()) return null
            val result = ArrayList<String>()
            while (!scan.empty()) {
                result.add(scan.requireNextToken())
                scan.skipWhitespace()
            }
            return result
        }


        /**
         * Returns:
         *   1 if token list contains token1,
         *   2 if it contains token2,
         *   3 if it contains both, or more than one of either,
         *   0 if it contains neither.
         */
        private fun containsWhich(
            tokens: MutableList<String>,
            token1: String,
            token2: String
        ): Int {
            return if (tokens.remove(token1)) {
                if (tokens.contains(token1) || tokens.contains(token2)) 3 else 1
            } else if (tokens.remove(token2)) {
                if (tokens.contains(token2)) 3 else 2
            } else {
                0
            }
        }

        /**
         * Returns:
         *   1 if token list contains token1,
         *   2 if it contains more than one token1,
         *   0 if it doesn't contain token1.
         */
        private fun containsOnce(tokens: MutableList<String>, token1: String): Int {
            return if (tokens.remove(token1)) {
                if (tokens.contains(token1)) 2 else 1
            } else {
                0
            }
        }


        /**
         * Checks haystack to see which needle is present (if any).  Returns the needle.
         * If there is more than one of the needles present, then returns null.
         */
        private fun containsOneOf(
            haystack: MutableList<String>,
            vararg needles: String
        ): String? {
            var found: String? = null
            for (needle in needles) {
                if (found == null && haystack.remove(needle)) {
                    found = needle
                }

                if (haystack.contains(needle)) {
                    return TOKEN_ERROR
                }
            }
            return found
        }


        /*
        * Parse a font-variant-ligatures property
        * Format:
        *   normal | none | [ <common-lig-values> || <discretionary-lig-values> || <historical-lig-values> || <contextual-alt-values> ]
        *   <common-lig-values>        = [ common-ligatures | no-common-ligatures ]
        *   <discretionary-lig-values> = [ discretionary-ligatures | no-discretionary-ligatures ]
        *   <historical-lig-values>    = [ historical-ligatures | no-historical-ligatures ]
        *   <contextual-alt-values>    = [ contextual | no-contextual ]
        */
        fun parseVariantLigatures(value: String): CSSFontFeatureSettings? {
            return when (value) {
                FONT_VARIANT_NORMAL -> {
                    LIGATURES_NORMAL
                }
                FONT_VARIANT_NONE -> {
                    LIGATURES_ALL_OFF
                }
                else -> {
                    val tokens: MutableList<String> =
                        extractTokensAsList(value) ?: return null // No tokens found

                    val result: CSSFontFeatureSettings? = parseVariantLigaturesSpecial(tokens)

                    // If nothing found, or duplicate keywords found, or tokens left over, then we have an error
                    if (result == null || result === ERROR || tokens.isNotEmpty()) {
                        null
                    } else {
                        result
                    }
                }
            }
        }

        private fun parseVariantLigaturesSpecial(tokens: MutableList<String>): CSSFontFeatureSettings? {
            val result = CSSFontFeatureSettings(LIGATURES_ALL_OFF)
            var found = false

            when (containsWhich(
                tokens,
                FONT_VARIANT_COMMON_LIGATURES,
                FONT_VARIANT_NO_COMMON_LIGATURES
            )) {
                1 -> {
                    result.addSettings(FEATURE_CLIG, FEATURE_LIGA, VALUE_ON)
                    found = true
                }

                2 -> {
                    result.addSettings(FEATURE_CLIG, FEATURE_LIGA, VALUE_OFF)
                    found = true
                }

                3 -> return ERROR
            }

            when (containsWhich(
                tokens,
                FONT_VARIANT_DISCRETIONARY_LIGATURES,
                FONT_VARIANT_NO_DISCRETIONARY_LIGATURES
            )) {
                1 -> {
                    result.addSetting(FEATURE_DLIG, VALUE_ON)
                    found = true
                }

                2 -> {
                    result.addSetting(FEATURE_DLIG, VALUE_OFF)
                    found = true
                }

                3 -> return ERROR
            }

            when (containsWhich(
                tokens,
                FONT_VARIANT_HISTORICAL_LIGATURES,
                FONT_VARIANT_NO_HISTORICAL_LIGATURES
            )) {
                1 -> {
                    result.addSetting(FEATURE_HLIG, VALUE_ON)
                    found = true
                }

                2 -> {
                    result.addSetting(FEATURE_HLIG, VALUE_OFF)
                    found = true
                }

                3 -> return ERROR
            }

            when (containsWhich(
                tokens,
                FONT_VARIANT_CONTEXTUAL_LIGATURES,
                FONT_VARIANT_NO_CONTEXTUAL_LIGATURES
            )) {
                1 -> {
                    result.addSetting(FEATURE_CALT, VALUE_ON)
                    found = true
                }

                2 -> {
                    result.addSetting(FEATURE_CALT, VALUE_OFF)
                    found = true
                }

                3 -> return ERROR
            }

            return if (found) {
                result
            } else {
                null
            }
        }


        // Parse a font-kerning property
        fun parseVariantPosition(value: String): CSSFontFeatureSettings? {
            return when (value) {
                FONT_VARIANT_NORMAL -> POSITION_ALL_OFF
                FONT_VARIANT_SUB -> CSSFontFeatureSettings(POSITION_ALL_OFF).apply {
                    addSetting(FEATURE_SUBS, VALUE_ON)
                }
                FONT_VARIANT_SUPER -> CSSFontFeatureSettings(POSITION_ALL_OFF).apply {
                    addSetting(FEATURE_SUPS, VALUE_ON)
                }
                else -> null
            }
        }


        // Used only by parseFontVariant()
        // Only looks for the values unique to this property
        private fun parseVariantPositionSpecial(tokens: MutableList<String>): CSSFontFeatureSettings? {
            return when (containsWhich(
                tokens = tokens,
                token1 = FONT_VARIANT_SUB,
                token2 = FONT_VARIANT_SUPER
            )) {
                1 -> {
                    val result = CSSFontFeatureSettings(POSITION_ALL_OFF)
                    result.addSetting(FEATURE_SUBS, VALUE_ON)
                    result
                }

                2 -> {
                    val result = CSSFontFeatureSettings(POSITION_ALL_OFF)
                    result.addSetting(FEATURE_SUPS, VALUE_ON)
                    result
                }

                3 -> ERROR

                else -> null
            }
        }

        // Parse a font-variant-caps property
        fun parseVariantCaps(value: String): CSSFontFeatureSettings? {
            return if (value == FONT_VARIANT_NORMAL) {
                CAPS_ALL_OFF
            } else {
                val result = CSSFontFeatureSettings(CAPS_ALL_OFF)
                if (setCapsFeature(result, value)) {
                    result
                } else {
                    null
                }
            }
        }

        private fun setCapsFeature(result: CSSFontFeatureSettings, value: String): Boolean {
            when (value) {
                FONT_VARIANT_SMALL_CAPS -> result.addSetting(FEATURE_SMCP, VALUE_ON)
                FONT_VARIANT_ALL_SMALL_CAPS -> result.addSettings(
                    FEATURE_SMCP,
                    FEATURE_C2SC,
                    VALUE_ON
                )

                FONT_VARIANT_PETITE_CAPS -> result.addSetting(FEATURE_PCAP, VALUE_ON)
                FONT_VARIANT_ALL_PETITE_CAPS -> result.addSettings(
                    FEATURE_PCAP,
                    FEATURE_C2PC,
                    VALUE_ON
                )

                FONT_VARIANT_UNICASE -> result.addSetting(FEATURE_UNIC, VALUE_ON)
                FONT_VARIANT_TITLING_CAPS -> result.addSetting(FEATURE_TITL, VALUE_ON)
                else -> return false
            }
            return true
        }

        // Used only by parseFontVariant()
        // Only looks for the values unique to this property
        private fun parseVariantCapsSpecial(tokens: MutableList<String>): CSSFontFeatureSettings? {
            val which: String? = containsOneOf(
                tokens,
                FONT_VARIANT_SMALL_CAPS,
                FONT_VARIANT_ALL_SMALL_CAPS,
                FONT_VARIANT_PETITE_CAPS,
                FONT_VARIANT_ALL_PETITE_CAPS,
                FONT_VARIANT_UNICASE,
                FONT_VARIANT_TITLING_CAPS
            )

            return when (which) {
                TOKEN_ERROR -> ERROR
                null -> null
                else -> {
                    val result = CSSFontFeatureSettings(CAPS_ALL_OFF)
                    setCapsFeature(result, which)
                    result
                }
            }
        }

        /**
         * Parse a font-variant-numeric property
         * Format:
         *   normal | [ <numeric-figure-values> || <numeric-spacing-values> || <numeric-fraction-values> || ordinal || slashed-zero ]
         *   <numeric-figure-values>   = [ lining-nums | oldstyle-nums ]
         *   <numeric-spacing-values>  = [ proportional-nums | tabular-nums ]
         *   <numeric-fraction-values> = [ diagonal-fractions | stacked-fractions ]
         */
        fun parseVariantNumeric(value: String): CSSFontFeatureSettings? {
            if (value == FONT_VARIANT_NORMAL) return NUMERIC_ALL_OFF

            val tokens: MutableList<String> = extractTokensAsList(value) ?: return null

            val result: CSSFontFeatureSettings? = parseVariantNumericSpecial(tokens)

            // If nothing found, or duplicate keywords found, or tokens left over, then we have an error
            if (result == null || result === ERROR || tokens.isNotEmpty()) return null

            return result
        }


        private fun parseVariantNumericSpecial(tokens: MutableList<String>): CSSFontFeatureSettings? {
            val result = CSSFontFeatureSettings(NUMERIC_ALL_OFF)
            var found = false

            when (containsWhich(tokens, FONT_VARIANT_LINING_NUMS, FONT_VARIANT_OLDSTYLE_NUMS)) {
                1 -> {
                    result.addSetting(FEATURE_LNUM, VALUE_ON)
                    found = true
                }

                2 -> {
                    result.addSetting(FEATURE_ONUM, VALUE_ON)
                    found = true
                }

                3 -> return ERROR
            }

            when (containsWhich(
                tokens,
                FONT_VARIANT_PROPORTIONAL_NUMS,
                FONT_VARIANT_TABULAR_NUMS
            )) {
                1 -> {
                    result.addSetting(FEATURE_PNUM, VALUE_ON)
                    found = true
                }

                2 -> {
                    result.addSetting(FEATURE_TNUM, VALUE_ON)
                    found = true
                }

                3 -> return ERROR
            }

            when (containsWhich(
                tokens,
                FONT_VARIANT_DIAGONAL_FRACTIONS,
                FONT_VARIANT_STACKED_FRACTIONS
            )) {
                1 -> {
                    result.addSetting(FEATURE_FRAC, VALUE_ON)
                    found = true
                }

                2 -> {
                    result.addSetting(FEATURE_AFRC, VALUE_ON)
                    found = true
                }

                3 -> return ERROR
            }

            when (containsOnce(tokens, FONT_VARIANT_ORDINAL)) {
                1 -> {
                    result.addSetting(FEATURE_ORDN, VALUE_ON)
                    found = true
                }

                2 -> return ERROR
            }

            when (containsOnce(tokens, FONT_VARIANT_SLASHED_ZERO)) {
                1 -> {
                    result.addSetting(FEATURE_ZERO, VALUE_ON)
                    found = true
                }

                2 -> return ERROR
            }

            return if (found) result else null
        }


        /**
         * Parse a font-variant-east-asian property
         * Format:
         *   normal | [ <east-asian-variant-values> || <east-asian-width-values> || ruby ]
         *   <east-asian-variant-values> = [ jis78 | jis83 | jis90 | jis04 | simplified | traditional ]
         *   <east-asian-width-values>   = [ full-width | proportional-width ]
         */
        fun parseEastAsian(value: String): CSSFontFeatureSettings? {
            if (value == FONT_VARIANT_NORMAL) return EAST_ASIAN_ALL_OFF

            val tokens: MutableList<String> = extractTokensAsList(value) ?: return null

            val result: CSSFontFeatureSettings? = parseVariantEastAsianSpecial(tokens)

            // If nothing found, or duplicate keywords found, or tokens left over, then we have an error
            if (result == null || result === ERROR || tokens.isNotEmpty()) return null

            return result
        }


        private fun parseVariantEastAsianSpecial(tokens: MutableList<String>): CSSFontFeatureSettings? {
            val result = CSSFontFeatureSettings(EAST_ASIAN_ALL_OFF)
            var found = false

            val which: String? = containsOneOf(
                tokens, FONT_VARIANT_JIS78, FONT_VARIANT_JIS83, FONT_VARIANT_JIS90,
                FONT_VARIANT_JIS04, FONT_VARIANT_SIMPLIFIED, FONT_VARIANT_TRADITIONAL
            )
            if (which != null) {
                when (which) {
                    FONT_VARIANT_JIS78 -> result.addSetting(FEATURE_JP78, VALUE_ON)
                    FONT_VARIANT_JIS83 -> result.addSetting(FEATURE_JP83, VALUE_ON)
                    FONT_VARIANT_JIS90 -> result.addSetting(FEATURE_JP90, VALUE_ON)
                    FONT_VARIANT_JIS04 -> result.addSetting(FEATURE_JP04, VALUE_ON)
                    FONT_VARIANT_SIMPLIFIED -> result.addSetting(FEATURE_SMPL, VALUE_ON)
                    FONT_VARIANT_TRADITIONAL -> result.addSetting(FEATURE_TRAD, VALUE_ON)
                    TOKEN_ERROR -> return ERROR // more than one, or duplicate, found
                }
                found = true
            }

            when (containsWhich(tokens, FONT_VARIANT_FULL_WIDTH, FONT_VARIANT_PROPORTIONAL_WIDTH)) {
                1 -> {
                    result.addSetting(FEATURE_FWID, VALUE_ON)
                    found = true
                }

                2 -> {
                    result.addSetting(FEATURE_PWID, VALUE_ON)
                    found = true
                }

                3 -> return ERROR
            }

            when (containsOnce(tokens, FONT_VARIANT_RUBY)) {
                1 -> {
                    result.addSetting(FEATURE_RUBY, VALUE_ON)
                    found = true
                }

                2 -> return ERROR
            }

            return if (found) result else null
        }


        //-----------------------------------------------------------------------------------------------
        fun parseFontVariant(style: Style, value: String) {
            if (value == FONT_VARIANT_NORMAL) {
                style.fontVariantLigatures = LIGATURES_NORMAL
                style.fontVariantPosition = POSITION_ALL_OFF
                style.fontVariantCaps = CAPS_ALL_OFF
                style.fontVariantNumeric = NUMERIC_ALL_OFF
                style.fontVariantEastAsian = EAST_ASIAN_ALL_OFF
                style.addSpecifiedFlag(
                    Style.SPECIFIED_FONT_VARIANT_LIGATURES or Style.SPECIFIED_FONT_VARIANT_POSITION or
                            Style.SPECIFIED_FONT_VARIANT_CAPS or Style.SPECIFIED_FONT_VARIANT_NUMERIC or
                            Style.SPECIFIED_FONT_VARIANT_EAST_ASIAN
                )
                return
            } else if (value == FONT_VARIANT_NONE) {
                style.fontVariantLigatures = LIGATURES_ALL_OFF
                style.fontVariantPosition = POSITION_ALL_OFF
                style.fontVariantCaps = CAPS_ALL_OFF
                style.fontVariantNumeric = NUMERIC_ALL_OFF
                style.fontVariantEastAsian = EAST_ASIAN_ALL_OFF
                style.addSpecifiedFlag(
                    Style.SPECIFIED_FONT_VARIANT_LIGATURES or Style.SPECIFIED_FONT_VARIANT_POSITION or
                            Style.SPECIFIED_FONT_VARIANT_CAPS or Style.SPECIFIED_FONT_VARIANT_NUMERIC or
                            Style.SPECIFIED_FONT_VARIANT_EAST_ASIAN
                )
                return
            }

            val tokens: MutableList<String> = extractTokensAsList(value) ?: return

            val ligatures: CSSFontFeatureSettings? = parseVariantLigaturesSpecial(tokens)
            if (ligatures === ERROR) return

            var position: CSSFontFeatureSettings? = null
            if (tokens.isNotEmpty()) {
                position = parseVariantPositionSpecial(tokens)
                if (position === ERROR) return
            }

            var caps: CSSFontFeatureSettings? = null
            if (tokens.isNotEmpty()) {
                caps = parseVariantCapsSpecial(tokens)
                if (caps === ERROR) return
            }

            var numeric: CSSFontFeatureSettings? = null
            if (tokens.isNotEmpty()) {
                numeric = parseVariantNumericSpecial(tokens)
                if (numeric === ERROR) return
            }

            var eastAsian: CSSFontFeatureSettings? = null
            if (tokens.isNotEmpty()) {
                eastAsian = parseVariantEastAsianSpecial(tokens)
                if (eastAsian === ERROR) return
            }

            //if (tokens.size() > 0)  // Tokens left over in line?
            // Ignore them, as they may be CSS Fonts 4 keywords, for example.

            // We found some good keywords in this value
            if (ligatures != null) {
                style.fontVariantLigatures = ligatures
                style.addSpecifiedFlag(Style.SPECIFIED_FONT_VARIANT_LIGATURES)
            }

            if (position != null) {
                style.fontVariantPosition = position
                style.addSpecifiedFlag(Style.SPECIFIED_FONT_VARIANT_POSITION)
            }

            if (caps != null) {
                style.fontVariantCaps = caps
                style.addSpecifiedFlag(Style.SPECIFIED_FONT_VARIANT_CAPS)
            }

            if (numeric != null) {
                style.fontVariantNumeric = numeric
                style.addSpecifiedFlag(Style.SPECIFIED_FONT_VARIANT_NUMERIC)
            }

            if (eastAsian != null) {
                style.fontVariantEastAsian = eastAsian
                style.addSpecifiedFlag(Style.SPECIFIED_FONT_VARIANT_EAST_ASIAN)
            }
        }
    }
}
