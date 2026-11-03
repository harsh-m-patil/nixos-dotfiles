import QtQuick
import QtQuick.Layouts

import "."

// Daily cost or stacked token usage (T3 Code Usage-style area chart).
Rectangle {
    id: root

    property var days: []
    property string metric: "cost"
    property string title: metric === "cost" ? "Daily cost" : "Daily tokens"
    property int chartHeight: 168
    property int yAxisWidth: 36

    readonly property int count: days.length
    readonly property real yMax: {
        let m = 0
        for (let i = 0; i < days.length; i++) {
            const d = days[i]
            if (!d)
                continue
            if (metric === "cost")
                m = Math.max(m, d.costUsd || 0)
            else
                m = Math.max(m, d.totalTokens || 0)
        }
        return Math.max(m * 1.08, metric === "cost" ? 0.01 : 1)
    }

    Layout.fillWidth: true
    implicitHeight: chartHeight
    radius: F1Hub.tileRadius
    color: F1Hub.fill

    Text {
        id: heading
        x: 10
        y: 8
        text: root.title
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.weight: Font.DemiBold
    }

    Item {
        id: plot
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: heading.bottom
        anchors.bottom: parent.bottom
        anchors.margins: 8
        anchors.leftMargin: root.yAxisWidth + 8
        anchors.rightMargin: 8
        clip: true

        Repeater {
            model: 4
            Rectangle {
                required property int index
                y: Math.round(plot.height * index / 3)
                width: plot.width
                height: 1
                color: Theme.highlightLow
            }
        }

        Canvas {
            id: canvas
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const n = root.count
                if (n < 1)
                    return
                const w = width
                const h = height
                const pad = 2
                const step = n > 1 ? (w - pad * 2) / (n - 1) : 0
                const peak = root.yMax
                const xAt = i => pad + i * step
                const yAt = v => h - pad - (h - pad * 2) * Math.min(1, Math.max(0, v / peak))

                if (root.metric === "cost") {
                    const pts = []
                    for (let i = 0; i < n; i++)
                        pts.push([xAt(i), yAt(days[i].costUsd || 0)])
                    ctx.beginPath()
                    ctx.moveTo(pts[0][0], h)
                    for (const p of pts)
                        ctx.lineTo(p[0], p[1])
                    ctx.lineTo(pts[pts.length - 1][0], h)
                    ctx.closePath()
                    ctx.fillStyle = Qt.rgba(Theme.gold.r, Theme.gold.g, Theme.gold.b, 0.18)
                    ctx.fill()
                    ctx.beginPath()
                    ctx.moveTo(pts[0][0], pts[0][1])
                    for (let i = 1; i < pts.length; i++)
                        ctx.lineTo(pts[i][0], pts[i][1])
                    ctx.lineWidth = 1.5
                    ctx.strokeStyle = Theme.gold
                    ctx.stroke()
                    return
                }

                const layers = [
                    { key: "cacheReadTokens", color: Theme.subtle },
                    { key: "inputTokens", color: Theme.iris },
                    { key: "outputTokens", color: Theme.foreground },
                ]
                let bases = new Array(n).fill(0)
                for (let li = 0; li < layers.length; li++) {
                    const layer = layers[li]
                    const tops = []
                    for (let i = 0; i < n; i++) {
                        const add = days[i][layer.key] || 0
                        bases[i] += add
                        tops.push(yAt(bases[i]))
                    }
                    const prevTops = []
                    for (let i = 0; i < n; i++) {
                        const prev = bases[i] - (days[i][layer.key] || 0)
                        prevTops.push(yAt(prev))
                    }
                    ctx.beginPath()
                    ctx.moveTo(xAt(0), prevTops[0])
                    for (let i = 0; i < n; i++)
                        ctx.lineTo(xAt(i), tops[i])
                    for (let i = n - 1; i >= 0; i--)
                        ctx.lineTo(xAt(i), prevTops[i])
                    ctx.closePath()
                    const c = Qt.color(layer.color)
                    ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, li === 0 ? 0.35 : 0.55)
                    ctx.fill()
                }
            }
        }

        Connections {
            target: root
            function onDaysChanged() { canvas.requestPaint() }
            function onMetricChanged() { canvas.requestPaint() }
        }
    }

    Repeater {
        model: 4
        Text {
            required property int index
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.top: plot.top
            anchors.topMargin: plot.height * index / 3 - 6
            width: root.yAxisWidth
            horizontalAlignment: Text.AlignRight
            text: {
                const v = root.yMax * (1 - index / 3)
                return root.metric === "cost" ? Fmt.usd(v) : Fmt.tokens(v)
            }
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 8
        }
    }

    RowLayout {
        anchors.left: plot.left
        anchors.right: plot.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        spacing: 0

        Text {
            visible: root.count > 0 && root.days[0]
            text: root.count > 0 && root.days[0] ? Fmt.dayShort(root.days[0].day) : ""
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 8
        }
        Item { Layout.fillWidth: true }
        Text {
            visible: root.count > 2 && root.days[Math.floor((root.count - 1) / 2)]
            text: (root.count > 2 && root.days[Math.floor((root.count - 1) / 2)])
                ? Fmt.dayShort(root.days[Math.floor((root.count - 1) / 2)].day)
                : ""
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 8
        }
        Item { Layout.fillWidth: true }
        Text {
            visible: root.count > 1 && root.days[root.count - 1]
            text: (root.count > 1 && root.days[root.count - 1])
                ? Fmt.dayShort(root.days[root.count - 1].day)
                : ""
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 8
        }
    }
}
