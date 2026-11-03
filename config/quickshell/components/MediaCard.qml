import QtQuick
import QtQuick.Layouts

import "."

// Peek: what's playing at a glance, with transport and a way into the full view.
ColumnLayout {
    id: card
    signal openRequested()
    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        MediaArt { Layout.preferredWidth: 76; Layout.preferredHeight: 76 }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            F1Text { Layout.fillWidth: true; text: Media.title; role: "title2" }
            F1Text { Layout.fillWidth: true; text: Media.artist; role: "body"; tone: "secondary"; visible: text !== "" }
            F1Text {
                Layout.fillWidth: true
                text: Media.app + (Media.playing ? "" : " · Paused")
                role: "footnote"; tone: "tertiary"
            }
        }

        MediaLevel { Layout.alignment: Qt.AlignTop | Qt.AlignRight; Layout.topMargin: 6; maxHeight: 18 }
    }

    MediaSeek { Layout.fillWidth: true; visible: Media.length > 0 }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        MediaControls { Layout.leftMargin: -6 }
        Item { Layout.fillWidth: true }

        Rectangle {
            implicitWidth: openRow.implicitWidth + 28
            implicitHeight: 32
            radius: 16
            color: openHover.hovered ? F1Hub.fillStrong : F1Hub.fill
            border.width: 1
            border.color: F1Hub.hairline
            scale: openTap.pressed ? 0.96 : 1
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutQuint } }

            Row {
                id: openRow
                anchors.centerIn: parent
                spacing: 8
                F1Text { anchors.verticalCenter: parent.verticalCenter; text: "Open Now Playing"; role: "footnote"; font.weight: Font.DemiBold }
                F1Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Media.players.length > 1
                    text: Media.players.length + " players"
                    role: "caption"; tone: "tertiary"
                }
            }
            HoverHandler { id: openHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { id: openTap; onTapped: card.openRequested() }
        }
    }
}
