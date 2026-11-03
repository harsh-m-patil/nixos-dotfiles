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

        IslandOpenButton {
            label: "Open Now Playing"
            detail: Media.players.length > 1 ? Media.players.length + " players" : ""
            onActivated: card.openRequested()
        }
    }
}
