import QtQuick

import "."

// Peek footer pill — MouseArea so clicks register inside morphing islands.
Rectangle {
    id: btn
    property string label
    property string detail: ""
    signal activated()

    implicitWidth: row.implicitWidth + 22
    implicitHeight: 28
    radius: 14
    z: 50
    color: hover.hovered ? F1Hub.fillStrong : F1Hub.fill
    border.width: 1
    border.color: F1Hub.hairline
    scale: area.pressed ? 0.96 : 1
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutQuint } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        F1Text {
            anchors.verticalCenter: parent.verticalCenter
            text: btn.label
            role: "footnote"
            font.weight: Font.DemiBold
        }
        F1Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: btn.detail !== ""
            text: btn.detail
            role: "caption"
            tone: "tertiary"
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    MouseArea {
        id: area
        anchors.fill: parent
        onClicked: btn.activated()
    }
}
