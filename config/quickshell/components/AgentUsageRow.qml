import QtQuick
import QtQuick.Layouts

import "."

// A model in the usage list: rank, name + tokens, cost, share bar. `selected` follows the keyboard.
Item {
    id: row
    property string rank
    property string title
    property string subtitle
    property string value
    property real share: 0
    property bool selected: false
    signal clicked()

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: implicitHeight
    Layout.maximumHeight: 48
    implicitHeight: 36

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: 9
        color: row.selected ? Theme.alpha(Theme.iris, 0.16) : hover.hovered ? F1Hub.fill : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Rectangle {
        x: 44
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        height: 2
        radius: 1
        width: Math.max(2, (parent.width - 58) * row.share)
        color: Theme.alpha(Theme.iris, 0.55)
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 14
        spacing: 10
        F1Text {
            Layout.preferredWidth: 22
            horizontalAlignment: Text.AlignRight
            text: row.rank
            role: "callout"
            tone: "tertiary"
            numeric: true
        }
        F1Text { text: row.title; role: "body"; font.weight: Font.Medium; Layout.maximumWidth: 240 }
        F1Text { text: row.subtitle; role: "callout"; tone: "tertiary"; numeric: true; Layout.fillWidth: true }
        F1Text { text: row.value; role: "callout"; tone: "secondary"; numeric: true }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: row.clicked() }
}
