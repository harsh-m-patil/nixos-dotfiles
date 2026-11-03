import QtQuick

import "."

Canvas {
    id: root

    property var track: null
    property int pad: 14
    property bool showSectors: true
    property bool showStraights: true

    readonly property var sectorColours: [Theme.love, Theme.foam, Theme.gold]
    readonly property color straightColour: Theme.foam

    onTrackChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onShowSectorsChanged: requestPaint()
    onShowStraightsChanged: requestPaint()

    function project(t) {
        const a = (t.rotation ?? 0) * Math.PI / 180
        const rot = (x, y) => [x * Math.cos(a) - y * Math.sin(a), -(x * Math.sin(a) + y * Math.cos(a))]
        const pts = t.x.map((x, i) => rot(x, t.y[i]))
        const corners = (t.corners ?? []).map(c => ({ n: c.number, p: rot(c.trackPosition.x, c.trackPosition.y) }))
        const xs = pts.map(p => p[0]), ys = pts.map(p => p[1])
        const minX = Math.min(...xs), maxX = Math.max(...xs), minY = Math.min(...ys), maxY = Math.max(...ys)
        const s = Math.min((width - pad * 2) / (maxX - minX), (height - pad * 2) / (maxY - minY))
        const ox = (width - (maxX - minX) * s) / 2, oy = (height - (maxY - minY) * s) / 2
        const map = p => [ox + (p[0] - minX) * s, oy + (p[1] - minY) * s]
        return { pts: pts.map(map), corners: corners.map(c => ({ n: c.n, p: map(c.p) })) }
    }

    function path(ctx, pts, from, to, close) {
        ctx.beginPath()
        ctx.moveTo(pts[from][0], pts[from][1])
        for (let i = from + 1; i <= to; i++) ctx.lineTo(pts[i][0], pts[i][1])
        if (close) ctx.lineTo(pts[0][0], pts[0][1])
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        if (!track || !track.x || track.x.length < 2) return
        const { pts, corners } = project(track)
        const last = pts.length - 1

        ctx.lineJoin = "round"
        ctx.lineCap = "round"

        path(ctx, pts, 0, last, true)
        ctx.strokeStyle = Qt.rgba(Theme.iris.r, Theme.iris.g, Theme.iris.b, 0.08)
        ctx.lineWidth = 16
        ctx.stroke()
        ctx.strokeStyle = Theme.highlightMed
        ctx.lineWidth = 8
        ctx.stroke()

        const [b1, b2] = track.sectors ?? [0, 0]
        if (showSectors && b1 > 0 && b2 > b1) {
            const ranges = [[0, b1, false], [b1, b2, false], [b2, last, true]]
            ranges.forEach(([f, t, close], i) => {
                path(ctx, pts, f, t, close)
                ctx.strokeStyle = sectorColours[i]
                ctx.lineWidth = 3
                ctx.stroke()
            })
        } else {
            path(ctx, pts, 0, last, true)
            ctx.strokeStyle = Theme.iris
            ctx.lineWidth = 3
            ctx.stroke()
        }

        if (showStraights) {
            for (const [f, t] of track.straights ?? []) {
                path(ctx, pts, f, t, false)
                ctx.strokeStyle = Qt.rgba(0.49, 0.9, 0.53, 0.28)
                ctx.lineWidth = 12
                ctx.stroke()
                ctx.strokeStyle = straightColour
                ctx.lineWidth = 1.5
                ctx.setLineDash([3, 4])
                ctx.stroke()
                ctx.setLineDash([])
            }
        }

        // Sector boundaries
        if (showSectors && b1 > 0) {
            ctx.font = "bold 9px '" + Theme.fontFamily + "'"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ;[[0, "S1"], [b1, "S2"], [b2, "S3"]].forEach(([i, label], k) => {
                const p = pts[i], q = pts[Math.min(i + 3, last)]
                const ang = Math.atan2(q[1] - p[1], q[0] - p[0]) + Math.PI / 2
                ctx.strokeStyle = Theme.foreground
                ctx.lineWidth = 2
                ctx.beginPath()
                ctx.moveTo(p[0] - Math.cos(ang) * 7, p[1] - Math.sin(ang) * 7)
                ctx.lineTo(p[0] + Math.cos(ang) * 7, p[1] + Math.sin(ang) * 7)
                ctx.stroke()
                const lx = p[0] + Math.cos(ang) * 18, ly = p[1] + Math.sin(ang) * 18
                ctx.fillStyle = sectorColours[k]
                ctx.beginPath()
                ctx.roundedRect(lx - 10, ly - 6.5, 20, 13, 4, 4)
                ctx.fill()
                ctx.fillStyle = Theme.background
                ctx.fillText(label, lx, ly)
            })
        }

        ctx.font = "bold 8px '" + Theme.fontFamily + "'"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        for (const c of corners) {
            ctx.fillStyle = Theme.surface
            ctx.beginPath()
            ctx.arc(c.p[0], c.p[1], 6, 0, Math.PI * 2)
            ctx.fill()
            ctx.fillStyle = Theme.subtle
            ctx.fillText(c.n, c.p[0], c.p[1])
        }
    }
}
