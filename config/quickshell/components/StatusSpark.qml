import QtQuick
import QtQuick.Layouts

import "."

// A mini history chart (values 0…1) with its label and current figure.
ColumnLayout {
    id: spark
    property string label
    property string value
    property string sub
    property var history: []
    property color accent: Theme.iris
    property bool selected: false

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        F1Text { text: spark.label; role: "footnote"; tone: "secondary"; Layout.fillWidth: true }
        F1Text { text: spark.sub; role: "caption"; tone: "tertiary"; numeric: true; visible: text !== "" }
    }
    F1Text { text: spark.value; role: "title2"; numeric: true }

    Canvas {
        id: canvas
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 44
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const h = spark.history, n = 60
            if (h.length < 2) return
            const pts = h.slice(-n)
            const step = width / (n - 1)
            const x0 = width - (pts.length - 1) * step
            const y = v => height - 2 - Math.max(0, Math.min(1, v)) * (height - 4)
            ctx.beginPath()
            ctx.moveTo(x0, height)
            pts.forEach((v, i) => ctx.lineTo(x0 + i * step, y(v)))
            ctx.lineTo(width, height)
            ctx.closePath()
            ctx.fillStyle = Theme.alpha(spark.accent, 0.16)
            ctx.fill()
            ctx.beginPath()
            pts.forEach((v, i) => i ? ctx.lineTo(x0 + i * step, y(v)) : ctx.moveTo(x0, y(v)))
            ctx.strokeStyle = spark.accent
            ctx.lineWidth = 1.6
            ctx.stroke()
        }
        Connections {
            target: spark
            function onHistoryChanged() { canvas.requestPaint() }
            function onAccentChanged() { canvas.requestPaint() }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }
}
