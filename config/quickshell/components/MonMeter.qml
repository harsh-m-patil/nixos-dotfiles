import QtQuick
import QtQuick.Layouts

import "."

ColumnLayout {
    id: root

    property string label: ""
    property string value: ""
    property real fraction: 0
    property color accent: Theme.iris

    Layout.fillWidth: true
    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: root.label
            color: Theme.subtle
            font.family: Theme.displayFont
            font.pixelSize: 11
        }
        Item { Layout.fillWidth: true }
        Text {
            text: root.value
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }
    MonBar { value: root.fraction; fill: root.accent }
}
