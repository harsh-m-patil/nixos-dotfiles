import QtQuick
import QtQuick.Layouts

import "."

F1Page {
    index: 2
    
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        ColumnLayout {
            Layout.preferredWidth: 400
            Layout.maximumWidth: 400
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: 10
            ColumnLayout {
                spacing: 0
                F1Label { text: "ROUND " + (F1Data.lastRace?.round ?? "") + " · " + (F1Data.lastRace?.season ?? "") }
                Text {
                    text: F1Data.lastRace?.raceName ?? ""
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.Black
                }
            }
            Item { Layout.fillHeight: true }
            F1Podium {
                entries: F1Data.results.slice(0, 3).map(r => ({ code: r.Driver.code, value: r.points + " pts", team: r.Constructor.constructorId }))
                headshotScale: 2.3
            }

            F1Label { text: "RACE SUMMARY" }
            GridLayout {
                id: raceStats
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                readonly property var res: F1Data.results
                readonly property var fastest: res.find(r => r.FastestLap?.rank === "1") ?? null
                readonly property var winner: res[0] ?? null
                readonly property int retired: res.filter(r => r.status !== "Finished" && !/^\+|Lap/.test(r.status)).length
                F1StatTile {
                    stretch: false
                    label: "FASTEST LAP"
                    team: raceStats.fastest?.Constructor.constructorId ?? ""
                    value: raceStats.fastest?.FastestLap.Time.time ?? ""
                    sub: raceStats.fastest ? raceStats.fastest.Driver.familyName + " · lap " + raceStats.fastest.FastestLap.lap : ""
                }
                F1StatTile {
                    stretch: false
                    label: "WINNING MARGIN"
                    value: raceStats.res[1]?.Time?.time ?? raceStats.res[1]?.status ?? ""
                    sub: raceStats.winner?.Time ? "Race time " + raceStats.winner.Time.time : ""
                }
                F1StatTile {
                    stretch: false
                    label: "WINNER STARTED"
                    team: raceStats.winner?.Constructor.constructorId ?? ""
                    value: raceStats.winner ? (raceStats.winner.grid === "0" ? "Pit lane" : "P" + raceStats.winner.grid) : ""
                    sub: raceStats.winner ? raceStats.winner.Driver.familyName + " · " + raceStats.winner.laps + " laps" : ""
                }
                F1StatTile {
                    stretch: false
                    label: "RETIREMENTS"
                    value: raceStats.winner ? String(raceStats.retired) : ""
                    sub: raceStats.res.length ? raceStats.res.length - raceStats.retired + " classified" : ""
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            F1Label { text: "CLASSIFICATION"; bottomPadding: 6 }
            Repeater {
                model: F1Data.results.slice(3, 13)
                F1DriverRow {
                    required property var modelData
                    position: Number(modelData.position)
                    code: modelData.Driver.code
                    name: modelData.Driver.givenName + " " + modelData.Driver.familyName
                    team: modelData.Constructor.name
                    value: modelData.Time?.time ?? modelData.status
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
