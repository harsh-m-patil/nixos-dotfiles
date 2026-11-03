import QtQuick
import QtQuick.Layouts

import "."

// A dashboard control tile: icon in a disc that fills with `accent` when on. Clickable.
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
    radius: 14
    scale: press.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: press.pressed ? 60 : 160; easing.type: Easing.OutCubic } }
    color: press.pressed ? F1Hub.fillStrong : hover.hovered ? F1Hub.fillStrong : F1Hub.fill
    border.width: selected ? 1 : 0
    border.color: Theme.alpha(Theme.foreground, 0.5)
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 9
        Rectangle {
            implicitWidth: 32
            implicitHeight: 32
            radius: 16
            color: lamp.on ? lamp.accent : Theme.alpha(Theme.foreground, 0.08)
            Behavior on color { ColorAnimation { duration: 160 } }
            Text {
                anchors.centerIn: parent
                text: lamp.icon
                color: lamp.on ? Theme.background : F1Hub.ink2
                font.family: Theme.fontFamily
                font.pixelSize: 16
                Behavior on color { ColorAnimation { duration: 160 } }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: lamp.label
                color: F1Hub.ink
                font.family: Theme.displayFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: lamp.detail
                visible: text !== ""
                color: F1Hub.ink3
                font.family: Theme.displayFont
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler {
        id: press
        onTapped: lamp.activated()
    }
}
