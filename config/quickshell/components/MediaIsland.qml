import QtQuick
import QtQuick.Layouts

import "."

Island {
    id: root
    hPad: 5
    visible: opacity > 0.01
    opacity: Media.player ? 1 : 0
    scale: Media.player ? 1 : 0.94

    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

    MediaHold { active: islandHover.hovered || card.hovered }

    RowLayout {
        spacing: 6

        WaveBars {
            bars: 10
            barWidth: 2
            gap: 1.5
            implicitHeight: 16
            playing: Media.playing
        }

        Item {
            id: titleBox
            Layout.preferredWidth: Math.min(titleText.implicitWidth, 220)
            implicitHeight: 22
            clip: true

            readonly property bool overflow: titleText.implicitWidth > 220

            Text {
                id: titleText
                anchors.verticalCenter: parent.verticalCenter
                text: Media.line
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: Media.playing ? Theme.foreground : Theme.subtle
                Behavior on color { ColorAnimation { duration: 250 } }

                SequentialAnimation on x {
                    running: titleBox.overflow && Media.playing
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) titleText.x = 0
                    PauseAnimation { duration: 1800 }
                    NumberAnimation {
                        to: 220 - titleText.implicitWidth
                        duration: Math.max(1500, (titleText.implicitWidth - 220) * 28)
                        easing.type: Easing.InOutSine
                    }
                    PauseAnimation { duration: 1200 }
                    NumberAnimation { to: 0; duration: 600; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    const p = Media.player
                    if (p?.canSeek)
                        p.seek(wheel.angleDelta.y > 0 ? 5 : -5)
                }
            }
        }
    }

    HoverHandler { id: islandHover }

    Rectangle {
        parent: root
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.radius
        anchors.bottomMargin: 1
        height: 2
        radius: 1
        width: (parent.width - root.radius * 2) * Media.progress
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.iris }
            GradientStop { position: 1; color: Theme.foam }
        }
        opacity: Media.playing ? 0.9 : 0.4
        Behavior on width { NumberAnimation { duration: 480; easing.type: Easing.Linear } }
    }

    MediaCard {
        id: card
        trigger: root
        triggerHovered: islandHover.hovered
    }
}
