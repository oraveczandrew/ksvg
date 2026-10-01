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

package hu.oandras.ksvg.render.text

/**
 * Reorders one text chunk into visual order for `unicode-bidi:
 * bidi-override` / `isolate-override` with a forced base direction.
 *
 * An override forces every character (except explicit codes) to a single
 * embedding level, so UBA rule L2 collapses to one full reversal — no
 * level computation is needed. Characters are grouped into clusters
 * (starter + following combining marks) so marks travel with their base,
 * and surrogates are kept intact. `direction` only picks the side: an RTL
 * base reverses, an LTR base is the identity (returned as null).
 *
 * Deliberately NOT built on `java.text.Bidi` levels: measured on the
 * host JDK, its level assignment is unusable for L2 here (explicit RTL
 * base reports content level 2, and LRO is ignored entirely), and the
 * information would not change the outcome inside the supported domain
 * anyway. `java.text.Bidi` availability (API 1, no ICU need for
 * `minSdk 26`) therefore stays a fact, not a dependency.
 *
 * Returns null when there is nothing (safe) to do:
 * - Empty text, a single cluster, or visual order identical to logical;
 * - Text containing strong right-to-left characters (R/AL): feeding an
 *   already-visual RTL run back into `drawText` would make the platform
 *   bidirectional algorithm reorder it a second time; such chunks keep
 *   today's behavior (the platform orders them, which is near-correct
 *   for an RTL base);
 * - Text containing explicit bidi codes (embeddings, overrides,
 *   isolates, PDF/PDI) or paragraph separators: nested levels would need
 *   real UBA resolution — deferred with the rest of G12.
 *
 * Bracket mirroring (UBA rule M) is not applied either — deferred.
 *
 * Build-time only: allocates freely, never called on the render hot path.
 * The returned string is safe for a single `drawText` call (no strong RTL
 * characters and no explicit codes, so the platform algorithm keeps its
 * order).
 */
internal fun visualOrderForOverride(logical: String, baseRtl: Boolean): String? {
    if (logical.isEmpty() || !baseRtl) return null
    if (!isReorderable(logical)) return null

    // Cluster starts (char offsets): a cluster starts at every non-mark
    // code point; combining marks join the previous cluster.
    val starts = IntArray(logical.length + 1)
    var clusterCount = 0
    var i = 0
    while (i < logical.length) {
        starts[clusterCount++] = i
        i += Character.charCount(Character.codePointAt(logical, i))
        while (i < logical.length) {
            val next = Character.codePointAt(logical, i)
            when (Character.getType(next)) {
                Character.NON_SPACING_MARK.toInt(),
                Character.ENCLOSING_MARK.toInt(),
                Character.COMBINING_SPACING_MARK.toInt() -> i += Character.charCount(next)
                else -> break
            }
        }
    }
    if (clusterCount <= 1) return null

    val builder = StringBuilder(logical.length)
    for (c in clusterCount - 1 downTo 0) {
        val from = starts[c]
        val to = if (c + 1 < clusterCount) starts[c + 1] else logical.length
        builder.append(logical, from, to)
    }
    val visual = builder.toString()
    return if (visual == logical) null else visual
}

/**
 * True when the chunk is inside the reversal domain: no strong-RTL
 * characters, no explicit bidi codes, no paragraph separators.
 */
private fun isReorderable(text: String): Boolean {
    var i = 0
    while (i < text.length) {
        val codePoint = Character.codePointAt(text, i)
        when (Character.getDirectionality(codePoint)) {
            Character.DIRECTIONALITY_RIGHT_TO_LEFT,
            Character.DIRECTIONALITY_RIGHT_TO_LEFT_ARABIC,
            Character.DIRECTIONALITY_LEFT_TO_RIGHT_EMBEDDING,
            Character.DIRECTIONALITY_LEFT_TO_RIGHT_OVERRIDE,
            Character.DIRECTIONALITY_RIGHT_TO_LEFT_EMBEDDING,
            Character.DIRECTIONALITY_RIGHT_TO_LEFT_OVERRIDE,
            Character.DIRECTIONALITY_POP_DIRECTIONAL_FORMAT,
            Character.DIRECTIONALITY_LEFT_TO_RIGHT_ISOLATE,
            Character.DIRECTIONALITY_RIGHT_TO_LEFT_ISOLATE,
            Character.DIRECTIONALITY_FIRST_STRONG_ISOLATE,
            Character.DIRECTIONALITY_POP_DIRECTIONAL_ISOLATE,
            Character.DIRECTIONALITY_PARAGRAPH_SEPARATOR -> return false
        }
        i += Character.charCount(codePoint)
    }
    return true
}
