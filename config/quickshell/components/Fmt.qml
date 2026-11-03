pragma Singleton
import QtQuick
import Quickshell

import "."

Singleton {
    function gb(b) { return (b / 1073741824).toFixed(1) + " GB" }
    function watts(uw) { return uw > 0 ? (uw / 1e6).toFixed(1) + " W" : "—" }
    function deg(c) { return c > 0 ? Math.round(c) + "°C" : "—" }
    function heat(c) { return c > 85 ? Theme.love : c > 70 ? Theme.gold : Theme.foreground }

    function rateParts(bps) {
        const u = ["B/s", "KB/s", "MB/s", "GB/s"]
        let i = 0
        while (bps >= 1024 && i < u.length - 1) { bps /= 1024; i++ }
        return [i === 0 ? String(Math.round(bps)) : bps.toFixed(bps < 10 ? 2 : 1), u[i]]
    }
    function rate(bps) { return rateParts(bps).join(" ") }

    function bytes(b) {
        const u = ["B", "KB", "MB", "GB", "TB"]
        let i = 0
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++ }
        return b.toFixed(i < 2 ? 0 : 1) + " " + u[i]
    }

    function uptime(sec) {
        sec = parseInt(sec) || 0
        const d = Math.floor(sec / 86400), h = Math.floor(sec % 86400 / 3600), m = Math.floor(sec % 3600 / 60)
        return (d > 0 ? d + "d " : "") + (h > 0 ? h + "h " : "") + m + "m"
    }

    function duration(hours) {
        const m = Math.round(hours * 60)
        return m >= 60 ? Math.floor(m / 60) + "h " + (m % 60) + "m" : m + "m"
    }

    function ago(epoch) {
        const sec = Date.now() / 1000 - epoch
        if (!(epoch > 0))
            return "—"
        if (sec < 60)
            return "just now"
        if (sec < 3600)
            return Math.floor(sec / 60) + "m ago"
        if (sec < 86400)
            return Math.floor(sec / 3600) + "h ago"
        return Math.floor(sec / 86400) + "d ago"
    }

    function clock(seconds) {
        if (!seconds || seconds < 0)
            return "0:00"
        const s = Math.floor(seconds % 60)
        const m = Math.floor((seconds / 60) % 60)
        const h = Math.floor(seconds / 3600)
        const pad = n => (n < 10 ? "0" : "") + n
        return h > 0 ? h + ":" + pad(m) + ":" + pad(s) : m + ":" + pad(s)
    }

    function usd(value) {
        const n = Number(value)
        if (!Number.isFinite(n))
            return "$0.00"
        const sign = n < 0 ? "-" : ""
        return sign + "$" + Math.abs(n).toFixed(2)
    }

    function tokens(value) {
        const n = Number(value)
        if (!Number.isFinite(n))
            return "0"
        const abs = Math.abs(n)
        const trim = (v, digits) => v.toFixed(digits).replace(/\.0+$/, "")
        if (abs >= 1e12)
            return trim(n / 1e12, abs >= 1e14 ? 0 : abs >= 1e13 ? 1 : 2) + "T"
        if (abs >= 1e9)
            return trim(n / 1e9, abs >= 1e11 ? 0 : abs >= 1e10 ? 1 : 2) + "B"
        if (abs >= 1e6)
            return trim(n / 1e6, abs >= 1e8 ? 0 : abs >= 1e7 ? 1 : 2) + "M"
        if (abs >= 1e3)
            return trim(n / 1e3, abs >= 1e5 ? 0 : abs >= 1e4 ? 1 : 2) + "K"
        return String(Math.round(n))
    }

    function dayShort(day) {
        if (!day || day.indexOf("-") < 0)
            return day || ""
        const p = day.split("-")
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        const m = parseInt(p[1], 10)
        return (months[m - 1] || p[1]) + " " + parseInt(p[2], 10)
    }

    function pct(fraction, digits) {
        digits = digits === undefined ? 1 : digits
        return (fraction * 100).toFixed(digits) + "%"
    }
}
