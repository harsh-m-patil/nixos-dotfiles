import QtQuick
import QtQuick.Layouts

import "."

Rectangle {
    id: driverTile
    property string code
    property string name
    property string value
    property string sub
    property string photo: ""
    property bool compact: false
    property bool stretch: false
    readonly property color tint: F1Data.driverColour(code)
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.fillHeight: stretch
    implicitHeight: stretch ? 120 : (compact ? 96 : 132)
    radius: 12
    color: Qt.rgba(tint.r, tint.g, tint.b, 0.16)
    border.width: 1
    border.color: Qt.rgba(tint.r, tint.g, tint.b, 0.5)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: compact ? 8 : 10
        spacing: 4

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: driverTile.stretch
            Layout.preferredHeight: driverTile.stretch ? -1 : (driverTile.compact ? 52 : 76)
            Layout.minimumHeight: driverTile.compact ? 52 : 76

            Image {
                anchors.centerIn: parent
                width: parent.width - 8
                height: parent.height - 4
                source: driverTile.photo || F1Data.headshotFor(driverTile.code, F1Data.myTeamName)
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                asynchronous: true
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: driverTile.code
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: 15
            font.weight: Font.Black
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: driverTile.value
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: text !== ""
            text: driverTile.sub
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }
}
