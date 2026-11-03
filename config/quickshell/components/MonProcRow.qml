import QtQuick
import QtQuick.Layouts

import "."

Item {
    id: root

    property var p: null
    property bool header: false
    property bool compact: false
    property real cpuScale: 1
    property bool sortable: false
    property string sortKey: ""
    property bool sortDesc: true
    signal sortRequested(string key)

    readonly property real c: p?.cpu ?? 0
    readonly property int pidWidth: 64
    readonly property int memWidth: 80

    Layout.fillWidth: true
    implicitHeight: header ? 30 : compact ? 28 : 32
    visible: header || p !== null

    component Head: Text {
        id: head
        property string label
        property bool active
        property bool desc
        property bool sortable
        signal activated()
        text: label + (active ? (desc ? "  ↓" : "  ↑") : "")
        color: active ? Theme.foreground : Theme.muted
        font.family: Theme.displayFont
        font.pixelSize: 11
        font.weight: Font.Medium
        MouseArea {
            anchors.fill: parent
            enabled: head.sortable
            cursorShape: Qt.PointingHandCursor
            onClicked: head.activated()
        }
    }

    RowLayout {
        visible: root.header
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 16

        Head {
            Layout.fillWidth: true
            Layout.minimumWidth: 120
            Layout.preferredWidth: 240
            label: "Name"; sortable: root.sortable; active: root.sortKey === "name"; desc: root.sortDesc
            onActivated: root.sortRequested("name")
        }
        Head {
            Layout.preferredWidth: root.pidWidth
            label: "PID"; sortable: root.sortable; active: root.sortKey === "pid"; desc: root.sortDesc
            onActivated: root.sortRequested("pid")
        }
        Head {
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.maximumWidth: 220
            Layout.preferredWidth: 160
            label: "CPU"; sortable: root.sortable; active: root.sortKey === "cpu"; desc: root.sortDesc
            onActivated: root.sortRequested("cpu")
        }
        Head {
            Layout.preferredWidth: root.memWidth
            horizontalAlignment: Text.AlignRight
            label: "Memory"; sortable: root.sortable; active: root.sortKey === "mem"; desc: root.sortDesc
            onActivated: root.sortRequested("mem")
        }
        Item { implicitWidth: 20 }
    }

    HoverHandler { id: hover; enabled: !root.header }

    Rectangle {
        visible: !root.header
        anchors.fill: parent
        radius: 4
        color: hover.hovered ? Theme.highlightLow : "transparent"
    }

    RowLayout {
        visible: !root.header
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 16

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 120
            Layout.preferredWidth: 240
            text: root.p?.name ?? ""
            color: Theme.foreground
            font.family: Theme.displayFont
            font.pixelSize: 12
            elide: Text.ElideRight
        }
        Text {
            Layout.preferredWidth: root.pidWidth
            text: root.p?.pid ?? ""
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.maximumWidth: 220
            Layout.preferredWidth: 160
            spacing: 10
            MonBar {
                value: root.c / root.cpuScale
                fill: root.c > 0.25 ? Theme.gold : Theme.iris
            }
            Text {
                Layout.preferredWidth: 44
                horizontalAlignment: Text.AlignRight
                text: (root.c * 100).toFixed(1) + "%"
                color: root.c > 0.005 ? Theme.foreground : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
        Text {
            Layout.preferredWidth: root.memWidth
            horizontalAlignment: Text.AlignRight
            text: Fmt.bytes(root.p?.mem ?? 0)
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
        Text {
            Layout.preferredWidth: 20
            horizontalAlignment: Text.AlignHCenter
            text: "󰅖"
            color: killArea.containsMouse ? Theme.love : Theme.muted
            opacity: hover.hovered ? 1 : 0
            font.family: Theme.fontFamily
            font.pixelSize: 13

            MouseArea {
                id: killArea
                anchors.fill: parent
                anchors.margins: -4
                enabled: hover.hovered
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.p) SystemData.kill(root.p.pid)
            }
        }
    }
}
