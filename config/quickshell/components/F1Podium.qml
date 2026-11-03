import QtQuick
import QtQuick.Layouts

import "."

RowLayout {
    id: podium
    // [{ code, value }] in finishing order
    property var entries: []
    property real headshotScale: 1
    Layout.fillWidth: true
    visible: entries.length > 0
    spacing: 8

    Repeater {
        model: [1, 0, 2]
        ColumnLayout {
            id: slot
            required property int modelData
            readonly property var entry: podium.entries[modelData] ?? null
            readonly property color tint: entry ? F1Data.driverColour(entry.code) : Theme.muted
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignBottom
            spacing: -6
            visible: entry !== null

            Image {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: (slot.modelData === 0 ? 76 : 60) * podium.headshotScale
                source: slot.entry ? F1Data.headshot(slot.entry.code) : ""
                fillMode: height > width ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                smooth: true
                mipmap: true
                asynchronous: true
                z: 0
            }
            Rectangle {
                z: 1
                Layout.fillWidth: true
                implicitHeight: slot.modelData === 0 ? 64 : slot.modelData === 1 ? 52 : 44
                radius: 10
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(slot.tint.r, slot.tint.g, slot.tint.b, 0.55) }
                    GradientStop { position: 1; color: Qt.rgba(slot.tint.r, slot.tint.g, slot.tint.b, 0.10) }
                }
                border.width: 1
                border.color: Qt.rgba(slot.tint.r, slot.tint.g, slot.tint.b, 0.6)
                Rectangle { anchors.fill: parent; z: -1; radius: parent.radius; color: Theme.background }
                Image {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 6
                    width: 30
                    height: 24
                    source: slot.entry?.team ? F1Data.teamLogo(slot.entry.team) : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                }
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: slot.entry?.code ?? ""
                        color: Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Black
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "P" + (slot.modelData + 1) + (slot.entry?.value ? "  " + slot.entry.value : "")
                        color: slot.modelData === 0 ? Theme.gold : Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }
}
