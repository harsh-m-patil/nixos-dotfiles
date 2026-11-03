import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

import "."

// The expanded status island: a Control Center laid out like an instrument cluster.
// Dials for load, indicator lamps for radios, LED meters for levels, then telemetry,
// outputs, display scale and tray. Keyboard: j/k rows, h/l within a row or adjust.
ColumnLayout {
    id: panel
    spacing: 10

    readonly property var netHistory: {
        const rx = SystemData.netRxHistory, tx = SystemData.netTxHistory
        const n = Math.min(rx.length, tx.length)
        const out = []
        for (let i = Math.max(0, n - 60); i < n; i++)
            out.push((rx[i] ?? 0) + (tx[i] ?? 0))
        return out
    }
    readonly property bool hasGpu: SystemData.gpuBusy > 0.005 || SystemData.gpuTemp > 0
    readonly property var topCpu: SystemData.topBy("cpu", 4)
    readonly property var chipNames: ({ k10temp: "CPU", coretemp: "CPU", amdgpu: "GPU", nvme: "NVMe", acpitz: "Board" })
    readonly property var temps: {
        const out = [], seen = {}
        for (const s of SystemData.sensors) {
            const name = chipNames[s[0]] ?? s[0]
            if (s.length < 3 || !(Number(s[2]) > 0) || seen[name]) continue
            seen[name] = true
            out.push({ name: name, c: Number(s[2]) / 1000 })
        }
        const order = ["CPU", "GPU", "NVMe", "Board"]
        const rank = n => order.includes(n) ? order.indexOf(n) : order.length
        return out.sort((a, b) => rank(a.name) - rank(b.name)).slice(0, 5)
    }

    property bool hints: false
    property int row: 0
    property int col: 0
    property int scaleCol: 0

    readonly property var display: MonitorData.monitors.find(m => m.name === MonitorData.focusedName) ?? MonitorData.monitors[0] ?? null
    readonly property var scales: ["1", "1.25", "1.5", "1.6", "1.75", "2"]
    readonly property int activeScale: display ? scales.findIndex(s => Math.abs(display.scale - Number(s)) < 0.01) : -1
    readonly property var layouts: [["Extend", "extend"], ["Mirror", "mirror"], ["External only", "secondary"]]
    readonly property var profiles: [["Eco", "power-saver"], ["Balanced", "balanced"], ["Performance", "performance"]]

    // Navigable rows, top to bottom.
    readonly property var rows: {
        const r = ["tiles", "volume"]
        if (StatusData.hasBacklight) r.push("brightness")
        for (let i = 0; i < StatusData.sinks.length; i++) r.push("sink" + i)
        if (display) r.push("scale")
        if (SystemTray.items.values.length) r.push("tray")
        return r
    }
    readonly property string current: rows[Math.min(row, rows.length - 1)] ?? ""
    function width_(r) { return r === "tiles" ? 4 : r === "tray" ? SystemTray.items.values.length : r === "scale" ? scales.length : 1 }
    onCurrentChanged: if (current === "scale") scaleCol = Math.max(0, activeScale)

    function activate(r, c) {
        if (r === "tiles") [StatusData.toggleWifi, StatusData.toggleBluetooth, StatusData.toggleMic, () => SystemData.windowOpen = true][c]()
        else if (r === "volume") StatusData.toggleMute()
        else if (r.startsWith("sink")) StatusData.useSink(StatusData.sinks[Number(r.slice(4))])
        else if (r === "scale" && display) MonitorData.setScale(display, scales[scaleCol])
        else if (r === "tray") SystemTray.items.values[c]?.activate()
    }
    function step(r, d) {
        if (r === "volume") StatusData.setVolume(StatusData.volume + d * 0.05)
        else if (r === "brightness") StatusData.setBrightness(StatusData.brightness + d * 0.05)
        else if (r === "scale") scaleCol = Math.max(0, Math.min(scales.length - 1, scaleCol + d))
        else col = Math.max(0, Math.min(width_(r) - 1, col + d))
    }

    function handleKey(e) {
        const k = e.key, t = e.text
        if (k === Qt.Key_Escape || t === "q") StatusData.open = false
        else if (k === Qt.Key_Down || t === "j" || k === Qt.Key_Tab) { row = Math.min(rows.length - 1, row + 1); col = Math.min(col, width_(current) - 1) }
        else if (k === Qt.Key_Up || t === "k" || k === Qt.Key_Backtab) { row = Math.max(0, row - 1); col = Math.min(col, width_(current) - 1) }
        else if (k === Qt.Key_Left || t === "h") step(current, -1)
        else if (k === Qt.Key_Right || t === "l") step(current, 1)
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) activate(current, col)
        else if (t >= "1" && t <= "4") activate("tiles", Number(t) - 1)
        else if (t === "m") StatusData.toggleMute()
        else if (t === "?") hints = !hints
        else return false
        return true
    }

    component HudLabel: Text {
        color: F1Hub.ink2
        font.family: Theme.displayFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
    }
    component HudSection: ColumnLayout {
        property string title
        property string detail
        default property alias content: body.data
        Layout.fillWidth: true
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: parent.parent.title
                color: F1Hub.ink
                font.family: Theme.displayFont
                font.pixelSize: 14
                font.weight: Font.Bold
            }
            Item { Layout.fillWidth: true }
            HudLabel {
                text: parent.parent.detail
                visible: text !== ""
                color: F1Hub.ink3
                font.weight: Font.Medium
                Layout.maximumWidth: 260
                elide: Text.ElideRight
            }
        }
        ColumnLayout { id: body; Layout.fillWidth: true; spacing: 4 }
    }

    // Header strip: host and uptime, power-profile "gear", monitor button
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: SystemData.info.host || "Control Center"
                color: F1Hub.ink
                font.family: Theme.displayFont
                font.pixelSize: 20
                font.weight: Font.Bold
                font.letterSpacing: -0.3
            }
            HudLabel {
                text: [
                    SystemData.s.up ? "Up " + Fmt.uptime(SystemData.s.up) : "",
                    SystemData.s.procs ? SystemData.s.procs + " processes" : "",
                    SystemData.s.governor ? String(SystemData.s.governor).replace(/^./, c => c.toUpperCase()) : ""
                ].filter(x => x).join("  ·  ")
                color: F1Hub.ink3
                font.weight: Font.Medium
                visible: text !== ""
            }
        }
        Rectangle {
            visible: !!SystemData.s.profile
            implicitWidth: profRow.implicitWidth + 4
            implicitHeight: 28
            radius: 14
            color: F1Hub.fill
        Row {
            id: profRow
            anchors.centerIn: parent
            spacing: 0
            Repeater {
                model: panel.profiles
                Rectangle {
                    required property var modelData
                    readonly property bool active: SystemData.s.profile === modelData[1]
                    width: gear.implicitWidth + 20; height: 24; radius: 12
                    scale: profPress.pressed ? 0.96 : 1
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                    color: active ? Theme.foreground : profHover.hovered ? F1Hub.fill : "transparent"
                    Behavior on color { ColorAnimation { duration: 160 } }
                    HudLabel {
                        id: gear
                        anchors.centerIn: parent
                        text: parent.modelData[0]
                        color: parent.active ? Theme.background : F1Hub.ink2
                    }
                    HoverHandler { id: profHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        id: profPress
                        onTapped: SystemData.setPowerProfile(parent.modelData[1])
                    }
                }
            }
        }
        }
        Rectangle {
            implicitWidth: monText.implicitWidth + 24
            implicitHeight: 28
            radius: 14
            scale: monPress.pressed ? 0.96 : 1
            Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            color: monPress.pressed || monHover.hovered ? F1Hub.fillStrong : F1Hub.fill
            HudLabel { id: monText; anchors.centerIn: parent; text: "󰨇  Monitor"; color: F1Hub.ink }
            HoverHandler { id: monHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { id: monPress; onTapped: SystemData.windowOpen = true }
        }
    }

    // Instrument cluster: CPU tach, centre readout, memory dial
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 178
        radius: 22
        color: F1Hub.fill

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            HudGauge {
                Layout.preferredWidth: 170
                Layout.fillHeight: true
                label: "CPU"
                value: SystemData.cpu
                accent: Theme.iris
                sub: [SystemData.temp > 0 ? Fmt.deg(SystemData.temp) : "",
                      SystemData.freq[1] > 0 ? (SystemData.freq[1] / 1000).toFixed(1) + " GHz" : ""].filter(x => x).join("  ")
            }

            // Centre: network "speed", fuel and temperature meters
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 6
                Layout.bottomMargin: 4
                spacing: 4

                HudLabel { Layout.alignment: Qt.AlignHCenter; text: "Download" }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Fmt.rate(Network.rxRate)
                    color: F1Hub.ink
                    font.family: Theme.displayFont
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    font.letterSpacing: -0.6
                    font.features: { "tnum": 1 }
                }
                HudLabel {
                    Layout.alignment: Qt.AlignHCenter
                    text: "↑ " + Fmt.rate(Network.txRate)
                    color: F1Hub.ink2
                    font.weight: Font.Medium
                }
                Item { Layout.fillHeight: true }
                HudBar {
                    implicitHeight: 26
                    interactive: false
                    segments: 12
                    icon: StatusData.hasBattery ? StatusData.batteryIcon : "󰚥"
                    label: StatusData.charging ? "Chg" : "Bat"
                    value: StatusData.hasBattery ? StatusData.batteryLevel : 1
                    accent: StatusData.batteryLow ? Theme.love : StatusData.charging ? Theme.iris : Theme.gold
                }
                HudBar {
                    implicitHeight: 26
                    interactive: false
                    segments: 12
                    icon: "󰔏"
                    label: "Temp"
                    value: Math.min(1, (panel.hasGpu ? Math.max(SystemData.temp, SystemData.gpuTemp) : SystemData.temp) / 100)
                    accent: Theme.iris
                    warnAbove: 0.8
                }
            }

            HudGauge {
                Layout.preferredWidth: 170
                Layout.fillHeight: true
                label: "Memory"
                value: SystemData.memFraction
                redline: 0.9
                accent: Theme.foam
                sub: Fmt.gb(SystemData.memUsed) + (SystemData.swapUsed > 0 ? "  swap " + Fmt.gb(SystemData.swapUsed) : "")
            }
        }
    }

    // Indicator lamps
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        HudTelltale {
            icon: StatusData.wifiIcon; label: "Wi-Fi"; detail: StatusData.wifiDetail
            on: StatusData.wifiOn
            selected: panel.current === "tiles" && panel.col === 0
            onActivated: StatusData.toggleWifi()
        }
        HudTelltale {
            icon: StatusData.btOn ? "󰂯" : "󰂲"; label: "Bluetooth"; detail: StatusData.btDetail
            on: StatusData.btOn
            accent: Theme.iris
            selected: panel.current === "tiles" && panel.col === 1
            onActivated: StatusData.toggleBluetooth()
        }
        HudTelltale {
            icon: StatusData.micMuted ? "󰍭" : "󰍬"; label: "Mic"
            detail: !StatusData.hasMic ? "Unavailable" : StatusData.micMuted ? "Muted" : "Live"
            on: StatusData.hasMic && !StatusData.micMuted
            accent: Theme.love
            selected: panel.current === "tiles" && panel.col === 2
            onActivated: StatusData.toggleMic()
        }
        HudTelltale {
            icon: StatusData.hasBattery ? StatusData.batteryIcon : "󰚥"
            label: StatusData.hasBattery ? Math.round(StatusData.batteryLevel * 100) + "%" : "AC power"
            detail: StatusData.hasBattery ? StatusData.batteryDetail : "No battery"
            on: StatusData.charging || StatusData.batteryLow
            accent: StatusData.batteryLow ? Theme.love : Theme.iris
            selected: panel.current === "tiles" && panel.col === 3
            onActivated: SystemData.windowOpen = true
        }
    }

    // Levels
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        StatusSlider {
            icon: StatusData.volumeIcon
            title: StatusData.muted ? "Muted" : "Volume"
            value: StatusData.volume
            dimmed: StatusData.muted
            selected: panel.current === "volume"
            onMoved: v => StatusData.setVolume(v)
            onIconTapped: StatusData.toggleMute()
        }
        StatusSlider {
            visible: StatusData.hasBacklight
            icon: "󰃟"
            title: "Brightness"
            value: StatusData.brightness
            selected: panel.current === "brightness"
            onMoved: v => StatusData.setBrightness(v)
        }
    }

    // Thermals and fans
    HudSection {
        visible: panel.temps.length > 0 || SystemData.fans.length > 0
        title: "Thermals"
        detail: SystemData.fans.length ? (SystemData.fans.some(f => f > 0) ? "Fans active" : "Fans idle") : ""
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: panel.temps
                Rectangle {
                    required property var modelData
                    readonly property real frac: Math.min(1, modelData.c / 100)
                    readonly property color tone: modelData.c >= 85 ? Theme.love : modelData.c >= 70 ? Theme.gold : Theme.iris
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 52
                    radius: F1Hub.tileRadius
                    color: F1Hub.fill
                    Rectangle {
                        anchors { left: parent.left; bottom: parent.bottom; margins: 6 }
                        width: 3; radius: 1.5
                        height: (parent.height - 12) * parent.frac
                        color: parent.tone
                        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    }
                    Column {
                        anchors { left: parent.left; leftMargin: 15; verticalCenter: parent.verticalCenter }
                        spacing: 1
                        HudLabel { text: parent.parent.modelData.name }
                        Text {
                            text: Math.round(parent.parent.modelData.c) + "°"
                            color: parent.parent.tone
                            font.family: Theme.displayFont
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            font.features: { "tnum": 1 }
                        }
                    }
                }
            }
            Repeater {
                model: SystemData.fans
                Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool spinning: modelData > 0
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 52
                    radius: F1Hub.tileRadius
                    color: F1Hub.fill
                    Text {
                        id: blade
                        anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
                        text: "󰈐"
                        color: parent.spinning ? Theme.iris : F1Hub.ink3
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                        RotationAnimator on rotation {
                            from: 0; to: 360; loops: Animation.Infinite
                            duration: Math.max(250, 600000 / Math.max(1, blade.parent.modelData))
                            running: blade.parent.spinning && blade.visible && !Motion.reduced
                        }
                    }
                    Column {
                        anchors { left: blade.right; leftMargin: 7; verticalCenter: parent.verticalCenter }
                        spacing: 1
                        HudLabel { text: "Fan " + (parent.parent.index + 1) }
                        Row {
                            spacing: 2
                            Text {
                                text: parent.parent.parent.spinning ? parent.parent.parent.modelData : "Off"
                                color: parent.parent.parent.spinning ? F1Hub.ink : F1Hub.ink3
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                font.features: { "tnum": 1 }
                            }
                            HudLabel {
                                anchors.baseline: parent.children[0].baseline
                                visible: parent.parent.parent.spinning
                                text: "rpm"
                            }
                        }
                    }
                }
            }
        }
    }

    // Telemetry
    HudSection {
        title: "Telemetry"
        detail: SystemData.load.length ? "Load " + SystemData.load.map(l => l.toFixed(2)).join(" ") : ""
        GridLayout {
            Layout.fillWidth: true
            columns: panel.hasGpu ? 4 : 3
            columnSpacing: 12
            StatusSpark {
                compact: true
                visible: panel.hasGpu
                Layout.preferredHeight: 46
                label: "GPU"
                value: Math.round(SystemData.gpuBusy * 100) + "%"
                history: SystemData.gpuHistory
                accent: Theme.gold
            }
            StatusSpark {
                compact: true
                Layout.preferredHeight: 46
                label: "Network"
                value: Fmt.rate(SystemData.netRx + SystemData.netTx)
                history: panel.netHistory.length > 1 ? panel.netHistory : Network.history
                autoscale: true
                accent: Theme.iris
            }
            StatusSpark {
                compact: true
                Layout.preferredHeight: 46
                label: "Read"
                value: Fmt.rate(SystemData.diskRead)
                history: SystemData.diskReadHistory
                autoscale: true
                accent: Theme.foam
            }
            StatusSpark {
                compact: true
                Layout.preferredHeight: 46
                label: "Write"
                value: Fmt.rate(SystemData.diskWrite)
                history: SystemData.diskWriteHistory
                autoscale: true
                accent: Theme.rose
            }
        }
    }

    // Processes beside outputs and display
    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        HudSection {
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            visible: panel.topCpu.length > 0
            title: "Top"
            detail: SystemData.diskFraction > 0 ? "Disk " + Math.round(SystemData.diskFraction * 100) + "%" : ""
            Repeater {
                model: panel.topCpu
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 22
                    spacing: 8
                    Text {
                        text: modelData.name
                        color: F1Hub.ink
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        Layout.preferredWidth: 40
                        implicitHeight: 4
                        radius: 2
                        color: Theme.alpha(Theme.foreground, 0.07)
                        Rectangle {
                            width: parent.width * Math.min(1, modelData.cpu)
                            height: parent.height
                            radius: 2
                            color: Theme.iris
                        }
                    }
                    Text {
                        text: Math.round(modelData.cpu * 100) + "%"
                        color: F1Hub.ink2
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.features: { "tnum": 1 }
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 30
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: 10

            HudSection {
                title: "Audio out"
                Repeater {
                    model: StatusData.sinks
                    Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool active: modelData.id === StatusData.sink?.id
                        readonly property bool sel: panel.current === "sink" + index
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 15
                        color: active ? F1Hub.fillStrong : sinkHover.hovered ? F1Hub.fill : "transparent"
                        border.width: 1
                        border.color: sel ? Theme.alpha(Theme.foreground, 0.6) : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            Rectangle {
                                implicitWidth: 6; implicitHeight: 6; radius: 3
                                color: parent.parent.active ? Theme.iris : F1Hub.fillStrong
                            }
                            Text {
                                text: parent.parent.modelData.description || parent.parent.modelData.name
                                color: parent.parent.active ? F1Hub.ink : F1Hub.ink2
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        HoverHandler { id: sinkHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: StatusData.useSink(parent.modelData) }
                    }
                }
            }

            HudSection {
                visible: !!panel.display
                title: "Display"
                detail: panel.display ? panel.display.name + " · " + panel.display.refreshRate.toFixed(0) + " Hz" : ""
                F1Segmented {
                    Layout.fillWidth: true
                    visible: MonitorData.monitors.length > 1
                    items: panel.layouts.map(l => l[0])
                    current: panel.layouts.findIndex(l => l[1] === MonitorData.layoutMode)
                    onPicked: i => i === 0 ? MonitorData.setExtended() : i === 1 ? MonitorData.setMirror(MonitorData.focusedName) : MonitorData.setSecondaryOnly()
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Repeater {
                        model: panel.scales
                        Rectangle {
                            required property string modelData
                            required property int index
                            readonly property bool active: index === panel.activeScale
                            readonly property bool sel: panel.current === "scale" && index === panel.scaleCol
                            Layout.fillWidth: true
                            implicitHeight: 28
                            radius: 14
                            color: active ? Theme.foreground : scaleHover.hovered ? F1Hub.fillStrong : F1Hub.fill
                            border.width: sel ? 1 : 0
                            border.color: Theme.alpha(Theme.foreground, 0.6)
                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData + "×"
                                color: parent.active ? Theme.background : F1Hub.ink2
                                font.family: Theme.displayFont
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }
                            HoverHandler { id: scaleHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { enabled: !MonitorData.busy; onTapped: MonitorData.setScale(panel.display, parent.modelData) }
                        }
                    }
                }
            }
        }
    }

    // Tray
    HudSection {
        visible: SystemTray.items.values.length > 0
        title: "Apps"
        Flow {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: SystemTray.items
                Rectangle {
                    id: trayItem
                    required property var modelData
                    required property int index
                    width: 36; height: 36; radius: 18
                    color: panel.current === "tray" && panel.col === index ? Theme.alpha(Theme.iris, 0.16)
                        : trayArea.containsMouse ? F1Hub.fillStrong : F1Hub.fill
                    border.width: panel.current === "tray" && panel.col === index ? 1 : 0
                    border.color: Theme.alpha(Theme.foreground, 0.6)
                    IconImage { anchors.centerIn: parent; implicitSize: 16; source: trayItem.modelData.icon }
                    MouseArea {
                        id: trayArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onClicked: mouse => {
                            const item = trayItem.modelData
                            if (mouse.button === Qt.MiddleButton) return item.secondaryActivate()
                            if ((mouse.button === Qt.RightButton || item.onlyMenu) && item.hasMenu) {
                                const p = trayItem.QsWindow.contentItem.mapFromItem(trayItem, mouse.x, mouse.y)
                                return item.display(trayItem.QsWindow.window, p.x, p.y)
                            }
                            mouse.button === Qt.RightButton ? item.secondaryActivate() : item.activate()
                        }
                        onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }
        }
    }

    F1Keys {
        Layout.alignment: Qt.AlignHCenter
        hints: panel.hints
            ? [["j k", "Row"], ["h l", "Move or adjust"], ["↵", "Toggle"], ["1–4", "Lamps"], ["m", "Mute"], ["esc", "Close"]]
            : [["?", "Keyboard shortcuts"]]
    }
}
