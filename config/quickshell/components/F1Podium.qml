import QtQuick
import QtQuick.Layouts

import "."

// Top three as portrait cards, winner centred and tallest. `entries` are result rows.
RowLayout {
    id: podium
    property var entries: []
    property int height1: 150
    Layout.fillWidth: true
    visible: entries.length > 0
    spacing: 10

    Repeater {
        model: [1, 0, 2]
        Item {
            id: slot
            required property int modelData
            readonly property var entry: podium.entries[modelData] ?? null
            readonly property color tint: F1Data.teamColour(entry?.team ?? "")
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            implicitHeight: podium.height1 - modelData * 16
            visible: entry !== null

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * (1 - slot.modelData * 0.1)
                radius: 14
                clip: true
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.alpha(slot.tint, 0.28) }
                    GradientStop { position: 1; color: Theme.alpha(slot.tint, 0.04) }
                }
                border.width: 1
                border.color: Theme.alpha(slot.tint, 0.25)

                Image {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 34
                    anchors.bottomMargin: 40
                    source: slot.entry ? F1Data.headshot(slot.entry.code) : ""
                    sourceSize.height: 480
                    fillMode: Image.PreserveAspectCrop
                    verticalAlignment: Image.AlignTop
                    asynchronous: true
                    smooth: true
                }

                F1Text {
                    x: 10; y: 8
                    text: String(slot.modelData + 1)
                    role: "title2"
                    numeric: true
                    tone: slot.modelData === 0 ? "primary" : "secondary"
                }
                Image {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    width: 30
                    height: 22
                    source: slot.entry?.team ? F1Data.teamLogo(slot.entry.team) : ""
                    sourceSize.height: 44
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 40
                    color: Theme.alpha(Theme.background, 0.72)
                    Column {
                        anchors.centerIn: parent
                        F1Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: slot.entry?.last ?? (slot.entry?.name ?? "").split(" ").pop()
                            role: "headline"
                        }
                        F1Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: slot.entry?.time ?? ""
                            role: "caption"
                            tone: "secondary"
                            numeric: true
                        }
                    }
                }
            }
        }
    }
}
