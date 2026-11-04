import QtQuick

import "."

// A CarPlay-style mini fuel dial: dark disc with a filled pie wedge for what's left (0…1),
// percentage in the middle, E and F at the foot. Below `reserve` the wedge turns red.
Item {
    id: fuel
    property real value: 1
    property string label
    property string readout: Math.round(value * 100) + "%"
    property string sub
    property real reserve: 0.15
    property color accent: Theme.iris
    property bool exceeded: false       // e.g. included spend past cap — empty dial, semantic warning colour

    property real anim: value
    Behavior on anim {
        enabled: !Motion.reduced
        SpringAnimation {
            spring: Motion.gaugeSpring
            damping: Motion.gaugeDamping
            epsilon: 0.001
        }
    }
    onValueChanged: if (Motion.reduced) anim = value
    onAnimChanged: dial.requestPaint()
    onAccentChanged: dial.requestPaint()

    readonly property bool low: exceeded || value <= reserve
    readonly property color tone: exceeded ? Theme.love : low ? Theme.love : value <= 0.35 ? Theme.gold : accent
    onToneChanged: dial.requestPaint()
    implicitWidth: 150
    implicitHeight: 104

    readonly property real r_: Math.max(0, Math.min(width / 2 - 4, (height - 30) / 2))
    readonly property real cy_: r_ + 2

    Canvas {
        id: dial
        anchors.fill: parent
        antialiasing: true
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const R = fuel.r_, cx = width / 2, cy = fuel.cy_
            const a0 = Math.PI * 3 / 4, sweep = Math.PI * 3 / 2
            const at = v => a0 + sweep * Math.max(0, Math.min(1, v))

            ctx.fillStyle = "#000000"
            ctx.beginPath(); ctx.arc(cx, cy, R, 0, Math.PI * 2); ctx.fill()
            ctx.fillStyle = Theme.alpha(Theme.foreground, 0.07)
            ctx.beginPath(); ctx.moveTo(cx, cy); ctx.arc(cx, cy, R - 2, at(0), at(1)); ctx.closePath(); ctx.fill()

            if (fuel.anim > 0.002) {
                const g = ctx.createLinearGradient(cx - R, cy + R, cx + R, cy - R)
                g.addColorStop(0, Theme.alpha(fuel.tone, 0.35))
                g.addColorStop(1, Theme.alpha(fuel.tone, 0.9))
                ctx.fillStyle = g
                ctx.beginPath(); ctx.moveTo(cx, cy); ctx.arc(cx, cy, R - 2, at(0), at(fuel.anim)); ctx.closePath(); ctx.fill()
            }

            // Hub so the readout sits on black
            ctx.fillStyle = "#000000"
            ctx.beginPath(); ctx.arc(cx, cy, R * 0.52, 0, Math.PI * 2); ctx.fill()
        }
    }

    component Mark: Text {
        color: F1Hub.ink3
        font.family: Theme.displayFont
        font.pixelSize: 8
        font.weight: Font.DemiBold
    }
    Mark { x: fuel.width / 2 - fuel.r_ * 0.55 - width / 2; y: fuel.cy_ + fuel.r_ * 0.55; text: "E"; color: fuel.low ? Theme.love : F1Hub.ink3 }
    Mark { x: fuel.width / 2 + fuel.r_ * 0.55 - width / 2; y: fuel.cy_ + fuel.r_ * 0.55; text: "F" }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: fuel.cy_ - height / 2
        text: fuel.readout
        color: fuel.low ? Theme.love : "#ffffff"
        font.family: Theme.displayFont
        font.pixelSize: Math.max(11, Math.round(fuel.r_ * 0.36))
        font.weight: Font.Bold
        font.letterSpacing: -0.3
        font.features: { "tnum": 1 }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: fuel.cy_ + fuel.r_ + 3
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, fuel.width)
            horizontalAlignment: Text.AlignHCenter
            text: fuel.label
            color: "#ffffff"
            font.family: Theme.displayFont
            font.pixelSize: 10
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: fuel.sub !== ""
            text: fuel.sub
            color: F1Hub.ink3
            font.family: Theme.displayFont
            font.pixelSize: 9
        }
    }
}
