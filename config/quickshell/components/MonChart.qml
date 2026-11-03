import QtQuick
import QtQuick.Layouts

import "."

Rectangle {
    id: root

    // [{ values: [...], color: "#..." }, ...]; mirrored draws series[1] downward
    property var series: []
    property real maxValue: 0
    property real floorValue: 1
    property int capacity: SystemData.historySize
    property bool mirrored: false
    property string topLabel: ""
    property bool framed: true

    readonly property real peak: {
        if (maxValue > 0)
            return maxValue
        let m = floorValue
        for (const s of series)
            for (const v of s.values ?? [])
                if (v > m)
                    m = v
        return m * 1.15
    }
    readonly property real step: plot.width / (capacity - 2)

    Layout.fillWidth: true
    implicitHeight: 90
    radius: 6
    color: framed ? Theme.background : "transparent"
    border.width: framed ? 1 : 0
    border.color: Theme.highlightLow

    property bool pending: false
    onSeriesChanged: { pending = true; canvas.requestPaint() }

    Item {
        id: plot
        anchors.fill: parent
        anchors.margins: 1
        clip: true

        Repeater {
            model: !root.framed ? [] : root.mirrored ? [0.5] : [0.25, 0.5, 0.75]
            Rectangle {
                required property real modelData
                y: Math.round(plot.height * modelData)
                width: plot.width
                height: 1
                color: root.mirrored ? Theme.highlightMed : Theme.highlightLow
            }
        }

        Canvas {
            id: canvas
            width: plot.width
            height: plot.height
            renderStrategy: Canvas.Cooperative
            transform: Translate { id: shift }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            NumberAnimation {
                id: slide
                target: shift
                property: "x"
                to: 0
                duration: 450
                easing.type: Easing.OutCubic
            }

            onPainted: {
                if (!root.pending)
                    return
                root.pending = false
                shift.x = root.step
                slide.restart()
            }

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const w = width, h = height, pad = 2
                const step = root.step

                for (let s = 0; s < root.series.length; s++) {
                    const ser = root.series[s]
                    const vals = ser.values ?? []
                    if (vals.length < 2)
                        continue
                    const c = Qt.color(ser.color)
                    const down = root.mirrored && s === 1
                    const base = root.mirrored ? h / 2 : h
                    const amp = root.mirrored ? h / 2 - pad : h - pad * 2
                    const pts = vals.map((v, i) => [
                        w - (vals.length - 1 - i) * step,
                        base + (down ? 1 : -1) * amp * Math.min(1, Math.max(0, v) / root.peak)
                    ])

                    ctx.beginPath()
                    ctx.moveTo(pts[0][0], base)
                    for (const p of pts)
                        ctx.lineTo(p[0], p[1])
                    ctx.lineTo(pts[pts.length - 1][0], base)
                    ctx.closePath()
                    ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, 0.12)
                    ctx.fill()

                    ctx.beginPath()
                    ctx.moveTo(pts[0][0], pts[0][1])
                    for (let i = 1; i < pts.length; i++)
                        ctx.lineTo(pts[i][0], pts[i][1])
                    ctx.lineWidth = 1.5
                    ctx.lineJoin = "round"
                    ctx.strokeStyle = c
                    ctx.stroke()
                }
            }
        }

        Text {
            visible: root.topLabel !== ""
            x: 6
            y: 4
            text: root.topLabel
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 9
        }
    }
}
