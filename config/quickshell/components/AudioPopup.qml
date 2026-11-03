import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire

import "."

BarPopup {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: {
        const result = []
        for (let i = 0; i < Pipewire.nodes.values.length; i++) {
            const node = Pipewire.nodes.values[i]
            if (node.isSink && !node.isStream)
                result.push(node)
        }
        return result
    }

    padding: 14
    contentMinWidth: 300

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    ColumnLayout {
        Layout.preferredWidth: 300
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            Rectangle {
                implicitWidth: 38
                implicitHeight: 38
                radius: 11
                color: Theme.alpha(Theme.iris, 0.14)
                Text {
                    anchors.centerIn: parent
                    text: root.sink?.audio?.muted ? "󰝟" : "󰕾"
                    color: Theme.iris
                    font.family: Theme.fontFamily
                    font.pixelSize: 19
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    text: "Audio"
                    color: Theme.foreground
                    font.family: Theme.displayFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
                Text {
                    text: root.sink?.description ?? "No output device"
                    color: Theme.subtle
                    font.family: Theme.displayFont
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "󰕾  Output volume"
                    color: Theme.foreground
                    font.family: Theme.displayFont
                    font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.sink?.audio ? Math.round(root.sink.audio.volume * 100) + "%" : "—"
                    color: Theme.subtle
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
                Rectangle {
                    implicitWidth: 25
                    implicitHeight: 25
                    radius: 7
                    color: outputMuteHover.hovered ? Theme.surface : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: root.sink?.audio?.muted ? "󰝟" : "󰖁"
                        color: root.sink?.audio?.muted ? Theme.love : Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                    }
                    HoverHandler { id: outputMuteHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted }
                }
            }

            Slider {
                id: outputSlider
                Layout.fillWidth: true
                from: 0
                to: 1.5
                value: root.sink?.audio?.volume ?? 0
                implicitHeight: 22
                onMoved: if (root.sink?.audio) root.sink.audio.volume = value

                background: Rectangle {
                    x: outputSlider.leftPadding
                    y: outputSlider.topPadding + outputSlider.availableHeight / 2 - height / 2
                    width: outputSlider.availableWidth
                    height: 4
                    radius: 2
                    color: Theme.highlightLow
                    Rectangle {
                        width: outputSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Theme.iris
                    }
                }
                handle: Rectangle {
                    x: outputSlider.leftPadding + outputSlider.visualPosition * (outputSlider.availableWidth - width)
                    y: outputSlider.topPadding + outputSlider.availableHeight / 2 - height / 2
                    width: 12
                    height: 12
                    radius: 6
                    color: outputSlider.pressed ? Theme.foreground : Theme.iris
                    border.width: 2
                    border.color: Theme.background
                }
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.highlightLow }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "󰍬  Microphone"
                    color: Theme.foreground
                    font.family: Theme.displayFont
                    font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.source?.audio ? Math.round(root.source.audio.volume * 100) + "%" : "Unavailable"
                    color: Theme.subtle
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
                Rectangle {
                    visible: !!root.source?.audio
                    implicitWidth: 25
                    implicitHeight: 25
                    radius: 7
                    color: inputMuteHover.hovered ? Theme.surface : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: root.source?.audio?.muted ? "󰍭" : "󰍬"
                        color: root.source?.audio?.muted ? Theme.love : Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                    }
                    HoverHandler { id: inputMuteHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted }
                }
            }

            Slider {
                id: inputSlider
                Layout.fillWidth: true
                visible: !!root.source?.audio
                from: 0
                to: 1.5
                value: root.source?.audio?.volume ?? 0
                implicitHeight: 22
                onMoved: if (root.source?.audio) root.source.audio.volume = value

                background: Rectangle {
                    x: inputSlider.leftPadding
                    y: inputSlider.topPadding + inputSlider.availableHeight / 2 - height / 2
                    width: inputSlider.availableWidth
                    height: 4
                    radius: 2
                    color: Theme.highlightLow
                    Rectangle {
                        width: inputSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Theme.foam
                    }
                }
                handle: Rectangle {
                    x: inputSlider.leftPadding + inputSlider.visualPosition * (inputSlider.availableWidth - width)
                    y: inputSlider.topPadding + inputSlider.availableHeight / 2 - height / 2
                    width: 12
                    height: 12
                    radius: 6
                    color: inputSlider.pressed ? Theme.foreground : Theme.foam
                    border.width: 2
                    border.color: Theme.background
                }
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.highlightLow }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            Text {
                text: "Output device"
                color: Theme.muted
                font.family: Theme.displayFont
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }

            Repeater {
                model: root.sinks
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool active: modelData.id === root.sink?.id
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 8
                    color: active ? Theme.alpha(Theme.iris, 0.12)
                        : deviceHover.hovered ? Theme.overlay : Theme.surface
                    border.width: 1
                    border.color: active ? Theme.alpha(Theme.iris, 0.4) : Theme.highlightLow
                    HoverHandler { id: deviceHover; cursorShape: Qt.PointingHandCursor }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        Text {
                            text: parent.parent.active ? "󰄬" : "󰓅"
                            color: parent.parent.active ? Theme.iris : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                        Text {
                            Layout.fillWidth: true
                            text: parent.parent.modelData.description || parent.parent.modelData.name
                            color: parent.parent.active ? Theme.foreground : Theme.subtle
                            font.family: Theme.displayFont
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    TapHandler {
                        enabled: modelData.id !== root.sink?.id
                        onTapped: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
            }
        }
    }
}
