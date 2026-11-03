import QtQuick
import Quickshell.Io

import "."

Item {
    id: root

    property int bars: 14
    property bool playing: false
    property real barWidth: 2.5
    property real gap: 2
    property color colorA: Theme.iris
    property color colorB: Theme.foam

    property var levels: []
    property bool cavaAlive: false
    property real phase: 0

    implicitWidth: bars * barWidth + (bars - 1) * gap
    implicitHeight: 18

    Process {
        id: cava
        running: root.playing
        command: ["sh", "-c",
            "command -v cava >/dev/null || exit 127; " +
            "conf=$(mktemp); printf '[general]\\nbars=" + root.bars + "\\nframerate=60\\n" +
            "[input]\\nmethod=pipewire\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\n" +
            "data_format=ascii\\nascii_max_range=100\\nbar_delimiter=59\\nframe_delimiter=10\\n" +
            "[smoothing]\\nnoise_reduction=55\\n' > \"$conf\"; exec cava -p \"$conf\""]
        stdout: SplitParser {
            onRead: data => {
                root.cavaAlive = true
                root.levels = data.split(";").filter(s => s !== "").map(v => Math.min(1, parseInt(v) / 100))
            }
        }
        onExited: root.cavaAlive = false
    }

    Timer {
        interval: 33
        repeat: true
        running: root.playing && !root.cavaAlive && root.visible
        onTriggered: {
            root.phase += 0.18
            const out = []
            for (let i = 0; i < root.bars; i++) {
                const a = Math.sin(root.phase + i * 0.55)
                const b = Math.sin(root.phase * 1.7 - i * 0.9)
                const c = Math.sin(root.phase * 0.6 + i * 1.3)
                out.push(Math.max(0.08, Math.abs(a * 0.5 + b * 0.3 + c * 0.2)))
            }
            root.levels = out
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: root.gap

        Repeater {
            model: root.bars

            Rectangle {
                required property int index
                readonly property real level: root.playing ? (root.levels[index] ?? 0.1) : 0.12

                anchors.verticalCenter: parent.verticalCenter
                width: root.barWidth
                height: Math.max(2, root.height * level)
                radius: width / 2
                color: Qt.rgba(
                    root.colorA.r + (root.colorB.r - root.colorA.r) * index / root.bars,
                    root.colorA.g + (root.colorB.g - root.colorA.g) * index / root.bars,
                    root.colorA.b + (root.colorB.b - root.colorA.b) * index / root.bars,
                    root.playing ? 0.95 : 0.45)

                Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 250 } }
            }
        }
    }
}
