pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Polls usage-snapshot.py (Cursor limits + token/cost, same APIs as T3 Code Usage).
Singleton {
    id: root

    property var snapshot: ({})
    property bool loading: false
    property string lastError: ""
    property bool everLoaded: false

    readonly property bool available: snapshot.ok === true
    readonly property var windows: {
        const limits = snapshot.limits
        return limits && limits.windows ? limits.windows : []
    }
    readonly property var today: snapshot.today !== undefined ? snapshot.today : null
    readonly property var cycle: snapshot.cycle !== undefined ? snapshot.cycle : null

    readonly property var primaryWindow: {
        const ws = root.windows
        if (!ws.length)
            return null
        for (const id of ["totalPercentUsed", "autoPercentUsed", "apiPercentUsed"]) {
            const hit = ws.find(w => w.id === id)
            if (hit)
                return hit
        }
        return ws[0]
    }

    readonly property int tightestRemaining: {
        let min = 100
        for (let i = 0; i < root.windows.length; i++) {
            const r = root.windows[i].remainingPercent
            if (typeof r === "number")
                min = Math.min(min, r)
        }
        return min
    }

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/usage-snapshot.py"

    function refresh() {
        if (!reader.running)
            reader.running = true
    }

    Process {
        id: reader
        command: ["python3", root.scriptPath]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                root.loading = false
                root.everLoaded = true
                try {
                    const data = JSON.parse(text.trim() || "{}")
                    root.snapshot = data
                    root.lastError = data.ok ? "" : (data.error || "Usage unavailable")
                } catch (e) {
                    root.lastError = "Invalid usage snapshot"
                }
            }
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (text.trim())
                    root.lastError = text.trim().split("\n")[0]
            }
        }
        onRunningChanged: root.loading = running
    }

    Timer {
        interval: 5 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
