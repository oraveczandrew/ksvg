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

import androidx.collection.ArraySet
import hu.oandras.ksvg.parser.TextScanner
import java.util.*

private const val FEATURE_STRING_PREFIX = "http://www.w3.org/TR/SVG11/feature#"

// Any element that can appear inside a <switch> element.
internal interface Conditional {
    val requiredFeatures: Set<String>?
    val requiredExtensions: String?
    val systemLanguage: Set<String>?
    val requiredFormats: Set<String>?
    val requiredFonts: Set<String>?
}

//=========================================================================
// Conditional processing (ie for <switch> element)
// Parse the attribute that declares the list of SVG features that must be
// supported if we are to render this element
internal fun parseRequiredFeatures(value: String): Set<String> {
    val scan = TextScanner(value)
    val result = ArraySet<String>()

    while (!scan.empty()) {
        val feature = scan.requireNextToken()
        if (feature.startsWith(FEATURE_STRING_PREFIX)) {
            result.add(feature.substring(FEATURE_STRING_PREFIX.length))
        } else {
            // Not a feature string we recognize or support. (In order to avoid accidentally
            // matches with our truncated feature strings, we'll replace it with a string
            // we know for sure won't match anything.)
            result.add("UNSUPPORTED")
        }
        scan.skipWhitespace()
    }
    return result
}


// Parse the attribute that declares the list of languages, one of which
// must be supported if we are to render this element
internal fun parseSystemLanguage(value: String): Set<String> {
    val scan = TextScanner(value)
    val result = ArraySet<String>()

    while (!scan.empty()) {
        var language = scan.requireNextToken()
        val hyphenPos = language.indexOf('-')
        if (hyphenPos != -1) {
            language = language.substring(0, hyphenPos)
        }
        language = Locale.forLanguageTag(language).language
        result.add(language)
        scan.skipWhitespace()
    }
    return result
}


// Parse the attribute that declares the list of MIME types that must be
// supported if we are to render this element
internal fun parseRequiredFormats(value: String): Set<String> {
    val scan = TextScanner(value)
    val result = ArraySet<String>()

    while (!scan.empty()) {
        val mimetype = scan.requireNextToken()
        result.add(mimetype)
        scan.skipWhitespace()
    }
    return result
}