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

import android.util.Log
import hu.oandras.ksvg.BuildConfig
import hu.oandras.ksvg.ExternalFileResolver
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.ElementBase
import hu.oandras.ksvg.dom.core.SvgObject
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.parser.checkCssState
import hu.oandras.ksvg.utils.forEachElement

/**
 * A very simple CSS parser that is not entirely compliant with the CSS spec but
 * hopefully parses almost all the CSS we are likely to strike in an SVG file.
 */
internal class CSSParser internal constructor(
    private val deviceMediaType: MediaType = MediaType.screen, // Where these rules came from (Parser or RenderOptions)
    private val source: Source = Source.Document,
    private val externalFileResolver: ExternalFileResolver? = null
) {

    private var inMediaRule = false

    internal class Attrib(
        @JvmField
        val name: String,
        @JvmField
        val operation: AttribOp,
        @JvmField
        val value: String
    )

    internal class SimpleSelector(
        combinator: Combinator?, // null means "*"
        @JvmField
        val tag: String?
    ) {
        @JvmField
        val combinator: Combinator = combinator ?: Combinator.DESCENDANT

        @JvmField
        var attributes: MutableList<Attrib>? = null

        @JvmField
        var pseudos: MutableList<PseudoClass>? = null

        fun addAttrib(attrName: String, op: AttribOp, attrValue: String) {
            val attrs = attributes ?: ArrayList<Attrib>().also {
                attributes = it
            }
            attrs.add(Attrib(attrName, op, attrValue))
        }

        fun addPseudo(pseudo: PseudoClass) {
            val pseudos = pseudos ?: ArrayList<PseudoClass>().also {
                pseudos = it
            }
            pseudos.add(pseudo)
        }

        override fun toString(): String {
            return buildString {
                when (combinator) {
                    Combinator.CHILD -> {
                        append("> ")
                    }

                    Combinator.FOLLOWS -> {
                        append("+ ")
                    }

                    Combinator.DESCENDANT -> {}
                }

                append(tag ?: "*")

                attributes?.forEachElement { attr ->
                    append('[')
                    append(attr.name)
                    when (attr.operation) {
                        AttribOp.EQUALS -> append('=').append(attr.value)
                        AttribOp.INCLUDES -> append("~=").append(attr.value)
                        AttribOp.DASH_MATCH -> append("|=").append(attr.value)
                        else -> {}
                    }
                    append(']')
                }

                pseudos?.forEachElement { pseudo ->
                    append(':').append(pseudo)
                }
            }
        }
    }

    internal class Selector {
        @JvmField
        var simpleSelectors: MutableList<SimpleSelector>? = null

        @JvmField
        var specificity: Int = 0

        fun add(part: SimpleSelector) {
            val simpleSelectors = simpleSelectors ?: ArrayList<SimpleSelector>().also {
                this.simpleSelectors = it
            }
            simpleSelectors.add(part)
        }

        fun size(): Int {
            return simpleSelectors?.size ?: 0
        }

        fun get(i: Int): SimpleSelector {
            return simpleSelectors!![i]
        }

        val isEmpty: Boolean
            get() = simpleSelectors.isNullOrEmpty()

        // Methods for accumulating a specificity value as SimpleSelector entries are added.
        // Number of ID selectors in the simpleSelectors
        fun addedIdAttribute() {
            specificity += SPECIFICITY_ID_ATTRIBUTE
        }

        // Number of class selectors, attributes selectors, and pseudo-classes
        fun addedAttributeOrPseudo() {
            specificity += SPECIFICITY_ATTRIBUTE_OR_PSEUDOCLASS
        }

        // Number of type (element) selectors and pseudo-elements
        fun addedElement() {
            specificity += SPECIFICITY_ELEMENT_OR_PSEUDOELEMENT
        }

        override fun toString(): String {
            return buildString {
                simpleSelectors?.joinTo(this, " ")
                append(' ')
                append('[')
                append(specificity)
                append(']')
            }
        }
    }


    internal constructor(
        source: Source,
        externalFileResolver: ExternalFileResolver?
    ) : this(
        deviceMediaType = MediaType.screen,
        source = source,
        externalFileResolver = externalFileResolver
    )


    internal fun parse(sheet: String): CSSRuleset {
        val scan = CSSTextScanner(sheet)
        scan.skipWhitespace()

        return parseRuleset(scan)
    }

    @Throws(CSSParseException::class)
    private fun parseAtRule(ruleset: CSSRuleset, scan: CSSTextScanner) {
        val atKeyword = scan.nextIdentifier()
        scan.skipWhitespace()
        checkCssState(atKeyword != null) { "Invalid '@' rule" }
        if (!inMediaRule && atKeyword == "media") {
            val mediaList = parseMediaList(scan)
            checkCssState(scan.consume('{')) { "Invalid @media rule: missing rule set" }

            scan.skipWhitespace()
            if (mediaMatches(mediaList, deviceMediaType)) {
                inMediaRule = true
                ruleset.addAll(parseRuleset(scan))
                inMediaRule = false
            } else {
                parseRuleset(scan) // parse and ignore accompanying ruleset
            }

            if (!scan.empty()) checkCssState(scan.consume('}')) { "Invalid @media rule: expected '}' at end of rule set" }
        } else if (!inMediaRule && atKeyword == "import") {
            val file = scan.nextURL()
                ?: scan.nextCSSString()
                ?: throw CSSParseException("Invalid @import rule: expected string or url()")

            scan.skipWhitespace()
            val mediaList = parseMediaList(scan)

            if (!scan.empty()) checkCssState(scan.consume(';')) { "Invalid @media rule: expected '}' at end of rule set" }

            if (externalFileResolver != null && mediaMatches(mediaList, deviceMediaType)) {
                val css = externalFileResolver.resolveCSSStyleSheet(file) ?: return
                ruleset.addAll(parse(css))
            }
        } else {
            // Unknown/unsupported at-rule
            warn("Ignoring @%s rule", atKeyword)
            skipAtRule(scan)
        }
        scan.skipWhitespace()
    }


    // Skip an unsupported at-rule: "ignore everything up to and including the next semicolon or block".
    private fun skipAtRule(scan: CSSTextScanner) {
        var depth = 0
        while (!scan.empty()) {
            val ch = scan.nextChar()
            when (ch) {
                ';' -> if (depth == 0) return
                '{' -> depth++
                '}' -> if (depth > 0) {
                    if (--depth == 0) return
                }
            }
        }
    }


    private fun parseRuleset(scan: CSSTextScanner): CSSRuleset {
        val ruleset = CSSRuleset()
        try {
            while (!scan.empty()) {
                if (scan.consume("<!--")) continue
                if (scan.consume("-->")) continue

                if (scan.consume('@')) {
                    parseAtRule(ruleset, scan)
                    continue
                }
                if (parseRule(ruleset, scan)) continue

                // Nothing recognizable found. Could be end of rule set. Return.
                break
            }
        } catch (e: CSSParseException) {
            Log.e(TAG, "CSS parser terminated early due to error: " + e.message)
            if (BuildConfig.DEBUG) Log.e(TAG, "Stacktrace:", e)
        }
        return ruleset
    }


    @Throws(CSSParseException::class)
    private fun parseRule(ruleset: CSSRuleset, scan: CSSTextScanner): Boolean {
        val selectors = scan.nextSelectorGroup()
        return if (!selectors.isNullOrEmpty()) {
            checkCssState(scan.consume('{')) { "Malformed rule block: expected '{'" }
            scan.skipWhitespace()
            val ruleStyle = parseDeclarations(scan)
            scan.skipWhitespace()
            selectors.forEachElement { selector ->
                ruleset.add(CSSRule(selector, ruleStyle, source))
            }
            true
        } else {
            false
        }
    }


    // Parse a list of CSS declarations
    @Throws(CSSParseException::class)
    private fun parseDeclarations(scan: CSSTextScanner): Style {
        val styleBuilder = Style().toBuilder()
        do {
            val propertyName = scan.nextIdentifier()
            scan.skipWhitespace()
            checkCssState(scan.consume(':')) { "Expected ':'" }
            scan.skipWhitespace()
            val propertyValue = scan.nextPropertyValue() ?: throw CSSParseException("Expected property value")
            // Check for !important flag.
            scan.skipWhitespace()
            var important = false
            if (scan.consume('!')) {
                scan.skipWhitespace()
                checkCssState(scan.consume("important")) { "Malformed rule set: found unexpected '!'" }
                important = true
                scan.skipWhitespace()
            }
            scan.consume(';')
            // 'inherit', 'unset' and 'initial' are handled in Style.processStyleProperty.
            styleBuilder.lastTouchedFlag = 0L
            Style.processStyleProperty(styleBuilder, propertyName, propertyValue, false)
            if (important && styleBuilder.lastTouchedFlag != 0L) {
                styleBuilder.markImportant(styleBuilder.lastTouchedFlag)
            }
            scan.skipWhitespace()
        } while (!scan.empty() && !scan.consume('}'))
        return styleBuilder.build()
    }


    //==============================================================================
    // Matching a selector against an object/element
    internal class RuleMatchContext(
        // From RenderOptions.target() and used for the :target selector
        @JvmField
        val targetElement: SvgObject? = null
    ) {

        override fun toString(): String {
            val targetElement = targetElement
            return if (targetElement != null) {
                String.format(
                    "<%s id=\"%s\">",
                    targetElement.getNodeName(),
                    targetElement.id
                )
            } else {
                ""
            }
        }
    }


    companion object {
        private const val TAG = "CSSParser"

        const val CSS_MIME_TYPE: String = "text/css"

        const val ID: String = "id"
        const val CLASS: String = "class"

        private const val SPECIFICITY_ID_ATTRIBUTE = 1000000
        private const val SPECIFICITY_ATTRIBUTE_OR_PSEUDOCLASS = 1000
        private const val SPECIFICITY_ELEMENT_OR_PSEUDOELEMENT = 1

        internal fun mediaMatches(mediaListStr: String, rendererMediaType: MediaType?): Boolean {
            val scan = CSSTextScanner(mediaListStr)
            scan.skipWhitespace()
            val mediaList = parseMediaList(scan)
            return mediaMatches(mediaList, rendererMediaType)
        }


        //==============================================================================
        @Suppress("SameParameterValue")
        private fun warn(format: String, vararg args: Any?) {
            Log.w(TAG, String.format(format, *args))
        }


        //==============================================================================
        // Returns true if 'deviceMediaType' matches one of the media types in 'mediaList'
        private fun mediaMatches(
            mediaList: List<MediaType>,
            rendererMediaType: MediaType?
        ): Boolean {
            if (mediaList.isEmpty()) {
                // No specific media specified, so match all
                return true
            }

            mediaList.forEachElement { type ->
                if (type == MediaType.all || type == rendererMediaType) {
                    return true
                }
            }

            return false
        }


        private fun parseMediaList(scan: CSSTextScanner): List<MediaType> {
            val typeList = ArrayList<MediaType>()
            while (!scan.empty()) {
                val type = scan.nextWord() ?: break
                try {
                    typeList.add(MediaType.valueOf(type))
                } catch (_: IllegalArgumentException) {
                    // Ignore invalid media types
                }
                // If there is a comma, keep looping, otherwise break
                if (!scan.skipCommaWhitespace()) break
            }
            return typeList
        }


        /**
         * Used by SVGParser to parse the "class" attribute.
         * Follows ordered set parser algorithm: https://dom.spec.whatwg.org/#concept-ordered-set-parser
         */
        fun parseClassAttribute(value: String): List<String>? {
            val scan = CSSTextScanner(value)
            var classNameList: MutableList<String>? = null

            while (!scan.empty()) {
                val className = scan.nextToken() ?: continue
                if (classNameList == null) classNameList = ArrayList()
                classNameList.add(className)
                scan.skipWhitespace()
            }
            return classNameList
        }


        /**
         * Used by renderer to check if a CSS rule matches the current element.
         */
        internal fun ruleMatch(
            ruleMatchContext: RuleMatchContext?,
            selector: Selector,
            obj: ElementBase
        ): Boolean {
            // Check the most common case first as a shortcut.
            if (selector.size() == 1) {
                return selectorMatch(ruleMatchContext, selector.get(0), obj)
            }

            // Build the list of ancestor objects
            val ancestors: MutableList<Container> = ArrayList()
            var parent = obj.parent
            while (parent != null) {
                ancestors.add(parent)
                parent = parent.parent
            }

            ancestors.reverse()


            // We start at the last part of the simpleSelectors and loop back through the parts
            // Get the next simpleSelectors part
            return ruleMatch(
                ruleMatchContext = ruleMatchContext,
                selector = selector,
                selPartPos = selector.size() - 1,
                ancestors = ancestors,
                ancestorsPos = ancestors.size - 1,
                obj = obj
            )
        }

        private fun ruleMatch(
            ruleMatchContext: RuleMatchContext?,
            selector: Selector,
            selPartPos: Int,
            ancestors: MutableList<Container>,
            ancestorsPos: Int,
            obj: ElementBase
        ): Boolean {
            // We start at the last part of the simpleSelectors and loop back through the parts
            // Get the next simpleSelectors part
            val sel = selector.get(selPartPos)
            return selectorMatch(
                ruleMatchContext = ruleMatchContext,
                sel = sel,
                obj = obj
            ) && when (sel.combinator) {
                Combinator.DESCENDANT -> {
                    if (selPartPos == 0) {
                        true
                    } else {
                        var match = false
                        // Search up the ancestors list for a node that matches the next simpleSelectors
                        var ancestorsPos = ancestorsPos
                        while (ancestorsPos >= 0) {
                            if (ruleMatchOnAncestors(
                                    ruleMatchContext = ruleMatchContext,
                                    selector = selector,
                                    selPartPos = selPartPos - 1,
                                    ancestors = ancestors,
                                    ancestorsPos = ancestorsPos
                                )
                            ) {
                                match = true
                                break
                            }
                            ancestorsPos--
                        }
                        match
                    }
                }

                Combinator.CHILD -> {
                    ruleMatchOnAncestors(
                        ruleMatchContext = ruleMatchContext,
                        selector = selector,
                        selPartPos = selPartPos - 1,
                        ancestors = ancestors,
                        ancestorsPos = ancestorsPos
                    )
                }

                Combinator.FOLLOWS -> {
                    matchPreviousSibling(
                        ruleMatchContext = ruleMatchContext,
                        selector = selector,
                        selPartPos = selPartPos,
                        ancestors = ancestors,
                        ancestorsPos = ancestorsPos,
                        obj = obj
                    )
                }
            }
        }

        private fun ruleMatchOnAncestors(
            ruleMatchContext: RuleMatchContext?,
            selector: Selector,
            selPartPos: Int,
            ancestors: MutableList<Container>,
            ancestorsPos: Int
        ): Boolean {
            val sel = selector.get(selPartPos)
            val obj: ElementBase = ancestors[ancestorsPos] as ElementBase

            return selectorMatch(
                ruleMatchContext = ruleMatchContext,
                sel = sel,
                obj = obj
            ) && when (sel.combinator) {
                Combinator.DESCENDANT -> {
                    if (selPartPos == 0) {
                        true
                    } else {
                        // Search up the ancestors list for a node that matches the next simpleSelectors
                        var match = false
                        var ancestorsPos = ancestorsPos
                        while (ancestorsPos > 0) {
                            if (ruleMatchOnAncestors(
                                    ruleMatchContext = ruleMatchContext,
                                    selector = selector,
                                    selPartPos = selPartPos - 1,
                                    ancestors = ancestors,
                                    ancestorsPos = --ancestorsPos
                                )
                            ) {
                                match = true
                                break
                            }
                        }
                        match
                    }
                }

                Combinator.CHILD -> {
                    ruleMatchOnAncestors(
                        ruleMatchContext = ruleMatchContext,
                        selector = selector,
                        selPartPos = selPartPos - 1,
                        ancestors = ancestors,
                        ancestorsPos = ancestorsPos - 1
                    )
                }

                Combinator.FOLLOWS -> {
                    matchPreviousSibling(
                        ruleMatchContext = ruleMatchContext,
                        selector = selector,
                        selPartPos = selPartPos,
                        ancestors = ancestors,
                        ancestorsPos = ancestorsPos,
                        obj = obj
                    )
                }
            }
        }

        private fun matchPreviousSibling(
            ruleMatchContext: RuleMatchContext?,
            selector: Selector,
            selPartPos: Int,
            ancestors: MutableList<Container>,
            ancestorsPos: Int,
            obj: ElementBase
        ): Boolean {
            val childPos = getChildPosition(ancestors, ancestorsPos, obj)
            if (childPos <= 0) return false
            val prevSibling = obj.parent!!.getChildren()[childPos - 1] as ElementBase
            return ruleMatch(
                ruleMatchContext = ruleMatchContext,
                selector = selector,
                selPartPos = selPartPos - 1,
                ancestors = ancestors,
                ancestorsPos = ancestorsPos,
                obj = prevSibling
            )
        }

        private fun getChildPosition(
            ancestors: MutableList<Container>,
            ancestorsPos: Int,
            obj: ElementBase
        ): Int {
            if (ancestorsPos < 0) {
                // Has no parent, so must be only child of document
                return 0
            }
            if (ancestors[ancestorsPos] !== obj.parent) {
                // parent doesn't match, so obj must be an indirect reference (e.g. from a <use>)
                return -1
            }
            val children = obj.parent!!.getChildren()
            for (childPos in children.indices) {
                if (children[childPos] === obj) {
                    return childPos
                }
            }
            return -1
        }

        private fun selectorMatch(
            ruleMatchContext: RuleMatchContext?,
            sel: SimpleSelector,
            obj: ElementBase
        ): Boolean {
            // Check tag name. tag==null means tag is "*" which matches everything.
            val tag = sel.tag
            if (tag != null && !tag.equals(obj.getNodeName(), ignoreCase = true)) {
                return false
            }

            // If here, then tag part matched

            // Check the attributes
            sel.attributes?.forEachElement { attr ->
                when (attr.name) {
                    ID -> {
                        if (attr.value != obj.id) {
                            return false
                        }
                    }

                    CLASS -> {
                        val classNames = obj.classNames ?: return false
                        if (!classNames.contains(attr.value)) {
                            return false
                        }
                    }

                    else -> {
                        val value = obj.attributes?.get(attr.name) ?: return false
                        when (attr.operation) {
                            AttribOp.EXISTS -> {}
                            AttribOp.EQUALS -> if (value != attr.value) return false
                            AttribOp.INCLUDES -> {
                                if (!value.split(' ').contains(attr.value)) return false
                            }
                            AttribOp.DASH_MATCH -> {
                                if (value != attr.value && !value.startsWith("${attr.value}-")) return false
                            }
                        }
                    }
                }
            }

            // Check the pseudo classes
            sel.pseudos?.forEachElement { pseudo ->
                if (!pseudo.matches(ruleMatchContext, obj)) {
                    return false
                }
            }

            // If w reached this point, the simpleSelectors matched
            return true
        }
    }
}
