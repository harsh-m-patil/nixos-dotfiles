import QtQuick
import QtQuick.Layouts

import "."

Rectangle {
    default property alias content: inner.data
    property int pad: 12
    Layout.fillWidth: true
    implicitHeight: inner.implicitHeight + pad * 2
    radius: 12
    color: Theme.surface
    border.width: 1
    border.color: Theme.highlightLow
    ColumnLayout {
        id: inner
        anchors.fill: parent
        anchors.margins: parent.pad
        spacing: 6
    }
}
