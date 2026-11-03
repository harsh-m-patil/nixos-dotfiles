import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris

import "."

Item {
    id: card

    property alias trigger: popup.trigger
    property alias triggerHovered: popup.triggerHovered
    readonly property bool hovered: popup.hovered

    readonly property color accent: {
        const c = quant.colors
        if (!c || c.length === 0)
            return Theme.iris
        let best = c[0]
        let bestScore = -1
        for (let i = 0; i < c.length; i++) {
            const col = c[i]
            const score = col.hsvSaturation * 0.7 + col.hsvValue * 0.3
            if (score > bestScore) {
                bestScore = score
                best = col
            }
        }
        return Qt.hsva(best.hsvHue, Math.max(0.45, best.hsvSaturation), Math.max(0.8, best.hsvValue), 1)
    }
    ColorQuantizer {
        id: quant
        source: Media.artUrl
        depth: 3
        rescaleSize: 64
    }

    BarPopup {
        id: popup
        framed: false
        padding: 0
        contentMinWidth: 480

    Item {
        implicitWidth: 480
        implicitHeight: 216

        Rectangle {
            id: frame
            anchors.fill: parent
            radius: 18
            color: Theme.background
            visible: false
        }

        Item {
            id: bgLayer
            anchors.fill: parent
            visible: false

            Rectangle { anchors.fill: parent; color: Theme.background }

            Image {
                id: backdrop
                anchors.fill: parent
                anchors.margins: -40
                source: Media.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            MultiEffect {
                anchors.fill: backdrop
                source: backdrop
                blurEnabled: true
                blur: 1
                blurMax: 64
                saturation: 0.2
                brightness: -0.45
                opacity: 0.8
                visible: backdrop.status === Image.Ready
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(0.098, 0.090, 0.141, 0.15) }
                    GradientStop { position: 0.55; color: Qt.rgba(0.098, 0.090, 0.141, 0.7) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.098, 0.090, 0.141, 0.92) }
                }
            }
        }

        MultiEffect {
            anchors.fill: parent
            source: bgLayer
            maskEnabled: true
            maskSource: frameMask
        }

        Item {
            id: frameMask
            anchors.fill: parent
            layer.enabled: true
            visible: false
            Rectangle { anchors.fill: parent; radius: 18 }
        }

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.28)
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 18

            Item {
                id: artBox
                Layout.preferredWidth: 184
                Layout.preferredHeight: 184
                Layout.alignment: Qt.AlignVCenter

                property real breathe: 1
                SequentialAnimation on breathe {
                    running: Media.playing && card.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.025; duration: 1800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
                }

                RectangularShadow {
                    anchors.fill: art
                    radius: 14
                    blur: 28
                    spread: 2
                    color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, Media.playing ? 0.45 : 0.15)
                    scale: art.scale
                    Behavior on color { ColorAnimation { duration: 500 } }
                }

                Item {
                    id: art
                    anchors.fill: parent
                    scale: Media.playing ? artBox.breathe : 0.92
                    Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: Theme.surface
                    }

                    Image {
                        id: artImg
                        anchors.fill: parent
                        source: Media.artUrl
                        sourceSize.width: 368
                        sourceSize.height: 368
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }

                    Item {
                        id: artMask
                        anchors.fill: parent
                        layer.enabled: true
                        visible: false
                        Rectangle { anchors.fill: parent; radius: 14 }
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: artImg
                        maskEnabled: true
                        maskSource: artMask
                        saturation: Media.playing ? 0 : -0.5
                        Behavior on saturation { NumberAnimation { duration: 400 } }
                        visible: artImg.status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: artImg.status !== Image.Ready
                        text: "󰎆"
                        color: card.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 64
                    }
                }
            }

            ColumnLayout {
                id: infoCol
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                Rectangle {
                    Layout.bottomMargin: 6
                    implicitWidth: chipRow.implicitWidth + 14
                    implicitHeight: 20
                    radius: 10
                    color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.16)

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: Media.playing ? "󰝚" : "󰏤"
                            color: card.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        Text {
                            text: (Media.player?.identity || "Media") + (Media.playing ? "" : " · paused")
                            color: card.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: Media.player?.trackTitle || "Unknown"
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 19
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                }
                Text {
                    Layout.fillWidth: true
                    text: Media.player?.trackArtist ?? ""
                    visible: text !== ""
                    color: card.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: Media.player?.trackAlbum ?? ""
                    visible: text !== ""
                    color: Theme.subtle
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Item { Layout.fillHeight: true }

                WaveBars {
                    Layout.fillWidth: true
                    implicitHeight: 26
                    bars: 32
                    barWidth: 3
                    gap: 2.4
                    playing: Media.playing
                    colorA: card.accent
                    colorB: Theme.foam
                }

                Item {
                    id: seek
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    implicitHeight: 14

                    property bool dragging: seekArea.pressed
                    property real dragPos: 0
                    readonly property real shown: dragging ? dragPos : Media.progress

                    Rectangle {
                        id: track
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: seekArea.containsMouse || seek.dragging ? 6 : 4
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, 0.1)
                        Behavior on height { NumberAnimation { duration: 150 } }

                        Rectangle {
                            width: parent.width * seek.shown
                            height: parent.height
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: card.accent }
                                GradientStop { position: 1; color: Theme.foam }
                            }
                            Behavior on width {
                                enabled: !seek.dragging
                                NumberAnimation { duration: 480 }
                            }
                        }
                    }

                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: Theme.foreground
                        anchors.verticalCenter: parent.verticalCenter
                        x: parent.width * seek.shown - width / 2
                        scale: seekArea.containsMouse || seek.dragging ? 1 : 0
                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                    }

                    MouseArea {
                        id: seekArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        enabled: Media.player?.canSeek ?? false
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => seek.dragPos = Math.max(0, Math.min(1, mouse.x / width))
                        onPositionChanged: mouse => {
                            if (pressed)
                                seek.dragPos = Math.max(0, Math.min(1, mouse.x / width))
                        }
                        onReleased: Media.player.position = Media.player.length * seek.dragPos
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: Fmt.clock(seek.dragging ? (Media.player?.length ?? 0) * seek.dragPos : (Media.player?.position ?? 0))
                        color: Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "-" + Fmt.clock((Media.player?.length ?? 0) - (Media.player?.position ?? 0))
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 4

                    MediaButton {
                        icon: "󰒟"
                        iconSize: 15
                        visible: Media.player?.shuffleSupported ?? false
                        accent: Media.player?.shuffle ?? false
                        onActivated: Media.player.shuffle = !Media.player.shuffle
                    }

                    Item { Layout.fillWidth: true }

                    MediaButton {
                        icon: "󰒮"
                        iconSize: 20
                        enabled: Media.player?.canGoPrevious ?? false
                        onActivated: Media.player?.previous()
                    }

                    Rectangle {
                        id: playBtn
                        implicitWidth: 42
                        implicitHeight: 42
                        radius: 21
                        color: card.accent
                        scale: playArea.pressed ? 0.9 : (playArea.containsMouse ? 1.08 : 1)
                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: Media.playing ? 0 : 1
                            text: Media.playing ? "󰏤" : "󰐊"
                            color: Theme.background
                            font.family: Theme.fontFamily
                            font.pixelSize: 22
                        }

                        MouseArea {
                            id: playArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: Media.player?.canTogglePlaying ?? false
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Media.player?.togglePlaying()
                        }
                    }

                    MediaButton {
                        icon: "󰒭"
                        iconSize: 20
                        enabled: Media.player?.canGoNext ?? false
                        onActivated: Media.player?.next()
                    }

                    Item { Layout.fillWidth: true }

                    MediaButton {
                        icon: Media.player?.loopState === MprisLoopState.Track ? "󰑘" : "󰑖"
                        iconSize: 15
                        visible: Media.player?.loopSupported ?? false
                        accent: (Media.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                        onActivated: {
                            const s = Media.player.loopState
                            Media.player.loopState = s === MprisLoopState.None ? MprisLoopState.Playlist
                                : s === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
                        }
                    }
                }
            }
        }
    }
    }
}
