import QtQuick

import "."

// Round glyph button. `primary` draws a filled disc (play / pause); `accent` marks an on state.
Item {
    id: root

    property string icon: ""
    property bool enabled: true
    property bool accent: false
    property bool primary: false
    property int iconSize: Theme.fontSize
    property int size: iconSize + 14
    signal activated()

    implicitWidth: size
    implicitHeight: size
    opacity: enabled ? 1 : 0.35

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.primary ? F1Hub.ink
            : root.accent ? Theme.alpha(Theme.iris, 0.16)
            : hover.hovered && root.enabled ? F1Hub.fillStrong : "transparent"
        scale: tap.pressed ? 0.94 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuint } }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Theme.fontFamily
        font.pixelSize: root.iconSize
        color: root.primary ? F1Hub.surface : root.accent ? Theme.iris : hover.hovered ? F1Hub.ink : F1Hub.ink2
        scale: tap.pressed ? 0.94 : 1
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuint } }
    }

    HoverHandler { id: hover; enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; enabled: root.enabled; onTapped: root.activated() }
}
