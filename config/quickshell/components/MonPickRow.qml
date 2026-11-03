import QtQuick
import QtQuick.Layouts

import "."

Item {
    id: root

    property string title: ""
    property string detail: ""
    property string icon: ""
    property bool active: false
    property bool last: false
    signal activated()

    Layout.fillWidth: true
    implicitHeight: 32

    Rectangle {
        id: hit
        anchors.fill: parent
        radius: 8
        color: hover.hovered ? Theme.alpha(Theme.foreground, 0.06) : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 6
            spacing: 8

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: root.active ? Theme.foam : "transparent"
                border.width: root.active ? 0 : 1
                border.color: Theme.alpha(Theme.foreground, 0.18)
            }
            Text {
                visible: root.icon !== ""
                text: root.icon
                color: root.active ? Theme.foam : Theme.subtle
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Text {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                color: root.active ? Theme.foreground : Theme.subtle
                font.family: Theme.displayFont
                font.pixelSize: 12
                font.weight: root.active ? Font.DemiBold : Font.Normal
            }
            Text {
                text: root.detail
                color: Theme.muted
                font.family: Theme.displayFont
                font.pixelSize: 11
                elide: Text.ElideLeft
                Layout.maximumWidth: 120
            }
        }

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.activated() }
    }

    Rectangle {
        visible: !root.last
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.highlightLow
    }
}
