import QtQuick
import QtQuick.Layouts

import "."

Island {
    id: root

    visible: F1Data.lastRace !== null || F1Data.nextRace !== null

    readonly property string sessionTag: ({ "Qualifying": "Q", "Sprint Qualifying": "SQ", "Sprint": "SPR",
        "Race": "RACE", "Practice 1": "FP1", "Practice 2": "FP2", "Practice 3": "FP3" })[F1Data.sessionName] ?? F1Data.sessionName
    readonly property var chipCodes: F1Data.sessionResults.length > 0
        ? F1Data.sessionResults.slice(0, 3).map(r => r.code)
        : F1Data.results.slice(0, 3).map(r => r.Driver.code)
    readonly property var pageTitles: ["Weekend", "Circuit", "Last Race", "My Team", "Standings"]
    readonly property var pageIcons: ["󰃭", "󰈼", "󰔸", "󰡉", "󰓒"]
    property int page: 0

    function shift(delta) {
        page = (page + delta + pageTitles.length) % pageTitles.length
    }

    // ── Bar chip ────────────────────────────────────────────────

    RowLayout {
        spacing: 7

        Rectangle {
            visible: F1Data.raceLive
            implicitWidth: 7
            implicitHeight: 7
            radius: 4
            color: Theme.love
            SequentialAnimation on opacity {
                running: F1Data.raceLive
                loops: Animation.Infinite
                NumberAnimation { to: 0.25; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }

        Text {
            text: F1Data.raceLive ? "LIVE" : root.sessionTag || "F1"
            color: F1Data.raceLive ? Theme.love : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            font.weight: Font.Bold
            font.letterSpacing: 0.5
        }

        Repeater {
            model: root.chipCodes
            RowLayout {
                required property string modelData
                required property int index
                spacing: 3
                Rectangle {
                    implicitWidth: 3
                    implicitHeight: Theme.fontSize
                    radius: 1.5
                    color: F1Data.driverColour(parent.modelData)
                }
                Text {
                    text: parent.modelData
                    color: parent.index === 0 ? Theme.gold : Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }
            }
        }
    }

    HoverHandler {
        id: hover
    }


    BarPopup {
        id: popup
        trigger: root
        triggerHovered: hover.hovered

        // Tab strip
        RowLayout {
            Layout.fillWidth: true
            spacing: 3

            Repeater {
                model: root.pageTitles.length
                Rectangle {
                    required property int index
                    readonly property bool active: index === root.page
                    implicitWidth: tabRow.implicitWidth + 14
                    implicitHeight: 30
                    radius: 10
                    color: active ? Qt.rgba(Theme.iris.r, Theme.iris.g, Theme.iris.b, 0.13)
                        : tabHover.hovered ? Theme.highlightLow : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: root.pageIcons[parent.parent.index]
                            color: parent.parent.active ? Theme.iris : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                        Text {
                            text: root.pageTitles[parent.parent.index]
                            color: parent.parent.active ? Theme.foreground : Theme.subtle
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                    }
                    HoverHandler { id: tabHover }
                    TapHandler { onTapped: root.page = parent.index }
                }
            }
            Item { Layout.fillWidth: true }
        }

        // Pages
        Item {
            id: pages
            Layout.preferredWidth: 860
            Layout.preferredHeight: Math.max(weekendPage.implicitHeight, circuitPage.implicitHeight,
                lastPage.implicitHeight, myTeamPage.implicitHeight, standingsPage.implicitHeight)
            clip: true

            F1WeekendPage { id: weekendPage; current: root.page }
            F1CircuitPage { id: circuitPage; current: root.page }
            F1LastRacePage { id: lastPage; current: root.page }
            F1MyTeamPage { id: myTeamPage; current: root.page }
            F1StandingsPage { id: standingsPage; current: root.page }
        }

        WheelHandler {
            onWheel: event => root.shift(event.angleDelta.y > 0 ? -1 : 1)
        }
    }
}
