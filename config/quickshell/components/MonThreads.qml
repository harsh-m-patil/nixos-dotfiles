import QtQuick
import QtQuick.Layouts

import "."

RowLayout {
    id: root

    property var cores: SystemData.cores
    property bool showValues: false

    spacing: 4

    Repeater {
        model: root.cores.length

        ColumnLayout {
            id: thread
            required property int index
            readonly property real v: root.cores[index] ?? 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 10
            Layout.minimumWidth: 0
            spacing: 4

            Text {
                visible: root.showValues
                Layout.alignment: Qt.AlignHCenter
                text: Math.round(thread.v * 100)
                color: Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 9
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 3
                color: Theme.highlightLow
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(2, parent.height * thread.v)
                    radius: 3
                    color: Theme.load(thread.v)
                    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: thread.index
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 9
            }
        }
    }
}
