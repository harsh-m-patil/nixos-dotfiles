import QtQuick

import "."

Row {
    id: root

    property string value: ""
    property string unit: ""
    property int size: 32
    property int weight: Font.Medium
    property color color: Theme.foreground
    property color unitColor: Theme.subtle

    spacing: Math.round(size * 0.1)

    Text {
        id: num
        text: root.value
        color: root.color
        font.family: Theme.displayFont
        font.pixelSize: root.size
        font.weight: root.weight
        font.letterSpacing: -root.size * 0.02
        font.features: { "tnum": 1 }
    }
    Text {
        visible: root.unit !== ""
        anchors.baseline: num.baseline
        text: root.unit
        color: root.unitColor
        font.family: Theme.displayFont
        font.pixelSize: Math.round(root.size * 0.45)
        font.weight: Font.Normal
    }
}
