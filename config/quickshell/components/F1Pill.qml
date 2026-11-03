import QtQuick

import "."

// Range bar: a rounded track with a gradient fill that springs to its share.
Rectangle {
    id: pill
    property real value: 0              // 0…1
    property color accent: F1Hub.accent

    implicitHeight: 10
    radius: height / 2
    color: F1Hub.track

    property real shown: Math.max(0, Math.min(1, value))
    Behavior on shown {
        enabled: !Motion.reduced
        SpringAnimation { spring: 3; damping: 1.0; epsilon: 0.001 }
    }

    Rectangle {
        width: Math.max(pill.height, pill.width * pill.shown)
        height: parent.height
        radius: parent.radius
        visible: pill.shown > 0.001
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.darker(pill.accent, 1.8) }
            GradientStop { position: 1; color: pill.accent }
        }
    }
}
