import QtQuick
import QtQuick.Layouts

import "."

F1Page {
    index: 3
    
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        ColumnLayout {
            Layout.preferredWidth: 380
            Layout.maximumWidth: 380
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: 10

            F1Card {
                pad: 14
                RowLayout {
                    spacing: 14
                    Image {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 40
                        source: F1Data.myTeamLogo
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                    }
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        F1Label { text: "CONSTRUCTORS' CHAMPIONSHIP" }
                        Text {
                            text: F1Data.myTeamName
                            color: Theme.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            font.weight: Font.Black
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: F1Data.myTeamStanding
                                ? "P" + F1Data.myTeamStanding.position + " · " + F1Data.myTeamPoints + " pts"
                                : "Not in standings yet"
                            color: Theme.gold
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                    }
                }
            }

            F1Label { text: "SEASON SUMMARY" }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                F1StatTile {
                    stretch: false
                    team: F1Data.myTeamId
                    label: "WCC GAP"
                    value: F1Data.myTeamStanding && Number(F1Data.myTeamStanding.position) > 1
                        ? F1Data.myTeamPointsGap + " pts" : F1Data.myTeamStanding ? "Leading" : "—"
                    sub: F1Data.teamStandings[0]
                        ? F1Data.teamStandings[0].Constructor.name + " · " + F1Data.teamStandings[0].points
                        : ""
                }
                F1StatTile {
                    stretch: false
                    team: F1Data.myTeamId
                    label: "SEASON WINS"
                    value: String(F1Data.myTeamHistory.seasonWins ?? 0)
                    sub: (F1Data.lastRace?.season ?? F1Data.nextRace?.season ?? "") + " season"
                }
                F1StatTile {
                    stretch: false
                    team: F1Data.myTeamId
                    label: "SEASON PODIUMS"
                    value: String(F1Data.myTeamHistory.seasonPodiums ?? 0)
                    sub: "Race finishes P1–P3"
                }
                F1StatTile {
                    stretch: false
                    team: F1Data.myTeamId
                    label: "LAST RACE"
                    value: F1Data.myLastRaceResults.length ? String(F1Data.myTeamRacePoints) + " pts" : "—"
                    sub: F1Data.lastRace ? F1Data.shortName(F1Data.lastRace) : ""
                }
                F1StatTile {
                    stretch: false
                    team: F1Data.myTeamId
                    label: "LAST WIN"
                    value: F1Data.myLastWinTitle
                    sub: F1Data.myLastWinSub
                }
                F1StatTile {
                    stretch: false
                    team: F1Data.myTeamId
                    label: "LAST WCC"
                    value: F1Data.myTeamHistory.lastWcc ?? "—"
                    sub: F1Data.myTeamHistory.lastWcc ? "Constructors' title" : ""
                }
            }

            F1Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: F1Data.nextRace !== null
                ColumnLayout {
                    spacing: 4
                    F1Label { text: "NEXT UP" }
                    Text {
                        text: F1Data.nextRace?.raceName ?? ""
                        color: Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Black
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "Round " + (F1Data.nextRace?.round ?? "") + " · "
                            + (F1Data.nextRace?.Circuit?.Location?.locality ?? "")
                        color: Theme.subtle
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                    Text {
                        text: F1Data.raceLive ? "● LIVE" : F1Data.nextSession
                            ? F1Data.nextSession.label + " in " + F1Data.countdown(F1Data.nextSession.start)
                            : F1Data.countdown(F1Data.nextStart)
                        color: F1Data.raceLive ? Theme.love : Theme.gold
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            F1Label {
                visible: F1Data.myDriversEven.length > 0
                text: "YOUR DRIVERS · " + (F1Data.lastRace?.season ?? F1Data.nextRace?.season ?? "") + " SEASON"
            }
            F1TeamDriverPair {
                stretch: true
                tiles: F1Data.myDriverTiles
            }

            F1Label {
                visible: F1Data.mySessionResults.length > 0
                text: "LATEST SESSION · " + F1Data.sessionName.toUpperCase()
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                visible: F1Data.mySessionResults.length > 0
                Repeater {
                    model: F1Data.mySessionResults.slice().sort((a, b) => a.code.localeCompare(b.code))
                    F1DriverRow {
                        required property var modelData
                        position: modelData.position
                        code: modelData.code
                        name: modelData.name.replace(/\b(\w)(\w*)$/, (m, a, b) => a + b.toLowerCase())
                        team: modelData.team
                        value: modelData.time
                        Layout.fillHeight: false
                    }
                }
            }
        }
    }
}
