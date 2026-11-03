import QtQuick
import QtQuick.Layouts

import "."

// One line in a grouped list: position, team dot, title + subtitle, trailing value,
// optional points bar. Rows of the user's team are tinted; `selected` follows the keyboard.
Item {
    id: row
    property string position
    property string title
    property string subtitle
    property string value
    property string team
    property bool selected: false
    property bool separator: true
    property real bar: -1               // 0…1 share of the leader, < 0 hides it
    readonly property color tint: F1Data.teamColour(team)
    readonly property bool mine: team !== "" && team === F1Data.myTeam
    signal clicked()

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: implicitHeight
    Layout.maximumHeight: 50
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: 9
        color: row.selected ? Theme.alpha(Theme.iris, 0.16)
            : hover.hovered ? F1Hub.fill
            : row.mine ? Theme.alpha(row.tint, 0.08) : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Rectangle {
        visible: row.bar >= 0
        x: 56
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        height: 2
        radius: 1
        width: Math.max(2, (parent.width - 68) * row.bar)
        color: Theme.alpha(row.tint, 0.55)
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 14
        spacing: 10

        F1Text {
            Layout.preferredWidth: Math.max(20, implicitWidth)
            horizontalAlignment: Text.AlignRight
            text: row.position
            role: "callout"
            tone: "tertiary"
            numeric: true
        }
        Item {
            implicitWidth: 22
            implicitHeight: 16
            Image {
                id: logo
                anchors.fill: parent
                source: row.team ? F1Data.teamLogo(row.team) : ""
                sourceSize.height: 32
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Rectangle {
                visible: logo.status !== Image.Ready
                anchors.centerIn: parent
                width: 8; height: 8; radius: 4
                color: row.tint
            }
        }
        F1Text {
            text: row.title
            role: "body"
            font.weight: row.mine ? Font.DemiBold : Font.Medium
            Layout.maximumWidth: 200
        }
        F1Text {
            text: row.subtitle
            role: "callout"
            tone: "tertiary"
            Layout.fillWidth: true
        }
        F1Text {
            text: row.value
            role: "callout"
            tone: "secondary"
            numeric: true
        }
    }

    Rectangle {
        visible: row.separator
        anchors.bottom: parent.bottom
        x: 56
        width: parent.width - 56
        height: 1
        color: F1Hub.fill
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: row.clicked() }
}
