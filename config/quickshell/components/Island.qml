import QtQuick
import QtQuick.Layouts

import "."

Rectangle {
    id: root

    default property alias content: contentLayout.data
    property int hPad: 7
    property int vPad: 0

    radius: Theme.islandRadius
    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.islandAlpha)
    border.color: Theme.highlightLow
    border.width: 1

    implicitWidth: contentLayout.implicitWidth + hPad * 2
    implicitHeight: 28
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.leftMargin: root.hPad
        anchors.rightMargin: root.hPad
        anchors.topMargin: root.vPad
        anchors.bottomMargin: root.vPad
        spacing: 6
    }
}
