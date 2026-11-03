import QtQuick
import QtQuick.Layouts

import "."

// Race weekend at a glance — header band, horizontal session strip, compact open pill.
ColumnLayout {
    id: peek
    signal openRequested()
    spacing: 8

    readonly property var w: F1Data.weekend
    readonly property string mode: F1Data.mode
    readonly property color accent: mode === "live" ? Theme.love : F1Hub.ink
    readonly property int stripWidth: Math.max(300, F1Data.sessions.length * 54 + 20)

    readonly property string statusLine: mode === "live" ? F1Data.liveSession.label + " live"
        : mode === "result" ? F1Data.session?.short ?? "Result"
        : F1Data.nextSession ? F1Data.nextSession.label + " in" : "Next up"
    readonly property string headlineRight: mode === "live" ? F1Data.elapsed(F1Data.liveSession.start)
        : mode === "result" ? (F1Data.session?.results?.[0]?.code ?? "")
        : F1Data.nextSession ? F1Data.countdown(F1Data.nextSession.start)
        : peek.w ? F1Data.countdown(peek.w.sessions[0].start) : ""

    implicitWidth: Math.max(headerRow.implicitWidth + 8, stripWidth)

    RowLayout {
        id: headerRow
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            visible: flag.status === Image.Ready
            Layout.preferredWidth: 32
            Layout.preferredHeight: 21
            radius: 4
            clip: true
            color: "transparent"
            Image {
                id: flag
                anchors.fill: parent
                source: F1Data.meeting?.flag ?? ""
                sourceSize.width: 64
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            F1Text {
                text: peek.w ? "R" + peek.w.round + " · " + peek.w.short + " GP" : (F1Data.lastRace?.short ?? "F1") + " GP"
                role: "callout"
                font.weight: Font.DemiBold
            }
            F1Text {
                Layout.fillWidth: true
                text: peek.w ? peek.w.locality + ", " + peek.w.country
                    : F1Data.lastRace?.name ?? "Formula 1"
                role: "footnote"
                tone: "secondary"
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            spacing: 0
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 5
                Rectangle {
                    visible: peek.mode === "live"
                    implicitWidth: 6; implicitHeight: 6; radius: 3
                    color: Theme.love
                }
                F1Text {
                    text: peek.statusLine
                    role: "caption"
                    tone: peek.mode === "live" ? "primary" : "tertiary"
                    color: peek.mode === "live" ? Theme.love : F1Hub.ink3
                }
            }
            F1Text {
                Layout.alignment: Qt.AlignRight
                text: peek.headlineRight
                role: "callout"
                numeric: peek.mode !== "result"
                font.weight: Font.DemiBold
                color: peek.accent
            }
        }
    }

    F1Group {
        Layout.fillWidth: true
        Layout.preferredWidth: peek.stripWidth
        visible: F1Data.sessions.length > 0
        title: "Weekend"
        detail: peek.w ? Qt.formatDate(peek.w.start, "d MMM") : ""
        pad: 4

        F1Timeline {
            dense: true
            Layout.fillWidth: true
            Layout.preferredWidth: peek.stripWidth - 8
        }
    }

    F1Group {
        Layout.fillWidth: true
        visible: peek.mode === "result" && (F1Data.session?.results?.length ?? 0) > 0
        title: "Podium"
        detail: F1Data.session?.short ?? ""
        pad: 4

        RowLayout {
            id: podiumRow
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: (F1Data.session?.results ?? []).slice(0, 3)
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 5
                    F1Text {
                        text: modelData.pos
                        role: "caption"
                        tone: "tertiary"
                        numeric: true
                        Layout.preferredWidth: 14
                    }
                    Rectangle {
                        width: 5; height: 5; radius: 2.5
                        color: F1Data.teamColour(modelData.team)
                    }
                    F1Text {
                        Layout.fillWidth: true
                        text: modelData.code
                        role: "callout"
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    F1Text {
                        text: modelData.time ?? ""
                        role: "caption"
                        tone: "secondary"
                        numeric: true
                        visible: text !== ""
                        Layout.maximumWidth: 52
                        elide: Text.ElideLeft
                    }
                }
            }
        }
    }

    ClockButton {
        Layout.alignment: Qt.AlignHCenter
        text: "Open F1 Hub"
        hint: "Super⇧F"
        onClicked: peek.openRequested()
    }
}
