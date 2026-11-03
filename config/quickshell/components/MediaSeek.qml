import QtQuick
import QtQuick.Layouts

import "."

// Progress bar with elapsed / remaining times. Drag or click to seek when `interactive`.
ColumnLayout {
    id: seek
    property bool interactive: true
    property bool dragging: false
    property real dragPos: 0
    readonly property real shown: dragging ? dragPos : Media.progress

    spacing: 6

    Item {
        Layout.fillWidth: true
        implicitHeight: 14

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: seek.dragging || hover.hovered ? 6 : 4
            radius: height / 2
            color: F1Hub.fillStrong
            Behavior on height { NumberAnimation { duration: 140 } }

            Rectangle {
                height: parent.height
                radius: parent.radius
                width: Math.max(parent.height, parent.width * seek.shown)
                color: seek.dragging || hover.hovered ? Media.accent : F1Hub.ink2
                Behavior on color { ColorAnimation { duration: 140 } }
            }
        }

        HoverHandler { id: hover; enabled: seek.interactive && Media.canSeek; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            anchors.fill: parent
            enabled: seek.interactive && Media.canSeek
            preventStealing: true
            onPressed: m => { seek.dragging = true; seek.dragPos = Math.max(0, Math.min(1, m.x / width)) }
            onPositionChanged: m => { if (pressed) seek.dragPos = Math.max(0, Math.min(1, m.x / width)) }
            onReleased: { Media.seekTo(seek.dragPos); seek.dragging = false }
            onCanceled: seek.dragging = false
        }
    }

    RowLayout {
        Layout.fillWidth: true
        F1Text {
            text: Fmt.clock(seek.dragging ? Media.length * seek.dragPos : Media.position)
            role: "caption"; tone: "tertiary"; numeric: true
            Layout.fillWidth: true
        }
        F1Text {
            text: Media.length > 0 ? "-" + Fmt.clock(Media.length * (1 - seek.shown)) : "Live"
            role: "caption"; tone: "tertiary"; numeric: true
        }
    }
}
