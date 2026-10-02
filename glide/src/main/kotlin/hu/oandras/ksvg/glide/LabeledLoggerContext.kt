/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.glide

import hu.oandras.ksvg.DelegatingLoggerContext
import hu.oandras.ksvg.LoggerContext

/**
 * [LoggerContext] decorator that prefixes every message with the decode source
 * label in parentheses, e.g., `(https://example.com/icon.svg) <original message>`.
 *
 * The label itself comes from [KSVGOptions.SOURCE_LABEL]; an empty label is a
 * no-op and the message is forwarded unchanged.
 */
private class LabeledLoggerContext(
    override val delegate: LoggerContext,
    @JvmField
    val label: String,
) : DelegatingLoggerContext {
    override fun log(level: Int, tag: String, message: String) {
        delegate.log(
            level = level,
            tag = tag,
            message = buildString {
                append('(')
                append(label)
                append(") ")
                append(message)
            }
        )
    }

    override fun isLoggable(tag: String, level: Int): Boolean {
        return delegate.isLoggable(tag, level)
    }
}

internal fun LoggerContext.labeledWith(label: String?): LoggerContext =
    if (label.isNullOrBlank()) this else LabeledLoggerContext(delegate = this, label = label)
