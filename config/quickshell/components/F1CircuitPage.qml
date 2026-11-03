import QtQuick
import QtQuick.Layouts

import "."

F1Page {
    index: 1
    
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        ColumnLayout {
            Layout.preferredWidth: 340
            Layout.maximumWidth: 340
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    F1Label { text: [(F1Data.nextRace?.Circuit.Location.locality ?? ""), (F1Data.nextRace?.Circuit.Location.country ?? "")].join(", ").toUpperCase() }
                    Text {
                        text: F1Data.nextRace?.Circuit.circuitName ?? ""
                        color: Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Black
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                F1Pill { visible: !!F1Data.track?.corners; text: (F1Data.track?.corners?.length ?? 0) + " TURNS"; tint: Theme.gold }
            }

            F1Card {
                pad: 4
                Layout.fillHeight: true
                TrackMap {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 180
                    track: F1Data.track
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                    model: [["S1", Theme.love], ["S2", Theme.foam], ["S3", Theme.gold]]
                    RowLayout {
                        required property var modelData
                        spacing: 4
                        Rectangle { implicitWidth: 14; implicitHeight: 3; radius: 1.5; color: parent.modelData[1] }
                        Text { text: parent.modelData[0]; color: Theme.subtle; font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold }
                    }
                }
                Item { Layout.fillWidth: true }
                Rectangle { implicitWidth: 14; implicitHeight: 6; radius: 3; color: Theme.alpha(Theme.foam, 0.28); border.width: 1; border.color: Theme.foam }
                Text { text: "Straight mode (est.)"; color: Theme.subtle; font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            F1Label { text: "CIRCUIT RECORDS" }
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: 8
                columnSpacing: 8

                F1StatTile {
                    fixedHeight: 84
                    label: "RACE LAP RECORD"
                    team: F1Data.circuit?.lapRecord?.team ?? ""
                    value: F1Data.circuit?.lapRecord?.time ?? ""
                    sub: F1Data.circuit?.lapRecord ? F1Data.circuit.lapRecord.name.split(" ").pop() + " · " + F1Data.circuit.lapRecord.season : ""
                }
                F1StatTile {
                    fixedHeight: 84
                    label: "QUALI RECORD"
                    team: F1Data.circuit?.qualiRecord?.team ?? ""
                    value: F1Data.circuit?.qualiRecord?.time ?? ""
                    sub: F1Data.circuit?.qualiRecord ? F1Data.circuit.qualiRecord.name.split(" ").pop() + " · " + F1Data.circuit.qualiRecord.season : ""
                }
                F1StatTile {
                    fixedHeight: 84
                    label: "FIRST GRAND PRIX"
                    value: F1Data.circuit?.firstYear ?? ""
                    sub: F1Data.circuit?.races ? F1Data.circuit.races + " races · " + F1Data.circuit.raceLaps + " laps" : ""
                }
                F1StatTile {
                    fixedHeight: 84
                    label: "MOST WINS"
                    team: F1Data.circuit?.mostWins?.team ?? ""
                    value: F1Data.circuit?.mostWins?.names ?? ""
                    sub: F1Data.circuit?.mostWins ? F1Data.circuit.mostWins.count + " victories" : ""
                }
                F1StatTile {
                    fixedHeight: 84
                    label: "MOST POLES"
                    team: F1Data.circuit?.mostPoles?.team ?? ""
                    value: F1Data.circuit?.mostPoles?.names ?? ""
                    sub: F1Data.circuit?.mostPoles ? F1Data.circuit.mostPoles.count + " poles" : ""
                }
                F1StatTile {
                    fixedHeight: 84
                    label: "MOST PODIUMS"
                    team: F1Data.circuit?.mostPodiums?.team ?? ""
                    value: F1Data.circuit?.mostPodiums?.names ?? ""
                    sub: F1Data.circuit?.mostPodiums ? F1Data.circuit.mostPodiums.count + " podiums" : ""
                }
                F1StatTile {
                    fixedHeight: 84
                    label: "MOST TEAM WINS"
                    team: F1Data.circuit?.mostTeamWins?.team ?? ""
                    value: F1Data.circuit?.mostTeamWins?.names ?? ""
                    sub: F1Data.circuit?.mostTeamWins ? F1Data.circuit.mostTeamWins.count + " victories" : ""
                }
                F1StatTile {
                    fixedHeight: 84
                    readonly property var both: {
                        const c = F1Data.circuit
                        if (!c?.winners || !c?.poles) return []
                        return Object.keys(c.winners).filter(y => c.poles[y])
                    }
                    readonly property int converted: both.filter(y => F1Data.circuit.winners[y] === F1Data.circuit.poles[y]).length
                    label: "POLE TO WIN"
                    value: both.length ? converted + " of " + both.length : ""
                    sub: both.length ? Math.round(converted / both.length * 100) + "% won from pole" : ""
                }
                F1StatTile {
                    fixedHeight: 84
                    label: "LOWEST GRID WIN"
                    team: F1Data.circuit?.lowestGridWin?.team ?? ""
                    value: F1Data.circuit?.lowestGridWin ? "P" + F1Data.circuit.lowestGridWin.grid : ""
                    sub: F1Data.circuit?.lowestGridWin ? F1Data.circuit.lowestGridWin.name.split(" ").pop() + " · " + F1Data.circuit.lowestGridWin.season : ""
                }
            }

            F1Label { text: "RECENT WINNERS"; topPadding: 2 }
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                Repeater {
                    model: F1Data.circuit?.recentWinners ?? []
                    Rectangle {
                        id: winnerCard
                        required property var modelData
                        readonly property color tint: F1Data.teamColour(modelData.team)
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        Layout.minimumHeight: 64
                        radius: 10
                        color: Qt.rgba(tint.r, tint.g, tint.b, 0.18)
                        border.width: 1
                        border.color: Qt.rgba(tint.r, tint.g, tint.b, 0.55)

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 12
                            spacing: 3
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: winnerCard.modelData.season
                                color: Theme.subtle
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }
                            Image {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 26
                                source: F1Data.teamLogo(winnerCard.modelData.team)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: winnerCard.modelData.code
                                color: Theme.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: 15
                                font.weight: Font.Black
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "from P" + winnerCard.modelData.grid
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
        }
    }
}
