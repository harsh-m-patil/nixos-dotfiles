pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var monitors: []
    property string focusedName: ""
    property bool busy: false
    property string layoutMode: "extend"
    property var savedLayout: []
    readonly property string statePath: Quickshell.env("HOME") + "/.local/state/quickshell/monitor-layout.json"
    property bool stateLoaded: false
    property string persistedState: ""

    FileView {
        id: stateFile
        path: root.statePath
        printErrors: false
        onLoaded: root.loadState()
    }

    Timer {
        id: stateLoadFallback
        interval: 300
        running: true
        onTriggered: {
            if (!root.stateLoaded)
                root.loadState()
        }
    }

    function loadState() {
        if (stateLoaded) return
        try {
            const saved = JSON.parse(stateFile.text() || "{}")
            if (Array.isArray(saved.savedLayout))
                savedLayout = saved.savedLayout.filter(entry => entry
                    && typeof entry.name === "string"
                    && /^\d+x\d+(@[\d.]+)?$/.test(entry.mode)
                    && isFinite(Number(entry.x)) && isFinite(Number(entry.y))
                    && isFinite(Number(entry.scale)) && Number(entry.scale) > 0)
            if (["extend", "mirror", "secondary"].includes(saved.layoutMode))
                layoutMode = saved.layoutMode
        } catch (e) {
            savedLayout = []
        }
        stateLoaded = true
        refresh()
    }

    function persistState() {
        if (!stateLoaded) return
        const next = JSON.stringify({ version: 1, layoutMode, savedLayout })
        if (next === persistedState) return
        persistedState = next
        stateFile.setText(next)
    }

    function refresh() {
        if (!reader.running)
            reader.running = true
    }

    function run(args) {
        action.command = args
        if (!action.running)
            action.running = true
    }

    function apply(name, mode, x, y, scale) {
        // This Hyprland config uses the Lua parser; the legacy `keyword monitor`
        // command is rejected by it. Apply changes through the same hl.monitor
        // API used by monitors.lua.
        if (!/^[A-Za-z0-9._-]+$/.test(name) || !/^\d+x\d+(@[\d.]+)?$/.test(mode))
            return
        const scaleValue = Number(scale)
        if (!isFinite(scaleValue) || scaleValue <= 0)
            return
        const position = Math.round(Number(x)) + "x" + Math.round(Number(y))
        const expression = "hl.monitor({ output = \"" + name + "\", mode = \"" + mode
            + "\", position = \"" + position + "\", scale = " + scaleValue + ", disabled = false, mirror = \"\" })"
        run(["hyprctl", "eval", expression])
    }

    function monitorRule(monitor, options) {
        const fields = ["output = " + JSON.stringify(monitor.name)]
        if (options.disabled) {
            fields.push("disabled = true")
            fields.push("mirror = \"\"")
        } else {
            fields.push("disabled = false")
            fields.push("mode = " + JSON.stringify(options.mode || monitor.currentMode || "preferred"))
            fields.push("position = " + JSON.stringify(options.position || (monitor.x + "x" + monitor.y)))
            fields.push("scale = " + Number(options.scale ?? monitor.scale ?? 1))
            fields.push("mirror = " + JSON.stringify(options.mirror || ""))
        }
        return "hl.monitor({ " + fields.join(", ") + " })"
    }

    function applyRules(rules) {
        if (!rules.length || busy) return false
        run(["hyprctl", "eval", rules.join("; ")])
        return true
    }

    function captureExtendedLayout(values) {
        const enabled = values.filter(m => !m.disabled)
        if (enabled.length < 2 || enabled.some(m => m.mirrorOf)) return
        const next = enabled.map(m => ({
            name: m.name,
            mode: m.currentMode,
            x: m.x,
            y: m.y,
            scale: m.scale
        }))
        if (JSON.stringify(next) !== JSON.stringify(savedLayout)) {
            savedLayout = next
            persistState()
        }
    }

    function setMirror(sourceName) {
        const source = monitors.find(m => m.name === sourceName)
        if (!source || monitors.length < 2 || busy) return
        captureExtendedLayout(monitors)
        const rules = [monitorRule(source, {
            mode: source.currentMode,
            position: source.x + "x" + source.y,
            scale: source.scale
        })]
        for (const monitor of monitors) {
            if (monitor.name === source.name) continue
            rules.push(monitorRule(monitor, {
                mode: monitor.currentMode,
                position: source.x + "x" + source.y,
                scale: source.scale,
                mirror: source.name
            }))
        }
        if (applyRules(rules)) {
            layoutMode = "mirror"
            persistState()
        }
    }

    function isInternal(monitor) {
        return /^(eDP|LVDS|DSI)/i.test(monitor.name)
    }

    function setSecondaryOnly() {
        if (monitors.length < 2 || busy) return
        captureExtendedLayout(monitors)
        let target = monitors.find(m => m.name === focusedName && !isInternal(m))
        if (!target) target = monitors.find(m => !isInternal(m) && m.modes.length > 0)
        if (!target) target = monitors.find(m => m.name === focusedName) || monitors[0]
        const rules = [monitorRule(target, {
            mode: target.currentMode,
            position: target.x + "x" + target.y,
            scale: target.scale
        })]
        for (const monitor of monitors) {
            if (monitor.name !== target.name)
                rules.push(monitorRule(monitor, { disabled: true }))
        }
        if (applyRules(rules)) {
            layoutMode = "secondary"
            persistState()
        }
    }

    function recoverSingleDisplay(connected) {
        if (!["secondary", "mirror"].includes(layoutMode) || connected.length !== 1) return false
        const remaining = connected[0]
        if (!remaining.disabled && !remaining.mirrorOf) {
            layoutMode = "extend"
            savedLayout = []
            persistState()
            return false
        }
        const rule = monitorRule(remaining, {
            mode: remaining.currentMode,
            position: "0x0",
            scale: remaining.scale
        })
        if (applyRules([rule])) {
            layoutMode = "extend"
            savedLayout = []
            persistState()
            return true
        }
        return false
    }

    function setExtended() {
        if (monitors.length < 2 || busy) return
        const layout = savedLayout.length > 0 ? savedLayout.slice() : []
        if (layout.length === 0) {
            const primary = monitors.find(m => m.name === focusedName && !m.disabled)
                || monitors.find(m => !m.disabled) || monitors[0]
            layout.push({ name: primary.name, mode: primary.currentMode, x: 0, y: 0, scale: primary.scale })
            let x = Math.round(primary.width / primary.scale)
            for (const monitor of monitors) {
                if (monitor.name === primary.name) continue
                layout.push({ name: monitor.name, mode: monitor.currentMode, x, y: 0, scale: monitor.scale })
                x += Math.round(monitor.width / monitor.scale)
            }
        }

        let right = 0
        for (const entry of layout) {
            const monitor = monitors.find(m => m.name === entry.name)
            if (monitor)
                right = Math.max(right, entry.x + Math.round(monitor.width / entry.scale))
        }
        for (const monitor of monitors) {
            if (layout.some(entry => entry.name === monitor.name)) continue
            layout.push({ name: monitor.name, mode: monitor.currentMode, x: right, y: 0, scale: monitor.scale })
            right += Math.round(monitor.width / monitor.scale)
        }

        const rules = layout.map(entry => {
            const monitor = monitors.find(m => m.name === entry.name)
            return monitor ? monitorRule(monitor, {
                mode: entry.mode,
                position: entry.x + "x" + entry.y,
                scale: entry.scale
            }) : ""
        }).filter(rule => rule !== "")
        if (applyRules(rules)) {
            layoutMode = "extend"
            persistState()
        }
    }

    function setScale(monitor, scale) {
        if (monitor && !monitor.disabled && layoutMode !== "mirror")
            apply(monitor.name, monitor.currentMode, monitor.x, monitor.y, scale)
    }

    function setMode(monitor, mode) {
        if (monitor && !monitor.disabled && layoutMode !== "mirror")
            apply(monitor.name, mode, monitor.x, monitor.y, monitor.scale)
    }

    function enable(monitor) {
        if (!monitor || !monitor.disabled || busy) return
        const enabled = monitors.filter(m => !m.disabled && m.name !== monitor.name)
        let x = 0
        if (enabled.length > 0)
            x = Math.max(...enabled.map(m => m.x + Math.round(m.width / m.scale)))
        const rule = monitorRule(monitor, {
            mode: monitor.currentMode,
            position: x + "x0",
            scale: monitor.scale
        })
        if (applyRules([rule])) {
            layoutMode = "extend"
            persistState()
        }
    }

    function place(monitor, side) {
        if (!monitor || monitor.disabled || layoutMode !== "extend") return
        const enabled = monitors.filter(m => !m.disabled && m.name !== monitor.name)
        if (enabled.length === 0)
            return
        let x = 0
        let y = 0
        if (side === "left") {
            x = Math.min(...enabled.map(m => m.x)) - Math.round(monitor.width / monitor.scale)
        } else if (side === "right") {
            x = Math.max(...enabled.map(m => m.x + Math.round(m.width / m.scale)))
        } else if (side === "above") {
            y = Math.min(...enabled.map(m => m.y)) - Math.round(monitor.height / monitor.scale)
        } else {
            y = Math.max(...enabled.map(m => m.y + Math.round(m.height / m.scale)))
        }
        apply(monitor.name, monitor.currentMode, x, y, monitor.scale)
    }

    Process {
        id: reader
        command: ["hyprctl", "-j", "monitors", "all"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const values = JSON.parse(text || "[]")
                    const nextMonitors = values.map(m => {
                        const mode = String(m.width) + "x" + String(m.height)
                        const rate = Number(m.refreshRate || 0)
                        return {
                            name: m.name,
                            description: m.description || m.name,
                            width: Number(m.width || 0),
                            height: Number(m.height || 0),
                            x: Number(m.x || 0),
                            y: Number(m.y || 0),
                            scale: Number(m.scale || 1),
                            refreshRate: rate,
                            currentMode: mode + (rate > 0 ? "@" + rate.toFixed(2) : ""),
                            focused: !!m.focused,
                            disabled: !!m.disabled,
                            mirrorOf: m.mirrorOf && m.mirrorOf !== "none" ? m.mirrorOf : "",
                            modes: (m.availableModes || []).map(value => String(value))
                        }
                    })
                    root.monitors = nextMonitors
                    if (!root.stateLoaded) return
                    if (nextMonitors.length === 0) {
                        root.focusedName = ""
                        return
                    }

                    if (["secondary", "mirror"].includes(root.layoutMode) && nextMonitors.length === 1) {
                        if (root.busy) return
                        if (root.recoverSingleDisplay(nextMonitors)) return
                    }

                    root.captureExtendedLayout(nextMonitors)
                    const enabled = nextMonitors.filter(m => !m.disabled)
                    if (enabled.length === 0) return
                    root.layoutMode = nextMonitors.some(m => m.mirrorOf) ? "mirror"
                        : nextMonitors.length < 2 ? "extend"
                        : enabled.length === 1 ? "secondary" : "extend"
                    if (root.layoutMode !== "secondary" && nextMonitors.length < 2)
                        root.savedLayout = []
                    root.persistState()
                    const focused = values.find(m => m.focused)
                    root.focusedName = focused ? focused.name : ""
                } catch (e) {
                    root.monitors = []
                }
            }
        }
    }

    Process {
        id: action
        onRunningChanged: {
            root.busy = running
            if (!running)
                Qt.callLater(root.refresh)
        }
        stdout: StdioCollector { waitForEnd: true }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: if (root.stateLoaded) root.refresh()
    }

    Component.onCompleted: stateFile.reload()
}
