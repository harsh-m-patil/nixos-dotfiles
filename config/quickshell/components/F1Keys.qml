import QtQuick

import "."

// Keyboard hints: [["⇥", "Next page"], …] rendered as keycaps.
Row {
    property var hints: []
    spacing: 16

    Repeater {
        model: parent.hints
        Row {
            required property var modelData
            spacing: 6
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(20, cap.implicitWidth + 10)
                height: 20
                radius: 5
                color: F1Hub.fillStrong
                border.width: 1
                border.color: F1Hub.fillStrong
                F1Text { id: cap; anchors.centerIn: parent; text: modelData[0]; role: "caption"; tone: "secondary"; numeric: true }
            }
            F1Text { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; role: "caption"; tone: "tertiary" }
        }
    }
}
