import QtQuick
import QtQuick.Layouts

import "."

// One agenda line: leading time, title, trailing status. Live sessions get a pulsing dot.
Item {
    id: ev
    property string time
    property string title
    property string value
    property bool live: false
    property bool past: false
    property bool accent: false
    property bool separator: true

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 34
    Layout.maximumHeight: 46
    implicitHeight: 34

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12
        opacity: ev.past ? 0.55 : 1

        F1Text { text: ev.time; role: "callout"; tone: "secondary"; numeric: true; Layout.preferredWidth: 38 }
        Rectangle {
            implicitWidth: 6; implicitHeight: 6; radius: 3
            color: ev.live ? Theme.love : ev.accent ? Theme.gold : F1Hub.ink3
            SequentialAnimation on opacity {
                running: ev.live
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
            }
        }
        F1Text { text: ev.title; role: "body"; font.weight: ev.accent ? Font.DemiBold : Font.Medium; Layout.fillWidth: true }
        F1Text {
            text: ev.live ? "Live" : ev.value
            visible: text !== ""
            role: "callout"
            numeric: true
            color: ev.live ? Theme.love : F1Hub.ink2
        }
    }

    Rectangle {
        visible: ev.separator
        anchors.bottom: parent.bottom
        x: 64
        width: parent.width - 64
        height: 1
        color: F1Hub.fill
    }
}
