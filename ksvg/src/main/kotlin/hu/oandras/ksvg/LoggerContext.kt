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

package hu.oandras.ksvg

import android.util.Log

/**
 * Abstraction over a logging backend so the library can log without depending on
 * a concrete implementation (e.g. Android's [Log]).
 *
 * Provide your own implementation and pass it to one of the `SVG.getFrom*`
 * methods to route all parser and renderer logging through it.
 */
public interface LoggerContext {
    public fun log(level: Int, tag: String, message: String)

    /**
     * Returns true if a message of the given [level] would actually be logged for [tag].
     * Used by the lazy inline logging helpers to avoid evaluating the message lambda.
     */
    public fun isLoggable(tag: String, level: Int): Boolean

    public companion object {
        public const val VERBOSE: Int = Log.VERBOSE
        public const val DEBUG: Int = Log.DEBUG
        public const val INFO: Int = Log.INFO
        public const val WARN: Int = Log.WARN
        public const val ERROR: Int = Log.ERROR
    }
}

/**
 * Default [LoggerContext] backed by Android's [Log].
 */
public object AndroidLoggerContext : LoggerContext {
    public override fun log(level: Int, tag: String, message: String) {
        Log.println(level, tag, message)
    }

    public override fun isLoggable(tag: String, level: Int): Boolean = Log.isLoggable(tag, level)
}

public object NoopLoggerContext : LoggerContext {
    public override fun log(level: Int, tag: String, message: String) {}

    public override fun isLoggable(tag: String, level: Int): Boolean = false
}

internal inline fun LoggerContext.logV(tag: String, message: () -> String) {
    if (isLoggable(tag, LoggerContext.VERBOSE)) log(LoggerContext.VERBOSE, tag, message())
}

internal inline fun LoggerContext.logD(tag: String, message: () -> String) {
    if (isLoggable(tag, LoggerContext.DEBUG)) log(LoggerContext.DEBUG, tag, message())
}

internal inline fun LoggerContext.logI(tag: String, message: () -> String) {
    if (isLoggable(tag, LoggerContext.INFO)) log(LoggerContext.INFO, tag, message())
}

internal inline fun LoggerContext.logW(tag: String, message: () -> String) {
    if (isLoggable(tag, LoggerContext.WARN)) log(LoggerContext.WARN, tag, message())
}

internal inline fun LoggerContext.logE(tag: String, message: () -> String) {
    if (isLoggable(tag, LoggerContext.ERROR)) log(LoggerContext.ERROR, tag, message())
}
