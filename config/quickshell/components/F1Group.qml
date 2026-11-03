import QtQuick
import QtQuick.Layouts

import "."

// An inset grouped section: optional header above a rounded, softly filled panel.
ColumnLayout {
    id: group
    property string title
    property string detail
    property int pad: 0
    default property alias content: body.data
    spacing: 6

    RowLayout {
        visible: group.title !== ""
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        F1Text { text: group.title; role: "footnote"; tone: "secondary"; Layout.fillWidth: true }
        F1Text { text: group.detail; role: "footnote"; tone: "tertiary"; visible: text !== "" }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitHeight: body.implicitHeight + group.pad * 2
        radius: 14
        color: F1Hub.fill
        border.width: 1
        border.color: F1Hub.fill

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: group.pad
            spacing: 0
        }
    }
}
