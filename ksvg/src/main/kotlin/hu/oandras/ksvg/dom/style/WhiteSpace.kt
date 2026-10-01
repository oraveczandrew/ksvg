/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.dom.style

/**
 * CSS `white-space` property (`normal | nowrap | pre | pre-line |
 * pre-wrap | break-spaces`). Inherited.
 *
 * Chrome parity (measured, see `tmp/BROWSER_TEXT_PARITY.md`): no engine
 * wraps SVG `<text>`, and Chrome collapses newlines everywhere. So the
 * wrapping values behave like their non-wrapping base (`pre-wrap` and
 * `break-spaces` preserve like `pre`; `pre-line` collapses like `normal`),
 * and newlines never break (see `textXMLSpaceTransform`).
 */
@Suppress("EnumEntryName")
internal enum class WhiteSpace {
    normal,
    nowrap,
    pre,
    preLine,
    preWrap,
    breakSpaces;

    /** True when spaces/tabs survive (no collapsing). */
    internal val preservesSpaces: Boolean
        get() = this == pre || this == preWrap || this == breakSpaces
}

// Parses a white-space value; null when invalid (two-value shorthands
// like "pre-wrap nowrap" are out of scope and ignored).
internal fun parseWhiteSpace(value: String): WhiteSpace? {
    return when {
        value.equals("normal", ignoreCase = true) -> WhiteSpace.normal
        value.equals("nowrap", ignoreCase = true) -> WhiteSpace.nowrap
        value.equals("pre", ignoreCase = true) -> WhiteSpace.pre
        value.equals("pre-line", ignoreCase = true) -> WhiteSpace.preLine
        value.equals("pre-wrap", ignoreCase = true) -> WhiteSpace.preWrap
        value.equals("break-spaces", ignoreCase = true) -> WhiteSpace.breakSpaces
        else -> null
    }
}
