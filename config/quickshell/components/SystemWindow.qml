import QtQuick
import QtQuick.Layouts
import Quickshell

import "."

FloatingWindow {
    id: win

    title: "System Monitor"
    implicitWidth: 1240
    implicitHeight: 780
    minimumSize: Qt.size(1000, 640)
    color: Theme.background
    visible: SystemData.windowOpen
    onClosed: SystemData.windowOpen = false

    readonly property var d: SystemData
    readonly property var tabs: [
        { name: "Overview", icon: "󰕮" },
        { name: "Processes", icon: "󰐱" },
        { name: "Performance", icon: "󰄪" },
        { name: "System", icon: "󰒓" }
    ]

    SystemSampler {
        active: win.visible
        detailed: true
    }

    onVisibleChanged: {
        if (visible)
            content.forceActiveFocus()
    }

    property date now: new Date()
    Connections {
        target: SystemData
        function onBeatChanged() { win.now = new Date() }
    }

    component HeaderStat: ColumnLayout {
        id: hs
        property string label
        property string value
        spacing: 1
        Text { Layout.alignment: Qt.AlignRight; text: hs.label; color: Theme.muted; font.family: Theme.displayFont; font.pixelSize: 10 }
        Text { Layout.alignment: Qt.AlignRight; text: hs.value; color: Theme.foreground; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Medium }
    }

    component VRule: Rectangle {
        implicitWidth: 1
        implicitHeight: 28
        color: Theme.highlightLow
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 0
        focus: true

        Keys.onPressed: event => {
            const n = win.tabs.length
            if (event.key === Qt.Key_Escape) {
                if (SystemData.tab === 1 && processes.query !== "")
                    processes.query = ""
                else
                    SystemData.windowOpen = false
            } else if (event.modifiers & Qt.ControlModifier) {
                if (event.key >= Qt.Key_1 && event.key < Qt.Key_1 + n)
                    SystemData.tab = event.key - Qt.Key_1
                else if (event.key === Qt.Key_Tab)
                    SystemData.tab = (SystemData.tab + 1) % n
                else if (event.key === Qt.Key_Backtab)
                    SystemData.tab = (SystemData.tab + n - 1) % n
                else if (event.key === Qt.Key_F) {
                    SystemData.tab = 1
                    processes.focusSearch()
                } else if (event.key === Qt.Key_P)
                    SystemData.showPrivate = !SystemData.showPrivate
                else
                    return
            } else
                return
            event.accepted = true
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.topMargin: 14
            spacing: 12

            Rectangle {
                implicitWidth: 34
                implicitHeight: 34
                radius: height / 2
                color: F1Hub.fillStrong
                Text {
                    anchors.centerIn: parent
                    text: "󰓅"
                    color: Theme.iris
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                }
            }

            ColumnLayout {
                spacing: 1
                Text {
                    text: "System Monitor"
                    color: Theme.foreground
                    font.family: Theme.displayFont
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }
                Text {
                    text: (win.d.showPrivate ? (win.d.info.host || "localhost") + "  ·  " : "") + (win.d.info.cpuname || "")
                    color: Theme.muted
                    font.family: Theme.displayFont
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            HeaderStat { label: "CPU"; value: Math.round(win.d.cpu * 100) + "%" }
            VRule {}
            HeaderStat { label: "Memory"; value: Math.round(win.d.memFraction * 100) + "%" }
            VRule {}
            HeaderStat { label: "Uptime"; value: Fmt.uptime(win.d.s.up) }
            VRule {}
            HeaderStat { label: "Updated"; value: Qt.formatTime(win.now, "hh:mm:ss") }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 20
            Layout.topMargin: 6
            spacing: 0

            Repeater {
                model: win.tabs

                Item {
                    id: tabItem
                    required property var modelData
                    required property int index
                    readonly property bool active: SystemData.tab === index
                    implicitWidth: tabRow.implicitWidth + 24
                    implicitHeight: 40

                    HoverHandler { id: tabHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: SystemData.tab = tabItem.index }

                    Row {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tabItem.modelData.icon
                            color: tabItem.active ? Theme.iris : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tabItem.modelData.name
                            color: tabItem.active || tabHover.hovered ? Theme.foreground : Theme.subtle
                            font.family: Theme.displayFont
                            font.pixelSize: 13
                            font.weight: tabItem.active ? Font.DemiBold : Font.Normal
                        }
                    }

                    Rectangle {
                        visible: tabItem.active
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 16
                        height: 2
                        radius: 1
                        color: Theme.iris
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                visible: SystemData.tab === 3
                Layout.rightMargin: 14
                implicitWidth: privRow.implicitWidth + 20
                implicitHeight: 26
                radius: height / 2
                color: SystemData.showPrivate ? Theme.alpha(Theme.gold, 0.22) : privHover.hovered ? F1Hub.fillStrong : F1Hub.fill
                Behavior on color { ColorAnimation { duration: 150 } }

                HoverHandler { id: privHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: SystemData.showPrivate = !SystemData.showPrivate }

                Row {
                    id: privRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: SystemData.showPrivate ? "󰈈" : "󰈉"
                        color: SystemData.showPrivate ? Theme.gold : Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: SystemData.showPrivate ? "Private info shown" : "Show private info"
                        color: SystemData.showPrivate ? Theme.foreground : Theme.subtle
                        font.family: Theme.displayFont
                        font.pixelSize: 11
                    }
                }
            }

            Text {
                text: "Ctrl+1–4 switch tabs   ·   " + (SystemData.tab === 3 ? "Ctrl+P private   ·   " : "") + "Esc close"
                color: Theme.muted
                font.family: Theme.displayFont
                font.pixelSize: 11
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.highlightLow
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16
            currentIndex: SystemData.tab

            SysOverview { onShowProcesses: SystemData.tab = 1 }
            SysProcesses { id: processes }
            SysPerformance {}
            SysInfo {}
        }
    }
}
