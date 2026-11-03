import QtQuick
import QtQuick.Layouts

import "."

Rectangle {
    property string text
    property color tint: Theme.subtle
    property bool filled: false
    implicitWidth: pillText.implicitWidth + 14
    implicitHeight: 20
    radius: 10
    color: filled ? tint : Qt.rgba(tint.r, tint.g, tint.b, 0.14)
    Text {
        id: pillText
        anchors.centerIn: parent
        text: parent.text
        color: parent.filled ? Theme.background : parent.tint
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.weight: Font.Bold
    }
}
