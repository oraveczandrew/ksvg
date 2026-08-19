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

package hu.oandras.ksvg.dom.core

internal class PathDefinition(
    initialCommands: Int = 8,
    initialCoords: Int = 16
) : PathInterface {
    private var commands: ByteArray = ByteArray(initialCommands)
    private var commandsLength = 0
    private var coords: FloatArray = FloatArray(initialCoords)
    private var coordsLength = 0

    val isEmpty: Boolean
        get() = commandsLength == 0

    private fun addCommand(value: Byte) {
        if (commandsLength == commands.size) {
            val newSize = if (commands.isEmpty()) 8 else commands.size * 2
            val newCommands = ByteArray(newSize)
            System.arraycopy(commands, 0, newCommands, 0, commands.size)
            commands = newCommands
        }
        commands[commandsLength++] = value
    }

    private fun coordsEnsure(num: Int) {
        if (coords.size < (coordsLength + num)) {
            var newSize = if (coords.isEmpty()) 16 else coords.size * 2
            while (newSize < (coordsLength + num)) {
                newSize *= 2
            }
            val newCoords = FloatArray(newSize)
            System.arraycopy(coords, 0, newCoords, 0, coords.size)
            coords = newCoords
        }
    }


    override fun moveTo(x: Float, y: Float) {
        addCommand(MOVETO)
        coordsEnsure(2)
        val coords = coords
        coords[coordsLength++] = x
        coords[coordsLength++] = y
    }


    override fun lineTo(x: Float, y: Float) {
        addCommand(LINETO)
        coordsEnsure(2)
        val coords = coords
        coords[coordsLength++] = x
        coords[coordsLength++] = y
    }

    override fun cubicTo(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) {
        addCommand(CUBICTO)
        coordsEnsure(6)
        val coords = coords
        coords[coordsLength++] = x1
        coords[coordsLength++] = y1
        coords[coordsLength++] = x2
        coords[coordsLength++] = y2
        coords[coordsLength++] = x3
        coords[coordsLength++] = y3
    }

    override fun quadTo(x1: Float, y1: Float, x2: Float, y2: Float) {
        addCommand(QUADTO)
        coordsEnsure(4)
        val coords = coords
        coords[coordsLength++] = x1
        coords[coordsLength++] = y1
        coords[coordsLength++] = x2
        coords[coordsLength++] = y2
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
        val arc = ARCTO.toInt() or (if (largeArcFlag) 2 else 0) or (if (sweepFlag) 1 else 0)
        addCommand(arc.toByte())
        coordsEnsure(5)
        val coords = coords
        coords[coordsLength++] = rx
        coords[coordsLength++] = ry
        coords[coordsLength++] = xAxisRotation
        coords[coordsLength++] = x
        coords[coordsLength++] = y
    }

    override fun close() {
        addCommand(CLOSE)
    }

    fun enumeratePath(handler: PathInterface) {
        var coordsPos = 0

        for (commandPos in 0..<commandsLength) {
            val commands = commands
            val coords = coords
            when (val command = commands[commandPos]) {
                MOVETO -> handler.moveTo(
                    x = coords[coordsPos++],
                    y = coords[coordsPos++]
                )
                LINETO -> handler.lineTo(
                    x = coords[coordsPos++],
                    y = coords[coordsPos++]
                )
                CUBICTO -> handler.cubicTo(
                    x1 = coords[coordsPos++],
                    y1 = coords[coordsPos++],
                    x2 = coords[coordsPos++],
                    y2 = coords[coordsPos++],
                    x3 = coords[coordsPos++],
                    y3 = coords[coordsPos++]
                )

                QUADTO -> handler.quadTo(
                    x1 = coords[coordsPos++],
                    y1 = coords[coordsPos++],
                    x2 = coords[coordsPos++],
                    y2 = coords[coordsPos++]
                )

                CLOSE -> handler.close()
                else -> {
                    val largeArcFlag = (command.toInt() and 2) != 0
                    val sweepFlag = (command.toInt() and 1) != 0
                    handler.arcTo(
                        rx = coords[coordsPos++],
                        ry = coords[coordsPos++],
                        xAxisRotation = coords[coordsPos++],
                        largeArcFlag = largeArcFlag,
                        sweepFlag = sweepFlag,
                        x = coords[coordsPos++],
                        y = coords[coordsPos++]
                    )
                }
            }
        }
    }

    fun commandsEquals(other: PathDefinition): Boolean {
        if (commandsLength != other.commandsLength) return false
        val a = commands
        val b = other.commands
        for (i in 0 until commandsLength) {
            if (a[i] != b[i]) return false
        }
        return true
    }

    /**
     * Writes an interpolated path into [handler]. The two definitions must have identical command
     * sequences (see [commandsEquals]); otherwise a discrete (snap) fallback is used.
     */
    fun enumerateInterpolated(other: PathDefinition, progress: Float, handler: PathInterface) {
        if (!commandsEquals(other)) {
            if (progress < 0.5f) enumeratePath(handler) else other.enumeratePath(handler)
            return
        }

        val a = coords
        val b = other.coords
        var pa = 0
        var pb = 0
        for (c in 0 until commandsLength) {
            when (val command = commands[c]) {
                MOVETO -> {
                    handler.moveTo(lerp(a[pa], b[pb], progress), lerp(a[pa + 1], b[pb + 1], progress))
                    pa += 2
                    pb += 2
                }

                LINETO -> {
                    handler.lineTo(lerp(a[pa], b[pb], progress), lerp(a[pa + 1], b[pb + 1], progress))
                    pa += 2
                    pb += 2
                }

                CUBICTO -> {
                    handler.cubicTo(
                        lerp(a[pa], b[pb], progress), lerp(a[pa + 1], b[pb + 1], progress),
                        lerp(a[pa + 2], b[pb + 2], progress), lerp(a[pa + 3], b[pb + 3], progress),
                        lerp(a[pa + 4], b[pb + 4], progress), lerp(a[pa + 5], b[pb + 5], progress)
                    )
                    pa += 6
                    pb += 6
                }

                QUADTO -> {
                    handler.quadTo(
                        lerp(a[pa], b[pb], progress), lerp(a[pa + 1], b[pb + 1], progress),
                        lerp(a[pa + 2], b[pb + 2], progress), lerp(a[pa + 3], b[pb + 3], progress)
                    )
                    pa += 4
                    pb += 4
                }

                CLOSE -> handler.close()

                else -> {
                    val largeArcFlag = (command.toInt() and 2) != 0
                    val sweepFlag = (command.toInt() and 1) != 0
                    handler.arcTo(
                        lerp(a[pa], b[pb], progress),
                        lerp(a[pa + 1], b[pb + 1], progress),
                        lerp(a[pa + 2], b[pb + 2], progress),
                        largeArcFlag,
                        sweepFlag,
                        lerp(a[pa + 3], b[pb + 3], progress),
                        lerp(a[pa + 4], b[pb + 4], progress)
                    )
                    pa += 5
                    pb += 5
                }
            }
        }
    }

    @Suppress("SpellCheckingInspection")
    companion object {
        private const val MOVETO: Byte = 0
        private const val LINETO: Byte = 1
        private const val CUBICTO: Byte = 2
        private const val QUADTO: Byte = 3
        private const val ARCTO: Byte = 4 // 4-7
        private const val CLOSE: Byte = 8

        internal fun lerp(from: Float, to: Float, progress: Float): Float = from + (to - from) * progress
    }
}