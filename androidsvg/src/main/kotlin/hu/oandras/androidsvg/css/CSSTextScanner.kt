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
package hu.oandras.androidsvg.css

import hu.oandras.androidsvg.parser.INVALID_CHAR
import hu.oandras.androidsvg.parser.IntegerParser
import hu.oandras.androidsvg.parser.IntegerParser.parseInt
import hu.oandras.androidsvg.parser.TextScanner
import hu.oandras.androidsvg.utils.compilePattern
import hu.oandras.androidsvg.utils.forEachElement
import java.util.regex.Pattern

internal class CSSTextScanner(input: String) : TextScanner(
    input = PATTERN_BLOCK_COMMENTS.matcher(input).replaceAll("")
) {
    /*
    * Scans for a CSS 'ident' identifier.
    */
    fun nextIdentifier(): String? {
        val end = scanForIdentifier()
        return if (end == position) {
            null
        } else {
            val result = input.substring(position, end)
            position = end
            result
        }
    }


    // ident-token:
    //   start-char rest-char*
    //   - start-char rest-char*
    //   -- rest-char*
    //
    // Where:
    //   start-char: a-z A-Z _ or escape or non-ASCII
    //   rest-char: a-z A-Z 0-9 _ - or escape non-ASCII
    //   escape:  (not yet implemented)
    //     \ char
    //     \ hexdigit{1-6}
    //     \ hexdigit{1-6} whitespace
    //   non-ASCII: >= U+0080
    //   whitespace: (space or \t or newline)+
    //   newline: \n or \r\n or \r or \f
    private fun scanForIdentifier(): Int {
        if (empty()) return position
        val start = position
        var lastValidPos = position

        var ch = input[position]
        if (ch == '-') ch = advanceChar()
        // start-char
        if (ch in 'A'..'Z' || ch in 'a'..'z' || ch == '-' || ch == '_' || ch >= 0x80.toChar()) {
            ch = advanceChar()
            // rest-char
            while (ch in 'A'..'Z' || ch in 'a'..'z' || ch in '0'..'9' || ch == '-' || ch == '_' || ch >= 0x80.toChar()) {
                ch = advanceChar()
            }
            lastValidPos = position
        }
        position = start
        return lastValidPos
    }

    /*
    * Parse a simpleSelectors group (eg. E, F, G). In many/most cases there will be only one entry.
    */
    @Throws(CSSParseException::class)
    internal fun nextSelectorGroup(): MutableList<CSSParser.Selector>? {
        if (empty()) return null

        val selectorGroup = ArrayList<CSSParser.Selector>(1)
        var selector = CSSParser.Selector()

        while (!empty()) {
            if (nextSimpleSelector(selector)) {
                // If there is a comma, keep looping, otherwise break
                if (!skipCommaWhitespace()) continue  // if not a comma, go back and check for next part of simpleSelectors

                selectorGroup.add(selector)
                selector = CSSParser.Selector()
            } else break
        }
        if (!selector.isEmpty) selectorGroup.add(selector)
        return selectorGroup
    }


    /*
    * Scans for a CSS 'simple simpleSelectors'.
    * Returns true if it found one.
    * Returns false if there was an error or the input is empty.
    */
    @Throws(CSSParseException::class)
    internal fun nextSimpleSelector(selector: CSSParser.Selector): Boolean {
        if (empty()) return false

        val start = position
        var combinator: CSSParser.Combinator? = null
        var selectorPart: CSSParser.SimpleSelector? = null

        if (!selector.isEmpty) {
            if (consume('>')) {
                combinator = CSSParser.Combinator.CHILD
                skipWhitespace()
            } else if (consume('+')) {
                combinator = CSSParser.Combinator.FOLLOWS
                skipWhitespace()
            }
        }

        if (consume('*')) {
            selectorPart = CSSParser.SimpleSelector(combinator, null)
        } else {
            val tag = nextIdentifier()
            if (tag != null) {
                selectorPart = CSSParser.SimpleSelector(combinator, tag)
                selector.addedElement()
            }
        }

        while (!empty()) {
            if (consume('.')) {
                // ".foo" is equivalent to *[class="foo"]
                if (selectorPart == null) {
                    selectorPart = CSSParser.SimpleSelector(combinator, null)
                }
                val value = nextIdentifier() ?: throw CSSParseException("Invalid \".class\" simpleSelectors")
                selectorPart.addAttrib(CSSParser.CLASS, CSSParser.AttribOp.EQUALS, value)
                selector.addedAttributeOrPseudo()
                continue
            }

            if (consume('#')) {
                // "#foo" is equivalent to *[id="foo"]
                if (selectorPart == null) {
                    selectorPart = CSSParser.SimpleSelector(combinator, null)
                }
                val value = nextIdentifier() ?: throw CSSParseException("Invalid \"#id\" simpleSelectors")
                selectorPart.addAttrib(CSSParser.ID, CSSParser.AttribOp.EQUALS, value)
                selector.addedIdAttribute()
                continue
            }

            // Now check for attribute selection and pseudo selectors
            if (consume('[')) {
                if (selectorPart == null) {
                    selectorPart = CSSParser.SimpleSelector(combinator, null)
                }
                skipWhitespace()
                val attrName = nextIdentifier() ?: throw CSSParseException("Invalid attribute simpleSelectors")
                var attrValue = ""
                skipWhitespace()

                val op: CSSParser.AttribOp? = if (consume('=')) {
                    CSSParser.AttribOp.EQUALS
                } else if (consume("~=")) {
                    CSSParser.AttribOp.INCLUDES
                } else if (consume("|=")) {
                    CSSParser.AttribOp.DASHMATCH
                } else {
                    null
                }

                if (op != null) {
                    skipWhitespace()
                    attrValue = nextAttribValue() ?: throw CSSParseException("Invalid attribute simpleSelectors")
                    skipWhitespace()
                }

                if (!consume(']')) {
                    throw CSSParseException("Invalid attribute simpleSelectors")
                }

                selectorPart.addAttrib(
                    attrName,
                    op ?: CSSParser.AttribOp.EXISTS,
                    attrValue
                )
                selector.addedAttributeOrPseudo()
                continue
            }

            if (consume(':')) {
                if (selectorPart == null) {
                    selectorPart = CSSParser.SimpleSelector(combinator, null)
                }
                parsePseudoClass(selector, selectorPart)
                continue
            }

            break
        }

        if (selectorPart != null) {
            selector.add(selectorPart)
            return true
        }

        // Otherwise 'fail'
        position = start
        return false
    }


    private class AnPlusB(
        @JvmField
        val a: Int,
        @JvmField
        val b: Int
    )


    private fun nextAnPlusB(): AnPlusB? {
        if (empty()) {
            return null
        }

        val start = position

        if (!consume('(')) {
            return null
        }
        skipWhitespace()

        val result = when {
            consume("odd") -> {
                AnPlusB(2, 1)
            }
            consume("even") -> {
                AnPlusB(2, 0)
            }
            else -> {
                // Parse an expression of the form +An+B
                // First check for an optional leading sign
                var aSign = 1
                var bSign = 1
                if (consume('+')) {
                    // do nothing
                } else if (consume('-')) {
                    bSign = -1
                }
                // Then an integer
                var a: IntegerParser.Result? = null
                var b = parseInt(input, position, inputLength, false)
                if (b != null) position = b.endPos
                // If an 'n' is next then that last part was the 'a' part. Now check for the 'b' part.
                if (consume('n') || consume('N')) {
                    a = b ?: IntegerParser.Result(1, position)
                    aSign = bSign
                    b = null
                    bSign = 1
                    skipWhitespace()
                    // Check for the sign for the b part
                    var hasB = consume('+')
                    if (!hasB) {
                        hasB = consume('-')
                        if (hasB) bSign = -1
                    }
                    // If there was a sign, then the b integer should follow next
                    if (hasB) {
                        skipWhitespace()
                        b = parseInt(input, position, inputLength, false)
                        if (b != null) {
                            position = b.endPos
                        } else {
                            position = start
                            return null
                        }
                    }
                }
                // Construct the result in anticipation that we will get the end bracket next
                AnPlusB(
                    if (a == null) 0 else aSign * a.value,
                    if (b == null) 0 else bSign * b.value
                )
            }
        }

        skipWhitespace()
        if (consume(')')) {
            return result
        }

        position = start
        return null
    }


    /*
    * Parse a list of identifiers from a pseudo class parameter set.
    * Eg. for :lang(en)
    */
    private fun nextIdentListParam(): MutableList<String>? {
        if (empty()) return null

        val start = position
        var result: ArrayList<String>? = null

        if (!consume('(')) return null
        skipWhitespace()

        do {
            val identifier = nextIdentifier()
            if (identifier == null) {
                position = start
                return null
            }
            if (result == null) result = ArrayList()
            result.add(identifier)
            skipWhitespace()
        } while (skipCommaWhitespace())

        if (consume(')')) return result

        position = start
        return null
    }


    /*
    * Parse a simpleSelectors group inside a pair of brackets.  For the :not pseudo class.
    */
    @Throws(CSSParseException::class)
    private fun nextPseudoNotParam(): List<CSSParser.Selector>? {
        if (empty()) return null

        val start = position

        if (!consume('(')) return null
        skipWhitespace()

        // Parse the parameter contents
        val result = nextSelectorGroup()

        if (result == null) {
            position = start
            return null
        }

        if (!consume(')')) {
            position = start
            return null
        }

        // Nesting a :not() pseudo class within a :not() is not allowed.
        for (i in result.indices) {
            val selector = result[i]
            val simpleSelectors = selector.simpleSelectors ?: break

            for (j in simpleSelectors.indices) {
                val simpleSelector = simpleSelectors[j]
                val pseudos = simpleSelector.pseudos ?: break
                pseudos.forEachElement { pseudo ->
                    if (pseudo is CSSParser.PseudoClassNot) {
                        return null
                    }
                }
            }
        }

        return result
    }


    /*
    * Parse a pseudo class (such as ":first-child")
    */
    @Throws(CSSParseException::class)
    private fun parsePseudoClass(selector: CSSParser.Selector, selectorPart: CSSParser.SimpleSelector) {
        // skip pseudo
//         int     pseudoStart = position;
        val identifier = nextIdentifier() ?: throw CSSParseException("Invalid pseudo class")

        val pseudo: CSSParser.PseudoClass?
        when (val identifierEnum = CSSParser.PseudoClassIdentifiers.fromString(identifier)) {
            CSSParser.PseudoClassIdentifiers.first_child -> {
                pseudo = CSSParser.PseudoClassAnPlusB(
                    a = 0,
                    b = 1,
                    isFromStart = true,
                    isOfType = false,
                    nodeName = null
                )
                selector.addedAttributeOrPseudo()
            }

            CSSParser.PseudoClassIdentifiers.last_child -> {
                pseudo = CSSParser.PseudoClassAnPlusB(
                    a = 0,
                    b = 1,
                    isFromStart = false,
                    isOfType = false,
                    nodeName = null
                )
                selector.addedAttributeOrPseudo()
            }

            CSSParser.PseudoClassIdentifiers.only_child -> {
                pseudo = CSSParser.PseudoClassOnlyChild(false, null)
                selector.addedAttributeOrPseudo()
            }

            CSSParser.PseudoClassIdentifiers.first_of_type -> {
                pseudo = CSSParser.PseudoClassAnPlusB(
                    a = 0,
                    b = 1,
                    isFromStart = true,
                    isOfType = true,
                    nodeName = selectorPart.tag
                )
                selector.addedAttributeOrPseudo()
            }

            CSSParser.PseudoClassIdentifiers.last_of_type -> {
                pseudo = CSSParser.PseudoClassAnPlusB(
                    a = 0,
                    b = 1,
                    isFromStart = false,
                    isOfType = true,
                    nodeName = selectorPart.tag
                )
                selector.addedAttributeOrPseudo()
            }

            CSSParser.PseudoClassIdentifiers.only_of_type -> {
                pseudo = CSSParser.PseudoClassOnlyChild(true, selectorPart.tag)
                selector.addedAttributeOrPseudo()
            }

            CSSParser.PseudoClassIdentifiers.root -> {
                pseudo = CSSParser.PseudoClassRoot()
                selector.addedAttributeOrPseudo()
            }

            CSSParser.PseudoClassIdentifiers.empty -> {
                pseudo = CSSParser.PseudoClassEmpty()
                selector.addedAttributeOrPseudo()
            }

            CSSParser.PseudoClassIdentifiers.nth_child,
            CSSParser.PseudoClassIdentifiers.nth_last_child,
            CSSParser.PseudoClassIdentifiers.nth_of_type,
            CSSParser.PseudoClassIdentifiers.nth_last_of_type -> {
                val fromStart = identifierEnum == CSSParser.PseudoClassIdentifiers.nth_child || identifierEnum == CSSParser.PseudoClassIdentifiers.nth_of_type
                val ofType = identifierEnum == CSSParser.PseudoClassIdentifiers.nth_of_type || identifierEnum == CSSParser.PseudoClassIdentifiers.nth_last_of_type
                val ab = nextAnPlusB()
                    ?: throw CSSParseException("Invalid or missing parameter section for pseudo class: $identifier")
                pseudo =
                    CSSParser.PseudoClassAnPlusB(ab.a, ab.b, fromStart, ofType, selectorPart.tag)
                selector.addedAttributeOrPseudo()
            }

            CSSParser.PseudoClassIdentifiers.not -> {
                val notSelectorGroup = nextPseudoNotParam()
                    ?: throw CSSParseException("Invalid or missing parameter section for pseudo class: $identifier")
                pseudo = CSSParser.PseudoClassNot(notSelectorGroup)
                selector.specificity = pseudo.specificity
            }

            CSSParser.PseudoClassIdentifiers.target -> {
                //TODO
                pseudo = CSSParser.PseudoClassTarget()
                selector.addedAttributeOrPseudo()
            }

            CSSParser.PseudoClassIdentifiers.lang -> {
                val _ = nextIdentListParam()
                pseudo = CSSParser.PseudoClassNotSupported(identifier)
                selector.addedAttributeOrPseudo()
            }

            CSSParser.PseudoClassIdentifiers.link,
            CSSParser.PseudoClassIdentifiers.visited,
            CSSParser.PseudoClassIdentifiers.hover,
            CSSParser.PseudoClassIdentifiers.active,
            CSSParser.PseudoClassIdentifiers.focus,
            CSSParser.PseudoClassIdentifiers.enabled,
            CSSParser.PseudoClassIdentifiers.disabled,
            CSSParser.PseudoClassIdentifiers.checked,
            CSSParser.PseudoClassIdentifiers.indeterminate -> {
                pseudo = CSSParser.PseudoClassNotSupported(identifier)
                selector.addedAttributeOrPseudo()
            }

            else -> throw CSSParseException("Unsupported pseudo class: $identifier")
        }

//      selectorPart.addPseudo(input.substring(pseudoStart, position));
        selectorPart.addPseudo(pseudo)
//      simpleSelectors.addedAttributeOrPseudo();
    }


    /*
    * The value (bar) part of "[foo="bar"]".
    */
    private fun nextAttribValue(): String? {
        if (empty()) return null
        return nextQuotedString() ?: nextIdentifier()
    }

    /*
    * Scans for a CSS property value.
    */
    fun nextPropertyValue(): String? {
        if (empty()) return null
        val start = position
        var lastValidPos = position

        var ch = input[position]
        while (ch != INVALID_CHAR && ch != ';' && ch != '}' && ch != '!' && !isEOL(ch)) {
            if (!isWhitespace(ch))  // don't include a spaces at the end
                lastValidPos = position + 1
            ch = advanceChar()
        }
        if (position > start) return input.substring(start, lastValidPos)
        position = start
        return null
    }

    /*
    * Scans for a string token
    */
    fun nextCSSString(): String? {
        if (empty()) return null
        var ch = input[position]
        val endQuote = ch
        if (ch != '\'' && ch != '"') return null

        val sb = StringBuilder()
        position++
        ch = nextChar()
        while (ch != INVALID_CHAR && ch != endQuote) {
            if (ch == '\\') {
                // Escaped char sequence
                ch = nextChar()
                if (ch == INVALID_CHAR)  // EOF: do nothing
                    continue
                if (ch == '\n' || ch == '\r' || ch == '\u000C') {  // a CSS newline
                    ch = nextChar()
                    continue  // Newline: consume it
                }
                var hc = hexChar(ch)
                if (hc != -1) {
                    var codepoint = hc
                    for (_ in 1..5) {
                        ch = nextChar()
                        hc = hexChar(ch)
                        if (hc == -1) break
                        codepoint = codepoint * 16 + hc
                    }
                    sb.append(codepoint.toChar())
                    continue
                }
                // Other chars just unescape to themselves
                // Fall through to append
            }
            sb.append(ch)
            ch = nextChar()
        }
        return sb.toString()
    }


    private fun hexChar(ch: Char): Int {
        return when (ch) {
            in '0'..'9' -> ch - '0'
            in 'A'..'F' -> ch - 'A' + 10
            in 'a'..'f' -> ch - 'a' + 10
            else -> -1
        }
    }

    /*
    * Scans for a url("...")
    * Called a <url> in the CSS spec.
    */
    fun nextURL(): String? {
        if (empty()) return null
        val start = position
        if (!consume("url(")) return null

        skipWhitespace()

        val url = nextCSSString()
            ?: nextLegacyURL() // legacy quote-less url(...).  Called a <url-token> in the CSS3 spec.

        if (url == null) {
            position = start
            return null
        }

        skipWhitespace()

        if (empty() || consume(')')) return url

        position = start
        return null
    }


    /*
    * Scans for a legacy URL string
    * See nextURLToken().
    */
    fun nextLegacyURL(): String? {
        val sb = StringBuilder()

        while (!empty()) {
            var ch = input[position]

            if (
                ch == '\'' ||
                ch == '"' ||
                ch == '(' ||
                ch == ')' ||
                isWhitespace(ch) ||
                ch.isISOControl()
            ) {
                break
            }

            position++
            if (ch == '\\') {
                if (empty())  // EOF: do nothing
                    continue
                // Escaped char sequence
                ch = input[position++]
                if (ch == '\n' || ch == '\r' || ch == '\u000C') {  // a CSS newline
                    continue  // Newline: consume it
                }
                var hc = hexChar(ch)
                if (hc != -1) {
                    var codepoint = hc
                    for (_ in 1..5) {
                        if (empty()) break
                        hc = hexChar(input[position])
                        if (hc == -1)  // Not a hex char
                            break
                        position++
                        codepoint = codepoint * 16 + hc
                    }
                    sb.append(codepoint.toChar())
                    continue
                }
                // Other chars just unescape to themselves
                // Fall through to append
            }
            sb.append(ch)
        }
        if (sb.isEmpty()) return null
        return sb.toString()
    }

    companion object {
        @JvmField
        val PATTERN_BLOCK_COMMENTS: Pattern = compilePattern("(?s)/\\*.*?\\*/")
    }
}
