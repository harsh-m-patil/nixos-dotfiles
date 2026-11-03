import QtQuick
import QtQuick.Layouts

import "."

Rectangle {
    id: root

    property real value: 0
    property color fill: Theme.iris
    property int thickness: 4

    Layout.fillWidth: true
    implicitHeight: thickness
    radius: Math.min(2, thickness / 2)
    color: Theme.highlightLow

    Rectangle {
        height: parent.height
        width: parent.width * Math.max(0, Math.min(1, root.value))
        radius: parent.radius
        color: root.fill
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    }
}
