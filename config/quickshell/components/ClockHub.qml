pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// UI state for the clock island: which screen is expanded, the selected day, and
// the F1 weekend lookups the calendar views read (plain shapes, from F1Data).
Singleton {
    id: hub

    property bool open: false
    property string screen: ""
    property date selected: new Date()
    property bool hints: false

    // Ticks every second while a peek or the calendar shows seconds, else once a minute.
    property date now: new Date()
    property int precise: 0
    Timer {
        running: true
        repeat: true
        interval: hub.precise > 0 ? 1000 - hub.now.getMilliseconds()
            : 60000 - hub.now.getSeconds() * 1000 - hub.now.getMilliseconds()
        onTriggered: hub.now = new Date()
    }
    onPreciseChanged: now = new Date()

    readonly property int year: selected.getFullYear()
    readonly property int month: selected.getMonth()
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"]

    function toggle(onScreen) {
        if (open && (!onScreen || onScreen === screen)) { open = false; return }
        show(onScreen)
    }
    function show(onScreen) {
        screen = onScreen || Hyprland.focusedMonitor?.name || Quickshell.screens[0]?.name || ""
        today()
        hints = false
        open = true
    }
    function today() { selected = new Date() }
    function moveDays(n) {
        const d = new Date(year, month, selected.getDate() + n)
        selected = d
    }
    function moveMonths(n) {
        const last = new Date(year, month + n + 1, 0).getDate()
        selected = new Date(year, month + n, Math.min(selected.getDate(), last))
    }
    function select(y, m, d) { selected = new Date(y, m, d) }

    function isoWeek(d) {
        const t = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 3 - (d.getDay() + 6) % 7)
        const w1 = new Date(t.getFullYear(), 0, 4)
        return 1 + Math.round(((t - w1) / 86400000 - 3 + (w1.getDay() + 6) % 7) / 7)
    }
    function dayOfYear(d) {
        return Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - new Date(d.getFullYear(), 0, 1)) / 86400000) + 1
    }
    // Monday of the week containing d.
    function weekStart(d) { return new Date(d.getFullYear(), d.getMonth(), d.getDate() - (d.getDay() + 6) % 7) }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
    }

    // F1 sessions on a date: [{ label, time, live, past }], with the weekend's title.
    function sessionsOn(y, m, d) {
        if (!F1Data.eventsOn(y, m, d).length) return []
        const out = []
        for (const r of F1Data.races)
            for (const s of r.sessions)
                if (s.start.getFullYear() === y && s.start.getMonth() === m && s.start.getDate() === d)
                    out.push({ label: s.label, time: Qt.formatTime(s.start, "hh:mm"),
                        live: s.start <= F1Data.now && F1Data.now < s.end, past: s.end <= F1Data.now,
                        race: s.label === "Race" })
        return out
    }
    function weekendTitle(y, m, d) { return F1Data.dayDetail(y, m, d)?.title ?? "" }
    function isRaceDay(y, m, d) { return F1Data.eventsOn(y, m, d).some(e => e.label === "Race") }

    IpcHandler {
        target: "clock"
        function toggle(): void { hub.toggle() }
        function show(): void { hub.show() }
        function hide(): void { hub.open = false }
    }
}
