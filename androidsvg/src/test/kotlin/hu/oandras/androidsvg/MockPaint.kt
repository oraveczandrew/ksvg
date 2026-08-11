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

package hu.oandras.androidsvg

import android.graphics.BlendMode
import android.graphics.ColorFilter
import android.graphics.MaskFilter
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PathEffect
import android.graphics.Rect
import android.graphics.Shader
import android.graphics.Typeface
import android.graphics.Xfermode
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.shadows.ShadowPaint
import java.math.BigDecimal
import java.math.RoundingMode

/**
 * Created by Paul on 10/07/2017.
 */
@Suppress("TestFunctionName", "unused")
@Implements(Paint::class)
class MockPaint: ShadowPaint() {
    private val settings: LinkedHashMap<String, String> = LinkedHashMap()

    @Implementation
    fun __constructor__() {}

    @Implementation
    override fun __constructor__(paint: Paint) {
        this.settings.putAll(paint.asShadow().settings)
        super.__constructor__(paint)
    }

    @Implementation
    fun __constructor__(flags: Int) {
        if (flags != 0) settings[FLAGS] = "f:" + genFlagsVal(flags)
    }

    @Implementation
    override fun setAlpha(alpha: Int) {
        settings.remove(ALPHA)
        settings[ALPHA] = "a:$alpha"
    }


    @Implementation
    override fun setColor(color: Int) {
        settings.remove(COLOR)
        settings[COLOR] =
            "color:#" + String.format("%08x", color)
    }

    @Implementation
    override fun setFlags(flags: Int) {
        settings.remove(FLAGS)
        if (flags != 0) settings[FLAGS] = "f:" + genFlagsVal(flags)
    }

    @Implementation
    fun setHinting(hinting: Int) {
        settings.remove(HINTING)
        settings[HINTING] = "h:" + (if (hinting == Paint.HINTING_ON) "ON" else "OFF")
    }

    @Implementation
    override fun setPathEffect(pathEffect: PathEffect?): PathEffect? {
        settings.remove(PATHEFFECT)
        settings[PATHEFFECT] = "dash:$pathEffect"
        return pathEffect
    }

    @Implementation
    override fun setShader(shader: Shader?): Shader? {
        settings.remove(SHADER)
        settings[SHADER] = "grad:$shader"
        return shader
    }

    @Implementation
    override fun setStrikeThruText(strikeThruText: Boolean) {
        settings.remove(STRIKETHRU)
        if (strikeThruText) settings[STRIKETHRU] = "<s>"
    }

    @Implementation
    override fun setStrokeCap(strokeCap: Paint.Cap?) {
        settings.remove(STROKECAP)
        settings[STROKECAP] = "cap:$strokeCap"
    }

    @Implementation
    override fun setStrokeJoin(join: Paint.Join?) {
        settings.remove(STROKEJOIN)
        settings[STROKEJOIN] = "join:$join"
    }

    @Implementation
    override fun setStrokeWidth(strokeWidth: Float) {
        settings.remove(STROKEWIDTH)
        settings[STROKEWIDTH] = "sw:" + num(strokeWidth)
    }

    @Implementation
    fun setStrokeMiter(miter: Float) {
        settings.remove(STROKEMITER)
        settings[STROKEMITER] = "miter:" + num(miter)
    }

    @Implementation
    override fun setStyle(style: Paint.Style?) {
        settings.remove(STYLE)
        settings[STYLE] = "s:$style"
    }

    @Implementation
    override fun setTextSize(textSize: Float) {
        settings.remove(TEXTSIZE)
        settings[TEXTSIZE] = "ts:" + num(textSize)
    }

    @Implementation
    override fun setLetterSpacing(letterSpacing: Float) {
        settings.remove(LETTERSPACING)
        settings[LETTERSPACING] = "ls:" + num(letterSpacing)
    }

    @Implementation
    override fun setWordSpacing(wordSpacing: Float) {
        settings.remove(WORDSPACING)
        settings[WORDSPACING] = "ws:" + num(wordSpacing)
    }

    @Implementation
    override fun setTypeface(typeface: Typeface?): Typeface? {
        settings.remove(TYPEFACE)
        settings[TYPEFACE] = "tf:$typeface"
        return typeface
    }

    @Implementation
    override fun setUnderlineText(underlineText: Boolean) {
        settings.remove(UNDERLINETEXT)
        if (underlineText) settings[UNDERLINETEXT] = "<u>"
    }

    @Implementation
    fun setFontFeatureSettings(features: String?) {
        settings.remove(FONTFEATURES)
        settings[FONTFEATURES] = "ff:$features"
    }

    @Implementation
    fun setFontVariationSettings(variation: String?): Boolean {
        settings.remove(FONTVARIATION)
        settings[FONTVARIATION] = "fv:$variation"
        return true
    }

    @Implementation
    fun setXfermode(xfermode: Xfermode?): Xfermode? {
        settings.remove(XFERMODE)
        settings[XFERMODE] = "xfer:$xfermode"
        return xfermode
    }

    @Implementation
    fun setBlendMode(blendMode: BlendMode?) {
        settings.remove(BLENDMODE)
        settings[BLENDMODE] = "blend:$blendMode"
    }

    @Implementation
    override fun setColorFilter(colorFilter: ColorFilter?): ColorFilter? {
        settings.remove(COLORFILTER)
        settings[COLORFILTER] = "cf:$colorFilter"
        return colorFilter
    }

    @Implementation
    override fun setFilterBitmap(filterBitmap: Boolean) {
        settings.remove(FILTERBITMAP)
        if (filterBitmap) settings[FILTERBITMAP] = "filter:ON"
    }

    @Implementation
    fun getTextWidths(text: String, widths: FloatArray): Int {
        // Mock: just fill with some value
        for (i in text.indices) {
            widths[i] = 10f
        }
        return text.length
    }

    @Implementation
    fun getTextBounds(text: String, start: Int, end: Int, bounds: Rect) {
        // Mock: set dummy bounds
        bounds.set(0, 0, (end - start) * 10, 20)
    }

    @Implementation
    fun getTextPath(text: String, start: Int, end: Int, x: Float, y: Float, path: Path) {
        path.asShadow().moveTo(x, y)
        path.asShadow().lineTo(x + (end - start) * 10, y)
    }

    @Implementation
    fun setMaskFilter(maskFilter: MaskFilter?): MaskFilter? {
        settings.remove(MASK_FILTER)
        settings[MASK_FILTER] = "mf:$maskFilter"
        return maskFilter
    }

    val description: String
        //-----------------------------------------------------------------------------------------------
        get() {
            // Sort settings for consistent order
            return buildString {
                append("Paint(")
                settings.values.toList().sorted().joinTo(this, "; ")
                append(')')
            }
        }

    private fun genFlagsVal(flags: Int): String {
        val f: ArrayList<String> = ArrayList(flags.countOneBits())
        for (b in 0..31) {
            val m = 1 shl b
            if ((flags and m) != 0) {
                when (m) {
                    Paint.ANTI_ALIAS_FLAG -> f.add("ANTI_ALIAS")
                    Paint.LINEAR_TEXT_FLAG -> f.add("LINEAR_TEXT")
                    Paint.SUBPIXEL_TEXT_FLAG -> f.add("SUBPIXEL_TEXT")
                    Paint.FILTER_BITMAP_FLAG -> f.add("FILTER_BITMAP")
                    else -> f.add(b.toString())
                }
            }
        }
        return f.joinToString("|")
    }

    companion object {
        private const val ALPHA = "alpha"
        private const val COLOR = "color"
        private const val FLAGS = "flags"
        private const val HINTING = "hinting"
        private const val PATHEFFECT = "pathEffect"
        private const val SHADER = "shader"
        private const val STRIKETHRU = "strikeThruText"
        private const val STROKECAP = "strokeCap"
        private const val STROKEJOIN = "strokeJoin"
        private const val STROKEMITER = "strokeMiter"
        private const val STROKEWIDTH = "strokeWidth"
        private const val STYLE = "style"
        private const val TEXTSIZE = "textSize"
        private const val TYPEFACE = "typeface"
        private const val UNDERLINETEXT = "underlineText"
        private const val FONTFEATURES = "fontFeatures"
        private const val FONTVARIATION = "fontVariation"
        private const val MASK_FILTER = "maskFilter"
        private const val XFERMODE = "xfermode"
        private const val BLENDMODE = "blendMode"
        private const val COLORFILTER = "colorFilter"
        private const val FILTERBITMAP = "filterBitmap"
        private const val LETTERSPACING = "letterSpacing"
        private const val WORDSPACING = "wordSpacing"

        private fun num(f: Float): String {
            return if (f == f.toLong().toFloat()) {
                String.format("%d", f.toLong())
            } else {
                String.format("%s", round(f, 2))
            }
        }

        @Suppress("SameParameterValue")
        private fun round(value: Float, places: Int): Float {
            var bd = BigDecimal(value.toString())
            bd = bd.setScale(places, RoundingMode.HALF_UP)
            return bd.toFloat()
        }
    }
}
