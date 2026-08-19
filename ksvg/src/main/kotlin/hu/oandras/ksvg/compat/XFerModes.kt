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

import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode

internal object XFerModes {
    @JvmField
    val Add = PorterDuffXfermode(PorterDuff.Mode.ADD)
    @JvmField
    val Clear = PorterDuffXfermode(PorterDuff.Mode.CLEAR)
    @JvmField
    val Darken = PorterDuffXfermode(PorterDuff.Mode.DARKEN)
    @JvmField
    val Dst = PorterDuffXfermode(PorterDuff.Mode.DST)
    @JvmField
    val DstAtop = PorterDuffXfermode(PorterDuff.Mode.DST_ATOP)
    @JvmField
    val DstIn = PorterDuffXfermode(PorterDuff.Mode.DST_IN)
    @JvmField
    val DstOut = PorterDuffXfermode(PorterDuff.Mode.DST_OUT)
    @JvmField
    val DstOver = PorterDuffXfermode(PorterDuff.Mode.DST_OVER)
    @JvmField
    val Lighten = PorterDuffXfermode(PorterDuff.Mode.LIGHTEN)
    @JvmField
    val Multiply = PorterDuffXfermode(PorterDuff.Mode.MULTIPLY)
    @JvmField
    val Overlay = PorterDuffXfermode(PorterDuff.Mode.OVERLAY)
    @JvmField
    val Screen = PorterDuffXfermode(PorterDuff.Mode.SCREEN)
    @JvmField
    val Src = PorterDuffXfermode(PorterDuff.Mode.SRC)
    @JvmField
    val SrcAtop = PorterDuffXfermode(PorterDuff.Mode.SRC_ATOP)
    @JvmField
    val SrcIn = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
    @JvmField
    val SrcOut = PorterDuffXfermode(PorterDuff.Mode.SRC_OUT)
    @JvmField
    val SrcOver = PorterDuffXfermode(PorterDuff.Mode.SRC_OVER)
    @JvmField
    val Xor = PorterDuffXfermode(PorterDuff.Mode.XOR)
}