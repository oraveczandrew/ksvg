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

package hu.oandras.ksvg.logger

import androidx.annotation.IntDef
import androidx.collection.ArraySet
import androidx.collection.MutableIntSet

/**
 * Deferred/unsupported SVG features that deserve a warning when an SVG
 * actually asks for the unimplemented behavior (not for values that
 * already behave correctly). Plain ids (not a bitmask); new features take
 * the next free id.
 *
 * Only for properties we DO recognize, where a specific *value* asks for
 * behavior we don't implement. Names we don't know at all are reported by
 * [logUnsupportedElement] / [logUnsupportedAttribute] instead.
 */
@Retention(AnnotationRetention.SOURCE)
@IntDef(
    value = [
        UnsupportedFeature.WHITE_SPACE_WRAP,
        UnsupportedFeature.LINE_HEIGHT,
        UnsupportedFeature.TEXT_OVERFLOW,
        UnsupportedFeature.MIX_BLEND_MODE_PLUS,
        UnsupportedFeature.CLIP_PATH_ROUND_CORNERS,
        UnsupportedFeature.ALTERNATE_STYLESHEET,
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

        /**
         * CSS Compositing 2 `mix-blend-mode` keywords (`plus-darker`,
         * `plus-lighter`): no software-blend equivalent, treated as `normal`.
         */
        const val MIX_BLEND_MODE_PLUS: Int = 3

        /**
         * `clip-path` shape `round()` with a per-corner radius list (CSS Borders 4
         * form); only a single radius is implemented, so the clip is dropped.
         */
        const val CLIP_PATH_ROUND_CORNERS: Int = 4

        /**
         * `<?xml-stylesheet alternate="yes" ...?>`: only the primary stylesheet
         * is applied, alternates are skipped.
         */
        const val ALTERNATE_STYLESHEET: Int = 5
    }
}

/**
 * The [LoggerScope] behind [UNSUPPORTED_FEATURE_SCOPE]: dedupes
 * [logUnsupportedFeature], [logUnsupportedElement], [logUnsupportedAttribute],
 * [logUnsupportedPseudoClass], [logUnsupportedAtRule] and
 * [logUnsupportedAnimatedAttribute] warnings per parsed document — the first
 * occurrence of each feature / tag / attribute / pseudo-class / at-rule /
 * animated-attribute name is logged, repeats stay silent. One instance
 * covers one parse (see [wrapAsUnsupportedFeatureScope]); a fresh parse logs
 * afresh.
 */
internal class UnsupportedFeatureScope : LoggerScope {

    private val warnedFeatures: MutableIntSet = MutableIntSet(0)
    private val warnedElements: ArraySet<String> = ArraySet(0)
    private val warnedAttributes: ArraySet<String> = ArraySet(0)
    private val warnedPseudoClasses: ArraySet<String> = ArraySet(0)
    private val warnedAtRules: ArraySet<String> = ArraySet(0)
    private val warnedAnimatedAttributes: ArraySet<String> = ArraySet(0)

    fun markFeatureWarned(@UnsupportedFeature feature: Int): Boolean = warnedFeatures.add(feature)

    fun markElementWarned(tag: String): Boolean = warnedElements.add(tag)

    fun markAttributeWarned(name: String): Boolean = warnedAttributes.add(name)

    fun markPseudoClassWarned(name: String): Boolean = warnedPseudoClasses.add(name)

    fun markAtRuleWarned(keyword: String): Boolean = warnedAtRules.add(keyword)

    fun markAnimatedAttributeWarned(name: String): Boolean = warnedAnimatedAttributes.add(name)
}

/**
 * [LoggerScope] name of the per-parse unsupported-warning dedup state.
 */
private const val UNSUPPORTED_FEATURE_SCOPE = "ksvg.unsupportedFeature"

/**
 * The innermost link of the per-parse chain: owns [UnsupportedFeatureScope] and
 * answers for that one scope name, while [findScope] continues into [delegate],
 * the caller's own context, for everything else.
 */
private class UnsupportedFeatureScopeContext(
    override val delegate: LoggerContext,
    private val scope: UnsupportedFeatureScope,
) : ScopedLoggerContext, LoggerContext by delegate {

    override fun getScope(name: String): LoggerScope? =
        if (name == UNSUPPORTED_FEATURE_SCOPE) scope else null
}

/**
 * Returns this context wrapped so that [logUnsupportedFeature],
 * [logUnsupportedElement], [logUnsupportedAttribute],
 * [logUnsupportedPseudoClass], [logUnsupportedAtRule] and
 * [logUnsupportedAnimatedAttribute] dedup per parse.
 * Already-scoped contexts pass through unchanged.
 *
 * This is the single place the scope is created: the parser wraps the caller's
 * context here and hands the same instance to the document it builds, so the
 * whole chain (document, DOM builders, CSS parsing) shares one dedup scope.
 */
internal fun LoggerContext.wrapAsUnsupportedFeatureScope(): LoggerContext =
    this as? ScopedLoggerContext ?: UnsupportedFeatureScopeContext(this, UnsupportedFeatureScope())

private fun LoggerContext.unsupportedFeatureScope(): UnsupportedFeatureScope? =
    findScope(UNSUPPORTED_FEATURE_SCOPE) as? UnsupportedFeatureScope

private fun unsupportedFeatureMessage(@UnsupportedFeature feature: Int): String =
    when (feature) {
        UnsupportedFeature.WHITE_SPACE_WRAP ->
            "white-space wrapping (pre-wrap/pre-line/break-spaces) is not supported " +
                "(SVG <text> has no wrapping area); declaration ignored"
        UnsupportedFeature.LINE_HEIGHT ->
            "line-height is not supported (text layout is single-line); declaration ignored"
        UnsupportedFeature.TEXT_OVERFLOW ->
            "text-overflow: ellipsis needs a wrapping area, which SVG <text> has none of; " +
                "declaration ignored"
        UnsupportedFeature.MIX_BLEND_MODE_PLUS ->
            "mix-blend-mode plus-darker/plus-lighter is not supported; treated as normal"
        UnsupportedFeature.CLIP_PATH_ROUND_CORNERS ->
            "clip-path round() with per-corner radii is not supported; declaration ignored"
        UnsupportedFeature.ALTERNATE_STYLESHEET ->
            "alternate stylesheets are not supported; stylesheet ignored"
        else -> "unsupported feature ($feature); declaration ignored"
    }

/**
 * Logs a warning for a deferred feature, deduped by the surrounding
 * [UnsupportedFeatureScope] (one log per feature per parse). A context with no
 * such scope in its chain ([findScope] finds none) logs every call.
 *
 * Callers decide WHEN a value actually needs the unimplemented behavior
 * (e.g., `white-space: normal` never calls this); this only dedupes.
 */
internal fun LoggerContext.logUnsupportedFeature(
    @UnsupportedFeature
    feature: Int,
) {
    val scope = unsupportedFeatureScope()
    if (scope != null && !scope.markFeatureWarned(feature)) return
    logW("KSVG") { unsupportedFeatureMessage(feature) }
}

/**
 * Logs a warning for a dropped unsupported element (e.g., `<foreignObject>`),
 * deduped by tag name by the surrounding [UnsupportedFeatureScope] (one log per
 * tag name per parse). A context with no such scope in its chain logs every call.
 */
internal fun LoggerContext.logUnsupportedElement(tag: String) {
    val scope = unsupportedFeatureScope()
    if (scope != null && !scope.markElementWarned(tag)) return
    logW("KSVG") { "Unsupported element <$tag> ignored" }
}

/**
 * Logs a warning for a dropped unknown presentation attribute (e.g.,
 * `foo="bar"`), deduped by attribute name by the surrounding
 * [UnsupportedFeatureScope] (one log per name per parse). A context with no such
 * scope in its chain logs every call.
 *
 * Only for names outside our vocabulary. A known property whose value asks
 * for unimplemented behavior is reported by [logUnsupportedFeature] instead,
 * and CSS declarations (rather than attributes) stay silent.
 *
 * Note: the name is the SAX local name, so namespace prefixes are already
 * stripped: `inkscape:label` reports as `label`.
 */
internal fun LoggerContext.logUnsupportedAttribute(name: String) {
    val scope = unsupportedFeatureScope()
    if (scope != null && !scope.markAttributeWarned(name)) return
    logW("KSVG") { "Unsupported attribute <$name> ignored" }
}

/**
 * Logs a warning for a recognized but unimplemented CSS pseudo-class (e.g.,
 * `:hover`), deduped by pseudo-class name by the surrounding
 * [UnsupportedFeatureScope] (one log per name per parse). A context with no
 * such scope in its chain logs every call.
 *
 * The name is already lowercase: pseudo-classes are ASCII case-insensitive,
 * so `:HOVER` and `:hover` dedup together.
 */
internal fun LoggerContext.logUnsupportedPseudoClass(name: String) {
    val scope = unsupportedFeatureScope()
    if (scope != null && !scope.markPseudoClassWarned(name)) return
    logW("KSVG") { "Unsupported pseudo-class :$name ignored" }
}

/**
 * Logs a warning for a dropped unknown/unsupported CSS at-rule (e.g.,
 * `@foobar`), deduped by keyword by the surrounding [UnsupportedFeatureScope]
 * (one log per keyword per parse). A context with no such scope in its chain
 * logs every call.
 *
 * The keyword is already lowercase: at-rule names are ASCII case-insensitive,
 * so `@FOOBAR` and `@foobar` dedup together.
 */
internal fun LoggerContext.logUnsupportedAtRule(keyword: String) {
    val scope = unsupportedFeatureScope()
    if (scope != null && !scope.markAtRuleWarned(keyword)) return
    logW("KSVG") { String.format("Ignoring @%s rule", keyword) }
}

/**
 * Logs a warning for an animation targeting an attribute the animator cannot
 * drive (e.g., `<animate attributeName="display">`), deduped by attribute name
 * by the surrounding [UnsupportedFeatureScope] (one log per name per parse).
 * A context with no such scope in its chain logs every call.
 *
 * Out-of-vocabulary targets are reported at parse time by
 * [logUnsupportedAttribute] instead, so names reaching here are either known
 * but unhandled, or the parse-time warning was bypassed. The name uses the
 * `SVGAttr` enum spelling (e.g., `stroke_dasharray`): it is reported as-is to
 * stay allocation-free on the animation hot path.
 */
internal fun LoggerContext.logUnsupportedAnimatedAttribute(name: String) {
    val scope = unsupportedFeatureScope()
    if (scope != null && !scope.markAnimatedAttributeWarned(name)) return
    logW("KSVG") { "Unsupported animated attribute <$name> ignored" }
}