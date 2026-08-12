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

import android.util.ArrayMap
import android.util.Log
import hu.oandras.ksvg.BuildConfig
import hu.oandras.ksvg.SVGExternalFileResolver
import hu.oandras.ksvg.dom.Style
import hu.oandras.ksvg.dom.SvgObject
import hu.oandras.ksvg.dom.SvgObject.SvgContainer
import hu.oandras.ksvg.dom.SvgObject.SvgElementBase
import hu.oandras.ksvg.utils.forEachElement
import java.util.LinkedList
import java.util.Locale
import kotlin.math.sign

/**
 * A very simple CSS parser that is not entirely compliant with the CSS spec but
 * hopefully parses almost all the CSS we are likely to strike in an SVG file.
 */
@Suppress("EnumEntryName")
internal class CSSParser internal constructor(
    private val deviceMediaType: MediaType = MediaType.screen, // Where these rules came from (Parser or RenderOptions)
    private val source: Source = Source.Document,
    private val externalFileResolver: SVGExternalFileResolver? = null
) {

    private var inMediaRule = false


    @Suppress("unused")
    internal enum class MediaType {
        all,
        aural,  // deprecated
        braille,  // deprecated
        embossed,  // deprecated
        handheld,  // deprecated
        print,
        projection,  // deprecated
        screen,
        speech,
        tty,  // deprecated
        tv // deprecated
    }

    internal enum class Combinator {
        DESCENDANT,  // E F
        CHILD,  // E > F
        FOLLOWS // E + F
    }

    internal enum class AttribOp {
        EXISTS,  // *[foo]
        EQUALS,  // *[foo=bar]
        INCLUDES,  // *[foo~=bar]
        DASHMATCH,  // *[foo|=bar]
    }

    // Supported SVG attributes
    internal enum class PseudoClassIdentifiers {
        target,
        root,
        nth_child,
        nth_last_child,
        nth_of_type,
        nth_last_of_type,
        first_child,
        last_child,
        first_of_type,
        last_of_type,
        only_child,
        only_of_type,
        empty,
        not,

        // Others from  Selectors 3 (and earlier)
        // Supported but always fail to match.
        lang,  // might support later
        link, visited, hover, active, focus, enabled, disabled, checked, indeterminate,  // Added in Selectors 4 spec
        // Might support these later
        //matches,
        //something,  // Not final name(?)
        //has,
        //dir,  might support later
        //target_within,
        //blank,

        // Operators from Selectors 4
        // any-link, local-link, scope, focus-visible, focus-within, drop, current, past,
        // future, playing, paused, read-only, read-write, placeholder-shown, default, valid, invalid,
        // in-range, out-of-range, required, optional, user-invalid, nth-col, nth-last-col
        UNSUPPORTED;

        companion object {
            private val cache: Map<String, PseudoClassIdentifiers> = ArrayMap<String, PseudoClassIdentifiers>(entries.size - 1).apply {
                for (attr in PseudoClassIdentifiers.entries) {
                    if (attr != UNSUPPORTED) {
                        val key = attr.name.replace('_', '-')
                        this[key] = attr
                    }
                }
            }

            @JvmStatic
            fun fromString(str: String?): PseudoClassIdentifiers {
                return cache[str] ?: UNSUPPORTED
            }
        }
    }

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

                    else -> {}
                }

                append(tag ?: "*")

                attributes?.forEachElement { attr ->
                    append('[')
                    append(attr.name)
                    when (attr.operation) {
                        AttribOp.EQUALS -> append('=').append(attr.value)
                        AttribOp.INCLUDES -> append("~=").append(attr.value)
                        AttribOp.DASHMATCH -> append("|=").append(attr.value)
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

    internal class Ruleset {

        private var _rules: MutableList<Rule>? = null

        val rules: List<Rule>
            get() = _rules ?: emptyList()

        // Add a rule to the ruleset. The position at which it is inserted is determined by its specificity value.
        fun add(rule: Rule) {
            val rules = _rules ?: LinkedList<Rule>().also {
                this._rules = it
            }

            for (i in rules.indices) {
                val nextRule = rules[i]

                if (nextRule.selector.specificity > rule.selector.specificity) {
                    rules.add(i, rule)
                    return
                }
            }

            rules.add(rule)
        }

        fun addAll(set: Ruleset) {
            set._rules?.forEachElement { rule ->
                add(rule)
            }
        }

        /**
         * Remove all rules that were added from a given Source.
         */
        fun removeFromSource(sourceToBeRemoved: Source?) {
            val rules = _rules ?: return
            for (i in rules.indices.reversed()) {
                if (rules[i].source == sourceToBeRemoved) {
                    rules.removeAt(i)
                }
            }
        }

        override fun toString(): String {
            return _rules?.joinToString("\n").orEmpty()
        }
    }


    enum class Source {
        Document,
        RenderOptions
    }

    internal class Rule internal constructor(
        @JvmField
        val selector: Selector,
        @JvmField
        val style: Style,
        @JvmField
        val source: Source
    ) {
        override fun toString(): String {
            return "$selector {...} (src=$source)"
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
        externalFileResolver: SVGExternalFileResolver?
    ) : this(
        deviceMediaType = MediaType.screen,
        source = source,
        externalFileResolver = externalFileResolver
    )


    internal fun parse(sheet: String): Ruleset {
        val scan = CSSTextScanner(sheet)
        scan.skipWhitespace()

        return parseRuleset(scan)
    }

    @Throws(CSSParseException::class)
    private fun parseAtRule(ruleset: Ruleset, scan: CSSTextScanner) {
        val atKeyword = scan.nextIdentifier()
        scan.skipWhitespace()
        if (atKeyword == null) throw CSSParseException("Invalid '@' rule")
        if (!inMediaRule && atKeyword == "media") {
            val mediaList = parseMediaList(scan)
            if (!scan.consume('{')) throw CSSParseException("Invalid @media rule: missing rule set")

            scan.skipWhitespace()
            if (mediaMatches(mediaList, deviceMediaType)) {
                inMediaRule = true
                ruleset.addAll(parseRuleset(scan))
                inMediaRule = false
            } else {
                parseRuleset(scan) // parse and ignore accompanying ruleset
            }

            if (!scan.empty() && !scan.consume('}')) throw CSSParseException("Invalid @media rule: expected '}' at end of rule set")
        } else if (!inMediaRule && atKeyword == "import") {
            val file = scan.nextURL()
                ?: scan.nextCSSString()
                ?: throw CSSParseException("Invalid @import rule: expected string or url()")

            scan.skipWhitespace()
            val mediaList = parseMediaList(scan)

            if (!scan.empty() && !scan.consume(';')) throw CSSParseException("Invalid @media rule: expected '}' at end of rule set")

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
            if (ch == ';' && depth == 0) return
            if (ch == '{') depth++
            else if (ch == '}' && depth > 0) {
                if (--depth == 0) return
            }
        }
    }


    private fun parseRuleset(scan: CSSTextScanner): Ruleset {
        val ruleset = Ruleset()
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
    private fun parseRule(ruleset: Ruleset, scan: CSSTextScanner): Boolean {
        val selectors = scan.nextSelectorGroup()
        return if (!selectors.isNullOrEmpty()) {
            if (!scan.consume('{')) throw CSSParseException("Malformed rule block: expected '{'")
            scan.skipWhitespace()
            val ruleStyle = parseDeclarations(scan)
            scan.skipWhitespace()
            selectors.forEachElement { selector ->
                ruleset.add(Rule(selector, ruleStyle, source))
            }
            true
        } else {
            false
        }
    }


    // Parse a list of CSS declarations
    @Throws(CSSParseException::class)
    private fun parseDeclarations(scan: CSSTextScanner): Style {
        val ruleStyle = Style()
        do {
            val propertyName = scan.nextIdentifier()
            scan.skipWhitespace()
            if (!scan.consume(':')) throw CSSParseException("Expected ':'")
            scan.skipWhitespace()
            val propertyValue = scan.nextPropertyValue() ?: throw CSSParseException("Expected property value")
            // Check for !important flag.
            scan.skipWhitespace()
            if (scan.consume('!')) {
                scan.skipWhitespace()
                if (!scan.consume("important")) {
                    throw CSSParseException("Malformed rule set: found unexpected '!'")
                }
                // We don't do anything with these. We just ignore them. TODO
                scan.skipWhitespace()
            }
            scan.consume(';')
            // TODO: support CSS only values such as "inherit"
            Style.processStyleProperty(ruleStyle, propertyName, propertyValue, false)
            scan.skipWhitespace()
        } while (!scan.empty() && !scan.consume('}'))
        return ruleStyle
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


    //==============================================================================
    internal interface PseudoClass {
        fun matches(ruleMatchContext: RuleMatchContext?, obj: SvgElementBase): Boolean
    }

    internal class PseudoClassAnPlusB(
        private val a: Int,
        private val b: Int,
        private val isFromStart: Boolean,
        private val isOfType: Boolean, // The node name for when isOfType is true
        private val nodeName: String?
    ) : PseudoClass {
        override fun matches(ruleMatchContext: RuleMatchContext?, obj: SvgElementBase): Boolean {
            // If this is a "*-of-type" pseudoclass, and the node name hasn't been specified,
            // then match true if the element being tested is first of its type
            val nodeNameToCheck = if (isOfType && nodeName == null) obj.getNodeName() else nodeName

            // Initialize with correct values for root element
            var childPos = 0
            var childCount = 1

            // If this is not the root element, then determine
            // this objects sibling position and total sibling count
            obj.parent?.let { parent ->
                childCount = 0
                parent.getChildren().forEachElement { node ->
                    val child = node as SvgElementBase // This should be safe. We shouldn't be styling any SvgObject that isn't an element.
                    if (child === obj) {
                        childPos = childCount
                    }
                    if (nodeNameToCheck == null || child.getNodeName() == nodeNameToCheck) {
                        childCount++ // this is a child of the right type
                    }
                }
            }

            childPos = if (isFromStart) {
                childPos + 1 // nth-child positions start at 1, not 0
            } else {
                childCount - childPos // for nth-last-child() type pseudo classes
            }

            // Check if an + b == childPos.  The test is true for any n >= 0.
            // So rearranging fo n we get: n = (childPos - b) / a
            if (a == 0) {
                // a is zero for pseudo classes like: nth-child(b)
                // So we match if childPos == b
                return childPos == b
            }
            // Otherwise we match if ((childPos - b) / a) is an integer (modulus is 0) and is >= 0
            val diff = childPos - b
            return diff % a == 0 && (diff == 0 || diff.sign == a.sign) // Faster equivalent of (diff / a) >= 0;
        }

        override fun toString(): String {
            val last = if (isFromStart) "" else "last-"
            return if (isOfType) String.format(
                Locale.US,
                "nth-%schild(%dn%+d of type <%s>)",
                last,
                a,
                b,
                nodeName
            ) else String.format(
                Locale.US, "nth-%schild(%dn%+d)", last, a, b
            )
        }
    }


    internal class PseudoClassOnlyChild(
        private val isOfType: Boolean, // The node name for when isOfType is true
        private val nodeName: String?
    ) : PseudoClass {
        override fun matches(ruleMatchContext: RuleMatchContext?, obj: SvgElementBase): Boolean {
            // If this is a "*-of-type" pseudoclass, and the node name hasn't been specified,
            // then match true if the element being tested is first of its type
            val nodeNameToCheck = if (isOfType && nodeName == null) obj.getNodeName() else nodeName

            // Initialize with correct values for root element
            var childCount = 1

            // If this is not the root element, then determine
            // this objects sibling position and total sibling count
            val parent = obj.parent
            if (parent != null) {
                childCount = 0
                parent.getChildren().forEachElement { node ->
                    val child = node as SvgElementBase // This should be safe. We shouldn't be styling any SvgObject that isn't an element.
                    if (nodeNameToCheck == null || child.getNodeName() == nodeNameToCheck) {
                        childCount++ // this is a child of the right type
                    }
                }
            }

            return childCount == 1
        }

        override fun toString(): String {
            return if (isOfType) {
                String.format("only-of-type <%s>", nodeName)
            } else {
                "only-child"
            }
        }
    }


    internal class PseudoClassRoot : PseudoClass {
        override fun matches(ruleMatchContext: RuleMatchContext?, obj: SvgElementBase): Boolean {
            return obj.parent == null
        }

        override fun toString(): String {
            return "root"
        }
    }

    internal class PseudoClassEmpty : PseudoClass {
        override fun matches(ruleMatchContext: RuleMatchContext?, obj: SvgElementBase): Boolean {
            //return (obj.getChildren().length == 0;

            // temp implementation

            return obj !is SvgContainer || obj.getChildren().isEmpty()
            // FIXME  all SVG graphics elements can have children, although for now we drop and ignore
            // them. This will be fixed when implement the DOM.  For now return true.
        }

        override fun toString(): String {
            return "empty"
        }
    }


    internal class PseudoClassNot(
        private val selectorGroup: List<Selector>
    ) : PseudoClass {

        override fun matches(ruleMatchContext: RuleMatchContext?, obj: SvgElementBase): Boolean {
            // If this element matches any of the selectors in the simpleSelectors group
            // provided to not, then :not fails to match.
            selectorGroup.forEachElement { selector ->
                if (ruleMatch(ruleMatchContext, selector, obj)) {
                    return false
                }
            }

            return true
        }

        val specificity: Int
            get() {
                // The specificity of :not is the highest specificity of the selectors in its simpleSelectors parameter list
                var highest = Int.MIN_VALUE

                selectorGroup.forEachElement { selector ->
                    if (selector.specificity > highest) {
                        highest = selector.specificity
                    }
                }

                return highest
            }

        override fun toString(): String {
            return "not($selectorGroup)"
        }
    }


    internal class PseudoClassTarget : PseudoClass {
        override fun matches(ruleMatchContext: RuleMatchContext?, obj: SvgElementBase): Boolean {
            return ruleMatchContext != null && obj === ruleMatchContext.targetElement
        }

        override fun toString(): String {
            return "target"
        }
    }


    internal class PseudoClassNotSupported(private val clazz: String) : PseudoClass {
        override fun matches(ruleMatchContext: RuleMatchContext?, obj: SvgElementBase): Boolean {
            return false
        }

        override fun toString(): String {
            return clazz
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


        /*
       private static void  error(String format, Object... args)
       {
          Log.e(TAG, String.format(format, args));
       }


       private static void  debug(String format, Object... args)
       {
          if (LibConfig.DEBUG)
             Log.d(TAG, String.format(format, args));
       }
       */
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
        @JvmStatic
        internal fun ruleMatch(
            ruleMatchContext: RuleMatchContext?,
            selector: Selector,
            obj: SvgElementBase
        ): Boolean {
            // Check the most common case first as a shortcut.
            if (selector.size() == 1) return selectorMatch(ruleMatchContext, selector.get(0), obj)

            // Build the list of ancestor objects
            val ancestors: MutableList<SvgContainer> = ArrayList()
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
            ancestors: MutableList<SvgContainer>,
            ancestorsPos: Int,
            obj: SvgElementBase
        ): Boolean {
            // We start at the last part of the simpleSelectors and loop back through the parts
            // Get the next simpleSelectors part
            var ancestorsPos = ancestorsPos
            val sel = selector.get(selPartPos)
            if (!selectorMatch(ruleMatchContext, sel, obj)) return false

            // Selector part matched, check its combinator
            when (sel.combinator) {
                Combinator.DESCENDANT -> {
                    if (selPartPos == 0) return true
                    // Search up the ancestors list for a node that matches the next simpleSelectors
                    while (ancestorsPos >= 0) {
                        if (ruleMatchOnAncestors(
                                ruleMatchContext,
                                selector,
                                selPartPos - 1,
                                ancestors,
                                ancestorsPos
                            )
                        ) return true
                        ancestorsPos--
                    }
                    return false
                }

                Combinator.CHILD -> {
                    return ruleMatchOnAncestors(
                        ruleMatchContext,
                        selector,
                        selPartPos - 1,
                        ancestors,
                        ancestorsPos
                    )
                }

                else  //if (sel.combinator == Combinator.FOLLOWS)
                    -> {
                    val childPos: Int = getChildPosition(ancestors, ancestorsPos, obj)
                    if (childPos <= 0) return false
                    val prevSibling = obj.parent!!.getChildren()[childPos - 1] as SvgElementBase
                    return ruleMatch(
                        ruleMatchContext,
                        selector,
                        selPartPos - 1,
                        ancestors,
                        ancestorsPos,
                        prevSibling
                    )
                }
            }
        }


        private fun ruleMatchOnAncestors(
            ruleMatchContext: RuleMatchContext?,
            selector: Selector,
            selPartPos: Int,
            ancestors: MutableList<SvgContainer>,
            ancestorsPos: Int
        ): Boolean {
            var ancestorsPos = ancestorsPos
            val sel = selector.get(selPartPos)
            val obj = ancestors[ancestorsPos] as SvgElementBase

            if (!selectorMatch(ruleMatchContext, sel, obj)) return false

            // Selector part matched, check its combinator
            when (sel.combinator) {
                Combinator.DESCENDANT -> {
                    if (selPartPos == 0) return true
                    // Search up the ancestors list for a node that matches the next simpleSelectors
                    while (ancestorsPos > 0) {
                        if (ruleMatchOnAncestors(
                                ruleMatchContext,
                                selector,
                                selPartPos - 1,
                                ancestors,
                                --ancestorsPos
                            )
                        ) return true
                    }
                    return false
                }

                Combinator.CHILD -> {
                    return ruleMatchOnAncestors(
                        ruleMatchContext,
                        selector,
                        selPartPos - 1,
                        ancestors,
                        ancestorsPos - 1
                    )
                }

                else  //if (sel.combinator == Combinator.FOLLOWS)
                    -> {
                    val childPos: Int = getChildPosition(ancestors, ancestorsPos, obj)
                    if (childPos <= 0) return false
                    val prevSibling = obj.parent!!.getChildren()[childPos - 1] as SvgElementBase
                    return ruleMatch(
                        ruleMatchContext,
                        selector,
                        selPartPos - 1,
                        ancestors,
                        ancestorsPos,
                        prevSibling
                    )
                }
            }
        }


        private fun getChildPosition(
            ancestors: MutableList<SvgContainer>,
            ancestorsPos: Int,
            obj: SvgElementBase
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
                if (children[childPos] === obj) return childPos
            }
            return -1
        }


        private fun selectorMatch(
            ruleMatchContext: RuleMatchContext?,
            sel: SimpleSelector,
            obj: SvgElementBase
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
                        // Other attribute simpleSelectors not yet supported
                        return false
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
