import QtQuick
import QtQuick.Layouts

import "."

BarPopup {
    id: root

    property string selectedName: MonitorData.focusedName
    readonly property var selected: {
        for (let i = 0; i < MonitorData.monitors.length; i++)
            if (MonitorData.monitors[i].name === selectedName)
                return MonitorData.monitors[i]
        return MonitorData.monitors.length ? MonitorData.monitors[0] : null
    }
    readonly property int panelWidth: 344
    readonly property bool settingsEnabled: !!selected && !selected.disabled
        && MonitorData.layoutMode !== "mirror" && !MonitorData.busy

    function selectAvailableMonitor() {
        if (MonitorData.monitors.some(m => m.name === selectedName)) return
        const focused = MonitorData.monitors.find(m => m.name === MonitorData.focusedName)
        selectedName = focused ? focused.name : (MonitorData.monitors[0]?.name ?? "")
    }

    Connections {
        target: MonitorData
        function onMonitorsChanged() { root.selectAvailableMonitor() }
    }

    onWantedChanged: if (wanted) MonitorData.refresh()
    contentMinWidth: panelWidth

    function applyScale(scale) {
        if (selected)
            MonitorData.setScale(selected, scale)
    }

    function modeOptions() {
        if (!selected) return []
        const result = []
        const seen = {}
        for (let i = 0; i < selected.modes.length; i++) {
            const match = selected.modes[i].match(/^(\d+x\d+)@([\d.]+)Hz$/)
            if (!match) continue
            const label = match[1]
            if (!seen[label]) {
                seen[label] = true
                result.push({ size: label, rate: Number(match[2]) })
            } else {
                for (let j = 0; j < result.length; j++)
                    if (result[j].size === label && Number(match[2]) > result[j].rate)
                        result[j] = { size: label, rate: Number(match[2]) }
            }
        }
        return result.sort((a, b) => b.size.split("x").map(Number).reduce((x, y) => x * y, 1)
            - a.size.split("x").map(Number).reduce((x, y) => x * y, 1))
    }

    function refreshOptions() {
        if (!selected) return []
        const prefix = selected.width + "x" + selected.height + "@"
        const rates = []
        for (let i = 0; i < selected.modes.length; i++) {
            const mode = selected.modes[i]
            if (!mode.startsWith(prefix)) continue
            const rate = Number(mode.slice(prefix.length).replace(/Hz$/, ""))
            if (isFinite(rate) && rates.indexOf(rate) < 0) rates.push(rate)
        }
        return rates.sort((a, b) => b - a)
    }

    ColumnLayout {
        Layout.preferredWidth: root.panelWidth
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                implicitWidth: 42
                implicitHeight: 42
                radius: 12
                color: Theme.alpha(Theme.iris, 0.14)
                Text {
                    anchors.centerIn: parent
                    text: MonitorData.monitors.length > 1 ? "󰍺" : "󰍹"
                    color: Theme.iris
                    font.family: Theme.fontFamily
                    font.pixelSize: 23
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    text: root.selected ? root.selected.description : "No displays found"
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: root.selected ? root.selected.name + "  ·  " + root.selected.width + " × " + root.selected.height
                        + "  ·  " + root.selected.refreshRate.toFixed(0) + " Hz" : "Connect a display and refresh"
                    color: Theme.subtle
                    font.family: Theme.displayFont
                    font.pixelSize: 10
                }
            }
            Text {
                text: MonitorData.busy ? "◌" : ""
                color: Theme.iris
                font.pixelSize: 16
            }
        }

        RowLayout {
            visible: MonitorData.monitors.length > 1
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: MonitorData.monitors
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 8
                    color: root.selectedName === modelData.name ? Theme.alpha(Theme.iris, 0.17) : Theme.surface
                    border.width: 1
                    border.color: root.selectedName === modelData.name ? Theme.alpha(Theme.iris, 0.5) : Theme.highlightMed
                    Text {
                        anchors.centerIn: parent
                        text: modelData.name
                        color: root.selectedName === modelData.name ? Theme.iris : Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.selectedName = modelData.name }
                }
            }
        }

        Rectangle {
            visible: !!root.selected && root.selected.disabled
            Layout.fillWidth: true
            implicitHeight: 34
            radius: 8
            color: enableHover.hovered ? Theme.alpha(Theme.iris, 0.18) : Theme.alpha(Theme.iris, 0.1)
            border.width: 1
            border.color: Theme.alpha(Theme.iris, 0.4)
            Text {
                anchors.centerIn: parent
                text: MonitorData.busy ? "Applying display layout…" : "Enable this display"
                color: Theme.iris
                font.family: Theme.displayFont
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
            HoverHandler { id: enableHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                enabled: !MonitorData.busy && !!root.selected?.disabled
                onTapped: MonitorData.enable(root.selected)
            }
        }

        ColumnLayout {
            visible: MonitorData.monitors.length > 1
            Layout.fillWidth: true
            spacing: 7

            Text {
                text: "Display layout"
                color: Theme.foreground
                font.family: Theme.displayFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Repeater {
                    model: [
                        { label: "Extend", mode: "extend" },
                        { label: "Mirror", mode: "mirror" },
                        { label: "Secondary only", mode: "secondary" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool active: MonitorData.layoutMode === modelData.mode
                        Layout.fillWidth: true
                        implicitHeight: 29
                        radius: 8
                        color: active ? Theme.alpha(Theme.iris, 0.18) : Theme.surface
                        opacity: MonitorData.busy ? 0.55 : 1
                        border.width: 1
                        border.color: active ? Theme.alpha(Theme.iris, 0.55) : Theme.highlightMed

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: parent.active ? Theme.iris : Theme.subtle
                            font.family: Theme.displayFont
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            enabled: !MonitorData.busy
                            onTapped: {
                                if (parent.modelData.mode === "extend") MonitorData.setExtended()
                                else if (parent.modelData.mode === "mirror") MonitorData.setMirror(root.selectedName)
                                else MonitorData.setSecondaryOnly()
                            }
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.highlightLow }

        ColumnLayout {
            visible: !!root.selected
            Layout.fillWidth: true
            spacing: 7
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Scale"; color: Theme.foreground; font.family: Theme.displayFont; font.pixelSize: 12; font.weight: Font.DemiBold }
                Item { Layout.fillWidth: true }
                Text { text: root.selected ? root.selected.scale.toFixed(2).replace(/0+$/, "").replace(/\.$/, "") + "×" : ""; color: Theme.subtle; font.family: Theme.fontFamily; font.pixelSize: 11 }
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: ["1", "1.25", "1.5", "1.6", "1.75", "2", "3"]
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool active: root.selected && Math.abs(root.selected.scale - Number(modelData)) < 0.01
                        width: 42
                        height: 29
                        radius: 8
                        color: active ? Theme.alpha(Theme.iris, 0.2) : Theme.surface
                        border.width: 1
                        border.color: active ? Theme.iris : Theme.highlightMed
                        Text { anchors.centerIn: parent; text: modelData + "×"; color: parent.active ? Theme.iris : Theme.subtle; font.family: Theme.fontFamily; font.pixelSize: 10 }
                        opacity: root.settingsEnabled ? 1 : 0.45
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { enabled: root.settingsEnabled; onTapped: root.applyScale(modelData) }
                    }
                }
            }
        }

        ColumnLayout {
            visible: !!root.selected && root.modeOptions().length > 1
            Layout.fillWidth: true
            spacing: 7
            Text { text: "Resolution"; color: Theme.foreground; font.family: Theme.displayFont; font.pixelSize: 12; font.weight: Font.DemiBold }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: root.modeOptions()
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool active: root.selected && root.selected.width + "x" + root.selected.height === modelData.size
                        implicitWidth: label.implicitWidth + 18
                        height: 28
                        radius: 8
                        color: active ? Theme.alpha(Theme.foam, 0.16) : Theme.surface
                        border.width: 1
                        border.color: active ? Theme.foam : Theme.highlightMed
                        Text { id: label; anchors.centerIn: parent; text: modelData.size; color: parent.active ? Theme.foam : Theme.subtle; font.family: Theme.fontFamily; font.pixelSize: 10 }
                        opacity: root.settingsEnabled ? 1 : 0.45
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { enabled: root.settingsEnabled; onTapped: MonitorData.setMode(root.selected, modelData.size + "@" + modelData.rate.toFixed(2)) }
                    }
                }
            }
        }

        ColumnLayout {
            visible: !!root.selected && root.refreshOptions().length > 1
            Layout.fillWidth: true
            spacing: 7
            Text { text: "Refresh rate"; color: Theme.foreground; font.family: Theme.displayFont; font.pixelSize: 12; font.weight: Font.DemiBold }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: root.refreshOptions()
                    delegate: Rectangle {
                        required property real modelData
                        readonly property bool active: root.selected && Math.abs(root.selected.refreshRate - modelData) < 0.1
                        implicitWidth: label.implicitWidth + 18
                        height: 28
                        radius: 8
                        color: active ? Theme.alpha(Theme.foam, 0.16) : Theme.surface
                        border.width: 1
                        border.color: active ? Theme.foam : Theme.highlightMed
                        Text { id: label; anchors.centerIn: parent; text: modelData.toFixed(0) + " Hz"; color: parent.active ? Theme.foam : Theme.subtle; font.family: Theme.fontFamily; font.pixelSize: 10 }
                        opacity: root.settingsEnabled ? 1 : 0.45
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { enabled: root.settingsEnabled; onTapped: MonitorData.setMode(root.selected, root.selected.width + "x" + root.selected.height + "@" + modelData.toFixed(2)) }
                    }
                }
            }
        }

        ColumnLayout {
            visible: MonitorData.monitors.filter(m => !m.disabled).length > 1 && !!root.selected
            Layout.fillWidth: true
            spacing: 7
            Text { text: "Arrange display"; color: Theme.foreground; font.family: Theme.displayFont; font.pixelSize: 12; font.weight: Font.DemiBold }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                Repeater {
                    model: [ ["󰅁", "left"], ["󰅂", "right"], ["󰅀", "above"], ["󰅃", "below"] ]
                    delegate: Rectangle {
                        required property var modelData
                        width: 42; height: 30; radius: 8
                        color: hover.hovered ? Theme.surface : "transparent"
                        border.width: 1; border.color: Theme.highlightMed
                        Text { anchors.centerIn: parent; text: modelData[0]; color: Theme.subtle; font.family: Theme.fontFamily; font.pixelSize: 16 }
                        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { enabled: root.settingsEnabled; onTapped: MonitorData.place(root.selected, modelData[1]) }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: MonitorData.monitors.length < 2
                ? "Only one display is detected. Connect another display to use mirror or secondary-only layouts."
                : "Mirror uses the selected display. Secondary only prefers an external display; Extend restores the previous extended layout."
            wrapMode: Text.WordWrap
            color: Theme.subtle
            font.family: Theme.displayFont
            font.pixelSize: 10
        }
    }
}
