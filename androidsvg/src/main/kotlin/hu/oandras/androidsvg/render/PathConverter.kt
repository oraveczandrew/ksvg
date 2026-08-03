package hu.oandras.androidsvg.render

import android.graphics.Matrix
import android.graphics.Path
import hu.oandras.androidsvg.dom.PathDefinition
import hu.oandras.androidsvg.dom.PathInterface
import hu.oandras.androidsvg.utils.toRadians
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.acos
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin
import kotlin.math.sqrt

//==============================================================================
/*
*  Convert an internal PathDefinition to an android.graphics.Path object
*/
internal class PathConverter internal constructor(pathDef: PathDefinition?) : PathInterface {
    @JvmField
    val path: Path = Path()

    @JvmField
    var lastX: Float = 0f

    @JvmField
    var lastY: Float = 0f

    init {
        pathDef?.enumeratePath(this)
    }

    override fun moveTo(x: Float, y: Float) {
        path.moveTo(x, y)
        lastX = x
        lastY = y
    }

    override fun lineTo(x: Float, y: Float) {
        path.lineTo(x, y)
        lastX = x
        lastY = y
    }

    override fun cubicTo(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) {
        path.cubicTo(x1, y1, x2, y2, x3, y3)
        lastX = x3
        lastY = y3
    }

    override fun quadTo(x1: Float, y1: Float, x2: Float, y2: Float) {
        path.quadTo(x1, y1, x2, y2)
        lastX = x2
        lastY = y2
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
        arcTo(
            lastX = lastX,
            lastY = lastY,
            rx = rx,
            ry = ry,
            angle = xAxisRotation,
            largeArcFlag = largeArcFlag,
            sweepFlag = sweepFlag,
            x = x,
            y = y,
            pather = this
        )
        lastX = x
        lastY = y
    }

    override fun close() {
        path.close()
    }
}

//=========================================================================
// Handling of Arcs
/*
* SVG arc representation uses "endpoint parameterization" where we specify the start and endpoint of the arc.
* This is to be consistent with the other path commands.  However, we need to convert this to "center point
* parameterization" in order to calculate the arc. Handily, the SVG spec provides all the required maths
* in section "F.6 Elliptical arc implementation notes".
*
* Some of this code has been borrowed from the Batik library (Apache-2 license).
*
* Previously, to work around issue #62, we converted this function to use floats. However in issue #155,
* we discovered that there are some arcs that fail due of a lack of precision. So we have switched back to doubles.
*/
internal fun arcTo(
    lastX: Float,
    lastY: Float,
    rx: Float,
    ry: Float,
    angle: Float,
    largeArcFlag: Boolean,
    sweepFlag: Boolean,
    x: Float,
    y: Float,
    pather: PathInterface
) {
    var dRx = rx.toDouble()
    var dRy = ry.toDouble()
    if (lastX == x && lastY == y) {
        // If the endpoints (x, y) and (x0, y0) are identical, then this
        // is equivalent to omitting the elliptical arc segment entirely.
        // (behavior specified by the spec)
        return
    }

    // Handle degenerate case (behavior specified by the spec)
    if (dRx == 0.0 || dRy == 0.0) {
        pather.lineTo(x, y)
        return
    }

    // Sign of the radii is ignored (behavior specified by the spec)
    dRx = abs(dRx)
    dRy = abs(dRy)

    // Convert angle from degrees to radians
    val angleRad = (angle % 360.0).toRadians()
    val cosAngle = cos(angleRad)
    val sinAngle = sin(angleRad)

    // We simplify the calculations by transforming the arc so that the origin is at the
    // midpoint calculated above followed by a rotation to line up the coordinate axes
    // with the axes of the ellipse.

    // Compute the midpoint of the line between the current and the end point
    val dx2 = (lastX.toDouble() - x) / 2.0
    val dy2 = (lastY.toDouble() - y) / 2.0

    // Step 1 : Compute (x1', y1')
    // x1,y1 is the midpoint vector rotated to take the arc's angle out of consideration
    val x1 = cosAngle * dx2 + sinAngle * dy2
    val y1 = -sinAngle * dx2 + cosAngle * dy2

    var rx_sq = dRx * dRx
    var ry_sq = dRy * dRy
    val x1_sq = x1 * x1
    val y1_sq = y1 * y1

    // Check that radii are large enough.
    // If they are not, the spec says to scale them up so they are.
    // This is to compensate for potential rounding errors/differences between SVG implementations.
    val radiiCheck = x1_sq / rx_sq + y1_sq / ry_sq
    if (radiiCheck > 0.99999) {
        val radiiScale = sqrt(radiiCheck) * 1.00001
        dRx *= radiiScale
        dRy *= radiiScale
        rx_sq = dRx * dRx
        ry_sq = dRy * dRy
    }

    // Step 2 : Compute (cx1, cy1) - the transformed center point
    var sign = if (largeArcFlag == sweepFlag) -1.0 else 1.0
    var sq = (rx_sq * ry_sq - rx_sq * y1_sq - ry_sq * x1_sq) / (rx_sq * y1_sq + ry_sq * x1_sq)
    sq = max(0.0, sq)
    val coef = sign * sqrt(sq)
    val cx1 = coef * (dRx * y1 / dRy)
    val cy1 = coef * -(dRy * x1 / dRx)

    // Step 3 : Compute (cx, cy) from (cx1, cy1)
    val sx2 = (lastX.toDouble() + x) / 2.0
    val sy2 = (lastY.toDouble() + y) / 2.0
    val cx = sx2 + (cosAngle * cx1 - sinAngle * cy1)
    val cy = sy2 + (sinAngle * cx1 + cosAngle * cy1)

    // Step 4 : Compute the angleStart (angle1) and the angleExtent (dangle)
    val ux = (x1 - cx1) / dRx
    val uy = (y1 - cy1) / dRy
    val vx = (-x1 - cx1) / dRx
    val vy = (-y1 - cy1) / dRy

    // Angle between two vectors is +/- acos( u.v / len(u) * len(v))
    // Where '.' is the dot product. And +/- is calculated from the sign of the cross product (u x v)
    val TWO_PI = PI * 2.0

    // Compute the start angle
    // The angle between (ux,uy) and the 0deg angle (1,0)
    var n: Double = sqrt(ux * ux + uy * uy) // len(u) * len(1,0) == len(u)
    var p: Double = ux // u.v == (ux,uy).(1,0) == (1 * ux) + (0 * uy) == ux
    sign = if (uy < 0) -1.0 else 1.0 // u x v == (1 * uy - ux * 0) == uy
    var angleStart = sign * acos(p / n) // No need for checkedArcCos() here. (p >= n) should always be true.

    // Compute the angle extent
    n = sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
    p = ux * vx + uy * vy
    sign = if (ux * vy - uy * vx < 0) -1.0 else 1.0
    var angleExtent: Double = sign * checkedArcCos(p / n)

    // Catch angleExtents of 0, which will cause problems later in arcToBeziers
    if (angleExtent == 0.0) {
        pather.lineTo(x, y)
        return
    }

    if (!sweepFlag && angleExtent > 0) {
        angleExtent -= TWO_PI
    } else if (sweepFlag && angleExtent < 0) {
        angleExtent += TWO_PI
    }
    angleExtent %= TWO_PI
    angleStart %= TWO_PI

    // Many elliptical arc implementations including the Java2D and Android ones, only
    // support arcs that are axis aligned.  Therefore, we need to substitute the arc
    // with Bézier curves.  The following method call will generate the Béziers for
    // a unit circle that covers the arc angles we want.
    val bezierPoints: FloatArray = arcToBeziers(angleStart, angleExtent)

    // Calculate a transformation matrix that will move and scale these bezier points to the correct location.
    val m = Matrix()
    m.postScale(dRx.toFloat(), dRy.toFloat())
    m.postRotate(angle)
    m.postTranslate(cx.toFloat(), cy.toFloat())
    m.mapPoints(bezierPoints)

    // The last point in the bezier set should match exactly the last coord pair in the arc (ie: x,y). But
    // considering all the mathematical manipulation we have been doing, it is bound to be off by a tiny
    // fraction. Experiments show that it can be up to around 0.00002.  So why don't we just set it to
    // exactly what it ought to be.
    bezierPoints[bezierPoints.size - 2] = x
    bezierPoints[bezierPoints.size - 1] = y

    // Final step is to add the Bézier curves to the path
    var i = 0
    while (i < bezierPoints.size) {
        pather.cubicTo(
            x1 = bezierPoints[i],
            y1 = bezierPoints[i + 1],
            x2 = bezierPoints[i + 2],
            y2 = bezierPoints[i + 3],
            x3 = bezierPoints[i + 4],
            y3 = bezierPoints[i + 5]
        )
        i += 6
    }
}


// Check input to Math.acos() in case rounding or other errors result in a val < -1 or > +1.
// For example, see the possible KitKat JIT error described in issue #62.
private fun checkedArcCos(value: Double): Double {
    return if (value < -1.0) PI else if (value > 1.0) 0.0 else acos(value)
}


/*
* Generate the control points and endpoints for a set of Bézier curves that match
* a circular arc starting from angle 'angleStart' and sweep the angle 'angleExtent'.
* The circle the arc follows will be centred on (0,0) and have a radius of 1.0.
*
* Each bezier can cover no more than 90 degrees, so the arc will be divided evenly
* into a maximum of four curves.
*
* The resulting control points will later be scaled and rotated to match the final
* arc required.
*
* The returned array has the format [x0,y0, x1,y1,...] and excludes the start point
* of the arc.
*/
private fun arcToBeziers(angleStart: Double, angleExtent: Double): FloatArray {
    val numSegments = ceil(abs(angleExtent) * 2.0 / PI).toInt() // (angleExtent / 90deg)

    val angleIncrement = angleExtent / numSegments


    // The length of each control point vector is given by the following formula.
    val controlLength =
        4.0 / 3.0 * sin(angleIncrement / 2.0) / (1.0 + cos(angleIncrement / 2.0))

    val coords = FloatArray(numSegments * 6)
    var pos = 0

    for (i in 0..<numSegments) {
        var angle = angleStart + i * angleIncrement
        // Calculate the control vector at this angle
        var dx = cos(angle)
        var dy = sin(angle)
        // First control point
        coords[pos++] = (dx - controlLength * dy).toFloat()
        coords[pos++] = (dy + controlLength * dx).toFloat()
        // Second control point
        angle += angleIncrement
        dx = cos(angle)
        dy = sin(angle)
        coords[pos++] = (dx + controlLength * dy).toFloat()
        coords[pos++] = (dy - controlLength * dx).toFloat()
        // Endpoint of bezier
        coords[pos++] = dx.toFloat()
        coords[pos++] = dy.toFloat()
    }
    return coords
}