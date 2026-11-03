import QtQuick
import QtQuick.Layouts

import "."

Rectangle {
    id: tile
    property string label
    property string value
    property string sub
    // constructorId of the driver/team the tile is about; tints the tile in their colour
    property string team
    readonly property color tint: F1Data.teamColours[team] ?? "transparent"
    readonly property bool tinted: team !== "" && F1Data.teamColours[team] !== undefined
    property bool stretch: false
    property int fixedHeight: 0
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitWidth: 200
    implicitHeight: fixedHeight > 0 ? fixedHeight : tileContent.implicitHeight + 22
    Layout.minimumHeight: implicitHeight
    Layout.fillHeight: stretch
    radius: 10
    color: tinted ? Qt.rgba(tint.r, tint.g, tint.b, 0.18) : Theme.surface
    border.width: 1
    border.color: tinted ? Qt.rgba(tint.r, tint.g, tint.b, 0.55) : Theme.highlightLow

    ColumnLayout {
        id: tileContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 2
        F1Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: tile.label
            color: tile.tinted ? Qt.lighter(tile.tint, 1.3) : Theme.muted
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: tile.value || "—"
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: text !== ""
            text: tile.sub
            color: Theme.subtle
            font.family: Theme.fontFamily
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }
}
