import QtQuick

import "."

Rectangle {
    id: root

    property int col: 0
    property int row: 0
    property int colSpan: 1
    property int rowSpan: 1
    property real cellW: 100
    property real cellH: 100
    property real gap: 12
    property bool pressable: false
    signal clicked()

    x: col * (cellW + gap)
    y: row * (cellH + gap)
    width: colSpan * cellW + (colSpan - 1) * gap
    height: rowSpan * cellH + (rowSpan - 1) * gap
    radius: F1Hub.tileRadius
    color: F1Hub.fill
    scale: tap.pressed ? 0.98 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    TapHandler {
        id: tap
        enabled: root.pressable
        onTapped: root.clicked()
    }
    HoverHandler { enabled: root.pressable; cursorShape: Qt.PointingHandCursor }
}
