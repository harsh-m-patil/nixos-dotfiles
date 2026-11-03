import QtQuick
import QtQuick.Layouts

import "."

// Where we are in the season: the current GP on the left, the moment that matters on the right.
ColumnLayout {
    id: hero
    property bool large: true
    readonly property var w: F1Data.weekend
    readonly property string mode: F1Data.mode
    readonly property color accent: mode === "live" ? Theme.love : F1Hub.ink

    readonly property string status: mode === "live" ? F1Data.liveSession.label + " is live"
        : mode === "result" ? F1Data.session.short + " winner"
        : F1Data.nextSession ? F1Data.nextSession.label + " starts in" : "Season complete"
    readonly property string headline: mode === "live" ? F1Data.elapsed(F1Data.liveSession.start) + " in"
        : mode === "result" ? (F1Data.session.results[0]?.name ?? "")
        : F1Data.nextSession ? F1Data.countdown(F1Data.nextSession.start) : ""

    spacing: large ? 18 : 12

    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        Rectangle {
            visible: flag.status === Image.Ready
            Layout.preferredWidth: hero.large ? 48 : 36
            Layout.preferredHeight: Layout.preferredWidth * 2 / 3
            radius: 5
            color: "transparent"
            clip: true
            Image {
                id: flag
                anchors.fill: parent
                source: F1Data.meeting?.flag ?? ""
                sourceSize.width: 96
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            F1Text {
                text: hero.w ? "Round " + hero.w.round + "  ·  " + hero.w.locality + ", " + hero.w.country : ""
                role: "footnote"
                tone: "secondary"
                Layout.fillWidth: true
            }
            F1Text {
                text: hero.w?.name ?? "Season complete"
                role: hero.large ? "largeTitle" : "title"
                Layout.fillWidth: true
            }
        }

        ColumnLayout {
            spacing: 1
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 6
                Rectangle {
                    visible: hero.mode === "live"
                    implicitWidth: 7; implicitHeight: 7; radius: 3.5
                    color: Theme.love
                }
                F1Text { text: hero.status; role: "footnote"; color: hero.mode === "live" ? Theme.love : F1Hub.ink2 }
            }
            F1Text {
                Layout.alignment: Qt.AlignRight
                text: hero.headline
                role: hero.large ? "largeTitle" : "title"
                numeric: hero.mode !== "result"
                color: hero.accent
            }
        }
    }

    F1Timeline {}
}
