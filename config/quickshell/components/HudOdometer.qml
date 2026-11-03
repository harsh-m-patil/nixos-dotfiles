import QtQuick

import "."

// Odometer readout: each character of `text` sits in its own drum cell; digits roll when they change.
Column {
    id: odo
    property string label
    property string text
    property string sub
    property int cell: 16
    property color accent: Theme.iris
    spacing: 3

    Text {
        text: odo.label.toUpperCase()
        color: odo.accent
        font.family: Theme.fontFamily
        font.pixelSize: 9
        font.weight: Font.Bold
        font.letterSpacing: 1.8
    }
    Row {
        spacing: 2
        Repeater {
            model: odo.text.length
            Rectangle {
                required property int index
                readonly property string modelData: odo.text.charAt(index)
                readonly property bool digit: /[0-9]/.test(modelData)
                width: digit ? odo.cell : odo.cell * 0.55
                height: odo.cell * 1.45
                radius: 3
                color: digit ? Theme.alpha(Theme.foreground, 0.06) : "transparent"
                border.width: digit ? 1 : 0
                border.color: F1Hub.hairline
                clip: true
                Text {
                    id: glyph
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: parent.digit ? F1Hub.ink : F1Hub.ink3
                    font.family: Theme.fontFamily
                    font.pixelSize: odo.cell * 0.95
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                    transform: Translate { id: shift }
                    onTextChanged: roll.restart()
                    NumberAnimation {
                        id: roll
                        target: shift
                        property: "y"
                        from: -odo.cell * 1.45
                        to: 0
                        duration: 320
                        easing.type: Easing.OutBack
                    }
                }
                Rectangle {
                    visible: parent.digit
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 1
                    color: Theme.alpha(Theme.background, 0.5)
                }
            }
        }
    }
    Text {
        visible: odo.sub !== ""
        text: odo.sub
        color: F1Hub.ink3
        font.family: Theme.fontFamily
        font.pixelSize: 10
    }
}
