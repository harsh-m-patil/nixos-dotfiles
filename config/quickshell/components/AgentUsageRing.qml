import QtQuick

import "."

// Small progress ring: `value` 0…1 of the circle is filled with `accent`.
Canvas {
    id: ring
    property real value: 0
    property color accent: Theme.iris
    property color track: F1Hub.fillStrong
    property real stroke: 2.5
    implicitWidth: 14
    implicitHeight: 14
    renderStrategy: Canvas.Cooperative

    onValueChanged: requestPaint()
    onAccentChanged: requestPaint()
    onTrackChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        const r = (width - stroke) / 2, c = width / 2
        ctx.reset()
        ctx.lineWidth = stroke
        ctx.lineCap = "round"
        ctx.strokeStyle = track
        ctx.beginPath(); ctx.arc(c, c, r, 0, 2 * Math.PI); ctx.stroke()
        ctx.strokeStyle = accent
        ctx.beginPath()
        ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.max(0.01, Math.min(1, value)))
        ctx.stroke()
    }
}
