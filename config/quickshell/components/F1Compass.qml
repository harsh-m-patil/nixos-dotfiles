import QtQuick

import "."

// Heading dial: a ring of ticks with a marker at `heading` (degrees, 0 = north). Children sit centred.
Item {
    id: compass
    property real heading: 0
    property color accent: F1Hub.accent
    default property alias content: centre.data

    implicitWidth: 120
    implicitHeight: 120
    onHeadingChanged: face.requestPaint()
    onAccentChanged: face.requestPaint()

    Canvas {
        id: face
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2 - 2
            if (r <= 8) return
            ctx.fillStyle = Qt.rgba(0, 0, 0, 0.35)
            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill()

            for (let i = 0; i < 36; i++) {
                const a = i * 10 * Math.PI / 180 - Math.PI / 2, major = i % 9 === 0
                ctx.strokeStyle = Qt.rgba(1, 1, 1, major ? 0.6 : 0.2)
                ctx.lineWidth = major ? 2 : 1
                const len = major ? 8 : 4
                ctx.beginPath()
                ctx.moveTo(cx + (r - 3) * Math.cos(a), cy + (r - 3) * Math.sin(a))
                ctx.lineTo(cx + (r - 3 - len) * Math.cos(a), cy + (r - 3 - len) * Math.sin(a))
                ctx.stroke()
            }

            const a = compass.heading * Math.PI / 180 - Math.PI / 2, tip = r - 14, w = 0.16
            ctx.fillStyle = compass.accent
            ctx.beginPath()
            ctx.moveTo(cx + tip * Math.cos(a), cy + tip * Math.sin(a))
            ctx.lineTo(cx + (tip - 11) * Math.cos(a - w), cy + (tip - 11) * Math.sin(a - w))
            ctx.lineTo(cx + (tip - 11) * Math.cos(a + w), cy + (tip - 11) * Math.sin(a + w))
            ctx.closePath()
            ctx.fill()
        }
    }

    Item { id: centre; anchors.fill: parent }
}
