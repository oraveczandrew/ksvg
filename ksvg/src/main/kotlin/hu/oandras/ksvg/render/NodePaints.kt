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

package hu.oandras.ksvg.render

import android.graphics.Paint
import hu.oandras.ksvg.compat.setWordSpacingCompat

/**
 * Lazily creates and field-diff-syncs the node-owned paints against the
 * incoming [PaintConfiguration].
 *
 * IMPORTANT: `applied*` are SNAPSHOT copies, never references to the incoming
 * configuration. Pooled RendererStates are reused, so comparing against the
 * live config object could alias it (self-comparison -> missed updates ->
 * frozen animations). Snapshots make the field diff always meaningful.
 */
internal fun RenderNode<*>.obtainFillPaint(cfg: PaintConfiguration): Paint {
    var p = nodeFillPaint
    if (p == null) {
        p = Paint().apply {
            flags = Paint.ANTI_ALIAS_FLAG or Paint.LINEAR_TEXT_FLAG or Paint.SUBPIXEL_TEXT_FLAG
            hinting = Paint.HINTING_OFF
            style = Paint.Style.FILL
        }
        nodeFillPaint = p
        // Fresh paint: unconditionally write everything once.
        PaintConfigSync.apply(p, cfg)
        appliedFillConfig = PaintConfiguration().also { it.setFromQuietly(cfg) }
        return p
    }
    val applied = appliedFillConfig!!
    writeConfigDiff(p, applied, cfg)
    applied.setFromQuietly(cfg)
    return p
}

internal fun RenderNode<*>.obtainStrokePaint(cfg: PaintConfiguration): Paint {
    var p = nodeStrokePaint
    if (p == null) {
        p = Paint().apply {
            flags = Paint.ANTI_ALIAS_FLAG or Paint.LINEAR_TEXT_FLAG or Paint.SUBPIXEL_TEXT_FLAG
            hinting = Paint.HINTING_OFF
            style = Paint.Style.STROKE
        }
        nodeStrokePaint = p
        PaintConfigSync.apply(p, cfg)
        appliedStrokeConfig = PaintConfiguration().also { it.setFromQuietly(cfg) }
        return p
    }
    val applied = appliedStrokeConfig!!
    writeConfigDiff(p, applied, cfg)
    applied.setFromQuietly(cfg)
    return p
}

private fun writeConfigDiff(p: Paint, applied: PaintConfiguration, cfg: PaintConfiguration) {
    if (applied.color != cfg.color) p.color = cfg.color
    if (applied.shader !== cfg.shader) p.shader = cfg.shader
    if (applied.pathEffect !== cfg.pathEffect) p.pathEffect = cfg.pathEffect
    if (applied.textSize != cfg.textSize) p.textSize = cfg.textSize
    if (applied.letterSpacing != cfg.letterSpacing) p.letterSpacing = cfg.letterSpacing
    if (applied.strikeThruText != cfg.strikeThruText) p.isStrikeThruText = cfg.strikeThruText
    if (applied.underlineText != cfg.underlineText) p.isUnderlineText = cfg.underlineText
    if (applied.strokeWidth != cfg.strokeWidth) p.strokeWidth = cfg.strokeWidth
    if (applied.strokeCap != cfg.strokeCap) p.strokeCap = cfg.strokeCap
    if (applied.strokeJoin != cfg.strokeJoin) p.strokeJoin = cfg.strokeJoin
    if (applied.strokeMiter != cfg.strokeMiter) p.strokeMiter = cfg.strokeMiter
    if (applied.typeface !== cfg.typeface) p.typeface = cfg.typeface
    if (applied.fontVariationSettings != cfg.fontVariationSettings) p.fontVariationSettings = cfg.fontVariationSettings
    if (applied.fontFeatureSettings != cfg.fontFeatureSettings) p.fontFeatureSettings = cfg.fontFeatureSettings
    if (applied.wordSpacing != cfg.wordSpacing && !cfg.wordSpacing.isNaN()) {
        p.setWordSpacingCompat(cfg.wordSpacing)
    }
}
