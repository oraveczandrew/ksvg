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
package hu.oandras.ksvg

import hu.oandras.ksvg.parser.TextScanner

/**
 * The PreserveAspectRatio class tells the renderer how to scale and position the
 * SVG document in the current viewport.  It is roughly equivalent to the
 * `preserveAspectRatio` attribute of an `<svg>` element.
 * 
 * 
 * In order for scaling to happen, the SVG document must have a viewBox attribute set.
 * For example:
 * 
 * <pre>
 * `<svg version="1.1" viewBox="0 0 200 100"> `
</pre> * 
 * 
 * This class was previous named `SVGPositioning`. It was renamed in version 1.3
 * to reduce confusion when used as part of the [RenderOptions] class.
 */
@ConsistentCopyVisibility
@Suppress("EnumEntryName")
public data class PreserveAspectRatio internal constructor(
    /**
     * Returns the alignment value of this instance.
     * @return the alignment
     */
    @JvmField
    val alignment: Alignment?,
    /**
     * Returns the scale value of this instance.
     * @return the scale
     */
    @JvmField
    val scale: Scale?
) {
    /**
     * Determines how the document is to me positioned relative to the viewport (normally the canvas).
     * 
     * 
     * For the value `none`, the document is stretched to fit the viewport dimensions. For all
     * other values, the aspect ratio of the document is kept the same but the document is scaled to
     * fit the viewport.
     */
    public enum class Alignment {
        /** Document is stretched to fit both the width and height of the viewport. When using this Alignment value, the value of Scale is not used and will be ignored.  */
        none,

        /** Document is positioned at the top left of the viewport.  */
        xMinYMin,

        /** Document is positioned at the center top of the viewport.  */
        xMidYMin,

        /** Document is positioned at the top right of the viewport.  */
        xMaxYMin,

        /** Document is positioned at the middle left of the viewport.  */
        xMinYMid,

        /** Document is centered in the viewport both vertically and horizontally.  */
        xMidYMid,

        /** Document is positioned at the middle right of the viewport.  */
        xMaxYMid,

        /** Document is positioned at the bottom left of the viewport.  */
        xMinYMax,

        /** Document is positioned at the bottom center of the viewport.  */
        xMidYMax,

        /** Document is positioned at the bottom right of the viewport.  */
        xMaxYMax
    }


    /**
     * Determine whether the scaled document fills the viewport entirely or is scaled to
     * fill the viewport without overflowing.
     */
    public enum class Scale {
        /**
         * The document is scaled so that it is as large as possible without overflowing the viewport.
         * There may be blank areas on one or more sides of the document.
         */
        meet,

        /**
         * The document is scaled so that entirely fills the viewport. That means that some of the
         * document may fall outside the viewport and will not be rendered.
         */
        slice
    }

    override fun toString(): String {
        return "$alignment $scale"
    }

    public companion object {

        /**
         * Draw document at its natural position and scale.
         */
        @JvmField
        public val UNSCALED: PreserveAspectRatio = PreserveAspectRatio(null, null)

        /**
         * Stretch horizontally and vertically to fill the viewport.
         * 
         * 
         * Equivalent to `preserveAspectRatio="none"` in an SVG.
         */
        @JvmField
        public val STRETCH: PreserveAspectRatio = PreserveAspectRatio(Alignment.none, null)

        /**
         * Keep the document's aspect ratio, but scale it so that it fits neatly inside the viewport.
         * 
         * 
         * The document will be centered in the viewport and may have blank strips at either the top and
         * bottom of the viewport or at the sides.
         * 
         * 
         * Equivalent to `preserveAspectRatio="xMidYMid meet"` in an SVG.
         */
        @JvmField
        public val LETTERBOX: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMidYMid, Scale.meet)

        /**
         * Keep the document's aspect ratio, but scale it so that it fits neatly inside the viewport.
         * 
         * 
         * The document will be positioned at the top of tall and narrow viewports, and at the left of short
         * and wide viewports.
         * 
         * 
         * Equivalent to `preserveAspectRatio="xMinYMin meet"` in an SVG.
         */
        @JvmField
        public val START: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMinYMin, Scale.meet)

        /**
         * Keep the document's aspect ratio, but scale it so that it fits neatly inside the viewport.
         * 
         * 
         * The document will be positioned at the bottom of tall and narrow viewports, and at the right of short
         * and wide viewports.
         * 
         * 
         * Equivalent to `preserveAspectRatio="xMaxYMax meet"` in an SVG.
         */
        @JvmField
        public val END: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMaxYMax, Scale.meet)

        /**
         * Keep the document's aspect ratio, but scale it so that it fits neatly inside the viewport.
         * 
         * 
         * The document will be positioned at the top of tall and narrow viewports, and at the center of
         * short and wide viewports.
         * 
         * 
         * Equivalent to `preserveAspectRatio="xMidYMin meet"` in an SVG.
         */
        @JvmField
        public val TOP: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMidYMin, Scale.meet)

        /**
         * Keep the document's aspect ratio, but scale it so that it fits neatly inside the viewport.
         * 
         * 
         * The document will be positioned at the bottom of tall and narrow viewports, and at the center of
         * short and wide viewports.
         * 
         * 
         * Equivalent to `preserveAspectRatio="xMidYMax meet"` in an SVG.
         */
        public val BOTTOM: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMidYMax, Scale.meet)

        /**
         * Keep the document's aspect ratio, but scale it so that it fills the entire viewport.
         * This may result in some of the document falling outside the viewport.
         * 
         * 
         * The document will be positioned so that the center of the document will always be visible,
         * but the edges of the document may not.
         * 
         * 
         * Equivalent to `preserveAspectRatio="xMidYMid slice"` in an SVG.
         */
        @JvmField
        public val FULLSCREEN: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMidYMid, Scale.slice)

        /**
         * Keep the document's aspect ratio, but scale it so that it fills the entire viewport.
         * This may result in some of the document falling outside the viewport.
         * 
         * 
         * The document will be positioned so that the top left of the document will always be visible,
         * but the right hand or bottom edge may not.
         * 
         * 
         * Equivalent to `preserveAspectRatio="xMinYMin slice"` in an SVG.
         */
        @JvmField
        public val FULLSCREEN_START: PreserveAspectRatio = PreserveAspectRatio(Alignment.xMinYMin, Scale.slice)

        /**
         * Parse the given SVG `preserveAspectRation` attribute value and return an equivalent
         * instance of this class.
         * @param value a string in the same format as an SVG `preserveAspectRatio` attribute
         * @return an instance of this class
         */
        @JvmStatic
        public fun of(value: String): PreserveAspectRatio {
            try {
                return parsePreserveAspectRatio(value)
            } catch (e: SVGParseException) {
                throw IllegalArgumentException(e.message)
            }
        }

        @Throws(SVGParseException::class)
        private fun parsePreserveAspectRatio(value: String): PreserveAspectRatio {
            val scan = TextScanner(value)
            scan.skipWhitespace()

            var word = scan.nextToken()
            if ("defer" == word) {    // Ignore defer keyword
                scan.skipWhitespace()
                word = scan.nextToken()
            }

            val align = resolveAspectRatioKeyword(word)

            scan.skipWhitespace()

            var scale: Scale? = null
            if (!scan.empty()) {
                val meetOrSlice = scan.nextToken()
                scale = when (meetOrSlice) {
                    "meet" -> Scale.meet
                    "slice" -> Scale.slice
                    else -> throw SVGParseException("Invalid preserveAspectRatio definition: $value")
                }
            }

            return PreserveAspectRatio(align, scale)
        }

        @Suppress("SpellCheckingInspection")
        private fun resolveAspectRatioKeyword(keyword: String?): Alignment? {
            return when (keyword) {
                "none" -> Alignment.none
                "xMinYMin" -> Alignment.xMinYMin
                "xMidYMin" -> Alignment.xMidYMin
                "xMaxYMin" -> Alignment.xMaxYMin
                "xMinYMid" -> Alignment.xMinYMid
                "xMidYMid" -> Alignment.xMidYMid
                "xMaxYMid" -> Alignment.xMaxYMid
                "xMinYMax" -> Alignment.xMinYMax
                "xMidYMax" -> Alignment.xMidYMax
                "xMaxYMax" -> Alignment.xMaxYMax
                else -> null
            }
        }
    }
}
