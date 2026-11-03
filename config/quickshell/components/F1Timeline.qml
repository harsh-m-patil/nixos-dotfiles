import QtQuick
import QtQuick.Layouts

import "."

// The weekend's sessions on one track line, filled up to "now".
Item {
    id: tl
    readonly property var sessions: F1Data.sessions
    readonly property int n: sessions.length
    readonly property real fill: {
        if (n < 2) return 0
        const now = F1Data.now
        let i = sessions.findIndex(s => now < s.end)
        if (i < 0) return 1
        const s = sessions[i]
        if (now >= s.start) return i / (n - 1)
        if (i === 0) return 0
        const prev = sessions[i - 1]
        return (i - 1 + (now - prev.end) / (s.start - prev.end)) / (n - 1)
    }
    readonly property real inset: width / n / 2

    Layout.fillWidth: true
    implicitHeight: 52
    visible: n > 0

    Rectangle {
        x: tl.inset
        y: 7
        width: tl.width - tl.inset * 2
        height: 2
        radius: 1
        color: F1Hub.fillStrong
        Rectangle {
            width: parent.width * tl.fill
            height: parent.height
            radius: 1
            color: F1Data.mode === "live" ? Theme.love : F1Hub.ink
            opacity: 0.7
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        }
    }

    Row {
        anchors.fill: parent
        Repeater {
            model: tl.sessions
            Item {
                id: stop
                required property var modelData
                readonly property bool done: modelData.end <= F1Data.now
                readonly property bool live: F1Data.liveSession === modelData
                readonly property bool next: F1Data.nextSession === modelData
                width: tl.width / tl.n
                height: tl.height

                Rectangle {
                    id: dot
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 8 - height / 2
                    width: parent.live || parent.next ? 12 : 8
                    height: width
                    radius: width / 2
                    color: parent.live ? Theme.love : parent.done ? F1Hub.ink : F1Hub.surface
                    border.width: parent.done || parent.live ? 0 : 1.5
                    border.color: parent.next ? F1Hub.ink : Theme.alpha(Theme.foreground, 0.3)
                    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
                    SequentialAnimation on opacity {
                        running: stop.live
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) dot.opacity = 1
                        NumberAnimation { to: 0.35; duration: 800; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
                    }
                }
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    spacing: 1
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        role: "footnote"
                        tone: parent.parent.done && !parent.parent.live ? "tertiary" : "primary"
                        font.weight: parent.parent.next || parent.parent.live ? Font.DemiBold : Font.Medium
                    }
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(modelData.start, "ddd HH:mm")
                        role: "caption"
                        tone: "tertiary"
                        numeric: true
                    }
                }
            }
        }
    }
}
