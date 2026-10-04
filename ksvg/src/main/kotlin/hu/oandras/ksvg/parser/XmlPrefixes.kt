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

@file:Suppress("SpellCheckingInspection")

package hu.oandras.ksvg.parser

/**
 * Namespace prefix without allocating: the prefixes seen in the wild map to
 * canonical constants; anything else falls back to a substring (rare enough
 * to not matter).
 *
 * @param qualified the `prefix:local` qualified name.
 * @param cut index of the `:` separator within [qualified].
 */
internal fun canonicalPrefix(qualified: String, cut: Int): String {
    when (cut) {
        1 -> {
            if (qualified.regionMatches(0, "i", 0, 1)) return "i"
            if (qualified.regionMatches(0, "a", 0, 1)) return "a"
        }
        2 -> {
            if (qualified.regionMatches(0, "dc", 0, 2)) return "dc"
            if (qualified.regionMatches(0, "cc", 0, 2)) return "cc"
        }
        3 -> {
            if (qualified.regionMatches(0, "xml", 0, 3)) return "xml"
            if (qualified.regionMatches(0, "svg", 0, 3)) return "svg"
            if (qualified.regionMatches(0, "rdf", 0, 3)) return "rdf"
            if (qualified.regionMatches(0, "xmp", 0, 3)) return "xmp"
        }
        4 -> {
            if (qualified.regionMatches(0, "math", 0, 4)) return "math"
        }
        5 -> {
            if (qualified.regionMatches(0, "xmlns", 0, 5)) return "xmlns"
            if (qualified.regionMatches(0, "xlink", 0, 5)) return "xlink"
            if (qualified.regionMatches(0, "xhtml", 0, 5)) return "xhtml"
        }
        6 -> {
            if (qualified.regionMatches(0, "sketch", 0, 6)) return "sketch"
        }
        7 -> {
            if (qualified.regionMatches(0, "dcterms", 0, 7)) return "dcterms"
        }
        8 -> {
            if (qualified.regionMatches(0, "sodipodi", 0, 8)) return "sodipodi"
            if (qualified.regionMatches(0, "inkscape", 0, 8)) return "inkscape"
        }
    }

    return qualified.substring(0, cut)
}
