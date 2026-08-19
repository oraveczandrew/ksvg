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

package hu.oandras.ksvg.dom.core

internal data class ConditionalBundle(
    override val requiredFeatures: Set<String>?,
    override val requiredExtensions: String?,
    override val systemLanguage: Set<String>?,
    override val requiredFormats: Set<String>?,
    override val requiredFonts: Set<String>?,
): Conditional

private var EmptySvgConditionalBundle: ConditionalBundle? = null

private fun emptyConditionalBundle(): ConditionalBundle {
    return EmptySvgConditionalBundle ?: ConditionalBundle(
        requiredFeatures = null,
        requiredExtensions = null,
        systemLanguage = null,
        requiredFormats = null,
        requiredFonts = null
    ).also {
        EmptySvgConditionalBundle = it
    }
}

internal fun Conditional(
    requiredFeatures: Set<String>?,
    requiredExtensions: String?,
    systemLanguage: Set<String>?,
    requiredFormats: Set<String>?,
    requiredFonts: Set<String>?,
): Conditional {
    return if (requiredFeatures != null || requiredExtensions != null || systemLanguage != null || requiredFormats != null || requiredFonts != null) {
        ConditionalBundle(
            requiredFeatures = requiredFeatures,
            requiredExtensions = requiredExtensions,
            requiredFormats = requiredFormats,
            requiredFonts = requiredFonts,
            systemLanguage = systemLanguage,
        )
    } else {
        emptyConditionalBundle()
    }
}