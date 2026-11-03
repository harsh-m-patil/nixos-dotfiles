import QtQuick

import "."

Canvas {
    id: root

    property var values: []
    property real maxValue: 0
    property real floorValue: 0
    property color accent: Theme.gold
    property int count: 48

    readonly property real peak: {
        if (maxValue > 0)
            return maxValue
        let m = floorValue
        for (const v of values)
            m = Math.max(m, v)
        return m || 1
    }

    implicitHeight: 40
    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onAccentChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const n = count, vs = values.slice(-n)
        const step = width / n, bw = Math.max(1.5, step * 0.45)
        for (let i = 0; i < n; i++) {
            const v = vs[i - (n - vs.length)] ?? 0
            const f = Math.max(0, Math.min(1, v / peak))
            const h = Math.max(3, f * height)
            ctx.globalAlpha = f > 0.01 ? 0.35 + 0.65 * (i / n) : 0.15
            ctx.fillStyle = f > 0.01 ? accent : Theme.foreground
            ctx.fillRect(i * step + (step - bw) / 2, height - h, bw, h)
        }
    }
}
