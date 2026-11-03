import QtQuick
import QtQuick.Layouts
import Quickshell

import "."

PopupWindow {
    id: popup

    required property Item trigger
    property bool triggerHovered: false
    property bool framed: true
    property int padding: 16
    property int contentMinWidth: 0
    property real align: 0.5
    default property alias content: contentCol.data

    readonly property bool hovered: bodyHover.hovered
    readonly property bool wanted: triggerHovered || hovered || grace.running
    readonly property bool shown: body.opacity > 0.01

    onTriggerHoveredChanged: if (!triggerHovered) grace.restart()
    onHoveredChanged: if (!hovered) grace.restart()

    Timer {
        id: grace
        interval: 220
    }

    anchor.item: trigger
    anchor.rect.x: Math.round(trigger.width * align - width * align)
    anchor.rect.y: trigger.height + 2
    implicitWidth: Math.max(contentMinWidth, contentCol.implicitWidth) + padding * 2 + 16
    implicitHeight: contentCol.implicitHeight + padding * 2 + 16
    color: "transparent"
    visible: wanted || shown

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: 8
        opacity: popup.wanted ? 1 : 0
        scale: Motion.reduced ? 1 : (popup.wanted ? 1 : 0.96)
        transformOrigin: Item.Top
        Behavior on opacity {
            NumberAnimation {
                duration: Motion.reduced ? 150 : 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            enabled: Motion.contentScaleAnim
            NumberAnimation { duration: 200; easing.type: Easing.OutQuint }
        }

        HoverHandler { id: bodyHover }

        Rectangle {
            visible: popup.framed
            anchors.fill: parent
            radius: 16
            color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.97)
            border.width: 1
            border.color: Theme.highlightMed
        }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: popup.framed ? popup.padding : 0
            spacing: popup.framed ? 10 : 0
        }
    }
}
