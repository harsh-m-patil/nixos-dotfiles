pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Agent usage store + island UI state. Polls usage-snapshot.py and normalises it into
// plain shapes the views read directly: limits, spend, today, cycle, models, days.
Singleton {
    id: root

    // ---- UI state (one expanded island at a time, across monitors)
    property bool open: false
    property string screen: ""
    property int page: 0
    readonly property var pages: ["Models", "Days", "Limits"]

    function toggle(onScreen) {
        if (open && (!onScreen || onScreen === screen)) { open = false; return }
        show(onScreen)
    }
    function show(onScreen) {
        screen = onScreen || Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || ""
        open = true
        if (Date.now() - readAt > 60000) refresh()
    }

    IpcHandler {
        target: "agentUsage"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.open = false }
        function refresh(): void { root.refresh() }
    }

    // ---- Data
    property bool loading: reader.running
    property bool ready: false
    property string error: ""
    property real readAt: 0

    property var limits: []             // [{ label, used (0–100), left, resetsAt (ms) }], tightest first
    property var spend: null            // { used, limit } in USD, or null
    property real cycleEnd: 0           // ms
    property var today: ({ cost: 0, tokens: 0, input: 0, output: 0, cache: 0 })
    property var cycle: ({ cost: 0, tokens: 0, sessions: 0, events: 0 })
    property var models: []             // [{ name, provider, cost, tokens, events, share }] by cost
    property var days: []               // [{ day, cost, tokens }] up to today

    readonly property var tightest: limits.length ? limits[0] : null
    readonly property color accent: !tightest ? Theme.iris
        : tightest.left <= 15 ? Theme.love : tightest.left <= 35 ? Theme.gold : Theme.iris

    function resetsIn(ms) {
        const h = (ms - Date.now()) / 3600000
        if (!(h > 0)) return ""
        return h >= 48 ? "resets in " + Math.round(h / 24) + " days" : "resets in " + Math.round(h) + " h"
    }

    function ingest(d) {
        readAt = Date.now()
        ready = true
        error = d.ok ? "" : (d.error || "Usage unavailable")

        limits = (d.limits?.windows ?? []).map(w => ({
            label: w.label,
            used: Math.max(0, Math.min(100, Number(w.usedPercent) || 0)),
            left: Number(w.remainingPercent) || 0,
            resetsAt: Date.parse(w.resetsAt) || 0
        })).sort((a, b) => a.left - b.left)

        const s = d.limits?.spend
        spend = s && s.limitCents > 0 ? { used: s.totalCents / 100, limit: s.limitCents / 100 } : null
        cycleEnd = Number(d.limits?.billingCycleEndMs) || 0

        const t = d.today ?? {}
        today = { cost: Number(t.costUsd) || 0, tokens: Number(t.totalTokens) || 0,
                  input: Number(t.inputTokens) || 0, output: Number(t.outputTokens) || 0,
                  cache: Number(t.cacheReadTokens) || 0 }

        const c = d.cycle ?? {}
        cycle = { cost: Number(c.costUsd) || 0, tokens: Number(c.totalTokens) || 0,
                  sessions: Number(c.sessions) || 0, events: Number(c.events) || 0 }

        const total = Math.max(0.0001, cycle.cost)
        models = (c.models ?? []).map(m => ({
            name: m.model, provider: m.provider,
            cost: Number(m.costUsd) || 0, tokens: Number(m.totalTokens) || 0,
            events: Number(m.events) || 0, share: (Number(m.costUsd) || 0) / total
        })).sort((a, b) => b.cost - a.cost)

        const todayKey = t.day ?? ""
        days = (c.daily ?? []).filter(x => !todayKey || x.day <= todayKey)
            .map(x => ({ day: x.day, cost: Number(x.costUsd) || 0, tokens: Number(x.totalTokens) || 0 }))
    }

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/usage-snapshot.py"

    function refresh() { if (!reader.running) reader.running = true }

    Process {
        id: reader
        command: ["python3", root.scriptPath]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try { root.ingest(JSON.parse(text.trim() || "{}")) }
                catch (e) { root.error = "Invalid usage snapshot" }
            }
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.trim() && !root.ready) root.error = text.trim().split("\n")[0]
        }
    }

    // The compact pill always shows today's spend, so a slow background poll stays on;
    // it speeds up while the expanded island is open.
    Timer {
        interval: root.open ? 60 * 1000 : 5 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
