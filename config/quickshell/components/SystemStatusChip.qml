import QtQuick
import QtQuick.Layouts

import "."

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: 28
    readonly property bool hovered: hover.hovered

    SystemSampler { active: true }

    SystemPopup {
        id: popup
        trigger: root
        triggerHovered: root.hovered
        align: 0.7
        onOpenDetails: SystemData.windowOpen = true
    }

    HoverHandler { id: hover }

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            text: "󰍛"
            color: root.hovered ? Theme.iris : Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            text: "CPU " + Math.round(SystemData.cpu * 100) + "%"
            color: SystemData.cpu > 0.85 ? Theme.love : Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.DemiBold
        }

        Text {
            text: "RAM " + Math.round(SystemData.memFraction * 100) + "%"
            color: SystemData.memFraction > 0.9 ? Theme.love : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: SystemData.windowOpen = !SystemData.windowOpen
    }
}
