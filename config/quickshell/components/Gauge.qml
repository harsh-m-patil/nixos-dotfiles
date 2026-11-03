import QtQuick
import QtQuick.Layouts

import "."

Rectangle {
    id: root

    property real value: 0
    property string text: Math.round(value * 100) + "%"
    property string label: ""
    property string sublabel: ""
    property color colorA: Theme.iris
    property color colorB: Theme.foam
    property bool warn: true

    readonly property color hot: value > 0.85 ? Theme.love : value > 0.7 ? Theme.gold : colorB

    Layout.fillWidth: true
    implicitHeight: 128
    radius: 14
    color: Theme.surface
    border.width: 1
    border.color: Theme.highlightLow

    property real shown: value
    Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    onShownChanged: ring.requestPaint()
    onHotChanged: ring.requestPaint()

    Canvas {
        id: ring
        width: 84
        height: 84
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2, cy = height / 2, r = width / 2 - 7
            const start = Math.PI * 0.75, sweep = Math.PI * 1.5
            ctx.lineCap = "round"

            ctx.lineWidth = 7
            ctx.strokeStyle = Theme.highlightLow
            ctx.beginPath()
            ctx.arc(cx, cy, r, start, start + sweep)
            ctx.stroke()

            const v = Math.max(0.002, Math.min(1, root.shown))
            const g = ctx.createLinearGradient(0, height, width, 0)
            g.addColorStop(0, root.colorA)
            g.addColorStop(1, root.warn ? root.hot : root.colorB)

            ctx.lineWidth = 12
            ctx.globalAlpha = 0.18
            ctx.strokeStyle = g
            ctx.beginPath()
            ctx.arc(cx, cy, r, start, start + sweep * v)
            ctx.stroke()

            ctx.globalAlpha = 1
            ctx.lineWidth = 7
            ctx.beginPath()
            ctx.arc(cx, cy, r, start, start + sweep * v)
            ctx.stroke()

            const ex = cx + r * Math.cos(start + sweep * v)
            const ey = cy + r * Math.sin(start + sweep * v)
            ctx.fillStyle = Theme.foreground
            ctx.beginPath()
            ctx.arc(ex, ey, 2.5, 0, Math.PI * 2)
            ctx.fill()
        }
    }

    Text {
        anchors.centerIn: ring
        anchors.verticalCenterOffset: -2
        text: root.text
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: 17
        font.weight: Font.Bold
    }

    Column {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.sublabel
            visible: text !== ""
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 9
        }
    }
}
