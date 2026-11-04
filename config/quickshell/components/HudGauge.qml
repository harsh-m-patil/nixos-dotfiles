import QtQuick

import "."

// A CarPlay-style dial: black face, thick filled sweep with numerals, bold hub readout,
// and a footer line cradled by a white arc.
Item {
    id: gauge
    property real value: 0              // 0…1
    property string label
    property string readout: Math.round(value * 100) + ""
    property string unit: "%"
    property string sub
    property real redline: 0.85
    property color accent: Theme.foam
    property var numerals: ["0", "20", "40", "60", "80", "100"]   // spread evenly along the band
    onNumeralsChanged: dial.requestPaint()

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

    readonly property bool hot: value >= redline
    onHotChanged: dial.requestPaint()
    implicitWidth: 168
    implicitHeight: 150

    readonly property real cx_: width / 2
    readonly property real cy_: height / 2
    readonly property real r_: Math.min(width, height) / 2 - 2

    Canvas {
        id: dial
        anchors.fill: parent
        antialiasing: true
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = gauge.cx_, cy = gauge.cy_, R = gauge.r_
            const a0 = Math.PI * 3 / 4, sweep = Math.PI * 3 / 2
            const at = v => a0 + sweep * Math.max(0, Math.min(1, v))
            const pt = (a, rr) => [cx + Math.cos(a) * rr, cy + Math.sin(a) * rr]
            const v = gauge.anim
            const col = gauge.hot ? Theme.love : gauge.accent
            const band = R * 0.3, rIn = R - band

            // Face
            ctx.fillStyle = "#000000"
            ctx.beginPath(); ctx.arc(cx, cy, R, 0, Math.PI * 2); ctx.fill()

            // Band: dim track, filled sweep, redline tint
            ctx.fillStyle = Theme.alpha(Theme.foreground, 0.06)
            ctx.beginPath(); ctx.arc(cx, cy, R - 3, at(0), at(1)); ctx.arc(cx, cy, rIn, at(1), at(0), true); ctx.closePath(); ctx.fill()
            ctx.fillStyle = Theme.alpha(Theme.love, 0.22)
            ctx.beginPath(); ctx.arc(cx, cy, R - 3, at(gauge.redline), at(1)); ctx.arc(cx, cy, rIn, at(1), at(gauge.redline), true); ctx.closePath(); ctx.fill()
            if (v > 0.002) {
                ctx.fillStyle = col
                ctx.beginPath(); ctx.arc(cx, cy, R - 3, at(0), at(v)); ctx.arc(cx, cy, rIn, at(v), at(0), true); ctx.closePath(); ctx.fill()
            }

            // Fine ticks along the outer edge
            for (let i = 0; i <= 50; i++) {
                const t = i / 50, major = i % 10 === 0
                const a = at(t)
                const [x1, y1] = pt(a, R - 4), [x2, y2] = pt(a, R - (major ? 10 : 7))
                ctx.strokeStyle = t <= v ? Theme.alpha("#000000", 0.45) : Theme.alpha(Theme.foreground, major ? 0.5 : 0.22)
                ctx.lineWidth = major ? 1.5 : 1
                ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke()
            }

            // Numerals inside the band
            ctx.font = "600 " + Math.round(R * 0.11) + "px '" + Theme.displayFont + "'"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            const n = gauge.numerals.length
            for (let i = 0; i < n && n > 1; i++) {
                const t = i / (n - 1)
                const [x, y] = pt(at(t), rIn + band * 0.42)
                ctx.fillStyle = t <= v ? Theme.alpha("#000000", 0.75) : Theme.alpha(Theme.foreground, 0.6)
                ctx.fillText(String(gauge.numerals[i]), x, y)
            }

            // Edge of the sweep
            const [e1x, e1y] = pt(at(v), rIn), [e2x, e2y] = pt(at(v), R - 3)
            ctx.strokeStyle = Theme.foreground
            ctx.lineWidth = 2
            ctx.beginPath(); ctx.moveTo(e1x, e1y); ctx.lineTo(e2x, e2y); ctx.stroke()

            // White cradle arc under the footer
            ctx.strokeStyle = Theme.alpha(Theme.foreground, 0.85)
            ctx.lineWidth = 2
            ctx.lineCap = "round"
            ctx.beginPath(); ctx.arc(cx, cy, R + 0.5, Math.PI * 0.32, Math.PI * 0.68); ctx.stroke()
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: gauge.cy_ - height / 2 - 2
        spacing: -3
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: gauge.r_ * 1.3
            horizontalAlignment: Text.AlignHCenter
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 11
            text: gauge.readout
            color: gauge.hot ? Theme.love : "#ffffff"
            font.family: Theme.displayFont
            font.pixelSize: Math.round(gauge.r_ * 0.42)
            font.weight: Font.Bold
            font.letterSpacing: -1
            font.features: { "tnum": 1 }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: gauge.label !== "" ? gauge.label : gauge.unit
            color: gauge.hot ? Theme.love : F1Hub.ink2
            font.family: Theme.displayFont
            font.pixelSize: 10
            font.weight: Font.Medium
        }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: gauge.cy_ + gauge.r_ * 0.62
        text: gauge.sub
        visible: text !== ""
        color: "#ffffff"
        font.family: Theme.displayFont
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
    }
}
