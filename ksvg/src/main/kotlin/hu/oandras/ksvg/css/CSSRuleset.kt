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

import hu.oandras.ksvg.utils.forEachElement
import java.util.*

internal class CSSRuleset {

    private var _rules: MutableList<CSSRule>? = null

    val rules: List<CSSRule>
        get() = _rules ?: emptyList()

    // Add a rule to the ruleset. The position at which it is inserted is determined by its specificity value.
    fun add(rule: CSSRule) {
        val rules = _rules ?: LinkedList<CSSRule>().also {
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

    fun addAll(set: CSSRuleset) {
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