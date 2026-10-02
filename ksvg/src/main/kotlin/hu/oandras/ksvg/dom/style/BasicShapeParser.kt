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

package hu.oandras.ksvg.dom.style

import hu.oandras.ksvg.logger.LoggerContext
import hu.oandras.ksvg.logger.UnsupportedFeature
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.logger.logUnsupportedFeature
import hu.oandras.ksvg.parser.TextScanner
import hu.oandras.ksvg.parser.parsePath

context(loggerContext: LoggerContext)
internal fun parseClipPath(value: String): CSSClipPath? {
    val v = value.trim()
    if (v.equals("none", ignoreCase = true)) return null
    if (v.startsWith("url(", ignoreCase = true)) {
        // url() with a shape fallback is invalid per grammar; shape wins (documented).
        val close = v.lastIndexOf(')')
        if (close != -1) {
            val after = v.substring(close + 1).trim()
            if (after.isNotEmpty()) {
                return parseClipPath(after)
            }
        }
        val iri = parseFunctionalIRI(v) ?: return null
        return CSSClipPath.UrlClip(iri)
    }
    val open = v.indexOf('(')
    val close = v.lastIndexOf(')')
    if (open == -1 || close < open) return null
    val name = v.substring(0, open).trim().lowercase()
    val body = v.substring(open + 1, close)
    val trailing = v.substring(close + 1).trim()
    if (trailing.contains('(') || trailing.contains(')')) return null
    return try {
        val shape = when (name) {
            "circle" -> parseCircle(body)
            "ellipse" -> parseEllipse(body)
            "inset" -> parseInset(body)
            "rect" -> parseRect(body)
            "xywh" -> parseXywh(body)
            "polygon" -> parsePolygon(body)
            "path" -> parsePathShape(body)
            else -> return null
        } ?: return null
        val refBox = shape.refBox ?: parseGeometryBoxWord(trailing) ?: return null
        CSSClipPath.ShapeClip(shape.shape, refBox)
    } catch (_: Exception) {
        null
    }
}

private data class Shaped<T : BasicShape>(
    @JvmField
    val shape: T,
    @JvmField
    val refBox: GeometryBox?
)

private fun parseCircle(body: String): Shaped<BasicShape.Circle>? {
    val scan = TextScanner(body)
    scan.skipWhitespace()
    val r = parseClipRadius(scan) ?: return null
    var cx: ClipPosition = ClipPosition.Center
    var cy: ClipPosition = ClipPosition.Center
    scan.skipWhitespace()
    if (scan.consumeKeyword("at")) {
        scan.skipWhitespace()
        val pos = parsePositionPair(scan) ?: return null
        cx = pos.first
        cy = pos.second
    }
    scan.skipWhitespace()
    var refBox: GeometryBox? = null
    if (!scan.empty()) {
        val word = scan.nextIdent() ?: return null
        refBox = parseGeometryBoxName(word) ?: return null
        scan.skipWhitespace()
    }
    if (!scan.empty()) return null
    return Shaped(BasicShape.Circle(r, cx, cy), refBox)
}

private fun parseEllipse(body: String): Shaped<BasicShape.Ellipse>? {
    val scan = TextScanner(body)
    scan.skipWhitespace()
    val rx = parseClipRadius(scan) ?: return null
    scan.skipWhitespace()
    // rx and ry may be comma- or space-separated
    scan.skipCommaWhitespace()
    scan.skipWhitespace()
    val ry = parseClipRadius(scan) ?: return null
    var cx: ClipPosition = ClipPosition.Center
    var cy: ClipPosition = ClipPosition.Center
    scan.skipWhitespace()
    if (scan.consumeKeyword("at")) {
        scan.skipWhitespace()
        val pos = parsePositionPair(scan) ?: return null
        cx = pos.first
        cy = pos.second
    }
    scan.skipWhitespace()
    var refBox: GeometryBox? = null
    if (!scan.empty()) {
        val word = scan.nextIdent() ?: return null
        refBox = parseGeometryBoxName(word) ?: return null
        scan.skipWhitespace()
    }
    if (!scan.empty()) return null
    return Shaped(BasicShape.Ellipse(rx, ry, cx, cy), refBox)
}

context(loggerContext: LoggerContext)
private fun parseInset(body: String): Shaped<BasicShape.Inset>? {
    val scan = TextScanner(body)
    scan.skipWhitespace()
    val first = scan.nextLength() ?: return null
    val second = nextInsetLength(scan)
    val third = if (second != null) nextInsetLength(scan) else null
    val fourth = if (third != null) nextInsetLength(scan) else null
    // 1 value: all edges; 2: vertical horizontal; 3: top horizontal bottom; 4: as given.
    val top = first
    val right = second ?: first
    val bottom = third ?: first
    val left = fourth ?: right

    val round = parseRoundRadii(scan) ?: return null
    val roundX: CSSLength? = round.first
    val roundY: CSSLength? = round.second
    scan.skipWhitespace()
    var refBox: GeometryBox? = null
    if (!scan.empty()) {
        val word = scan.nextIdent() ?: return null
        refBox = parseGeometryBoxName(word) ?: return null
        scan.skipWhitespace()
    }
    if (!scan.empty()) return null
    return Shaped(BasicShape.Inset(top, right, bottom, left, roundX, roundY), refBox)
}

/**
 * Reads the next `inset()` edge, or returns null while leaving the scan position
 * untouched when the value is absent, unparsable, or the `round` radii begin.
 * Reading stops at the first missing edge, so a gap in 2-3-4 value syntax is
 * impossible.
 */
private fun nextInsetLength(scan: TextScanner): CSSLength? {
    val save = scan.getPosition()
    scan.skipCommaWhitespace()
    if (scan.empty() || scan.peekKeyword("round")) {
        scan.setPosition(save)
        return null
    }
    val length = scan.nextLength()
    if (length == null) scan.setPosition(save)
    return length
}

/** Radius for `circle()` / `ellipse()`: length or closest-side/farthest-side. */
private fun parseClipRadius(scan: TextScanner): ClipRadius? {
    scan.skipWhitespace()
    if (scan.peekKeyword("closest-side")) {
        scan.nextIdent()
        return ClipRadius.ClosestSide
    }
    if (scan.peekKeyword("farthest-side")) {
        scan.nextIdent()
        return ClipRadius.FarthestSide
    }
    val len = scan.nextLength() ?: return null
    if (len.isNegative) return null
    return ClipRadius.Len(len)
}

context(loggerContext: LoggerContext)
private fun parseRect(body: String): Shaped<BasicShape.Rect>? {
    val scan = TextScanner(body)
    scan.skipWhitespace()
    // rect() takes absolute top/right/bottom/left (unlike inset() offsets).
    val edges = ArrayList<CSSLength>(4)
    repeat(4) { i ->
        if (i > 0) {
            scan.skipWhitespace()
            scan.skipCommaWhitespace()
            scan.skipWhitespace()
        }
        edges.add(scan.nextLength() ?: return null)
    }
    val round = parseRoundRadii(scan) ?: return null
    scan.skipWhitespace()
    var refBox: GeometryBox? = null
    if (!scan.empty()) {
        val word = scan.nextIdent() ?: return null
        refBox = parseGeometryBoxName(word) ?: return null
        scan.skipWhitespace()
    }
    if (!scan.empty()) return null
    return Shaped(
        BasicShape.Rect(
            top = edges[0],
            right = edges[1],
            bottom = edges[2],
            left = edges[3],
            roundX = round.first,
            roundY = round.second
        ),
        refBox,
    )
}

context(loggerContext: LoggerContext)
private fun parseXywh(body: String): Shaped<BasicShape.Xywh>? {
    val scan = TextScanner(body)
    scan.skipWhitespace()
    val nums = ArrayList<CSSLength>(4)
    repeat(4) { i ->
        if (i > 0) {
            scan.skipWhitespace()
            scan.skipCommaWhitespace()
            scan.skipWhitespace()
        }
        nums.add(scan.nextLength() ?: return null)
    }
    if (nums[2].isNegative || nums[3].isNegative) return null
    val round = parseRoundRadii(scan) ?: return null
    scan.skipWhitespace()
    var refBox: GeometryBox? = null
    if (!scan.empty()) {
        val word = scan.nextIdent() ?: return null
        refBox = parseGeometryBoxName(word) ?: return null
        scan.skipWhitespace()
    }
    if (!scan.empty()) return null
    return Shaped(
        BasicShape.Xywh(
            x = nums[0],
            y = nums[1],
            w = nums[2],
            h = nums[3],
            roundX = round.first,
            roundY = round.second
        ),
        refBox,
    )
}

/**
 * Parses `round <r> [ '/' <r2> ]?`, the corner-radius forms this renderer
 * supports: a single circular radius, or a single elliptical one. The per-corner
 * radius lists of CSS Borders 4 (`round 1px 2px 3px 4px`) are not supported;
 * a value using them is rejected here so it falls back to "no clip" like any
 * other malformed `clip-path`, rather than being mis-shaped.
 * Returns null only when the `round` keyword is present but malformed.
 */
context(loggerContext: LoggerContext)
private fun parseRoundRadii(scan: TextScanner): Pair<CSSLength?, CSSLength?>? {
    scan.skipWhitespace()
    if (!scan.consumeKeyword("round")) return Pair(null, null)
    scan.skipWhitespace()
    val first = scan.nextLength() ?: return null
    if (first.isNegative) return null
    scan.skipWhitespace()
    if (scan.consume('/')) {
        scan.skipWhitespace()
        val second = scan.nextLength() ?: return null
        if (second.isNegative) return null
        return Pair(first, second)
    }
    // A second length starts a per-corner radius list (CSS Borders 4), which we
    // don't implement: warn once and reject, so it falls back to "no clip" like
    // any other malformed clip-path. Anything else trailing (a refBox word,
    // garbage) keeps the old silent-malformed path: rewind and let the caller
    // decide.
    val save = scan.getPosition()
    scan.skipCommaWhitespace()
    scan.skipWhitespace()
    if (scan.nextLength() != null) {
        loggerContext.logUnsupportedFeature(UnsupportedFeature.CLIP_PATH_ROUND_CORNERS)
        return null
    }
    scan.setPosition(save)
    return Pair(first, first)
}

context(loggerContext: LoggerContext)
private fun parsePathShape(body: String): Shaped<BasicShape.Path>? {
    val scan = TextScanner(body)
    scan.skipWhitespace()
    var fillRule = FillRule.UNSPECIFIED
    // optional "<fill-rule>," prefix (same as polygon())
    val save = scan.getPosition()
    val word = scan.nextIdent()
    if (word != null && (word.equals("nonzero", ignoreCase = true) || word.equals("evenodd", ignoreCase = true))) {
        fillRule = parseFillRule(word)
        scan.skipWhitespace()
        if (!scan.consume(',')) return null
        scan.skipWhitespace()
    } else {
        scan.setPosition(save)
    }
    val quote = scan.peekChar()
    if (quote != '"' && quote != '\'') return null
    scan.nextChar()
    val start = scan.getPosition()
    while (!scan.empty() && scan.peekChar() != quote) scan.nextChar()
    if (scan.empty()) return null
    val pathData = scan.substring(start, scan.getPosition())
    scan.nextChar()
    if (pathData.isBlank()) return null
    val pathDef = parsePath(pathData)
    if (pathDef.isEmpty) return null
    scan.skipWhitespace()
    var refBox: GeometryBox? = null
    if (!scan.empty()) {
        val boxWord = scan.nextIdent() ?: return null
        refBox = parseGeometryBoxName(boxWord) ?: return null
        scan.skipWhitespace()
    }
    if (!scan.empty()) return null
    return Shaped(BasicShape.Path(pathDef, fillRule), refBox)
}

private fun parsePolygon(body: String): Shaped<BasicShape.Polygon>? {
    val scan = TextScanner(body)
    scan.skipWhitespace()
    var fillRule = FillRule.UNSPECIFIED
    // optional "<fill-rule>," prefix
    val save = scan.getPosition()
    val word = scan.nextIdent()
    if (word != null && (word.equals("nonzero", ignoreCase = true) || word.equals("evenodd", ignoreCase = true))) {
        fillRule = parseFillRule(word)
        scan.skipWhitespace()
        if (!scan.consume(',')) {
            // fill-rule without comma is invalid per grammar; require comma
            return null
        }
        scan.skipWhitespace()
    } else {
        scan.setPosition(save)
    }
    val points = ArrayList<CSSLength>()
    while (!scan.empty()) {
        // stop at trailing geometry-box keyword
        if (scan.peekKeyword("fill-box") || scan.peekKeyword("stroke-box") || scan.peekKeyword("view-box")) break
        val len = scan.nextLength() ?: return null
        points.add(len)
        scan.skipWhitespace()
        scan.skipCommaWhitespace()
        scan.skipWhitespace()
    }
    if (points.size < 4 || points.size % 2 != 0) return null
    scan.skipWhitespace()
    var refBox: GeometryBox? = null
    if (!scan.empty()) {
        val word = scan.nextIdent() ?: return null
        refBox = parseGeometryBoxName(word) ?: return null
        scan.skipWhitespace()
    }
    if (!scan.empty()) return null
    return Shaped(BasicShape.Polygon(points, fillRule), refBox)
}

/**
 * Parses the 1-4 value `<position>` of `circle()`/`ellipse()` into an (x, y)
 * pair. Reading is greedy: how many tokens follow decides how they are read.
 */
private fun parsePositionPair(scan: TextScanner): Pair<ClipPosition, ClipPosition>? {
    val first = nextPositionValue(scan) ?: return null
    val second = nextPositionValue(scan) ?: return singleValuePosition(first)
    val third = nextPositionValue(scan) ?: return twoValuePosition(first, second)
    val fourth = nextPositionValue(scan) ?: return offsetPosition(first, second, third)
    return offsetPosition(first, second, third, fourth)
}

/**
 * Reads the next `<position>` token: an edge/center keyword or a
 * `<length-percentage>`. Returns null with the scan position restored when
 * neither follows, so the caller can still read a trailing `<geometry-box>`.
 */
private fun nextPositionValue(scan: TextScanner): ClipPosition? {
    val save = scan.getPosition()
    scan.skipCommaWhitespace()
    val keyword = scan.nextIdent()
    if (keyword != null) {
        when (keyword.lowercase()) {
            "left" -> return ClipPosition.Left
            "center" -> return ClipPosition.Center
            "right" -> return ClipPosition.Right
            "top" -> return ClipPosition.Top
            "bottom" -> return ClipPosition.Bottom
        }
        scan.setPosition(save)
    }
    val length = scan.nextLength()
    return if (length == null) {
        scan.setPosition(save)
        null
    } else {
        ClipPosition.Len(length)
    }
}

/** Single value: `at top`/`at bottom` position vertically, anything else horizontally. */
private fun singleValuePosition(value: ClipPosition): Pair<ClipPosition, ClipPosition> {
    return if (value.isEdgeY()) Pair(ClipPosition.Center, value) else Pair(value, ClipPosition.Center)
}

/** Two values, one per axis. A vertical keyword may be written first: `at top left`. */
private fun twoValuePosition(
    first: ClipPosition,
    second: ClipPosition,
): Pair<ClipPosition, ClipPosition>? {
    // A lone keyword+offset pair is the 3-4 value syntax missing its second axis.
    if (first.isKeyword() && !second.isKeyword()) return null
    if (first.isEdgeY()) return if (second.isEdgeY()) null else Pair(second, first)
    return if (second.isV() || !second.isKeyword()) Pair(first, second) else null
}

/**
 * Three-value syntax: a keyword with an offset on one axis, the other axis
 * given by a plain value, in either order (`right 10px bottom`,
 * `left bottom 20px`).
 */
private fun offsetPosition(
    first: ClipPosition,
    second: ClipPosition,
    third: ClipPosition,
): Pair<ClipPosition, ClipPosition>? {
    val dx = second.asLen()
    if (dx != null) {
        if (!first.isH() || !third.isV()) return null
        return Pair(ClipPosition.Offset(first, dx), third)
    }
    val dy = third.asLen() ?: return null
    if (!first.isH() || !second.isV()) return null
    return Pair(first, ClipPosition.Offset(second, dy))
}

/** Four-value syntax: `left 10px top 20px`. */
private fun offsetPosition(
    first: ClipPosition,
    second: ClipPosition,
    third: ClipPosition,
    fourth: ClipPosition,
): Pair<ClipPosition, ClipPosition>? {
    val dx = second.asLen() ?: return null
    val dy = fourth.asLen() ?: return null
    if (!first.isH() || !third.isV()) return null
    return Pair(ClipPosition.Offset(first, dx), ClipPosition.Offset(third, dy))
}

/** `left` or `right`. */
private fun ClipPosition.isEdgeX() = this == ClipPosition.Left || this == ClipPosition.Right

/** `top` or `bottom`. */
private fun ClipPosition.isEdgeY() = this == ClipPosition.Top || this == ClipPosition.Bottom

/** Keyword rather than `<length-percentage>`. */
private fun ClipPosition.isKeyword() = asLen() == null

/** `left`, `center` or `right`: a keyword that can anchor a horizontal position. */
private fun ClipPosition.isH() = isEdgeX() || this == ClipPosition.Center

/** `top`, `center` or `bottom`: a keyword that can anchor a vertical position. */
private fun ClipPosition.isV() = isEdgeY() || this == ClipPosition.Center

private fun ClipPosition.asLen() = (this as? ClipPosition.Len)?.v

private fun parseGeometryBoxWord(trailing: String): GeometryBox? {
    val t = trailing.trim()
    // No box: CSS default is `border-box`; SVG has no CSS boxes, so the
    // object bounding box (`fill-box`) is the faithful analog (a `view-box`
    // default would misplace shapes on off-origin elements vs browsers).
    if (t.isEmpty()) return GeometryBox.FILL_BOX
    if (t.any { it.isWhitespace() }) return null
    return parseGeometryBoxName(t)
}

// Shared with transform-box parsing (same keyword table and SVG fallbacks).
internal fun parseGeometryBoxName(word: String): GeometryBox? {
    return when (word.lowercase()) {
        "fill-box" -> GeometryBox.FILL_BOX
        "stroke-box" -> GeometryBox.STROKE_BOX
        "view-box" -> GeometryBox.VIEW_BOX
        // border-box maps to view-box in SVG (documented approximation)
        "border-box", "padding-box", "content-box", "margin-box" -> GeometryBox.VIEW_BOX
        else -> null
    }
}

/**
 * Parses a semicolon-separated list of `clip-path` values (e.g., the `values`
 * of an `<animate attributeName="clip-path">`). `none` is a valid endpoint
 * ([CSSClipPath.NoClip]); any invalid item drops the whole list (null), so
 * the animation is rejected like any other invalid value.
 */
context(loggerContext: LoggerContext)
internal fun parseSemicolonClipPathList(value: String): List<CSSClipPath>? {
    val result = mutableListOf<CSSClipPath>()
    val len = value.length
    var start = 0
    var i = 0
    while (i <= len) {
        if (i == len || value[i] == ';') {
            if (i > start) {
                val segment = value.substring(start, i).trim()
                if (segment.isNotEmpty()) {
                    if (segment.equals("none", ignoreCase = true)) {
                        result.add(CSSClipPath.NoClip)
                    } else {
                        result.add(parseClipPath(segment) ?: return null)
                    }
                }
            }
            start = i + 1
        }
        i++
    }
    return result
}

/**
 * Parses one `clip-path` animation endpoint: `none` maps to
 * [CSSClipPath.NoClip] (a valid endpoint), anything unparsable is null
 * (absent value, e.g., a missing `from` — or an invalid animation).
 */
context(loggerContext: LoggerContext)
internal fun parseClipPathEndpoint(value: String): CSSClipPath? {
    val v = value.trim()
    if (v.isEmpty()) return null
    if (v.equals("none", ignoreCase = true)) return CSSClipPath.NoClip
    return parseClipPath(v)
}
