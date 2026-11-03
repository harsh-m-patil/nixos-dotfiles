import QtQuick
import QtQuick.Layouts

import "."

ColumnLayout {
    id: root

    property string icon: ""
    property string label: ""
    property string value: ""
    property real fraction: -1
    property color accent: Theme.iris
    property int valueWidth: 0

    spacing: 5
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: root.icon
            color: root.accent
            font.family: Theme.fontFamily
            font.pixelSize: 14
        }
        Text {
            text: root.label
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
        Item { Layout.fillWidth: true }
        Text {
            text: root.value
            Layout.preferredWidth: root.valueWidth
            Layout.minimumWidth: root.valueWidth
            horizontalAlignment: Text.AlignRight
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }

    Rectangle {
        visible: root.fraction >= 0
        Layout.fillWidth: true
        implicitHeight: 5
        radius: 3
        color: Theme.highlightLow

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.fraction))
            height: parent.height
            radius: parent.radius
            color: root.fraction > 0.85 ? Theme.love : root.fraction > 0.65 ? Theme.gold : root.accent
            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }
}
