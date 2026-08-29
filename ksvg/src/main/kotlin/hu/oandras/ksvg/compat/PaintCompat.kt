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
package hu.oandras.ksvg.compat

import android.graphics.BlendMode
import android.graphics.Paint
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.BuildConfig
import hu.oandras.ksvg.dom.style.CSSBlendMode

internal enum class BlendModeCompat {
    CLEAR, SRC, DST, SRC_OVER, DST_OVER, SRC_IN, DST_IN, SRC_OUT, DST_OUT, SRC_ATOP, DST_ATOP, XOR, ADD,
    MULTIPLY, SCREEN, OVERLAY, DARKEN, LIGHTEN, COLOR_DODGE, COLOR_BURN, HARD_LIGHT, SOFT_LIGHT, DIFFERENCE, EXCLUSION,
    HUE, SATURATION, COLOR, LUMINOSITY
}

private interface PaintCompat {
    fun setWordSpacing(paint: Paint, value: Float)
    fun getWordSpacing(paint: Paint): Float
    fun supportsWordSpacing(): Boolean
    fun setBlendMode(paint: Paint, mode: BlendModeCompat?)
    fun isBlendModeSupported(mode: BlendModeCompat): Boolean
}

@RequiresApi(Build.VERSION_CODES.Q)
private class PaintCompatImpl29 : PaintCompat {
    override fun setWordSpacing(paint: Paint, value: Float) {
        paint.wordSpacing = value
    }

    override fun getWordSpacing(paint: Paint): Float {
        return paint.wordSpacing
    }

    override fun supportsWordSpacing(): Boolean {
        return true
    }

    override fun setBlendMode(paint: Paint, mode: BlendModeCompat?) {
        paint.blendMode = when (mode) {
            BlendModeCompat.CLEAR -> BlendMode.CLEAR
            BlendModeCompat.SRC -> BlendMode.SRC
            BlendModeCompat.DST -> BlendMode.DST
            BlendModeCompat.SRC_OVER -> BlendMode.SRC_OVER
            BlendModeCompat.DST_OVER -> BlendMode.DST_OVER
            BlendModeCompat.SRC_IN -> BlendMode.SRC_IN
            BlendModeCompat.DST_IN -> BlendMode.DST_IN
            BlendModeCompat.SRC_OUT -> BlendMode.SRC_OUT
            BlendModeCompat.DST_OUT -> BlendMode.DST_OUT
            BlendModeCompat.SRC_ATOP -> BlendMode.SRC_ATOP
            BlendModeCompat.DST_ATOP -> BlendMode.DST_ATOP
            BlendModeCompat.XOR -> BlendMode.XOR
            BlendModeCompat.ADD -> BlendMode.PLUS
            BlendModeCompat.MULTIPLY -> BlendMode.MULTIPLY
            BlendModeCompat.SCREEN -> BlendMode.SCREEN
            BlendModeCompat.OVERLAY -> BlendMode.OVERLAY
            BlendModeCompat.DARKEN -> BlendMode.DARKEN
            BlendModeCompat.LIGHTEN -> BlendMode.LIGHTEN
            BlendModeCompat.COLOR_DODGE -> BlendMode.COLOR_DODGE
            BlendModeCompat.COLOR_BURN -> BlendMode.COLOR_BURN
            BlendModeCompat.HARD_LIGHT -> BlendMode.HARD_LIGHT
            BlendModeCompat.SOFT_LIGHT -> BlendMode.SOFT_LIGHT
            BlendModeCompat.DIFFERENCE -> BlendMode.DIFFERENCE
            BlendModeCompat.EXCLUSION -> BlendMode.EXCLUSION
            BlendModeCompat.HUE -> BlendMode.HUE
            BlendModeCompat.SATURATION -> BlendMode.SATURATION
            BlendModeCompat.COLOR -> BlendMode.COLOR
            BlendModeCompat.LUMINOSITY -> BlendMode.LUMINOSITY
            null -> null
        }
    }

    override fun isBlendModeSupported(mode: BlendModeCompat): Boolean = true
}

private open class PaintCompatImplBase : PaintCompat {
    override fun setWordSpacing(paint: Paint, value: Float) {
        // No-op by default
    }

    override fun getWordSpacing(paint: Paint): Float {
        return 0f
    }

    override fun supportsWordSpacing(): Boolean {
        return false
    }

    override fun setBlendMode(paint: Paint, mode: BlendModeCompat?) {
        paint.xfermode = when (mode) {
            BlendModeCompat.CLEAR -> XFerModes.Clear
            BlendModeCompat.SRC -> XFerModes.Src
            BlendModeCompat.DST -> XFerModes.Dst
            BlendModeCompat.SRC_OVER -> XFerModes.SrcOver
            BlendModeCompat.DST_OVER -> XFerModes.DstOver
            BlendModeCompat.SRC_IN -> XFerModes.SrcIn
            BlendModeCompat.DST_IN -> XFerModes.DstIn
            BlendModeCompat.SRC_OUT -> XFerModes.SrcOut
            BlendModeCompat.DST_OUT -> XFerModes.DstOut
            BlendModeCompat.SRC_ATOP -> XFerModes.SrcAtop
            BlendModeCompat.DST_ATOP -> XFerModes.DstAtop
            BlendModeCompat.XOR -> XFerModes.Xor
            BlendModeCompat.ADD -> XFerModes.Add
            BlendModeCompat.MULTIPLY -> XFerModes.Multiply
            BlendModeCompat.SCREEN -> XFerModes.Screen
            BlendModeCompat.OVERLAY -> XFerModes.Overlay
            BlendModeCompat.DARKEN -> XFerModes.Darken
            BlendModeCompat.LIGHTEN -> XFerModes.Lighten
            else -> null // Others not supported via PorterDuff
        }
    }

    override fun isBlendModeSupported(mode: BlendModeCompat): Boolean {
        return when (mode) {
            BlendModeCompat.CLEAR, BlendModeCompat.SRC, BlendModeCompat.DST,
            BlendModeCompat.SRC_OVER, BlendModeCompat.DST_OVER, BlendModeCompat.SRC_IN,
            BlendModeCompat.DST_IN, BlendModeCompat.SRC_OUT, BlendModeCompat.DST_OUT,
            BlendModeCompat.SRC_ATOP, BlendModeCompat.DST_ATOP, BlendModeCompat.XOR,
            BlendModeCompat.ADD, BlendModeCompat.MULTIPLY, BlendModeCompat.SCREEN,
            BlendModeCompat.OVERLAY, BlendModeCompat.DARKEN, BlendModeCompat.LIGHTEN -> true
            else -> false
        }
    }
}

@RequiresApi(Build.VERSION_CODES.O_MR1)
private class PaintCompatImpl27 : PaintCompatImplBase() {
    private val setMethod = try {
        Paint::class.java.getDeclaredMethod("setWordSpacing", Float::class.javaPrimitiveType)
    } catch (_: Throwable) {
        null
    }

    private val getMethod = try {
        Paint::class.java.getDeclaredMethod("getWordSpacing")
    } catch (_: Throwable) {
        null
    }

    override fun setWordSpacing(paint: Paint, value: Float) {
        try {
            setMethod!!.invoke(paint, value)
        } catch (e: Throwable) {
            if (BuildConfig.DEBUG) {
                Log.w("KSVG", "Paint.setWordSpacing reflection failed", e)
            }
        }
    }

    override fun getWordSpacing(paint: Paint): Float {
        return try {
            (getMethod!!.invoke(paint) as Float)
        } catch (e: Throwable) {
            if (BuildConfig.DEBUG) {
                Log.w("KSVG", "Paint.getWordSpacing reflection failed", e)
            }
            0f
        }
    }

    override fun supportsWordSpacing(): Boolean {
        return setMethod != null && getMethod != null
    }
}

private val paintCompat: PaintCompat = when {
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> PaintCompatImpl29()
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1 -> PaintCompatImpl27()
    else -> PaintCompatImplBase()
}

internal fun Paint.setWordSpacingCompat(value: Float) {
    paintCompat.setWordSpacing(this, value)
}

internal fun Paint.getWordSpacingCompat(): Float {
    return paintCompat.getWordSpacing(this)
}

internal fun supportsWordSpacing(): Boolean {
    return paintCompat.supportsWordSpacing()
}

internal fun Paint.setBlendModeCompat(mode: BlendModeCompat?) {
    paintCompat.setBlendMode(this, mode)
}

internal fun isBlendModeSupported(mode: BlendModeCompat): Boolean {
    return paintCompat.isBlendModeSupported(mode)
}

internal fun CSSBlendMode.toBlendModeCompat(): BlendModeCompat? {
    return when (this) {
        CSSBlendMode.multiply -> BlendModeCompat.MULTIPLY
        CSSBlendMode.screen -> BlendModeCompat.SCREEN
        CSSBlendMode.overlay -> BlendModeCompat.OVERLAY
        CSSBlendMode.darken -> BlendModeCompat.DARKEN
        CSSBlendMode.lighten -> BlendModeCompat.LIGHTEN
        CSSBlendMode.color_dodge -> BlendModeCompat.COLOR_DODGE
        CSSBlendMode.color_burn -> BlendModeCompat.COLOR_BURN
        CSSBlendMode.hard_light -> BlendModeCompat.HARD_LIGHT
        CSSBlendMode.soft_light -> BlendModeCompat.SOFT_LIGHT
        CSSBlendMode.difference -> BlendModeCompat.DIFFERENCE
        CSSBlendMode.exclusion -> BlendModeCompat.EXCLUSION
        CSSBlendMode.hue -> BlendModeCompat.HUE
        CSSBlendMode.saturation -> BlendModeCompat.SATURATION
        CSSBlendMode.color -> BlendModeCompat.COLOR
        CSSBlendMode.luminosity -> BlendModeCompat.LUMINOSITY
        else -> null
    }
}
