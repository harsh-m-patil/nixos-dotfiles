import QtQuick
import QtQuick.Layouts

import "."

RowLayout {
    id: root

    property real value: 0
    property int count: 10
    property color accent: Theme.foam

    spacing: 5
    implicitHeight: 28

    Repeater {
        model: root.count
        Rectangle {
            required property int index
            readonly property bool lit: (index + 0.5) / root.count <= root.value
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Math.min(width, height) / 2.4
            color: lit ? root.accent : Theme.alpha(Theme.foreground, 0.12)
            Behavior on color { ColorAnimation { duration: 260 } }
        }
    }
}
