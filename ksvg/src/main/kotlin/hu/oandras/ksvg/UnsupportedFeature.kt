/*
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

package hu.oandras.ksvg

import androidx.annotation.IntDef
import androidx.collection.MutableIntSet

/**
 * Deferred/unsupported SVG features that deserve a warning when an SVG
 * actually asks for the unimplemented behavior (not for values that
 * already behave correctly). Plain ids (not a bitmask); new features take
 * the next free id.
 */
@Retention(AnnotationRetention.SOURCE)
@IntDef(
    value = [
        UnsupportedFeature.WHITE_SPACE_WRAP,
        UnsupportedFeature.LINE_HEIGHT,
        UnsupportedFeature.TEXT_OVERFLOW,
    ]
)
internal annotation class UnsupportedFeature {
    companion object {
        /** `white-space` wrapping values (`pre-wrap`, `pre-line`, `break-spaces`). */
        const val WHITE_SPACE_WRAP: Int = 0

        /** Non-`normal` `line-height` (no multi-line layout to apply it to). */
        const val LINE_HEIGHT: Int = 1

        /** `text-overflow: ellipsis` (no wrapping area exists on SVG text). */
        const val TEXT_OVERFLOW: Int = 2
    }
}

/**
 * [LoggerContext] wrapper that dedupes [logUnsupportedFeature] warnings
 * per parsed document: the first occurrence of each feature logs through
 * [delegate], repeats stay silent. One wrapper instance covers one parse
 * (see `createParser`); a fresh parse logs afresh.
 */
private class UnsupportedFeatureLoggerContext(val delegate: LoggerContext) : LoggerContext by delegate {
    private val warned: MutableIntSet = MutableIntSet()

    fun markWarned(@UnsupportedFeature feature: Int): Boolean = warned.add(feature)
}

private fun unsupportedFeatureMessage(@UnsupportedFeature feature: Int): String {
    return when (feature) {
        UnsupportedFeature.WHITE_SPACE_WRAP ->
            "white-space wrapping (pre-wrap/pre-line/break-spaces) is not supported " +
                "(SVG <text> has no wrapping area); declaration ignored"
        UnsupportedFeature.LINE_HEIGHT ->
            "line-height is not supported (text layout is single-line); declaration ignored"
        UnsupportedFeature.TEXT_OVERFLOW ->
            "text-overflow: ellipsis needs a wrapping area, which SVG <text> has none of; " +
                "declaration ignored"
        else -> "unsupported feature ($feature); declaration ignored"
    }
}

/**
 * Returns this context wrapped for per-parse [logUnsupportedFeature]
 * dedup. Already-wrapped contexts pass through unchanged.
 */
internal fun LoggerContext.wrapAsUnsupportedFeatureLoggerContext(): LoggerContext =
    this as? UnsupportedFeatureLoggerContext ?: UnsupportedFeatureLoggerContext(this)

/**
 * Logs a warning for a deferred feature, deduped by the surrounding
 * [UnsupportedFeatureLoggerContext] (one log per feature per parse).
 * On a bare [LoggerContext] every call logs.
 *
 * Callers decide WHEN a value actually needs the unimplemented behavior
 * (e.g. `white-space: normal` never calls this); this only dedupes.
 */
internal fun LoggerContext.logUnsupportedFeature(@UnsupportedFeature feature: Int) {
    if (this is UnsupportedFeatureLoggerContext && !markWarned(feature)) return
    logW("KSVG") { unsupportedFeatureMessage(feature) }
}
