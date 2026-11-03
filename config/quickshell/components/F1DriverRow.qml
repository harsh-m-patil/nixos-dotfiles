import QtQuick
import QtQuick.Layouts

import "."

Item {
    property int position
    property string code
    property string name
    property string team
    property string value
    property color tint: F1Data.driverColour(code)
    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: rowHover.hovered ? Theme.highlightLow : "transparent"
        HoverHandler { id: rowHover }
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 8
        spacing: 8
        Text {
            text: parent.parent.position
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 16
        }
        Rectangle { implicitWidth: 3; implicitHeight: 14; radius: 1.5; color: parent.parent.tint }
        Text {
            text: parent.parent.name
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            Layout.preferredWidth: 140
        }
        Image {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 20
            source: F1Data.teamLogo(parent.parent.team)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
        }
        Text {
            text: parent.parent.team
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Text {
            text: parent.parent.value
            color: Theme.subtle
            font.family: "monospace"
            font.pixelSize: 12
        }
    }
}
