import QtQuick

import "."

Row {
    property var hints: []
    spacing: 18

    Repeater {
        model: parent.hints
        Row {
            required property var modelData
            spacing: 6
            Rectangle {
                width: keyText.implicitWidth + 12
                height: 20
                radius: 5
                color: Qt.rgba(0, 0, 0, 0.6)
                Text {
                    id: keyText
                    anchors.centerIn: parent
                    text: modelData[0]
                    color: "#ffffff"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: modelData[1]
                color: "#ffffff"
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.55)
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
    }
}
