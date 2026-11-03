import QtQuick
import QtQuick.Layouts

import "."

// Expanded: large artwork, seekable progress, full transport and the player switcher.
ColumnLayout {
    id: view
    property bool showHints: false
    spacing: 14

    function handleKey(e) {
        const k = e.key
        const shift = e.modifiers & Qt.ShiftModifier
        if (k === Qt.Key_Escape || k === Qt.Key_Q) Media.open = false
        else if (k === Qt.Key_Space || k === Qt.Key_Return) Media.togglePlaying()
        else if (k === Qt.Key_H || k === Qt.Key_Left) Media.seekBy(shift ? -30 : -5)
        else if (k === Qt.Key_L || k === Qt.Key_Right) Media.seekBy(shift ? 30 : 5)
        else if (k === Qt.Key_J || k === Qt.Key_Down) Media.step(1)
        else if (k === Qt.Key_K || k === Qt.Key_Up) Media.step(-1)
        else if (k === Qt.Key_N || k === Qt.Key_Period) Media.next()
        else if (k === Qt.Key_P || k === Qt.Key_Comma) Media.previous()
        else if (k === Qt.Key_S) Media.toggleShuffle()
        else if (k === Qt.Key_R) Media.cycleLoop()
        else if (k >= Qt.Key_1 && k <= Qt.Key_9 && k - Qt.Key_1 < Media.players.length) Media.select(Media.players[k - Qt.Key_1])
        else if (k === Qt.Key_Question || (k === Qt.Key_Slash && shift)) showHints = !showHints
        else return false
        return true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 22

        MediaArt { Layout.preferredWidth: 236; Layout.preferredHeight: 236 }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                MediaLevel { maxHeight: 12; barWidth: 2.5 }
                F1Text {
                    Layout.fillWidth: true
                    text: Media.app + (Media.playing ? "" : " · Paused")
                    role: "footnote"; tone: "secondary"
                }
            }
            F1Text {
                Layout.fillWidth: true
                Layout.topMargin: 6
                text: Media.title
                role: "title"
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }
            F1Text { Layout.fillWidth: true; text: Media.artist; role: "headline"; tone: "secondary"; visible: text !== "" }
            F1Text { Layout.fillWidth: true; text: Media.album; role: "callout"; tone: "tertiary"; visible: text !== "" }

            Item { Layout.fillHeight: true }

            MediaSeek { Layout.fillWidth: true; visible: Media.length > 0 }
            MediaControls { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 4; full: true }
        }
    }

    F1Group {
        Layout.fillWidth: true
        visible: Media.players.length > 1
        title: "Players"
        detail: "j / k to switch"
        pad: 4

        Flow {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: Media.players
                Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool current: modelData === Media.player
                    width: playerRow.implicitWidth + 24
                    height: 34
                    radius: 10
                    color: current ? Theme.alpha(Theme.iris, 0.16) : pHover.hovered ? F1Hub.fill : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Row {
                        id: playerRow
                        anchors.centerIn: parent
                        spacing: 8
                        F1Text { anchors.verticalCenter: parent.verticalCenter; text: index + 1; role: "caption"; tone: "tertiary"; numeric: true }
                        F1Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.identity || "Player"
                            role: "callout"
                            font.weight: current ? Font.DemiBold : Font.Medium
                        }
                        F1Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, 160)
                            text: (modelData.isPlaying ? "" : "Paused · ") + (modelData.trackTitle || "")
                            role: "caption"; tone: modelData.isPlaying ? "secondary" : "tertiary"
                        }
                    }
                    HoverHandler { id: pHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Media.select(modelData) }
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 20
        F1Keys {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: view.showHints
            hints: [["Space", "Play"], ["h l", "Seek"], ["n p", "Track"], ["j k", "Player"], ["s r", "Shuffle, repeat"], ["Esc", "Close"]]
        }
        F1Text {
            anchors.centerIn: parent
            visible: !view.showHints
            text: "Press ? for shortcuts"
            role: "caption"; tone: "tertiary"
            TapHandler { onTapped: view.showHints = true }
        }
    }
}
