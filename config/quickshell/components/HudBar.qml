import QtQuick
import QtQuick.Layouts

import "."

// An LED-segment level meter. Drag, tap or scroll to set; tapping the glyph runs `iconTapped`.
Item {
    id: bar
    property string icon
    property string label
    property real value: 0              // 0…1
    property bool interactive: true
    property bool selected: false
    property bool dimmed: false
    property color accent: Theme.iris
    property real warnAbove: 2          // segments past this fraction light in love
    property int segments: 20
    signal moved(real value)
    signal iconTapped()

    Layout.fillWidth: true
    implicitHeight: 38
    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * segments)

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: "transparent"
        border.width: 1
        border.color: bar.selected ? Theme.alpha(Theme.foreground, 0.6) : F1Hub.hairline
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8
        Text {
            text: bar.icon
            color: bar.dimmed ? F1Hub.ink3 : bar.accent
            font.family: Theme.fontFamily
            font.pixelSize: 15
            TapHandler { onTapped: bar.iconTapped() }
        }
        Text {
            text: bar.label.toUpperCase()
            color: F1Hub.ink2
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 1.4
            Layout.preferredWidth: 34
        }
        Item {
            id: track
            Layout.fillWidth: true
            Layout.fillHeight: true
            Row {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: 2
                Repeater {
                    model: bar.segments
                    Rectangle {
                        required property int index
                        readonly property bool on: index < bar.lit
                        width: (track.width - (bar.segments - 1) * 2) / bar.segments
                        height: 12
                        radius: 2
                        color: !on ? Theme.alpha(Theme.foreground, 0.07)
                            : bar.dimmed ? F1Hub.ink3
                            : (index + 1) / bar.segments > bar.warnAbove ? Theme.love : bar.accent
                        Behavior on color { enabled: !Motion.reduced; ColorAnimation { duration: 90 } }
                    }
                }
            }
            DragHandler {
                enabled: bar.interactive
                target: null
                yAxis.enabled: false
                cursorShape: Qt.PointingHandCursor
                onCentroidChanged: if (active) bar.moved(Math.max(0, Math.min(1, centroid.position.x / track.width)))
            }
            TapHandler {
                enabled: bar.interactive
                onTapped: p => bar.moved(Math.max(0, Math.min(1, p.position.x / track.width)))
            }
            WheelHandler {
                enabled: bar.interactive
                onWheel: e => bar.moved(Math.max(0, Math.min(1, bar.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
            }
        }
        Text {
            text: Math.round(bar.value * 100)
            color: bar.dimmed ? F1Hub.ink3 : F1Hub.ink
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 26
        }
    }
}
