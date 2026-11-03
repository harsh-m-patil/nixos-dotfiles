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

    F1Grid {
        anchors.fill: parent

        F1Tile {
            col: 0; row: 0; colSpan: 2; rowSpan: 3
            pad: 10
            label: page.w?.circuit ?? ""
            detail: [F1Data.track?.corners ? F1Data.track.corners.length + " turns" : "",
                     F1Data.track?.pitLoss ? "pit loss " + F1Data.track.pitLoss.toFixed(1) + "s" : ""].filter(s => s).join(" · ")
            TrackMap {
                id: map
                Layout.fillWidth: true
                Layout.fillHeight: true
                track: F1Data.track
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14
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

        F1Tile {
            col: 2; row: 0
            pad: 8
            F1Arc {
                Layout.fillWidth: true
                Layout.fillHeight: true
                value: page.h?.races ? page.h.fromPole / page.h.races : 0
                thickness: 8
                Column {
                    anchors.centerIn: parent
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.h?.races ? Math.round(page.h.fromPole / page.h.races * 100) + "%" : "—"
                        role: "numeral"; numeric: true
                    }
                    F1Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.h?.races ? page.h.fromPole + " of " + page.h.races : ""
                        role: "caption"; tone: "secondary"; numeric: true
                    }
                }
                F1Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: "Won from pole"
                    role: "caption"; tone: "tertiary"
                }
            }
        }

        F1Tile {
            col: 3; row: 0
            label: "Race distance"
            F1Text { text: page.h?.laps ? String(page.h.laps) : "—"; role: "display"; numeric: true }
            F1Text { text: "laps"; role: "caption"; tone: "tertiary" }
            Item { Layout.fillHeight: true }
            F1Ticks { Layout.fillWidth: true; count: 28; value: 1 }
            F1Text {
                Layout.topMargin: 4
                text: page.h?.races ? page.h.races + " Grands Prix since " + page.h.first : ""
                role: "caption"; tone: "tertiary"
            }
        }

        F1Tile {
            id: winsTile
            col: 2; row: 1
            readonly property color tint: F1Data.teamColour(page.h?.mostWins?.team ?? "", F1Hub.accent)
            label: "Most wins"
            F1Text { text: page.h?.mostWins ? String(page.h.mostWins.count) : "—"; role: "numeral"; numeric: true }
            F1Text {
                text: page.h?.mostWins?.names.join(", ") ?? ""
                role: "callout"; font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            Item { Layout.fillHeight: true }
            F1Ticks { Layout.fillWidth: true; cells: true; count: 10; value: (page.h?.mostWins?.count ?? 0) / 10; accent: winsTile.tint }
            F1Text {
                Layout.topMargin: 4
                text: page.h?.mostTeamWins ? page.h.mostTeamWins.names.join(", ") + " · " + page.h.mostTeamWins.count + " team wins" : ""
                role: "caption"; tone: "tertiary"
                Layout.fillWidth: true
            }
        }

        F1Tile {
            col: 3; row: 1
            label: "Lowest grid win"
            F1Text { text: page.h?.lowest ? "P" + page.h.lowest.grid : "—"; role: "display"; numeric: true }
            F1Text {
                text: page.h?.lowest ? page.h.lowest.last + " · " + page.h.lowest.season : ""
                role: "caption"; tone: "tertiary"
            }
            Item { Layout.fillHeight: true }
            F1Pill { Layout.fillWidth: true; value: page.h?.lowest ? page.h.lowest.grid / 20 : 0 }
        }

        F1Tile {
            col: 2; row: 2; colSpan: 2
            pad: 8
            label: "Recent winners"
            clip: true
            Repeater {
                model: (page.h?.recent ?? []).slice(0, 5)
                F1Row {
                    required property var modelData
                    implicitHeight: 24
                    position: modelData.season
                    title: modelData.name
                    subtitle: modelData.grid > 0 ? "from P" + modelData.grid : "from pit lane"
                    value: modelData.time
                    team: modelData.team
                    separator: false
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
