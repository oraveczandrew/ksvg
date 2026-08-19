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

package hu.oandras.ksvg.parser

import android.graphics.Matrix
import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.utils.toRadians
import kotlin.math.tan


@Throws(KSVGParseException::class)
internal fun parseTransform(value: String): Matrix {
    val matrix = Matrix()

    val scan = TextScanner(value)
    scan.skipWhitespace()

    while (!scan.empty()) {
        val cmd = scan.nextFunction()
            ?: throw KSVGParseException("Bad transform function encountered in transform list: $value")

        when (cmd) {
            "matrix" -> {
                scan.skipWhitespace()
                val a = scan.nextFloat()
                scan.skipCommaWhitespace()
                val b = scan.nextFloat()
                scan.skipCommaWhitespace()
                val c = scan.nextFloat()
                scan.skipCommaWhitespace()
                val d = scan.nextFloat()
                scan.skipCommaWhitespace()
                val e = scan.nextFloat()
                scan.skipCommaWhitespace()
                val f = scan.nextFloat()
                scan.skipWhitespace()

                checkState(!f.isNaN() && scan.consume(')')) { "Invalid transform list: $value" }

                val m = Matrix()
                m.setValues(floatArrayOf(a, c, e, b, d, f, 0f, 0f, 1f))
                matrix.preConcat(m)
            }

            "translate" -> {
                scan.skipWhitespace()
                val tx = scan.nextFloat()
                val ty = scan.possibleNextFloat()
                scan.skipWhitespace()

                checkState(!tx.isNaN() && scan.consume(')')) { "Invalid transform list: $value" }

                if (ty.isNaN()) matrix.preTranslate(tx, 0f)
                else matrix.preTranslate(tx, ty)
            }

            "scale" -> {
                scan.skipWhitespace()
                val sx = scan.nextFloat()
                val sy = scan.possibleNextFloat()
                scan.skipWhitespace()

                checkState(!sx.isNaN() && scan.consume(')')) { "Invalid transform list: $value" }

                if (sy.isNaN()) matrix.preScale(sx, sx)
                else matrix.preScale(sx, sy)
            }

            "rotate" -> {
                scan.skipWhitespace()
                val ang = scan.nextFloat()
                val cx = scan.possibleNextFloat()
                val cy = scan.possibleNextFloat()
                scan.skipWhitespace()

                checkState(!ang.isNaN() && scan.consume(')')) { "Invalid transform list: $value" }

                if (cx.isNaN()) {
                    matrix.preRotate(ang)
                } else if (!cy.isNaN()) {
                    matrix.preRotate(ang, cx, cy)
                } else {
                    throw KSVGParseException("Invalid transform list: $value")
                }
            }

            "skewX" -> {
                scan.skipWhitespace()
                val ang = scan.nextFloat()
                scan.skipWhitespace()

                checkState(!ang.isNaN() && scan.consume(')')) { "Invalid transform list: $value" }

                matrix.preSkew(tan(ang.toRadians()), 0f)
            }

            "skewY" -> {
                scan.skipWhitespace()
                val ang = scan.nextFloat()
                scan.skipWhitespace()

                checkState(!ang.isNaN() && scan.consume(')')) { "Invalid transform list: $value" }

                matrix.preSkew(0f, tan(ang.toRadians()))
            }

            else -> throw KSVGParseException("Invalid transform list fn: $cmd)")
        }

        if (scan.empty()) break
        scan.skipCommaWhitespace()
    }

    return matrix
}