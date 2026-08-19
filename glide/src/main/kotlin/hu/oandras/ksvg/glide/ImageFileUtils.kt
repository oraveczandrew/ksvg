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

@file:Suppress("NOTHING_TO_INLINE")

package hu.oandras.ksvg.glide

import java.io.InputStream

internal fun isSvg(inputStream: InputStream): Boolean {
    val source = inputStream.buffered()
    source.mark(20)
    val byteArray = ByteArray(15)
    source.read(byteArray)
    source.reset()
    return !isAndroidBinaryXmlFile(byteArray) && guessImageTypeFromBytes(byteArray) == null && hasSvgOpenTag(source)
}

@ImageMime
@SuppressWarnings("kotlin:S3776")
private fun guessImageTypeFromBytes(bytes: ByteArray?): String? {
    if (bytes == null || bytes.size < 15) {
        return null
    }

    if (
        bytes.isSameByte(0, 'G') &&
        bytes.isSameByte(1, 'I') &&
        bytes.isSameByte(2, 'F') &&
        bytes.isSameByte(3, '8')
    ) {
        return ImageMime.GIF
    }

    if (
        bytes.isSameByte(0, 0x89) &&
        bytes.isSameByte(1, 'P') &&
        bytes.isSameByte(2, 'N') &&
        bytes.isSameByte(3, 'G') &&
        bytes.isSameByte(4, '\r') &&
        bytes.isSameByte(5, '\n') &&
        bytes.isSameByte(6, 0x1A) &&
        bytes.isSameByte(7, '\n')
    ) {
        return ImageMime.PNG
    }

    if (
        bytes.isSameByte(0, 0xFF) &&
        bytes.isSameByte(1, 0xD8) &&
        bytes.isSameByte(2, 0xFF) &&
        (
                bytes.isSameByte(3, 0xE0) ||
                        bytes.isSameByte(3, 0xE1) ||
                        bytes.isSameByte(3, 0xE2) ||
                        bytes.isSameByte(3, 0xE3) ||
                        bytes.isSameByte(3, 0xEE) ||
                        bytes.isSameByte(3, 0xDB) ||
                        bytes.isSameByte(3, 0xEB)
                )
    ) {
        return ImageMime.JPEG
    }

    if (
        bytes.isSameByte(0, 'R') &&
        bytes.isSameByte(1, 'I') &&
        bytes.isSameByte(2, 'F') &&
        bytes.isSameByte(3, 'F') &&

        bytes.isSameByte(8, 'W') &&
        bytes.isSameByte(9, 'E') &&
        bytes.isSameByte(10, 'B') &&
        bytes.isSameByte(11, 'P') &&
        bytes.isSameByte(12, 'V') &&
        bytes.isSameByte(13, 'P') &&
        bytes.isSameByte(14, '8')
    ) {
        return ImageMime.WEBP
    }

    if (
        bytes.isSameByte(4, 'f') &&
        bytes.isSameByte(5, 't') &&
        bytes.isSameByte(6, 'y') &&
        bytes.isSameByte(7, 'p') &&
        bytes.isSameByte(8, 'a') &&
        bytes.isSameByte(9, 'v') &&
        bytes.isSameByte(10, 'i') &&
        bytes.isSameByte(11, 'f')
    ) {
        return ImageMime.AVIF
    }

    return null
}

private fun hasSvgOpenTag(inputStream: InputStream): Boolean {
    val buffer = ByteArray(8192)
    var match = 0

    while (true) {
        val read = inputStream.read(buffer)
        if (read == -1) return false

        for (i in 0 until read) {
            match = when (buffer[i].toInt().toChar()) {
                '<' -> 1
                's', 'S' -> if (match == 1) 2 else 0
                'v', 'V' -> if (match == 2) 3 else 0
                'g', 'G' -> if (match == 3) return true else 0
                else -> 0
            }
        }
    }
}

private inline fun ByteArray.isSameByte(index: Int, byte: Int): Boolean {
    return get(index).bitsAsInt() == byte
}

@Suppress("DEPRECATION")
private inline fun ByteArray.isSameByte(index: Int, char: Char): Boolean {
    return get(index).bitsAsInt() == char.toInt()
}

private inline fun Byte.bitsAsInt(): Int {
    return toInt() and 0xFF
}

private fun isAndroidBinaryXmlFile(byteArray: ByteArray): Boolean {
    return byteArray[0] == 0x3.toByte() &&
            byteArray[1] == 0x0.toByte() &&
            byteArray[2] == 0x8.toByte()
}