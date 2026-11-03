import QtQuick

import "."

Item {
    id: root

    property real value: 0
    property string style: "ring"
    property color accent: Theme.iris
    property string text: ""
    property string unit: ""
    property string caption: ""
    property string footer: ""
    property var scaleLabels: []
    property int ticks: 40
    property int majorEvery: 5
    property bool fullCircle: false

    readonly property real size: Math.min(width, height)
    readonly property real r: size / 2 - 4
    readonly property real a0: fullCircle ? -Math.PI / 2 : Math.PI * 0.75
    readonly property real span: fullCircle ? Math.PI * 2 : Math.PI * 1.5

    property real shown: Math.max(0, Math.min(1, value))
    Behavior on shown { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
    onShownChanged: canvas.requestPaint()
    onAccentChanged: canvas.requestPaint()
    onStyleChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.centerIn: parent
        width: root.size
        height: root.size
        antialiasing: true
        onWidthChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2, cy = height / 2, r = root.r
            const a0 = root.a0, span = root.span, v = root.shown
            const end = a0 + span * v
            const fg = Theme.foreground, ac = root.accent

            ctx.lineCap = "round"

            ctx.globalAlpha = 0.10
            ctx.fillStyle = fg
            ctx.beginPath()
            ctx.arc(cx, cy, r * 0.62, 0, Math.PI * 2)
            ctx.fill()

            if (root.style === "sweep") {
                ctx.globalAlpha = 1
                const g = ctx.createRadialGradient(cx, cy, r * 0.6, cx, cy, r)
                g.addColorStop(0, Qt.darker(ac, 1.35))
                g.addColorStop(1, ac)
                ctx.fillStyle = g
                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.97, a0, end)
                ctx.arc(cx, cy, r * 0.64, end, a0, true)
                ctx.closePath()
                ctx.fill()
            }

            for (let i = 0; i <= root.ticks; i++) {
                if (root.fullCircle && i === root.ticks)
                    break
                const t = i / root.ticks
                const a = a0 + span * t
                const major = i % root.majorEvery === 0
                const lit = t <= v
                ctx.globalAlpha = root.style === "sweep" ? (lit ? 0.55 : 0.35) : lit && root.style === "ring" ? 0.9 : major ? 0.55 : 0.22
                ctx.strokeStyle = root.style === "sweep" && lit ? "#000000" : root.style === "ring" && lit ? ac : fg
                ctx.lineWidth = major ? 2 : 1
                const ri = r * (major ? 0.76 : 0.8), ro = r * 0.86
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * ri, cy + Math.sin(a) * ri)
                ctx.lineTo(cx + Math.cos(a) * ro, cy + Math.sin(a) * ro)
                ctx.stroke()
            }

            if (root.style !== "sweep") {
                ctx.lineWidth = Math.max(3, r * 0.05)
                ctx.globalAlpha = 0.14
                ctx.strokeStyle = fg
                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.95, a0, a0 + span)
                ctx.stroke()
                if (v > 0.002) {
                    ctx.globalAlpha = 1
                    ctx.strokeStyle = ac
                    ctx.beginPath()
                    ctx.arc(cx, cy, r * 0.95, a0, end)
                    ctx.stroke()
                }
            }

            const n = root.scaleLabels.length
            if (n > 1) {
                ctx.globalAlpha = root.style === "sweep" ? 0.9 : 0.6
                ctx.fillStyle = fg
                ctx.font = "500 " + Math.max(8, Math.round(r * 0.085)) + "px Geist"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                for (let j = 0; j < n; j++) {
                    const a = a0 + span * j / (n - 1)
                    const lit = j / (n - 1) <= v
                    ctx.fillStyle = root.style === "sweep" && lit ? "#000000" : fg
                    ctx.fillText(root.scaleLabels[j], cx + Math.cos(a) * r * 0.7, cy + Math.sin(a) * r * 0.7)
                }
            }

            if (root.style === "needle") {
                ctx.globalAlpha = 1
                ctx.strokeStyle = ac
                ctx.lineWidth = Math.max(2, r * 0.03)
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(end) * r * 0.18, cy + Math.sin(end) * r * 0.18)
                ctx.lineTo(cx + Math.cos(end) * r * 0.88, cy + Math.sin(end) * r * 0.88)
                ctx.stroke()
                ctx.fillStyle = ac
                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.045, 0, Math.PI * 2)
                ctx.fill()
            }
        }
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.style === "needle" ? root.r * 0.3 : 0
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.caption !== ""
            text: root.caption
            color: root.accent
            font.family: Theme.displayFont
            font.pixelSize: Math.max(9, root.r * 0.1)
            font.weight: Font.Medium
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.text
            color: Theme.foreground
            font.family: Theme.displayFont
            readonly property real px: Math.max(14, root.r * (root.style === "needle" ? 0.24 : 0.36))
            font.pixelSize: px
            font.weight: Font.DemiBold
            font.letterSpacing: -px * 0.03
            font.features: { "tnum": 1 }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.unit !== ""
            text: root.unit
            color: Theme.subtle
            font.family: Theme.displayFont
            font.pixelSize: Math.max(9, root.r * 0.09)
        }
    }

    Text {
        visible: root.footer !== "" && !root.fullCircle
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 + root.r * 0.78
        text: root.footer
        color: Theme.foreground
        font.family: Theme.displayFont
        font.pixelSize: Math.max(9, root.r * 0.085)
        font.weight: Font.Medium
    }
}
