import QtQuick

import "."

// CarPlay gauge: a thick arc over a dim track with optional speedometer ticks.
// The open side faces down; children sit centred inside the dial.
Item {
    id: arc
    property real value: 0              // 0…1
    property real sweep: 270            // degrees
    property real thickness: 10
    property int ticks: 0               // minor ticks outside the arc; every fifth is major
    property color accent: F1Hub.accent
    property color track: F1Hub.track
    default property alias content: centre.data

    implicitWidth: 140
    implicitHeight: 140

    // Passive telemetry: settles without bounce, jumps under reduced motion.
    property real shown: Math.max(0, Math.min(1, value))
    Behavior on shown {
        enabled: !Motion.reduced
        SpringAnimation { spring: 3; damping: 1.0; epsilon: 0.001 }
    }
    onShownChanged: dial.requestPaint()
    onAccentChanged: dial.requestPaint()
    onTrackChanged: dial.requestPaint()

    readonly property real size: Math.min(width, height)
    readonly property real tickRoom: ticks > 0 ? Math.max(8, thickness * 0.8) : 0
    readonly property real radius: size / 2 - thickness / 2 - tickRoom - 2

    Canvas {
        id: dial
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2, cy = height / 2, r = arc.radius
            if (r <= 0) return
            const rad = Math.PI / 180
            const a0 = (90 + (360 - arc.sweep) / 2) * rad, span = arc.sweep * rad
            const v = arc.shown, a1 = a0 + span * v

            ctx.lineCap = "butt"
            ctx.lineWidth = arc.thickness
            ctx.strokeStyle = arc.track
            ctx.beginPath(); ctx.arc(cx, cy, r, a0, a0 + span); ctx.stroke()

            if (v > 0.001) {
                ctx.globalAlpha = 0.22
                ctx.lineWidth = arc.thickness + 8
                ctx.strokeStyle = arc.accent
                ctx.beginPath(); ctx.arc(cx, cy, r, a0, a1); ctx.stroke()

                ctx.globalAlpha = 1
                ctx.lineWidth = arc.thickness
                ctx.beginPath(); ctx.arc(cx, cy, r, a0, a1); ctx.stroke()

                // Bright leading edge, like a needle riding the arc.
                ctx.strokeStyle = "#ffffff"
                ctx.lineWidth = 2
                const ri = r - arc.thickness / 2, ro = r + arc.thickness / 2
                ctx.beginPath()
                ctx.moveTo(cx + ri * Math.cos(a1), cy + ri * Math.sin(a1))
                ctx.lineTo(cx + ro * Math.cos(a1), cy + ro * Math.sin(a1))
                ctx.stroke()
            }

            if (arc.ticks > 0) {
                const base = r + arc.thickness / 2 + 3
                for (let i = 0; i <= arc.ticks; i++) {
                    const t = i / arc.ticks, a = a0 + span * t, major = i % 5 === 0
                    ctx.strokeStyle = t <= v ? Qt.rgba(arc.accent.r, arc.accent.g, arc.accent.b, major ? 1 : 0.7)
                                             : Qt.rgba(1, 1, 1, major ? 0.45 : 0.18)
                    ctx.lineWidth = major ? 2 : 1
                    const len = major ? arc.tickRoom : arc.tickRoom * 0.55
                    ctx.beginPath()
                    ctx.moveTo(cx + base * Math.cos(a), cy + base * Math.sin(a))
                    ctx.lineTo(cx + (base + len) * Math.cos(a), cy + (base + len) * Math.sin(a))
                    ctx.stroke()
                }
            }
        }
    }

    Item { id: centre; anchors.fill: parent }
}
