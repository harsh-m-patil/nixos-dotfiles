import QtQuick

import "."

Canvas {
    id: root

    property var track: null
    property int pad: 24
    property bool showSectors: true

    // Fixed broadcast-style colours; team themes can wash the palette colours into near-identical greys.
    readonly property var sectorColours: ["#e8475f", "#3fa9f5", "#f5c542"]

    onTrackChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onShowSectorsChanged: requestPaint()

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
        const out = pts.map(map)
        return { pts: out, corners: corners.map(c => placeBadge(out, c.n, map(c.p))) }
    }

    // Unit direction of travel at index i.
    function heading(pts, i) {
        const n = pts.length, a = pts[(i - 2 + n) % n], b = pts[(i + 2) % n]
        const len = Math.hypot(b[0] - a[0], b[1] - a[1]) || 1
        return [(b[0] - a[0]) / len, (b[1] - a[1]) / len]
    }

    function clearance(pts, x, y) {
        let d = Infinity
        for (let i = 0; i < pts.length; i += 2) d = Math.min(d, Math.hypot(pts[i][0] - x, pts[i][1] - y))
        return d
    }

    // Push the turn badge off the racing line, to whichever side has more room.
    function placeBadge(pts, n, p) {
        let best = 0, bd = Infinity
        pts.forEach((q, i) => { const d = Math.hypot(q[0] - p[0], q[1] - p[1]); if (d < bd) { bd = d; best = i } })
        const [hx, hy] = heading(pts, best), base = pts[best]
        const off = 14
        const sides = [[-hy, hx], [hy, -hx]].map(([nx, ny]) => {
            const x = base[0] + nx * off, y = base[1] + ny * off
            return { x, y, room: clearance(pts, x, y) }
        })
        const s = sides[0].room >= sides[1].room ? sides[0] : sides[1]
        return { n, track: base, p: [s.x, s.y] }
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

        // Direction chevrons, spaced by on-screen distance.
        ctx.strokeStyle = Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.55)
        ctx.lineWidth = 1.5
        let run = 0
        for (let i = 1; i < pts.length; i++) {
            run += Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1])
            if (run < 60 || i < 8) continue
            run = 0
            const [hx, hy] = heading(pts, i), [x, y] = pts[i]
            ctx.beginPath()
            ctx.moveTo(x - hx * 3 - hy * 3, y - hy * 3 + hx * 3)
            ctx.lineTo(x + hx * 1.5, y + hy * 1.5)
            ctx.lineTo(x - hx * 3 + hy * 3, y - hy * 3 - hx * 3)
            ctx.stroke()
        }

        // Chequered start/finish line plus a direction arrow.
        {
            const [hx, hy] = heading(pts, 0), [x, y] = pts[0]
            const nx = -hy, ny = hx, cell = 2.5
            for (let r = 0; r < 2; r++)
                for (let k = -3; k < 3; k++) {
                    ctx.fillStyle = (r + k) % 2 === 0 ? "#ffffff" : "#111111"
                    const cx = x + nx * (k + 0.5) * cell + hx * (r - 0.5) * cell
                    const cy = y + ny * (k + 0.5) * cell + hy * (r - 0.5) * cell
                    ctx.beginPath()
                    ctx.moveTo(cx + (nx + hx) * cell / 2, cy + (ny + hy) * cell / 2)
                    ctx.lineTo(cx + (nx - hx) * cell / 2, cy + (ny - hy) * cell / 2)
                    ctx.lineTo(cx - (nx + hx) * cell / 2, cy - (ny + hy) * cell / 2)
                    ctx.lineTo(cx - (nx - hx) * cell / 2, cy - (ny - hy) * cell / 2)
                    ctx.closePath()
                    ctx.fill()
                }
            const ax = x + hx * 16, ay = y + hy * 16
            ctx.fillStyle = Theme.foreground
            ctx.beginPath()
            ctx.moveTo(ax + hx * 5, ay + hy * 5)
            ctx.lineTo(ax - hx * 3 + nx * 4, ay - hy * 3 + ny * 4)
            ctx.lineTo(ax - hx * 3 - nx * 4, ay - hy * 3 - ny * 4)
            ctx.closePath()
            ctx.fill()
        }

        ctx.font = "bold 8px '" + Theme.fontFamily + "'"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        for (const c of corners) {
            ctx.strokeStyle = Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.25)
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(c.track[0], c.track[1])
            ctx.lineTo(c.p[0], c.p[1])
            ctx.stroke()
            ctx.fillStyle = Theme.surface
            ctx.strokeStyle = Theme.alpha(Theme.foreground, 0.3)
            ctx.beginPath()
            ctx.arc(c.p[0], c.p[1], 6.5, 0, Math.PI * 2)
            ctx.fill()
            ctx.stroke()
            ctx.fillStyle = Theme.foreground
            ctx.fillText(c.n, c.p[0], c.p[1] + 0.5)
        }
    }
}
