import QtQuick
import QtQuick.Layouts

import "."

Item {
    id: root

    property string icon: ""
    property string label: ""
    property color fg: Theme.subtle
    property bool clickable: true

    signal clicked()
    signal wheelUp()
    signal wheelDown()

    readonly property bool hovered: iconHover.hovered

    HoverHandler { id: iconHover }

    implicitWidth: row.implicitWidth
    implicitHeight: 28

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            text: root.icon + (root.label !== "" ? " " + root.label : "")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: root.fg
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: true
        onClicked: root.clicked()
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                root.wheelUp()
            else if (wheel.angleDelta.y < 0)
                root.wheelDown()
        }
    }
}
