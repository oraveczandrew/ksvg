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

import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.ElementBase
import hu.oandras.ksvg.utils.forEachElement
import java.util.*
import kotlin.math.sign

internal sealed interface PseudoClass {
    fun matches(ruleMatchContext: CSSParser.RuleMatchContext?, obj: ElementBase): Boolean

    val specificity: Int
        get() = 0
}

internal class PseudoClassAnPlusB(
    private val a: Int,
    private val b: Int,
    private val isFromStart: Boolean,
    private val isOfType: Boolean, // The node name for when isOfType is true
    private val nodeName: String?
) : PseudoClass {

    override fun matches(ruleMatchContext: CSSParser.RuleMatchContext?, obj: ElementBase): Boolean {
        // For "*-of-type" pseudo-classes with no explicit node name, count only children of the element's own type.
        val nodeNameToCheck = if (isOfType && nodeName == null) obj.getNodeName() else nodeName

        // Initialize with correct values for root element
        var childPos = 0
        var childCount = 1

        // If this is not the root element, then determine
        // this objects sibling position and total sibling count
        obj.parent?.let { parent ->
            childCount = 0
            parent.getChildren().forEachElement { node ->
                val child = node as ElementBase // This should be safe. We shouldn't be styling any SvgObject that isn't an element.
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
    override fun matches(ruleMatchContext: CSSParser.RuleMatchContext?, obj: ElementBase): Boolean {
        // For "*-of-type" pseudo-classes with no explicit node name, count only children of the element's own type.
        val nodeNameToCheck = if (isOfType && nodeName == null) obj.getNodeName() else nodeName

        // Initialize with correct values for root element
        var childCount = 1

        // If this is not the root element, then determine
        // this objects sibling position and total sibling count
        val parent = obj.parent
        if (parent != null) {
            childCount = 0
            parent.getChildren().forEachElement { node ->
                val child = node as ElementBase // This should be safe. We shouldn't be styling any SvgObject that isn't an element.
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


internal data object PseudoClassRoot : PseudoClass {
    override fun matches(ruleMatchContext: CSSParser.RuleMatchContext?, obj: ElementBase): Boolean {
        return obj.parent == null
    }

    override fun toString(): String {
        return "root"
    }
}

internal data object PseudoClassEmpty : PseudoClass {
    override fun matches(ruleMatchContext: CSSParser.RuleMatchContext?, obj: ElementBase): Boolean {
        // An element is considered empty when it has no child elements or text content.
        // Elements whose children are dropped/ignored during rendering are treated as empty.
        return obj !is Container || obj.getChildren().isEmpty()
    }

    override fun toString(): String {
        return "empty"
    }
}

internal class PseudoClassNot(
    private val selectorGroup: List<CSSParser.Selector>
) : PseudoClass {

    override fun matches(ruleMatchContext: CSSParser.RuleMatchContext?, obj: ElementBase): Boolean {
        // If this element matches any of the selectors in the simpleSelectors group
        // provided to not, then :not fails to match.
        selectorGroup.forEachElement { selector ->
            if (CSSParser.ruleMatch(ruleMatchContext, selector, obj)) {
                return false
            }
        }

        return true
    }

    override val specificity: Int
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


internal data object PseudoClassTarget : PseudoClass {
    override fun matches(ruleMatchContext: CSSParser.RuleMatchContext?, obj: ElementBase): Boolean {
        return ruleMatchContext != null && obj === ruleMatchContext.targetElement
    }

    override fun toString(): String {
        return "target"
    }
}


internal class PseudoClassNotSupported(private val clazz: String) : PseudoClass {
    override fun matches(ruleMatchContext: CSSParser.RuleMatchContext?, obj: ElementBase): Boolean {
        return false
    }

    override fun toString(): String {
        return clazz
    }
}
