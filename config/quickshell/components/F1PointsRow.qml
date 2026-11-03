import QtQuick
import QtQuick.Layouts

import "."

Item {
    property int position
    property string name
    property real points
    property real leader: 1
    property color tint: Theme.iris
    property string logo
    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: 28

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        height: 24
        radius: 5
        width: Math.max(24, (parent.width - 24) * parent.points / Math.max(1, parent.leader))
        color: Qt.rgba(parent.tint.r, parent.tint.g, parent.tint.b, 0.22)
        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Rectangle { width: 3; height: parent.height; radius: 1.5; color: parent.parent.tint }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        horizontalAlignment: Text.AlignRight
        text: parent.position
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.weight: Font.Bold
    }
    Image {
        id: pointsLogo
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 30
        width: parent.logo ? 24 : 0
        height: 20
        source: parent.logo
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: pointsLogo.right
        anchors.leftMargin: 6
        text: parent.name
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 6
        text: parent.points
        color: Theme.subtle
        font.family: "monospace"
        font.pixelSize: 12
    }
}
