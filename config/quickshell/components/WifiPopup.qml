import QtQuick
import QtQuick.Layouts

import "."

BarPopup {
    id: root

    readonly property var info: Network.info
    readonly property bool connected: Network.connected
    readonly property int signal: Math.max(0, Network.signal)
    property bool showSensitive: false
    readonly property string hidden: "••••••"

    onVisibleChanged: if (!visible) showSensitive = false

    function sensitive(raw, transform) {
        if (!showSensitive)
            return hidden
        const v = transform ? transform(raw ?? "") : (raw ?? "")
        return v || "—"
    }

    RowLayout {
        spacing: 12

        Rectangle {
            implicitWidth: 44
            implicitHeight: 44
            radius: 12
            color: Qt.rgba(Theme.foam.r, Theme.foam.g, Theme.foam.b, root.connected ? 0.16 : 0.06)

            Text {
                anchors.centerIn: parent
                text: Network.icon
                color: root.connected ? Theme.foam : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 22
            }
        }

        ColumnLayout {
            spacing: 1
            Text {
                text: root.connected ? Network.ssid : "Not connected"
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.weight: Font.Bold
            }
            Text {
                text: root.connected ? (root.info.sec || "Open") + "  ·  " + (root.info.dev ?? "") : "Click the icon to pick a network"
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
    }

    ColumnLayout {
        visible: root.connected
        Layout.preferredWidth: 280
        spacing: 10

        StatBar {
            icon: "󰒢"
            label: "Signal"
            value: root.signal + "%"
            fraction: root.signal / 100
            accent: Theme.foam
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 44

            Row {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                spacing: 2

                Repeater {
                    model: Network.historySize
                    Rectangle {
                        required property int index
                        readonly property var h: Network.history
                        readonly property real v: h[index - (Network.historySize - h.length)] ?? 0
                        readonly property real peak: Math.max(1024, ...h)
                        width: 5
                        height: Math.max(2, 44 * v / peak)
                        anchors.bottom: parent.bottom
                        radius: 2
                        color: Theme.iris
                        opacity: 0.35 + 0.65 * index / Network.historySize
                        Behavior on height { NumberAnimation { duration: 300 } }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            StatBar { icon: "󰁅"; label: "Down"; value: Fmt.rate(Network.rxRate); accent: Theme.foam }
            Item { implicitWidth: 16 }
            StatBar { icon: "󰁝"; label: "Up"; value: Fmt.rate(Network.txRate); accent: Theme.gold }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.highlightLow }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 26
            radius: 8
            color: root.showSensitive ? Theme.alpha(Theme.gold, 0.14) : sensHover.hovered ? Theme.surface : "transparent"
            border.width: 1
            border.color: root.showSensitive ? Theme.alpha(Theme.gold, 0.35) : Theme.highlightMed
            Behavior on color { ColorAnimation { duration: 150 } }

            HoverHandler { id: sensHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.showSensitive = !root.showSensitive }

            Row {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.showSensitive ? "󰈈" : "󰈉"
                    color: root.showSensitive ? Theme.gold : Theme.subtle
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.showSensitive ? "Network details shown" : "Show network details"
                    color: root.showSensitive ? Theme.foreground : Theme.subtle
                    font.family: Theme.displayFont
                    font.pixelSize: 11
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 4

            Repeater {
                model: [
                    ["IP", root.sensitive(root.info.ip, v => v.split("/")[0])],
                    ["Gateway", root.sensitive(root.info.gw)],
                    ["DNS", root.sensitive(root.info.dns, v => v.split("|")[0])],
                    ["MAC", root.sensitive(root.info.mac)],
                    ["Band", root.info.freq ? root.info.freq + "  ·  ch " + root.info.chan : ""],
                    ["Link", root.info.rate ?? ""]
                ].reduce((a, r) => a.concat(r), [])
                Text {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: index % 2 === 1
                    horizontalAlignment: index % 2 === 1 ? Text.AlignRight : Text.AlignLeft
                    text: modelData || "—"
                    color: index % 2 === 0 ? Theme.muted : Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
        }
    }
}
