import QtQuick
import QtQuick.Layouts

import "."

F1Page {
    id: page
    readonly property var w: F1Data.weekend
    readonly property var h: F1Data.history

    hints: [["s", "Sectors"]]
    Component.onCompleted: F1Data.loadHistory()
    Connections { target: F1Data; function onWeekendChanged() { F1Data.loadHistory() } }

    function handleKey(e) {
        if (e.key === Qt.Key_S) { map.showSectors = !map.showSectors; return true }
        return false
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12

        F1Group {
            title: page.w?.circuit ?? ""
            detail: [F1Data.track?.corners ? F1Data.track.corners.length + " turns" : "",
                     F1Data.track?.pitLoss ? "pit loss " + F1Data.track.pitLoss.toFixed(1) + "s" : ""].filter(s => s).join(" · ")
            Layout.preferredWidth: 5
            Layout.fillWidth: true
            Layout.fillHeight: true
            pad: 8
            TrackMap {
                id: map
                Layout.fillWidth: true
                Layout.fillHeight: true
                track: F1Data.track
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 6
                spacing: 12
                Repeater {
                    model: (F1Data.track?.sectors?.[0] ?? 0) > 0
                        ? [1, 2, 3].map(n => ["Sector " + n, map.sectorColours[n - 1]]) : []
                    Row {
                        required property var modelData
                        spacing: 5
                        opacity: map.showSectors ? 1 : 0.35
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: modelData[1] }
                        F1Text { text: modelData[0]; role: "caption"; tone: "secondary" }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 4
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            F1Group {
                title: "History"
                detail: page.h?.races ? page.h.races + " Grands Prix since " + page.h.first : ""
                Layout.fillHeight: false
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 0
                    rowSpacing: 0
                    F1Stat {
                        label: "Most wins"
                        value: page.h?.mostWins?.names.join(", ") ?? ""
                        sub: page.h?.mostWins ? page.h.mostWins.count + " victories" : ""
                        accent: F1Data.teamColour(page.h?.mostWins?.team ?? "", F1Hub.ink)
                    }
                    F1Stat {
                        label: "Most team wins"
                        value: page.h?.mostTeamWins?.names.join(", ") ?? ""
                        sub: page.h?.mostTeamWins ? page.h.mostTeamWins.count + " victories" : ""
                        accent: F1Data.teamColour(page.h?.mostTeamWins?.team ?? "", F1Hub.ink)
                    }
                    F1Stat {
                        label: "Won from pole"
                        value: page.h?.races ? Math.round(page.h.fromPole / page.h.races * 100) + "%" : ""
                        sub: page.h?.races ? page.h.fromPole + " of " + page.h.races : ""
                    }
                    F1Stat {
                        label: "Lowest grid win"
                        value: page.h?.lowest ? "P" + page.h.lowest.grid : ""
                        sub: page.h?.lowest ? page.h.lowest.last + " · " + page.h.lowest.season : ""
                    }
                    F1Stat { label: "Race distance"; value: page.h?.laps ? page.h.laps + " laps" : "" }
                    F1Stat { label: "Location"; value: page.w?.locality ?? ""; sub: page.w?.country ?? "" }
                }
            }

            F1Group {
                title: "Recent winners"
                Layout.fillHeight: true
                Repeater {
                    model: page.h?.recent ?? []
                    F1Row {
                        required property var modelData
                        required property int index
                        implicitHeight: 30
                        position: modelData.season
                        title: modelData.name
                        subtitle: modelData.grid > 0 ? "from P" + modelData.grid : "from pit lane"
                        value: modelData.time
                        team: modelData.team
                        separator: index < (page.h?.recent.length ?? 0) - 1
                    }
                }
            }
        }
    }
}
