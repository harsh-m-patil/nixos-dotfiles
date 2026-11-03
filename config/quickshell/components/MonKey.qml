import QtQuick
import QtQuick.Layouts

import "."

RowLayout {
    id: root

    property string label: ""
    property string value: ""
    property color accent: Theme.iris

    spacing: 6

    Rectangle {
        implicitWidth: 8
        implicitHeight: 8
        radius: 2
        color: root.accent
    }
    Text {
        text: root.label
        color: Theme.subtle
        font.family: Theme.displayFont
        font.pixelSize: 11
    }
    Text {
        visible: root.value !== ""
        text: root.value
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }
}
