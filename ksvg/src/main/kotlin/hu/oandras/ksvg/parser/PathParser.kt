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

import hu.oandras.ksvg.LoggerContext
import hu.oandras.ksvg.dom.core.PathDefinition
import hu.oandras.ksvg.logE

private const val TAG = "PathParser"

context(loggerContext: LoggerContext)
internal fun parsePath(value: String): PathDefinition {
    val scan = TextScanner(value)

    var currentX = 0f
    var currentY = 0f // The last point visited in the subpath
    var lastMoveX = 0f
    var lastMoveY = 0f // The initial point of current subpath
    var lastControlX = 0f
    var lastControlY = 0f // Last control point of the just completed Bézier curve.
    var x: Float
    var y: Float
    var x1: Float
    var y1: Float
    var x2: Float
    var y2: Float
    var rx: Float
    var ry: Float
    var xAxisRotation: Float
    var largeArcFlag: Boolean?
    var sweepFlag: Boolean?

    val length = value.length
    val path = PathDefinition(
        initialCommands = (length / 8).coerceAtLeast(8),
        initialCoords = (length / 4).coerceAtLeast(16)
    )

    if (scan.empty()) return path

    var pathCommand = scan.nextChar()

    if (pathCommand != 'M' && pathCommand != 'm') return path // Invalid path - doesn't start with a move

    while (true) {
        scan.skipWhitespace()

        when (pathCommand) {
            'M',
            'm' -> {
                x = scan.nextFloat()
                y = scan.checkedNextFloat(x)
                if (y.isNaN()) {
                    loggerContext.logE(TAG) { "Bad path coords for $pathCommand path segment" }
                    return path
                }
                // Relative moveto at the start of a path is treated as an absolute moveto.
                if (pathCommand == 'm' && !path.isEmpty) {
                    x += currentX
                    y += currentY
                }
                path.moveTo(
                    x = x,
                    y = y
                )
                run {
                    lastControlX = x
                    lastMoveX = lastControlX
                    currentX = lastMoveX
                }
                run {
                    lastControlY = y
                    lastMoveY = lastControlY
                    currentY = lastMoveY
                }
                // Any subsequent coord pairs should be treated as a lineto.
                pathCommand = if (pathCommand == 'm') 'l' else 'L'
            }

            'L',
            'l' -> {
                x = scan.nextFloat()
                y = scan.checkedNextFloat(x)
                if (y.isNaN()) {
                    loggerContext.logE(TAG) { "Bad path coords for $pathCommand path segment" }
                    return path
                }
                if (pathCommand == 'l') {
                    x += currentX
                    y += currentY
                }
                path.lineTo(
                    x = x,
                    y = y
                )
                run {
                    lastControlX = x
                    currentX = lastControlX
                }
                run {
                    lastControlY = y
                    currentY = lastControlY
                }
            }

            'C',
            'c' -> {
                x1 = scan.nextFloat()
                y1 = scan.checkedNextFloat(x1)
                x2 = scan.checkedNextFloat(y1)
                y2 = scan.checkedNextFloat(x2)
                x = scan.checkedNextFloat(y2)
                y = scan.checkedNextFloat(x)
                if (y.isNaN()) {
                    loggerContext.logE(TAG) { "Bad path coords for $pathCommand path segment" }
                    return path
                }
                if (pathCommand == 'c') {
                    x += currentX
                    y += currentY
                    x1 += currentX
                    y1 += currentY
                    x2 += currentX
                    y2 += currentY
                }
                path.cubicTo(
                    x1 = x1,
                    y1 = y1,
                    x2 = x2,
                    y2 = y2,
                    x3 = x,
                    y3 = y
                )
                lastControlX = x2
                lastControlY = y2
                currentX = x
                currentY = y
            }

            'S',
            's' -> {
                x1 = 2 * currentX - lastControlX
                y1 = 2 * currentY - lastControlY
                x2 = scan.nextFloat()
                y2 = scan.checkedNextFloat(x2)
                x = scan.checkedNextFloat(y2)
                y = scan.checkedNextFloat(x)
                if (y.isNaN()) {
                    loggerContext.logE(TAG) { "Bad path coords for $pathCommand path segment" }
                    return path
                }
                if (pathCommand == 's') {
                    x += currentX
                    y += currentY
                    x2 += currentX
                    y2 += currentY
                }
                path.cubicTo(
                    x1 = x1,
                    y1 = y1,
                    x2 = x2,
                    y2 = y2,
                    x3 = x,
                    y3 = y
                )
                lastControlX = x2
                lastControlY = y2
                currentX = x
                currentY = y
            }

            'Z',
            'z' -> {
                path.close()
                run {
                    lastControlX = lastMoveX
                    currentX = lastControlX
                }
                run {
                    lastControlY = lastMoveY
                    currentY = lastControlY
                }
            }

            'H',
            'h' -> {
                x = scan.nextFloat()
                if (x.isNaN()) {
                    loggerContext.logE(TAG) { "Bad path coords for $pathCommand path segment" }
                    return path
                }
                if (pathCommand == 'h') {
                    x += currentX
                }
                path.lineTo(
                    x = x,
                    y = currentY
                )
                run {
                    lastControlX = x
                    currentX = lastControlX
                }
                lastControlY = currentY
            }

            'V',
            'v' -> {
                y = scan.nextFloat()
                if (y.isNaN()) {
                    loggerContext.logE(TAG) { "Bad path coords for $pathCommand path segment" }
                    return path
                }
                if (pathCommand == 'v') {
                    y += currentY
                }
                path.lineTo(
                    x = currentX,
                    y = y
                )
                lastControlX = currentX
                run {
                    lastControlY = y
                    currentY = lastControlY
                }
            }

            'Q',
            'q' -> {
                x1 = scan.nextFloat()
                y1 = scan.checkedNextFloat(x1)
                x = scan.checkedNextFloat(y1)
                y = scan.checkedNextFloat(x)
                if (y.isNaN()) {
                    loggerContext.logE(TAG) { "Bad path coords for $pathCommand path segment" }
                    return path
                }
                if (pathCommand == 'q') {
                    x += currentX
                    y += currentY
                    x1 += currentX
                    y1 += currentY
                }
                path.quadTo(
                    x1 = x1,
                    y1 = y1,
                    x2 = x,
                    y2 = y
                )
                lastControlX = x1
                lastControlY = y1
                currentX = x
                currentY = y
            }

            'T',
            't' -> {
                x1 = 2 * currentX - lastControlX
                y1 = 2 * currentY - lastControlY
                x = scan.nextFloat()
                y = scan.checkedNextFloat(x)
                if (y.isNaN()) {
                    loggerContext.logE(TAG) { "Bad path coords for $pathCommand path segment" }
                    return path
                }
                if (pathCommand == 't') {
                    x += currentX
                    y += currentY
                }
                path.quadTo(
                    x1 = x1,
                    y1 = y1,
                    x2 = x,
                    y2 = y
                )
                lastControlX = x1
                lastControlY = y1
                currentX = x
                currentY = y
            }

            'A',
            'a' -> {
                rx = scan.nextFloat()
                ry = scan.checkedNextFloat(rx)
                xAxisRotation = scan.checkedNextFloat(ry)
                largeArcFlag = scan.checkedNextFlag(xAxisRotation)
                sweepFlag = scan.checkedNextFlag(largeArcFlag)
                x = scan.checkedNextFloat(sweepFlag)
                y = scan.checkedNextFloat(x)
                if (y.isNaN() || rx < 0 || ry < 0) {
                    loggerContext.logE(TAG) { "Bad path coords for $pathCommand path segment" }
                    return path
                }
                if (pathCommand == 'a') {
                    x += currentX
                    y += currentY
                }
                path.arcTo(
                    rx = rx,
                    ry = ry,
                    xAxisRotation = xAxisRotation,
                    largeArcFlag = largeArcFlag!!,
                    sweepFlag = sweepFlag!!,
                    x = x,
                    y = y
                )
                run {
                    lastControlX = x
                    currentX = lastControlX
                }
                run {
                    lastControlY = y
                    currentY = lastControlY
                }
            }

            else -> return path
        }

        scan.skipCommaWhitespace()
        if (scan.empty()) break

        // Test to see if there is another set of coords for the current path command
        if (scan.hasLetter()) {
            // Nope, so get the new path command instead
            pathCommand = scan.nextChar()
        }
    }
    return path
}

/**
 * Parses a semicolon-separated list of path data strings (e.g. the `values` of an
 * `<animate attributeName="d">`) into a list of [PathDefinition]s.
 */
context(loggerContext: LoggerContext)
internal fun parseSemicolonPathList(value: String): List<PathDefinition> {
    val result = mutableListOf<PathDefinition>()
    val len = value.length
    var start = 0
    var i = 0
    while (i <= len) {
        if (i == len || value[i] == ';') {
            if (i > start) {
                val segment = value.substring(start, i).trim()
                if (segment.isNotEmpty()) {
                    result.add(parsePath(segment))
                }
            }
            start = i + 1
        }
        i++
    }
    return result
}

internal fun parsePointsAsPath(value: String): PathDefinition {
    val points = parsePoints(value)
    val path = PathDefinition(
        initialCommands = (points.size / 2).coerceAtLeast(8),
        initialCoords = points.size.coerceAtLeast(16)
    )
    if (points.size >= 2) {
        path.moveTo(points[0], points[1])
        var j = 2
        while (j + 1 < points.size) {
            path.lineTo(points[j], points[j + 1])
            j += 2
        }
    }
    return path
}

internal fun parseSemicolonPointsPathList(value: String): List<PathDefinition> {
    val result = mutableListOf<PathDefinition>()
    val len = value.length
    var start = 0
    var i = 0
    while (i <= len) {
        if (i == len || value[i] == ';') {
            if (i > start) {
                val segment = value.substring(start, i).trim()
                if (segment.isNotEmpty()) {
                    result.add(parsePointsAsPath(segment))
                }
            }
            start = i + 1
        }
        i++
    }
    return result
}
