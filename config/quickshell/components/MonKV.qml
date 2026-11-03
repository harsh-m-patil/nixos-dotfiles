import QtQuick
import QtQuick.Layouts

import "."

Item {
    id: root

    property string label: ""
    property string value: ""
    property color valueColor: Theme.foreground
    property bool last: false
    property bool dense: false

    Layout.fillWidth: true
    implicitHeight: dense ? 28 : 32

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.subtle
        font.family: Theme.displayFont
        font.pixelSize: 12
    }
    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, root.width * 0.72)
        horizontalAlignment: Text.AlignRight
        text: root.value
        color: root.valueColor
        font.family: Theme.fontFamily
        font.pixelSize: 12
        elide: Text.ElideRight
    }
    Rectangle {
        visible: !root.last
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.highlightLow
    }
}
