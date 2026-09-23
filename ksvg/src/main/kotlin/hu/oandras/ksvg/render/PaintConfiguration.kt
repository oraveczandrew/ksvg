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
import android.graphics.PathEffect
import android.graphics.Shader
import android.graphics.Typeface
import hu.oandras.ksvg.compat.setWordSpacingCompat

/**
 * The paint-driving state of a [RendererState]: everything we would write into
 * an Android [Paint], held as plain data instead.
 *
 * States no longer copy live Paint objects around (Paint.set() allocates native
 * objects and trips OEM hooks such as OnePlus PaintExtImpl); they copy this
 * configuration, and the Paint is lazily brought up to date — field-diffed —
 * the next time it is read (see RendererState.fillPaint/strokePaint).
 *
 * NOT covered here (intentionally kept as direct guarded writes):
 *  - typeface / font-variation-settings / font-feature-settings:
 *    handled by selectTypefaceAndFontStyling + applied* caches, because their
 *    Paint getters allocate strings and some cannot be safely re-read under
 *    Robolectric shadows.
 *  - word-spacing: compat path writes through letterSpacing on older APIs;
 *    guarded separately by RendererState.appliedWordSpacing.
 */
internal class PaintConfiguration {
    /** Bumped whenever any field actually changes; drives lazy paint sync. */
    var version: Long = 0L
        private set

    @JvmField
    var color: Int = DEFAULT_COLOR

    @JvmField
    var shader: Shader? = null

    @JvmField
    var pathEffect: PathEffect? = null

    @JvmField
    var textSize: Float = DEFAULT_TEXT_SIZE

    @JvmField
    var letterSpacing: Float = 0f

    @JvmField
    var strikeThruText: Boolean = false

    @JvmField
    var underlineText: Boolean = false

    @JvmField
    var strokeWidth: Float = 1f

    @JvmField
    var strokeCap: Paint.Cap = Paint.Cap.BUTT

    @JvmField
    var strokeJoin: Paint.Join = Paint.Join.MITER

    @JvmField
    var strokeMiter: Float = 4f

    @JvmField
    var typeface: Typeface? = null

    @JvmField
    var fontVariationSettings: String = ""

    @JvmField
    var fontFeatureSettings: String = ""

    @JvmField
    var wordSpacing: Float = Float.NaN

    fun setColor(value: Int) {
        if (color != value) {
            color = value
            bump()
        }
    }

    /**
     * Deliberately NOT equality-guarded: clearing the shader must always reach
     * the Paint, because mock-based tests record the assignment itself.
     */
    fun setShader(value: Shader?) {
        shader = value
        bump()
    }

    fun setPathEffect(value: PathEffect?) {
        if (pathEffect !== value) {
            pathEffect = value
            bump()
        }
    }

    fun setTextSize(value: Float) {
        if (textSize != value) {
            textSize = value
            bump()
        }
    }

    fun setLetterSpacing(value: Float) {
        if (letterSpacing != value) {
            letterSpacing = value
            bump()
        }
    }

    fun setTextDecorations(strikeThru: Boolean, underline: Boolean) {
        if (strikeThruText != strikeThru || underlineText != underline) {
            strikeThruText = strikeThru
            underlineText = underline
            bump()
        }
    }

    fun setStrokeWidth(value: Float) {
        if (strokeWidth != value) {
            strokeWidth = value
            bump()
        }
    }

    fun setStrokeCap(value: Paint.Cap) {
        if (strokeCap != value) {
            strokeCap = value
            bump()
        }
    }

    fun setStrokeJoin(value: Paint.Join) {
        if (strokeJoin != value) {
            strokeJoin = value
            bump()
        }
    }

    fun setStrokeMiter(value: Float) {
        if (strokeMiter != value) {
            strokeMiter = value
            bump()
        }
    }

    fun setTypeface(value: Typeface?) {
        if (typeface !== value) {
            typeface = value
            bump()
        }
    }

    fun setFontVariationSettings(value: String) {
        if (fontVariationSettings != value) {
            fontVariationSettings = value
            bump()
        }
    }

    fun setFontFeatureSettings(value: String) {
        if (fontFeatureSettings != value) {
            fontFeatureSettings = value
            bump()
        }
    }

    fun setWordSpacing(value: Float) {
        if (wordSpacing != value) {
            wordSpacing = value
            bump()
        }
    }

    /** Copies all fields from [src]; bumps the version only when something changed. */
    fun setFrom(src: PaintConfiguration) {
        val changed =
            color != src.color ||
                    shader !== src.shader ||
                    pathEffect !== src.pathEffect ||
                    textSize != src.textSize ||
                    letterSpacing != src.letterSpacing ||
                    strikeThruText != src.strikeThruText ||
                    underlineText != src.underlineText ||
                    strokeWidth != src.strokeWidth ||
                    strokeCap != src.strokeCap ||
                    strokeJoin != src.strokeJoin ||
                    strokeMiter != src.strokeMiter ||
                    typeface !== src.typeface ||
                    fontVariationSettings != src.fontVariationSettings ||
                    fontFeatureSettings != src.fontFeatureSettings ||
                    wordSpacing != src.wordSpacing
        if (changed) {
            color = src.color
            shader = src.shader
            pathEffect = src.pathEffect
            textSize = src.textSize
            letterSpacing = src.letterSpacing
            strikeThruText = src.strikeThruText
            underlineText = src.underlineText
            strokeWidth = src.strokeWidth
            strokeCap = src.strokeCap
            strokeJoin = src.strokeJoin
            strokeMiter = src.strokeMiter
            typeface = src.typeface
            fontVariationSettings = src.fontVariationSettings
            fontFeatureSettings = src.fontFeatureSettings
            wordSpacing = src.wordSpacing
            bump()
        }
    }

    private fun bump() {
        version++
    }

    /** Copies fields WITHOUT bumping the version (used for sync snapshots). */
    internal fun setFromQuietly(src: PaintConfiguration) {
        color = src.color
        shader = src.shader
        pathEffect = src.pathEffect
        textSize = src.textSize
        letterSpacing = src.letterSpacing
        strikeThruText = src.strikeThruText
        underlineText = src.underlineText
        strokeWidth = src.strokeWidth
        strokeCap = src.strokeCap
        strokeJoin = src.strokeJoin
        strokeMiter = src.strokeMiter
        typeface = src.typeface
        fontVariationSettings = src.fontVariationSettings
        fontFeatureSettings = src.fontFeatureSettings
        wordSpacing = src.wordSpacing
    }

    companion object {
        // Must mirror a freshly constructed Android Paint so the first sync is a no-op.
        const val DEFAULT_COLOR: Int = 0xFF000000.toInt()
        const val DEFAULT_TEXT_SIZE: Float = 16f
    }
}

internal object PaintConfigSync {
    /**
     * Writes every field unconditionally. Used for detached (host-less) paints,
     * where we cannot diff against a previous configuration cheaply.
     */
    fun apply(paint: Paint, cfg: PaintConfiguration) {
        paint.color = cfg.color
        paint.shader = cfg.shader
        paint.pathEffect = cfg.pathEffect
        paint.textSize = cfg.textSize
        paint.letterSpacing = cfg.letterSpacing
        // word-spacing must be written here too: the lazy diff path
        // (writeConfigDiff) seeds its snapshot from this configuration, so a
        // value missing here would never register as changed (audit #15).
        if (!cfg.wordSpacing.isNaN()) {
            paint.setWordSpacingCompat(cfg.wordSpacing)
        }
        paint.isStrikeThruText = cfg.strikeThruText
        paint.isUnderlineText = cfg.underlineText
        paint.strokeWidth = cfg.strokeWidth
        paint.strokeCap = cfg.strokeCap
        paint.strokeJoin = cfg.strokeJoin
        paint.strokeMiter = cfg.strokeMiter
        paint.typeface = cfg.typeface ?: Typeface.DEFAULT
        paint.fontFeatureSettings = cfg.fontFeatureSettings
        paint.fontVariationSettings = cfg.fontVariationSettings
    }
}
