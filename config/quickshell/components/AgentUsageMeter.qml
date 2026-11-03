import QtQuick
import QtQuick.Layouts

import "."

// One limit line: label + figure above a thin track filled to `fraction`.
Item {
    id: meter
    property string label
    property string value
    property string detail
    property real fraction: 0
    property color accent: Theme.iris
    Layout.fillWidth: true
    implicitHeight: name.implicitHeight + 8

    F1Text { id: name; text: meter.label; role: "callout"; font.weight: Font.Medium }
    F1Text {
        anchors.left: name.right
        anchors.leftMargin: 10
        anchors.right: figure.left
        anchors.rightMargin: 10
        anchors.baseline: name.baseline
        text: meter.detail
        role: "caption"
        tone: "tertiary"
    }
    F1Text { id: figure; anchors.right: parent.right; text: meter.value; role: "callout"; tone: "secondary"; numeric: true }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 4
        radius: 2
        color: F1Hub.fillStrong
        Rectangle {
            width: Math.max(6, parent.width * Math.max(0, Math.min(1, meter.fraction)))
            height: parent.height
            radius: 2
            color: meter.accent
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        }
    }
}
