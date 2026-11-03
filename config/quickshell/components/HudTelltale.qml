import QtQuick
import QtQuick.Layouts

import "."

// A dashboard indicator lamp: glows in `accent` when on, dark when off. Clickable.
Rectangle {
    id: lamp
    property string icon
    property string label
    property string detail
    property bool on: false
    property bool selected: false
    property color accent: Theme.iris
    signal activated()

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: 52
    radius: 10
    color: on ? Theme.alpha(accent, hover.hovered ? 0.16 : 0.1) : hover.hovered ? F1Hub.fill : "transparent"
    border.width: 1
    border.color: selected ? Theme.alpha(Theme.foreground, 0.6) : on ? Theme.alpha(accent, 0.35) : F1Hub.hairline
    Behavior on color { ColorAnimation { duration: 180 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 9
        Item {
            implicitWidth: 22
            implicitHeight: 22
            Text {
                anchors.centerIn: parent
                text: lamp.icon
                color: lamp.accent
                opacity: lamp.on ? 0.35 : 0
                font.family: Theme.fontFamily
                font.pixelSize: 24
            }
            Text {
                anchors.centerIn: parent
                text: lamp.icon
                color: lamp.on ? lamp.accent : F1Hub.ink3
                font.family: Theme.fontFamily
                font.pixelSize: 18
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: lamp.label.toUpperCase()
                color: lamp.on ? F1Hub.ink : F1Hub.ink2
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.4
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: lamp.detail
                visible: text !== ""
                color: F1Hub.ink3
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: lamp.activated() }
}
