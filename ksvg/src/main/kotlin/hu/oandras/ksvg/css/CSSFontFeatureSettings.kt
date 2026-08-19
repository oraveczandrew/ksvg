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

import hu.oandras.ksvg.dom.style.FontKerning
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.parser.TextScanner
import java.util.*
import kotlin.contracts.ExperimentalContracts
import kotlin.contracts.contract

@ConsistentCopyVisibility
internal data class CSSFontFeatureSettings internal constructor(
    @JvmField
    val rlig: Boolean? = null,
    @JvmField
    val liga: Boolean? = null,
    @JvmField
    val clig: Boolean? = null,
    @JvmField
    val calt: Boolean? = null,
    @JvmField
    val locl: Boolean? = null,
    @JvmField
    val ccmp: Boolean? = null,
    @JvmField
    val mark: Boolean? = null,
    @JvmField
    val mkmk: Boolean? = null,
    @JvmField
    val kern: Boolean? = null,
    @JvmField
    val dlig: Boolean? = null,
    @JvmField
    val hlig: Boolean? = null,
    @JvmField
    val subs: Boolean? = null,
    @JvmField
    val sups: Boolean? = null,
    @JvmField
    val smcp: Boolean? = null,
    @JvmField
    val c2sc: Boolean? = null,
    @JvmField
    val pcap: Boolean? = null,
    @JvmField
    val c2pc: Boolean? = null,
    @JvmField
    val unic: Boolean? = null,
    @JvmField
    val titl: Boolean? = null,
    @JvmField
    val lnum: Boolean? = null,
    @JvmField
    val onum: Boolean? = null,
    @JvmField
    val pnum: Boolean? = null,
    @JvmField
    val tnum: Boolean? = null,
    @JvmField
    val frac: Boolean? = null,
    @JvmField
    val afrc: Boolean? = null,
    @JvmField
    val ordn: Boolean? = null,
    @JvmField
    val zero: Boolean? = null,
    @JvmField
    val jp78: Boolean? = null,
    @JvmField
    val jp83: Boolean? = null,
    @JvmField
    val jp90: Boolean? = null,
    @JvmField
    val jp04: Boolean? = null,
    @JvmField
    val smpl: Boolean? = null,
    @JvmField
    val trad: Boolean? = null,
    @JvmField
    val fwid: Boolean? = null,
    @JvmField
    val pwid: Boolean? = null,
    @JvmField
    val ruby: Boolean? = null,
    @JvmField
    val swsh: Int? = null
) {

    fun toBuilder(): Builder = Builder().apply { reset(this@CSSFontFeatureSettings) }

    internal class Builder {
        private lateinit var original: CSSFontFeatureSettings
        private var rlig: Boolean? = null
        private var liga: Boolean? = null
        private var clig: Boolean? = null
        private var calt: Boolean? = null
        private var locl: Boolean? = null
        private var ccmp: Boolean? = null
        private var mark: Boolean? = null
        private var mkmk: Boolean? = null
        private var kern: Boolean? = null
        private var dlig: Boolean? = null
        private var hlig: Boolean? = null
        private var subs: Boolean? = null
        private var sups: Boolean? = null
        private var smcp: Boolean? = null
        private var c2sc: Boolean? = null
        private var pcap: Boolean? = null
        private var c2pc: Boolean? = null
        private var unic: Boolean? = null
        private var titl: Boolean? = null
        private var lnum: Boolean? = null
        private var onum: Boolean? = null
        private var pnum: Boolean? = null
        private var tnum: Boolean? = null
        private var frac: Boolean? = null
        private var afrc: Boolean? = null
        private var ordn: Boolean? = null
        private var zero: Boolean? = null
        private var jp78: Boolean? = null
        private var jp83: Boolean? = null
        private var jp90: Boolean? = null
        private var jp04: Boolean? = null
        private var smpl: Boolean? = null
        private var trad: Boolean? = null
        private var fwid: Boolean? = null
        private var pwid: Boolean? = null
        private var ruby: Boolean? = null
        private var swsh: Int? = null

        fun reset(original: CSSFontFeatureSettings) {
            this.original = original
            this.rlig = original.rlig
            this.liga = original.liga
            this.clig = original.clig
            this.calt = original.calt
            this.locl = original.locl
            this.ccmp = original.ccmp
            this.mark = original.mark
            this.mkmk = original.mkmk
            this.kern = original.kern
            this.dlig = original.dlig
            this.hlig = original.hlig
            this.subs = original.subs
            this.sups = original.sups
            this.smcp = original.smcp
            this.c2sc = original.c2sc
            this.pcap = original.pcap
            this.c2pc = original.c2pc
            this.unic = original.unic
            this.titl = original.titl
            this.lnum = original.lnum
            this.onum = original.onum
            this.pnum = original.pnum
            this.tnum = original.tnum
            this.frac = original.frac
            this.afrc = original.afrc
            this.ordn = original.ordn
            this.zero = original.zero
            this.jp78 = original.jp78
            this.jp83 = original.jp83
            this.jp90 = original.jp90
            this.jp04 = original.jp04
            this.smpl = original.smpl
            this.trad = original.trad
            this.fwid = original.fwid
            this.pwid = original.pwid
            this.ruby = original.ruby
            this.swsh = original.swsh
        }

        fun addSettings(other: CSSFontFeatureSettings?) {
            if (other == null) return

            other.rlig?.let { rlig = it }
            other.liga?.let { liga = it }
            other.clig?.let { clig = it }
            other.calt?.let { calt = it }
            other.locl?.let { locl = it }
            other.ccmp?.let { ccmp = it }
            other.mark?.let { mark = it }
            other.mkmk?.let { mkmk = it }
            other.kern?.let { kern = it }
            other.dlig?.let { dlig = it }
            other.hlig?.let { hlig = it }
            other.subs?.let { subs = it }
            other.sups?.let { sups = it }
            other.smcp?.let { smcp = it }
            other.c2sc?.let { c2sc = it }
            other.pcap?.let { pcap = it }
            other.c2pc?.let { c2pc = it }
            other.unic?.let { unic = it }
            other.titl?.let { titl = it }
            other.lnum?.let { lnum = it }
            other.onum?.let { onum = it }
            other.pnum?.let { pnum = it }
            other.tnum?.let { tnum = it }
            other.frac?.let { frac = it }
            other.afrc?.let { afrc = it }
            other.ordn?.let { ordn = it }
            other.zero?.let { zero = it }
            other.jp78?.let { jp78 = it }
            other.jp83?.let { jp83 = it }
            other.jp90?.let { jp90 = it }
            other.jp04?.let { jp04 = it }
            other.smpl?.let { smpl = it }
            other.trad?.let { trad = it }
            other.fwid?.let { fwid = it }
            other.pwid?.let { pwid = it }
            other.ruby?.let { ruby = it }
            other.swsh?.let { swsh = it }
        }

        fun applySettings(other: CSSFontFeatureSettings?) {
            if (other == null) return

            rlig = other.rlig
            liga = other.liga
            clig = other.clig
            calt = other.calt
            locl = other.locl
            ccmp = other.ccmp
            mark = other.mark
            mkmk = other.mkmk
            kern = other.kern
            dlig = other.dlig
            hlig = other.hlig
            subs = other.subs
            sups = other.sups
            smcp = other.smcp
            c2sc = other.c2sc
            pcap = other.pcap
            c2pc = other.c2pc
            unic = other.unic
            titl = other.titl
            lnum = other.lnum
            onum = other.onum
            pnum = other.pnum
            tnum = other.tnum
            frac = other.frac
            afrc = other.afrc
            ordn = other.ordn
            zero = other.zero
            jp78 = other.jp78
            jp83 = other.jp83
            jp90 = other.jp90
            jp04 = other.jp04
            smpl = other.smpl
            trad = other.trad
            fwid = other.fwid
            pwid = other.pwid
            ruby = other.ruby
            swsh = other.swsh
        }

        fun applyKerning(kern: FontKerning?) {
            setSetting(
                FEATURE_KERN,
                kern != FontKerning.none
            )
        }

        fun addSetting(
            feature: String,
            onOrOff: Int
        ) {
            if (feature == FEATURE_SWSH) {
                swsh = onOrOff
            } else {
                setSetting(feature, onOrOff != VALUE_OFF)
            }
        }

        fun addSettings(
            feature1: String,
            feature2: String,
            onOrOff: Int
        ) {
            val value = onOrOff != VALUE_OFF
            setSetting(feature1, value)
            setSetting(feature2, value)
        }

        private fun setSetting(
            feature: String,
            value: Boolean
        ) {
            when (feature) {
                FEATURE_RLIG -> rlig = value
                FEATURE_LIGA -> liga = value
                FEATURE_CLIG -> clig = value
                FEATURE_CALT -> calt = value
                FEATURE_LOCL -> locl = value
                FEATURE_CCMP -> ccmp = value
                FEATURE_MARK -> mark = value
                FEATURE_MKMK -> mkmk = value
                FEATURE_KERN -> kern = value

                FEATURE_DLIG -> dlig = value
                FEATURE_HLIG -> hlig = value

                FEATURE_SUBS -> subs = value
                FEATURE_SUPS -> sups = value

                FEATURE_SMCP -> smcp = value
                FEATURE_C2SC -> c2sc = value
                FEATURE_PCAP -> pcap = value
                FEATURE_C2PC -> c2pc = value
                FEATURE_UNIC -> unic = value
                FEATURE_TITL -> titl = value

                FEATURE_LNUM -> lnum = value
                FEATURE_ONUM -> onum = value
                FEATURE_PNUM -> pnum = value
                FEATURE_TNUM -> tnum = value
                FEATURE_FRAC -> frac = value
                FEATURE_AFRC -> afrc = value
                FEATURE_ORDN -> ordn = value
                FEATURE_ZERO -> zero = value

                FEATURE_JP78 -> jp78 = value
                FEATURE_JP83 -> jp83 = value
                FEATURE_JP90 -> jp90 = value
                FEATURE_JP04 -> jp04 = value
                FEATURE_SMPL -> smpl = value
                FEATURE_TRAD -> trad = value
                FEATURE_FWID -> fwid = value
                FEATURE_PWID -> pwid = value
                FEATURE_RUBY -> ruby = value
            }
        }

        private var lastBuilt: CSSFontFeatureSettings? = null
        fun build(): CSSFontFeatureSettings {
            val original = original
            if (dataIsEqualsWith(original)) {
                return original
            }

            val lastBuilt = lastBuilt
            if (dataIsEqualsWith(lastBuilt)) {
                return lastBuilt
            }

            return CSSFontFeatureSettings(
                rlig = rlig,
                liga = liga,
                clig = clig,
                calt = calt,
                locl = locl,
                ccmp = ccmp,
                mark = mark,
                mkmk = mkmk,
                kern = kern,
                dlig = dlig,
                hlig = hlig,
                subs = subs,
                sups = sups,
                smcp = smcp,
                c2sc = c2sc,
                pcap = pcap,
                c2pc = c2pc,
                unic = unic,
                titl = titl,
                lnum = lnum,
                onum = onum,
                pnum = pnum,
                tnum = tnum,
                frac = frac,
                afrc = afrc,
                ordn = ordn,
                zero = zero,
                jp78 = jp78,
                jp83 = jp83,
                jp90 = jp90,
                jp04 = jp04,
                smpl = smpl,
                trad = trad,
                fwid = fwid,
                pwid = pwid,
                ruby = ruby,
                swsh = swsh
            ).also {
                this.lastBuilt = it
            }
        }

        private fun dataIsEqualsWith(settings: CSSFontFeatureSettings?): Boolean {
            contract {
                returns(true) implies (settings != null)
            }

            return settings != null &&
                    rlig == settings.rlig &&
                    liga == settings.liga &&
                    clig == settings.clig &&
                    calt == settings.calt &&
                    locl == settings.locl &&
                    ccmp == settings.ccmp &&
                    mark == settings.mark &&
                    mkmk == settings.mkmk &&
                    kern == settings.kern &&
                    dlig == settings.dlig &&
                    hlig == settings.hlig &&
                    subs == settings.subs &&
                    sups == settings.sups &&
                    smcp == settings.smcp &&
                    c2sc == settings.c2sc &&
                    pcap == settings.pcap &&
                    c2pc == settings.c2pc &&
                    unic == settings.unic &&
                    titl == settings.titl &&
                    lnum == settings.lnum &&
                    onum == settings.onum &&
                    pnum == settings.pnum &&
                    tnum == settings.tnum &&
                    frac == settings.frac &&
                    afrc == settings.afrc &&
                    ordn == settings.ordn &&
                    zero == settings.zero &&
                    jp78 == settings.jp78 &&
                    jp83 == settings.jp83 &&
                    jp90 == settings.jp90 &&
                    jp04 == settings.jp04 &&
                    smpl == settings.smpl &&
                    trad == settings.trad &&
                    fwid == settings.fwid &&
                    pwid == settings.pwid &&
                    ruby == settings.ruby &&
                    swsh == settings.swsh
        }
    }

    override fun toString(): String {
        val sb = StringBuilder()

        appendSetting(sb, FEATURE_RLIG, rlig)
        appendSetting(sb, FEATURE_LIGA, liga)
        appendSetting(sb, FEATURE_CLIG, clig)
        appendSetting(sb, FEATURE_CALT, calt)
        appendSetting(sb, FEATURE_LOCL, locl)
        appendSetting(sb, FEATURE_CCMP, ccmp)
        appendSetting(sb, FEATURE_MARK, mark)
        appendSetting(sb, FEATURE_MKMK, mkmk)
        appendSetting(sb, FEATURE_KERN, kern)
        appendSetting(sb, FEATURE_DLIG, dlig)
        appendSetting(sb, FEATURE_HLIG, hlig)
        appendSetting(sb, FEATURE_SUBS, subs)
        appendSetting(sb, FEATURE_SUPS, sups)
        appendSetting(sb, FEATURE_SMCP, smcp)
        appendSetting(sb, FEATURE_C2SC, c2sc)
        appendSetting(sb, FEATURE_PCAP, pcap)
        appendSetting(sb, FEATURE_C2PC, c2pc)
        appendSetting(sb, FEATURE_UNIC, unic)
        appendSetting(sb, FEATURE_TITL, titl)
        appendSetting(sb, FEATURE_LNUM, lnum)
        appendSetting(sb, FEATURE_ONUM, onum)
        appendSetting(sb, FEATURE_PNUM, pnum)
        appendSetting(sb, FEATURE_TNUM, tnum)
        appendSetting(sb, FEATURE_FRAC, frac)
        appendSetting(sb, FEATURE_AFRC, afrc)
        appendSetting(sb, FEATURE_ORDN, ordn)
        appendSetting(sb, FEATURE_ZERO, zero)
        appendSetting(sb, FEATURE_JP78, jp78)
        appendSetting(sb, FEATURE_JP83, jp83)
        appendSetting(sb, FEATURE_JP90, jp90)
        appendSetting(sb, FEATURE_JP04, jp04)
        appendSetting(sb, FEATURE_SMPL, smpl)
        appendSetting(sb, FEATURE_TRAD, trad)
        appendSetting(sb, FEATURE_FWID, fwid)
        appendSetting(sb, FEATURE_PWID, pwid)
        appendSetting(sb, FEATURE_RUBY, ruby)
        swsh?.let {
            if (sb.isNotEmpty()) {
                sb.append(',')
            }
            sb.append('\'')
            sb.append(FEATURE_SWSH)
            sb.append("' ")
            sb.append(it)
        }

        return sb.toString()
    }

    private fun appendSetting(
        sb: StringBuilder,
        feature: String,
        value: Boolean?
    ) {
        if (value == null) return

        if (sb.isNotEmpty()) {
            sb.append(',')
        }

        sb.append('\'')
        sb.append(feature)
        sb.append("' ")
        sb.append(if (value) VALUE_ON else VALUE_OFF)
    }

    @Suppress("SpellCheckingInspection")
    companion object {

        private const val FEATURE_RLIG = "rlig"
        private const val FEATURE_LOCL = "locl"
        private const val FEATURE_CCMP = "ccmp"
        private const val FEATURE_MARK = "mark"
        private const val FEATURE_MKMK = "mkmk"

        @JvmField
        val EMPTY = CSSFontFeatureSettings()

        // TODO FIXME also enable "vert" for vertical runs in complex scripts
        @JvmField
        val FONT_FEATURE_SETTINGS_NORMAL: CSSFontFeatureSettings =
            CSSFontFeatureSettings(
                rlig = true,
                liga = true,
                clig = true,
                calt = true,
                locl = true,
                ccmp = true,
                mark = true,
                mkmk = true
            )

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
        val LIGATURES_NORMAL: CSSFontFeatureSettings =
            CSSFontFeatureSettings(
                liga = true,
                clig = true,
                dlig = false,
                hlig = false,
                calt = true
            )

        private val LIGATURES_ALL_OFF: CSSFontFeatureSettings =
            CSSFontFeatureSettings(
                liga = false,
                clig = false,
                dlig = false,
                hlig = false,
                calt = false
            )

        private const val FONT_VARIANT_COMMON_LIGATURES =
            "common-ligatures"

        private const val FONT_VARIANT_NO_COMMON_LIGATURES =
            "no-common-ligatures"

        private const val FONT_VARIANT_DISCRETIONARY_LIGATURES =
            "discretionary-ligatures"

        private const val FONT_VARIANT_NO_DISCRETIONARY_LIGATURES =
            "no-discretionary-ligatures"

        private const val FONT_VARIANT_HISTORICAL_LIGATURES =
            "historical-ligatures"

        private const val FONT_VARIANT_NO_HISTORICAL_LIGATURES =
            "no-historical-ligatures"

        private const val FONT_VARIANT_CONTEXTUAL_LIGATURES =
            "contextual"

        private const val FONT_VARIANT_NO_CONTEXTUAL_LIGATURES =
            "no-contextual"

        const val FEATURE_CLIG: String = "clig"
        const val FEATURE_LIGA: String = "liga"
        const val FEATURE_DLIG: String = "dlig"
        const val FEATURE_HLIG: String = "hlig"
        const val FEATURE_CALT: String = "calt"

        // For font-variant-position

        @JvmField
        val POSITION_ALL_OFF: CSSFontFeatureSettings =
            CSSFontFeatureSettings(
                subs = false,
                sups = false
            )

        private const val FONT_VARIANT_SUB = "sub"
        private const val FONT_VARIANT_SUPER = "super"

        private const val FEATURE_SUBS = "subs"
        private const val FEATURE_SUPS = "sups"

        // For font-variant-caps
        @JvmField
        val CAPS_ALL_OFF: CSSFontFeatureSettings =
            CSSFontFeatureSettings(
                smcp = false,
                c2sc = false,
                pcap = false,
                c2pc = false,
                unic = false,
                titl = false
            )

        @JvmField
        val CAPS_SMALL_CAPS: CSSFontFeatureSettings =
            CSSFontFeatureSettings(
                smcp = true,
                c2sc = false,
                pcap = false,
                c2pc = false,
                unic = false,
                titl = false
            )

        const val FONT_VARIANT_SMALL_CAPS: String = "small-caps"

        private const val FONT_VARIANT_ALL_SMALL_CAPS =
            "all-small-caps"

        private const val FONT_VARIANT_PETITE_CAPS =
            "petite-caps"

        private const val FONT_VARIANT_ALL_PETITE_CAPS =
            "all-petite-caps"

        private const val FONT_VARIANT_UNICASE =
            "unicase"

        private const val FONT_VARIANT_TITLING_CAPS =
            "titling-caps"

        private const val FEATURE_SMCP = "smcp"
        private const val FEATURE_C2SC = "c2sc"
        private const val FEATURE_PCAP = "pcap"
        private const val FEATURE_C2PC = "c2pc"
        private const val FEATURE_UNIC = "unic"
        private const val FEATURE_TITL = "titl"

        // For font-variant-numeric
        @JvmField
        val NUMERIC_ALL_OFF: CSSFontFeatureSettings =
            CSSFontFeatureSettings(
                lnum = false,
                onum = false,
                pnum = false,
                tnum = false,
                frac = false,
                afrc = false,
                ordn = false,
                zero = false
            )

        private const val FONT_VARIANT_LINING_NUMS = "lining-nums"
        private const val FONT_VARIANT_OLDSTYLE_NUMS = "oldstyle-nums"
        private const val FONT_VARIANT_PROPORTIONAL_NUMS =
            "proportional-nums"

        private const val FONT_VARIANT_TABULAR_NUMS =
            "tabular-nums"

        private const val FONT_VARIANT_DIAGONAL_FRACTIONS =
            "diagonal-fractions"

        private const val FONT_VARIANT_STACKED_FRACTIONS =
            "stacked-fractions"

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
        val EAST_ASIAN_ALL_OFF: CSSFontFeatureSettings =
            CSSFontFeatureSettings(
                jp78 = false,
                jp83 = false,
                jp90 = false,
                jp04 = false,
                smpl = false,
                trad = false,
                fwid = false,
                pwid = false,
                ruby = false
            )

        private const val FONT_VARIANT_JIS78 = "jis78"
        private const val FONT_VARIANT_JIS83 = "jis83"
        private const val FONT_VARIANT_JIS90 = "jis90"
        private const val FONT_VARIANT_JIS04 = "jis04"
        private const val FONT_VARIANT_SIMPLIFIED = "simplified"
        private const val FONT_VARIANT_TRADITIONAL = "traditional"
        private const val FONT_VARIANT_FULL_WIDTH = "full-width"
        private const val FONT_VARIANT_PROPORTIONAL_WIDTH =
            "proportional-width"

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
        const val FEATURE_SWSH: String = "swsh"

        //-----------------------------------------------------------------------------------------------
        // Parsing font-feature-settings property value

        /**
         * Parse the value of the CSS property "font-feature-settings".
         *
         * Format is: <feature-tag-value>[comma-wsp <feature-tag-value>]*
         *            <feature-tag-value> = <string> [ <integer> | on | off ]?
         */
        fun parseFontFeatureSettings(
            value: String
        ): CSSFontFeatureSettings? {
            val builder = CSSFontFeatureSettings().toBuilder()

            val scan = TextScanner(value)
            scan.skipWhitespace()

            while (!scan.empty()) {
                if (!nextFeatureEntry(builder, scan)) {
                    return null
                }

                scan.skipCommaWhitespace()
            }

            return builder.build()
        }

        private fun nextFeatureEntry(
            builder: Builder,
            scan: TextScanner
        ): Boolean {
            scan.skipWhitespace()

            val name = scan.nextQuotedString()

            if (name == null || name.length != 4) {
                return false
            }

            scan.skipWhitespace()

            var value = VALUE_ON

            if (!scan.empty()) {
                val num = scan.nextInteger(false)

                if (num == null) {
                    if (scan.consume(FEATURE_OFF)) {
                        value = VALUE_OFF
                    } else {
                        scan.consume(FEATURE_ON)
                    }
                } else {
                    value = num
                }
            }

            builder.addSetting(name, value)
            return true
        }

        //-----------------------------------------------------------------------------------------------
        // Parse a font-kerning keyword

        fun parseFontKerning(
            value: String
        ): FontKerning? {
            return when {
                value.equals(FONT_VARIANT_AUTO, ignoreCase = true) -> FontKerning.auto
                value.equals(FONT_VARIANT_NORMAL, ignoreCase = true) -> FontKerning.normal
                value.equals(FONT_VARIANT_NONE, ignoreCase = true) -> FontKerning.none
                else -> null
            }
        }

        private fun extractTokensAsList(
            value: String
        ): MutableList<String>? {
            val scan = TextScanner(value)
            scan.skipWhitespace()

            if (scan.empty()) return null

            val result = ArrayList<String>()

            while (!scan.empty()) {
                result.add(scan.requireNextToken().lowercase(Locale.US))
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
                if (tokens.contains(token1) ||
                    tokens.contains(token2)
                ) {
                    3
                } else {
                    1
                }
            } else if (tokens.remove(token2)) {
                if (tokens.contains(token2)) {
                    3
                } else {
                    2
                }
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
        private fun containsOnce(
            tokens: MutableList<String>,
            token1: String
        ): Int {
            return if (tokens.remove(token1)) {
                if (tokens.contains(token1)) 2 else 1
            } else {
                0
            }
        }

        /**
         * Checks haystack to see which needle is present (if any).
         * Returns the needle.
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
            return when {
                value.equals(FONT_VARIANT_NORMAL, ignoreCase = true) -> {
                    LIGATURES_NORMAL
                }
                value.equals(FONT_VARIANT_NONE, ignoreCase = true) -> {
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
            val builder = LIGATURES_ALL_OFF.toBuilder()
            var found = false

            when (containsWhich(
                tokens,
                FONT_VARIANT_COMMON_LIGATURES,
                FONT_VARIANT_NO_COMMON_LIGATURES
            )) {
                1 -> {
                    builder.addSettings(FEATURE_CLIG, FEATURE_LIGA, VALUE_ON)
                    found = true
                }

                2 -> {
                    builder.addSettings(FEATURE_CLIG, FEATURE_LIGA, VALUE_OFF)
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
                    builder.addSetting(FEATURE_DLIG, VALUE_ON)
                    found = true
                }

                2 -> {
                    builder.addSetting(FEATURE_DLIG, VALUE_OFF)
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
                    builder.addSetting(FEATURE_HLIG, VALUE_ON)
                    found = true
                }

                2 -> {
                    builder.addSetting(FEATURE_HLIG, VALUE_OFF)
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
                    builder.addSetting(FEATURE_CALT, VALUE_ON)
                    found = true
                }

                2 -> {
                    builder.addSetting(FEATURE_CALT, VALUE_OFF)
                    found = true
                }

                3 -> return ERROR
            }

            return if (found) {
                builder.build()
            } else {
                null
            }
        }


        // Parse a font-kerning property
        fun parseVariantPosition(value: String): CSSFontFeatureSettings? {
            return when {
                value.equals(FONT_VARIANT_NORMAL, ignoreCase = true) -> POSITION_ALL_OFF
                value.equals(FONT_VARIANT_SUB, ignoreCase = true) -> POSITION_ALL_OFF.toBuilder().apply {
                    addSetting(FEATURE_SUBS, VALUE_ON)
                }.build()
                value.equals(FONT_VARIANT_SUPER, ignoreCase = true) -> POSITION_ALL_OFF.toBuilder().apply {
                    addSetting(FEATURE_SUPS, VALUE_ON)
                }.build()
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
                    val builder = POSITION_ALL_OFF.toBuilder()
                    builder.addSetting(FEATURE_SUBS, VALUE_ON)
                    builder.build()
                }

                2 -> {
                    val builder = POSITION_ALL_OFF.toBuilder()
                    builder.addSetting(FEATURE_SUPS, VALUE_ON)
                    builder.build()
                }

                3 -> ERROR

                else -> null
            }
        }

        // Parse a font-variant-caps property
        fun parseVariantCaps(value: String): CSSFontFeatureSettings? {
            val lowerValue = value.lowercase(Locale.US)
            return if (lowerValue == FONT_VARIANT_NORMAL) {
                CAPS_ALL_OFF
            } else {
                val builder = CAPS_ALL_OFF.toBuilder()
                if (setCapsFeature(builder, lowerValue)) {
                    builder.build()
                } else {
                    null
                }
            }
        }

        private fun setCapsFeature(builder: Builder, value: String): Boolean {
            when (value) {
                FONT_VARIANT_SMALL_CAPS -> builder.addSetting(FEATURE_SMCP, VALUE_ON)
                FONT_VARIANT_ALL_SMALL_CAPS -> builder.addSettings(
                    FEATURE_SMCP,
                    FEATURE_C2SC,
                    VALUE_ON
                )

                FONT_VARIANT_PETITE_CAPS -> builder.addSetting(FEATURE_PCAP, VALUE_ON)
                FONT_VARIANT_ALL_PETITE_CAPS -> builder.addSettings(
                    FEATURE_PCAP,
                    FEATURE_C2PC,
                    VALUE_ON
                )

                FONT_VARIANT_UNICASE -> builder.addSetting(FEATURE_UNIC, VALUE_ON)
                FONT_VARIANT_TITLING_CAPS -> builder.addSetting(FEATURE_TITL, VALUE_ON)
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
                    val builder = CAPS_ALL_OFF.toBuilder()
                    setCapsFeature(builder, which)
                    builder.build()
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
            if (value.equals(FONT_VARIANT_NORMAL, ignoreCase = true)) return NUMERIC_ALL_OFF

            val tokens: MutableList<String> = extractTokensAsList(value) ?: return null

            val result: CSSFontFeatureSettings? = parseVariantNumericSpecial(tokens)

            // If nothing found, or duplicate keywords found, or tokens left over, then we have an error
            if (result == null || result === ERROR || tokens.isNotEmpty()) return null

            return result
        }


        private fun parseVariantNumericSpecial(tokens: MutableList<String>): CSSFontFeatureSettings? {
            val builder = NUMERIC_ALL_OFF.toBuilder()
            var found = false

            when (containsWhich(tokens, FONT_VARIANT_LINING_NUMS, FONT_VARIANT_OLDSTYLE_NUMS)) {
                1 -> {
                    builder.addSetting(FEATURE_LNUM, VALUE_ON)
                    found = true
                }

                2 -> {
                    builder.addSetting(FEATURE_ONUM, VALUE_ON)
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
                    builder.addSetting(FEATURE_PNUM, VALUE_ON)
                    found = true
                }

                2 -> {
                    builder.addSetting(FEATURE_TNUM, VALUE_ON)
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
                    builder.addSetting(FEATURE_FRAC, VALUE_ON)
                    found = true
                }

                2 -> {
                    builder.addSetting(FEATURE_AFRC, VALUE_ON)
                    found = true
                }

                3 -> return ERROR
            }

            when (containsOnce(tokens, FONT_VARIANT_ORDINAL)) {
                1 -> {
                    builder.addSetting(FEATURE_ORDN, VALUE_ON)
                    found = true
                }

                2 -> return ERROR
            }

            when (containsOnce(tokens, FONT_VARIANT_SLASHED_ZERO)) {
                1 -> {
                    builder.addSetting(FEATURE_ZERO, VALUE_ON)
                    found = true
                }

                2 -> return ERROR
            }

            return if (found) builder.build() else null
        }


        /**
         * Parse a font-variant-east-asian property
         * Format:
         *   normal | [ <east-asian-variant-values> || <east-asian-width-values> || ruby ]
         *   <east-asian-variant-values> = [ jis78 | jis83 | jis90 | jis04 | simplified | traditional ]
         *   <east-asian-width-values>   = [ full-width | proportional-width ]
         */
        fun parseEastAsian(value: String): CSSFontFeatureSettings? {
            if (value.equals(FONT_VARIANT_NORMAL, ignoreCase = true)) return EAST_ASIAN_ALL_OFF

            val tokens: MutableList<String> = extractTokensAsList(value) ?: return null

            val result: CSSFontFeatureSettings? = parseVariantEastAsianSpecial(tokens)

            // If nothing found, or duplicate keywords found, or tokens left over, then we have an error
            if (result == null || result === ERROR || tokens.isNotEmpty()) return null

            return result
        }


        private fun parseVariantEastAsianSpecial(tokens: MutableList<String>): CSSFontFeatureSettings? {
            val builder = EAST_ASIAN_ALL_OFF.toBuilder()
            var found = false

            val which: String? = containsOneOf(
                tokens,
                FONT_VARIANT_JIS78,
                FONT_VARIANT_JIS83,
                FONT_VARIANT_JIS90,
                FONT_VARIANT_JIS04,
                FONT_VARIANT_SIMPLIFIED,
                FONT_VARIANT_TRADITIONAL
            )

            if (which != null) {
                when (which) {
                    FONT_VARIANT_JIS78 -> builder.addSetting(FEATURE_JP78, VALUE_ON)
                    FONT_VARIANT_JIS83 -> builder.addSetting(FEATURE_JP83, VALUE_ON)
                    FONT_VARIANT_JIS90 -> builder.addSetting(FEATURE_JP90, VALUE_ON)
                    FONT_VARIANT_JIS04 -> builder.addSetting(FEATURE_JP04, VALUE_ON)
                    FONT_VARIANT_SIMPLIFIED -> builder.addSetting(FEATURE_SMPL, VALUE_ON)
                    FONT_VARIANT_TRADITIONAL -> builder.addSetting(FEATURE_TRAD, VALUE_ON)
                    TOKEN_ERROR -> return ERROR // more than one, or duplicate, found
                }
                found = true
            }

            when (containsWhich(tokens, FONT_VARIANT_FULL_WIDTH, FONT_VARIANT_PROPORTIONAL_WIDTH)) {
                1 -> {
                    builder.addSetting(FEATURE_FWID, VALUE_ON)
                    found = true
                }

                2 -> {
                    builder.addSetting(FEATURE_PWID, VALUE_ON)
                    found = true
                }

                3 -> return ERROR
            }

            when (containsOnce(tokens, FONT_VARIANT_RUBY)) {
                1 -> {
                    builder.addSetting(FEATURE_RUBY, VALUE_ON)
                    found = true
                }

                2 -> return ERROR
            }

            return if (found) builder.build() else null
        }


        //-----------------------------------------------------------------------------------------------
        fun parseFontVariant(style: Style.Builder, value: String) {
            when {
                value.equals(FONT_VARIANT_NORMAL, ignoreCase = true) -> {
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
                }
                value.equals(FONT_VARIANT_NONE, ignoreCase = true) -> {
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
                }
                else -> {
                    val tokens = extractTokensAsList(value) ?: return

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
    }
}
