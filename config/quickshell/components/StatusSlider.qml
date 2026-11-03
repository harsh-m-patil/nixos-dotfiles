import QtQuick
import QtQuick.Layouts

import "."

// A wide Control Center slider: the fill is the track, the glyph sits inside it.
// Drag or scroll to change; `icon` taps run `iconTapped` (mute).
Rectangle {
    id: slider
    property string icon
    property string title
    property real value: 0              // 0…1
    property bool selected: false
    property bool dimmed: false
    signal moved(real value)
    signal iconTapped()

    Layout.fillWidth: true
    implicitHeight: 44
    radius: 22
    color: F1Hub.fill
    border.width: 1
    border.color: selected ? Theme.alpha(Theme.iris, 0.7) : F1Hub.fill

    Rectangle {
        id: fill
        x: 0
        height: parent.height
        width: Math.max(height, parent.width * Math.min(1, slider.value))
        radius: slider.radius
        color: slider.dimmed ? F1Hub.fillStrong : Theme.alpha(F1Hub.ink, 0.86)
        Behavior on width { enabled: !drag.active; SpringAnimation { spring: 4; damping: 0.4; epsilon: 0.3 } }
    }

    Text {
        x: 15
        anchors.verticalCenter: parent.verticalCenter
        text: slider.icon
        color: slider.dimmed ? F1Hub.ink2 : F1Hub.surface
        font.family: Theme.fontFamily
        font.pixelSize: 17
        TapHandler { onTapped: slider.iconTapped() }
    }
    F1Text {
        x: 44
        anchors.verticalCenter: parent.verticalCenter
        text: slider.title
        role: "footnote"
        font.weight: Font.DemiBold
        color: fill.width > x + implicitWidth ? (slider.dimmed ? F1Hub.ink2 : F1Hub.surface) : F1Hub.ink2
    }
    F1Text {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(slider.value * 100) + "%"
        role: "footnote"
        numeric: true
        color: fill.width > parent.width - 50 ? F1Hub.surface : F1Hub.ink2
    }

    DragHandler {
        id: drag
        target: null
        xAxis.enabled: true
        yAxis.enabled: false
        cursorShape: Qt.PointingHandCursor
        onCentroidChanged: if (active) slider.moved(Math.max(0, Math.min(1, centroid.position.x / slider.width)))
    }
    TapHandler {
        onTapped: (point) => slider.moved(Math.max(0, Math.min(1, point.position.x / slider.width)))
    }
    WheelHandler {
        onWheel: e => slider.moved(Math.max(0, Math.min(1, slider.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
