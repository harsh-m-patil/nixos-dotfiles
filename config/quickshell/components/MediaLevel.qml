import QtQuick

import "."

// A small animated level meter, like the Live Activity waveform. Flat when paused;
// animates only while visible and playing.
Row {
    id: level
    property int bars: 4
    property real barWidth: 3
    property real maxHeight: 14
    property color color: Media.accent
    readonly property bool running: Media.playing && visible

    spacing: 2
    height: maxHeight

    property real phase: 0
    Timer {
        interval: 90
        repeat: true
        running: level.running
        onTriggered: level.phase += 1
    }

    Repeater {
        model: level.bars
        Rectangle {
            required property int index
            readonly property real amp: level.running
                ? 0.25 + 0.75 * Math.abs(Math.sin(level.phase * (0.55 + index * 0.23) + index * 1.7) * Math.cos(level.phase * 0.31 + index))
                : 0.18
            anchors.verticalCenter: parent.verticalCenter
            width: level.barWidth
            height: Math.max(level.barWidth, level.maxHeight * amp)
            radius: width / 2
            color: level.color
            opacity: level.running ? 1 : 0.5
            Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        }
    }
}
