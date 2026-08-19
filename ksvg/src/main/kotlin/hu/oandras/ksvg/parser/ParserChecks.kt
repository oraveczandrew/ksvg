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

@file:OptIn(ExperimentalContracts::class)

package hu.oandras.ksvg.parser

import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.css.CSSParseException
import kotlin.contracts.ExperimentalContracts
import kotlin.contracts.contract

/**
 * Throws [KSVGParseException] if [condition] is false.
 */
@Throws(KSVGParseException::class)
internal inline fun checkState(condition: Boolean, lazyMessage: () -> String) {
    contract {
        returns() implies condition
    }

    if (!condition) {
        throw KSVGParseException(lazyMessage())
    }
}

/**
 * Throws [CSSParseException] if [condition] is false.
 */
@Throws(CSSParseException::class)
internal inline fun checkCssState(condition: Boolean, lazyMessage: () -> String) {
    contract {
        returns() implies condition
    }

    if (!condition) {
        throw CSSParseException(lazyMessage())
    }
}
