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

import androidx.collection.MutableFloatList
import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.toFloatArray

internal fun parseFloatList(value: String): FloatArray {
    val scanner = TextScanner(value)
    val list = MutableFloatList()
    while (!scanner.empty()) {
        val f = scanner.nextFloat()
        if (!f.isNaN()) {
            list.add(f)
        }
        scanner.skipCommaWhitespace()
    }
    return list.toFloatArray()
}

@Throws(KSVGParseException::class)
internal fun parsePoints(value: String): FloatArray {
    val scan = TextScanner(value)
    val points = MutableFloatList()
    scan.skipWhitespace()
    while (!scan.empty()) {
        val x = scan.nextFloat()
        checkState(!x.isNaN()) { "Invalid points attribute. At least one number expected" }
        scan.skipCommaWhitespace()
        val y = scan.nextFloat()
        checkState(!y.isNaN()) { "Invalid points attribute. Numbers must come in pairs" }
        scan.skipCommaWhitespace()
        points.add(x)
        points.add(y)
    }
    return points.toFloatArray()
}

/*
* Parse a generic float value.
*/
@Throws(KSVGParseException::class)
internal fun parseFloat(value: String): Float {
    val len = value.length
    checkState(len > 0) { "Invalid float value (empty string)" }
    return parseFloat(value, 0, len)
}

@Throws(KSVGParseException::class)
internal fun parseNonNegativeFloat(value: String, errorMessage: String): Float {
    return parseFloat(value).also {
        checkState(it >= 0f) { errorMessage }
    }
}

@Suppress("SameParameterValue")
@Throws(KSVGParseException::class)
internal fun parseFloat(value: String, offset: Int, len: Int): Float {
    val num = NumberParser.parseNumber(value, offset, len)
    checkState(!num.isNaN()) { "Invalid float value: $value" }
    return num
}

/*
* Parse an opacity value (a float clamped to the range 0..1).
*/
internal fun parseOpacity(value: String): Float {
    return try {
        clamp(n = parseFloat(value), min = 0f, max = 1f)
    } catch (_: KSVGParseException) {
        Float.NaN
    }
}