import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

import "."

// The expanded status island: a Control Center of toggles, sliders, load charts,
// outputs, display scale and tray. Keyboard: j/k rows, h/l within a row or adjust.
ColumnLayout {
    id: panel
    spacing: 14

    property bool hints: false
    property int row: 0
    property int col: 0
    property int scaleCol: 0

    readonly property var display: MonitorData.monitors.find(m => m.name === MonitorData.focusedName) ?? MonitorData.monitors[0] ?? null
    readonly property var scales: ["1", "1.25", "1.5", "1.6", "1.75", "2"]
    readonly property int activeScale: display ? scales.findIndex(s => Math.abs(display.scale - Number(s)) < 0.01) : -1
    readonly property var layouts: [["Extend", "extend"], ["Mirror", "mirror"], ["External only", "secondary"]]

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

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            F1Text { text: "Control Center"; role: "title2" }
            F1Text {
                text: [SystemData.info.host, SystemData.s.up ? "up " + Fmt.uptime(SystemData.s.up) : ""].filter(x => x).join(" · ")
                role: "footnote"; tone: "secondary"; visible: text !== ""
            }
        }
        Rectangle {
            implicitWidth: monRow.implicitWidth + 24
            implicitHeight: 30
            radius: 15
            color: monHover.hovered ? F1Hub.fillStrong : F1Hub.fill
            border.width: 1
            border.color: F1Hub.hairline
            Row {
                id: monRow
                anchors.centerIn: parent
                spacing: 7
                F1Text { anchors.verticalCenter: parent.verticalCenter; text: "System monitor"; role: "footnote"; font.weight: Font.DemiBold }
            }
            HoverHandler { id: monHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: SystemData.windowOpen = true }
        }
    }

    // Toggles
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        StatusTile {
            icon: StatusData.wifiIcon; title: "Wi-Fi"; detail: StatusData.wifiDetail
            on: StatusData.wifiOn
            selected: panel.current === "tiles" && panel.col === 0
            onActivated: StatusData.toggleWifi()
        }
        StatusTile {
            icon: StatusData.btOn ? "󰂯" : "󰂲"; title: "Bluetooth"; detail: StatusData.btDetail
            on: StatusData.btOn
            selected: panel.current === "tiles" && panel.col === 1
            onActivated: StatusData.toggleBluetooth()
        }
        StatusTile {
            icon: StatusData.micMuted ? "󰍭" : "󰍬"; title: "Microphone"
            detail: !StatusData.hasMic ? "Unavailable" : StatusData.micMuted ? "Muted" : "Live"
            on: StatusData.hasMic && !StatusData.micMuted
            accent: Theme.love
            selected: panel.current === "tiles" && panel.col === 2
            onActivated: StatusData.toggleMic()
        }
        StatusTile {
            icon: StatusData.hasBattery ? StatusData.batteryIcon : "󰚥"
            title: StatusData.hasBattery ? Math.round(StatusData.batteryLevel * 100) + "%" : "AC power"
            detail: StatusData.hasBattery ? StatusData.batteryDetail : "No battery"
            on: StatusData.charging || StatusData.batteryLow
            accent: StatusData.batteryLow ? Theme.love : Theme.foam
            selected: panel.current === "tiles" && panel.col === 3
            onActivated: SystemData.windowOpen = true
        }
    }

    // Sliders
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

    // Load
    F1Group {
        Layout.fillWidth: true
        title: "Activity"
        detail: SystemData.cpuModel
        pad: 14
        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 104
            spacing: 22
            StatusSpark {
                Layout.fillHeight: true
                label: "CPU"
                value: Math.round(SystemData.cpu * 100) + "%"
                sub: SystemData.temp > 0 ? Fmt.deg(SystemData.temp) : ""
                history: SystemData.cpuHistory
                accent: SystemData.cpu > 0.85 ? Theme.love : Theme.iris
            }
            StatusSpark {
                Layout.fillHeight: true
                label: "Memory"
                value: Math.round(SystemData.memFraction * 100) + "%"
                sub: Fmt.gb(SystemData.memUsed) + " of " + Fmt.gb(SystemData.memTotal)
                history: SystemData.memHistory
                accent: SystemData.memFraction > 0.9 ? Theme.love : Theme.foam
            }
        }
    }

    // Outputs and display
    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        F1Group {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            title: "Sound output"
            pad: 4
            Repeater {
                model: StatusData.sinks
                Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool active: modelData.id === StatusData.sink?.id
                    readonly property bool sel: panel.current === "sink" + index
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 10
                    color: sel ? Theme.alpha(Theme.iris, 0.16) : sinkHover.hovered ? F1Hub.fill : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8
                        F1Text {
                            text: parent.parent.modelData.description || parent.parent.modelData.name
                            role: "callout"
                            font.weight: parent.parent.active ? Font.DemiBold : Font.Normal
                            tone: parent.parent.active ? "primary" : "secondary"
                            Layout.fillWidth: true
                        }
                        Text {
                            visible: parent.parent.active
                            text: "󰄬"
                            color: Theme.iris
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                    }
                    HoverHandler { id: sinkHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: StatusData.useSink(parent.modelData) }
                }
            }
        }

        F1Group {
            visible: !!panel.display
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            title: "Display"
            detail: panel.display ? panel.display.name + " · " + panel.display.refreshRate.toFixed(0) + " Hz" : ""
            pad: 10
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                F1Segmented {
                    Layout.fillWidth: true
                    visible: MonitorData.monitors.length > 1
                    items: panel.layouts.map(l => l[0])
                    current: panel.layouts.findIndex(l => l[1] === MonitorData.layoutMode)
                    onPicked: i => i === 0 ? MonitorData.setExtended() : i === 1 ? MonitorData.setMirror(MonitorData.focusedName) : MonitorData.setSecondaryOnly()
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Repeater {
                        model: panel.scales
                        Rectangle {
                            required property string modelData
                            required property int index
                            readonly property bool active: index === panel.activeScale
                            readonly property bool sel: panel.current === "scale" && index === panel.scaleCol
                            Layout.fillWidth: true
                            implicitHeight: 28
                            radius: 8
                            color: active ? F1Hub.fillStrong : scaleHover.hovered ? F1Hub.fill : "transparent"
                            border.width: 1
                            border.color: sel ? Theme.alpha(Theme.iris, 0.7) : active ? F1Hub.fillStrong : "transparent"
                            F1Text {
                                anchors.centerIn: parent
                                text: parent.modelData + "×"
                                role: "caption"; numeric: true
                                tone: parent.active ? "primary" : "secondary"
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
    F1Group {
        visible: SystemTray.items.values.length > 0
        Layout.fillWidth: true
        title: "Menu bar apps"
        pad: 6
        Flow {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: SystemTray.items
                Rectangle {
                    id: trayItem
                    required property var modelData
                    required property int index
                    width: 36; height: 36; radius: 10
                    color: panel.current === "tray" && panel.col === index ? Theme.alpha(Theme.iris, 0.16)
                        : trayArea.containsMouse ? F1Hub.fillStrong : "transparent"
                    IconImage { anchors.centerIn: parent; implicitSize: 18; source: trayItem.modelData.icon }
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
            ? [["j k", "Row"], ["h l", "Move or adjust"], ["↵", "Toggle"], ["1–4", "Tiles"], ["m", "Mute"], ["esc", "Close"]]
            : [["?", "Keyboard shortcuts"]]
    }
}
