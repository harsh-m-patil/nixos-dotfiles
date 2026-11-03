import QtQuick
import QtQuick.Layouts

import "."

// Daily spend bars for the cycle so far. Bars stretch to fill; `current` is highlighted.
Item {
    id: chart
    property var days: []
    property int current: -1
    property bool labels: true
    signal picked(int index)

    readonly property real peak: Math.max(0.01, ...days.map(d => d.cost))

    Layout.fillWidth: true
    implicitHeight: 120

    RowLayout {
        anchors.fill: parent
        spacing: chart.days.length > 20 ? 3 : 5

        Repeater {
            model: chart.days
            Item {
                id: col
                required property var modelData
                required property int index
                readonly property bool sel: index === chart.current
                Layout.fillWidth: true
                Layout.fillHeight: true

                F1Text {
                    id: dayLabel
                    visible: chart.labels
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: col.modelData.day.slice(8).replace(/^0/, "")
                    role: "caption"
                    tone: col.sel ? "primary" : "tertiary"
                    numeric: true
                }
                Rectangle {
                    anchors.bottom: chart.labels ? dayLabel.top : parent.bottom
                    anchors.bottomMargin: chart.labels ? 4 : 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width, 22)
                    readonly property real room: parent.height - (chart.labels ? dayLabel.height + 4 : 0)
                    height: Math.max(3, room * col.modelData.cost / chart.peak)
                    radius: Math.min(4, width / 2)
                    color: col.sel || tapHover.hovered ? Theme.iris
                        : col.modelData.cost > 0 ? Theme.alpha(Theme.iris, 0.45) : F1Hub.fillStrong
                    Behavior on height { SequentialAnimation { PauseAnimation { duration: Math.min(col.index, 12) * 20 } NumberAnimation { duration: 300; easing.type: Easing.OutQuint } } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                HoverHandler { id: tapHover }
                TapHandler { onTapped: chart.picked(col.index) }
            }
        }
    }
}
