import QtQuick
import QtQuick.Layouts

import "."

ColumnLayout {
    id: root

    property string label: ""
    property string value: ""
    property color accent: Theme.foreground

    Layout.fillWidth: true
    spacing: 4

    Text {
        text: root.label
        color: Theme.muted
        font.family: Theme.displayFont
        font.pixelSize: 11
    }
    Text {
        Layout.fillWidth: true
        text: root.value
        color: root.accent
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.weight: Font.Medium
        elide: Text.ElideRight
    }
}
