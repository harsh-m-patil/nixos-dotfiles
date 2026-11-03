import QtQuick

import "."

// A dashboard dial: 240° sweep with major/minor ticks and a redline zone, digital readout in the hub.
Item {
    id: gauge
    property real value: 0              // 0…1
    property string label
    property string readout: Math.round(value * 100) + ""
    property string unit: "%"
    property string sub
    property real redline: 0.85
    property color accent: Theme.foam

    property real anim: value
    Behavior on anim { SpringAnimation { spring: 2.6; damping: 0.32; epsilon: 0.002 } }
    onAnimChanged: dial.requestPaint()
    onAccentChanged: dial.requestPaint()

    readonly property bool hot: value >= redline
    implicitWidth: 168
    implicitHeight: 150

    Canvas {
        id: dial
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2, cy = height * 0.56
            const r = Math.min(width / 2, height * 0.56) - 6
            const a0 = Math.PI * 5 / 6, sweep = Math.PI * 4 / 3
            const at = v => a0 + sweep * Math.max(0, Math.min(1, v))
            const v = gauge.anim

            // Track and redline zone
            ctx.lineCap = "round"
            ctx.lineWidth = 6
            ctx.strokeStyle = Theme.alpha(Theme.foreground, 0.07)
            ctx.beginPath(); ctx.arc(cx, cy, r, at(0), at(1)); ctx.stroke()
            ctx.lineCap = "butt"
            ctx.lineWidth = 3
            ctx.strokeStyle = Theme.alpha(Theme.love, 0.55)
            ctx.beginPath(); ctx.arc(cx, cy, r + 6, at(gauge.redline), at(1)); ctx.stroke()

            // Ticks
            for (let i = 0; i <= 50; i++) {
                const t = i / 50, major = i % 10 === 0
                const a = at(t), len = major ? 9 : 4
                const lit = t <= v + 1e-6
                ctx.strokeStyle = t >= gauge.redline ? Theme.alpha(Theme.love, lit ? 1 : 0.45)
                    : lit ? Theme.alpha(gauge.accent, major ? 1 : 0.8) : Theme.alpha(Theme.foreground, major ? 0.3 : 0.12)
                ctx.lineWidth = major ? 2 : 1.2
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * (r - 10), cy + Math.sin(a) * (r - 10))
                ctx.lineTo(cx + Math.cos(a) * (r - 10 - len), cy + Math.sin(a) * (r - 10 - len))
                ctx.stroke()
            }

            // Value arc with glow
            const col = gauge.hot ? Theme.love : gauge.accent
            ctx.lineCap = "round"
            ctx.lineWidth = 12
            ctx.strokeStyle = Theme.alpha(col, 0.16)
            ctx.beginPath(); ctx.arc(cx, cy, r, at(0), at(v)); ctx.stroke()
            ctx.lineWidth = 5
            ctx.strokeStyle = col
            ctx.beginPath(); ctx.arc(cx, cy, r, at(0), at(v)); ctx.stroke()

            // Needle tip
            const tip = at(v)
            ctx.fillStyle = Theme.foreground
            ctx.beginPath(); ctx.arc(cx + Math.cos(tip) * r, cy + Math.sin(tip) * r, 3.2, 0, Math.PI * 2); ctx.fill()
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.56 - height / 2 - 2
        spacing: 0
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 1
            Text {
                text: gauge.readout
                color: gauge.hot ? Theme.love : F1Hub.ink
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(18, Math.min(30, gauge.width * 0.18))
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
            }
            Text {
                anchors.baseline: parent.children[0].baseline
                text: gauge.unit
                color: F1Hub.ink3
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: gauge.label.toUpperCase()
            color: gauge.hot ? Theme.love : gauge.accent
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 2
        }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        text: gauge.sub
        visible: text !== ""
        color: F1Hub.ink2
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.features: { "tnum": 1 }
    }
}
