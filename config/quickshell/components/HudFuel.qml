import QtQuick

import "."

// A fuel gauge: half-dial from E to F with a swinging needle. `value` is what's left (0…1);
// the reserve zone below `reserve` reads red.
Item {
    id: fuel
    property real value: 1
    property string label
    property string readout: Math.round(value * 100) + "%"
    property string sub
    property real reserve: 0.15
    property color accent: Theme.iris

    property real anim: value
    Behavior on anim { SpringAnimation { spring: 2.2; damping: 0.28; epsilon: 0.002 } }
    onAnimChanged: dial.requestPaint()
    onAccentChanged: dial.requestPaint()

    readonly property bool low: value <= reserve
    readonly property color tone: low ? Theme.love : value <= 0.35 ? Theme.gold : accent
    onToneChanged: dial.requestPaint()
    implicitWidth: 150
    implicitHeight: 104

    Canvas {
        id: dial
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const r = Math.min(width / 2 - 8, height - 56)
            const cx = width / 2, cy = r + 10
            const at = v => Math.PI + Math.PI * Math.max(0, Math.min(1, v))

            // Band: reserve in red, the rest dim
            ctx.lineWidth = 7
            ctx.strokeStyle = Theme.alpha(Theme.foreground, 0.07)
            ctx.beginPath(); ctx.arc(cx, cy, r, at(fuel.reserve), at(1)); ctx.stroke()
            ctx.strokeStyle = Theme.alpha(Theme.love, 0.45)
            ctx.beginPath(); ctx.arc(cx, cy, r, at(0), at(fuel.reserve)); ctx.stroke()
            ctx.strokeStyle = Theme.alpha(fuel.tone, 0.85)
            ctx.beginPath(); ctx.arc(cx, cy, r, at(Math.max(fuel.reserve, 0)), at(Math.max(fuel.reserve, fuel.anim))); ctx.stroke()

            // Quarter ticks
            for (let i = 0; i <= 4; i++) {
                const a = at(i / 4)
                ctx.strokeStyle = Theme.alpha(Theme.foreground, i % 2 ? 0.25 : 0.5)
                ctx.lineWidth = 2
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * (r - 7), cy + Math.sin(a) * (r - 7))
                ctx.lineTo(cx + Math.cos(a) * (r - (i % 2 ? 11 : 14)), cy + Math.sin(a) * (r - (i % 2 ? 11 : 14)))
                ctx.stroke()
            }

            // Needle
            const a = at(fuel.anim)
            ctx.strokeStyle = Theme.alpha(fuel.tone, 0.25)
            ctx.lineWidth = 6
            ctx.lineCap = "round"
            ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(cx + Math.cos(a) * (r - 4), cy + Math.sin(a) * (r - 4)); ctx.stroke()
            ctx.strokeStyle = Theme.foreground
            ctx.lineWidth = 2
            ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(cx + Math.cos(a) * (r - 4), cy + Math.sin(a) * (r - 4)); ctx.stroke()
            ctx.fillStyle = Theme.foreground
            ctx.beginPath(); ctx.arc(cx, cy, 4, 0, Math.PI * 2); ctx.fill()
        }
    }

    component Mark: Text {
        color: F1Hub.ink3
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.weight: Font.Bold
    }
    readonly property real r_: Math.min(width / 2 - 8, height - 56)
    Mark { x: fuel.width / 2 - fuel.r_ - 4; y: fuel.r_ + 14; text: "E"; color: fuel.low ? Theme.love : F1Hub.ink3 }
    Mark { x: fuel.width / 2 + fuel.r_ - 3; y: fuel.r_ + 14; text: "F" }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: fuel.r_ + 14
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: fuel.readout
            color: fuel.low ? Theme.love : F1Hub.ink
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, fuel.width)
            text: fuel.label.toUpperCase()
            color: fuel.tone
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 1.4
            elide: Text.ElideRight
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: fuel.sub !== ""
            text: fuel.sub
            color: F1Hub.ink3
            font.family: Theme.fontFamily
            font.pixelSize: 9
        }
    }
}
