import QtQuick

import "."

// Segmented meter: `count` slim ticks (rev-counter) or rounded cells (fuel cells), the first share lit.
Item {
    id: meter
    property real value: 0              // 0…1
    property int count: 32
    property bool cells: false
    property color accent: F1Hub.accent
    property real spacing: cells ? 4 : 3
    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * count)
    readonly property real step: (width - spacing * (count - 1)) / count

    implicitHeight: cells ? 22 : 18

    Repeater {
        model: meter.count
        Rectangle {
            required property int index
            readonly property bool on: index < meter.lit
            x: index * (meter.step + meter.spacing)
            width: Math.max(1, meter.step)
            height: meter.height
            radius: meter.cells ? Math.min(6, width / 2) : 1
            color: on ? meter.accent : F1Hub.track
            Behavior on color {
                enabled: !Motion.reduced
                SequentialAnimation {
                    PauseAnimation { duration: index * 8 }
                    ColorAnimation { duration: 160 }
                }
            }
        }
    }
}
