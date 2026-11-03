import QtQuick

import "."

Item {
    id: root

    property string icon: ""
    property bool enabled: true
    property bool accent: false
    property int iconSize: Theme.fontSize
    signal activated()

    property real pressScale: 1
    property bool hovered: false

    implicitWidth: iconSize + 12
    implicitHeight: 24

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Theme.fontFamily
        font.pixelSize: root.iconSize
        color: !root.enabled ? Theme.muted
            : (root.accent ? Theme.iris : (root.hovered ? Theme.foreground : Theme.subtle))
        scale: root.pressScale
        Behavior on scale { NumberAnimation { duration: 100 } }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onPressed: root.pressScale = 0.88
        onReleased: root.pressScale = 1
        onCanceled: root.pressScale = 1
        onClicked: root.activated()
    }
}
