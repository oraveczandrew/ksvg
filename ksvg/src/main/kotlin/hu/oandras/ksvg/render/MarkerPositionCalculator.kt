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

package hu.oandras.ksvg.render

import hu.oandras.ksvg.dom.core.PathDefinition
import hu.oandras.ksvg.dom.core.PathInterface
import hu.oandras.ksvg.dom.shapes.LineShape
import hu.oandras.ksvg.dom.shapes.PolyLineShape
import hu.oandras.ksvg.dom.shapes.PolygonShape

context(renderContext: RenderContext)
internal fun calculateMarkerPositions(obj: LineShape): List<MarkerVector> {
    val x1: Float = obj.x1?.floatValueXInContext() ?: 0f
    val y1: Float = obj.y1?.floatValueYInContext() ?: 0f
    val x2: Float = obj.x2?.floatValueXInContext() ?: 0f
    val y2: Float = obj.y2?.floatValueYInContext() ?: 0f

    return listOf(
        MarkerVector(x1, y1, x2 - x1, y2 - y1),
        MarkerVector(x2, y2, x2 - x1, y2 - y1)
    )
}

context(_: RenderContext)
internal fun calculateMarkerPositions(obj: PolyLineShape): List<MarkerVector>? {
    val points = obj.points ?: return null

    val numPoints = points.size
    if (numPoints < 2) {
        return null
    }

    val markers: MutableList<MarkerVector> = ArrayList(numPoints / 2 + 1)
    var lastPos = MarkerVector(points[0], points[1], 0f, 0f)
    var x = 0f
    var y = 0f

    var i = 2
    while (i < numPoints) {
        x = points[i]
        y = points[i + 1]
        lastPos.add(x, y)
        markers.add(lastPos)
        lastPos = MarkerVector(x, y, x - lastPos.x, y - lastPos.y)
        i += 2
    }

    // Deal with last point
    if (obj is PolygonShape) {
        if (x != points[0] && y != points[1]) {
            x = points[0]
            y = points[1]
            lastPos.add(x, y)
            markers.add(lastPos)
            // Last marker point needs special handling because its orientation depends
            // on the orientation of the very first segment of the path
            val newPos = MarkerVector(x, y, x - lastPos.x, y - lastPos.y)
            newPos.add(markers[0])
            markers.add(newPos)
            markers[0] = newPos // Start marker is the same
        }
    } else {
        markers.add(lastPos)
    }
    return markers
}

/*
*  Calculates the positions and orientations of any markers that should be placed on the given path.
*/
internal class MarkerPositionCalculator(pathDef: PathDefinition?) : PathInterface {
    @JvmField
    val markers: MutableList<MarkerVector> = ArrayList()

    private var startX = 0f
    private var startY = 0f
    private var lastPos: MarkerVector? = null
    private var startArc = false
    private var normalCubic = true
    private var subpathStartIndex = -1
    private var closePathReAdjustPending = false


    init {
        if (pathDef != null) {
            // Generate and add markers for the first N-1 points
            pathDef.enumeratePath(this)

            if (closePathReAdjustPending) {
                // Now correct the start and end marker points of the subpath.
                // They should both be oriented as if this was a midpoint (ie sum the vectors).
                val lastPos = lastPos!!
                lastPos.add(markers[subpathStartIndex])
                // Overwrite start marker. Other (end) marker will be written on exit or at start of next subpath.
                markers[subpathStartIndex] = lastPos
                closePathReAdjustPending = false
            }
            // Add the marker for the pending last point
            lastPos?.let { markers.add(it) }
        }
    }

    override fun moveTo(x: Float, y: Float) {
        if (closePathReAdjustPending) {
            // Now correct the start and end marker points of the subpath.
            // They should both be oriented as if this was a midpoint (ie sum the vectors).
            val lastPos = lastPos!!
            lastPos.add(markers[subpathStartIndex])
            // Overwrite start marker. Other (end) marker will be written on exit or at start of next subpath.
            markers[subpathStartIndex] = lastPos
            closePathReAdjustPending = false
        }
        lastPos?.let { markers.add(it) }
        startX = x
        startY = y
        lastPos = MarkerVector(x, y, 0f, 0f)
        subpathStartIndex = markers.size
    }

    override fun lineTo(x: Float, y: Float) {
        val prevPos = lastPos!!
        prevPos.add(x, y)
        markers.add(prevPos)
        lastPos = MarkerVector(x, y, x - prevPos.x, y - prevPos.y)
        closePathReAdjustPending = false
    }

    override fun cubicTo(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) {
        if (normalCubic || startArc) {
            val prevPos = lastPos!!
            prevPos.add(x1, y1)
            markers.add(prevPos)
            startArc = false
        }
        lastPos = MarkerVector(x3, y3, x3 - x2, y3 - y2)
        closePathReAdjustPending = false
    }

    override fun quadTo(x1: Float, y1: Float, x2: Float, y2: Float) {
        val prevPos = lastPos!!
        prevPos.add(x1, y1)
        markers.add(prevPos)
        lastPos = MarkerVector(x2, y2, x2 - x1, y2 - y1)
        closePathReAdjustPending = false
    }

    override fun arcTo(
        rx: Float,
        ry: Float,
        xAxisRotation: Float,
        largeArcFlag: Boolean,
        sweepFlag: Boolean,
        x: Float,
        y: Float
    ) {
        // We'll piggyback on the arc->bezier conversion to get our start and end vectors
        startArc = true
        normalCubic = false
        val lastPos = lastPos!!
        arcTo(
            lastPos.x,
            lastPos.y,
            rx,
            ry,
            xAxisRotation,
            largeArcFlag,
            sweepFlag,
            x,
            y,
            this
        )
        normalCubic = true
        closePathReAdjustPending = false
    }

    override fun close() {
        markers.add(lastPos!!)
        lineTo(startX, startY)
        // We may need to readjust the first and last markers on this subpath so that
        // the orientation is a sum of the inward and outward vectors.
        // But this only happens if the path ends or the next subpath starts with a Move.
        // See description of "orient" attribute in section 11.6.2.
        closePathReAdjustPending = true
    }
}