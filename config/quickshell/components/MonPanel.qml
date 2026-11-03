import QtQuick
import QtQuick.Layouts

import "."

Rectangle {
    id: root

    property string title: ""
    property string icon: ""
    property string trailing: ""
    property color accent: Theme.iris
    property real padding: 16
    property bool trailingLink: false
    default property alias content: body.data
    signal trailingClicked()

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignTop
    implicitHeight: body.implicitHeight + padding * 2
    radius: F1Hub.tileRadius
    color: F1Hub.fill

    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 14

        RowLayout {
            visible: root.title !== ""
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.icon
                color: root.accent
                font.family: Theme.fontFamily
                font.pixelSize: 14
            }
            Text {
                text: root.title
                color: Theme.foreground
                font.family: Theme.displayFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true }
            Text {
                Layout.maximumWidth: 360
                text: root.trailing
                color: !root.trailingLink ? Theme.muted : linkArea.containsMouse ? Theme.foreground : Theme.iris
                font.family: Theme.displayFont
                font.pixelSize: 11
                font.weight: root.trailingLink ? Font.Medium : Font.Normal
                elide: Text.ElideLeft
                MouseArea {
                    id: linkArea
                    anchors.fill: parent
                    enabled: root.trailingLink
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.trailingClicked()
                }
            }
        }
    }
}
