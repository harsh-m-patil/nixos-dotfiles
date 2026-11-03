import QtQuick
import QtQuick.Layouts

import "."

// A Control Center toggle: round glyph, title and state line. Filled with the accent when on.
Rectangle {
    id: tile
    property string icon
    property string title
    property string detail
    property bool on: false
    property bool selected: false
    property color accent: Theme.iris
    signal activated()

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: 60
    radius: 16
    color: hover.hovered ? F1Hub.fillStrong : F1Hub.fill
    border.width: 1
    border.color: selected ? Theme.alpha(Theme.iris, 0.7) : F1Hub.fill
    scale: tap.pressed ? 0.97 : 1
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutQuint } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Rectangle {
            implicitWidth: 34
            implicitHeight: 34
            radius: 17
            color: tile.on ? tile.accent : F1Hub.fillStrong
            Behavior on color { ColorAnimation { duration: 160 } }
            Text {
                anchors.centerIn: parent
                text: tile.icon
                color: tile.on ? Theme.background : F1Hub.ink2
                font.family: Theme.fontFamily
                font.pixelSize: 16
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            F1Text { text: tile.title; role: "footnote"; font.weight: Font.DemiBold; Layout.fillWidth: true }
            F1Text { text: tile.detail; role: "caption"; tone: "secondary"; Layout.fillWidth: true }
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: tile.activated() }
}
