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
 * a concrete implementation (e.g., Android's [Log]).
 *
 * Provide your own implementation and pass it to one of the `SVG.getFrom*`
 * methods to route all parsers and renderer logging through it.
 */
public interface LoggerContext {
    /**
     * Logs [message] for [tag] at the given [level] (one of the `VERBOSE..ERROR`
     * constants below, mirroring Android's [Log] levels).
     */
    public fun log(level: Int, tag: String, message: String)

    /**
     * Returns true if a message of the given [level] would actually be logged for [tag].
     * Used by the lazy inline logging helpers to avoid evaluating the message lambda.
     */
    public fun isLoggable(tag: String, level: Int): Boolean

    public companion object {
        /** Log levels mirroring Android's [Log] constants. */
        public const val VERBOSE: Int = Log.VERBOSE
        public const val DEBUG: Int = Log.DEBUG
        public const val INFO: Int = Log.INFO
        public const val WARN: Int = Log.WARN
        public const val ERROR: Int = Log.ERROR
    }
}

/**
 * A [LoggerContext] that forwards every log call to another context, [delegate].
 *
 * Keeping the target reachable lets the library walk a chain of contexts to find
 * state that is shared along it, so a decorator must expose what it wraps instead
 * of hiding it. Pair it with `LoggerContext by delegate`:
 *
 * ```
 * class MyContext(override val delegate: LoggerContext) :
 *     DelegatingLoggerContext, LoggerContext by delegate
 * ```
 */
public interface DelegatingLoggerContext : LoggerContext {
    /** The context this one forwards every log call to. */
    public val delegate: LoggerContext
}

/**
 * A named bag of state shared by the log messages of a single parse, e.g., the
 * "already warned" sets behind `UnsupportedFeatureScope`. Library-internal:
 * reach it through [findScope] instead of holding one.
 */
internal interface LoggerScope

/**
 * A link of a [LoggerContext] delegation chain that may also own a
 * [LoggerScope]: [getScope] answers for the scopes this very context owns, while
 * the inherited [delegate] is where [findScope] walks next.
 *
 * Every context between a scope owner and a log call implements this, so state
 * created once per parse (the unsupported-warning dedup scope) is reachable from
 * everywhere below it — without every log call having to be handed a scoped
 * context. The per-parse wrapper owns the scope and delegates to the caller's
 * context; the document (delegate = that wrapper), the DOM builders (delegate =
 * the document) and the render tree (delegate = the document) are pure links.
 */
internal interface ScopedLoggerContext : DelegatingLoggerContext {
    /** The scope owned by this very context as [name], or null when it owns none. */
    fun getScope(name: String): LoggerScope?
}

/**
 * Returns the [LoggerScope] registered as [name] anywhere in this context's
 * delegation chain, or null when there is none (in which case the caller has to
 * log unconditionally). Recurses through [DelegatingLoggerContext.delegate] until a
 * scope is found or the chain ends at a context that does not take part in it.
 */
internal fun LoggerContext.findScope(name: String): LoggerScope? {
    if (this is ScopedLoggerContext) {
        getScope(name)?.let { return it }
    }

    return if (this is DelegatingLoggerContext) {
        delegate.findScope(name)
    } else {
        null
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

/**
 * [LoggerContext] that drops every message. Pass it to the `SVG.getFrom*` methods
 * to silence all parser and renderer logging.
 */
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

internal inline fun LoggerContext.logE(tag: String, throwable: Throwable, message: () -> String = { throwable.message ?: "Error" }) {
    if (isLoggable(tag, LoggerContext.ERROR)) {
        val msg = message()
        val stackTrace = Log.getStackTraceString(throwable)
        log(LoggerContext.ERROR, tag, "$msg\n$stackTrace")
    }
}
