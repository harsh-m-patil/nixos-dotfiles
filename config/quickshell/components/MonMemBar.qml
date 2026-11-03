import QtQuick
import QtQuick.Layouts

import "."

Item {
    id: root

    readonly property var d: SystemData
    readonly property real used: d.memTotal > 0 ? d.memUsed / d.memTotal : 0
    readonly property real cache: d.memTotal > 0 ? Math.min(1 - used, d.memCache / d.memTotal) : 0

    Layout.fillWidth: true
    implicitHeight: 8

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: Theme.highlightLow
    }
    Rectangle {
        id: usedSeg
        width: parent.width * root.used
        height: parent.height
        radius: 2
        color: Theme.foam
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    }
    Rectangle {
        x: usedSeg.width + 2
        width: Math.max(0, parent.width * root.cache - 2)
        height: parent.height
        radius: 2
        color: Theme.alpha(Theme.foam, 0.35)
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    }
}
