import QtQuick

import "."

// Odometer readout: each character of `text` is clipped to its own slot; digits roll in when they change.
Column {
    id: odo
    property string label
    property string text
    property string sub
    property int cell: 16
    property color accent: Theme.iris
    spacing: 2

    Text {
        text: odo.label
        color: F1Hub.ink2
        font.family: Theme.displayFont
        font.pixelSize: 11
        font.weight: Font.Medium
    }
    Row {
        spacing: 0
        Repeater {
            model: odo.text.length
            Item {
                required property int index
                readonly property string modelData: odo.text.charAt(index)
                readonly property bool digit: /[0-9]/.test(modelData)
                width: digit ? odo.cell * 0.68 : glyph.implicitWidth + 1
                height: odo.cell * 1.35
                clip: true
                Text {
                    id: glyph
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: parent.digit ? F1Hub.ink : F1Hub.ink3
                    font.family: Theme.displayFont
                    font.pixelSize: odo.cell * 1.15
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                    transform: Translate { id: shift }
                    onTextChanged: {
                        if (Motion.reduced) {
                            shift.y = 0
                            return
                        }
                        roll.restart()
                    }
                    ParallelAnimation {
                        id: roll
                        NumberAnimation {
                            target: shift; property: "y"
                            from: -odo.cell * 0.9; to: 0
                            duration: 420; easing.type: Easing.OutQuint
                        }
                        NumberAnimation {
                            target: glyph; property: "opacity"
                            from: 0; to: 1
                            duration: 260; easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
    Text {
        visible: odo.sub !== ""
        text: odo.sub
        color: F1Hub.ink3
        font.family: Theme.displayFont
        font.pixelSize: 10
    }
}
